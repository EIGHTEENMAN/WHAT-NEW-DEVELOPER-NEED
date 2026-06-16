#!/bin/bash
# ============================================================
# 项目运行规则升级脚本 — project-upgrade.sh
# 用途：把已存在的项目升级到最新的通用项目开发规则运行版本
#      （不会动源代码、文档、任务卡，只更新 CLAUDE.md 和 memory/项目信息.md）
# 用法：bash project-upgrade.sh [项目目录]
#
# 幂等：可重复运行，已升级过的项目再次运行无副作用
# 安全：升级前自动备份旧文件到 memory/版本历史/
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 参数处理 ---
if [ -z "$1" ]; then
  echo -e "${YELLOW}⚠️  请指定项目目录${NC}"
  echo "用法: bash $0 [项目目录]"
  exit 1
fi

PROJECT_DIR="$1"

# 规则系统根目录（脚本所在目录的父目录）
RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$RULES_DIR/模板/CLAUDE.md.template"
CURRENT_DATE="$(date '+%Y-%m-%d')"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  🔄 项目运行规则升级开始${NC}"
echo -e "${BLUE}     目录: ${PROJECT_DIR}${NC}"
echo -e "${BLUE}     规则: ${RULES_DIR}/项目开发步骤.md${NC}"
echo -e "${BLUE}========================================${NC}"

# --- 步骤 0：基础检查 ---
if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}❌ 项目目录不存在: $PROJECT_DIR${NC}"
  exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo -e "${RED}❌ 规则模板不存在: $TEMPLATE_FILE${NC}"
  exit 1
fi

# --- 步骤 1：解析项目名 ---
# 优先从 memory/项目信息.md 中读取，其次用目录名
PROJECT_NAME="$(basename "$PROJECT_DIR")"
INFO_FILE="$PROJECT_DIR/memory/项目信息.md"
if [ -f "$INFO_FILE" ]; then
  EXTRACTED_NAME="$(grep -m1 "^项目名称:" "$INFO_FILE" 2>/dev/null | sed 's/^项目名称:[[:space:]]*//' | tr -d '\r')"
  if [ -n "$EXTRACTED_NAME" ]; then
    PROJECT_NAME="$EXTRACTED_NAME"
  fi
fi
echo -e "\n${GREEN}[1/4] 项目名称: ${PROJECT_NAME}${NC}"

# --- 步骤 2：备份目录准备 ---
BACKUP_DIR="$PROJECT_DIR/memory/版本历史"
mkdir -p "$BACKUP_DIR"

UPGRADED_FILES=()
SKIPPED_FILES=()

# --- 步骤 3：升级 CLAUDE.md ---
echo -e "\n${GREEN}[2/4] 检查 CLAUDE.md...${NC}"
CLAUDE_FILE="$PROJECT_DIR/CLAUDE.md"

if [ ! -f "$CLAUDE_FILE" ]; then
  echo -e "   ${YELLOW}⚠️  CLAUDE.md 不存在，跳过（项目可能未按本规则初始化）${NC}"
  SKIPPED_FILES+=("CLAUDE.md（不存在）")
else
  if grep -q "2.3 项目经理模式" "$CLAUDE_FILE" 2>/dev/null; then
    echo -e "   ${GREEN}✅ CLAUDE.md 已包含 2.3 项目经理模式，无需升级${NC}"
    SKIPPED_FILES+=("CLAUDE.md")
  else
    echo -e "   ${YELLOW}📦 备份旧版 CLAUDE.md → memory/版本历史/CLAUDE.md.bak.${TIMESTAMP}${NC}"
    cp "$CLAUDE_FILE" "$BACKUP_DIR/CLAUDE.md.bak.${TIMESTAMP}"

    # 按当前最新模板重新生成
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s|{{RULES_PATH}}|$RULES_DIR/项目开发步骤.md|g" \
        -e "s/{{DATE}}/$CURRENT_DATE/g" \
        "$TEMPLATE_FILE" > "$CLAUDE_FILE"

    echo -e "   ${GREEN}✅ CLAUDE.md 已升级到最新模板（含 2.3 项目经理模式）${NC}"
    UPGRADED_FILES+=("CLAUDE.md")
  fi
fi

# --- 步骤 4：升级 memory/项目信息.md（前置注入角色声明）---
echo -e "\n${GREEN}[3/4] 检查 memory/项目信息.md...${NC}"

ROLE_DECLARATION_HEADER="================ 项目经理角色声明 ================"
ROLE_DECLARATION_FOOTER="================================================"

if [ ! -f "$INFO_FILE" ]; then
  echo -e "   ${YELLOW}⚠️  memory/项目信息.md 不存在，跳过${NC}"
  SKIPPED_FILES+=("memory/项目信息.md（不存在）")
else
  if grep -q "$ROLE_DECLARATION_HEADER" "$INFO_FILE" 2>/dev/null; then
    echo -e "   ${GREEN}✅ 项目信息.md 已包含项目经理角色声明，无需注入${NC}"
    SKIPPED_FILES+=("memory/项目信息.md")
  else
    echo -e "   ${YELLOW}📦 备份旧版 项目信息.md → memory/版本历史/项目信息.md.bak.${TIMESTAMP}${NC}"
    cp "$INFO_FILE" "$BACKUP_DIR/项目信息.md.bak.${TIMESTAMP}"

    # 构造临时角色声明文件，awk 拼接：声明 + 原文
    TMP_DECL="$(mktemp)"
    cat > "$TMP_DECL" << DECL_EOF
$ROLE_DECLARATION_HEADER
本项目 Claude 的角色定位：项目经理（不是单兵执行者）。

接到任何指令、任务、需求，遵循六步流程：
1. 接收与理解 — 重述任务、反问补齐信息
2. 拆分与规划 — 子任务、DAG、subagent 类型
3. 派发与授权 — 按 subagent 指令模板下达
4. 监控与协调 — 范围合规、接口一致、进度偏差、质量门禁、文档同步
5. 汇总与校验 — 跨模块一致性 + 触发门禁
6. 汇报与记录 — 完成项、决策、未完成、风险、文档同步

派发优先：能拆就拆、能派就派、能并行就并行。
例外（直接动手）：简单问答、< 30 行单文件修改、用户明确要求"你亲自做"、紧急止血。

一句话总则：进了项目就是项目经理，能不亲自干就不亲自干，
但派出去之后必须盯到底、兜底负责。

详细规则：通用项目开发规则 项目开发步骤.md 3.5 节
$ROLE_DECLARATION_FOOTER

DECL_EOF

    TMP_OUT="$(mktemp)"
    cat "$TMP_DECL" "$INFO_FILE" > "$TMP_OUT"
    mv "$TMP_OUT" "$INFO_FILE"
    rm -f "$TMP_DECL"

    echo -e "   ${GREEN}✅ 项目信息.md 顶部已注入项目经理角色声明${NC}"
    UPGRADED_FILES+=("memory/项目信息.md")
  fi
fi

# --- 步骤 5：检查规则系统版本提示 ---
echo -e "\n${GREEN}[4/4] 检查规则系统版本...${NC}"
RULES_VERSION="$(grep -m1 "^> \*\*版本\*\*:" "$RULES_DIR/项目开发步骤.md" 2>/dev/null | sed 's/^> \*\*版本\*\*:[[:space:]]*//' | tr -d '\r')"
if [ -n "$RULES_VERSION" ]; then
  echo -e "   ${BLUE}📌 规则系统当前版本: ${RULES_VERSION}${NC}"
fi

# --- 完成汇报 ---
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}  ✅ 升级检查完成${NC}"
echo -e "${BLUE}========================================${NC}"

if [ ${#UPGRADED_FILES[@]} -gt 0 ]; then
  echo ""
  echo -e "${GREEN}升级的文件（${#UPGRADED_FILES[@]} 个）：${NC}"
  for f in "${UPGRADED_FILES[@]}"; do
    echo -e "  ${GREEN}✓${NC} $f"
  done
fi

if [ ${#SKIPPED_FILES[@]} -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}跳过（已是最新或不存在）：${NC}"
  for f in "${SKIPPED_FILES[@]}"; do
    echo -e "  ${YELLOW}⏭${NC} $f"
  done
fi

echo ""
echo -e "${BLUE}备份位置：${BACKUP_DIR}${NC}"
echo ""
echo -e "${YELLOW}📋 下一步：${NC}"
echo -e "   1. cd $PROJECT_DIR"
echo -e "   2. git diff 检视 CLAUDE.md 与 memory/项目信息.md 的变化"
echo -e "   3. 确认无误后 git add . && git commit -m 'chore: 升级运行规则到 v${RULES_VERSION}'"
echo ""
echo "提示：本脚本可重复运行，已升级过的项目再次运行无副作用。"

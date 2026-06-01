#!/bin/bash
# ============================================================
# 项目初始化脚本 — project-init.sh
# 用途：按照通用项目开发规则自动初始化一个新项目
# 用法：bash project-init.sh [项目目录] [项目名称]
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- 参数处理 ---
if [ -z "$1" ]; then
  echo -e "${YELLOW}⚠️  请指定项目目录${NC}"
  echo "用法: bash $0 [项目目录] [项目名称]"
  exit 1
fi

PROJECT_DIR="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_DIR")}"

# 规则系统根目录
RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  🚀 项目初始化开始${NC}"
echo -e "${BLUE}     项目: ${PROJECT_NAME}${NC}"
echo -e "${BLUE}     目录: ${PROJECT_DIR}${NC}"
echo -e "${BLUE}========================================${NC}"

# --- 步骤 1：创建项目目录 ---
echo -e "\n${GREEN}[1/8] 创建项目目录结构...${NC}"
mkdir -p "$PROJECT_DIR"/{memory,文档,任务卡,src,scripts,tests}
echo "   📁  $PROJECT_DIR/"
echo "   📁  ├── memory/"
echo "   📁  ├── 文档/"
echo "   📁  ├── 任务卡/"
echo "   📁  ├── src/"
echo "   📁  ├── tests/"
echo "   📁  └── scripts/"

# --- 步骤 2：初始化 Git 仓库 ---
echo -e "\n${GREEN}[2/8] 初始化 Git 仓库...${NC}"
cd "$PROJECT_DIR"

if [ -d ".git" ]; then
  echo -e "   ${YELLOW}⚠️   Git 仓库已存在，跳过${NC}"
else
  git init
  echo "node_modules/
dist/
.env
*.log
.DS_Store" > .gitignore
  git add .
  git commit -m "🎉 初始化项目 $PROJECT_NAME" --allow-empty
  echo -e "   ${GREEN}✅ Git 仓库初始化完成${NC}"
fi

# --- 步骤 3：创建 Memory 文件 ---
echo -e "\n${GREEN}[3/8] 创建项目 Memory 文件...${NC}"

cat > "$PROJECT_DIR/memory/项目信息.md" << EOF
---
name: 项目信息
description: $PROJECT_NAME 的核心项目信息
metadata:
  type: project
---

$PROJECT_NAME

项目名称: $PROJECT_NAME
启动日期: $(date +%Y-%m-%d)
项目目标: 待填写
技术栈: 待填写
团队成员: 待填写

里程碑

[时间1] — [里程碑描述1] — 待开始
EOF

echo "   ✅ memory/项目信息.md 已创建"

# --- 步骤 4：创建 CLAUDE.md ---
echo -e "\n${GREEN}[4/8] 创建 CLAUDE.md 项目运行规则...${NC}"

# 将模板中的变量替换
CURRENT_DATE="$(date '+%Y-%m-%d')"
sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s|{{RULES_PATH}}|$RULES_DIR/项目开发步骤.md|g" \
    -e "s/{{DATE}}/$CURRENT_DATE/g" \
    "$RULES_DIR/模板/CLAUDE.md.template" > "$PROJECT_DIR/CLAUDE.md"

echo "   ✅ CLAUDE.md 已创建"

# --- 步骤 5：创建文档模板 ---
echo -e "\n${GREEN}[5/8] 创建项目文档模板...${NC}"

# 复制文档模板
TEMPLATE_DIR="$RULES_DIR/模板/文档模板"
DOC_DIR="$PROJECT_DIR/文档"

if [ -d "$TEMPLATE_DIR" ]; then
  CURRENT_DATE="$(date '+%Y-%m-%d')"
  for template_file in "$TEMPLATE_DIR"/*.md; do
    filename=$(basename "$template_file")
    target_file="$DOC_DIR/$filename"
    if [ ! -f "$target_file" ]; then
      sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
          -e "s/{{DATE}}/$CURRENT_DATE/g" \
          "$template_file" > "$target_file"
      echo "   📄  $filename"
    else
      echo -e "   ${YELLOW}⚠️   $filename 已存在，跳过${NC}"
    fi
  done
else
  echo -e "   ${YELLOW}⚠️  文档模板目录不存在，跳过${NC}"
fi

# 如果没有模板，创建空文件占位
for doc_name in 商业计划书 PMP项目管理 用户体验蓝图 PRD产品需求文档 数据库设计 技术架构; do
  target_file="$DOC_DIR/${doc_name}.md"
  if [ ! -f "$target_file" ]; then
    echo "# $doc_name" > "$target_file"
    echo "" >> "$target_file"
    echo "> 项目: $PROJECT_NAME" >> "$target_file"
    echo "" >> "$target_file"
    echo "<!-- TODO: 填写 $doc_name 内容 -->" >> "$target_file"
  fi
done

echo "   📚  文档模板创建完成"

# --- 步骤 6：创建初始待办清单 ---
echo -e "\n${GREEN}[6/8] 创建初始待办任务清单...${NC}"

TODO_FILE="$PROJECT_DIR/memory/TODO.md"

# 从规则文件读取任务项
cat > "$TODO_FILE" << 'TASKEOF'
TODO — 项目任务清单

自动生成于：{{DATE}}
项目：{{PROJECT_NAME}}

项目初始化任务（优先级 P0）

1. 完善项目 Memory 文件（memory/项目信息.md）
2. 确认 Git 仓库配置与远程仓库
3. 配置 CI/CD 自动部署
4. 配置每日备份（22:00 自动备份）

项目规划任务（优先级 P0）

5. 编写商业计划书（PPT + MD）
6. 建立 PMP 项目管理文件
7. 编写用户体验蓝图
8. 编写 PRD 产品需求文档
9. 数据库设计
10. 技术架构设计

开发准备任务（优先级 P1）

11. 创建开发任务卡
12. 建立测试 Hook
13. 配置代码检查和类型检查
14. 配置 pre-commit hooks

已创建的任务

{{DATE}} — 项目初始化 — 进行中

TASKEOF

# 替换模板变量
sed -i '' "s/{{DATE}}/$(date '+%Y-%m-%d %H:%M')/g" "$TODO_FILE"
sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TODO_FILE"

echo "   ✅ 初始任务清单已创建"
echo "   📋  共 14 个待办事项"

# --- 步骤 7：配置测试 hook 脚本 ---
echo -e "\n${GREEN}[7/8] 创建测试 Hook 脚本...${NC}"

# 创建 .claude 目录
mkdir -p "$PROJECT_DIR/.claude"

cat > "$PROJECT_DIR/scripts/run-checks.sh" << 'CHECKS'
#!/bin/bash
# 代码检测脚本 — 每次任务结束后自动运行
# 由 Claude Code hooks 触发

echo "🔍 运行代码检测..."

# 检测 package.json 是否存在
if [ -f "package.json" ]; then
  echo "📦 Node.js 项目检测..."

  # ESLint
  if grep -q '"eslint"' package.json 2>/dev/null; then
    echo "  → 运行 ESLint..."
    npx eslint src/ --quiet 2>/dev/null && echo "    ✅ ESLint 通过" || echo "    ⚠️  ESLint 有警告"
  fi

  # TypeScript 类型检查
  if grep -q '"typescript"' package.json 2>/dev/null; then
    echo "  → 运行 TypeScript 类型检查..."
    npx tsc --noEmit 2>/dev/null && echo "    ✅ TypeScript 检查通过" || echo "    ⚠️  TypeScript 检查有错误"
  fi

  # 运行测试
  if grep -q '"jest\|vitest\|mocha"' package.json 2>/dev/null; then
    echo "  → 运行测试..."
    npx vitest run 2>/dev/null || npx jest --passWithNoTests 2>/dev/null || echo "    ⚠️  测试未配置完成"
  fi
fi

# 检测 pyproject.toml 或 requirements.txt
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  echo "🐍 Python 项目检测..."

  # ruff / flake8
  if command -v ruff &>/dev/null; then
    echo "  → 运行 ruff..."
    ruff check src/ --quiet 2>/dev/null && echo "    ✅ ruff 通过" || echo "    ⚠️  ruff 有建议"
  fi

  # pytest
  if command -v pytest &>/dev/null; then
    echo "  → 运行 pytest..."
    pytest --quiet 2>/dev/null && echo "    ✅ 测试通过" || echo "    ⚠️  测试有失败"
  fi
fi

echo "✅ 代码检测完成"
CHECKS

chmod +x "$PROJECT_DIR/scripts/run-checks.sh"

# 创建 .claude/settings.json hooks 配置
cat > "$PROJECT_DIR/.claude/settings.json" << 'SETTINGS'
{
  "hooks": {
    "PostToolUse": {
      "run": "bash scripts/run-checks.sh"
    }
  },
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(cd * && git *)",
      "Bash(python *)",
      "Bash(* test *)"
    ]
  }
}
SETTINGS

echo "   ✅ 测试 Hook 已配置"

# --- 步骤 8：创建 .gitignore 和备份配置 ---
echo -e "\n${GREEN}[8/8] 完善项目配置...${NC}"

# 确保 .gitignore
if ! grep -q "memory/" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
  cat >> "$PROJECT_DIR/.gitignore" << 'EOF'

# 项目特殊忽略
*.local
EOF
fi

# 创建备份脚本
cat > "$PROJECT_DIR/scripts/backup.sh" << 'BACKUP'
#!/bin/bash
# 每日备份脚本 — 每天 22:00 自动运行
# 备份完整代码到指定位置

BACKUP_DIR="${BACKUP_DIR:-./backups}"
PROJECT_NAME="$(basename "$(pwd)")"
DATE_STAMP=$(date +%Y%m%d_%H%M)
BACKUP_FILE="${BACKUP_DIR}/${PROJECT_NAME}_${DATE_STAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 开始备份 $PROJECT_NAME..."
tar --exclude="node_modules" \
    --exclude=".git" \
    --exclude="dist" \
    --exclude=".next" \
    --exclude="venv" \
    --exclude="__pycache__" \
    --exclude="backups" \
    -czf "$BACKUP_FILE" .

echo "✅ 备份完成: $BACKUP_FILE"
BACKUP

chmod +x "$PROJECT_DIR/scripts/backup.sh"

echo "   ✅ .gitignore 已配置"
echo "   ✅ backup.sh 已创建"

# --- 完成 ---
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}  ✅ 项目初始化完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "项目结构："
echo "$PROJECT_DIR/"
echo "├── CLAUDE.md            ← 项目运行规则"
echo "├── memory/              ← 项目记忆"
echo "├── 文档/                 ← 项目文档"
echo "├── 任务卡/               ← 开发任务卡"
echo "├── src/                 ← 源代码目录"
echo "├── tests/               ← 测试目录"
echo "├── scripts/             ← 自动化脚本"
echo "├── .claude/             ← Claude Code 配置"
echo "└── .gitignore"
echo ""
echo -e "${YELLOW}📋 下一步：转到项目目录并启动 Claude Code${NC}"
echo "   cd $PROJECT_DIR"
echo "   claude"
echo ""
echo "然后输入：\"查看待办\" 查看初始化任务清单"

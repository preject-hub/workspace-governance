#!/bin/bash

# Workspace Governance - 初始化工作区
# 用于首次使用时创建必要的目录结构

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 工作区根目录
WORKSPACE_ROOT="$HOME/workspace"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否已初始化
check_initialized() {
    if [ -d "$WORKSPACE_ROOT/projects" ] && \
       [ -d "$WORKSPACE_ROOT/registry" ] && \
       [ -d "$WORKSPACE_ROOT/templates" ] && \
       [ -d "$WORKSPACE_ROOT/.ai" ]; then
        return 0
    fi
    return 1
}

# 创建目录结构
create_directories() {
    log_info "创建工作区目录结构..."

    # 创建主目录
    mkdir -p "$WORKSPACE_ROOT"

    # 创建子目录
    mkdir -p "$WORKSPACE_ROOT/projects"
    mkdir -p "$WORKSPACE_ROOT/registry"
    mkdir -p "$WORKSPACE_ROOT/templates"
    mkdir -p "$WORKSPACE_ROOT/.ai"

    log_info "目录结构创建完成"
}

# 初始化 registry 文件
init_registry() {
    local registry_file="$WORKSPACE_ROOT/registry/projects.yaml"

    if [ ! -f "$registry_file" ]; then
        log_info "初始化 projects.yaml..."
        cat > "$registry_file" << 'EOF'
# OpenClaw 项目注册表
# 由 workspace-governance skill 管理
# 请勿手动编辑此文件

projects: {}
EOF
        log_info "projects.yaml 初始化完成"
    else
        log_warn "projects.yaml 已存在，跳过初始化"
    fi
}

# 创建模板链接
link_templates() {
    local skill_templates="$HOME/.openclaw/skills/workspace-governance/templates"

    if [ -d "$skill_templates" ]; then
        log_info "链接模板文件..."
        # 使用符号链接而不是复制，便于更新
        ln -sf "$skill_templates"/* "$WORKSPACE_ROOT/templates/" 2>/dev/null || true
        log_info "模板链接完成"
    else
        log_warn "模板目录不存在：$skill_templates"
    fi
}

# 创建 AI 配置文件
init_ai_config() {
    local ai_config="$WORKSPACE_ROOT/.ai/config.yaml"

    if [ ! -f "$ai_config" ]; then
        log_info "初始化 AI 配置..."
        cat > "$ai_config" << 'EOF'
# OpenClaw AI 配置

# 默认 AI 工具
defaults:
  primary: openclaw
  secondary:
    - claude-code

# 上下文加载设置
context:
  auto_load: true
  max_depth: 3
  ignore_patterns:
    - node_modules
    - .git
    - dist
    - build

# 代码生成设置
generation:
  style: airbnb
  typescript: true
  testing: true
EOF
        log_info "AI 配置初始化完成"
    else
        log_warn "AI 配置已存在，跳过初始化"
    fi
}

# 创建 .gitignore
init_gitignore() {
    local gitignore="$WORKSPACE_ROOT/.gitignore"

    if [ ! -f "$gitignore" ]; then
        log_info "创建 .gitignore..."
        cat > "$gitignore" << 'EOF'
# 依赖
node_modules/
.pnp
.pnp.js

# 构建
dist/
build/
out/

# 环境
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# 系统
.DS_Store
Thumbs.db

# 日志
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# 临时文件
tmp/
temp/
EOF
        log_info ".gitignore 创建完成"
    fi
}

# 显示工作区信息
show_workspace_info() {
    echo ""
    echo "=========================================="
    echo "  OpenClaw Workspace 初始化完成"
    echo "=========================================="
    echo ""
    echo "工作区位置：$WORKSPACE_ROOT"
    echo ""
    echo "目录结构："
    echo "  ~/workspace/"
    echo "  ├── projects/      # 项目源码"
    echo "  ├── registry/      # 项目注册表"
    echo "  ├── templates/     # 模板文件"
    echo "  └── .ai/           # AI 配置"
    echo ""
    echo "下一步："
    echo "  1. 创建新项目：create-project <project-name>"
    echo "  2. 查看项目列表：list-projects"
    echo "  3. 加载项目上下文：load-project-context <project-name>"
    echo ""
}

# 主函数
main() {
    echo "开始初始化 OpenClaw Workspace..."
    echo ""

    # 检查是否已初始化
    if check_initialized; then
        log_warn "工作区已初始化"
        read -p "是否重新初始化？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "取消初始化"
            exit 0
        fi
    fi

    # 执行初始化
    create_directories
    init_registry
    link_templates
    init_ai_config
    init_gitignore

    # 显示信息
    show_workspace_info
}

# 执行主函数
main "$@"

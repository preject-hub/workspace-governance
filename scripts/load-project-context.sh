#!/bin/bash

# Workspace Governance - 加载项目上下文
# 读取项目配置并输出 AI Agent 可用的上下文信息

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 配置
WORKSPACE_ROOT="$HOME/workspace"
REGISTRY_FILE="$WORKSPACE_ROOT/registry/projects.yaml"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 显示帮助
show_help() {
    cat << 'EOF'
用法: load-project-context <project-name> [options]

选项:
  --format, -f    输出格式（text/json/markdown）
  --section, -s   输出指定部分（all/basic/tech/style/git/deployment）
  --help, -h      显示帮助信息

示例:
  load-project-context my-app
  load-project-context my-app --format json
  load-project-context my-app --section tech
EOF
}

# 解析参数
parse_args() {
    PROJECT_NAME=""
    OUTPUT_FORMAT="text"
    OUTPUT_SECTION="all"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --format|-f)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --section|-s)
                OUTPUT_SECTION="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$PROJECT_NAME" ]; then
                    PROJECT_NAME="$1"
                else
                    log_error "多余的参数: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 验证项目名称
    if [ -z "$PROJECT_NAME" ]; then
        log_error "请提供项目名称"
        show_help
        exit 1
    fi
}

# 检查项目是否存在
check_project_exists() {
    # 检查目录
    if [ ! -d "$WORKSPACE_ROOT/projects/$PROJECT_NAME" ]; then
        log_error "项目目录不存在: $WORKSPACE_ROOT/projects/$PROJECT_NAME"
        exit 1
    fi

    # 检查 registry
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_error "项目注册表不存在: $REGISTRY_FILE"
        exit 1
    fi

    if ! grep -q "  $PROJECT_NAME:" "$REGISTRY_FILE"; then
        log_error "项目未注册: $PROJECT_NAME"
        exit 1
    fi
}

# 解析 YAML 值（简单版本，不依赖 yq）
parse_yaml_value() {
    local file="$1"
    local key="$2"
    local value=""

    # 使用 grep 和 sed 提取值
    value=$(grep -A 100 "  $PROJECT_NAME:" "$file" | grep -m 1 "$key:" | sed 's/.*: *//' | sed 's/^"//' | sed 's/"$//')

    echo "$value"
}

# 获取项目基本信息
get_basic_info() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    # 从 CLAW.md 读取描述
    local description=""
    if [ -f "$project_dir/CLAW.md" ]; then
        description=$(head -5 "$project_dir/CLAW.md" | grep "^>" | sed 's/^> //')
    fi

    # 从 registry 读取创建时间
    local created=$(parse_yaml_value "$REGISTRY_FILE" "created")

    cat << EOF
项目名称：$PROJECT_NAME
项目描述：${description:-未配置}
项目位置：$WORKSPACE_ROOT/projects/$PROJECT_NAME
创建时间：${created:-未知}
EOF
}

# 获取技术栈信息
get_tech_info() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    # 从 CLAW.md 读取技术栈
    if [ -f "$project_dir/CLAW.md" ]; then
        echo "技术栈："
        # 提取技术栈部分
        sed -n '/^## 技术栈/,/^## /p' "$project_dir/CLAW.md" | \
            grep "^- " | \
            sed 's/^/  /'
    else
        echo "技术栈：未配置"
    fi
}

# 获取代码风格信息
get_style_info() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    # 从 registry 读取
    local code_style=$(parse_yaml_value "$REGISTRY_FILE" "code:")
    local ui_framework=$(parse_yaml_value "$REGISTRY_FILE" "ui:")
    local naming=$(parse_yaml_value "$REGISTRY_FILE" "naming:")

    cat << EOF
代码风格：${code_style:-未配置}
UI 框架：${ui_framework:-未配置}
命名规范：${naming:-未配置}
EOF
}

# 获取 Git 信息
get_git_info() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    # 从 registry 读取
    local remote=$(parse_yaml_value "$REGISTRY_FILE" "remote:")
    local branch=$(parse_yaml_value "$REGISTRY_FILE" "branch:")

    # 如果 registry 中没有，尝试从 git 读取
    if [ -z "$remote" ] && [ -d "$project_dir/.git" ]; then
        remote=$(cd "$project_dir" && git remote get-url origin 2>/dev/null || echo "")
    fi

    if [ -z "$branch" ] && [ -d "$project_dir/.git" ]; then
        branch=$(cd "$project_dir" && git branch --show-current 2>/dev/null || echo "main")
    fi

    cat << EOF
远程仓库：${remote:-未配置}
主分支：${branch:-main}
EOF
}

# 获取部署信息
get_deployment_info() {
    # 从 registry 读取
    local prod_url=$(parse_yaml_value "$REGISTRY_FILE" "prod:")
    local staging_url=$(parse_yaml_value "$REGISTRY_FILE" "staging:")

    cat << EOF
生产环境：${prod_url:-未配置}
测试环境：${staging_url:-未配置}
EOF
}

# 获取 CLAW.md 内容
get_claw_content() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"
    local claw_file="$project_dir/CLAW.md"

    if [ -f "$claw_file" ]; then
        cat "$claw_file"
    else
        echo "CLAW.md 不存在"
    fi
}

# 获取 CLAUDE.md 内容
get_claude_content() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"
    local claude_file="$project_dir/CLAUDE.md"

    if [ -f "$claude_file" ]; then
        cat "$claude_file"
    else
        echo "CLAUDE.md 不存在"
    fi
}

# 输出文本格式
output_text() {
    case $OUTPUT_SECTION in
        all)
            echo "=========================================="
            echo "  项目上下文：$PROJECT_NAME"
            echo "=========================================="
            echo ""
            echo "--- 基本信息 ---"
            get_basic_info
            echo ""
            echo "--- 技术栈 ---"
            get_tech_info
            echo ""
            echo "--- 代码风格 ---"
            get_style_info
            echo ""
            echo "--- Git 信息 ---"
            get_git_info
            echo ""
            echo "--- 部署信息 ---"
            get_deployment_info
            echo ""
            echo "--- CLAW.md ---"
            get_claw_content
            ;;
        basic)
            get_basic_info
            ;;
        tech)
            get_tech_info
            ;;
        style)
            get_style_info
            ;;
        git)
            get_git_info
            ;;
        deployment)
            get_deployment_info
            ;;
        *)
            log_error "未知的 section: $OUTPUT_SECTION"
            exit 1
            ;;
    esac
}

# 输出 JSON 格式
output_json() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    # 从 CLAW.md 读取描述
    local description=""
    if [ -f "$project_dir/CLAW.md" ]; then
        description=$(head -5 "$project_dir/CLAW.md" | grep "^>" | sed 's/^> //')
    fi

    # 从 registry 读取
    local created=$(parse_yaml_value "$REGISTRY_FILE" "created:")
    local code_style=$(parse_yaml_value "$REGISTRY_FILE" "code:")
    local ui_framework=$(parse_yaml_value "$REGISTRY_FILE" "ui:")
    local naming=$(parse_yaml_value "$REGISTRY_FILE" "naming:")
    local remote=$(parse_yaml_value "$REGISTRY_FILE" "remote:")
    local branch=$(parse_yaml_value "$REGISTRY_FILE" "branch:")

    cat << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "description": "${description:-}",
    "path": "$project_dir",
    "created": "${created:-}"
  },
  "tech": {
    "frontend": [],
    "backend": [],
    "database": []
  },
  "style": {
    "code": "${code_style:-}",
    "ui": "${ui_framework:-}",
    "naming": "${naming:-}"
  },
  "git": {
    "remote": "${remote:-}",
    "branch": "${branch:-main}"
  },
  "deployment": {
    "prod": {
      "url": ""
    },
    "staging": {
      "url": ""
    }
  }
}
EOF
}

# 输出 Markdown 格式
output_markdown() {
    cat << EOF
# 项目上下文：$PROJECT_NAME

## 基本信息

$(get_basic_info)

## 技术栈

$(get_tech_info)

## 代码风格

$(get_style_info)

## Git 信息

$(get_git_info)

## 部署信息

$(get_deployment_info)

## CLAW.md

$(get_claw_content)
EOF
}

# 主函数
main() {
    # 解析参数
    parse_args "$@"

    # 检查项目是否存在
    check_project_exists

    # 根据格式输出
    case $OUTPUT_FORMAT in
        text)
            output_text
            ;;
        json)
            output_json
            ;;
        markdown)
            output_markdown
            ;;
        *)
            log_error "未知的输出格式: $OUTPUT_FORMAT"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"

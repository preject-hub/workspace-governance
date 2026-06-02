#!/bin/bash

# Workspace Governance - 创建项目
# 自动初始化新项目的目录结构和配置文件

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
WORKSPACE_ROOT="$HOME/workspace"
SKILL_ROOT="$HOME/.openclaw/skills/workspace-governance"
REGISTRY_FILE="$WORKSPACE_ROOT/registry/projects.yaml"

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 显示帮助
show_help() {
    cat << 'EOF'
用法: create-project <project-name> [options]

选项:
  --description, -d   项目描述
  --tech, -t          技术栈（逗号分隔）
  --style, -s         代码风格（airbnb/standard/prettier）
  --git, -g           Git 远程仓库地址
  --ui, -u            UI 框架（semi-design/antd/element）
  --help, -h          显示帮助信息

示例:
  create-project my-app
  create-project my-app --description "我的应用" --tech react,vite,node
  create-project my-app -d "我的应用" -t react,vite -s airbnb -u semi-design
EOF
}

# 解析参数
parse_args() {
    PROJECT_NAME=""
    DESCRIPTION=""
    TECH_STACK=""
    CODE_STYLE="airbnb"
    GIT_REMOTE=""
    UI_FRAMEWORK="semi-design"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --description|-d)
                DESCRIPTION="$2"
                shift 2
                ;;
            --tech|-t)
                TECH_STACK="$2"
                shift 2
                ;;
            --style|-s)
                CODE_STYLE="$2"
                shift 2
                ;;
            --git|-g)
                GIT_REMOTE="$2"
                shift 2
                ;;
            --ui|-u)
                UI_FRAMEWORK="$2"
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

    # 验证项目名称格式
    if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
        log_error "项目名称必须以小写字母开头，只能包含小写字母、数字和连字符"
        exit 1
    fi

    # 设置默认描述
    if [ -z "$DESCRIPTION" ]; then
        DESCRIPTION="$PROJECT_NAME 项目"
    fi

    # 设置默认技术栈
    if [ -z "$TECH_STACK" ]; then
        TECH_STACK="react,vite,typescript"
    fi
}

# 检查项目是否已存在
check_project_exists() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    if [ -d "$project_dir" ]; then
        log_error "项目已存在: $project_dir"
        exit 1
    fi

    # 检查 registry
    if [ -f "$REGISTRY_FILE" ] && grep -q "  $PROJECT_NAME:" "$REGISTRY_FILE"; then
        log_error "项目已注册: $PROJECT_NAME"
        exit 1
    fi
}

# 创建项目目录
create_project_directory() {
    log_step "创建项目目录..."

    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"
    mkdir -p "$project_dir"

    # 创建子目录
    mkdir -p "$project_dir/src"
    mkdir -p "$project_dir/public"
    mkdir -p "$project_dir/tests"
    mkdir -p "$project_dir/docs"
    mkdir -p "$project_dir/deployment"

    log_info "项目目录创建完成: $project_dir"
}

# 初始化 Git
init_git() {
    log_step "初始化 Git 仓库..."

    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    cd "$project_dir"
    git init

    # 创建 .gitignore
    cat > .gitignore << 'EOF'
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

# 测试
coverage/
.nyc_output/

# 临时文件
tmp/
temp/
.cache/
EOF

    # 如果提供了远程仓库，添加远程
    if [ -n "$GIT_REMOTE" ]; then
        git remote add origin "$GIT_REMOTE"
        log_info "已添加远程仓库: $GIT_REMOTE"
    fi

    log_info "Git 仓库初始化完成"
}

# 创建 README.md
create_readme() {
    log_step "创建 README.md..."

    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    cat > "$project_dir/README.md" << EOF
# $PROJECT_NAME

> $DESCRIPTION

## 技术栈

$(echo "$TECH_STACK" | tr ',' '\n' | sed 's/^/- /')

## 快速开始

### 安装依赖

\`\`\`bash
npm install
\`\`\`

### 开发

\`\`\`bash
npm run dev
\`\`\`

### 构建

\`\`\`bash
npm run build
\`\`\`

## 项目结构

\`\`\`
$PROJECT_NAME/
├── src/            # 源代码
├── public/         # 静态资源
├── tests/          # 测试文件
├── docs/           # 文档
└── deployment/     # 部署配置
\`\`\`

## 开发规范

详见 [CLAW.md](./CLAW.md)

## 许可证

MIT
EOF

    log_info "README.md 创建完成"
}

# 创建 CLAW.md
create_claw_md() {
    log_step "创建 CLAW.md..."

    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"
    local template_file="$SKILL_ROOT/templates/CLAW.md.template"

    # 解析技术栈
    IFS=',' read -ra TECH_ARRAY <<< "$TECH_STACK"
    TECH_FRONTEND=""
    TECH_BACKEND=""
    TECH_DATABASE=""

    for tech in "${TECH_ARRAY[@]}"; do
        case $tech in
            react|vue|angular|svelte|vite|webpack|next|nuxt)
                TECH_FRONTEND="$TECH_FRONTEND- $tech\n"
                ;;
            node|express|koa|fastify|nestjs|python|django|flask|go|gin|java|spring)
                TECH_BACKEND="$TECH_BACKEND- $tech\n"
                ;;
            postgresql|mysql|mongodb|redis|sqlite)
                TECH_DATABASE="$TECH_DATABASE- $tech\n"
                ;;
            typescript|javascript)
                # 通用，放入前端
                TECH_FRONTEND="$TECH_FRONTEND- $tech\n"
                ;;
        esac
    done

    # 如果没有明确分类，默认放入前端
    if [ -z "$TECH_FRONTEND" ] && [ -z "$TECH_BACKEND" ]; then
        for tech in "${TECH_ARRAY[@]}"; do
            TECH_FRONTEND="$TECH_FRONTEND- $tech\n"
        done
    fi

    # 生成 CLAW.md
    cat > "$project_dir/CLAW.md" << EOF
# $PROJECT_NAME

> $DESCRIPTION

## 技术栈

### 前端
$(echo -e "$TECH_FRONTEND")

### 后端
$(echo -e "$TECH_BACKEND")

### 数据库
$(echo -e "$TECH_DATABASE")

## 代码风格

- **编码规范**：$CODE_STYLE
- **命名规范**：camelCase
- **UI 框架**：$UI_FRAMEWORK

## 命名规范

### 变量命名
- 普通变量：\`camelCase\`
- 常量：\`UPPER_SNAKE_CASE\`
- 布尔值：以 \`is\`、\`has\`、\`can\` 开头

### 函数命名
- 普通函数：\`camelCase\`
- 事件处理：\`handle\` + 事件名
- 获取数据：\`get\` + 数据名
- 设置数据：\`set\` + 数据名

### 组件命名
- React 组件：\`PascalCase\`
- 页面组件：\`PascalCase\` + \`Page\` 后缀
- 工具组件：\`PascalCase\` + 功能描述

### 文件命名
- 组件文件：\`PascalCase.tsx\`
- 工具文件：\`camelCase.ts\`
- 样式文件：\`camelCase.module.less\`
- 类型文件：\`PascalCase.types.ts\`

## Hook 规范

### 自定义 Hook
\`\`\`typescript
// 以 use 开头
useUserProfile()
useAuth()
useLocalStorage()
\`\`\`

### 生命周期 Hook
\`\`\`typescript
// 组件挂载后执行
useEffect(() => {
  // 初始化逻辑
}, [])

// 依赖变化时执行
useEffect(() => {
  // 副作用逻辑
}, [dependency])
\`\`\`

## API 规范

### RESTful API
- GET：获取资源
- POST：创建资源
- PUT：更新资源（全量）
- PATCH：更新资源（部分）
- DELETE：删除资源

### 响应格式
\`\`\`typescript
interface ApiResponse<T> {
  code: number;      // 状态码
  message: string;   // 提示信息
  data: T;          // 响应数据
}
\`\`\`

## Git Commit 规范

### Commit Message 格式
\`\`\`
<type>(<scope>): <subject>

<body>

<footer>
\`\`\`

### Type 类型
- \`feat\`：新功能
- \`fix\`：修复 Bug
- \`docs\`：文档更新
- \`style\`：代码格式（不影响功能）
- \`refactor\`：重构
- \`perf\`：性能优化
- \`test\`：测试相关
- \`chore\`：构建/工具相关

## Agent 职责

### 代码生成
- 根据需求生成符合规范的代码
- 遵循项目的技术栈和代码风格
- 生成完整的类型定义

### 代码审查
- 检查代码规范遵守情况
- 发现潜在的 Bug 和安全问题
- 提供优化建议

### 文档维护
- 更新 README 和 API 文档
- 维护 CHANGELOG
- 生成组件文档

### 测试支持
- 生成单元测试
- 编写集成测试
- 维护测试覆盖率
EOF

    log_info "CLAW.md 创建完成"
}

# 创建 CLAUDE.md
create_claude_md() {
    log_step "创建 CLAUDE.md..."

    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    cat > "$project_dir/CLAUDE.md" << EOF
# 角色：二开前端工程师

## 身份标识

**当前身份**：secondary-frontend
**身份目录**：\`secondary-frontend\`
**项目名称**：$PROJECT_NAME

## Skill 限制

**只能使用 \`secondary-frontend\` 目录下的 Skill，禁止使用其他身份的 Skill。**

## 角色说明

专注于基于基线产品的二次前端开发，遵循二开技术规范，确保代码的可维护性和与基线版本的兼容性。

## 项目上下文

### 基本信息
- **项目名称**：$PROJECT_NAME
- **项目描述**：$DESCRIPTION
- **创建时间**：$(date +%Y-%m-%d)

### 技术栈
$(echo "$TECH_STACK" | tr ',' '\n' | sed 's/^/- /')

### 代码规范
- **编码风格**：$CODE_STYLE
- **命名规范**：camelCase
- **UI 框架**：$UI_FRAMEWORK

## 工作准则

### 通用准则
1. **代码质量**：编写清晰、可维护的代码
2. **类型安全**：使用 TypeScript，避免 any
3. **测试覆盖**：关键逻辑必须有测试
4. **文档完整**：公共 API 必须有文档

### 项目特定准则
1. **扩展优先**：优先通过扩展方式实现需求，避免直接修改基线源码
2. **文档意识**：关键逻辑必须添加清晰的中文注释，标明二开修改点
3. **升级兼容**：考虑基线版本升级时的兼容性问题，降低升级成本

## 上下文信息

### Git 信息
- **仓库地址**：${GIT_REMOTE:-未配置}
- **主分支**：main

### AI 配置
- **主要工具**：openclaw
- **辅助工具**：claude-code
EOF

    log_info "CLAUDE.md 创建完成"
}

# 注册到 projects.yaml
register_project() {
    log_step "注册项目到 projects.yaml..."

    # 确保 registry 目录存在
    mkdir -p "$WORKSPACE_ROOT/registry"

    # 如果文件不存在或为空，创建初始文件
    if [ ! -f "$REGISTRY_FILE" ] || [ ! -s "$REGISTRY_FILE" ] || ! grep -q "^projects:" "$REGISTRY_FILE"; then
        cat > "$REGISTRY_FILE" << 'EOF'
# OpenClaw 项目注册表
# 由 workspace-governance skill 管理

projects:
EOF
    fi

    # 生成技术栈 YAML
    IFS=',' read -ra TECH_ARRAY <<< "$TECH_STACK"
    TECH_YAML=""
    for tech in "${TECH_ARRAY[@]}"; do
        case $tech in
            react|vue|angular|svelte|vite|webpack|next|nuxt|typescript|javascript)
                TECH_YAML="${TECH_YAML}        - $tech\n"
                ;;
            node|express|koa|fastify|nestjs|python|django|flask|go|gin|java|spring)
                TECH_YAML="${TECH_YAML}        - $tech\n"
                ;;
            *)
                TECH_YAML="${TECH_YAML}        - $tech\n"
                ;;
        esac
    done

    # 添加项目配置
    cat >> "$REGISTRY_FILE" << EOF
  $PROJECT_NAME:
    description: $DESCRIPTION
    created: $(date +%Y-%m-%d)
    updated: $(date +%Y-%m-%d)

    paths:
      source: ~/workspace/projects/$PROJECT_NAME
      templates: ~/.openclaw/skills/workspace-governance/templates

    git:
      remote: ${GIT_REMOTE:-}
      branch: main

    deployment:
      prod:
        url:
        status: pending
      staging:
        url:
        status: pending

    tech:
      frontend:
$(echo -e "$TECH_YAML")

    ai:
      primary: openclaw
      secondary:
        - claude-code

    style:
      code: $CODE_STYLE
      ui: $UI_FRAMEWORK
      naming: camelCase

    status: active
    archived: false
EOF

    log_info "项目注册完成"
}

# 创建 .editorconfig
create_editorconfig() {
    log_step "创建 .editorconfig..."

    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    cat > "$project_dir/.editorconfig" << 'EOF'
# EditorConfig helps maintain consistent coding styles
# https://editorconfig.org

root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[*.{js,jsx,ts,tsx}]
indent_style = space
indent_size = 2

[*.{json,yml,yaml}]
indent_style = space
indent_size = 2

[*.css]
indent_style = space
indent_size = 2

[*.less]
indent_style = space
indent_size = 2

[*.html]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
EOF

    log_info ".editorconfig 创建完成"
}

# 创建 .prettierrc
create_prettierrc() {
    log_step "创建 .prettierrc..."

    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    cat > "$project_dir/.prettierrc" << 'EOF'
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "quoteProps": "as-needed",
  "jsxSingleQuote": false,
  "trailingComma": "all",
  "bracketSpacing": true,
  "jsxBracketSameLine": false,
  "arrowParens": "always",
  "rangeStart": 0,
  "rangeEnd": Infinity,
  "requirePragma": false,
  "insertPragma": false,
  "proseWrap": "preserve",
  "htmlWhitespaceSensitivity": "css",
  "vueIndentScriptAndStyle": false,
  "endOfLine": "lf",
  "embeddedLanguageFormatting": "auto",
  "singleAttributePerLine": false
}
EOF

    log_info ".prettierrc 创建完成"
}

# 显示创建结果
show_result() {
    local project_dir="$WORKSPACE_ROOT/projects/$PROJECT_NAME"

    echo ""
    echo "=========================================="
    echo "  项目创建成功"
    echo "=========================================="
    echo ""
    echo "项目名称：$PROJECT_NAME"
    echo "项目位置：$project_dir"
    echo ""
    echo "已创建文件："
    echo "  ├── README.md"
    echo "  ├── CLAW.md"
    echo "  ├── CLAUDE.md"
    echo "  ├── .gitignore"
    echo "  ├── .editorconfig"
    echo "  └── .prettierrc"
    echo ""
    echo "已创建目录："
    echo "  ├── src/"
    echo "  ├── public/"
    echo "  ├── tests/"
    echo "  ├── docs/"
    echo "  └── deployment/"
    echo ""
    echo "下一步："
    echo "  1. cd $project_dir"
    echo "  2. npm init"
    echo "  3. npm install"
    echo "  4. 开始开发"
    echo ""
}

# 主函数
main() {
    # 解析参数
    parse_args "$@"

    echo "开始创建项目: $PROJECT_NAME"
    echo ""

    # 检查项目是否已存在
    check_project_exists

    # 创建项目
    create_project_directory
    init_git
    create_readme
    create_claw_md
    create_claude_md
    register_project
    create_editorconfig
    create_prettierrc

    # 显示结果
    show_result
}

# 执行主函数
main "$@"

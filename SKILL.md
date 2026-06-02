---
name: workspace-governance
description: AI Workspace Governance - 管理 AI 生成项目的生命周期，包括项目元数据、Git、部署、技术栈和代码风格
version: 1.1.0
author: openclaw
tags:
  - workspace
  - governance
  - project-management
  - lifecycle
---

# Workspace Governance Skill

## 概述

本 Skill 用于管理 AI 生成项目的完整生命周期，提供统一的项目初始化、配置管理和上下文加载能力。

## 何时使用

- 创建新的 AI 项目时
- 管理多个项目的元数据和配置时
- 加载项目上下文供 AI Agent 使用时
- 初始化工作区环境时

## 核心功能

### 1. 项目初始化

通过 `create-project.sh` 脚本自动完成：

```bash
# 创建新项目
~/.openclaw/skills/workspace-governance/scripts/create-project.sh <project-name> [options]

# 示例
create-project harmony-chat --description "HarmonyOS IM 项目" --tech react,vite
```

自动执行：
- 创建项目目录结构
- 初始化 Git 仓库
- 生成 README.md、CLAW.md、CLAUDE.md
- 注册到 projects.yaml
- 初始化 deployment 配置
- 生成 .editorconfig 和 .prettierrc

### 2. 工作区初始化

首次使用时执行：

```bash
~/.openclaw/skills/workspace-governance/scripts/init-workspace.sh
```

创建结构：
```
~/workspace/
├── projects/      # 项目源码
├── registry/      # 项目注册表
├── templates/     # 模板文件
└── .ai/           # AI 相关配置
```

### 3. 项目上下文加载

为 AI Agent 提供项目上下文：

```bash
~/.openclaw/skills/workspace-governance/scripts/load-project-context.sh <project-name>
```

输出包含：
- 项目基本信息
- 技术栈配置
- 代码风格规范
- 部署信息
- Git 配置

## Registry 管理规则

### projects.yaml 结构

```yaml
projects:
  <project-name>:
    description: 项目描述
    created: YYYY-MM-DD
    updated: YYYY-MM-DD
    status: active | archived

    # 项目组关联（重要！）
    group: <group-name>        # 同属一个大项目的子项目共享此字段
    role: <role>                # 子项目角色（见下方角色列表）

    paths:
      source: ~/workspace/projects/<project-name>

    git:
      remote: git@github.com:<org>/<repo>.git
      branch: main

    deployment:
      production:
        host: <ip-or-domain>
        port: <port>
        service: <systemd-service-name>
        status: active

    tech:
      frontend:
        - react
        - vite
      backend:
        - node
        - express
      database:
        - postgresql
      mobile:
        - kotlin
        - jetpack-compose
      desktop:
        - swift

    ai:
      primary: openclaw
      coding: claude-code

    style:
      code: airbnb
      naming: camelCase
```

### 更新规则

1. **创建项目时**：自动添加到 registry
2. **删除项目时**：从 registry 移除（保留记录标记为 archived）
3. **修改配置时**：更新对应字段并记录 updated 时间

### 项目组（Group）规则

一个大项目可能包含多个子项目（前端、后端、移动端等）。通过 `group` 字段关联：

**group 命名规范：**
- 使用项目英文名，如 `game-activities`、`family-tree`
- 独立项目（无子项目）设为 `null` 或省略

**role 角色列表：**

| role | 说明 | 示例 |
|------|------|------|
| `tool` | 独立工具 | hdc-manager |
| `fullstack` | 前后端一体 | family-tree |
| `frontend-admin` | 管理后台前端 | game-activities-admin |
| `backend-admin` | 管理端 API | game-activities-admin-backend |
| `backend-app` | 用户端 API | game-activities-app-backend |
| `mobile-android` | Android App | game-activities-android |
| `mobile-harmony` | 鸿蒙 App | game-activities-harmony |
| `mobile-ios` | iOS App | - |
| `desktop` | 桌面端 | - |

**查询项目组：**
```yaml
# 查找 group: game-activities 的所有子项目
game-activities-admin-backend  # group: game-activities, role: backend-admin
game-activities-app-backend    # group: game-activities, role: backend-app
game-activities-admin          # group: game-activities, role: frontend-admin
game-activities-android        # group: game-activities, role: mobile-android
game-activities-harmony       # group: game-activities, role: mobile-harmony
```

## AI 声明文件规则

### CLAW.md 规范

CLAW.md 是 OpenClaw 专用的项目声明文件，必须包含：

1. **项目描述**：简明扼要的项目说明
2. **技术栈**：前端、后端、数据库等
3. **代码风格**：遵循的编码规范
4. **命名规范**：变量、函数、类的命名规则
5. **Hook 规范**：生命周期钩子使用规范
6. **API 规范**：接口设计规范
7. **Git commit 规范**：提交信息格式
8. **Agent 职责**：AI Agent 的职责范围

### CLAUDE.md 规范

CLAUDE.md 是 Claude Code 专用配置，包含：

1. **角色设定**：当前 Agent 的身份
2. **Skill 限制**：可用的 Skill 列表
3. **工作准则**：开发规范和约束
4. **上下文信息**：项目相关的上下文

## 项目上下文加载规则

### 加载顺序

1. 读取 `projects.yaml` 获取项目基本信息
2. 读取项目目录下的 `CLAW.md`
3. 读取项目目录下的 `CLAUDE.md`
4. 组合生成完整的 prompt context

### 上下文结构

```markdown
# 项目上下文

## 基本信息
- 项目名称：xxx
- 描述：xxx
- 创建时间：xxx

## 技术栈
- 前端：xxx
- 后端：xxx
- 数据库：xxx

## 代码规范
- 风格：xxx
- 命名：xxx

## 部署信息
- 生产环境：xxx
- 测试环境：xxx

## AI 配置
- 主要工具：xxx
- 辅助工具：xxx
```

## 使用示例

### 创建新项目

```bash
# 基础创建
create-project my-app

# 带参数创建
create-project my-app \
  --description "我的应用" \
  --tech react,vite,node \
  --style airbnb \
  --git git@github.com:org/repo.git
```

### 加载项目上下文

```bash
# 加载项目上下文到 AI Agent
load-project-context my-app

# 输出会自动注入到 Agent 的 prompt 中
```

### 管理项目

```bash
# 列出所有项目
list-projects

# 查看项目详情
show-project my-app

# 归档项目
archive-project my-app
```

## 目录结构

```
~/.openclaw/skills/workspace-governance/
├── SKILL.md                    # 本文件
├── templates/
│   ├── CLAW.md.template       # CLAW.md 模板
│   ├── CLAUDE.md.template     # CLAUDE.md 模板
│   └── PROJECT.yaml.template  # 项目配置模板
├── scripts/
│   ├── init-workspace.sh      # 初始化工作区
│   ├── create-project.sh      # 创建项目
│   └── load-project-context.sh # 加载项目上下文
└── registry/
    └── projects.yaml          # 项目注册表
```
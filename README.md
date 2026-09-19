# Unzeit

一套简洁、模态（modal）的个人 Emacs 配置。暗色，只用一个强调色（红），几乎全部
用 Emacs 自带能力搭起来，没有框架。

## 特性

- **模态编辑** —— [meow](https://github.com/meow-edit/meow)，`SPC` 是 leader
- **补全栈** —— corfu + cape（缓冲内）、vertico + consult + embark + marginalia
  + orderless（minibuffer）、yasnippet
- **IDE 层** —— eglot + tree-sitter + apheleia。覆盖 C/C++、Java、Rust、Go、
  Python、Ruby、TypeScript/JavaScript、CSS、HTML、Lua、CMake、Meson、JSON、
  YAML、TOML，外加 Odin、C3、Simp
- **光标动画** —— 手写的拖尾与跳跃脉冲（`lisp/unzeit-cursor.el`，纯 Elisp，
  无依赖）
- **自制主屏** —— `*dashboard*`，nano 式布局
- **专注写作模式** —— `SPC o w`
- **自制模式行** —— 缓冲 / 编码 / 大小 / 字数 / LSP / VC / 缩放 / 时钟

## 目录结构

```
early-init.el            启动优化（GC、file handlers、第一帧形状）
init.el                  加载顺序编排，也是本配置的说明书
lisp/
  init-package.el        包管理：镜像测速 + use-package
  unzeit-theme.el        主题：单一红色强调的暗色高对比调色板
  core.el                基础层：默认值、界面、字体、光标、dired/project、magit
  unzeit-cursor.el       光标动画：拖尾 + 跳跃脉冲
  init-dashboard.el      主屏
  editor.el              meow 编辑 + SPC leader + 模式行
  completion.el          补全栈
  init-eglot.el          tree-sitter + eglot + apheleia
  init-org.el            org
  unzeit-writer.el       专注写作模式
  init-misc.el           杂项：editorconfig、缩进猜测、hl-todo…
  init-local.el          本机私有配置（模板）
```

## 按键

`SPC` 是 leader（meow normal / motion 态），which-key 会提示下一层。

| 键       | 作用                          | 键       | 作用                |
| -------- | ----------------------------- | -------- | ------------------- |
| `SPC h`  | 主屏                          | `SPC o`  | org / 日程 / 写作   |
| `SPC f`  | 文件 / 最近 / Dired / ripgrep | `SPC g`  | Git（magit）        |
| `SPC p`  | 项目                          | `SPC l`  | LSP / xref / 格式化 |
| `SPC s`  | 搜索                          | `SPC b`  | 缓冲                |
| `SPC w`  | 窗口                          | `SPC t`  | eshell              |
| `SPC T`  | 标签 / 工作区                 | `SPC q`  | 保存并退出          |

## 环境要求

- **Emacs 30 或更高**（在 30.2 上开发）
- **字体**：Iosevka Term、Sarasa Term SC、Maple Mono NF CN、Noto Color Emoji。
  Emacs 不读 fontconfig，中文与图标回退要在 `core.el` 里用 fontset 显式设置
- **ripgrep**：`consult-ripgrep` 用
- **xsel**：X11 剪贴板桥（可选，没有会自动降级）
- 语言服务器与 C 工具链由系统或版本管理器提供，不走包管理

## 安装

```sh
git clone https://codeberg.org/Lofi_Concrete/Unzeit-Emacs.git ~/.emacs.d
```

也可以把仓库放在任意位置、加入 `load-path` 后加载 `init.el`。

`lisp/init-local.el` 是机器本地配置，不随部署走，私有设置写在这里，不会被覆盖。

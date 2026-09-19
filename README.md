# Unzeit

个人 Emacs 配置：模态编辑（meow，`SPC` 是 leader），暗色，只用一个强调色；除了
少量轻量插件外全部用 Emacs 自带能力搭起来，没有框架。

语言覆盖 C/C++、Rust、Go、Python、Ruby、TypeScript/JavaScript、Haskell、Zig、
Lua、HTML/CSS 等，走 eglot + tree-sitter。

## 特性

- **模态编辑** —— meow，`SPC` 是 leader
- **补全** —— corfu + cape（缓冲内），vertico + consult + embark + marginalia +
  orderless（minibuffer）
- **IDE** —— eglot + tree-sitter + apheleia
- **自制** —— 主屏 `*dashboard*`、模式行、光标动画（拖尾 + 跳跃脉冲）、专注写作模式
- **主题** —— 单一红色强调的暗色高对比，语法高亮靠字重与字形分层，不用多色

## 环境要求

- Emacs 30 或更高
- 字体：Iosevka Term（拉丁）、Sarasa Term SC（中文）、Maple Mono NF CN（图标）
- `ripgrep`；`xsel`（X11 剪贴板，可选）

## 安装

```sh
git clone https://codeberg.org/Lofi_Concrete/Unzeit-Emacs.git ~/.emacs.d
```

首次启动会自动安装第三方包。

## 定制

机器私有设置写在 `lisp/init-local.el`，不会被覆盖。主题在
`lisp/unzeit-theme.el`，字体与界面在 `lisp/core.el`。

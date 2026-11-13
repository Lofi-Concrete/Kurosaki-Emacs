# Kurosaki-emacs

[English](README.md) | **简体中文**

![Kurosaki-emacs](images/emacs-logo.png)

## 目录

- [简介](#简介)
- [主屏](#主屏)
- [特性](#特性)
- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [更新](#更新)
- [定制](#定制)
- [快捷键](#快捷键)
- [截图](#截图)
- [AI 声明](#ai-声明)
- [致谢](#致谢)
- [许可证](#许可证)

## 简介

Kurosaki-emacs 是一套个人使用的 Emacs 配置，主要面向 Guix System 和 Wayland。
它围绕 meow、vertico 与 corfu/consult、eglot 与 tree-sitter、org-roam、magit，
以及克制的 Tokyo Night 界面构建。

它不是通用 starter kit，而是我每天实际使用的那份配置。单独放在一个仓库里，
方便不拉取整套 Guix home 配置也能 clone 下来使用。

内部命名空间仍保留 `unzeit/`（历史原因），项目名是 Kurosaki-emacs。

## 主屏

![Dashboard](images/dashboard.png)

主屏显示最近文件、项目、随机引言和 leader 键提示。which-key、vertico 和
transient 弹层都使用居中的 child frame。

## 特性

- meow 模态编辑：normal 和 motion 态 `SPC` 是 leader；`C-c` 是不依赖状态的
  自定义前缀。
- 现代补全：vertico、orderless、marginalia、consult 和 embark，corfu、cape 和
  yasnippet，居中的 child-frame 弹层，consult 扩展，以及 wgrep、link-hint、
  browse-kill-ring 等编辑增强。
- LSP 与 tree-sitter：eglot、tree-sitter 和 apheleia 提供补全、诊断和格式化；
  缺少 server 时只降级，不报错。
- 多语言：C/C++、Go、Python、Rust、Java、JavaScript/TypeScript、Web/JSP、
  Zig、Haskell、C3、Odin、Ruby、Lua、Dart、Julia、PHP、Scala、Swift、
  PowerShell、CMake、CSV、Fish、Protobuf、SCSS、RON、Markdown。
- 文件树：`SPC f t/T` 是 treemacs；`SPC f v/V` 是原有的 dirvish-side；
  dired 与 dirvish 辅助保留。
- Git：magit、magit-todos、git-timemachine、browse-at-remote、git-messenger
  和 git-modes；`SPC g` 是 git 前缀。
- 笔记：org、org-roam 和 org-roam-ui；roam 数据库使用 Emacs 31 内置 SQLite，
  不需要外部 sqlite3。
- 界面：Tokyo Night 主题、Maple Mono NF CN、dashboard、居中的 which-key、
  transient 和 vertico 弹层、ultra-scroll、solaire-mode、行尾诊断 chip，以及
  eldoc-mouse 光标停留弹窗。
- Guix 集成：emacs-guix、guix-devel-mode、build log 高亮、store 路径美化。
- 中文优先：中文字体集、拼音搜索、CJK 标点与间距。

## 前置要求

### 操作系统

- Guix System 是主要目标。home 模块在 `home/editor/editor.scm` 和
  `home/lang/lang.scm`。
- Linux 和 Wayland 是测试过的显示环境（niri 和 Noctalia）。
- 独立使用时，任何带 pgtk 的 Emacs 31.1 都可以。pgtk 是原生 Wayland 剪贴板和
  child-frame 行为所必需的。

### GNU Emacs

需要 GNU Emacs 31.1 或更新版本。配置依赖：

- 原生 tree-sitter（treesit）
- 原生 JSON 与 SQLite
- pgtk 与 Wayland
- libgccjit 用于原生编译，可选但推荐

### 字体

- Maple Mono NF CN：正文、中文和 Nerd 图标
- LXGW WenKai Mono：org 写作
- Noto Color Emoji：emoji

### 外部工具

配置在缺少这些工具时会降级，但完整体验需要：

- language server：clangd、gopls、rust-analyzer、zls、hls、solargraph、
  lua-language-server、typescript-language-server、vscode-html-language-server
  和 vscode-css-language-server
- formatter：clang-format、gofmt 或 gofumpt、rustfmt、zig fmt 和 prettier
- Guix profile 里的 tree-sitter 语法

## 快速开始

### Guix Home

本配置以 git submodule 形式被 Guix home 仓库消费：

```sh
git clone ssh://git@codeberg.org/Lofi_Concrete/lc-guix-home-manager.git ~/guix
git -C ~/guix submodule update --init --recursive
guix home reconfigure ~/guix/home/home.scm \
  --load-path="$HOME/Projects/lc-guix-channels/guix" --fallback
```

`--load-path` 是必需的，因为 home 配置会导入 lc-guix 渠道里的包。
submodule 位于 `home/editor/.emacs.d`。

### 独立使用

不经过 Guix home，直接使用 Emacs 配置：

```sh
mv ~/.emacs.d ~/.emacs.d.bak
git clone <Kurosaki-emacs-url> ~/.emacs.d
~/.emacs.d/tests/preinstall-modern.sh
~/.emacs.d/tests/preinstall-features.sh
cp ~/.emacs.d/lisp/init-local.example.el ~/.emacs.d/lisp/init-local.el
```

然后安装上面的字体与外部工具。启动 Emacs；首次启动会测速 ELPA 镜像并补齐缺失的包。

### 首次启动

- 包镜像在后台测速；关键启动路径上不发网络请求。
- `M-x unzeit/doctor` 会打印健康报告：字体、language server、tree-sitter 语法、
  包状态和当前配置。
- 如果觉得配置没生效：Guix 模式下 `~/.emacs.d` 是 store 部署出来的软链；改仓库后
  要 `guix home reconfigure` 再重启 Emacs。

## 更新

独立使用：

```sh
git -C ~/.emacs.d pull --ff-only
emacs --batch -Q --eval '(progn (package-initialize) (package-quickstart-refresh))'
```

Guix home：

```sh
git -C ~/guix submodule update --remote --merge
guix home reconfigure ~/guix/home/home.scm \
  --load-path="$HOME/Projects/lc-guix-channels/guix" --fallback
```

reconfigure 之后重启 Emacs；正在运行的实例仍然持有旧 store。

## 定制

- `unzeit/modern-*`：现代层的开关（滚动、GC、posframe、vertico-posframe、
  solaire、诊断）。`M-x customize-group unzeit/modern`。
- `init-local.el`：机器本地覆盖，Guix 不会部署。从
  `lisp/init-local.example.el` 复制后修改。
- 字体：`lisp/core.el` 里的 `unzeit/body-font-height` 和
  `unzeit/ui-font-height`；`early-init.el` 里的 frame 字体串。
- 语言：每种语言一个文件放在 `langs/`；新增 `.el` 会自动加载。
- 主题：固定 Tokyo Night 调色板，在 `lisp/unzeit-theme.el`。

## 快捷键

`SPC` 是 meow normal 和 motion 态的 leader；`C-c` 提供同样的自定义命令，但不依赖状态。

| 键 | 作用 |
|-----|------|
| `SPC f t` / `SPC f T` | treemacs 开关 / 聚焦 |
| `SPC f v` / `SPC f V` | dirvish-side 开关 / 聚焦 |
| `SPC f f` / `SPC f s` / `SPC f o` | 打开文件 / 保存 / 另一窗口 |
| `SPC f e` | consult-dir |
| `SPC s s` / `SPC s g` | consult-line / consult-ripgrep |
| `SPC s y` / `SPC s T` / `SPC s F` | consult-yasnippet / todo / flyspell |
| `SPC g s` / `SPC g l` / `SPC g d` | magit status / log / diff |
| `SPC g T` / `SPC g t` / `SPC g o` / `SPC g m` | magit-todos / timemachine / browse-at-remote / git-messenger |
| `SPC o r` / `SPC o i` / `SPC o b` | org-roam node-find / insert / buffer-toggle |
| `SPC o d` / `SPC o u` | org-roam dailies / org-roam-ui |
| `SPC o a` / `SPC o c` | org-agenda / org-capture |
| `SPC l d` / `SPC l r` / `SPC l o` | xref 定义 / 引用 / link-hint |
| `SPC y` | browse-kill-ring |
| `SPC c g` | Guix 包 / 世代 / 服务 |
| `SPC ?` | 帮助命令 |
| `C-c t` / `C-c v` | treemacs / dirvish-side |
| `C-c a` / `C-c c` | org-agenda / org-capture |
| `C-c g` | Guix 弹层 |

## 截图

which-key 弹层：

![Which-key](images/which-key.png)

vertico 补全：

![Vertico](images/vertico.png)

主屏截图见本 README 顶部。

## AI 声明

本项目是 AI 辅助完成的。部分 Emacs Lisp 模块、语言文件、文档和本 README 是在
AI 编程助手（DeepSeek Harness，DeepSeek 模型驱动）的协助下生成或修改的。人类
维护者负责审查、测试并对配置负责。AI 生成内容可能不完整或有误，请自行评估风险。

完整声明见 [AI-DECLARATION.md](AI-DECLARATION.md)。

## 致谢

- Centaur Emacs（https://github.com/seagle0128/.emacs.d）：README 版式与部分
  UI 思路的来源。
- Emacs、Guix、meow、vertico、corfu、consult、embark、eglot、magit、org-roam
  社区。
- Maple Mono、LXGW WenKai 和 Tokyo Night 主题。

## 许可证

GPL-3.0。见 [LICENSE](LICENSE) 或 https://www.gnu.org/licenses/gpl-3.0。

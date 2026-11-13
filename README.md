# Unzeit Emacs（独立仓库）

这是 Unzeit 的独立 Emacs 配置仓库，**不依赖 `~/guix`**。clone 到 `~/.emacs.d` 即可使用。

## 快速开始

```sh
git clone <this-repo> ~/.emacs.d
```

- 字体：正文/中文 `Maple Mono NF CN`，org 写作 `LXGW WenKai Mono`，emoji `Noto Color Emoji`。
- 首次启动会测速 ELPA 镜像；也可以先跑 `tests/preinstall-modern.sh`。
- 机器本地配置：`cp lisp/init-local.example.el lisp/init-local.el`。
- 健康检查：`M-x unzeit/doctor`。
- 外部工具（clangd/gopls/rust-analyzer/zls、tree-sitter 语法等）见 `docs/操作手册.org`。

# Unzeit

我的 Emacs 配置：meow 模态编辑（`SPC` 是 leader，normal/motion 态），
同时保留 `C-c` 这套不依赖状态的自定义命令；eglot + tree-sitter 给补全与诊断，
主题固定 Tokyo Night（doom 自带 `doom-tokyo-night`，不跟桌面壁纸取色）。
正文字体 Maple Mono NF CN 13pt（与 Ghostty 的 `font-size = 13` 对齐），
中文也用 Maple Mono NF CN，org 用 LXGW WenKai Mono，Nerd 图标同 Maple。
窗口不透明（不做 `alpha-background`）；行号只在代码/配置缓冲开启，绝对号、宽度自适应
（Centaur 方案；原因见 core.el 的「行号」一节），全局当前行高亮用 `C-c H` 开关。
除少量轻量插件外都用 Emacs 自带能力搭。

- meow：`ESC` 回 normal，`i`/`a` 进 insert，`SPC` 是 leader；`SPC m ?` 是速查表。
- 原生键：`C-x C-f` 开文件、`C-x C-s` 保存、`C-x b` 切缓冲、`C-x p` 项目、`C-x g` Git。
- 自定义键：`C-c` 前缀（文件树、体检、eshell、AI、Java、Guix 等），全表见 `docs/操作手册.org`。
- 标签栏图标保留 nerd-icons 的彩色 face；dirvish 侧栏按文件名自适应 20–32 列。
- 现代化层（Centaur 风格）：`ultra-scroll` 像素滚动、which-key/transient 的 childframe、
  minibuffer 候选在屏幕中央的 `vertico-posframe` childframe 里、
  `solaire-mode` 变暗非文件缓冲、corfu 2 字符/0.15 秒、flymake 0.15 秒 + flyover 内联诊断、
  Emacs 31 的 `treesit-enabled-modes`（语法仍由 Guix profile 预装）；开关都在
  `lisp/unzeit-modern.el`，`init-local.el` 可逐项回退。

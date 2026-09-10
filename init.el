;;; init.el --- Unzeit: a monochrome, modal Emacs -*- lexical-binding: t; -*-

;;; Commentary:

;; Unzeit — 简洁、模块化、可维护的个人 Emacs 配置
;;
;; 设计原则:
;;   Emacs 原生功能 > 轻量成熟插件 > 自己写 glue code > 大型框架
;;
;; 视觉体系:
;;   配色直接照抄 nano-emacs 的 nano-theme-dark (Nord): 雪白信息 +
;;   琥珀色动作强调 (光标/选区/搜索/快捷键), 红色只留给错误与危险,
;;   青蓝用于链接/关键字/类型全部常量见 unzeit-theme.el
;;
;; 使用方式 (以 GUI 实例为主, 实例自带 server):
;;   emacs                         ; 启动 GUI 实例 (日常主力)
;;   emc                           ; 在当前终端开 TTY 帧 (无参数时显示 Dashboard)
;;   emacsclient -c                ; 再开一个 GUI 帧
;;   emacsclient -t                ; 在终端中打开会话
;;   emacsclient -e '(...)'        ; 执行一段 elisp
;;   emacsclient -e '(kill-emacs)' ; 关掉当前 server (改配置后靠它重启, 再重新 emacs)
;;
;; core.el 在非 daemon 时执行 server-start, 所以这个 GUI 实例本身就是 server,
;; 上面几条 emacsclient 都接到它上面, 不会另起进程; 单实例下 SPC q 与 C-x C-c
;; 都是退出整个 Emacs (只关帧用 C-x 5 0)。dwm autostart 仍兜底: 登录时若没有
;; 任何 server 在响应, 才 emacs --daemon。
;;
;; 按键:
;;   SPC   = leader 前缀 (meow normal/motion 态), which-key 提示下一层
;;   SPC h = Unzeit Dashboard (主页底部有操作手册入口提示)
;;   SPC c c = 编辑本配置;  SPC m ? = meow 速查表;  SPC m t = meow 教程
;;   SPC o m = 操作手册 (org, 主页也提示此键);  SPC o w = 专注写作模式
;;   SPC f d = Dired
;;
;; 配置文件结构:
;;   early-init.el   启动优化 (GC / file handlers / 首帧)
;;   init.el         加载顺序编排 (本文件)
;;   lisp/core.el           基础: 常量/核心默认/界面/文件/剪贴板 (const+base+ui+files+vc+clipboard 合并)
;;   lisp/init-package.el   包管理 (镜像测速 + 归档新鲜度 + use-package)
;;   lisp/unzeit-theme.el   主题: nano-emacs 暗色 (Nord) 调色板
;;   lisp/init-dashboard.el     dashboard 插件 (MELPA) 主屏 (nano 式布局)
;;   lisp/editor.el         meow 编辑 + SPC leader + mode line (meow+modeline 合并)
;;   lisp/completion.el     补全栈: corfu/cape + vertico/consult (corfu+completion 合并)
;;   lisp/init-eglot.el     eglot/treesit/apheleia + 语言
;;   lisp/init-org.el       org 最小配置
;;   lisp/unzeit-writer.el  专注写作模式 (nano-writer 风格)
;;   lisp/init-misc.el      其他 (editorconfig/ws-butler/hl-todo/...)
;;   lisp/init-local.el     个人私有配置 (机器本地, 不随 guix 部署)
;;
;; 注意: 本仓库的文件经由 guix home 以只读 store 链接部署到
;; ~/.emacs.d/不要直接在 ~/.emacs.d/ 下编辑;
;; 修改 emacs/ 目录后执行 `guix home reconfigure'

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; 包管理 / use-package 引导 (不依赖 unzeit 常量)
(require 'init-package)

;; 主题加载优先级最高: 面 (faces) 要先于 modeline/dashboard 使用
(add-to-list 'custom-theme-load-path (expand-file-name "lisp" user-emacs-directory))
(require 'unzeit-theme)
(load-theme 'unzeit t)

;; 基础层: 常量、核心编辑默认、界面、dired/project、git、X11 剪贴板
(require 'core)
;; 主屏依赖主题面 + 基础层
(require 'init-dashboard)
;; modal 编辑 (meow) + 自制 mode line; meow 必须先于下方程补全 (corfu 用到 meow keymap)
(require 'editor)
;; 补全栈: corfu/cape 缓冲弹窗 + vertico/consult 等 minibuffer
(require 'completion)
;; IDE 层: tree-sitter 模式 + eglot + apheleia
(require 'init-eglot)
(require 'init-org)
;; 专注写作模式 (org/text/markdown 缓冲, SPC o w 切换)
(require 'unzeit-writer)
(require 'init-misc)

;; 用户私有配置, 最后加载, 可覆盖一切文件位于机器本地
;; ~/.emacs.d/lisp/init-local.el (不在仓库中, 不随 guix 部署)
(require 'init-local nil t)

(provide 'init)
;;; init.el ends here

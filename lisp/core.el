;;; core.el --- Unzeit: 基础层（常量、基础行为、界面、文件、剪贴板） -*- lexical-binding: t; -*-

;;; Commentary:
;; 由 init-const/init-base/init-ui/init-files/init-vc 与 init-clipboard 合并
;; 而来：不属于具体应用的那部分胶水 —— 路径与 Customize、核心编辑默认、
;; 字体/行号/空白符、光标动画、dired/project、magit/diff-hl，以及 X11
;; 剪贴板桥
;; 最先加载

;;; Code:



(defgroup unzeit nil
  "Unzeit：一套简洁、模态（modal）的 Emacs 配置"
  :group 'emacs
  :prefix "unzeit/")

;;; ---- 路径（Paths） ----------------------------------------------

(defconst unzeit/cache-dir
  (expand-file-name "emacs" (or (getenv "XDG_CACHE_HOME") "~/.cache"))
  "Unzeit 存放运行时状态（recentf、history、backups 等）的目录")

;; 机器本地的 Customize 状态该文件不由 Guix 部署（部署出来的是只读
;; store 链接），而是由 Emacs 自己创建并写入
(setq custom-file (expand-file-name "custom-state.el" user-emacs-directory))
(load custom-file t)

;;; ---- 杂项（Misc） ------------------------------------------------

;; 启动后恢复一个合理的 GC 阈值（见 early-init.el）
(use-package gcmh
  :ensure t
  :demand t
  :custom
  (gcmh-idle-delay 'auto)
  (gcmh-high-cons-threshold (* 64 1024 1024))
  :config
  (gcmh-mode 1))

;;; ---- 服务器（daemon / emacsclient） ------------------------------

(use-package server
  :ensure nil
  :demand t
  :config
  (unless (or (daemonp) noninteractive)
    (server-start)))

;;; ---- 基础行为 ----------------------------------------------------

(setq use-short-answers t)
(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)
(setq initial-major-mode 'fundamental-mode)
(setq ring-bell-function 'ignore)        ; 关闭铃声
(setq use-dialog-box nil)                ; 用 minibuffer 而非对话框
(setq enable-recursive-minibuffers t)
(setq auto-mode-case-fold nil)

(delete-selection-mode 1)                ; 键入覆盖选中
(electric-pair-mode 1)                   ; 自动配对括号
(global-auto-revert-mode 1)              ; 文件被外部更改时自动刷新
(winner-mode 1)                          ; 撤销窗口配置改变
(show-paren-mode 1)
(setq show-paren-delay 0)

(setq kill-ring-max 200
      kill-do-not-save-duplicates t
      save-interprogram-paste-before-kill t)
(setq mouse-yank-at-point t)

;;; ---- 滚动与重绘 --------------------------------------------------

(setq scroll-conservatively 101)         ; 平滑滚动，不跳光标
(setq scroll-margin 3)
(setq scroll-preserve-screen-position t)
(setq fast-but-imprecise-scrolling t)
(setq redisplay-skip-fontification-on-input t)
(setq jit-lock-defer-time 0)

;;; ---- 文件 --------------------------------------------------------

(setq-default fill-column 80)
(setq find-file-visit-truename t)
(setq vc-follow-symlinks t)
(setq xref-prompt-for-identifier nil)
(setq uniquify-buffer-name-style 'forward)

;; 备份与自动保存放到缓存目录，不污染源码目录
(make-directory (expand-file-name "backups" unzeit/cache-dir) t)
(make-directory (expand-file-name "autosaves" unzeit/cache-dir) t)
(setq backup-directory-alist `(("." . ,(expand-file-name "backups" unzeit/cache-dir))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "autosaves" unzeit/cache-dir) t)))
(setq auto-save-list-file-prefix
      (expand-file-name "autosaves/.saves-" unzeit/cache-dir))

;; 打开一个还不存在的文件时顺手把父目录建出来（minemacs 的
;; +create-non-existent-directory）：C-x C-f ~/org/2026/05/foo.org RET 就能
;; 直接落笔，不必先 M-x make-directory。TRAMP/远程路径必须跳过——在那边
;; 建目录既走网络，又可能落到"另一台机器"上
(defun unzeit/find-file-create-parent-dir (orig file &rest args)
  "打开不存在 FILE 时先创建其父目录，再交给 ORIG 打开。"
  (when (and (stringp file)
             (not (file-remote-p file))
             (not (file-directory-p file))
             (not (file-exists-p file)))
    (when-let* ((dir (file-name-directory file)))
      (unless (file-exists-p dir)
        (condition-case err
            (make-directory dir t)
          (error (message "Unzeit：无法创建目录 %s（%s）" dir err))))))
  (apply orig file args))

(advice-add #'find-file :around #'unzeit/find-file-create-parent-dir)

;;; ---- 历史与状态 --------------------------------------------------

;; recentf-save-file 必须在启用模式之前设置：启用 recentf 时它会在激活
;; 那一刻读取保存文件，所以如果之后才改这个变量，真正的列表（在
;; ~/.cache/emacs/recentf 中）就永远不会被加载，主屏的“最近文件”会一直
;; 是空的
(setq recentf-max-saved-items 50
      recentf-save-file (expand-file-name "recentf" unzeit/cache-dir))
(recentf-mode 1)
;; 这个 recentf 构建在模式开启时并不会读取保存文件，所以在这里显式加载
;; 一遍（并剔除已不存在的文件项，好让主屏的“最近文件”只显示真实存在的
;; 文件）
(recentf-load-list)
(recentf-cleanup)

(savehist-mode 1)
(setq savehist-file (expand-file-name "history" unzeit/cache-dir))
(add-to-list 'savehist-additional-variables 'kill-ring)

(save-place-mode 1)
(setq save-place-file (expand-file-name "places" unzeit/cache-dir))

;; 别让警告弹出到窗口里：*Warnings* 缓冲弹开会分割窗口（例如出现在主屏
;; 旁边）警告仍然会落到 *Messages* / 日志里
(setq warning-minimum-level :emergency)



;;; ---- 字体（拉丁 Iosevka Term + 中文 Sarasa Term SC） --------------
;; Emacs 不读 fontconfig；中文回退必须显式通过 fontset 做
;;
;; 拉丁 = Iosevka Term（Guix 包 font-iosevka-term，见
;;   ~/guix/home/home-config-packages.scm）；
;; 中文 = Sarasa Term SC（系统 profile 的 font-sarasa-gothic）。
;; 这两个是天生一对：Sarasa 的 Term 系拉丁底座就是 Iosevka Term，汉字正好
;; 两个半角宽，混排不需要任何缩放（故 face-font-rescale-alist 不再需要）。
;; Nerd Font 图标（私用区 PUA）两者都没有，继续由 Maple Mono NF CN 提供。
;;
;; 字号分三档（2026-09-15 用户要求）：正文 24pt、界面 18pt、标签栏 17pt。
;; `:height' 的单位是 1/10 磅，必须是整数；**浮点在这里表示「相对底层 face 的
;; 倍数」而不是磅值** —— 图标那个 1.2 就是这个坑，见 `unzeit/tab-icon-height'。
;; 正文 240 = 24pt：此前放过 37.3 / 35.3 / 25.3 三版，2026-09-15 用户定为 24。
;; 界面 180 = 18pt 是那轮放大之前的原值；标签栏**文字** `unzeit/tab-font-height'
;; = 170 比界面档再小一点点，而标签栏的**栏高**取图标高度
;; （`unzeit/tab-bar-height' = 204 = 20.4pt），图标因此不再被 header-line 裁掉。
;; 改这里时 early-init.el 的 `default-frame-alist' 字体串要一起改（正文档的
;; 磅值，取整即可）。

(defconst unzeit/body-font-height 240
  "正文 buffer 的字号（1/10 磅）：24pt。")

(defconst unzeit/ui-font-height 180
  "界面元素的字号（1/10 磅）：18pt，即正文被放大之前的原值。
界面 = mode line / minibuffer / dashboard / which-key / vertico / 提示类缓冲
这类「窗口装饰」；corfu 的缓冲弹窗不算界面 —— 它跟着正文一起大。")

(defconst unzeit/tab-font-height 170
  "标签栏里**文字**的字号（1/10 磅）：17pt，比界面档 18pt 再小一点点。
栏高另算，见 `unzeit/tab-bar-height'。")

(defconst unzeit/tab-icon-scale 1.2
  "标签图标相对标签文字的大小倍数。
图标比文字略大一点点，才顶得住标签栏的视觉高度。")

(defconst unzeit/tab-icon-height
  (round (* unzeit/tab-icon-scale unzeit/tab-font-height))
  "标签图标的**绝对**字号（1/10 磅）：204 = 20.4pt = 文字 170 的 1.2 倍。

nerd-icons 生成的图标 face 把 `:height' 写成浮点 1.2，而浮点在 Emacs 里是
「相对**底层 face** 的倍数」（`set-face-attribute' 文档原话：a scaling factor
for the underlying face height）—— 标签栏里那个底层 face 就是 header-line
本身，于是栏高一旦跟着图标长高，图标又按新栏高再放大 1.2 倍，永远追不上。
所以 `unzeit/awesome-tab-icon-for-tab' 会把图标 face 的 `:height' 改写成这个
绝对值，图标大小从此只由这一个常量决定。")

(defconst unzeit/tab-bar-height unzeit/tab-icon-height
  "标签栏（awesome-tab 画在 header-line 上的那条）的**栏高**（1/10 磅）：
204 = 20.4pt，与图标严格等高。栏里的文字仍是 `unzeit/tab-font-height'
（17pt），比栏略小 —— 栏高对齐的是图标，不是文字。")

(defconst unzeit/ui-font-ratio
  (/ (float unzeit/ui-font-height) unzeit/body-font-height)
  "界面字号相对正文字号的倍数（宽度同样按这个比例缩）。
主屏这类界面缓冲的文字按界面档渲染，但 `:align-to' 里数字的单位是**帧默认
字体**（正文）的宽度，两者差这个比例；一切按字符数算出来的居中偏移都要乘它，
否则文字会整体偏左半个宽度。")

(defconst unzeit/ui-faces
  '(;; 模式行（含自制 modeline 片段与 meow 状态块）
    mode-line mode-line-inactive mode-line-highlight mode-line-emphasis
    mode-line-buffer-id
    unzeit-modeline-buffer unzeit-modeline-modified unzeit-modeline-lsp
    unzeit-modeline-mode unzeit-modeline-muted unzeit-modeline-position
    meow-normal-indicator meow-insert-indicator meow-motion-indicator
    meow-keypad-indicator meow-beacon-indicator
    ;; 标签栏（awesome-tab）**不在这里**：它用单独一档
    ;; `unzeit/tab-font-height'（170 = 17pt，比界面档再小一点点），见下面的
    ;; `unzeit/tab-faces'。
    ;; Emacs 自带 tab-bar / tab-line（本配置不启用，留着自己开）
    tab-bar tab-bar-tab tab-bar-tab-inactive tab-bar-tab-group
    tab-bar-tab-group-current
    tab-line tab-line-tab tab-line-tab-current tab-line-tab-inactive
    ;; minibuffer（输入行本身用 face-remapping 缩，见
    ;; `unzeit/setup-minibuffer-font'）
    minibuffer-prompt minibuffer-prompt-end
    vertico-current vertico-group-title vertico-multiline
    ;; 主屏与 which-key 提示
    dashboard-text-banner dashboard-banner-logo-title dashboard-navigator
    dashboard-heading dashboard-items-face dashboard-no-items-face
    dashboard-footer-face dashboard-footer-icon-face
    unzeit-dashboard-logo unzeit-dashboard-logo-red unzeit-dashboard-key
    which-key-key-face which-key-group-description-face
    which-key-command-description-face which-key-local-map-description-face
    which-key-separator-face which-key-note-face which-key-special-key-face
    which-key-highlighted-command-face which-key-preview-face)
  "固定用 `unzeit/ui-font-height' 的界面 face。
它们不能跟 `default' 走：正文是 24pt，界面要留在 18pt。")

(defun unzeit/apply-ui-font-height ()
  "把 `unzeit/ui-faces' 的字号钉到 `unzeit/ui-font-height'。
face 由各自的包定义，还没加载到的先跳过（`facep' 为 nil），
下面的 `with-eval-after-load' 会在包加载后再补一次。"
  (dolist (face unzeit/ui-faces)
    (when (facep face)
      (set-face-attribute face nil :height unzeit/ui-font-height))))

(defconst unzeit/tab-faces
  '(awesome-tab-selected-face awesome-tab-unselected-face
    awesome-tab-selected-ace-face awesome-tab-unselected-ace-face
    awesome-tab-selected-index-face awesome-tab-unselected-index-face)
  "标签栏里**文字**用 `unzeit/tab-font-height' 的 face。
标签文字是 `awesome-tab-*-face'（自己不设 :height，否则继承 `default' 的
正文字号）。栏高不在这里 —— 栏高是 `header-line'，取图标高度
（`unzeit/tab-bar-height'），由 `unzeit/apply-tab-font-height' 一起钉。")

(defun unzeit/apply-tab-font-height ()
  "把标签栏钉死：栏高 = `unzeit/tab-bar-height'（与图标等高），文字 = `unzeit/tab-font-height'。
`awesome-tab-height' 也一起同步成栏高：`awesome-tab-adjust-color-with-theme'
（每次换主题时跑）会执行 `(set-face-attribute 'header-line nil :height
awesome-tab-height)'，不同步栏高就会被它改回去。"
  (when (facep 'header-line)
    (set-face-attribute 'header-line nil :height unzeit/tab-bar-height))
  (dolist (face unzeit/tab-faces)
    (when (facep face)
      (set-face-attribute face nil :height unzeit/tab-font-height)))
  (when (boundp 'awesome-tab-height)
    (setq awesome-tab-height unzeit/tab-bar-height)))

(defun unzeit/use-ui-font-buffer ()
  "把当前缓冲里的**所有**文字都钉到界面字号 `unzeit/ui-font-height'。

`unzeit/ui-faces' 只能管住各包自己定义了 face 的那部分文字；缓冲里没有 face
属性的文字（dashboard 的 logo 间隔空格、Recents/Projects 列表项、底部快捷键
网格的中文标签）以及只设了前景色的 face（dashboard 的 init-info 行走的是
`font-lock-comment-face'）都会落回 `default' 的 35.3pt —— 于是一个缓冲里大字
小字混排，正是主屏看起来「有的特别大有得特别小」的原因。

这里用 buffer-local 的 `face-remapping-alist' 重映射 `default'：remap 规格里
排在前面的优先，所以这条盖得住全局的正文字号；而已经显式写了 :height 的
face（`unzeit/ui-faces' 里那些，含 dashboard 自己的各 face）保持不变。"
  (setq-local face-remapping-alist
              `((default (:height ,unzeit/ui-font-height) default))))

(defun unzeit/setup-minibuffer-font ()
  "minibuffer 用界面字号（同 `unzeit/use-ui-font-buffer'）。
minibuffer 里的文字（提示、echo area、vertico/marginalia 候选）走的是
`default' 面，只能用 buffer-local 的 `face-remapping-alist' 把它压回
`unzeit/ui-font-height'。"
  (unzeit/use-ui-font-buffer))

(add-hook 'minibuffer-setup-hook #'unzeit/setup-minibuffer-font)

;; 提示 / 诊断类缓冲也整体走界面字号：*Messages*、*Help*、*Warnings*、
;; *Apropos*、*Backtrace* 这些平时是「看提示」用的，跟正文的 25.3pt 混在一起
;; 会大小参差（用户 2026-09-15 要求对齐）。它们各自派生自 special-mode，
;; 内容基本是只读文本，统一压到界面档最自然
(defconst unzeit/ui-font-modes
  '(messages-buffer-mode help-mode warning-mode apropos-mode backtrace-mode)
  "整个缓冲都用界面字号（`unzeit/ui-font-height'）的提示类 major mode。")

(dolist (unzeit/ui-font-hook
         '(messages-buffer-mode-hook help-mode-hook warning-mode-hook
                                     apropos-mode-hook backtrace-mode-hook))
  (add-hook unzeit/ui-font-hook #'unzeit/use-ui-font-buffer))

;; 钩子只管新建的缓冲；`*Messages*' 在 core.el 加载之前就建好了，得补一遍
(dolist (unzeit/ui-font-buf (buffer-list))
  (with-current-buffer unzeit/ui-font-buf
    (when (memq major-mode unzeit/ui-font-modes)
      (unzeit/use-ui-font-buffer))))

(defun unzeit/setup-fonts (&optional frame)
  "在 FRAME 上设置 Unzeit 默认字体以及中文/图标/emoji 回退字体"
  (when frame (select-frame frame))
  (set-face-attribute 'default nil
                      :family "Iosevka Term"
                      :height unzeit/body-font-height
                      :weight 'regular)
  (unzeit/apply-ui-font-height)
  (unzeit/apply-tab-font-height)
  ;; 汉字及日韩文字：Sarasa Term SC
  (dolist (charset '(han kana hangul cjk-misc bopomofo))
    (set-fontset-font t charset nil)
    (set-fontset-font t charset
                      (font-spec :family "Sarasa Term SC") nil 'prepend))
  ;; 中文标点与全角形式同样交给 Sarasa（Iosevka 里没有这些字形，
  ;; 不显式指定就会落到默认字体上渲染成豆腐块）
  (dolist (range '((#x3000 . #x303f)    ; CJK 标点
                   (#x2e80 . #x2eff)    ; CJK 部首补充
                   (#x31c0 . #x31ef)    ; CJK 笔画
                   (#xff00 . #xffef)))  ; 全角/半角形式
    (set-fontset-font t range (font-spec :family "Sarasa Term SC") nil 'prepend))
  ;; Nerd Font 图标：BMP 私用区 + 补充私用区 A/B（corfu、marginalia、
  ;; dashboard 的图标都落在这里）
  (dolist (range '((#xe000 . #xf8ff)
                   (#xf0000 . #xffffd)
                   (#x100000 . #x10fffd)))
    (set-fontset-font t range
                      (font-spec :family "Maple Mono NF CN") nil 'prepend))
  (set-fontset-font t 'symbol
                    (font-spec :family "Noto Color Emoji") nil 'append)
  (setq inhibit-compacting-font-caches t))

;; 第一帧可能已存在（daemon 客户端）；总是（重新）应用一次
(add-hook 'window-setup-hook #'unzeit/setup-fonts)
(add-hook 'after-make-frame-functions #'unzeit/setup-fonts)

;; 界面 face 由各自的包定义：包加载完再钉一次字号（core.el 加载时它们
;; 可能还不存在，`unzeit/apply-ui-font-height' 会跳过）
(dolist (unzeit/ui-lib '(dashboard vertico marginalia which-key))
  (with-eval-after-load unzeit/ui-lib #'unzeit/apply-ui-font-height))

;; 标签栏一样：awesome-tab 的 face 与 `awesome-tab-height' 都要等它加载后钉
(with-eval-after-load 'awesome-tab #'unzeit/apply-tab-font-height)

;; 换主题会让 `awesome-tab-adjust-color-with-theme' 重设 header-line 高度，
;; 主题重载后把标签栏字号再钉一遍（与光标颜色同一个时机）
(add-hook 'enable-theme-functions
          (lambda (&rest _) (unzeit/apply-tab-font-height)))

;;; ---- 光标 --------------------------------------------------------

(setq cursor-type 'box)
(setq x-stretch-cursor t)       ; 方块光标盖住整个 tab/空格单元
(blink-cursor-mode -1)
(setq cursor-in-non-selected-windows 'hollow)

;; 光标动画：移动时拖一条逐渐熄灭的尾巴，跨行跳走时在落点闪一下
;; （见 unzeit-cursor.el；SPC c a 开关，终端帧上自动静默）
(require 'unzeit-cursor)
(unzeit/cursor-mode 1)

;; 每帧都把光标颜色显式写成强调色。主题的 `cursor' face 已经有颜色，但 meow
;; 会把「当前状态光标 face 的背景色」写进帧参数 cursor-color
;; （meow--set-cursor-color），而帧参数优先级高于 face：只要哪一帧里读到过
;; 旧颜色（换主题之前建的帧、上一条配置留下的帧参数），光标就会一直停在那个
;; 旧颜色上（比如上一版强调色的棕色）。这里在建帧与换主题后各重写一遍
(defun unzeit/cursor-color ()
  "当前主题的光标颜色（唯一强调色，构成主义红）。"
  (or (and (boundp 'unzeit/accent) unzeit/accent)
      (face-background 'cursor nil t)
      "#C83B27"))

(defun unzeit/apply-cursor-color (&optional frame)
  "把 FRAME（默认当前帧）的光标颜色设成 `unzeit/cursor-color'。"
  (set-frame-parameter (or frame (selected-frame))
                       'cursor-color (unzeit/cursor-color)))

(add-hook 'after-make-frame-functions #'unzeit/apply-cursor-color)
(add-hook 'enable-theme-functions
          (lambda (&rest _)
            (dolist (frame (frame-list)) (unzeit/apply-cursor-color frame))))
(dolist (frame (frame-list)) (unzeit/apply-cursor-color frame))

;; 允许窗口被拖到只剩 2 行内容（默认下限 4 行会让辅助窗口显得臃肿，
;; 且缩不到足够小）宽度保持默认，避免并排窗口被压得过窄
(setq window-min-height 2)

;; 平滑的像素级滚动（触摸板 / 滚轮）：内容滑动而不是逐行跳Emacs 30+
;; 内置，但只作为 buffer 局部模式（该预测试没有全局化变体），因此为每个
;; 代码 / 文本缓冲开启
(dolist (hook '(prog-mode-hook text-mode-hook))
  (add-hook hook #'pixel-scroll-precision-mode))

;; 仅高亮当前行
(global-hl-line-mode 1)

;;; ---- 行号 --------------------------

(setq display-line-numbers-type 'relative)
;; 固定行号栏宽度：否则当前行的绝对行号跨 999→1000 时栏宽加一格，整
;; 个缓冲会向右抽动一格（上下移动时视觉上左右漂移）
(setq display-line-numbers-width 4)
(global-display-line-numbers-mode 1)
;; （dashboard-mode 会自行关闭 display-line-numbers，因此这里无需按 buffer
;; 排除，也不用加任何 hook/advice）

;;; ---- 空白符渲染 --------------------------------------------------
;; Tab 用浅色箭头；空格用浅色点；行尾空白与缺少收尾换行用红色标记
;; （错误就是一种“动作”）

(use-package whitespace
  :ensure nil
  :hook ((prog-mode . whitespace-mode)
         (text-mode . whitespace-mode))
  :custom
  (whitespace-style '(tabs spaces trailing space-before-tab missing-newline-at-eof))
  (whitespace-display-mappings
   '((tab-mark ?\t [?› ?\t] [?\s ?\t])
     (space-mark ?\s [?·] [?.])
     (newline-mark ?\n [?¬ ?\n] [?$ ?\n]))))

;;; ---- 其它界面 ----------------------------------------------------

(setq frame-title-format '("" (:eval (if (buffer-file-name)
                                         (abbreviate-file-name (buffer-file-name))
                                       (buffer-name)))))



;;; ---- dired ---------------------------------------------------------

(use-package dired
  :ensure nil
  :defer t
  :custom
  ;; 长格式：权限、链接数、属主、组、人类可读大小、完整时间戳
  ;;（--time-style=long-iso），目录排前在 dired 里按 "(" 可切到紧凑的
  ;; 仅名称视图
  (dired-listing-switches "-alh --group-directories-first --time-style=long-iso")
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (delete-by-moving-to-trash t)
  (wdired-allow-move-file-names t))

;; 侧边文件树（Dired 在 side window 里显示，SPC f t 切换）
(use-package dired-sidebar
  :ensure t
  :defer t
  :commands (dired-sidebar-toggle-sidebar
             dired-sidebar-show-sidebar dired-sidebar-hide-sidebar)
  :config
  (setq dired-sidebar-theme 'nerd))

;;; ---- project ------------------------------------------------------

(use-package project
  :ensure nil
  :defer t
  :custom
  (project-list-file (expand-file-name "projects" unzeit/cache-dir))
  (project-switch-commands
   '((project-find-file "查找文件")
     (project-find-dir "查找目录")
     (project-switch-to-buffer "切换缓冲")
     (project-find-dired "Dired")
     (project-vc-dir "VC 目录"))))



(use-package magit
  :ensure t
  :defer t
  :bind (("C-x g" . magit-status))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package diff-hl
  :ensure t
  :defer t
  :hook (prog-mode . diff-hl-mode))



(defun unzeit/xsel-bin ()
  "返回 `xsel' 的路径；若不可用返回 nil
优先回落 Guix home profile 的位置（经由 dwm autostart 启动的 daemon 可能
不在 PATH 上）"
  (or (executable-find "xsel")
      (let ((f (expand-file-name "~/.guix-home/profile/bin/xsel")))
        (and (file-executable-p f) f))))

(defun unzeit/clipboard-get ()
  "返回 X11 CLIPBOARD 内容（字符串），没有或不可用时返回 nil"
  (let* ((bin (unzeit/xsel-bin)))
  (if (not bin)
      nil
    (let ((default-directory "/")
          (text (shell-command-to-string
                 (concat (shell-quote-argument bin)
                         " --clipboard --output"))))
      (and (not (string-empty-p text)) text)))))

(defun unzeit/clipboard-set (text)
  "把 TEXT 写入 X11 CLIPBOARD空 TEXT 或无 xsel 时不操作"
  (let ((bin (unzeit/xsel-bin)))
    (when (and bin (stringp text) (not (string-empty-p text)))
      (let ((buf (get-buffer-create " *unzeit-xsel*")))
        (unwind-protect
            (with-current-buffer buf
              (erase-buffer)
              (insert text)
              (call-process-region (point-min) (point-max)
                                   bin nil nil nil
                                   "--clipboard" "--input"))
          (when (buffer-live-p buf) (kill-buffer buf)))))))

;;; ---- 复制：kill-new -> xsel -------------------------------------
(define-advice kill-new (:after (text &optional _replace _yank-handler) xsel-set)
  "把 TEXT 同步到 X11 CLIPBOARD
当 CLIPBOARD 已经等于 TEXT 时跳过（这正是下方 yank 时机再次 kill 时发生的
情况，避免一次多余的 xsel 写入）"
  (let ((clip (unzeit/clipboard-get)))
    (unless (and clip (string-equal text clip))
      (unzeit/clipboard-set text))))

;;; ---- 粘贴：yank <- xsel ----------------------------------------
(define-advice yank (:before (&optional _arg) xsel-pull)
  "yank 之前，确保 kill-ring 头部与 CLIPBOARD 一致，
这样外部复制的字符串才能被粘贴出来"
  (let ((clip (unzeit/clipboard-get)))
    (when (and clip (not (equal clip (car kill-ring))))
      ;; 复用 kill-new，以重置 kill-ring 指针并把字符串放到头部；
      ;; kill-new advice 里的 xsel 写入会因剪贴板已等于 CLIP 而跳过
      (kill-new clip 'replace))))

;;; core.el ends here
(provide 'core)

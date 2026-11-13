;;; core.el --- Unzeit: 基础层（常量、基础行为、界面、文件、剪贴板） -*- lexical-binding: t; -*-

(defgroup unzeit nil
  ""
  :group 'emacs
  :prefix "unzeit/")

;;; ---- 路径（Paths） ----------------------------------------------

(defconst unzeit/cache-dir
  (expand-file-name "emacs" (or (getenv "XDG_CACHE_HOME") "~/.cache")))

(defcustom unzeit/config-directory
  ;; 路径必须指向仓库源：~/.emacs.d 是只读 store 软链，改那里不生效。
  (let ((repo (expand-file-name "~/guix/home/editor/.emacs.d")))
    (if (file-directory-p repo) repo user-emacs-directory))
  "Unzeit 配置源仓库的 .emacs.d 目录（C-c e / C-c E 打开这里）。"
  :group 'unzeit
  :type 'directory)

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

;; Centaur 的做法：整场保持 1.0（heap 翻倍才 GC）；关掉则回到启动后的 0.1。
(setq gc-cons-percentage (if unzeit/modern-gc 1.0 0.1))

;;; ---- 性能（bidi 设 nil 实测比 'left-to-right 快一倍）----
(setq-default bidi-display-reordering nil)
(setq bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)
(setq fast-but-imprecise-scrolling t)
(setq inhibit-compacting-font-caches t)
(setq redisplay-skip-fontification-on-input t)
(when (boundp 'pgtk-wait-for-event-timeout)
  (setq pgtk-wait-for-event-timeout 0.001))

;; LSP 读大块 4MB；子进程走管道不给 pty（Doom 默认）。
(setq read-process-output-max (* 4 1024 1024))
(setq process-connection-type nil)
;; 不生成锁文件：少一次 I/O，也免掉 .#foo 的 "Break the lock?" 提示。
(setq create-lockfiles nil)
;; 超长行自动切 so-long（Doom 默认开）。
(when (fboundp 'global-so-long-mode)
  (global-so-long-mode 1))
;; native-comp 警告不往 echo area 挤。
(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

;; native-comp 并行压到 2：默认 0 = 核数一半，本机 4 个编译器会把整机打满。
(setq native-comp-async-jobs-number 2)

;; 不在启动时原生编译：缺 .eln 直接用 .elc，避免重建缓存把 CPU 占满。
(setq native-comp-jit-compilation nil)

;;; ---- 服务器（daemon / emacsclient） ------------------------------

(use-package server
  :ensure nil
  :demand t
  :config
  ;; server-start 失败不能拖垮启动（socket 不可用时它会 signal error）。
  (unless (or (daemonp) noninteractive)
    (condition-case err
        (server-start)
      (error (message "Unzeit: server-start 失败（%s），继续启动" err)))))

;;; ---- 基础行为 ----------------------------------------------------

(setq use-short-answers t)
(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)
(setq initial-major-mode 'fundamental-mode)
(setq ring-bell-function 'ignore)        ; 关闭铃声
(setq use-dialog-box nil)                ; 用 minibuffer 而非对话框
(setq enable-recursive-minibuffers t)
(setq auto-mode-case-fold nil)
(setq select-enable-clipboard t)         ; 原生剪贴板；不再调用 wl-copy/xsel

(setq vc-handled-backends '(Git))
(setq ffap-machine-p-known 'reject)
(setq window-combination-resize t)
(setq sentence-end-double-space nil)
;; 中文写作：句末按 。！？ 断句（Centaur 同款）。
(setq sentence-end "\\([。！？]\\|……\\|[.?!][]\"')}]*\\($\\|[ \t]\\)\\)[ \t\n]*")
(setq switch-to-buffer-obey-display-actions t)
(repeat-mode 1)
(when (fboundp 'kill-ring-deindent-mode)
  (kill-ring-deindent-mode 1))

;; Centaur 的编辑默认：逻辑行移动、EOL 跟踪、C-k 带换行、C-SPC 重复弹栈。
(setq kill-whole-line t
      line-move-visual nil
      track-eol t
      set-mark-command-repeat-pop t)
;; 删除进系统回收站（Centaur 全局；此前只在 dired 里设）。
(setq delete-by-moving-to-trash t)

(delete-selection-mode 1)                ; 键入覆盖选中
(electric-pair-mode 1)                   ; 自动配对括号
(global-auto-revert-mode 1)              ; 文件被外部更改时自动刷新
(setq auto-revert-avoid-polling t)
(winner-mode 1)                          ; 撤销窗口配置改变
(setq winner-boring-buffers
      '("*Completions*" "*Compile-Log*" "*inferior-lisp*"
        "*Fuzzy Completions*" "*Apropos*" "*Help*" "*cvs*"
        "*Buffer List*" "*Ibuffer*" "*esh command on file*"))
(show-paren-mode 1)

;; 当前行高亮（Centaur）：dashboard / term / help 里关掉。
(defun unzeit/hl-line-off ()
  "在不需要当前行高亮的 buffer 里关掉 hl-line。"
  (hl-line-mode -1))
(when unzeit/modern-hl-line
  (global-hl-line-mode 1)
  (dolist (hook '(dashboard-mode-hook term-mode-hook vterm-mode-hook
                                      help-mode-hook completion-list-mode-hook))
    (add-hook hook #'unzeit/hl-line-off)))

;; 全 frame 缩放（Centaur）：s-= / s-- / s-0；buffer 级仍用 SPC z。
(use-package default-text-scale
  :ensure t
  :demand t
  :config (default-text-scale-mode 1)
  :bind (:map default-text-scale-mode-map
          ("s-=" . default-text-scale-increase)
          ("s--" . default-text-scale-decrease)
          ("s-0" . default-text-scale-reset)))

;; 括号滚出屏幕时在 echo area 提示上下文。
(setq show-paren-context-when-offscreen t)

;; 连字：Maple Mono NF CN 自带这些组合，渲染成单个符号（不改文本，只改显示）
(use-package ligature
  :ensure t
  :demand t
  :config
  (ligature-set-ligatures 'prog-mode
                          '("->" "->>" "=>" "==>" "<=" ">=" "==" "==="
                            "!=" "!==" "&&" "||" "::" "..." "/*" "*/"
                            "|>" "<|" "<-" "-->" "<--" "<=>"
                            "++" "+=" "-=" "*=" "/=" "?." "??"))
  (global-ligature-mode 1))

;; 分屏之间 1px 细分隔线（颜色由主题的 window-divider 决定）
(setq window-divider-default-places (if unzeit/modern-dividers t 'right-only)
      window-divider-default-bottom-width 1
      window-divider-default-right-width 1)
(window-divider-mode 1)

;; 行距比默认松一点点，长代码更好读
(setq-default line-spacing 0.12)
(setq show-paren-delay 0.1)

(setq kill-ring-max 200
      kill-do-not-save-duplicates t
      save-interprogram-paste-before-kill t)
(setq mouse-yank-at-point t)

;;; ---- 滚动与重绘 --------------------------------------------------

;; Centaur 方案：ultra-scroll 的像素平滑滚动；无 GUI 时退回行滚动。
(when unzeit/modern-scroll
  (use-package ultra-scroll
    :ensure t
    :demand t
    :custom
    (scroll-conservatively 3)
    (scroll-margin 0)
    :config
    ;; init 时可能还没有 GUI 帧；等 window-setup 再开。
    (defun unzeit/enable-ultra-scroll (&rest _)
      (when (display-graphic-p)
        (ultra-scroll-mode 1)))
    (add-hook 'window-setup-hook #'unzeit/enable-ultra-scroll 'append)
    (add-hook 'after-make-frame-functions
              #'unzeit/enable-ultra-scroll 'append)))

(setq scroll-conservatively (if unzeit/modern-scroll 3 101) ; 平滑滚动，不跳光标
      scroll-margin (if unzeit/modern-scroll 0 3)
      scroll-preserve-screen-position t
      auto-window-vscroll nil
      mouse-wheel-progressive-speed nil
      mouse-wheel-scroll-amount-horizontal 1
      jit-lock-defer-time 0)

;;; ---- 文件 --------------------------------------------------------

(setq-default fill-column 80)
(setq find-file-visit-truename t)
(setq vc-follow-symlinks t)
(setq xref-prompt-for-identifier nil)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

;; xref/eglot 跳转优先复用现成窗口，再退到最近使用的窗口
(with-eval-after-load 'xref
  (add-to-list 'display-buffer-alist
               '((category . xref-jump)
                 (display-buffer-reuse-window display-buffer-use-some-window)
                 (some-window . mru))))

;; 备份与自动保存放到缓存目录，不污染源码目录
(make-directory (expand-file-name "backups" unzeit/cache-dir) t)
(make-directory (expand-file-name "autosaves" unzeit/cache-dir) t)
(setq backup-directory-alist `(("." . ,(expand-file-name "backups" unzeit/cache-dir))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "autosaves" unzeit/cache-dir) t)))
(setq auto-save-list-file-prefix
      (expand-file-name "autosaves/.saves-" unzeit/cache-dir))

(defun unzeit/find-file-create-parent-dir (orig file &rest args)
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

(setq recentf-max-saved-items 50
      recentf-save-file (expand-file-name "recentf" unzeit/cache-dir))
(recentf-mode 1)
(recentf-load-list)
(recentf-cleanup)

(savehist-mode 1)
(setq savehist-file (expand-file-name "history" unzeit/cache-dir))
(add-to-list 'savehist-additional-variables 'kill-ring)

(save-place-mode 1)
(setq save-place-file (expand-file-name "places" unzeit/cache-dir))

(setq warning-minimum-level :emergency)

;;; ---- 字体（Maple Mono NF CN；org 用 LXGW）----

(defconst unzeit/body-font-height 130)  ; Ghostty font-size = 13

(defconst unzeit/ui-font-height 120)

(defconst unzeit/ui-faces
  '(;; 模式行（自制 modeline 片段）
    mode-line mode-line-inactive mode-line-highlight mode-line-emphasis
    mode-line-buffer-id
    unzeit-modeline-buffer unzeit-modeline-modified unzeit-modeline-lsp
    unzeit-modeline-mode unzeit-modeline-muted unzeit-modeline-position
    meow-normal-indicator meow-insert-indicator meow-motion-indicator
    meow-keypad-indicator meow-beacon-indicator
    minibuffer-prompt minibuffer-prompt-end
    vertico-current vertico-group-title vertico-multiline
    ;; 主屏与 which-key 提示
    dashboard-banner-logo-title dashboard-text-banner dashboard-navigator
    dashboard-heading dashboard-items-face dashboard-no-items-face
    dashboard-footer-face dashboard-footer-icon-face
    which-key-key-face which-key-group-description-face
    which-key-command-description-face which-key-local-map-description-face
    which-key-separator-face which-key-note-face which-key-special-key-face
    which-key-highlighted-command-face which-key-preview-face))

(defun unzeit/apply-ui-font-height ()

  (dolist (face unzeit/ui-faces)
    (when (facep face)
      (set-face-attribute face nil :height unzeit/ui-font-height))))

(defun unzeit/use-ui-font-buffer ()

  (setq-local face-remapping-alist
              `((default (:height ,unzeit/ui-font-height) default))))

(defun unzeit/setup-minibuffer-font ()

  (unzeit/use-ui-font-buffer))

(add-hook 'minibuffer-setup-hook #'unzeit/setup-minibuffer-font)

(defconst unzeit/ui-font-modes
  '(messages-buffer-mode help-mode warning-mode apropos-mode backtrace-mode))

(dolist (unzeit/ui-font-hook
         '(messages-buffer-mode-hook help-mode-hook warning-mode-hook
                                     apropos-mode-hook backtrace-mode-hook))
  (add-hook unzeit/ui-font-hook #'unzeit/use-ui-font-buffer))

(dolist (unzeit/ui-font-buf (buffer-list))
  (with-current-buffer unzeit/ui-font-buf
    (when (memq major-mode unzeit/ui-font-modes)
      (unzeit/use-ui-font-buffer))))

(defun unzeit/apply-chinese-font (family)
  "把中日韩字符的 fontset 切到 FAMILY。"
  (dolist (charset '(han kana hangul cjk-misc bopomofo))
    (set-fontset-font t charset (font-spec :family family)))
  (dolist (range '((#x3000 . #x303f)
                   (#x2e80 . #x2eff)
                   (#x31c0 . #x31ef)
                   (#xff00 . #xffef)))
    (set-fontset-font t range (font-spec :family family))))

(defun unzeit/setup-fonts (&optional frame)
  (when frame (select-frame frame))
  ;; 拉丁与中文都用 Maple Mono NF CN；org 在 org-mode-hook 里切 LXGW。
  (set-face-attribute 'default nil
                      :family "Maple Mono NF CN"
                      :height unzeit/body-font-height
                      :weight 'regular)
  (unzeit/apply-ui-font-height)
  ;; 非 org 的中文也用 Maple Mono NF CN；org 在 org-mode-hook 里切 LXGW。
  (unzeit/apply-chinese-font "Maple Mono NF CN")
  (dolist (range '((#xe000 . #xf8ff)
                   (#xf0000 . #xffffd)
                   (#x100000 . #x10fffd)))
    (set-fontset-font t range
                      (font-spec :family "Maple Mono NF CN") nil 'prepend))
  (set-fontset-font t 'symbol
                    (font-spec :family "Noto Color Emoji") nil 'append))

;; 第一帧可能已存在（daemon 客户端）；总是（重新）应用一次
(add-hook 'window-setup-hook #'unzeit/setup-fonts)
(add-hook 'after-make-frame-functions #'unzeit/setup-fonts)

(dolist (unzeit/ui-lib '(dashboard vertico marginalia which-key editor))
  (with-eval-after-load unzeit/ui-lib #'unzeit/apply-ui-font-height))

;;; ---- 光标 --------------------------------------------------------

;; 光标颜色/闪烁交给主题的 cursor face，这里只管形状。
(setq cursor-type 'box)
(setq x-stretch-cursor t)       ; 方块光标盖住整个 tab/空格单元
(blink-cursor-mode 1)            ; 2026-11-08 用户要"光标会闪"，原来关着
(setq blink-cursor-interval 0.5
      blink-cursor-blinks 0)      ; 0 = 一直闪，不自动停
;; 非选中窗口不画光标：见性能节的 cursor-in-non-selected-windows。

(setq window-min-height 2)

;;; ---- 窗口不透明（alpha-background 有黑块：bug#77104）-------------

(defun unzeit/soft-wrap ()
  "长行折行（truncate-lines nil + word-wrap t），只影响显示。"
  (setq-local truncate-lines nil)
  (setq-local word-wrap t))
(dolist (hook '(prog-mode-hook text-mode-hook))
  (add-hook hook #'unzeit/soft-wrap)
  (unless unzeit/modern-scroll
    (add-hook hook #'pixel-scroll-precision-mode)))

;;; ---- 行号（Centaur 方案：只在代码/配置文件里显示，宽度自适应）----

(defcustom unzeit/line-numbers-in-prog t
  "非 nil 时 prog/conf/yaml/toml 缓冲显示行号（默认 t）。"
  :type 'boolean
  :group 'unzeit)

(setq display-line-numbers-type t)
(setq-default display-line-numbers-width 1)
(setq display-line-numbers-width-start t)

;; 统一 current-line face，保住 try_cursor_movement 快路径（移动 7.4→1.9ms，
;; 见上游 #81133/#76504）。想换回 Centaur 的当前行行号高亮就关掉这项。
(defun unzeit/line-number-faces-unify (&rest _)
  "把 line-number-current-line 扳成与 line-number 相同。"
  (let ((fg (face-attribute 'line-number :foreground nil t))
        (bg (face-attribute 'line-number :background nil t)))
    (set-face-attribute 'line-number nil
                        :foreground fg :background bg :inherit 'unspecified)
    (set-face-attribute 'line-number-current-line nil
                        :foreground fg :background bg :inherit 'unspecified)))

(when unzeit/modern-line-number-fast-path
  (unzeit/line-number-faces-unify)
  (add-hook 'enable-theme-functions #'unzeit/line-number-faces-unify))

(defun unzeit/line-numbers-on ()
  "在代码/配置文件缓冲里开行号；text/org/dired/dashboard 不开。"
  (when (and unzeit/line-numbers-in-prog
             (derived-mode-p 'prog-mode 'conf-mode
                             'yaml-mode 'yaml-ts-mode 'toml-ts-mode))
    (display-line-numbers-mode 1)))

(dolist (hook '(prog-mode-hook conf-mode-hook
                yaml-mode-hook yaml-ts-mode-hook toml-ts-mode-hook))
  (add-hook hook #'unzeit/line-numbers-on))

;;; ---- 空白符渲染 --------------------------------------------------

(use-package whitespace
  :ensure nil
  :hook ((prog-mode . whitespace-mode)
         (text-mode . whitespace-mode))
  :custom
  (whitespace-style
   '(face
     tabs tab-mark
     trailing
     space-before-tab
     space-after-tab
     missing-newline-at-eof))
  (whitespace-display-mappings
   '((tab-mark ?\t [?→ ?\t] [?\\ ?\t])
     (newline-mark ?\n [?¬ ?\n] [?$ ?\n]))))

;;; ---- 其它界面 ----------------------------------------------------

;; 当前行高亮由上面的 `unzeit/modern-hl-line` 控制（dashboard/term/help 除外）。

;; 标题按 buffer 缓存：frame-title-format 每次 redisplay 都求值，直接跑 project-current 太贵。
(defvar-local unzeit/frame-title-cache nil
  "当前缓冲的窗口标题缓存；见 `unzeit/frame-title-string'。")

(defun unzeit/frame-title-string ()
  "返回当前缓冲的窗口标题，按 buffer-local 缓存（供 `frame-title-format' 的 :eval 用）。"
  (or unzeit/frame-title-cache
      (setq unzeit/frame-title-cache
            (let* ((proj (project-current))
                   (pname (and proj (project-name proj)))
                   (name (or (and buffer-file-name
                                  (file-name-nondirectory buffer-file-name))
                             (buffer-name))))
              (if pname (format "%s — %s" name pname) name)))))

(setq frame-title-format '("" (:eval (unzeit/frame-title-string))))

;;; ---- dired ---------------------------------------------------------

(use-package dired
  :ensure nil
  :defer t
  :custom
  (dired-listing-switches "-alh --group-directories-first --time-style=long-iso")
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (delete-by-moving-to-trash t)
  (wdired-allow-move-file-names t))

(use-package dired-aux
  :ensure nil
  :after dired
  :custom
  (dired-vc-rename-file t)
  (dired-do-revert-buffer t)
  (dired-isearch-filenames 'dwim)
  (dired-create-destination-dirs 'ask)
  (dired-guess-shell-alist-user
   `((,(rx "."
           (or "mp4" "avi" "mkv" "flv" "ogv" "ogg" "mov"
               "wav" "mp3" "flac"
               "jpg" "jpeg" "png" "gif" "xpm" "svg" "bmp"
               "pdf" "md" "djvu" "ps" "eps" "doc" "docx" "xls" "xlsx" "ppt" "pptx")
           string-end)
      "xdg-open"))))

(use-package dired-x
  :ensure nil
  :after dired
  :hook (dired-mode . dired-omit-mode)
  :custom
  (dired-omit-verbose nil)
  (dired-omit-files
   (rx string-start
       (or ".DS_Store" ".cache" ".vscode" ".ccls-cache" ".clangd")
       string-end)))

(dolist (unzeit/no-line-numbers-hook '(dired-mode-hook))
  (add-hook unzeit/no-line-numbers-hook (lambda () (display-line-numbers-mode -1))))

(use-package dirvish
  :ensure t
  :demand t
  :init
  (when-let* ((dir (file-name-directory (or (locate-library "dirvish") "")))
              (ext (expand-file-name "extensions" dir))
              ((file-directory-p ext)))
    (add-to-list 'load-path ext))
  :custom
  (dirvish-attributes '(nerd-icons subtree-state))
  (dirvish-side-attributes '(nerd-icons subtree-state))
  (dirvish-hide-details t)
  (dirvish-side-width 20)
  (dirvish-side-auto-expand t)
  ;; 同一个目录复用已有会话，不每次重建
  (dirvish-reuse-session 'open)
  :config
  (require 'dirvish-side)
  (require 'dirvish-quick-access)
  ;; 全局接管 dired：dired / dired-jump / dired-noselect 都走 dirvish
  (dirvish-override-dired-mode 1)
  ;; 跟随当前缓冲所在的文件。
  (dirvish-side-follow-mode 1)
  ;; 书签式快跳（M-x dirvish-quick-access）：常用的几个根目录一键到
  (setq dirvish-quick-access-entries
        `(("h" ,(expand-file-name "~/")                    "Home")
          ("g" ,(expand-file-name "~/guix/")                "Guix 配置仓")
          ("e" ,(expand-file-name "~/guix/home/editor/.emacs.d/") "Emacs 配置")
          ("o" ,(expand-file-name "~/org/")                 "org")
          ("p" ,(expand-file-name "~/Projects/")            "Projects"))))

;;; ---- dirvish：详情列 -------------------------------------------------

(defun unzeit/dirvish-hide-details (&rest _)
  (when (derived-mode-p 'dired-mode)
    (setq-local dired-hide-details-hide-symlink-targets t
                dired-hide-details-hide-information-lines t
                truncate-lines nil)
    (dired-hide-details-mode 1)))

(advice-add 'dirvish--find-entry :after #'unzeit/dirvish-hide-details)

(defun unzeit/dirvish-subtree--apply-props (orig &rest args)

  (let ((before (copy-sequence dirvish-subtree--overlays)))
    (prog1 (apply orig args)
      (dolist (ov (seq-difference dirvish-subtree--overlays before))
        (when-let* ((beg (overlay-start ov))
                    (end (overlay-end ov)))
          (let ((inhibit-read-only t))
            (save-excursion
              (dired-insert-set-properties beg end))))))))

(with-eval-after-load 'dirvish-subtree
  (advice-add 'dirvish-subtree--insert :around
              #'unzeit/dirvish-subtree--apply-props))

;;; ---- 侧栏 / 全窗口：再按一次就关 ------------------------

(defun unzeit/file-tree-window ()

  (or (dirvish-side--session-visible-p)
      (seq-find (lambda (w)
                  (and (eq (window-parameter w 'window-side) 'left)
                       (with-current-buffer (window-buffer w)
                         (or (derived-mode-p 'dired-mode)
                             (string-prefix-p " *SIDE" (buffer-name))))))
                (window-list nil 'nomini))))

(defun unzeit/dirvish-side-fit-width (dir)
  "按 DIR 里最长的文件名估一个刚够用的侧栏宽度（列）。"
  (let* ((names (ignore-errors (directory-files dir nil nil t)))
         (names (seq-remove (lambda (n) (member n '("." ".."))) names))
         (max-name (if names
                       (apply #'max (mapcar #'string-width names))
                     0)))
    (max 20 (min 32 (+ 3 max-name)))))

(defun unzeit/dirvish-side-apply-width (&optional dir)
  "把当前侧栏收/放到 DIR 内容需要的宽度（只动 side window）。"
  (when-let* ((win (unzeit/file-tree-window)))
    (let* ((dir (or dir (with-current-buffer (window-buffer win)
                          default-directory)))
           (w (unzeit/dirvish-side-fit-width dir)))
      (setq dirvish-side-width w)
      (with-selected-window win
        (let ((window-size-fixed nil))
          (ignore-errors
            (enlarge-window-horizontally (- w (window-width)))))))))

(defun unzeit/dirvish-side-fit ()
  "侧栏 dired 读完目录后按内容收窄/放宽；普通 dired 不动。"
  (when (and (derived-mode-p 'dired-mode)
             (eq (current-buffer)
                 (let ((w (unzeit/file-tree-window)))
                   (and w (window-buffer w)))))
    (unzeit/dirvish-side-apply-width default-directory)))

(add-hook 'dired-after-readin-hook #'unzeit/dirvish-side-fit)

(defun unzeit/file-tree-toggle ()
  (interactive)
  (if-let* ((win (unzeit/file-tree-window)))
      (progn
        ;; 先让 dirvish 自己收拾（清掉会话里隐藏的 dired 缓冲）
        (when (eq win (selected-window))
          (ignore-errors (dirvish-quit)))
        (when (window-live-p win)
          (when (eq win (selected-window))
            (ignore-errors (other-window 1)))
          (ignore-errors (delete-window win))))
    (setq dirvish-side-width
          (unzeit/dirvish-side-fit-width default-directory))
    (dirvish-side)))

(defun unzeit/file-tree-focus ()
  (interactive)
  (if-let* ((win (unzeit/file-tree-window)))
      (select-window win)
    (setq dirvish-side-width
          (unzeit/dirvish-side-fit-width default-directory))
    (dirvish-side)))

(defun unzeit/kill-buffer-dwim (&optional buffer)

  (interactive)
  (let* ((buf (or buffer (current-buffer)))
         (wins (get-buffer-window-list buf nil t))
         (win (car wins))
         (many (> (length (window-list nil 'nomini)) 1)))
    (let ((mains (seq-remove (lambda (w) (window-parameter w 'window-side))
                             (window-list nil 'nomini))))
      (if (and win many (= (length wins) 1)
               (> (length mains) 1)
               (not (window-parameter win 'window-side)))
          (progn
            (kill-buffer buf)
            (when (window-live-p win) (ignore-errors (delete-window win))))
        (kill-buffer buf)))))

(defun unzeit/dirvish-toggle ()
  (interactive)
  (if (and (dirvish-curr) (dv-curr-layout (dirvish-curr)))
      (dirvish-quit)
    (dirvish)))

;;; ---- project ------------------------------------------------------

(use-package project
  :ensure nil
  :defer t
  :custom
  (project-list-file (expand-file-name "projects" unzeit/cache-dir))
  (project-vc-ignores
   '("node_modules" ".cache" ".direnv" ".venv" ".ruff_cache"
     ".pytest_cache" "dist" "build" "target" "bazel-bin"
     "bazel-out" "bazel-testlogs" "*.eln" "*.elc" "*.pyc"
     "*.o" "*.so" "*.a" "*.swp"))
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
  :custom-face
  (diff-hl-change ((t (:inherit custom-changed :foreground unspecified :background unspecified))))
  (diff-hl-insert ((t (:inherit diff-added :background unspecified))))
  (diff-hl-delete ((t (:inherit diff-removed :background unspecified))))
  :hook ((after-init . global-diff-hl-mode)
         (after-init . global-diff-hl-show-hunk-mouse-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode . diff-hl-dired-mode))
  :custom
  (diff-hl-draw-borders nil)
  (diff-hl-update-async t)
  (diff-hl-global-modes '(not image-mode pdf-view-mode))
  :config
  (setq-default fringes-outside-margins t)
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p) (diff-hl-margin-mode 1)))

;;; core.el ends here
(provide 'core)

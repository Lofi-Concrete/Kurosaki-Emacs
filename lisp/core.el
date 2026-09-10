;;; core.el --- Unzeit: 基础层（常量、基础行为、界面、文件、剪贴板） -*- lexical-binding: t; -*-

;;; Commentary:
;; 由 init-const/init-base/init-ui/init-files/init-vc 与 init-clipboard 合并
;; 而来：不属于具体应用的那部分胶水 —— 路径与 Customize、核心编辑默认、
;; 字体/行号/空白符、dired/project、magit/diff-hl，以及 X11 剪贴板桥
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



;;; ---- 字体（Maple Mono + 中文回退） --------------------------------
;; Emacs 不读 fontconfig；中文回退必须显式通过 fontset 做

(defun unzeit/setup-fonts (&optional frame)
  "在 FRAME 上设置 Unzeit 默认字体以及中文/emoji 回退字体"
  (when frame (select-frame frame))
  (set-face-attribute 'default nil
                      :family "Maple Mono NF CN"
                      :height 180
                      :weight 'regular)
  (dolist (charset '(han kana hangul cjk-misc bopomofo))
    (set-fontset-font t charset nil)
    (set-fontset-font t charset
                      (font-spec :family "LXGW WenKai") nil 'prepend)
    (set-fontset-font t charset
                      (font-spec :family "Noto Sans CJK SC") nil 'prepend))
  (set-fontset-font t 'symbol
                    (font-spec :family "Noto Color Emoji") nil 'append)
  (setq face-font-rescale-alist
        '(("LXGW WenKai" . 0.95)
          ("Noto Sans CJK SC" . 0.9)
          ("Noto Sans Mono CJK SC" . 0.9)))
  (setq inhibit-compacting-font-caches t))

;; 第一帧可能已存在（daemon 客户端）；总是（重新）应用一次
(add-hook 'window-setup-hook #'unzeit/setup-fonts)
(add-hook 'after-make-frame-functions #'unzeit/setup-fonts)

;;; ---- 光标 --------------------------------------------------------

(setq cursor-type 'box)
(setq x-stretch-cursor t)       ; 方块光标盖住整个 tab/空格单元
(blink-cursor-mode -1)
(setq cursor-in-non-selected-windows 'hollow)

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

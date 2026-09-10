;;; editor.el --- Unzeit: 模态编辑（meow）+ 模式行 -*- lexical-binding: t; -*-

;;; Commentary:
;; 由 init-meow 与 unzeit-modeline 合并而来：meow 的 leader 键映射、
;; which-key，以及手写的模式行

;;; Code:



;;; ---- Leader 键映射 ------------------------------

(defvar-keymap unzeit/file-map
  :doc "SPC f：文件"
  "f" #'find-file
  "r" #'consult-recent-file
  "d" #'unzeit/dired-here
  "s" #'consult-ripgrep
  "b" #'consult-buffer
  "t" #'dired-sidebar-toggle-sidebar)

(defun unzeit/dired-here ()
  "在当前缓冲所在目录打开 Dired"
  (interactive)
  (let ((file (buffer-file-name)))
    (dired (if file (file-name-directory file) default-directory))))

(defvar-keymap unzeit/project-map
  :doc "SPC p：项目"
  "p" #'project-switch-project
  "f" #'project-find-file
  "b" #'consult-project-buffer
  "s" #'unzeit/project-ripgrep)

(defvar-keymap unzeit/search-map
  :doc "SPC s：搜索"
  "s" #'consult-line
  "g" #'consult-ripgrep
  "f" #'consult-find
  "b" #'consult-buffer)

(defvar-keymap unzeit/buffer-map
  :doc "SPC b：缓冲"
  "b" #'consult-buffer
  "k" #'kill-buffer
  "n" #'next-buffer
  "p" #'previous-buffer
  "i" #'ibuffer)

(defvar-keymap unzeit/window-map
  :doc "SPC w：窗口"
  "s" #'split-window-below
  "v" #'split-window-right
  "d" #'delete-window
  "o" #'delete-other-windows
  "=" #'balance-windows
  "u" #'winner-undo
  "r" #'winner-redo
  "h" #'windmove-left
  "j" #'windmove-down
  "k" #'windmove-up
  "l" #'windmove-right
  "w" #'ace-window
  "a" #'ace-swap-window
  "q" #'quit-window)

(defvar-keymap unzeit/tab-map
  :doc "SPC T：标签页 / 工作区（awesome-tab）"
  "f" #'awesome-tab-forward-tab
  "b" #'awesome-tab-backward-tab
  "n" #'awesome-tab-forward-group
  "p" #'awesome-tab-backward-group
  "g" #'awesome-tab-switch-group
  "j" #'awesome-tab-ace-jump
  "h" #'awesome-tab-move-current-tab-to-left
  "l" #'awesome-tab-move-current-tab-to-right
  "k" #'awesome-tab-kill-other-buffers-in-current-group
  "K" #'awesome-tab-kill-all-buffers-in-current-group)

(use-package all-the-icons
  :ensure t
  :defer t)

;; 顶层标签/工作区栏（按项目/模式分组 buffer），供 awesome-tab-mode 渲染
(use-package awesome-tab
  :ensure t
  :vc (:url "https://github.com/manateelazycat/awesome-tab")
  :demand t
  :config
  (awesome-tab-mode 1))

(defvar-keymap unzeit/git-map
  :doc "SPC g：git（magit）"
  "s" #'magit-status
  "l" #'magit-log-all
  "d" #'magit-diff-dwim
  "c" #'magit-commit-create
  "p" #'magit-push
  "f" #'magit-fetch
  "b" #'magit-blame)

(defvar-keymap unzeit/lsp-map
  :doc "SPC l：LSP（eglot）与 xref"
  "d" #'xref-find-definitions
  "t" #'xref-find-references
  "i" #'xref-find-implementations
  "b" #'xref-go-back
  "r" #'eglot-rename
  "a" #'eglot-code-actions
  "f" #'eglot-format
  "h" #'eldoc
  "s" #'consult-eglot-symbols)

(defvar-keymap unzeit/config-map
  :doc "SPC c：配置 + 编译"
  "c" #'unzeit/config-open
  "l" #'unzeit/config-lisp-dir
  "t" #'consult-theme
  "p" #'unzeit/package-list-packages
  "u" #'unzeit/package-upgrade-all
  ;; 编译组 —— spacemacs 默认，原样照抄
  "C" #'compile
  "r" #'recompile
  "k" #'kill-compilation
  "n" #'next-error
  "N" #'previous-error
  "b" #'unzeit/switch-to-compilation
  "d" #'unzeit/hide-compilation)

(defvar-keymap unzeit/register-map
  :doc "SPC r：寄存器（spacemacs 默认）"
  "l" #'list-registers
  "s" #'point-to-register
  "j" #'jump-to-register
  "y" #'copy-to-register
  "i" #'insert-register)

(defvar-keymap unzeit/narrow-map
  :doc "SPC n：收窄/放宽（spacemacs 默认）"
  "r" #'narrow-to-region
  "f" #'narrow-to-defun
  "p" #'narrow-to-page
  "w" #'widen)

;; spacemacs：SPC ; = 注释运算符这里注释/取消注释当前行（或选区）
(defun unzeit/comment-line ()
  "注释或取消注释当前行（或激活的选区）"
  (interactive)
  (if (region-active-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (comment-line 1)))

(defvar-keymap unzeit/meow-map
  :doc "SPC m：meow"
  "?" #'meow-cheatsheet
  "t" #'meow-tutor)

(defvar-keymap unzeit/org-map
  :doc "SPC o：org"
  "a" #'org-agenda
  "c" #'org-capture
  "l" #'org-store-link
  "m" #'unzeit/org-manual
  "w" #'unzeit/writer-toggle)

(defun unzeit/org-manual ()
  "打开 Unzeit 操作手册"
  (interactive)
  (require 'org)
  (find-file (expand-file-name "操作手册.org" org-directory)))

(defvar-keymap unzeit/zoom-map
  :doc "SPC z：字体缩放"
  "+" #'text-scale-increase
  "-" #'text-scale-decrease
  "0" #'text-scale-adjust)

(defvar-keymap unzeit/leader-map
  :doc "Unzeit leader 前缀（meow normal/motion 状态下的 SPC）"
  "h" #'unzeit/dashboard
  "f" unzeit/file-map
  "p" unzeit/project-map
  "s" unzeit/search-map
  "b" unzeit/buffer-map
  "w" unzeit/window-map
  "T" unzeit/tab-map
  "g" unzeit/git-map
  "l" unzeit/lsp-map
  "c" unzeit/config-map
  "m" unzeit/meow-map
  "o" unzeit/org-map
  "z" unzeit/zoom-map
  "t" #'eshell
  "r" unzeit/register-map
  "n" unzeit/narrow-map
  ";" #'unzeit/comment-line
  "q" #'save-buffers-kill-terminal)

(defun unzeit/project-ripgrep ()
  "从当前项目根目录用 ripgrep 搜索"
  (interactive)
  (let ((root (project-root (project-current t))))
    (consult-ripgrep root (thing-at-point 'symbol t))))

(defun unzeit/config-lisp-dir ()
  "用 Dired 打开 Unzeit 的 lisp 目录"
  (interactive)
  (dired (expand-file-name "lisp" user-emacs-directory)))

(defun unzeit/config-open ()
  "打开 Unzeit 的 init 文件（SPC c c）部署出来的是只读 store 软链接，
因此应编辑源文件 ~/dotfiles/emacs/init.el"
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

;;; ---- which-key 描述 ----------------------------------------------

(which-key-add-key-based-replacements "SPC"
  '("Unzeit" . "leader"))

(which-key-add-key-based-replacements "SPC f"
  '("文件" . "查找 / 最近 / 目录 / 文件树 / 搜索"))
(which-key-add-key-based-replacements "SPC p"
  '("项目" . "切换 / 查找 / 搜索"))
(which-key-add-key-based-replacements "SPC s"
  '("搜索" . "行 / ripgrep / 文件"))
(which-key-add-key-based-replacements "SPC b"
  '("缓冲" . "切换 / 关闭 / 下一个"))
(which-key-add-key-based-replacements "SPC w"
  '("窗口" . "分割 / 删除 / 移动 / 跳转 / 平衡 / 撤销"))
(which-key-add-key-based-replacements "SPC T"
  '("标签" . "awesome-tab 工作区 / 跳转"))
(which-key-add-key-based-replacements "SPC g"
  '("Git" . "magit"))
(which-key-add-key-based-replacements "SPC l"
  '("LSP" . "eglot / xref / 格式化"))
(which-key-add-key-based-replacements "SPC c"
  '("配置" . "打开 / 包 / 主题"))
(which-key-add-key-based-replacements "SPC m"
  '("Meow" . "速查 / 教程"))
(which-key-add-key-based-replacements "SPC o"
  '("Org" . "日程 / 捕获 / 链接 / 写作"))
(which-key-add-key-based-replacements "SPC z"
  '("缩放" . "字体缩放"))
(which-key-add-key-based-replacements "SPC r"
  '("寄存器" . "列表 / 存储 / 跳转 / 插入"))
(which-key-add-key-based-replacements "SPC n"
  '("收窄" . "区域 / defun / 页 / 放宽"))
(which-key-add-key-based-replacements "SPC ;"
  '("注释" . "注释 / 取消注释行"))
(which-key-add-key-based-replacements "SPC t"
  '("终端" . "eshell"))
(which-key-add-key-based-replacements "SPC q"
  '("退出" . "保存并退出"))
(which-key-add-key-based-replacements "SPC h"
  '("主页" . "Unzeit 主屏"))

;;; ---- which-key（标准配置，参照参考配置）
;; 用内置默认值的普通 `which-key-mode'（底部 side window），
;; 与 centaur/coldnew/minemacs/purcell 例子完全一致

(use-package which-key
  :ensure t
  :demand t
  :custom
  (which-key-idle-delay 0.3)
  (which-key-idle-secondary-delay 0.05)
  (which-key-show-prefix 'echo)
  (which-key-add-column-padding 2)
  (which-key-max-description-length 40)
  :config
  (which-key-mode 1))

;;; ---- meow ---------------------------------------------------------

(defun unzeit/meow-setup ()
  "为 meow 配置 Qwerty 布局（基于 meow 的 KEYBINDING_QWERTY）"
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (meow-motion-define-key
   '("j" . meow-next)
   '("k" . meow-prev)
   '("<escape>" . ignore))
  (meow-normal-define-key
   '("0" . meow-expand-0)
   '("9" . meow-expand-9)
   '("8" . meow-expand-8)
   '("7" . meow-expand-7)
   '("6" . meow-expand-6)
   '("5" . meow-expand-5)
   '("4" . meow-expand-4)
   '("3" . meow-expand-3)
   '("2" . meow-expand-2)
   '("1" . meow-expand-1)
   '("-" . negative-argument)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("a" . meow-append)
   '("A" . meow-open-below)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("c" . meow-change)
   '("d" . meow-delete)
   '("D" . meow-backward-delete)
   '("e" . meow-next-word)
   '("E" . meow-next-symbol)
   '("f" . meow-find)
   '("g" . meow-cancel-selection)
   '("G" . meow-grab)
   '("h" . meow-left)
   '("H" . meow-left-expand)
   '("i" . meow-insert)
   '("I" . meow-open-above)
   '("j" . meow-next)
   '("J" . meow-next-expand)
   '("k" . meow-prev)
   '("K" . meow-prev-expand)
   '("l" . meow-right)
   '("L" . meow-right-expand)
   '("m" . meow-join)
   '("n" . meow-search)
   '("o" . meow-block)
   '("O" . meow-to-block)
   '("p" . meow-yank)
   '("q" . meow-quit)
   '("Q" . meow-goto-line)
   '("r" . meow-replace)
   '("R" . meow-swap-grab)
   '("s" . meow-kill)
   '("t" . meow-till)
   '("u" . meow-undo)
   '("U" . meow-undo-in-selection)
   '("v" . meow-visit)
   '("w" . meow-mark-word)
   '("W" . meow-mark-symbol)
   '("x" . meow-line)
   '("X" . meow-goto-line)
   '("y" . meow-save)
   '("Y" . meow-sync-grab)
   '("z" . meow-pop-selection)
   '("'" . repeat)
   '("<escape>" . ignore)))

(use-package meow
  :ensure t
  :demand t
  :init
  ;; SPC 是 leader；不使用 meow 自带的 keypad 翻译
  (setq meow-keypad-leader-key nil)
  (setq meow-use-clipboard t)
  :config
  (unzeit/meow-setup)
  (meow-global-mode 1)
  ;; 在 normal 与 motion 状态绑定 leaderinsert 状态保留 SPC 用于输入
  (define-key meow-normal-state-keymap (kbd "SPC") unzeit/leader-map)
  (define-key meow-motion-state-keymap (kbd "SPC") unzeit/leader-map)
  :custom
  (meow-cursor-type-normal 'box)
  (meow-cursor-type-insert 'box)
  (meow-cursor-type-motion 'box)
  (meow-cursor-type-keypad 'box)
  (meow-cursor-type-beacon 'box))



;;; ---- 模式行片段（Segments）-----------------------------------------

(defun unzeit/modeline-buffer ()
  "缓冲名片段；有改动时标红主屏缓冲显示为 UNZEIT"
  (let* ((file (buffer-file-name))
         (modified (buffer-modified-p))
         (ro (and buffer-read-only (not modified) file))
         (name (cond (file (file-name-nondirectory file))
                     ((equal (buffer-name) "*dashboard*") "UNZEIT")
                     (t (buffer-name)))))
    (concat
     (propertize name
                 'face (if modified 'unzeit-modeline-modified 'unzeit-modeline-buffer))
     (if ro (propertize "  RO" 'face 'unzeit-modeline-muted) ""))))

(defun unzeit/modeline-vc ()
  "VC 分支片段（例如 Git）"
  (if vc-mode
      (propertize (string-trim vc-mode) 'face 'unzeit-modeline-muted)
    ""))

(defun unzeit/modeline-mode ()
  "主模式片段"
  (propertize (format-mode-line mode-name) 'face 'unzeit-modeline-mode))

(defun unzeit/modeline-position ()
  "位置片段：百分比 行:列"
  (propertize (format "%s %d:%d"
                      (format-mode-line "%p")
                      (line-number-at-pos)
                      (1+ (current-column)))
              'face 'unzeit-modeline-position))

(defun unzeit/modeline-state ()
  "Meow 状态指示（meow 加载前为空操作）"
  (if (fboundp 'meow-indicator)
      (meow-indicator)
    ""))

;;; ---- 额外信息片段 -------------------------------------

(defun unzeit/modeline-encoding ()
  "编码 + 换行 + 缩进片段（UTF-8 LF 4sp）"
  (when (buffer-file-name)
    (let* ((coding (symbol-name (or buffer-file-coding-system 'undecided)))
           (coding-short (if (string-match "utf-8" coding) "UTF-8"
                           (if (string-match "utf-16" coding) "UTF-16"
                             coding)))
           (eol (pcase (coding-system-eol-type buffer-file-coding-system)
                  (0 "LF") (1 "CRLF") (2 "CR") (_ "?")))
           (indent (if indent-tabs-mode "TAB" "SP"))
           (width (number-to-string (or (and (bound-and-true-p tab-width) tab-width)
                                        standard-indent 4))))
      (propertize (format "%s %s %s%s" coding-short eol indent width)
                  'face 'unzeit-modeline-muted))))

(defun unzeit/modeline-wordcount ()
  "文本类模式的字/行计数"
  (when (memq major-mode
              '(text-mode org-mode rst-mode
                          message-mode mail-mode))
    (let ((words (count-words (point-min) (point-max)))
          (lines (line-number-at-pos (point-max))))
      (propertize (format "%dw/%dl" words lines)
                  'face 'unzeit-modeline-muted))))

(defun unzeit/modeline-filesize ()
  "文件缓冲的人类可读文件大小"
  (when (and (buffer-file-name) (file-exists-p (buffer-file-name)))
    (let ((size (file-attribute-size (file-attributes (buffer-file-name)))))
      (propertize (file-size-human-readable size)
                  'face 'unzeit-modeline-muted))))

(defun unzeit/modeline-ime ()
  "输入法指示：显示 current-input-method，否则空白"
  (if current-input-method
      (propertize (format "%s" current-input-method)
                  'face 'unzeit-modeline-lsp)
    ""))

(defun unzeit/modeline-scale ()
  "缓冲被缩放时的文字比例指示（如 120%）"
  (if (and (bound-and-true-p text-scale-mode)
           (boundp 'text-scale-mode-amount)
           (/= text-scale-mode-amount 0))
      (propertize (format "%d%%" (round (* 100 (expt text-scale-mode-step text-scale-mode-amount))))
                  'face 'unzeit-modeline-muted)
    ""))

(defun unzeit/modeline-clock ()
  "时钟片段；mouse-1 = world-clock，滚轮 = 字体缩放"
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line down-mouse-1]
      (lambda () (interactive) (world-clock 1)))
    (define-key map [mode-line mouse-4]
      (lambda () (interactive) (text-scale-increase 1)))
    (define-key map [mode-line mouse-5]
      (lambda () (interactive) (text-scale-decrease 1)))
    (propertize (format-time-string "%H:%M")
                'face 'unzeit-modeline-position
                'local-map map
                'mouse-face 'mode-line-highlight
                'help-echo "mouse-1: 世界时钟，滚轮: 字体缩放")))

;;; ---- LSP（eglot）-------------------------------------------------

(defun unzeit/modeline-eglot ()
  "Eglot 指示：服务器已连接时红色，否则灰色"
  (when (bound-and-true-p eglot--managed-mode)
    (let* ((server (and (boundp 'eglot--cached-server) eglot--cached-server))
           (proc (and server (ignore-errors (jsonrpc--process server))))
           (live (and proc (process-live-p proc))))
      (propertize "LSP"
                  'face (if live 'unzeit-modeline-lsp 'unzeit-modeline-muted)
                  'help-echo (if live
                                 (format "LSP: %s" (process-name proc))
                               "LSP: 连接中…")))))

;;; ---- 模式行格式 ----------------------------------------------------

(defun unzeit/modeline-writer ()
  "专注写作模式指示（见 unzeit-writer.el；未加载时为空操作）"
  (when (bound-and-true-p unzeit/writer-mode)
    (propertize "✎"
                'face 'unzeit-modeline-lsp
                'help-echo "专注写作模式（SPC o w）")))

(setq-default mode-line-format
              '("%e"
                " "
                (:eval (unzeit/modeline-state))
                " "
                (:eval (unzeit/modeline-buffer))
                " "
                (:eval (unzeit/modeline-encoding))
                " "
                (:eval (unzeit/modeline-filesize))
                " "
                (:eval (unzeit/modeline-wordcount))
                (:eval (unzeit/modeline-ime))
                " "
                (:eval (unzeit/modeline-eglot))
                (:eval (unzeit/modeline-vc))
                (:eval (unzeit/modeline-scale))
                (:eval (unzeit/modeline-writer))
                (:eval (propertize " " 'display '(space :align-to (right-fringe right-margin))))
                (:eval (unzeit/modeline-mode))
                " "
                (:eval (unzeit/modeline-position))
                " "
                (:eval (unzeit/modeline-clock))
                " "))

;;; editor.el ends here
(provide 'editor)

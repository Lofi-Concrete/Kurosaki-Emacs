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
  ;; SPC w d = 关掉这个分割窗**连同它的 buffer**（用户 2026-09-18 反馈：
  ;; 原来绑 delete-window 时“关不掉”，只落成关 buffer 的观感）。
  ;; kill-buffer-and-window 是内置命令，正好两件事一起做；只剩一个窗口时
  ;; 它会拒绝杀掉最后一个 buffer，语义安全。
  "d" #'kill-buffer-and-window
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

;; 顶层标签/工作区栏（按项目/模式分组 buffer），供 awesome-tab-mode 渲染。
;; 它把标签栏画在 header-line 上（改的是 `header-line-format' 的全局默认
;; 值），所以「标签栏不见了」有两个独立的坑，两个都得堵：
;;
;;   1. 分组名算不出来：`project-current' 对 VC 项目（git/hg）返回
;;      (vc BACKEND ROOT)，cdr 是列表不是字符串，awesome-tab 却直接拿它去
;;      `expand-file-name'。只要缓冲列表里有一个属于 git 项目的缓冲，整次
;;      分组更新就中断，tabset 建不出来，标签栏整个消失。不属于任何项目的
;;      缓冲走 "Common" 组反而正常——这就是「有时不显示」的来源
;;   2. header-line 被抢：任何 buffer-local 的 header-line-format 都会顶掉
;;      标签栏（topsy 就是这么干的，见 init-misc.el）。文件缓冲由下面
;;      `unzeit/tab-bar-restore' 兜底；magit / org-agenda 这类不访问文件的
;;      缓冲保留自己的 header-line——那里也不需要标签栏
(defun unzeit/awesome-tab-project-name ()
  "当前缓冲所属项目组的名字；修正 awesome-tab 在 VC 项目下崩溃的问题。
`project-current' 有两种返回值：(transient . \"~/x/\") 与 (vc Git \"~/x/\")，
这里把两者都归一成根目录字符串；找不到项目就回到 Common 组。"
  (let* ((project (project-current))
         (root (cdr project))
         (dir (cond ((stringp root) root)
                    ((and (consp root) (stringp (cadr root))) (cadr root)))))
    (if dir
        (format "Project: %s" (expand-file-name dir))
      awesome-tab-common-group-name)))

(use-package awesome-tab
  :ensure t
  :vc (:url "https://github.com/manateelazycat/awesome-tab")
  :demand t
  :custom
  ;; 标签图标大小：相对标签**文字**（`unzeit/tab-font-height' = 17pt）的倍数，
  ;; 默认 0.6 太小，1.2 比标签文字略大一点点。注意这个值最终会被
  ;; `unzeit/awesome-tab-icon-pin-height' 换算并**钉成绝对字号**
  ;; `unzeit/tab-icon-height'（204 = 20.4pt）—— 它是浮点 1.2，在这里的含义是
  ;; 「底层 face 的 1.2 倍」，直接留着会跟栏高互相追着长大
  (awesome-tab-icon-height unzeit/tab-icon-scale)
  ;; 图标与栏严格等高，抬高一点就会被裁掉，所以基线不加偏移
  (awesome-tab-icon-v-adjust 0.0)
  :config
  ;; 栏高 = 图标高（`unzeit/tab-bar-height' = 204 = 20.4pt），栏里文字
  ;; = `unzeit/tab-font-height'（17pt）：都由 core.el 的
  ;; `unzeit/apply-tab-font-height' 钉。先把 `awesome-tab-height' 对齐到栏高：
  ;; 既免得加载瞬间它用自带的 190，也免得
  ;; `awesome-tab-adjust-color-with-theme' 换主题时把 header-line 改回去
  (setq awesome-tab-height unzeit/tab-bar-height)
  (unzeit/apply-tab-font-height)
  (advice-add 'awesome-tab-project-name
              :override #'unzeit/awesome-tab-project-name)
  ;; 丢掉之前算坏 / 算了一半的分组缓存，让标签栏按修好的规则重建
  (setq awesome-tab-groups-hash (make-hash-table :test 'equal)
        awesome-tab--buffers nil)
  (awesome-tab-mode 1))

;; 标签图标：awesome-tab 内置实现走 all-the-icons，而 all-the-icons 要
;; FontAwesome / file-icons / Material Icons 等一大堆字体，本机一个都没装 ——
;; 于是标签上只剩 ``E926'' 这样的码点。nerd-icons 统一用 Nerd Font 码点，而
;; Maple Mono NF CN 自带完整 Nerd Font 符号（corfu 候选图标就是这么来的；
;; 主字体 Iosevka Term 与中文 Sarasa Term SC 都没有私用区字形，core.el 的
;; fontset 把 PUA 回退挂在 Maple 上），所以把取图标这一步整个换成 nerd-icons。
;; 图标大小 / 基线仍读 awesome-tab 自己的两个 defcustom（`awesome-tab-icon-height'
;; = `unzeit/tab-icon-scale'，基线偏移 0），但大小会被钉成绝对值 —— 见下面
;; `unzeit/awesome-tab-icon-pin-height'
;;
;; 走文件分支只看 `buffer-file-name'，**不再要求文件已存在**：`C-x C-f' 打开
;; 一个尚不存在的路径时它已经设好，磁盘上却还没有那个文件；一要求
;; `file-exists-p' 就会掉进 mode 分支，而 `.c/.h' 走的是 simpc-mode
;; （见 init-eglot.el），它不在 nerd-icons 的 mode 表里，兜底值恰好是那个
;; Emacs 图标 —— 还没落盘的 .c 因此顶着 Emacs 图标。名字本身像文件名
;; （foo.c）时也按扩展名取图标，这样新建缓冲当场就是对的
(defun unzeit/awesome-tab-icon-file (buffer)
  "返回 BUFFER 用来查图标的名字；没有则 nil（交给 mode 分支）。"
  (or (buffer-file-name buffer)
      (let ((name (buffer-name buffer)))
        (and (string-match-p "\\`[^ *]+\\.[[:alnum:]]+\\'" name) name))))

(defun unzeit/awesome-tab-icon-pin-height (icon-face)
  "把 ICON-FACE 里那个浮点 `:height'（＝底层 face 的倍数）换成绝对值。

nerd-icons 把 `awesome-tab-icon-height' 原样写进 face，于是 `:height' 是浮点
1.2。浮点在 Emacs 里不是磅值而是「底层 face 的倍数」（`set-face-attribute'
文档原话：a scaling factor for the underlying face height），而标签栏里的底层
face 就是 header-line —— 栏高一涨（栏高要对齐图标，见 `unzeit/tab-bar-height'），
图标又按新栏高再放大 1.2 倍，两者互相追着长，永远差一截。钉成整数
`unzeit/tab-icon-height' 之后，图标大小只由那一个常量决定。"
  (if (and (listp icon-face) (floatp (plist-get icon-face :height)))
      (plist-put (copy-sequence icon-face) :height unzeit/tab-icon-height)
    icon-face))

(defun unzeit/awesome-tab-icon-for-tab (tab face)
  "用 nerd-icons 取 TAB 的图标（替代 awesome-tab 内置的 all-the-icons 版本）。"
  (when awesome-tab-display-icon
    (let ((tab-buffer (car tab)))
      (when (buffer-live-p tab-buffer)
        (let* ((file (unzeit/awesome-tab-icon-file tab-buffer))
               (icon (if file
                         (nerd-icons-icon-for-file
                          file
                          :height awesome-tab-icon-height
                          :v-adjust awesome-tab-icon-v-adjust)
                       (with-current-buffer tab-buffer
                         (nerd-icons-icon-for-mode
                          major-mode
                          :height awesome-tab-icon-height
                          :v-adjust awesome-tab-icon-v-adjust)))))
          (when (stringp icon)
            ;; 与 awesome-tab 原实现一致：保留图标自带的 face（字体族 / 颜色），
            ;; 只把背景换成标签的底色，图标才会跟标签融在一起。字号先钉成
            ;; 绝对值（见上面那个函数），否则图标会跟着栏高一起长
            (propertize icon
                        'face `(:inherit
                                ,(unzeit/awesome-tab-icon-pin-height
                                  (get-text-property 0 'face icon))
                                :background ,(face-background face)))))))))

(advice-add 'awesome-tab-icon-for-tab
            :override #'unzeit/awesome-tab-icon-for-tab)

;; 标签栏整条补 face：awesome-tab 拼出来的串里混着个别**没有 face 属性**的字符
;; （tab 之间的分隔空格），它们按 `default' —— 也就是**正文字号** —— 渲染，
;; header-line 于是被撑到跟正文一样高（正文 24pt → 49px），栏高就不再由图标
;; 决定：正文字号一动标签栏跟着动，这正是「Tab 高度跟图标不一样」的根源
;; （2026-09-15 用 `format-mode-line header-line-format' 逐字符查出来的：
;; 整条串里只有一个码点 32 的空格没 face）。这里把 awesome-tab 的模板渲染成
;; 字符串，逐字符补上标签档 face（**只补没有 face 的**，其余原样不动），再把
;; `header-line-format' 换成这条 `:eval'。awesome-tab 自己隐藏标签栏时是把
;; buffer-local 的 header-line-format 设成 nil，那条路径不受影响。
(defun unzeit/tab-bar-filler-face ()
  "标签栏里没上 face 的杂项字符用的 face（跟标签文字同一档）。"
  (list :height unzeit/tab-font-height))

(defun unzeit/tab-bar-string ()
  "awesome-tab 的标签栏内容，并给没有 face 的字符补上标签档 face。"
  (let ((s (format-mode-line (awesome-tab-line))))
    (when (stringp s)
      (dotimes (i (length s))
        (unless (get-text-property i 'face s)
          (put-text-property i (1+ i) 'face (unzeit/tab-bar-filler-face) s))))
    s))

(with-eval-after-load 'awesome-tab
  (setq-default header-line-format '(:eval (unzeit/tab-bar-string))))

;; simpc-mode（.c/.h/.cpp，见 init-eglot.el）不在 nerd-icons 的 mode 表里，
;; 兜底会退成 Emacs 图标；显式给它 C 的图标（与内置 c-mode/c-ts-mode 同款），
;; 这样连名字里没有扩展名的 C 缓冲也不会认错
(with-eval-after-load 'nerd-icons
  (add-to-list 'nerd-icons-mode-icon-alist
               '(simpc-mode nerd-icons-sucicon "nf-custom-c" :face nerd-icons-blue)))

(defun unzeit/tab-bar-restore ()
  "把文件缓冲里被抢走的 header-line 还给 awesome-tab 标签栏。
`after-change-major-mode-hook' 在所有 mode hook 之后运行，所以这条能追上
在 prog-mode-hook 里动手脚的包（topsy 就是那样）。"
  (when (and (buffer-file-name)
             (local-variable-p 'header-line-format)
             (not (eq header-line-format (default-value 'header-line-format))))
    (kill-local-variable 'header-line-format)))

(add-hook 'after-change-major-mode-hook #'unzeit/tab-bar-restore)
(add-hook 'find-file-hook #'unzeit/tab-bar-restore)

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
  "a" #'unzeit/cursor-toggle
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
  "?" #'unzeit/meow-cheatsheet
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
  '("配置" . "打开 / 包 / 主题 / 光标动画"))
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

;;; ---- meow 速查表（表格版）-------------------------------------------
;; meow 自带的 `meow-cheatsheet' 画的是 ANSI 物理键盘图：最宽一行 290 列，
;; 整张图还全靠制表符字形拼出来。137 列的帧里必然折行，字形一旦回退到
;; 全角的中文字体就更是一团乱（所以「太大 + 错位」）。
;;
;; 这里改成表格式速查表：键位从当前生效的键位图现算（改了 `unzeit/meow-setup'
;; 速查表跟着变），说明来自下面这张中文表，排版交给 `org-table-align' ——
;; 横向约 90 列，任何帧都不会折行，对齐也由 org 保证

(defconst unzeit/meow-key-descriptions
  '(;; 移动与选择
    ("h" . "左移一个字符")
    ("j" . "下移一行")
    ("k" . "上移一行")
    ("l" . "右移一个字符")
    ("H" . "向左扩展选区")
    ("J" . "向下扩展选区")
    ("K" . "向上扩展选区")
    ("L" . "向右扩展选区")
    ("e" . "到词尾")
    ("E" . "到符号尾")
    ("b" . "到词首")
    ("B" . "到符号首")
    ("w" . "选中一个词")
    ("W" . "选中一个符号")
    ("x" . "选中整行(不含换行)")
    ("0" . "扩展选区到\"词\"")
    ("1" . "扩展选区到\"符号\"")
    ("2" . "扩展选区到\"空白分隔\"")
    ("3" . "扩展选区到\"行\"")
    ("4" . "扩展选区到\"段\"")
    ("5" . "扩展选区到\"句\"")
    ("6" . "扩展选区到\"s 表达式\"")
    ("7" . "扩展选区到\"[] 内\"")
    ("8" . "扩展选区到\"{} 内\"")
    ("9" . "扩展选区到\"() 内\"")
    ;; 文本对象
    ("," . "文本对象内部(inner)")
    ("." . "含边界的整体(bounds)")
    ("[" . "跳到文本对象起点")
    ("]" . "跳到文本对象终点")
    ("o" . "按缩进或括号选中块")
    ("O" . "扩展到下一层块")
    ;; 编辑
    ("i" . "光标前插入")
    ("a" . "光标后追加")
    ("I" . "行首插入(上方开新行)")
    ("A" . "行尾追加(下方开新行)")
    ("d" . "删除选区(不保存)")
    ("D" . "反向删除")
    ("s" . "剪切选区到 kill ring")
    ("y" . "复制选区")
    ("p" . "粘贴(有选区则覆盖)")
    ("c" . "删除选区并进入 insert")
    ("r" . "用剪贴板内容替换选区")
    ("u" . "撤销")
    ("U" . "只撤销选区内")
    ("m" . "把下一行接到当前行")
    ;; 搜索与跳转
    ("v" . "输入关键词搜索并选中")
    ("n" . "选中下一个匹配")
    ("f" . "向后查找字符")
    ("t" . "向后查到字符前一位")
    (";" . "反向重复上一次 f / t")
    ("Q" . "跳到指定行并选中该行")
    ("X" . "跳到指定行")
    ;; 抓取与选区
    ("G" . "抓取(grab)")
    ("R" . "与选区交换内容")
    ("Y" . "用当前选区同步 grab")
    ("g" . "取消选区")
    ("z" . "回退上一次选区(弹出)")
    ;; 其它
    ("'" . "重复上一个命令")
    ("-" . "负前缀: 反向 / 反向搜索")
    ("q" . "关闭窗口或 buffer(非退出)")
    ("SPC" . "leader 前缀(见下表)")
    ("<escape>" . "无操作(防误触)"))
  "meow 按键的中文说明.
这张表同时决定速查表的行序; 键位图里有, 这里没写的键会排在最后并标成
??, 方便对照 `unzeit/meow-setup' 补齐. ")

(defconst unzeit/leader-descriptions
  '(("h" . "主页")
    ("f" . "文件")
    ("p" . "项目")
    ("s" . "搜索")
    ("b" . "缓冲")
    ("w" . "窗口")
    ("T" . "标签 / 工作区")
    ("g" . "Git")
    ("l" . "LSP / xref")
    ("c" . "配置 / 编译")
    ("m" . "meow")
    ("o" . "org / 写作")
    ("z" . "字号缩放")
    ("t" . "eshell")
    ("r" . "寄存器")
    ("n" . "收窄 / 放宽")
    (";" . "注释")
    ("q" . "保存并退出"))
  "SPC leader 各前缀的中文说明(与 which-key 的提示保持一致). ")

(defun unzeit/cheatsheet--live-keys (keymap)
  "KEYMAP（含其父键位图）里所有按键的名字，按字符排序。
只收单字符绑定与 <escape>：多键序列由 which-key 负责提示。"
  (let (keys)
    (while keymap
      (map-keymap
       (lambda (event _def)
         (let ((key (cond ((characterp event) (char-to-string event))
                          ((eq event 'escape) "<escape>"))))
           (when key (push key keys))))
       keymap)
      (setq keymap (keymap-parent keymap)))
    (sort (delete-dups (mapcar (lambda (key)
                                 (if (equal key " ") "SPC" key))
                               keys))
          #'string<)))

(defun unzeit/cheatsheet--command (keymap key)
  "KEYMAP 里 KEY 绑定的命令名（去掉 meow- 前缀）。"
  (let ((def (lookup-key keymap (kbd key))))
    (cond ((eq def 'ignore) "—")
          ((keymapp def) "前缀")
          ((symbolp def) (string-remove-prefix "meow-" (symbol-name def)))
          (t (format "%S" def)))))

(defun unzeit/cheatsheet--table (rows)
  "把 ROWS（(键 命令 说明) 列表）渲染成 org 表格字符串。"
  (concat "| 键 | 命令 | 说明 |\n"
          "|----+------+------|\n"
          (mapconcat (lambda (row)
                       (format "| %s | %s | %s |"
                               (nth 0 row) (nth 1 row) (nth 2 row)))
                     rows "\n")
          "\n"))

(defun unzeit/cheatsheet--key-table (keymap descriptions)
  "按 DESCRIPTIONS 的顺序，把 KEYMAP 的活键位渲染成 org 表格。"
  (let* ((live (unzeit/cheatsheet--live-keys keymap))
         (order (mapcar #'car descriptions))
         (keys (append (seq-filter (lambda (key) (member key live)) order)
                       (seq-remove (lambda (key) (member key order)) live))))
    (unzeit/cheatsheet--table
     (mapcar (lambda (key)
               (list key
                     (unzeit/cheatsheet--command keymap key)
                     (or (cdr (assoc key descriptions)) "?? 待补说明")))
             keys))))

(defun unzeit/cheatsheet--leader-table ()
  "把 leader 前缀渲染成两列并排的 org 表格（省一半行数）。"
  (let* ((entries (mapcar (lambda (entry)
                            (list (concat "SPC " (car entry)) (cdr entry)))
                          unzeit/leader-descriptions))
         (rows (seq-partition (append entries (make-list (mod (length entries) 2) '("" "")))
                              2)))
    (concat "| 键 | 组 | 键 | 组 |\n"
            "|----+----+----+----|\n"
            (mapconcat (lambda (pair)
                         (format "| %s | %s | %s | %s |"
                                 (nth 0 (nth 0 pair)) (nth 1 (nth 0 pair))
                                 (nth 0 (nth 1 pair)) (nth 1 (nth 1 pair))))
                       rows "\n")
            "\n")))

(defun unzeit/meow-cheatsheet ()
  "打开 meow 键位速查表(org 表格, 横向不折行).
键位取自当前生效的键位图, 说明取自 `unzeit/meow-key-descriptions'. "
  (interactive)
  (let ((buf (get-buffer-create "*meow 速查表*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "meow 速查表(SPC m ?): 键位取自当前生效的绑定\n"
                "\n* 状态\n\n"
                "| 状态 | 用途 | 进入 |\n"
                "|------+------+------|\n"
                "| normal | 移动 / 删除 / 复制 | ESC 从 insert 返回 |\n"
                "| insert | 输入文本(SPC 是空格) | i a I A |\n"
                "| motion | j / k 上下浏览 | 自动 |\n"
                "| beacon | 有活动选区时 | 自动 |\n"
                "\n* normal 态键位\n\n"
                (unzeit/cheatsheet--key-table meow-normal-state-keymap
                                              unzeit/meow-key-descriptions)
                "\n* motion 态键位\n\n"
                (unzeit/cheatsheet--key-table meow-motion-state-keymap
                                              unzeit/meow-key-descriptions)
                "\n* SPC leader 前缀\n\n"
                (unzeit/cheatsheet--leader-table)
                "\n* 组合方式\n\n"
                "- 数字前缀: 3j 下移 3 行, 2w 选中两个词\n"
                "- 负前缀: - 反向(-n 反向搜索, -3j 上移 3 行)\n"
                "- 有选区时直接打字 = 用新内容替换选区\n"
                "- 按 SPC 停 0.3 秒, which-key 会提示下一层\n"))
      ;; org-startup-folded 是 'content(见 init-org.el), org-mode 会把速查表
      ;; 折成一排 "状态..." / "normal 态键位...", 表格一张也看不见, 所以开完立刻
      ;; 整体展开(headings + blocks + drawers)
      (org-mode)
      (if (fboundp 'org-fold-show-all) (org-fold-show-all) (outline-show-all))
      ;; 逐张表对齐: `org-table-align' 在表格外调用会 Search failed, 所以先
      ;; 逐行找到每张表的表头再对齐
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*|" nil t)
        (org-table-align))
      (display-line-numbers-mode -1)
      ;; 表格宁可横向截断也不要折行: 折了就全错位
      (setq-local truncate-lines t)
      (goto-char (point-min))
      (setq buffer-read-only t))
    (switch-to-buffer buf)))



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
  "Eglot 指示：服务器已连接时米白粗体，否则灰色"
  (when (bound-and-true-p eglot--managed-mode)
    (let* ((server (and (boundp 'eglot--cached-server) eglot--cached-server))
           (proc (and server (ignore-errors (jsonrpc--process server))))
           (live (and proc (process-live-p proc))))
      (propertize "LSP"
                  'face (if live 'unzeit-modeline-lsp 'unzeit-modeline-muted)
                  'help-echo (if live
                                 (format "LSP: %s" (process-name proc))
                               "LSP: 连接中...")))))

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

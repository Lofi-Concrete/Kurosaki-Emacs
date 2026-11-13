;;; editor.el --- Unzeit: 模态编辑（meow）+ 模式行 -*- lexical-binding: t; -*-

;;; ---- Leader 键映射 ------------------------------

(defvar-keymap unzeit/file-map
  :doc "SPC f：文件"
  "f" #'find-file
  "s" #'save-buffer
  "S" #'write-file
  "o" #'find-file-other-window
  "r" #'consult-recent-file
  "R" #'consult-ripgrep
  "d" #'dirvish-dwim
  "b" #'consult-buffer
  "t" #'unzeit/treemacs-toggle
  "T" #'unzeit/treemacs-focus
  "v" #'unzeit/file-tree-toggle
  "V" #'unzeit/file-tree-focus
  "e" #'consult-dir
  "D" #'unzeit/dirvish-toggle
  "F" #'dirvish-fd
  "a" #'dirvish-quick-access)

(defun unzeit/run-tests ()
  "在项目根跑测试（按标志文件猜命令），输出进 *compilation*。"
  (interactive)
  (let* ((proj (project-current))
         (root (if proj (project-root proj) default-directory))
         (cmd (cond ((file-exists-p (expand-file-name "Cargo.toml" root)) "cargo test")
                    ((file-exists-p (expand-file-name "package.json" root)) "npm test")
                    ((file-exists-p (expand-file-name "pyproject.toml" root)) "pytest")
                    ((file-exists-p (expand-file-name "setup.py" root)) "pytest")
                    ((file-exists-p (expand-file-name "go.mod" root)) "go test ./...")
                    ((file-exists-p (expand-file-name "build.zig" root)) "zig build test")
                    ((file-exists-p (expand-file-name "pom.xml" root)) "mvn test")
                    ((file-exists-p (expand-file-name "Makefile" root)) "make test")
                    (t (read-string "测试命令: ")))))
    (let ((default-directory root))
      (compile cmd))))

(defvar-keymap unzeit/project-map
  :doc "SPC p：项目"
  "p" #'project-switch-project
  "f" #'project-find-file
  "F" #'project-or-external-find-file
  "b" #'consult-project-buffer
  "g" #'project-find-regexp
  "G" #'project-or-external-find-regexp
  "d" #'project-find-dir
  "D" #'project-dired
  "v" #'project-vc-dir
  "c" #'project-compile
  "w" #'project-save-some-buffers
  "s" #'unzeit/project-ripgrep
  "S" #'project-shell
  "k" #'project-kill-buffers
  "E" #'project-eshell
  "!" #'project-shell-command
  "&" #'project-async-shell-command
  "x" #'project-execute-extended-command
  "o" #'project-any-command
  "r" #'project-query-replace-regexp
  "t" #'unzeit/run-tests)

(defvar-keymap unzeit/search-map
  :doc "SPC s：搜索"
  "s" #'consult-line
  "g" #'consult-ripgrep
  "f" #'consult-find
  "b" #'consult-buffer
  "y" #'consult-yasnippet
  "T" #'consult-todo
  "F" #'consult-flyspell)

;;; ---- 窗口 / 缓冲切换的辅助命令 ----------------------------------

(defun unzeit/switch-to-last-buffer ()
  "切到最近用过的另一个 buffer（只换本窗口的 buffer）。"
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) t)))

(defun unzeit/eshell-other-window ()
  "下方分屏开 eshell，并同步到当前 buffer 的目录。"
  (interactive)
  (require 'eshell)
  (let ((dir default-directory)
        (buf (get-buffer eshell-buffer-name)))
    (when (and buf (not (eq buf (current-buffer))))
      (with-current-buffer buf
        (unless (equal default-directory dir)
          (setq default-directory dir))))
    (let ((display-buffer-overriding-action
           '((display-buffer-reuse-window display-buffer-below-selected)
             (window-height . 0.4))))
      (eshell))))

(defun unzeit/eshell-toggle ()
  "显示/收起 eshell（已显示就只收窗口，保留会话）。"
  (interactive)
  (require 'eshell)
  (if-let* ((win (get-buffer-window eshell-buffer-name t)))
      (with-selected-window win
        (quit-window))
    (unzeit/eshell-other-window)))

(defun unzeit/window-prev ()
  "跳到上一个窗口（doom 的 `SPC w W'，与 `SPC w w' 反方向）。"
  (interactive)
  (other-window -1))

(defun unzeit/window-toggle-maximize ()
  "最大化/还原当前窗口（多窗口收成一个，单窗口 winner-undo）。"
  (interactive)
  (if (one-window-p)
      (unless (ignore-errors (winner-undo) t)
        (message "Unzeit：没有可还原的窗口布局"))
    (delete-other-windows)))

(defun unzeit/window-list ()
  "按视觉顺序排列窗口（不用 window-list 的环形顺序）。"
  (sort (window-list nil 'nomini)
        (lambda (a b)
          (let ((ea (window-edges a))
                (eb (window-edges b)))
            (if (= (nth 1 ea) (nth 1 eb))   ; 同一行：左边的在前
                (< (nth 0 ea) (nth 0 eb))
              (< (nth 1 ea) (nth 1 eb)))))))

(defun unzeit/window-select-n (n)
  "选第 N 个窗口（按 `unzeit/window-list' 的视觉顺序，从 1 数）。"
  (interactive "n窗口号: ")
  (let ((wins (unzeit/window-list)))
    (if (and (integerp n) (<= 1 n) (<= n (length wins)))
        (select-window (nth (1- n) wins))
      (user-error "没有第 %d 个窗口（当前共 %d 个）" n (length wins)))))

(defun unzeit/window-number ()
  "当前窗口在 `unzeit/window-list' 里的编号（从 1 数）；只有一个窗口时返回 nil。"
  (let* ((wins (unzeit/window-list))
         (idx (seq-position wins (selected-window))))
    (when (and idx (> (length wins) 1))
      (1+ idx))))

(defun unzeit/modeline-window-number ()
  "模式行最左的窗口编号；只有一个窗口时为空。"
  (when-let* ((n (unzeit/window-number)))
    (propertize (format " %d " n)
                'face 'unzeit-modeline-window-number
                'help-echo (format "当前是第 %d 个窗口（SPC w %d 直接跳过来）" n n))))

(dotimes (i 9)
  (let ((n (1+ i)))
    (defalias (intern (format "unzeit/window-select-%d" n))
      (lambda ()
        (interactive)
        (unzeit/window-select-n n))
      (format "选第 %d 个窗口（SPC w %d）。" n n))))

(defvar-keymap unzeit/buffer-map
  :doc "SPC b：缓冲"
  "b" #'consult-buffer
  "k" #'kill-buffer
  "n" #'next-buffer
  "p" #'previous-buffer
  "," #'unzeit/switch-to-last-buffer
  "s" #'save-buffer
  "i" #'ibuffer)

(defvar-keymap unzeit/window-map
  :doc "SPC w：窗口"
  "h" #'windmove-left
  "j" #'windmove-down
  "k" #'windmove-up
  "l" #'windmove-right
  "w" #'other-window
  "W" #'unzeit/window-prev
  "s" #'split-window-below
  "v" #'split-window-right
  "d" #'kill-buffer-and-window
  "D" #'delete-other-windows
  "o" #'other-window
  "=" #'balance-windows
  "m" #'unzeit/window-toggle-maximize
  "u" #'winner-undo
  "r" #'winner-redo
  "a" #'ace-window
  "A" #'ace-swap-window
  "1" #'unzeit/window-select-1
  "2" #'unzeit/window-select-2
  "3" #'unzeit/window-select-3
  "4" #'unzeit/window-select-4
  "5" #'unzeit/window-select-5
  "6" #'unzeit/window-select-6
  "7" #'unzeit/window-select-7
  "8" #'unzeit/window-select-8
  "9" #'unzeit/window-select-9
  "q" #'quit-window)

(defvar-keymap unzeit/git-map
  :doc "SPC g：git（magit）"
  "s" #'magit-status
  "l" #'magit-log-all
  "d" #'magit-diff-dwim
  "c" #'magit-commit-create
  "p" #'magit-push
  "f" #'magit-fetch
  "b" #'magit-blame
  "t" #'git-timemachine
  "T" #'magit-todos-list
  "o" #'browse-at-remote
  "m" #'git-messenger:popup-message)

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
  "w" #'unzeit/diagnostics-toggle-warnings
  "s" #'consult-eglot-symbols)

(defvar-keymap unzeit/config-map
  :doc "SPC c：配置 + 编译"
  "c" #'unzeit/config-open
  "l" #'unzeit/config-lisp-dir
  "D" #'unzeit/doctor-toggle
  "t" #'consult-theme
  "p" #'unzeit/package-list-packages
  "u" #'unzeit/package-upgrade-all
  ;; 编译组（spacemacs 默认）
  "C" #'compile
  "T" #'unzeit/compile-in-terminal   ; 同一条命令，在 Eat 终端里跑（能看进度盘）
  "v" #'unzeit/compile-toggle-view   ; 日志视图 ⇄ 终端视图
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

;; SPC ; = 注释当前行/选区（spacemacs 同键）
(defun unzeit/comment-line ()
  "注释当前行或选区（判据用 mark-active，选区扩到整行）。"
  (interactive)
  (let* ((beg (cond ((region-active-p) (region-beginning))
                    ((and mark-active (mark t) (/= (mark t) (point)))
                     (min (point) (mark t)))))
         (end (cond ((region-active-p) (region-end))
                    ((and mark-active (mark t) (/= (mark t) (point)))
                     (max (point) (mark t))))))
    (if (and beg end)
        (comment-or-uncomment-region (min beg end) (max beg end))
      (comment-line 1))))

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
  "q" #'unzeit/quickstart-manual
  "w" #'unzeit/writer-toggle
  "r" #'org-roam-node-find
  "i" #'org-roam-node-insert
  "b" #'org-roam-buffer-toggle
  "d" #'org-roam-dailies-today
  "u" #'org-roam-ui-mode)

(defun unzeit/org-manual ()
  "打开 Unzeit 操作手册"
  (interactive)
  (require 'org)
  (find-file (expand-file-name "操作手册.org" org-directory)))

(defun unzeit/quickstart-manual ()
  "打开快速上手（一页纸）；文件在 org-directory。"
  (interactive)
  (require 'org)
  (find-file (expand-file-name "快速上手.org" org-directory)))

(defvar-keymap unzeit/zoom-map
  :doc "SPC z：字体缩放"
  "+" #'text-scale-increase
  "-" #'text-scale-decrease
  "0" #'text-scale-adjust)

(defvar-keymap unzeit/debug-map
  :doc "SPC d：调试（dape / DAP）"
  "d" #'dape
  "b" #'dape-breakpoint-toggle
  "B" #'dape-breakpoint-remove-all
  "c" #'dape-continue
  "n" #'dape-next
  "i" #'dape-step-in
  "o" #'dape-step-out
  "p" #'dape-pause
  "r" #'dape-restart
  "q" #'dape-quit
  "e" #'dape-evaluate-expression
  "l" #'dape-repl
  "s" #'dape-switch-to-buffer
  "S" #'dape-select-stack
  "w" #'dape-watch-dwim
  "h" #'dape-transient)

(defvar-keymap unzeit/ai-map
  :doc "SPC a：AI（DeepSeek）"
  "c" #'unzeit/ai-chat
  "r" #'unzeit/ai-rewrite
  "e" #'unzeit/ai-explain
  "t" #'unzeit/ai-translate
  "A" #'unzeit/ai-aider
  "k" #'unzeit/ai-reset-key)

(defvar-keymap unzeit/help-map
  :doc "SPC ?：帮助"
  "h" #'help-command
  "k" #'describe-key
  "f" #'describe-function
  "v" #'describe-variable
  "b" #'describe-bindings
  "o" #'info
  "m" #'man
  "a" #'apropos)

(defvar-keymap unzeit/leader-map
  :doc "Unzeit leader 前缀（meow normal/motion 状态下的 SPC）"
  "h" #'unzeit/dashboard-toggle
  "f" unzeit/file-map
  "p" unzeit/project-map
  "s" unzeit/search-map
  "b" unzeit/buffer-map
  "w" unzeit/window-map
  "g" unzeit/git-map
  "l" unzeit/lsp-map
  "c" unzeit/config-map
  "m" unzeit/meow-map
  "o" unzeit/org-map
  "z" unzeit/zoom-map
  "t" #'unzeit/eshell-toggle
  "T" #'eat
  "d" unzeit/debug-map
  "a" unzeit/ai-map
  "r" unzeit/register-map
  "n" unzeit/narrow-map
  "?" unzeit/help-map
  ";" #'unzeit/comment-line
  "," #'unzeit/switch-to-last-buffer
  "`" #'other-window
  "W" #'unzeit/window-prev
  "q" #'save-buffers-kill-terminal
  "y" #'browse-kill-ring)

;;; ---- C-c：原生 Emacs 的自定义命令前缀 ------------------------------

(defun unzeit/debug-menu ()
  "打开 dape 的 transient 调试菜单；F5 直接启动调试。"
  (interactive)
  (require 'dape)
  (if (fboundp 'dape-transient)
      (call-interactively #'dape-transient)
    (user-error "dape 菜单还没准备好：先 M-x dape 或按 F5")))

(defun unzeit/java-menu ()
  "打开 Maven Web / Tomcat 菜单（由 Java 语言模块提供）。"
  (interactive)
  (if (fboundp 'unzeit/servlet-menu-open)
      (call-interactively #'unzeit/servlet-menu-open)
    (user-error "没加载 Java Web 模块（home/lang/java）")))

(defun unzeit/toggle-hl-line ()
  "开关全局当前行高亮（dashboard/term/help 自动排除）。"
  (interactive)
  (if (bound-and-true-p global-hl-line-mode)
      (progn (global-hl-line-mode -1) (message "hl-line: off"))
    (global-hl-line-mode 1) (message "hl-line: on")))

(defvar-keymap unzeit/custom-map
  :doc "C-c：Unzeit 自定义命令（与 meow 的 SPC leader 并存）"
  ;; 文件 / 目录
  "t" #'unzeit/treemacs-toggle
  "T" #'unzeit/treemacs-focus
  "v" #'unzeit/file-tree-toggle
  "V" #'unzeit/file-tree-focus
  "d" #'unzeit/dirvish-toggle
  ;; 主屏 / 体检 / 写作
  "h" #'unzeit/dashboard-toggle
  "D" #'unzeit/doctor-toggle
  "w" #'unzeit/writer-toggle
  ;; 配置 / 手册
  "e" #'unzeit/config-open
  "E" #'unzeit/config-lisp-dir
  "m" #'unzeit/org-manual
  "M" #'unzeit/quickstart-manual
  ;; Org
  "a" #'org-agenda
  "c" #'org-capture
  ;; 终端 / 项目 / 编译
  "s" #'unzeit/eshell-toggle
  "S" #'eat
  "r" #'unzeit/project-ripgrep
  "R" #'unzeit/run-tests
  "x" #'unzeit/compile-in-terminal
  "X" #'unzeit/compile-toggle-view
  ;; 调试 / 诊断 / Java / AI
  "b" #'unzeit/debug-menu
  "W" #'unzeit/diagnostics-toggle-warnings
  "J" #'unzeit/java-menu
  "H" #'unzeit/toggle-hl-line
  "A" unzeit/ai-map)



;; custom-map 定义在 leader 之后，这里再单独接上 SPC x（同 C-c）。
(keymap-set unzeit/leader-map "x" unzeit/custom-map)
(which-key-add-key-based-replacements "SPC x" "自定义（同 C-c）")
;; 保留 C-c 上原有的全局绑定（flymake / avy / profiler / 缩进 / org 链接…）：
;; 自定义表把原来的 C-c 前缀挂成 parent，新增的键只是叠加。
(let ((base (lookup-key global-map (kbd "C-c"))))
  (when (keymapp base)
    (set-keymap-parent unzeit/custom-map base)))
(keymap-set global-map "C-c" unzeit/custom-map)

(defun unzeit/project-ripgrep ()
  "从当前项目根目录用 ripgrep 搜索"
  (interactive)
  (let ((root (project-root (project-current t))))
    (consult-ripgrep root (thing-at-point 'symbol t))))

(defun unzeit/config--dir ()
  "返回 `unzeit/config-directory'；目录不存在时报错说明怎么改。"
  (unless (file-directory-p unzeit/config-directory)
    (user-error "Unzeit：找不到源仓库 %s（在 init-local.el 里设置 `unzeit/config-directory'）"
                unzeit/config-directory))
  unzeit/config-directory)

(defun unzeit/config-lisp-dir ()
  "用 Dired 打开 Unzeit 源仓库的 lisp 目录（SPC c l）。"
  (interactive)
  (dired (expand-file-name "lisp" (unzeit/config--dir))))

(defun unzeit/config-open ()
  "打开 init 源文件（绕开只读 store 链接）。"
  (interactive)
  (let ((find-file-visit-truename nil))
    (find-file (expand-file-name "init.el" (unzeit/config--dir)))))

;;; ---- which-key ----

(use-package which-key
  :ensure nil
  :demand t
  :custom
  (which-key-idle-delay 0.3)
  (which-key-idle-secondary-delay 0.05)
  (which-key-show-prefix 'echo)
  (which-key-show-remaining-keys t)
  (which-key-add-column-padding 1)
  (which-key-max-description-length 30)
  (which-key-max-display-columns 3)
  ;; 0.5 只是上限；真正定高的是下面的 fit 方式。
  (which-key-side-window-max-height 0.5)
  ;; daemon / 无 GUI 帧时加载会让默认值变成 t（按行数定高）；
  ;; 本机行高比 frame-char-height 高 0.12em，最后一行会被裁掉。
  (which-key-allow-imprecise-window-fit nil)
  :config
  (which-key-mode 1))

;; Centaur 方案：which-key 放浮动 childframe；没有 GUI/childframe 时保持上面的侧窗。
;; posframe 本身没有这个 poshandler（Centaur 在 init-base.el 里自定义）；
;; 不定义的话 which-key 的 timer 会报 void-function。
(defun posframe-poshandler-frame-center-near-bottom (info)
  "把 childframe 放在父 frame 水平居中、底部偏上的位置。"
  (cons (/ (- (plist-get info :parent-frame-width)
              (plist-get info :posframe-width))
           2)
        (/ (+ (plist-get info :parent-frame-height)
              (* 2 (plist-get info :font-height)))
           2)))

(when unzeit/modern-posframe
  (use-package which-key-posframe
    :ensure t
    :demand t
    :custom
    (which-key-posframe-poshandler 'posframe-poshandler-frame-center)
    (which-key-posframe-parameters '((left-fringe . 8) (right-fringe . 8)))
    :config
    ;; init 时第一帧还没建好，display-graphic-p 可能是 nil；等 window-setup。
    (defun unzeit/enable-which-key-posframe (&rest _)
      (when (and (display-graphic-p)
                 (eq (frame-parameter (selected-frame) 'minibuffer) 't))
        (which-key-posframe-mode 1)))
    (add-hook 'window-setup-hook #'unzeit/enable-which-key-posframe 'append)
    (add-hook 'after-make-frame-functions
              #'unzeit/enable-which-key-posframe 'append)))

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
   '("y" . meow-save)
   '("Y" . meow-sync-grab)
   '("z" . meow-pop-selection)
   '("'" . repeat)
   '("<escape>" . ignore)))

(use-package meow
  :ensure t
  :demand t
  :init
  (setq meow-keypad-leader-dispatch nil)
  (setq meow-use-clipboard t)
  :config
  (unzeit/meow-setup)
  (meow-global-mode 1)
  (define-key meow-normal-state-keymap (kbd "SPC") unzeit/leader-map)
  (define-key meow-motion-state-keymap (kbd "SPC") unzeit/leader-map)
  ;; 光标形状用 meow 默认；要改须显式 setq 并验证。
  )

;;; ---- meow 速查表（表格版）-------------------------------------------

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
  "meow 按键的中文说明，也决定速查表行序。
键位图里有、这里没写的键排最后并标 ??，方便对照 `unzeit/meow-setup' 补齐。")

(defconst unzeit/leader-descriptions
  '(
    ("h" . "主页")
    ("f" . "文件")
    ("p" . "项目")
    ("s" . "搜索")
    ("b" . "缓冲")
    ("w" . "窗口")
    ("T" . "终端（eat）")
    ("d" . "调试")
    ("a" . "AI")
    ("g" . "Git")
    ("j" . "Java Web / Maven / Tomcat")
    ("l" . "LSP / xref")
    ("c" . "配置 / 编译")
    ("m" . "meow")
    ("o" . "org / 写作")
    ("z" . "字号缩放")
    ("t" . "eshell")
    ("r" . "寄存器")
    ("n" . "收窄 / 放宽")
    (";" . "注释")
    ("," . "上一个缓冲")
    ("`" . "跳窗口")
    ("W" . "上一个窗口")
    ("q" . "保存并退出"))
  "SPC leader 各前缀的中文说明(速查表用; 与 which-key 的提示保持一致). ")

(defconst unzeit/leader-popup-texts
  '(
    ("f" "文件" . "查找 / 最近 / 目录 / 文件树 / 搜索")
    ("p" "项目" . "切换 / 查找 / 搜索")
    ("s" "搜索" . "行 / ripgrep / 文件")
    ("b" "缓冲" . "切换 / 循环 / 上一个 / 关闭 / 保存")
    ("w" "窗口" . "四向 / 循环 / 分屏 / 关闭 / 最大化 / 选第 N 个")
    ("T" "终端" . "eat（真终端，TUI 程序也能跑）")
    ("d" "调试" . "启动 / 断点 / 继续 / 单步 / 求值")
    ("a" "AI" . "对话 / 改写 / 解释 / 翻译 / aider")
    ("g" "Git" . "magit")
    ("j" "Java Web" . "mvn 编译/测试/打包 / Tomcat 启动/停止/日志")
    ("l" "LSP" . "eglot / xref / 格式化")
    ("c" "配置" . "打开 / Guix / 包 / 主题")
    ("m" "Meow" . "速查 / 教程")
    ("o" "Org" . "日程 / 捕获 / 链接 / 写作 / 快速上手")
    ("z" "缩放" . "字体缩放")
    ("r" "寄存器" . "列表 / 存储 / 跳转 / 插入")
    ("n" "收窄" . "区域 / defun / 页 / 放宽")
    (";" "注释" . "注释 / 取消注释行")
    ("t" "终端" . "eshell")
    ("," "缓冲" . "切回最近用过的另一个")
    ("`" "窗口" . "跳到 other-window")
    ("W" "窗口" . "循环到上一个窗口")
    ("q" "退出" . "保存并退出")
    ("h" "主页" . "Unzeit 主屏")
    )
  "leader 前缀在 which-key 弹窗里的标签与说明。")

(defun unzeit/leader--replacements ()
  "把两张 leader 表合成 which-key 替换参数。"
  (cons '("SPC" "Unzeit" . "leader")
        (mapcar (lambda (row)
                  (let* ((key (car row))
                         (popup (assoc key unzeit/leader-popup-texts))
                         (label (if popup (cadr popup)
                                  (cdr (assoc key unzeit/leader-descriptions))))
                         (detail (if popup (cddr popup) label)))
                    (cons (concat "SPC " key) (cons label detail))))
                unzeit/leader-descriptions)))

(mapc (lambda (entry)
        (which-key-add-key-based-replacements (car entry) (cdr entry)))
      (unzeit/leader--replacements))

;;; ---- C-c 的 which-key 说明与排序 ------------------------------------

(defconst unzeit/custom-key-descriptions
  '(("t" . "文件树开关")
    ("T" . "进文件树")
    ("d" . "全窗 dirvish 开关")
    ("h" . "主屏开关")
    ("D" . "体检报告")
    ("w" . "专注写作")
    ("e" . "打开配置 init.el")
    ("E" . "打开配置 lisp 目录")
    ("m" . "操作手册")
    ("M" . "快速上手")
    ("a" . "日程（org-agenda）")
    ("c" . "捕获（org-capture）")
    ("s" . "eshell 开关")
    ("S" . "eat 终端")
    ("r" . "项目 ripgrep")
    ("R" . "跑测试")
    ("x" . "终端里编译")
    ("X" . "日志 / 终端视图切换")
    ("b" . "调试菜单（dape）")
    ("W" . "诊断 warning 开关")
    ("J" . "Java / Tomcat 菜单")
    ("H" . "当前行高亮开关")
    ("g" . "Guix 包 / 世代 / 服务")
    ("A" . "AI（DeepSeek）"))
  "C-c 各键的中文说明（which-key 用）。")

(mapc (lambda (entry)
        (which-key-add-key-based-replacements
         (concat "C-c " (car entry)) (cdr entry)))
      unzeit/custom-key-descriptions)

(which-key-add-key-based-replacements "C-c" "Unzeit 自定义")

;; C-c 同时是主模式自己的前缀（例如 c-ts-mode 的 C-c .），which-key 会把两边
;; 的键混在一起。这里让自定义表里的键排在前面：按 C-c 先看到的是本配置的命令，
;; 模式自己的键排到后面；其它前缀（C-x / C-h…）仍用 which-key 默认顺序。
(defconst unzeit/custom-key-strings
  (mapcar (lambda (entry) (concat "C-c " (car entry)))
          unzeit/custom-key-descriptions)
  "C-c 自定义命令的完整键描述（which-key 排序用）。")

(defun unzeit/which-key-custom-key-p (key)
  "KEY（which-key 的键描述）是否属于 C-c 自定义表。"
  (member key unzeit/custom-key-strings))

(defun unzeit/which-key-custom-first (a b)
  "C-c 下先列 Unzeit 自定义键，再列模式自己的键；其余前缀按原顺序。"
  (let ((ca (unzeit/which-key-custom-key-p (car a)))
        (cb (unzeit/which-key-custom-key-p (car b))))
    (cond ((and ca (not cb)) t)
          ((and cb (not ca)) nil)
          (t (which-key-key-order a b)))))

(setq which-key-sort-order #'unzeit/which-key-custom-first)

(defun unzeit/cheatsheet--live-keys (keymap)
  "KEYMAP 里所有单字符绑定与 <escape>。"
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
  "打开 meow 键位速查表（org 表格）。"
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
      (org-mode)
      (if (fboundp 'org-fold-show-all) (org-fold-show-all) (outline-show-all))
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*|" nil t)
        (org-table-align))
      (display-line-numbers-mode -1)
      ;; 表格宁可横向截断也不要折行: 折了就全错位
      (setq-local truncate-lines t)
      (goto-char (point-min))
      (setq buffer-read-only t))
    (switch-to-buffer buf)))

;;; ---- 文件标签栏（VSC 那种）-----------------------------------------

(defun unzeit/tab-line-tabs ()
  "VSC 风格：只列本窗口的**文件**缓冲，跳过 *scratch* / *dashboard* 这类。"
  (seq-filter (lambda (tab)
                (let ((b (if (bufferp tab) tab (alist-get 'buffer tab))))
                  (and (bufferp b) (buffer-file-name b))))
              (tab-line-tabs-fixed-window-buffers)))

(defun unzeit/tab-line--icon (tab)
  "返回 TAB 的 nerd icon 串（带自己的 face）；没有就 nil。"
  (let* ((buf (if (bufferp tab) tab (alist-get 'buffer tab)))
         (file (and (bufferp buf) (buffer-file-name buf))))
    (when (bufferp buf)
      (require 'nerd-icons nil t)
      (ignore-errors
        (if file (nerd-icons-icon-for-file file)
          (with-current-buffer buf (nerd-icons-icon-for-buffer)))))))

(defun unzeit/tab-line-name (tab _tabs)
  "标签名：图标 + 文件名；非文件缓冲用缓冲名。"
  (let* ((buf (if (bufferp tab) tab (alist-get 'buffer tab)))
         (file (and (bufferp buf) (buffer-file-name buf)))
         (name (cond (file (file-name-nondirectory file))
                     ((bufferp tab) (buffer-name tab))
                     (t (or (alist-get 'name tab) ""))))
         (icon (unzeit/tab-line--icon tab)))
    (concat (or icon "") " " name)))

(defun unzeit/tab-line-name-format (orig tab tabs)
  "调用 ORIG 生成标签串后，把图标自己的 face 盖回图标那几个字符。
tab-line 的默认格式函数给整条标签串加 `tab-line-tab' face，会把
nerd-icons 的彩色 face 整个覆盖掉；这里只恢复图标前缀的 face。"
  (let ((s (funcall orig tab tabs))
        (icon (unzeit/tab-line--icon tab)))
    (when (and (stringp s) icon (> (length icon) 0))
      (let ((face (get-text-property 0 'face icon)))
        (when face
          (add-face-text-property 0 (length icon) face nil s))))
    s))

(use-package tab-line
  :ensure nil
  :demand t
  :custom
  (tab-line-tabs-function #'unzeit/tab-line-tabs)
  (tab-line-tab-name-function #'unzeit/tab-line-name)
  (tab-line-close-tab-function 'kill-buffer)
  (tab-line-new-button-show nil)
  (tab-line-close-button-show nil)
  (tab-line-tab-name-truncated-max 30)
  (tab-line-exclude-modes '(completion-list-mode help-mode dired-mode dashboard-mode))
  :config
  (advice-add 'tab-line-tab-name-format-default :around
              #'unzeit/tab-line-name-format)
  (global-tab-line-mode 1)
  ;; VSC 的 Ctrl+Tab / Ctrl+Shift+Tab
  (keymap-global-set "C-<tab>" #'tab-line-switch-to-next-tab)
  (keymap-global-set "C-S-<tab>" #'tab-line-switch-to-prev-tab))

;;; ---- 模式行片段（Segments）-----------------------------------------

;; 只声明模式行片段用到的 face，其余颜色继承 doom 主题。
(defface unzeit-modeline-buffer
  '((t (:inherit bold)))
  "模式行缓冲名。"
  :group 'unzeit)

(defface unzeit-modeline-modified
  '((t (:inherit error :weight bold)))
  "模式行已修改标记。"
  :group 'unzeit)

(defface unzeit-modeline-lsp
  '((t (:inherit success :weight bold)))
  "模式行 LSP 指示。"
  :group 'unzeit)

(defface unzeit-modeline-mode
  '((t (:inherit bold)))
  "模式行主模式名。"
  :group 'unzeit)

(defface unzeit-modeline-muted
  '((t (:inherit shadow)))
  "模式行次要信息。"
  :group 'unzeit)

(defface unzeit-modeline-position
  '((t (:inherit mode-line)))
  "模式行位置/时钟。"
  :group 'unzeit)

(defface unzeit-modeline-error
  '((t (:inherit error :weight bold)))
  "模式行错误计数。"
  :group 'unzeit)

(defface unzeit-modeline-warning
  '((t (:inherit warning :weight bold)))
  "模式行警告计数。"
  :group 'unzeit)

(defface unzeit-modeline-window-number
  '((t (:inherit mode-line-emphasis :weight bold)))
  "模式行窗口编号。"
  :group 'unzeit)

(defun unzeit/modeline-buffer ()
  "缓冲名片段；有改动时标红主屏缓冲显示为 UNZEIT"
  (let* ((file (buffer-file-name))
         (modified (buffer-modified-p))
         (ro (and buffer-read-only (not modified) file))
         (name (cond (file (file-name-nondirectory file))
                     ((equal (buffer-name) "*dashboard*") "UNZEIT")
                     (t (buffer-name)))))
    (concat
     ;; 文件类型图标（与 dired / corfu 同一套 Nerd Font 码点）
     (when (and file (require 'nerd-icons nil t))
       (let ((icon (ignore-errors (nerd-icons-icon-for-file file))))
         (if icon (concat icon " ") "")))
     (propertize name
                 'face (if modified 'unzeit-modeline-modified 'unzeit-modeline-buffer))
     (if ro (propertize "  RO" 'face 'unzeit-modeline-muted) ""))))

(defun unzeit/modeline-vc ()
  "VC 分支片段（例如 Git）"
  (if vc-mode
      (propertize (replace-regexp-in-string "\\`\\(Git\\|SVN\\|Hg\\):" ""
                                            (string-trim vc-mode))
                  'face 'unzeit-modeline-muted)
    ""))

(defun unzeit/modeline-mode ()
  "主模式片段"
  (propertize (format-mode-line mode-name) 'face 'unzeit-modeline-mode))

(defun unzeit/modeline-position ()
  "位置片段：百分比 行:列（行号取 format-mode-line 的 %l）。"
  (let ((pct (format-mode-line "%p")))
    (propertize (format "%s%d:%d"
                        (if (string= pct "All") "" (concat pct " "))
                        (line-number-at-pos)
                        (1+ (current-column)))
                'face 'unzeit-modeline-position)))

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
           )
      ;; 只报异常：编码非 UTF-8 或换行不是 LF 才显示。
      (unless (and (or (string= coding-short "UTF-8")
                       (string-prefix-p "undecided" coding-short))
                   (string= eol "LF"))
        (propertize (format "%s %s" coding-short eol)
                    'face 'unzeit-modeline-muted)))))

(defvar-local unzeit/modeline--counts nil
  "`unzeit/modeline-wordcount' 的缓存：(修改计数 . (词数 . 行数))。
`(:eval)' 每帧都跑；`count-words' 是 O(字符数)，不缓存大文件每帧重算。")

(defun unzeit/modeline-wordcount ()
  "文本类模式的字/行计数（按 `buffer-chars-modified-tick' 缓存）"
  (when (memq major-mode
              '(text-mode org-mode rst-mode
                          message-mode mail-mode))
    (let ((tick (buffer-chars-modified-tick)))
      (unless (eq tick (car unzeit/modeline--counts))
        (setq unzeit/modeline--counts
              (cons tick
                    (cons (count-words (point-min) (point-max))
                          (line-number-at-pos (point-max)))))))
    (let ((counts (cdr unzeit/modeline--counts)))
      (propertize (format "%dw/%dl" (car counts) (cdr counts))
                  'face 'unzeit-modeline-muted))))

(defvar-local unzeit/modeline--filesize nil
  "`unzeit/modeline-filesize' 的缓存：(取样时间 . 显示串)。
`file-attributes' 是一次 stat 系统调用，而这里每帧都要算。")

(defun unzeit/modeline-filesize ()
  "文件大小（1 秒内复用上次 stat）。"
  (when-let* ((file (buffer-file-name)))
    (let ((now (float-time)))
      (when (or (null unzeit/modeline--filesize)
                (>= (- now (car unzeit/modeline--filesize)) 1.0))
        (setq unzeit/modeline--filesize
              (cons now (ignore-errors
                          (file-size-human-readable
                           (file-attribute-size (file-attributes file)))))))
      (when (cdr unzeit/modeline--filesize)
        (propertize (cdr unzeit/modeline--filesize)
                    'face 'unzeit-modeline-muted)))))

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

(defconst unzeit/modeline-clock-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line down-mouse-1]
      (lambda () (interactive) (world-clock 1)))
    (define-key map [mode-line mouse-4]
      (lambda () (interactive) (text-scale-increase 1)))
    (define-key map [mode-line mouse-5]
      (lambda () (interactive) (text-scale-decrease 1)))
    map)
  "mode-line 时钟片段的鼠标键位图（mouse-1 世界时钟，滚轮字体缩放）。")

(defun unzeit/modeline-clock ()
  "时钟片段；mouse-1 = world-clock，滚轮 = 字体缩放"
  (propertize (format-time-string "%H:%M")
              'face 'unzeit-modeline-position
              'local-map unzeit/modeline-clock-map
              'mouse-face 'mode-line-highlight
              'help-echo "mouse-1: 世界时钟，滚轮: 字体缩放"))

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

(defun unzeit/--diag-severity (type)
  "把 flymake 诊断类型归一成 error/warning/nil。"
  (let ((sev (ignore-errors (flymake--severity type))))
    (cond ((eq sev :error) 'error)
          ((eq sev :warning) 'warning)
          ((numberp sev) (cond ((>= sev 3) 'error)
                               ((= sev 2) 'warning)
                               (t nil)))
          ((string-match-p "error" (format "%s" type)) 'error)
          ((string-match-p "warn" (format "%s" type)) 'warning)
          (t nil))))

(defun unzeit/modeline-code-action ()
  "有代码修复时显示灯泡，点击选 action。"
  (when (and (bound-and-true-p eglot--managed-mode)
             (boundp 'eglot--suggestion-overlay)
             (overlay-buffer eglot--suggestion-overlay))
    (let ((map (make-sparse-keymap)))
      (define-key map [mode-line down-mouse-1] #'eglot-code-actions-at-mouse)
      (propertize (concat (or eglot-code-action-indicator "💡") " ")
                  'face 'unzeit-modeline-lsp
                  'mouse-face 'mode-line-highlight
                  'local-map map
                  'help-echo "有可用的代码修复：点击选择"))))

(defun unzeit/modeline-diagnostics ()
  "Flymake 错误/警告计数；有诊断才显示。点击打开诊断列表。"
  (when (bound-and-true-p flymake-mode)
    (let* ((diags (flymake-diagnostics))
           (errs (seq-count (lambda (d) (eq 'error (unzeit/--diag-severity
                                                   (flymake-diagnostic-type d))))
                            diags))
           (warns (seq-count (lambda (d) (eq 'warning (unzeit/--diag-severity
                                                     (flymake-diagnostic-type d))))
                             diags)))
      (when (> (+ errs warns) 0)
        (let ((map (make-sparse-keymap)))
          (define-key map [mode-line down-mouse-1] #'consult-flymake)
          (concat
           (when (> errs 0)
             (propertize (format " %d" errs)
                         'face 'unzeit-modeline-error
                         'mouse-face 'mode-line-highlight
                         'local-map map
                         'help-echo "有错误：点击看诊断"))
           (when (> warns 0)
             (propertize (format " %d" warns)
                         'face 'unzeit-modeline-warning
                         'mouse-face 'mode-line-highlight
                         'local-map map
                         'help-echo "有警告：点击看诊断"))
           ;; 有计数时补一个空格，免得和后面的 LSP 粘在一起
           " "))))))

;;; ---- 模式行格式 ----------------------------------------------------

(defun unzeit/modeline-writer ()
  "专注写作模式指示（见 unzeit-writer.el；未加载时为空操作）"
  (when (bound-and-true-p unzeit/writer-mode)
    (propertize "✎"
                'face 'unzeit-modeline-lsp
                'help-echo "专注写作模式（SPC o w）")))

;;; ---- 模式行格式：左半段按 KEY 缓存 ----

(defvar-local unzeit/modeline--left-cache nil
  "缓存：(KEY . STRING)。只有 `unzeit/modeline--left-key' 变了才重拼左半段。")

(defun unzeit/modeline--left-key ()
  "左半段依赖的全部输入（缓存 KEY）。"
  (list (unzeit/window-number)
        (buffer-name) (buffer-modified-p) buffer-read-only
        (buffer-file-name) buffer-file-coding-system
        (symbol-name major-mode)
        (buffer-chars-modified-tick)
        current-input-method
        vc-mode
        (and (fboundp 'meow-indicator) (meow-indicator))
        (and (bound-and-true-p text-scale-mode) text-scale-mode-amount)
        (and (bound-and-true-p unzeit/writer-mode) t)
        (and (bound-and-true-p eglot--managed-mode) t)
        (and (boundp 'eglot--cached-server)
             (let ((proc (and eglot--cached-server
                              (ignore-errors (jsonrpc--process eglot--cached-server)))))
               (and proc (process-live-p proc))))
        (and (boundp 'eglot--suggestion-overlay)
             (let ((ov (and (overlayp eglot--suggestion-overlay)
                            eglot--suggestion-overlay)))
               (and ov (overlay-buffer ov) (overlay-end ov))))
        (and (bound-and-true-p flymake-mode)
             (mapcar #'flymake-diagnostic-type (flymake-diagnostics)))))

(defun unzeit/modeline-left ()
  "左半段：窗口号/meow 状态/文件名/编码/字数/IME/修复灯/诊断/LSP/VC/缩放/写作。"
  (let ((key (unzeit/modeline--left-key)))
    (if (and unzeit/modeline--left-cache
             (equal key (car unzeit/modeline--left-cache)))
        (cdr unzeit/modeline--left-cache)
      (let ((str (concat
                  (unzeit/modeline-window-number) " "
                  (unzeit/modeline-state) " "
                  (unzeit/modeline-buffer) " "
                  (unzeit/modeline-encoding) " "
                  (unzeit/modeline-wordcount)
                  (unzeit/modeline-ime) " "
                  (unzeit/modeline-code-action)
                  (unzeit/modeline-diagnostics)
                  (unzeit/modeline-eglot)
                  (unzeit/modeline-vc)
                  (unzeit/modeline-scale)
                  (unzeit/modeline-writer))))
        (setq unzeit/modeline--left-cache (cons key str))
        str))))

(defun unzeit/modeline-render ()
  "把整条模式行一次拼成字符串（见本节开头说明）。"
  (concat (unzeit/modeline-left)
          (propertize " " 'display '(space :align-to (right-fringe right-margin)))
          (unzeit/modeline-mode)
          " "
          (unzeit/modeline-position)
          " "
          (unzeit/modeline-clock)
          " "))

(setq-default mode-line-format
              '("%e" (:eval (unzeit/modeline-render))))

;;; editor.el ends here
(provide 'editor)

(global-set-key (kbd "C-x k") #'unzeit/kill-buffer-dwim)


;;; init-misc.el --- Unzeit: editorconfig, ws-butler, hl-todo, eshell, ... -*- lexical-binding: t; -*-

(use-package editorconfig
  :ensure nil
  :demand t
  :config
  (editorconfig-mode 1))

;; 只清理你实际编辑过的行上的行尾空白
(use-package ws-butler
  :ensure t
  :defer t
  :hook (prog-mode . ws-butler-mode))

;; TODO / FIXME / NOTE 标记（红色 = 动作）
(use-package hl-todo
  :ensure t
  :defer t
  :hook (prog-mode . hl-todo-mode)
  :custom
  (hl-todo-keyword-faces
   '(("TODO" . error)
     ("FIXME" . error)
     ("HACK" . warning)
     ("REVIEW" . warning)
     ("NOTE" . font-lock-comment-face))))

(defun unzeit/ace-window ()
  "M-o：多窗口时用 ace-window 按字母跳；只有一个窗口时给一句提示。"
  (interactive)
  (if (one-window-p t)
      (message "只有一个窗口：先 C-x 2 / C-x 3 分屏，再按 M-o")
    (require 'ace-window)
    (ace-window)))

(use-package ace-window
  :ensure t
  :defer t
  ;; M-o 原本是 facemenu 前缀，这里让给“给每个窗口标字母、按字母跳”。
  :bind ("M-o" . unzeit/ace-window)
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

;;; ---- 颜色预览：底色块 + 四边描边 -------------------------------------

;; 色块边框：向内 2px（不改字符宽度），颜色取色块自身的对比色。
(defconst unzeit/color-swatch-box '(:line-width -2)
  "颜色色块的四边描边。")

(defvar unzeit/hex-color-regexp
  "#\\([0-9a-fA-F]\\{6\\}\\|[0-9a-fA-F]\\{3\\}\\)"
  "十六进制颜色字面量正则（带 # 前缀）")

(defun unzeit/rainbow-region (beg end)
  "给 BEG..END 里的十六进制颜色画「底色 + 描边」（colorful-mode 已接管时跳过）。"
  (unless (bound-and-true-p colorful-mode)
    (save-excursion
      (goto-char beg)
      (while (re-search-forward unzeit/hex-color-regexp end t)
        (let ((color (match-string 0)))
          (when (ignore-errors (color-distance color "white"))
            (font-lock-prepend-text-property
             (match-beginning 0) (match-end 0) 'face
             `(:background ,color
               :foreground ,(if (< (color-distance color "white" nil)
                                   50000)
                                "white" "black")
               :box ,unzeit/color-swatch-box))))))))

(jit-lock-register #'unzeit/rainbow-region)

(make-variable-buffer-local 'compile-command)
(setq-default compile-command "")

(defun unzeit/compilation-no-pty ()
  "编译子进程走管道，不给 pty（否则日志里全是终端绘制）。"
  (setq-local process-connection-type nil))

(use-package compile
  :ensure nil
  :defer t
  :custom
  (compilation-scroll-output t)
  (compilation-max-output-line-length nil)
  :hook (compilation-mode . unzeit/compilation-no-pty)
  :config
  ;; 把编译输出里的 SGR/OSC 翻成 face。
  (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
  (add-hook 'compilation-filter-hook #'ansi-osc-compilation-filter))

(use-package project
  :ensure nil
  :defer t
  :bind (("C-x c" . project-compile)
         ("<f9>" . project-compile)))

(defun unzeit/switch-to-compilation ()
  "切换到编译缓冲"
  (interactive)
  (switch-to-buffer (or (compilation-find-buffer) "*compilation*")))

(defun unzeit/hide-compilation ()
  "隐藏编译缓冲窗口"
  (interactive)
  (when-let* ((win (get-buffer-window (compilation-find-buffer) t)))
    (delete-window win)))

(use-package yasnippet
  :ensure t
  :defer t
  :hook ((prog-mode . yas-minor-mode)
         (html-mode . yas-minor-mode))
  :config
  (make-directory (locate-user-emacs-file "snippets/") t)

  ;; web 模板族：TAB 不展开 snippet，snippet 表裁到 html/web，标签名内不给候选。
  (defconst unzeit/web-family-modes '(html-mode web-mode mhtml-mode)
    "web 模板族的主模式；它们的后代共用同一套 TAB / snippet 规则。")

  (defun unzeit/web-family-p (&optional mode)
    "MODE（默认 `major-mode'）是否属于 web 模板族。"
    (apply #'provided-mode-derived-p (or mode major-mode)
           unzeit/web-family-modes))

  (defconst unzeit/yas-web-dropped-tables '(nxml-mode js-mode js-ts-mode)
    "web 族不该继承的 snippet 表（见本节 ②）。")

  (defun unzeit/yas--modes-to-activate-web (orig &optional mode)
    "web 族里裁掉 NXML / JS 的 snippet 表继承。"
    (let ((modes (funcall orig mode)))
      (if (unzeit/web-family-p (or mode major-mode))
          (seq-difference modes unzeit/yas-web-dropped-tables)
        modes)))

  (defun unzeit/yas-expand-web-tab (orig &rest args)
    "web 缓冲里 TAB 走 `unzeit/tab-dwim'（缩进 / 补全），不展开 snippet。"
    (if (unzeit/web-family-p)
        (unzeit/tab-dwim)
      (apply orig args)))

  (defun unzeit/at-html-tag-name-p ()
    "点是否紧跟在 `<标签名' 之后（HTML/JSP 的标签名内部）。"
    (save-excursion
      (skip-chars-backward "[:alnum:]_.:-")
      (eq (char-before) ?<)))

  (defun unzeit/yasnippet-capf-web-guard (orig &rest args)
    "web 族里在标签名内部不给 snippet 候选（见本节 ③）。"
    (if (and (unzeit/web-family-p) (unzeit/at-html-tag-name-p))
        nil
      (apply orig args)))

  (advice-add 'yas-expand :around #'unzeit/yas-expand-web-tab)
  (advice-add 'yas--modes-to-activate :around #'unzeit/yas--modes-to-activate-web)
  (advice-add 'yasnippet-capf :around #'unzeit/yasnippet-capf-web-guard)

  ;; snippet 活动域里的 TAB：补全优先，跳域兜底（函数在 completion.el）。
  (define-key yas-keymap (kbd "TAB")
    (if (fboundp 'yas-filtered-definition)
        (yas-filtered-definition #'unzeit/snippet-tab)
      #'unzeit/snippet-tab)))

(use-package yasnippet-snippets
  :ensure t
  :defer t)

(use-package yasnippet-capf
  :ensure t
  :defer t
  :init
  (add-hook 'completion-at-point-functions #'yasnippet-capf 30))

;; .c <-> .h 切换
(use-package files
  :ensure nil
  :defer t
  :bind (("C-x M-f" . find-sibling-file)
         ("C-c C-f" . find-file-other-window))
  :custom
  (find-sibling-rules '(("\\([^/]+\\)\\.c\\'" "\\1.h")
                        ("\\([^/]+\\)\\.h\\'" "\\1.c")
                        ("\\([^/]+\\)\\.cc\\'" "\\1.h")
                        ("\\([^/]+\\)\\.cpp\\'" "\\1.hpp")
                        ("\\([^/]+\\)\\.hpp\\'" "\\1.cpp"))))

;; lambda→λ、-> → 等符号美化（无害）
(use-package prog-mode
  :ensure nil
  :defer t
  :hook (prog-mode . prettify-symbols-mode)
  :init
  (setq prettify-symbols-unprettify-at-point 'right-edge))

;; 分析器（内置）：C-c p b/e/r
(use-package profiler
  :ensure nil
  :defer t
  :bind (("C-c p b" . profiler-start)
         ("C-c p e" . profiler-stop)
         ("C-c p r" . profiler-report)))

(defconst unzeit/indent-specs
  '((c-mode         tab 4   c-basic-offset)
    (c-ts-mode      tab 4   c-ts-mode-indent-offset)
    (c++-mode       tab 4   c-basic-offset)
    (c++-ts-mode    tab 4   c-ts-mode-indent-offset)
    (java-mode      tab 4   java-basic-offset)
    (cmake-mode     tab 4   cmake-tab-width)
    (cmake-ts-mode  tab 4   cmake-ts-mode-indent-offset)
    (go-ts-mode     tab 4   go-ts-mode-indent-offset)
    (emacs-lisp-mode space -1 lisp-indent-offset)
    (lisp-mode      space -1 lisp-indent-offset)
    (lisp-interaction-mode space -1 lisp-indent-offset)
    (js-mode        space 2 js-indent-level)
    (json-ts-mode   space 2 js-indent-level)
    (typescript-ts-mode space 2 typescript-indent-level)
    (tsx-ts-mode    space 2 typescript-indent-level)
    (css-mode       space 2 css-indent-offset)
    (css-ts-mode    space 2 css-indent-offset)
    (html-mode      space 2 nil)
    (mhtml-ts-mode  space 2 nil)
    (web-mode       space 2 web-mode-markup-indent-offset)
    (nxml-mode      space 2 nil)
    (yaml-mode      space 2 yaml-indent-offset)
    (yaml-ts-mode   space -1 nil)
    (toml-ts-mode   space 2 nil)
    (lua-ts-mode    space 2 nil)
    (meson-mode     space 2 meson-indent-level)
    (python-mode    space 4 python-indent-offset)
    (python-ts-mode space 4 python-indent-offset)
    (rust-ts-mode   space 4 rust-ts-mode-indent-offset)
    (zig-mode       space 4 zig-indent-offset)
    (haskell-mode   space 4 haskell-indent-offset)
    (c3-ts-mode     space 4 c-ts-mode-indent-offset)
    (odin-ts-mode   space 4 nil))
  "主模式的缩进规格：(MODE STYLE WIDTH OFFSET-VAR)。
查找见 `unzeit/indent-spec'。")

(defun unzeit/indent-spec ()
  "返回当前缓冲的缩进规格 (MODE STYLE WIDTH OFFSET-VAR)。"
  (or (assq major-mode unzeit/indent-specs)
      (seq-find (lambda (spec)
                  (provided-mode-derived-p major-mode (car spec)))
                unzeit/indent-specs)))

(add-hook 'change-major-mode-after-body-hook
          (lambda ()
            (when-let* ((spec (unzeit/indent-spec)))
              (pcase (nth 1 spec)
                ('tab (unzeit/indent-tabs (nth 2 spec)))
                ('space (unzeit/indent-spaces (nth 2 spec)))))))

(defun unzeit/set-indent-offset (num)
  "把当前模式的缩进偏移设为 NUM（负数置 nil）。"
  (interactive `(,(read-number "Indent offset (chars): ")))
  (let ((offset (nth 3 (unzeit/indent-spec))))
    (when offset
      (make-local-variable offset)
      (if (< num 0)
          (set offset nil)
        (set offset num)))))

(defun unzeit/indent-tabs (num)
  "标记此缓冲用 tab 缩进，并把缩进偏移设为 NUM 字符"
  (interactive `(,(read-number "Indent offset (chars): ")))
  (indent-tabs-mode 1)
  (unzeit/set-indent-offset num))

(defun unzeit/indent-spaces (num)
  "标记此缓冲用空格缩进，并把缩进偏移设为 NUM 字符"
  (interactive `(,(read-number "Indent offset (chars): ")))
  (indent-tabs-mode -1)
  (unzeit/set-indent-offset num))

(defun unzeit/set-tab-width (num)
  "标记此缓冲，把 tab 宽度设为 NUM 字符"
  (interactive `(,(read-number "Tab width (chars): " tab-width)))
  (when (/= tab-width num)
    (setq tab-width num)))

(defconst unzeit/skip-guess-indent-modes
  '(lisp-mode emacs-lisp-mode lisp-interaction-mode)
  "对这些主模式不做缩进猜测")

(defun unzeit/guess-indent ()
  "扫描前 200 行猜缩进偏移与 tab/space，并设好。"
  (interactive)
  (if (member major-mode unzeit/skip-guess-indent-modes)
      (message "对 %s 跳过 guess-indent" (symbol-name major-mode))
    (let* ((total-lines (count-lines (point-min) (point-max)))
           (detect-lines (min total-lines 200))
           (shortest-spaces 0)
           (has-tab nil))
      (save-mark-and-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          (dotimes (_ detect-lines)
            (goto-char (line-beginning-position))
            (let ((current-char (char-after)))
              (cond
               ((= current-char ?\t) (setq has-tab t))
               ((= current-char ?\s)
                (let ((spaces 0))
                  (while (= current-char ?\s)
                    (setq spaces (1+ spaces))
                    (forward-char)
                    (setq current-char (char-after)))
                  (when (and (> spaces 0)
                             (/= spaces 1)
                             (or (= shortest-spaces 0)
                                 (< spaces shortest-spaces)))
                    (setq shortest-spaces spaces))))))
            (forward-line 1))
          (if has-tab
              (unzeit/indent-tabs shortest-spaces)
            (unzeit/indent-spaces shortest-spaces)))))))

(global-set-key (kbd "C-c i TAB") #'unzeit/indent-tabs)
(global-set-key (kbd "C-c i SPC") #'unzeit/indent-spaces)
(global-set-key (kbd "C-c i o") #'unzeit/set-indent-offset)
(global-set-key (kbd "C-c i w") #'unzeit/set-tab-width)
(global-set-key (kbd "C-c i g") #'unzeit/guess-indent)

(use-package move-text
  :ensure t
  :defer t
  :bind (:map prog-mode-map
         ("M-p" . move-text-up)
         ("M-n" . move-text-down)
         :map text-mode-map
         ("M-p" . move-text-up)
         ("M-n" . move-text-down)))

;; 无选区时对整行操作
(use-package whole-line-or-region
  :ensure t
  :demand t
  :config
  (whole-line-or-region-global-mode 1))

(use-package indent-bars
  :ensure t
  :defer t
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  ;; 实线：pattern "." 填满整格，width 0.08、pad 0.125。
  (indent-bars-prefer-character nil)
  (indent-bars-pattern ".")
  (indent-bars-width-frac 0.08)
  (indent-bars-pad-frac 0.125)
  (indent-bars-starting-column 0)
  (indent-bars-display-on-blank-lines t)
  (indent-bars-zigzag nil)
  ;; 缩进线颜色：显式 #8a94c8（与高亮底色混合在深色主题上太淡，不能交给主题的
  ;; toolbar 灰；沿革：TN ← Ember #908a7e → City Lights #688094 → 换回）。
  (indent-bars-color '("#8a94c8"))
  ;; 按层级彩虹色在暖灰主题下太花，关掉
  (indent-bars-color-by-depth nil)
  (indent-bars-highlight-current-depth nil))

(use-package popper
  :ensure t
  :demand t
  :bind (("C-'" . popper-toggle)
         ("C-M-'" . popper-toggle-type))
  :config
  (popper-mode 1)
  (popper-echo-mode 1)
  :custom
  (popper-group-function #'popper-group-by-directory)
  (popper-echo-dispatch-actions t)
  (popper-reference-buffers '("\\*Backtrace\\*"
                              "\\*IBuffer\\*"
                              "\\*Warnings\\*"
                              "\\*Compile-Log\\*"
                              "Output\\*$"
                              "\\*Async Shell Command\\*"
                              help-mode))
  (popper-mode-line ""))

(use-package meson-mode
  :ensure t
  :defer t
  :mode (("meson\\.build\\'" . meson-mode)
         ("meson\\.options\\'" . meson-mode)
         ("meson_options\\.txt\\'" . meson-mode)))

(use-package ibuffer
  :ensure nil
  :defer t
  :bind ("C-x C-b" . ibuffer))

(use-package eshell
  :ensure nil
  :defer t
  :custom
  (eshell-scroll-show-maximum-output t))

(defun unzeit/eshell-setup ()
  "给 eshell 补上 C-r 历史搜索。"
  (keymap-set eshell-mode-map "C-r" #'consult-history))

(add-hook 'eshell-mode-hook #'unzeit/eshell-setup)

(use-package tramp
  :ensure nil
  :defer t
  :custom
  (tramp-persistency-file-name (expand-file-name "tramp" unzeit/cache-dir)))

;;; ---- dev 工作流的零碎 ----------------------------------

(use-package envrc
  :ensure t
  :if (executable-find "direnv")
  :hook (after-init . envrc-global-mode))

(use-package magit-delta
  :ensure t
  :if (executable-find "delta")
  :hook (magit-mode . magit-delta-mode)
  :custom
  (magit-delta-hide-plus-minus-markers t))

;; CSS 颜色只留 colorful 一套（css-fontify-colors 关掉，否则色块叠底、边框被盖）。
(setq css-fontify-colors nil)

(use-package colorful-mode
  :ensure t
  :hook ((prog-mode conf-mode) . colorful-mode)
  :custom
  ;; 用「底色 + 边框」预览，不用 ● 前缀（前缀会占掉左边一格）。
  (colorful-use-prefix nil)
  :config
  ;; 默认是 bold + 1px 内框；改常规字重 + 2px 内框，框才看得出来。
  (set-face-attribute 'colorful-base nil
                      :weight 'normal
                      :box unzeit/color-swatch-box))

(use-package eat
  :ensure t
  :defer t
  :commands (eat eat-project eat-compile)
  :custom
  (eat-kill-buffer-on-exit t)
  (eat-shell "zsh")
  (eat-eshell-visual-command-mode t))

;;; ---- 编辑器的「注视感」 --------------------------------------

;; 光标下符号高亮：空闲 0.3s 后扫，只在 prog/conf 开。
(use-package symbol-overlay
  :ensure t
  :hook ((prog-mode conf-mode) . symbol-overlay-mode)
  :custom
  (symbol-overlay-idle-time 0.3))

;;; ---- 小体量视觉增强 ------------------------------------------

;; 数字统一染色（常量、端口、尺寸一眼能扫）
(use-package highlight-numbers
  :ensure t
  :hook ((prog-mode conf-mode) . highlight-numbers-mode))

;; 括号按嵌套深度上色，只给 lisp 系（省一次 font-lock 扫描）。
(use-package rainbow-delimiters
  :ensure t
  :hook ((emacs-lisp-mode lisp-mode scheme-mode) . rainbow-delimiters-mode)
  :custom
  (rainbow-delimiters-max-face-count 4))

;;; ---- 持久化 undo / smerge -------------------------------------------

(use-package undo-fu-session
  :ensure t
  :defer 1
  :config
  (undo-fu-session-global-mode 1))

;; 打开到冲突标记时自动进入 smerge-mode；超大缓冲跳过
(use-package smerge-mode
  :ensure nil
  :hook (find-file . (lambda ()
                       (when (< (buffer-size) (* 2 1024 1024))
                         (save-excursion
                           (goto-char (point-min))
                           (when (re-search-forward "^<<<<<<< " nil t)
                             (smerge-mode 1)))))))

;;; init-misc.el ends here
(provide 'init-misc)

;;; ---- Git 增强（magit-todos / timemachine / browse-at-remote / messenger）----

(use-package magit-todos
  :ensure t
  :after magit
  :hook (magit-mode . magit-todos-mode))

(use-package git-timemachine
  :ensure t
  :defer t)

(use-package browse-at-remote
  :ensure t
  :defer t)

(use-package git-messenger
  :ensure t
  :defer t)

(use-package git-modes
  :ensure t
  :defer t)


(provide 'init-misc)

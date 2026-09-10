;;; init-misc.el --- Unzeit: editorconfig, ws-butler, hl-todo, eshell, ... -*- lexical-binding: t; -*-

;;; Commentary:
;; 所有无处安放的东西：小型的“生活质量”包以及内置便利功能

;;; Code:

(use-package editorconfig
  :ensure t
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

;; 窗口/缓冲切换：ace-window 用字符选中窗口（SPC w w 选中、SPC w a 交换）
;; 去掉其默认全局 M-o 绑定，只用 leader 键，避免与 meow/其他冲突
(use-package ace-window
  :ensure t
  :defer t
  :commands (ace-window ace-swap-window)
  :config
  (global-unset-key (kbd "M-o")))

;; 十六进制颜色（#ff0000、#abc）用自身的颜色渲染
;; 用 jit-lock 实现而非 rainbow-mode：rainbow-mode 只挂到
;; font-lock-keywords，而 treesit 模式（css-ts-mode、go-ts-mode ...）从不
;; 查询它 —— 所以在那些模式里它静默失效jit-lock 函数在所有模式里运行，
;; 且对 treesit 依旧有效
(defvar unzeit/hex-color-regexp
  "#\\([0-9a-fA-F]\\{6\\}\\|[0-9a-fA-F]\\{3\\}\\)"
  "十六进制颜色字面量正则（带 # 前缀）")

(defun unzeit/rainbow-region (beg end)
  "用颜色自身的颜色渲染 BEG 与 END 之间的十六进制颜色字面量"
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
                              "white" "black"))))))))

(jit-lock-register #'unzeit/rainbow-region)

;; 编译 —— project-compile + 每个项目通过 .dir-locals.el 设置
;; 各自的 `compile-command'（它必须是 buffer-local 才能按项目设置）
(make-variable-buffer-local 'compile-command)
(use-package compile
  :ensure nil
  :defer t
  :custom
  (compilation-scroll-output t)
  (compilation-max-output-line-length nil))

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

;; 代码片段
;; 由 yasnippet-capf 喂给 corfu 弹窗）
(use-package yasnippet
  :ensure t
  :defer t
  :hook (prog-mode . yas-minor-mode)
  :config
  (make-directory (locate-user-emacs-file "snippets/") t))

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

;; 把 lambda 显示为 λ、-> 显示为 → 等（centaur 风格，无害）
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

;; 缩进控制：按模式设置缩进偏移变量、每模式的默认
;; tab/space、C-c i 键、guess-indent

(defconst unzeit/mode-indent-offsets
  '((c-mode c-basic-offset)
    (c-ts-mode c-ts-mode-indent-offset)
    (c++-mode c-basic-offset)
    (c++-ts-mode c-ts-mode-indent-offset)
    (cmake-mode cmake-tab-width)
    (cmake-ts-mode cmake-ts-mode-indent-offset)
    (css-mode css-indent-offset)
    (css-ts-mode css-indent-offset)
    (emacs-lisp-mode lisp-indent-offset)
    (java-mode java-basic-offset)
    (js-mode js-indent-level)
    (js2-mode js2-basic-offset)
    (json-ts-mode js-indent-level)
    (typescript-ts-mode typescript-indent-level)
    (web-mode web-mode-markup-indent-offset)
    (python-mode python-indent-offset)
    (python-ts-mode python-indent-offset)
    (rust-ts-mode rust-ts-mode-indent-offset)
    (zig-mode zig-indent-offset)
    (haskell-mode haskell-indent-offset)
    (c3-ts-mode c-ts-mode-indent-offset)
    (yaml-mode yaml-indent-offset)
    (meson-mode meson-indent-level))
  "主模式及其缩进偏移变量的关联列表")

(defconst unzeit/modes-default-indent
  '((prog-mode tab 4)
    (c-mode tab 4)
    (c-ts-mode tab 4)
    (java-mode tab 4)
    (lisp-mode space -1)
    (emacs-lisp-mode space -1)
    (lisp-interaction-mode space -1)
    (js-mode space 2)
    (js2-mode space 2)
    (json-ts-mode space 2)
    (typescript-ts-mode space 2)
    (css-mode space 2)
    (html-mode space 2)
    (nxml-mode space 2)
    (web-mode space 2)
    (yaml-mode space 2)
    (yaml-ts-mode space -1)
    (meson-mode space 2)
    (python-mode space 4)
    (python-ts-mode space 4)
    (rust-ts-mode space 4)
    (zig-mode space 4)
    (haskell-mode space 4)
    (c3-ts-mode space 4)
    (odin-ts-mode space 4))
  "不同模式的默认缩进方式（tab/space 及宽度）")

;; 在 .editorconfig / .dir-locals.el 之前运行，它们会覆盖这些默认值
(add-hook 'change-major-mode-after-body-hook
          (lambda ()
            (let* ((pair (assq major-mode unzeit/modes-default-indent))
                   (mode (nth 1 pair))
                   (indent-offset (nth 2 pair)))
              (cond
               ((eq mode 'tab) (unzeit/indent-tabs indent-offset))
               ((eq mode 'space) (unzeit/indent-spaces indent-offset))))))

(defun unzeit/set-indent-offset (num)
  "把当前模式的缩进偏移设为 NUM 字符
若 NUM 为负，缩进偏移将设为 nil"
  (interactive `(,(read-number "Indent offset (chars): ")))
  (let ((offset (cadr (assq major-mode unzeit/mode-indent-offsets))))
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
  "猜测并设置当前缓冲的缩进偏移与 tab/space
扫描前 200 行：除 0/1 外最短的空格前缀即为缩进偏移；任何 tab 前缀的
行意味着用 tab"
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

;; 上下移动行（M-p/M-n）只在 prog/text 映射里绑定，这样 minibuffer
;; 里 M-n/M-p 留给 corfu/vertico 候选导航
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

;; 缩进参考线
(use-package highlight-indent-guides
  :ensure t
  :defer t
  :hook (prog-mode . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-method 'character)
  (highlight-indent-guides-responsive 'top))

;; 弹出窗口管理器：C-' 切换编译 / 帮助等 popup
;;（M-' 保留给 consult-register-store；这里只有 toggle + toggle-type）
(use-package popper
  :ensure t
  :demand t
  :bind (("C-'" . popper-toggle)
         ("C-M-'" . popper-toggle-type))
  :config
  (popper-mode 1)
  (popper-echo-mode 1)
  :custom
  (popper-reference-buffers '("\\*Backtrace\\*"
                              "\\*IBuffer\\*"
                              "\\*Warnings\\*"
                              ;; 不要让 popper 吸收 `*Completions*`：在 GUI
                              ;; 帧里它会把候选列表重绘成一个挡住缓冲的巨大
                              ;; popup
                              "\\*Compile-Log\\*"
                              "Output\\*$"
                              "\\*Async Shell Command\\*"
                              help-mode))
  (popper-mode-line ""))

;; 粘性函数头
(use-package topsy
  :ensure t
  :defer t
  :hook (prog-mode . topsy-mode))

;; 颜色预览
(use-package rainbow-mode
  :ensure t
  :defer t
  :hook ((prog-mode . rainbow-mode)
         (text-mode . rainbow-mode)))

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

(use-package tramp
  :ensure nil
  :defer t
  :custom
  (tramp-persistency-file-name (expand-file-name "tramp" unzeit/cache-dir)))

;;; init-misc.el ends here
(provide 'init-misc)

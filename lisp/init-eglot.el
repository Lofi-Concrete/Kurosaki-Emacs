;;; init-eglot.el --- Unzeit: LSP / tree-sitter / apheleia 核心 -*- lexical-binding: t; -*-

;;; ---- Tree-sitter（全局旋钮）--------------------------------------

(require 'treesit)

;; jsonrpc 的进程缓冲是 unibyte 的，解析出的非 ASCII 字符串是 UTF-8 原始字节
;; （clangd 的 •/… 会显示成 \342\200\242）。在 jsonrpc 出口统一解码，
;; eglot 的补全候选/doc/诊断就都正常了。
(defun unzeit/decode-json-string (s)
  "S 是非 multibyte 的 UTF-8 原始字节时解码；否则原样。"
  (if (and (stringp s) (not (multibyte-string-p s)))
      (decode-coding-string s 'utf-8)
    s))

(defun unzeit/decode-json-strings (obj)
  "递归解码 OBJ 中的字符串。"
  (cond ((stringp obj) (unzeit/decode-json-string obj))
        ((consp obj) (cons (unzeit/decode-json-strings (car obj))
                           (unzeit/decode-json-strings (cdr obj))))
        ((vectorp obj) (vconcat (mapcar #'unzeit/decode-json-strings obj)))
        (t obj)))

(defun unzeit/jsonrpc-decode (orig &rest args)
  "在 jsonrpc 读到消息后解码其中的字符串。"
  (unzeit/decode-json-strings (apply orig args)))

(with-eval-after-load 'jsonrpc
  (unless (advice-member-p #'unzeit/jsonrpc-decode #'jsonrpc--json-read)
    (advice-add 'jsonrpc--json-read :around #'unzeit/jsonrpc-decode)))

;; Centaur 方案：Emacs 31 用 `treesit-enabled-modes' 统一启用内置 ts-mode；
;; 不再维护 `treesit-language-source-alist' 的逐语言 source；语法预装
;; （Guix profile 或 ~/.emacs.d/tree-sitter），缺了只提示、不自动编译。
(setq treesit-language-source-alist nil)

;; 兼容旧变量：即使不装 treesit-auto，也确保没有“自动装语法”的开关被打开。
(setq treesit-auto-install-grammar nil)

(setq treesit-extra-load-path
      (list (expand-file-name "~/.guix-home/profile/lib/tree-sitter")
            (locate-user-emacs-file "tree-sitter")))

(setq treesit-font-lock-level 3)

;; 启用所有内置 ts-mode，但 rust/markdown 保持经典模式（Centaur 的意图）。
;; 注意：31.1 的 `treesit-enabled-modes' 只接受“ts-mode 列表或 t”，
;; 且 `setq' 不会触发它的 :set —— 必须用 `customize-set-variable'。
(when (and (boundp 'treesit-enabled-modes)
           (boundp 'treesit-major-mode-remap-alist))
  (customize-set-variable
   'treesit-enabled-modes
   (seq-remove (lambda (m) (memq m '(rust-ts-mode markdown-ts-mode)))
               (mapcar #'cdr treesit-major-mode-remap-alist))))

(defvar unzeit/treesit-languages nil
  "本配置登记过的语法语言（去重，仅供 doctor/smoke 检查）。")

(defun unzeit/treesit-source (lang _url &optional _dir)
  "兼容旧语言文件：只登记 LANG；语法来源交给 Guix/手工预装（Centaur 方案）。"
  (add-to-list 'unzeit/treesit-languages lang))

(defun unzeit/treesit-ensure-grammar (&rest _)
  "缺语法时只在回显区提示，绝不弹问、绝不在 find-file 里编译。"
  (when-let* ((lang (treesit-language-at (point))))
    (unless (treesit-language-available-p lang)
      (message "Unzeit：缺少 %s 的 tree-sitter 语法（M-x treesit-install-language-grammar 安装）"
               lang))))

(advice-add 'treesit-major-mode-setup :after #'unzeit/treesit-ensure-grammar)

(defun unzeit/remap-mode (classic ts)
  "把经典模式 CLASSIC 重映射到 TS 变体（登记进 `major-mode-remap-alist'）。"
  (add-to-list 'major-mode-remap-alist (cons classic ts)))

;;; ---- 按需加载语言主模式（shim 宏）--------------------------------

(defmacro unzeit/define-on-demand-mode (mode package regexp &rest args)
  "定义按需加载的语言主模式入口（PACKAGE/REGEXP/ARGS）。"
  (declare (indent 2))
  (let* ((entry (intern (format "unzeit/%s" mode)))
         ;; 正则允许写成字符串，或（可能带 quote 的）字符串列表
         (raw (if (and (consp regexp) (eq (car regexp) 'quote))
                  (cadr regexp)
                regexp))
         (regexps (if (listp raw) raw (list raw)))
         (vc-url (plist-get args :vc))
         (also (plist-get args :also)))
    `(progn
       (defun ,entry ()
         ,(format "按需安装并加载 %s，然后进入 %s。" package mode)
         (interactive)
         (condition-case err
             (progn
               (unzeit/ensure-package ',package ',vc-url)
               ,@(mapcar (lambda (pkg) `(unzeit/ensure-package ',pkg)) also)
               (require ',package nil t)
               ,@(mapcar (lambda (pkg) `(require ',pkg nil t)) also)
               (if (fboundp ',mode)
                   (progn
                     (dolist (re ',regexps)
                       (when-let* ((cell (assoc re auto-mode-alist)))
                         (setcdr cell ',mode)))
                     (funcall #',mode))
                 (fundamental-mode)
                 (message "Unzeit：%s 没有提供 %s，暂用 fundamental-mode"
                          ',package ',mode)))
           (error
            (fundamental-mode)
            (message "Unzeit：加载 %s 失败（%s），暂用 fundamental-mode"
                     ',package err))))
       (dolist (re ',regexps)
         (add-to-list 'auto-mode-alist (cons re #',entry))))))

;;; ---- 登记助手（给 ~/.emacs.d/langs/*.el 用）----------------------

(defvar unzeit/eglot-registered-servers nil
  "本配置登记过的 LSP 条目（供体检区分内建表）。")

(defun unzeit/eglot-server (spec)
  "把 SPEC 登记进 eglot-server-programs，并记进清单。"
  (setq unzeit/eglot-registered-servers
        (cons spec unzeit/eglot-registered-servers))
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs spec)))

(defun unzeit/apheleia-formatter (spec)
  "登记自定义 formatter（必须 add-to-list，setq 会清空内置）。"
  (with-eval-after-load 'apheleia
    (add-to-list 'apheleia-formatters spec)))

(defvar unzeit/apheleia-mode-alist nil
  "各语言文件登记进来的 `apheleia-mode-alist' 条目（保存时用哪个格式化器）。")

(defun unzeit/apheleia-mode (alist)
  "把 ALIST 合并进登记表；apheleia 加载后整体生效（见下面的 `:config'）。"
  (setq unzeit/apheleia-mode-alist
        (append alist unzeit/apheleia-mode-alist)))

;;; ---- Eglot（补全 + 诊断后端）-------------------------------------

(defun unzeit/eglot-ensure-auto ()
  "prog 派生模式自动连 LSP；web-mode 只放行 jsp，elisp/makefile 等不连（Centaur 同款）。"
  (cond ((derived-mode-p 'jsp-mode) (eglot-ensure))
        ((derived-mode-p 'web-mode) nil)
        ((derived-mode-p 'emacs-lisp-mode 'lisp-mode 'makefile-mode
                         'snippet-mode 'ron-mode
                         'dart-mode 'julia-ts-mode 'julia-mode
                         'php-mode 'scala-ts-mode 'swift-ts-mode
                         'powershell 'cmake-mode 'csv-mode 'fish-mode
                         'protobuf-mode)
         nil)
        (t (eglot-ensure))))

(use-package eglot
  :ensure nil
  :defer t
  :custom
  (eglot-send-changes-idle-time 0.3)
  (eglot-extend-to-xref t)
  (eglot-sync-connect 0)
  (eglot-autoshutdown t)
  (eglot-report-progress nil)
  (eglot-events-buffer-config '(:size 0 :format full))
  :hook ((prog-mode . unzeit/eglot-ensure-auto)
         (yaml-ts-mode . eglot-ensure)
         (html-mode . eglot-ensure))
  :config
  ;; 格式化交给 apheleia，别让 server 也来一遍
  (dolist (cap '(:documentFormattingProvider
                 :documentRangeFormattingProvider
                 :documentOnTypeFormattingProvider))
    (add-to-list 'eglot-ignored-server-capabilities cap)))

(use-package consult-eglot
  :ensure t
  :defer t
  :bind (:map eglot-mode-map
          ("C-M-." . consult-eglot-symbols)))

;;; ---- 诊断的"现代"显示：行尾摘要只留最严重一条，做成暖色色块 ----
(setq flymake-show-diagnostics-at-end-of-line 'short)

(defconst unzeit/flymake-eol-chips
  '((flymake-error-echo-at-eol    "#ffb3b3" "#3d1c20"
     (:line-width (4 . 1) :color "#8a3a40"))
    (flymake-warning-echo-at-eol  "#ffd998" "#3a2b12"
     (:line-width (4 . 1) :color "#8a6a2a"))
    (flymake-note-echo-at-eol     "#9cf0bb" "#123322"
     (:line-width (4 . 1) :color "#2f6b47"))
    ;; "and N more"：不留底色/边框，压到最暗的一档
    (flymake-eol-information-face "#7d8590" unspecified nil))
  "行尾诊断标签的 (FACE 前景 背景 边框)：暖色块 = 批注，别和语法高亮混。
换风格只改这张表；`:box' 写 nil 表示不要边框。")

;;; ---- 只显示红色 error，warning/note 默认不显示 ---------------------

;; warning/note 默认不显示（C-c W 开关）：行尾只在有 error 时出摘要。
(defcustom unzeit/diagnostics-show-warnings t
  "非 nil 时行尾摘要也显示 warning/note；默认显示黄/红两种 chip。"
  :type 'boolean
  :group 'unzeit)

(defun unzeit/diagnostics--eol-filter (orig src-ovs)
  "没有 error 时不生成行尾摘要。"
  (let ((sevs (mapcar (lambda (o)
                        (flymake--severity
                         (flymake-diagnostic-type
                          (overlay-get o 'flymake-diagnostic))))
                      src-ovs)))
    (when (or unzeit/diagnostics-show-warnings (memq :error sevs))
      (funcall orig src-ovs))))


(defun unzeit/diagnostics-toggle-warnings ()
  "切换行尾摘要是否显示 warning/note（默认只显示 error）。"
  (interactive)
  (setq unzeit/diagnostics-show-warnings
        (not unzeit/diagnostics-show-warnings))
  (dolist (b (buffer-list))
    (with-current-buffer b
      (when (bound-and-true-p flymake-mode)
        (ignore-errors (flymake--update-eol-overlays)))))
  (message "行尾诊断：%s"
           (if unzeit/diagnostics-show-warnings
               "error + warning/note"
             "只显示 error")))

;; 不要 flymake-popon：每次弹出建 GTK 子框架，实测 82ms；诊断看行尾/eldoc/C-c f。

(add-hook 'eglot-managed-mode-hook #'eglot-inlay-hints-mode)

(defun unzeit/eglot-capf ()
  "在 eglot 缓冲里把 LSP 与 yasnippet 合成一个 capf。"
  (require 'cape)
  (setq-local completion-at-point-functions
              (list (cape-capf-super #'eglot-completion-at-point
                                     #'yasnippet-capf)
                    #'cape-file)))

(add-hook 'eglot-managed-mode-hook #'unzeit/eglot-capf)

;;; ---- Flymake / Elisp 诊断（照 acdcbyl/init-check）-------------------

(setq trusted-content (list (expand-file-name "lisp/" user-emacs-directory)))

(use-package flymake
  :ensure nil
  :bind ("C-c f" . flymake-show-buffer-diagnostics)
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-suppress-zero-counters t)
  (flymake-no-changes-timeout 0.15)
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-margin-indicator-position 'right-margin)
  :config
  ;; 行尾摘要过滤：默认只在有 error 时出摘要（见 `unzeit/diagnostics-show-warnings'）。
  (when (fboundp 'flymake--eol-overlay-summary)
    (advice-add 'flymake--eol-overlay-summary :around
                #'unzeit/diagnostics--eol-filter))
  ;; 行尾标签：四列样式见 `unzeit/flymake-eol-chips' 的注释。
  (pcase-dolist (`(,face ,fg ,bg ,bd) unzeit/flymake-eol-chips)
    (set-face-attribute face nil
                        :foreground fg :background bg
                        :slant 'normal :underline nil :box bd))
  ;; doom 主题会给 flymake 诊断加波浪下划线；正文里只保留行尾那一处标记。
  (dolist (face '(flymake-error flymake-warning flymake-note))
    (set-face-attribute face nil :underline nil))
  (defun unzeit/elisp-flymake-byte-compile (fn &rest args)
    "让 elisp 字节编译检查器也看到当前 `load-path'。"
    (let ((elisp-flymake-byte-compile-load-path
           (append elisp-flymake-byte-compile-load-path load-path)))
      (apply fn args)))
  (advice-add 'elisp-flymake-byte-compile :around
              #'unzeit/elisp-flymake-byte-compile))

;;; ---- Apheleia（保存时格式化）--------------------------------------

(use-package apheleia
  :ensure t
  :demand t
  :config
  ;; Centaur 方案：全局开。语言文件的 `unzeit/apheleia-mode' 登记在 langs/
  ;; 加载之后才齐，所以合并放到 `unzeit/apheleia-merge'（init.el 调）。
  (if (fboundp 'apheleia-global-mode)
      (apheleia-global-mode 1)
    (add-hook 'prog-mode-hook #'apheleia-mode)))

(defun unzeit/apheleia-merge ()
  "把 langs/ 登记的自定义 formatter 合并进 `apheleia-mode-alist'。
不整体 setq，否则会清掉内置 formatter（见 AGENTS）。"
  (dolist (entry unzeit/apheleia-mode-alist)
    (add-to-list 'apheleia-mode-alist entry)))

;;; ---- LSP 性能 + 生命周期 --------------------------------------------

(when (and (locate-library "eglot-booster")
           (executable-find "emacs-lsp-booster"))
  (require 'eglot-booster)
  (eglot-booster-mode 1))

(setq eglot-autoshutdown t)

;;; init-eglot.el ends here
(provide 'init-eglot)

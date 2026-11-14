;;; completion.el --- Unzeit: minibuffer 与缓冲内补全栈 -*- lexical-binding: t; -*-

(use-package vertico
  :ensure t
  :demand t
  :custom
  (vertico-count 15)
  (vertico-cycle t)
  (vertico-resize t)
  :config
  (vertico-mode 1))

(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
          ("RET" . vertico-directory-enter)
          ("DEL" . vertico-directory-delete-char)
          ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :ensure t
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles orderless basic partial-completion))))
  (completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (orderless-component-separator #'orderless-escapable-split-on-space))

;; Centaur 方案：CJK 候选可以用拼音首字母匹配（如 "wj" 命中 "文件"）。
(use-package pinyinlib
  :ensure t
  :after orderless
  :functions orderless-regexp
  :init
  (defun unzeit/orderless-regexp-pinyin (component)
    "把含 CJK 的 COMPONENT 展开成拼音 regexp。"
    (if (or (not (string-match-p "\\cc" component))
            (ignore-errors (orderless-regexp component)))
        (orderless-regexp component)
      (orderless-regexp (pinyinlib-build-regexp-string component))))
  (add-to-list 'orderless-matching-styles #'unzeit/orderless-regexp-pinyin))

(use-package marginalia
  :ensure t
  :demand t
  :config
  (marginalia-mode 1))

(use-package consult
  :ensure t
  :demand t
  :bind
  (("C-x b" . consult-buffer)
   ("C-s" . consult-line)
   ("C-M-s" . consult-ripgrep)
   ("M-y" . consult-yank-pop)
   ("M-s d" . consult-find)
   ("M-s g" . consult-ripgrep)
   ("M-s l" . consult-line)
   ("M-s D" . consult-locate)
   ("M-s G" . consult-git-grep)
   ("M-s L" . consult-line-multi)
   ("M-s k" . consult-keep-lines)
   ("M-s u" . consult-focus-lines)
   ([remap goto-line] . consult-goto-line)
   ([remap imenu] . consult-imenu)
   ([remap recentf-open] . consult-recent-file)
   ([remap bookmark-jump] . consult-bookmark)
   ([remap switch-to-buffer] . consult-buffer)
   ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
   ([remap switch-to-buffer-other-frame] . consult-buffer-other-frame)
   ([remap project-switch-to-buffer] . consult-project-buffer)
   ([remap repeat-complex-command] . consult-complex-command)
   ;; M-g 组：错误 / 大纲 / 标记 / imenu
   ("M-g e" . consult-compile-error)
   ("M-g o" . consult-outline)
   ("M-g m" . consult-mark)
   ("M-g k" . consult-global-mark)
   ("M-g I" . consult-imenu-multi)
   ("M-g ," . xref-go-back)
   ;; 寄存器：装载 / 存储 / 列表
   ("M-#" . consult-register-load)
   ("M-'" . consult-register-store)
   ("C-M-#" . consult-register)
   ("C-x p b" . consult-project-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ;; Isearch 集成：M-s l / M-s L
   :map isearch-mode-map
   ([remap isearch-edit-string] . consult-isearch-history)
   ("M-s l" . consult-line)
   ("M-s L" . consult-line-multi)
   :map minibuffer-local-map
   ([remap next-matching-history-element] . consult-history)
   ([remap previous-matching-history-element] . consult-history))
  :custom
  ;; Centaur 方案：默认不预览；只在 line/grep 类命令上自动预览。
  (consult-preview-key nil)
  (consult-narrow-key "<")
  (register-preview-delay 0.5)
  (register-preview-function #'consult-register-format)
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  :config
  (advice-add #'register-preview :override #'consult-register-window)
  (setq consult-async-refresh-debounce 0.2
        consult-async-input-throttle 0.1)
  ;; 连按两次 C-s 重复上一次 consult-line 搜索
  (defvar unzeit/consult-line-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "C-s") #'previous-history-element)
      map))
  (consult-customize consult-line :keymap unzeit/consult-line-map)
  (consult-customize
   consult-line :preview-key 'any
   consult-grep :preview-key 'any
   consult-ripgrep :preview-key 'any
   consult-git-grep :preview-key 'any)
  ;; 不给搜索结果上字体标记（如缩进辅助 face）
  (setq consult-fontify-preserve nil))

(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t
  :hook (completion-list-mode . embark-consult-preview-minor-mode))

(use-package corfu
  :ensure t
  :demand t
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-count 12)
  ;; 弹窗瘦身：变窄、少显示几条、滚动条细一点
  (corfu-max-width 50)
  (corfu-min-width 18)
  (corfu-count 10)
  (corfu-bar-width 2)
  (corfu-scroll-margin 2)
  (corfu-on-exact-match nil)
  (corfu-quit-at-boundary 'separator)
  (corfu-quit-no-match 'separator)
  :bind (:map corfu-map
         ("TAB" . corfu-next)
         ("S-TAB" . corfu-previous)
         ("RET" . corfu-insert)
         ("ESC" . corfu-reset)
         ;; C-k / C-j 在候选间移动
         ("C-k" . corfu-previous)
         ("C-j" . corfu-next))
  :config
  (global-corfu-mode 1)
  (corfu-indexed-mode 1)
  (add-to-list 'savehist-additional-variables 'corfu-history)
  ;; eglot 的 capf 也走 orderless
  (add-to-list 'completion-category-overrides
               `(eglot-capf (styles ,@completion-styles)))
  (define-key meow-insert-state-keymap (kbd "C-M-i") #'completion-at-point)
  (with-eval-after-load 'savehist (corfu-history-mode 1)))

(setq corfu-auto-delay 0.15
      corfu-auto-prefix 2)

(use-package corfu-popupinfo
  :ensure nil                      ; 随 corfu 一起装的库，不是独立包
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :custom
  (corfu-popupinfo-delay '(0.4 . 0.2))
  (corfu-popupinfo-max-height 12))

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (nerd-icons-completion-marginalia-setup)
  (nerd-icons-completion-mode 1))

(use-package nerd-icons
  :ensure t
  :defer t
  :custom
  (nerd-icons-font-family "Maple Mono NF CN"))

(use-package nerd-icons-corfu
  :ensure t
  :defer t
  :after corfu
  :init
)

(use-package cape
  :ensure t
  :defer t
  :init
  (remove-hook 'completion-at-point-functions
               #'tags-completion-at-point-function)
  (remove-hook 'completion-at-point-functions
               #'ispell-completion-at-point)
  (add-hook 'emacs-lisp-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-keyword 80)))
  (add-hook 'completion-at-point-functions #'cape-dabbrev 40)
  (add-hook 'completion-at-point-functions #'cape-file 50)
  (defun unzeit/capf-setup (expand)
    "org：丢掉内置垃圾 capf，本地加 cape。"

    (setq-local completion-at-point-functions
                (delq 'tags-completion-at-point-function
                      (delq 'ispell-completion-at-point
                            (delq 'pcomplete-completions-at-point
                                  completion-at-point-functions))))
    (add-hook 'completion-at-point-functions expand 0 t))
  (add-hook 'org-mode-hook
            (lambda () (unzeit/capf-setup 'cape-elisp-block)))
  )

(defun unzeit/geiser-capf--no-repl-guard (orig &rest args)
  "没有 Geiser REPL 时让 geiser 的 capf 安静返回 nil。"
  (condition-case err
      (apply orig args)
    (error (if (string-match-p "\\`No Geiser REPL" (error-message-string err))
               nil
             (signal (car err) (cdr err))))))

(with-eval-after-load 'geiser-capf
  (dolist (f '(geiser-capf--for-symbol
               geiser-capf--for-module
               geiser-capf--for-filename))
    (advice-add f :around #'unzeit/geiser-capf--no-repl-guard)))

(setq tab-always-indent 'complete)

(defun unzeit/tab-dwim (&optional arg)
  "TAB：缩进、补全，兜底插 tab；C-u 时只做刚性缩进。"
  (interactive "P")
  (if (use-region-p)
      ;; 与 `indent-for-tab-command' 一致：选中区域时缩进区域
      (indent-region (region-beginning) (region-end))
    (let ((tick (buffer-chars-modified-tick))
          (pt (point)))
      ;; capf 报错当作没有补全，别让它掀掉兜底
      (condition-case nil
          (indent-for-tab-command arg)
        (error nil))
      (when (and (not arg)
                 (eql pt (point))
                 (eql tick (buffer-chars-modified-tick))
                 (not (bound-and-true-p completion-in-region-mode)))
        (insert-tab)))))

(define-key global-map (kbd "TAB") #'unzeit/tab-dwim)

;;; ---- snippet 里的 TAB：能补全就先补全（yas 抢 TAB）----

(defun unzeit/capf-would-improve-p ()
  "点上的补全是否比已输入更进；`try-completion' 返 t 算没有。"
  (run-hook-wrapped
   'completion-at-point-functions
   (lambda (fn)
     (let ((res (ignore-errors (funcall fn))))
       (when (and (consp res) (nth 2 res))
         (let* ((beg (nth 0 res))
                (end (nth 1 res))
                (text (if (and (integer-or-marker-p beg) (integer-or-marker-p end)
                               (<= beg end))
                          (buffer-substring-no-properties beg end)
                        ""))
                (done (ignore-errors (try-completion text (nth 2 res)))))
           (and (stringp done) (not (equal done text)))))))))

(defun unzeit/snippet-tab (&optional arg)
  "snippet 域里的 TAB：网页里补全优先，其余跳域。"
  (interactive "P")
  (if (and (not arg)
           (fboundp 'unzeit/web-family-p)
           (unzeit/web-family-p)
           (unzeit/capf-would-improve-p))
      (completion-at-point)
    (yas-next-field-or-maybe-expand)))

;;; ---- 候选预览与跳转 ----

(add-hook 'prog-mode-hook #'completion-preview-mode)

(defun unzeit/completion-preview-inhibit-corfu-p ()
  "Corfu 弹窗可见时不要显示 completion-preview 的 ghost text。"
  (and (bound-and-true-p corfu--frame)
       (frame-live-p corfu--frame)
       (frame-visible-p corfu--frame)))

(with-eval-after-load 'completion-preview
  (add-hook 'completion-preview-inhibit-functions
            #'unzeit/completion-preview-inhibit-corfu-p)
  (setopt completion-preview-sort-function #'corfu-sort-length-alpha))

(use-package avy
  :ensure t
  :bind (("C-c j" . avy-goto-line)
         ("s-j" . avy-goto-char-timer)))

(defun unzeit/avy-action-embark (pt)
  "在 avy 选中的 PT 上调用 `embark-act'。"
  (unwind-protect
      (save-excursion
        (goto-char pt)
        (embark-act))
    (select-window (cdr (ring-ref avy-ring 0))))
  t)

(with-eval-after-load 'avy
  (setf (alist-get ?. avy-dispatch-alist) #'unzeit/avy-action-embark))


;;; ---- consult 扩展与编辑增强 ---------------------------------------

(use-package consult-dir
  :ensure t
  :after consult
  :bind (("C-x C-d" . consult-dir)
         :map minibuffer-local-completion-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file)))

(use-package consult-yasnippet
  :ensure t
  :after (consult yasnippet))

(use-package hl-todo
  :ensure t
  :config
  (global-hl-todo-mode 1))

(use-package consult-todo
  :ensure t
  :after (consult hl-todo))

(use-package consult-flyspell
  :ensure t
  :after consult)

(use-package wgrep
  :ensure t
  :defer t)

(use-package link-hint
  :ensure t
  :defer t)

(use-package browse-kill-ring
  :ensure t
  :defer t)

(use-package easy-kill
  :ensure t
  :defer t)

(use-package smart-region
  :ensure t
  :config
  (smart-region-on))

(use-package drag-stuff
  :ensure t
  :defer t)

(use-package avy-zap
  :ensure t
  :defer t)

(use-package rg
  :ensure t
  :defer t)

(use-package region-occurrences-highlighter
  :ensure t
  :defer t)


;;; completion.el ends here
(provide 'completion)

;; clangd 的补全 label 里可能带 \342\200\242 这类字面量转义；
;; corfu 显示前统一解码，和 eldoc 弹窗共用同一个函数。
(with-eval-after-load 'corfu
  (advice-add 'corfu--affixate :filter-args
              (lambda (args)
                (cons (mapcar #'unzeit/eldoc-decode-doc (car args))
                      (cdr args)))))

;; 补全插入前去掉 kind 图标（? / •）并解码残留八进制转义。
(defun unzeit/corfu-clean-replace (args)
  (let* ((str (caddr args))
         (clean (replace-regexp-in-string
                 "\\`[•?]" "" (unzeit/eldoc-decode-doc str))))
    (list (car args) (cadr args) clean)))

(with-eval-after-load 'corfu
  (advice-add 'corfu--replace :filter-args #'unzeit/corfu-clean-replace))

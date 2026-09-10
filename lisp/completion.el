;;; completion.el --- Unzeit: minibuffer 与缓冲内补全栈 -*- lexical-binding: t; -*-

;;; Commentary:
;; 由 init-completion 与 init-corfu 合并而来：minibuffer 用
;; vertico/consult/orderless，缓冲弹窗用 corfu/cape

;;; Code:



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
  (completion-category-overrides '((file (styles basic partial-completion))))
  (completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (orderless-component-separator #'orderless-escapable-split-on-space))

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
   ;; M-g 组 —— 从 centaur-emacs 抄来
   ("M-g e" . consult-compile-error)
   ("M-g o" . consult-outline)
   ("M-g m" . consult-mark)
   ("M-g k" . consult-global-mark)
   ("M-g I" . consult-imenu-multi)
   ("M-g ," . xref-go-back)
   ;; 快速访问寄存器 —— 从 centaur-emacs 抄来
   ("M-#" . consult-register-load)
   ("M-'" . consult-register-store)
   ("C-M-#" . consult-register)
   ("C-x p b" . consult-project-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ;; Isearch 集成（alynx）
   :map isearch-mode-map
   ([remap isearch-edit-string] . consult-isearch-history)
   ("M-s l" . consult-line)
   ("M-s L" . consult-line-multi)
   ;; Minibuffer 历史（alynx：M-r / M-s）
   :map minibuffer-local-map
   ([remap next-matching-history-element] . consult-history)
   ([remap previous-matching-history-element] . consult-history))
  :custom
  (consult-preview-key '(:debounce 0.2 any))
  (consult-narrow-key "<")
  (register-preview-delay 0.5)
  (register-preview-function #'consult-register-format)
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  :config
  (advice-add #'register-preview :override #'consult-register-window)
  (setq consult-async-refresh-debounce 0.2
        consult-async-input-throttle 0.1)
  ;; alynx：连按两次 C-s 重复上一次 consult-line 搜索
  (defvar unzeit/consult-line-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "C-s") #'previous-history-element)
      map))
  (consult-customize consult-line :keymap unzeit/consult-line-map)
  ;; alynx：不要给搜索结果上字体标记（如缩进辅助 face 等）
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
  ;; Popup 最大宽度（字符）corfu 的 max-width 是 natnum（整数），展示时它
  ;; 还会用 (min ... corfu-max-width (- (frame-width) 4)) 兜底，所以设一个
  ;; 固定值即可，小窗口也不会溢出
  (corfu-max-width 45)
  (corfu-min-width 15)
  (corfu-on-exact-match nil)
  (corfu-quit-at-boundary 'separator)
  (corfu-quit-no-match 'separator)
  (corfu-popupinfo-mode)
  :bind (:map corfu-map
         ;; popup 显示时：TAB 向下移动、S-TAB 向上、RET 确认选中
         ;; 隐藏时这些键回退为缩进 / 换行
         ("TAB" . corfu-next)
         ("S-TAB" . corfu-previous)
         ("RET" . corfu-insert)
         ("ESC" . corfu-reset)
         ;; doom：C-k/C-j 移动候选
         ("C-k" . corfu-previous)
         ("C-j" . corfu-next))
  :config
  (global-corfu-mode 1)
  ;; doom：LSP 的 capf 也用 orderless 风格
  (add-to-list 'completion-category-overrides
               `(eglot-capf (styles ,@completion-styles)))
  ;; 显式补全触发（insert 状态按 C-M-i / M-TAB；C-SPC/C-@ 被 fcitx5 占用）
  (define-key meow-insert-state-keymap (kbd "C-M-i") #'completion-at-point)
  (with-eval-after-load 'savehist (corfu-history-mode 1)))

(use-package corfu-auto
  :ensure nil
  :defer t
  :config
  (setq corfu-auto-delay 0.1
        corfu-auto-prefix 1))

;; NOTE: corfu-terminal 已内置到 Emacs 31（MELPA 的包甚至会警告这一点），
;; 因此这里不再配置它

;; NOTE: corfu-popupinfo（候选文档框）已禁用：它第二个浮动 popon 与
;; corfu-terminal 冲突（位置错乱），且 LSP 文档会在屏幕中间乱弹
;; 文档信息放在 eldoc（SPC l h）

;; 候选边距的图标（需要 Nerd Font；Maple Mono NF CN 已包含完整 Nerd Font 符号集）
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
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :ensure t
  :defer t
  :init
  ;; Emacs 30/31 会把过时的 etags capf
  ;;（`tags-completion-at-point-function'）放到 DEFAULT
  ;; completion-at-point-functions 列表前部在 corfu 下它会报错
  ;;（wrong-type-argument）或彻底阻塞补全，故移除它
  (remove-hook 'completion-at-point-functions
               #'tags-completion-at-point-function)
  ;; 本机没有 aspell/hunspell 字典，ispell-capf 每次补全都报
  ;; "No plain word-list found"；本配置的补全来源是 cape/eglot/yasnippet，
  ;; 直接去掉它
  (remove-hook 'completion-at-point-functions
               #'ispell-completion-at-point)
  ;; NOTE: dabbrev/file 作为兜底（eglot 的 capf 在连接时先运行，因此它们
  ;; 只在 LSP 没有内容时填充）若 cape-dabbrev 间歇性的
  ;; `wrong-type-argument sequencep' 又出现，就删掉那两个 add-hook 行
  ;; elisp 缓冲里的关键字补全
  (add-hook 'emacs-lisp-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-keyword 80)))
  ;; 兜底补全：即使（或没有）LSP 服务器，输入一个字母也能拿到同缓冲单词 /
  ;; 文件路径候选当 eglot 管理某缓冲时会前置它自己的 capf，因此这些只在
  ;; LSP 无结果时生效 —— 它们永远不会抢占上下文补全
  (add-hook 'completion-at-point-functions #'cape-dabbrev 40)
  (add-hook 'completion-at-point-functions #'cape-file 50)
  ;; org 代码块内的 elisp 补全
  ;;
  ;; NOTE: `org-mode' 会把 completion-at-point-functions
  ;; 以 BUFFER-LOCAL 方式重绑到内置默认值，其中仍含 ispell 与 pcomplete ——
  ;; 覆盖了上面的全局清理，并重新引入每次按键都报 "No plain word-list" 的
  ;; ispell 错误所以必须在这里清除这些垃圾，并把 cape-elisp-block 也作为
  ;; buffer-local hook 加回
  (defun unzeit/capf-setup (expand)
    "对 org：在本地丢弃内置的垃圾 capf，并本地加上 cape EXPAND 后端
（org 会在本地重绑 capf）"
    (setq-local completion-at-point-functions
                (delq 'tags-completion-at-point-function
                      (delq 'ispell-completion-at-point
                            (delq 'pcomplete-completions-at-point
                                  completion-at-point-functions))))
    (add-hook 'completion-at-point-functions expand 0 t))
  (add-hook 'org-mode-hook
            (lambda () (unzeit/capf-setup 'cape-elisp-block))))

;; TAB 循环：缩进 → 补全 → yasnippet 式展开
(setq tab-always-indent 'complete)

;;; completion.el ends here
(provide 'completion)

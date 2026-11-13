;;; lsp & dap
;;; Commentary:
;;; Code:

(use-package lsp-mode
 :ensure t
 :defer t
 :init
 ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
 (setq lsp-keymap-prefix "C-c l"
	lsp-file-watch-threshold 500)
 :hook  (lsp-mode . lsp-enable-which-key-integration) ; which-key integration
 :commands (lsp lsp-deferred)
 :config
 (setq lsp-completion-provider :none) ;; 阻止 lsp 重新设置 company-backend 而覆盖我们 yasnippet 的设置
 (setq lsp-headerline-breadcrumb-enable t)
 :bind
 ("C-c l s" . lsp-ivy-workspace-symbol)) ;; 可快速搜索工作区内的符号（类名、函数名、变量名等）

(use-package lsp-ui
 :ensure t
 :defer t
 :config
 (define-key lsp-ui-mode-map [remap xref-find-definitions] #'lsp-ui-peek-find-definitions)
 (define-key lsp-ui-mode-map [remap xref-find-references] #'lsp-ui-peek-find-references)
 (setq lsp-ui-doc-position 'top))

(use-package lsp-ivy
 :ensure t
 :defer t
 :after (lsp-mode))

(use-package dap-mode
 :ensure t
 :defer t
 :after lsp-mode
 :init (add-to-list 'image-types 'svg)
 :commands dap-debug
 :custom
 (dap-auto-configure-mode t)
 :hydra
 (dap-hydra
  (:color pink :hint nil :foreign-keys run)
  "
^Stepping^     ^Switch^         ^Breakpoints^     ^Debug^           ^Eval^
^^^^^^^^---------------------------------------------------------------------------------------------------------------
_n_: Next      _ss_: Session      _bb_: Toggle     _dd_: Debug         _ee_: Eval
_i_: Step in    _st_: Thread       _bd_: Delete     _dr_: Debug recent     _er_: Eval region
_o_: Step out    _sf_: Stack frame    _ba_: Add       _dl_: Debug last      _es_: Eval thing at point
_c_: Continue    _su_: Up stack frame   _bc_: Set condition  _de_: Edit debug template  _ea_: Add expression.
_r_: Restart frame _sd_: Down stack frame  _bh_: Set hit count  _ds_: Debug restart
_Q_: Disconnect   _sl_: List locals    _bl_: Set log message
         _sb_: List breakpoints
         _se_: List expressions
"
  ("n" dap-next)
  ("i" dap-step-in)
  ("o" dap-step-out)
  ("c" dap-continue)
  ("r" dap-restart-frame)
  ("ss" dap-switch-session)
  ("st" dap-switch-thread)
  ("sf" dap-switch-stack-frame)
  ("su" dap-up-stack-frame)
  ("sd" dap-down-stack-frame)
  ("sl" dap-ui-locals)
  ("sb" dap-ui-breakpoints)
  ("se" dap-ui-expressions)
  ("bb" dap-breakpoint-toggle)
  ("ba" dap-breakpoint-add)
  ("bd" dap-breakpoint-delete)
  ("bc" dap-breakpoint-condition)
  ("bh" dap-breakpoint-hit-condition)
  ("bl" dap-breakpoint-log-message)
  ("dd" dap-debug)
  ("dr" dap-debug-recent)
  ("ds" dap-debug-restart)
  ("dl" dap-debug-last)
  ("de" dap-debug-edit-template)
  ("ee" dap-eval)
  ("ea" dap-ui-expressions-add)
  ("er" dap-eval-region)
  ("es" dap-eval-thing-at-point)
  ("q" nil "quit" :color blue)
  ("Q" dap-disconnect "Disconnect" :color blue))
 :config
 (dap-ui-mode 1)
 (defun dap-hydra ()
	(interactive)
	"Run `dap-hydra/body'."
	(dap-hydra/body)))

(provide 'init-lsp)

;;; init-lsp.el ends here

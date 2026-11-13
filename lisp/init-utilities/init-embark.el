;;; Emacs Mini-Buffer Actions Rooted in Keymaps
;;; Commentary:
;;; Code:

(use-package embark
 :ensure t
 :defer t
 :init
 ;; Optionally replace the key help with a completing-read interface
 (setq prefix-help-command #'embark-prefix-help-command)
 :config
 ;; Hide the mode line of the Embark live/completions buffers
 (add-to-list 'display-buffer-alist
        '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
         nil
         (window-parameters (mode-line-format . none))))
 :bind
 (("C-." . embark-act)     ;; pick some comfortable binding
  ("C-;" . embark-dwim)    ;; good alternative: M-.
  ("C-h B" . embark-bindings))) ;; alternative for `describe-bindings'

(provide 'init-embark)

;;; init-embark.el ends here

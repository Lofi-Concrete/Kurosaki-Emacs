;;; Move to the beginning/end of line, code or comment
;;; Commenatry:
;;; Code:

(use-package mwim
 :ensure t
 :defer t
 :bind
 ("C-a" . mwim-beginning-of-code-or-line)
 ("C-e" . mwim-end-of-code-or-line))

(provide 'init-mwin)

;;; init-mwin.el ends here

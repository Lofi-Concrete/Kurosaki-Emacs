;;; marginalia.el - Marginalia in the minibuffer
;;; Commentary:
;;; Code:

(use-package marginalia
 :ensure t
 :defer t
 :init (marginalia-mode)
 :bind (:map minibuffer-local-map
     ("M-A" . marginalia-cycle)))

(provide 'init-marginalia)

;;; init-marginalia.el ends here

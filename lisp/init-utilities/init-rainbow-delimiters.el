;;; Emacs rainbow delimiters mode
;;; Commentary:
;;; Code:

(use-package rainbow-delimiters
 :ensure t
 :defer t
 :hook (prog-mode . rainbow-delimiters-mode))

(provide 'init-rainbow-delimiters)

;;; init-rainbow-delimiters.el ends here

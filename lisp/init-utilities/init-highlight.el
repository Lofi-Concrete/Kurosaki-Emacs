;;; Emacs: automatic and manual symbol highlighting
;;; Commentary:
;;; Code:

(use-package highlight-symbol
 :ensure t
 :defer t
 :init (highlight-symbol-mode)
 :bind ("<f3>" . highlight-symbol))

(provide 'init-highlight)

;;; init-highlight.el ends here

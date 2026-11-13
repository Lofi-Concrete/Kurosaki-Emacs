;;; Quickly switch windows in Emacs
;;; Commentary:
;;; Code:

(use-package ace-window
 :ensure t
 :defer t
 :bind (("C-x o" . 'ace-window)))

(provide 'init-ace-window)

;;; init-ace-window.el ends here

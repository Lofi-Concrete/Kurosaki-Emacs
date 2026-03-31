;;;
;;; Commentary:
;;; Code:

(require 'init-ace-window)
(require 'init-hydra)
(require 'init-mwin)
(require 'init-undo-tree)
(require 'init-marginalia)
(require 'init-embark)
(require 'init-multiple-cursors)
(require 'init-highlight)
(require 'init-rainbow-delimiters)
(require 'init-evil)
(require 'init-esup)

;; Org-mode
(add-to-list 'load-path (expand-file-name "lisp/init-utilities/init-org-mode" user-emacs-directory))
(require 'init-org-mode)

(provide 'init-utilities-all)

;;; init-utilities-all.el ends here

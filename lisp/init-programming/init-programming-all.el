;;;
;;; Commentary:
;;; Code:

(require 'init-company-mode)
(require 'init-yasnippet)
(require 'init-flycheck)
(require 'init-projectile)
(require 'init-magit)
(require 'init-clang-format)

(add-to-list 'load-path (expand-file-name "lisp/init-programming/init-lsp" user-emacs-directory))
(require 'init-lsp)
(require 'init-treemacs)
(require 'init-c)

(provide 'init-programming-all)

;;; init-programming-all.el ends here

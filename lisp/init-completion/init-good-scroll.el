;;; Attempt at good pixel-based smooth scrolling in Emacs
;;; Commentary:
;;; Code:

(use-package good-scroll
 :defer t
 :ensure t
 :if window-system
 :init (good-scroll-mode))

(provide 'init-good-scroll)

;;; init-good-scroll.el ends here

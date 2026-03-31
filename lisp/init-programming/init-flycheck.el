;;; Flycheck is a modern on-the-fly syntax checking extension for GNU Emacs
;;; Commentary:
;;; Code:

(use-package flycheck
 :ensure t
 :defer t
 :config
 (setq truncate-lines nil) ; 如果单行信息很长会自动换行
 :hook
 (prog-mode . flycheck-mode))

(provide 'init-flycheck)

;;; init-flycheck.el ends here

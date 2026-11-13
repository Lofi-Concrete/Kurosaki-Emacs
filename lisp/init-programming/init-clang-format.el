;;;
;;; Commentry:
;;; Code:

(use-package clang-format
  :ensure t
  :defer t
  :hook ((c-mode . (lambda () (add-hook 'before-save-hook 'clang-format-buffer nil t)))
           (c++-mode . (lambda () (add-hook 'before-save-hook 'clang-format-buffer nil t))))
  :config
  (setq clang-format-style "LLVM"))

(provide 'init-clang-format)

;;; init-clang-format.el ends here

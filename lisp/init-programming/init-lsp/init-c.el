;;;
;;; Commentry:
;;; Code:

(defun file-name-only ()
 "Get the current buffer file name without directory."
 (file-name-nondirectory (buffer-name)))

(defun file-name-only-noext ()
 "Get the currennt buffer file name without directory and extension."
 (file-name-sans-extension (file-name-only)))

(add-hook 'c++mode-hook
  (lambda ()
    (setq-local compile-command
      (concat "clang++ -g "
        (file-name-only) " -o "
        (file-name-only-noext)))))

(add-hook 'c-mode-hook
  (lambda ()
    (setq-local compile-command
      (concat "clang -g "
        (file-name-only) " -o "
        (file-name-only-noext)))))

(use-package cc-mode
 :ensure nil
 :defer t
 :functions  ; suppress warnings
 c-toggle-hungry-state
 :hook
 (c-mode . lsp-deferred)
 (c++-mode . lsp-deferred)
 (c++-mode . c-toggle-hungry-state))

(provide 'init-c)

;;; init-c.el ends here

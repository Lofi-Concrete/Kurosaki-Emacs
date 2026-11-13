;;; go.el --- Unzeit: Go -*- lexical-binding: t; -*-

(unzeit/treesit-source 'go "https://github.com/tree-sitter/tree-sitter-go")

(use-package go-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.go\\'" . go-ts-mode))
  :custom
  (go-ts-mode-test-flags nil))

;; 照 acdcbyl：打开 gopls 的 inlay hints
(unzeit/eglot-server
 '(go-ts-mode . ("gopls" :initializationOptions
                 (:hints (:assignVariableTypes t
                                               :compositeLiteralFields t
                                               :parameterNames t
                                               :functionTypeParameters t)))))

(unzeit/apheleia-mode '((go-ts-mode . (gofmt))))

(provide 'unzeit-lang-go)
;;; go.el ends here

;;; haskell.el --- Unzeit: Haskell -*- lexical-binding: t; -*-

(unzeit/treesit-source 'haskell "https://github.com/tree-sitter/tree-sitter-haskell")

(unzeit/define-on-demand-mode haskell-mode haskell-mode "\\.hs\\'")

(unzeit/eglot-server '(haskell-mode . ("haskell-language-server" "--lsp")))

(provide 'unzeit-lang-haskell)
;;; haskell.el ends here

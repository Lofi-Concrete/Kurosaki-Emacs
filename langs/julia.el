;;; julia.el --- Unzeit: Julia -*- lexical-binding: t; -*-
(unzeit/treesit-source 'julia "https://github.com/tree-sitter/tree-sitter-julia")
(use-package julia-mode :ensure t :defer t)
(unzeit/define-on-demand-mode julia-ts-mode julia-ts-mode "\\.jl\\'")
(provide 'unzeit-lang-julia)
;;; julia.el ends here

;;; scala.el --- Unzeit: Scala -*- lexical-binding: t; -*-
(unzeit/treesit-source 'scala "https://github.com/tree-sitter/tree-sitter-scala")
(unzeit/define-on-demand-mode scala-ts-mode scala-ts-mode "\\.scala\\'")
(provide 'unzeit-lang-scala)
;;; scala.el ends here

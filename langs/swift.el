;;; swift.el --- Unzeit: Swift -*- lexical-binding: t; -*-
(unzeit/treesit-source 'swift "https://github.com/alex-pinkus/tree-sitter-swift")
(unzeit/define-on-demand-mode swift-ts-mode swift-ts-mode "\\.swift\\'")
(provide 'unzeit-lang-swift)
;;; swift.el ends here

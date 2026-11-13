;;; c3.el --- Unzeit: C3 -*- lexical-binding: t; -*-

(unzeit/treesit-source 'c3 "https://github.com/c3lang/tree-sitter-c3")

(unzeit/define-on-demand-mode c3-ts-mode c3-ts-mode "\\.c3\\'"
                              :vc ("https://github.com/c3lang/c3-ts-mode"
                                   . "fab8d91341ab1a0903be5b8086063545d14c3cf9"))

(provide 'unzeit-lang-c3)
;;; c3.el ends here

;;; python.el --- Unzeit: Python -*- lexical-binding: t; -*-

(unzeit/treesit-source 'python "https://github.com/tree-sitter/tree-sitter-python")

(unzeit/remap-mode 'python-mode 'python-ts-mode)

(unzeit/apheleia-mode '((python-ts-mode . (black))))

(provide 'unzeit-lang-python)
;;; python.el ends here

;;; rust.el --- Unzeit: Rust -*- lexical-binding: t; -*-

(unzeit/treesit-source 'rust "https://github.com/tree-sitter/tree-sitter-rust")

(use-package rust-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.rs\\'" . rust-ts-mode)))

(unzeit/apheleia-mode '((rust-ts-mode . (rustfmt))))

(provide 'unzeit-lang-rust)
;;; rust.el ends here

;;; ruby.el --- Unzeit: Ruby -*- lexical-binding: t; -*-

(unzeit/treesit-source 'ruby "https://github.com/tree-sitter/tree-sitter-ruby")

(use-package ruby-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.rb\\'" . ruby-ts-mode)))


(use-package inf-ruby
  :ensure t :defer t
  :hook (ruby-ts-mode . inf-ruby-minor-mode))

(use-package rspec-mode
  :ensure t :defer t
  :hook (ruby-ts-mode . rspec-mode))

(use-package ruby-refactor
  :ensure t :defer t
  :after ruby-ts-mode)


(provide 'unzeit-lang-ruby)
;;; ruby.el ends here

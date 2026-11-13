;;; markdown.el --- Unzeit: Markdown / Mermaid -*- lexical-binding: t; -*-
(use-package markdown-mode :ensure t :defer t :mode ("\\.md\\'" . markdown-mode))
(use-package markdown-mermaid :ensure t :after markdown-mode)
(use-package mermaid-ts-mode :ensure t :defer t)
(provide 'unzeit-lang-markdown)
;;; markdown.el ends here

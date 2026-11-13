;;; js-ts.el --- Unzeit: JavaScript / TypeScript / JSON -*- lexical-binding: t; -*-

(unzeit/treesit-source 'javascript "https://github.com/tree-sitter/tree-sitter-javascript")
(unzeit/treesit-source 'typescript "https://github.com/tree-sitter/tree-sitter-typescript" "typescript/src")
(unzeit/treesit-source 'tsx "https://github.com/tree-sitter/tree-sitter-typescript" "tsx/src")
(unzeit/treesit-source 'json "https://github.com/tree-sitter/tree-sitter-json")
(unzeit/treesit-source 'jsdoc "https://github.com/tree-sitter/tree-sitter-jsdoc")

(unzeit/remap-mode 'js-mode 'js-ts-mode)

(autoload 'js-ts-mode "js" "JavaScript 的 tree-sitter 主模式。" t)
(dolist (unzeit/js-regexp '("\\.m?js\\'" "\\.cjs\\'" "\\.jsx\\'"))
  (add-to-list 'auto-mode-alist (cons unzeit/js-regexp #'js-ts-mode)))

(use-package typescript-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.ts\\'"  . typescript-ts-mode)
         ("\\.mts\\'" . typescript-ts-mode)
         ("\\.cts\\'" . typescript-ts-mode)
         ("\\.tsx\\'" . tsx-ts-mode)))

(use-package json-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.bowerrc\\'" . json-ts-mode)
         ("\\.jshintrc\\'" . json-ts-mode)
         ("\\.json_schema\\'" . json-ts-mode)
         ("\\.json\\'" . json-ts-mode)))

(unzeit/apheleia-mode '((js-ts-mode . (prettier-javascript))
                        (typescript-ts-mode . (prettier-typescript))
                        (tsx-ts-mode . (prettier-typescript))
                        (json-ts-mode . (prettier-json))))

(provide 'unzeit-lang-js-ts)
;;; js-ts.el ends here

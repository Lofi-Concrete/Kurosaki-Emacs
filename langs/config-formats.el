;;; config-formats.el --- Unzeit: 配置与构建格式（TOML / YAML / Lua / CMake / KDL） -*- lexical-binding: t; -*-

(unzeit/treesit-source 'toml "https://github.com/tree-sitter/tree-sitter-toml")
(unzeit/treesit-source 'yaml "https://github.com/tree-sitter-grammars/tree-sitter-yaml")

(use-package toml-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.toml\\'" . toml-ts-mode)))

(use-package yaml-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.ya?ml\\'" . yaml-ts-mode)))

(use-package lua-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.lua\\'" . lua-ts-mode)
         ("\\.fuse\\'" . lua-ts-mode)))

(use-package cmake-ts-mode
  :ensure nil
  :defer t
  :mode (("CMakeLists\\.txt\\'" . cmake-ts-mode)
         ("\\.cmake\\'" . cmake-ts-mode)))

(unzeit/apheleia-mode '((yaml-ts-mode . (prettier-yaml))
                        (toml-ts-mode . (taplo))))

(unzeit/treesit-source 'kdl "https://github.com/tree-sitter-grammars/tree-sitter-kdl")

(unzeit/define-on-demand-mode kdl-mode kdl-mode "\\.kdl\\'")

(with-eval-after-load 'kdl-mode
  (advice-add 'kdl-install-tree-sitter-grammar :override
              (lambda (&rest _)
                (message "Unzeit：缺少 kdl 的 tree-sitter 语法（M-x treesit-install-language-grammar 安装）"))))

(provide 'unzeit-lang-config-formats)
;;; config-formats.el ends here

;;; zig.el --- Unzeit: Zig -*- lexical-binding: t; -*-

(unzeit/treesit-source 'zig "https://github.com/tree-sitter-grammars/tree-sitter-zig")

(unzeit/define-on-demand-mode zig-mode zig-mode "\\.zig\\'")

(unzeit/eglot-server '(zig-mode . ("zls")))

;; 格式化 = apheleia **内建**的 `zig-fmt'（即 `("zig" "fmt" "--stdin")'），不另定义 formatter。
;; ★ 这一行不能省：init-eglot.el 用 `setq' 整体换掉 `apheleia-mode-alist'，每门语言都得自己报一次。
(unzeit/apheleia-mode '((zig-mode . zig-fmt)))

(provide 'unzeit-lang-zig)
;;; zig.el ends here

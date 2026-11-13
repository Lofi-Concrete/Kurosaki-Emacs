;;; c-cpp.el --- Unzeit: C / C++ -*- lexical-binding: t; -*-

(unzeit/treesit-source 'c "https://github.com/tree-sitter/tree-sitter-c")
(unzeit/treesit-source 'cpp "https://github.com/tree-sitter/tree-sitter-cpp")

(unzeit/remap-mode 'c-mode 'c-ts-mode)
(unzeit/remap-mode 'c++-mode 'c++-ts-mode)

(unzeit/remap-mode 'c-or-c++-mode 'c-or-c++-ts-mode)

(unzeit/eglot-server '((c-mode c++-mode c-ts-mode c++-ts-mode) . ("clangd")))

(defun unzeit/c-ts-large-file-tune ()
  "超大 C/C++ 缓冲（> 1 MiB）把 treesit 高亮降到第 1 档。
判据 1 MiB：sqlite3.c / imgui.h 这类单文件在 3 档下滚动掉帧，1 档仍保住关键字/字符串/注释；不要为此引入第三方主模式。"
  (when (> (buffer-size) (* 1024 1024))
    (setq-local treesit-font-lock-level 1)
    (when (fboundp 'treesit-font-lock-recompute-features)
      (treesit-font-lock-recompute-features))
    (message "Unzeit：%s 有 %.1f MiB，treesit 高亮降到 1 档"
             (buffer-name) (/ (buffer-size) 1048576.0))))

(add-hook 'c-ts-mode-hook #'unzeit/c-ts-large-file-tune)
(add-hook 'c++-ts-mode-hook #'unzeit/c-ts-large-file-tune)

(unzeit/apheleia-mode '((c-mode . (clang-format))
                        (c++-mode . (clang-format))
                        (c-ts-mode . (clang-format))
                        (c++-ts-mode . (clang-format))))

(provide 'unzeit-lang-c-cpp)
;;; c-cpp.el ends here

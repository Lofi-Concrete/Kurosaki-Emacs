;;; raylib.el --- Unzeit: raylib（跨语言 C 图形库） -*- lexical-binding: t; -*-

(defconst unzeit/raylib-include-re "<raylib\\.h>"
  "判定当前缓冲是否在用 raylib 的 include 形式。")

(defun unzeit/raylib-maybe-set-compile-command ()
  "若当前缓冲 include 了 <raylib.h>，把 compile-command 设成 pkg-config 版。
只在缓冲还没有自己的本地 compile-command 时设置，不覆盖项目已有的。"
  (when (and buffer-file-name
             (not (local-variable-p 'compile-command (current-buffer)))
             (save-excursion
               (goto-char (point-min))
               (re-search-forward unzeit/raylib-include-re 8192 t)))
    (let* ((src (buffer-file-name))
           (exe (file-name-base src)))
      (setq-local compile-command
                  (format "cc %s -o %s $(pkg-config --cflags --libs raylib) && ./%s"
                          (shell-quote-argument src)
                          (shell-quote-argument exe)
                          (shell-quote-argument exe))))))

(dolist (hook '(c-ts-mode-hook c++-ts-mode-hook simpc-mode-hook))
  (add-hook hook #'unzeit/raylib-maybe-set-compile-command))

(provide 'unzeit-lang-raylib)
;;; raylib.el ends here

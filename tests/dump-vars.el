;; -*- lexical-binding: t; -*-
;; 一次性 dump：把 P0/P3 要比的 Emacs 变量写到 $DUMP_OUT（避免 stdout 转义污染 diff）。
(require 'eglot nil t)
(require 'apheleia nil t)
(let ((out (getenv "DUMP_OUT")))
  (with-temp-file out
    (let ((print-length nil)
          (print-level nil))
      (prin1 (list :eglot-server-programs (and (boundp 'eglot-server-programs) eglot-server-programs)
                   :apheleia-formatters (and (boundp 'apheleia-formatters) apheleia-formatters)
                   :treesit-language-source-alist (and (boundp 'treesit-language-source-alist)
                                                       treesit-language-source-alist)
                   :major-mode-remap-alist (and (boundp 'major-mode-remap-alist)
                                                major-mode-remap-alist))
             (current-buffer))
      (terpri))))
(princ "DUMP-OK\n")

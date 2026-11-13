;; -*- lexical-binding: t; -*-
(let ((out (getenv "DUMP_OUT2")))
  (with-temp-file out
    (prin1 (list :exec-path exec-path
                 :PATH (getenv "PATH")
                 :LD_LIBRARY_PATH (getenv "LD_LIBRARY_PATH"))
           (current-buffer))
    (terpri)))
(princ "ENV-OK\n")

;; -*- lexical-binding: t; -*-
(defun uzd/read (f)
  (with-temp-buffer (insert-file-contents f) (goto-char (point-min)) (read (current-buffer))))
(defun uzd/canon (x) (sort (mapcar #'prin1-to-string (copy-sequence x)) #'string<))
(let* ((a (uzd/read (getenv "A"))) (b (uzd/read (getenv "B")))
       (keys '(:eglot-server-programs :apheleia-formatters
               :treesit-language-source-alist :major-mode-remap-alist))
       (fail 0))
  (dolist (k keys)
    (let* ((va (plist-get a k)) (vb (plist-get b k))
           (ca (uzd/canon va)) (cb (uzd/canon vb))
           (missing (seq-difference ca cb #'equal))
           (extra (seq-difference cb ca #'equal)))
      (if (and (null missing) (null extra))
          (princ (format "OK   %-30s 旧 %d / 新 %d 条，集合一致%s\n"
                         k (length va) (length vb)
                         (if (equal va vb) "（连顺序都一致）" "")))
        (progn
          (setq fail (1+ fail))
          (princ (format "FAIL %-30s 旧 %d / 新 %d\n" k (length va) (length vb)))
          (dolist (m missing) (princ (format "   缺: %.160s\n" m)))
          (dolist (e extra) (princ (format "   多: %.160s\n" e)))))))
  (princ (if (zerop fail) "\n★ 四个变量：集合完全一致（顺序差异无语义）\n" "\n！有差异\n")))

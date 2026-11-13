;; -*- lexical-binding: t; -*-
;; 验收 PATH/exec-path/LD_LIBRARY_PATH：目录集合 + 可执行名解析到同一真实文件；不查档间顺序。
(defun uzd/read (f)
  (with-temp-buffer (insert-file-contents f) (goto-char (point-min)) (read (current-buffer)))) 

(defun uzd/split (s)
  (if (and s (not (string-empty-p s))) (split-string s ":" t) '()))

(defun uzd/bin-map (dirs)
  "按 DIRS 的顺序做 可执行名 → 首个所在目录 的映射（PATH 的查找语义）。"
  (let ((m (make-hash-table :test #'equal)))
    (dolist (d dirs)
      (when (file-directory-p d)
        (ignore-errors
          (dolist (f (directory-files d t "\\`[^.]"))
            (when (and (file-regular-p f) (file-executable-p f))
              (let ((n (file-name-nondirectory f)))
                (unless (gethash n m) (puthash n d m))))))))
    m))

(let* ((a (uzd/read (getenv "A"))) (b (uzd/read (getenv "B")))
       (pa (uzd/split (plist-get a :PATH))) (pb (uzd/split (plist-get b :PATH)))
       (la (uzd/split (plist-get a :LD_LIBRARY_PATH)))
       (lb (uzd/split (plist-get b :LD_LIBRARY_PATH)))
       (fail 0))
  (princ (format "PATH 目录：旧 %d / 新 %d\n" (length pa) (length pb)))
  ;; ① 目录集合
  (let ((missing (seq-difference pa pb #'equal))
        (extra (seq-difference pb pa #'equal)))
    (if (and (null missing) (null extra))
        (princ "OK   PATH 目录集合一致\n")
      (setq fail (1+ fail))
      (dolist (d missing) (princ (format "     缺: %s\n" d)))
      (dolist (d extra) (princ (format "     多: %s\n" d)))))
  ;; ② 逐个可执行名的解析结果
  (let* ((ma (uzd/bin-map pa)) (mb (uzd/bin-map pb))
         (names (let (acc) (maphash (lambda (k _) (push k acc)) ma) acc))
         (changed nil) (lost nil) (same-file 0))
    (dolist (n names)
      (let ((da (gethash n ma)) (db (gethash n mb)))
        (cond
         ((null db) (push n lost))
         ((not (equal da db))
          (push n changed)
          (let ((ra (ignore-errors (file-truename (expand-file-name n da))))
                (rb (ignore-errors (file-truename (expand-file-name n db)))))
            (if (equal ra rb) (setq same-file (1+ same-file))
              (setq fail (1+ fail))
              (princ (format "FAIL %s 换到了不同文件：\n     %s\n     %s\n" n ra rb))))))))
    (princ (format "     旧 PATH 里可执行名 %d 个；换目录 %d 个（其中真实文件相同 %d 个）；消失 %d 个\n"
                   (length names) (length changed) same-file (length lost)))
    (when lost (setq fail (1+ fail))
          (princ (format "FAIL 这些可执行名在旧 PATH 里有、新 PATH 里找不到：%S\n" lost))))
  ;; ③ LD_LIBRARY_PATH 集合
  (if (equal (sort (copy-sequence la) #'string<) (sort (copy-sequence lb) #'string<))
      (princ (format "OK   LD_LIBRARY_PATH 集合一致（%S）\n" lb))
    (progn (setq fail (1+ fail))
           (princ (format "FAIL LD_LIBRARY_PATH：旧 %S / 新 %S\n" la lb))))
  (princ (if (zerop fail) "\n★ PATH 侧全部通过\n" "\n！PATH 侧有差异\n")))

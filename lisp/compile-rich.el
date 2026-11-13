;;; compile-rich.el --- Unzeit: 能看进度的编译（Eat 终端）+ 错误跳转 -*- lexical-binding: t; -*-

;; compile 在 pty 上会带整套终端绘制；这里改在 Eat 里跑 + 自扫错误跳转。

(require 'compile)

;;;; 终端视图

(defvar unzeit/compile-in-terminal--last-marker nil
  "上一次跳转到的错误在 Eat 缓冲里的位置（marker，随终端重绘自动移动）。")
(make-variable-buffer-local 'unzeit/compile-in-terminal--last-marker)

(defun unzeit/compile-in-terminal--root ()
  "当前项目根（没有项目就用 `default-directory'）。"
  (let ((proj (project-current)))
    (if proj (project-root proj) default-directory)))

(defun unzeit/compile-in-terminal--buffer-name (&optional root)
  "Eat 编译缓冲的名字，按项目区分（`zig' 一个项目一个终端）。"
  (format "*compile:%s*"
          (file-name-nondirectory
           (directory-file-name (or root (unzeit/compile-in-terminal--root))))))

;;;###autoload
(defun unzeit/compile-in-terminal (&optional command)
  "在 Eat 里跑编译命令（有进度盘/颜色）；错误用 M-g n/p 跳。"
  (interactive)
  (unless (require 'eat nil t)
    (user-error "没有装 eat，跑不了终端视图"))
  (let* ((root (unzeit/compile-in-terminal--root))
         (name (unzeit/compile-in-terminal--buffer-name root))
         (default-directory root)
         (cmd (or (and (stringp command) (not (string-empty-p command)) command)
                  (and (stringp compile-command)
                       (not (string-empty-p compile-command))
                       compile-command)
                  (read-shell-command "Compile in terminal: " compile-command)))
         (old (get-buffer name))
         (eat-buffer-name name)
         (eat-kill-buffer-on-exit nil)   ; 跑完留着看输出
         buf)
    (when (and old (get-buffer-process old) (process-live-p (get-buffer-process old)))
      (user-error "终端 %s 里还有进程在跑（C-c C-c 或 M-x kill-buffer）" name))
    (when (buffer-live-p old) (kill-buffer old))
    (setq buf (eat cmd))
    (with-current-buffer buf
      (unzeit/compile-in-terminal-mode 1))
    buf))

(defun unzeit/compile-toggle-view ()
  "在编译日志与 Eat 编译终端之间切换。"
  (interactive)
  (if (eq major-mode 'eat-mode)
      (let ((log (ignore-errors (compilation-find-buffer t))))
        (if (buffer-live-p log)
            (pop-to-buffer log)
          (user-error "还没有编译日志，先 `M-x compile' 跑一次")))
    (let ((buf (get-buffer (unzeit/compile-in-terminal--buffer-name))))
      (if (buffer-live-p buf)
          (pop-to-buffer buf)
        (unzeit/compile-in-terminal)))))

;;;; 错误扫描器（不依赖 compilation 的解析状态）

(defun unzeit/compile--group (x)
  "把 regexp 条目里的分组说明取成整数（裸整数或 cons）。"
  (cond ((integerp x) x)
        ((consp x) (and (integerp (car x)) (car x)))))

(defun unzeit/compile--regexp-table ()
  "把 compilation-error-regexp-alist 摊平成 (REGEXP FILE LINE COLUMN)。"
  (let (table)
    (dolist (entry compilation-error-regexp-alist)
      (let* ((spec (if (symbolp entry)
                       (cdr (assq entry compilation-error-regexp-alist-alist))
                     entry))
             (fg (unzeit/compile--group (nth 1 spec)))
             (lg (unzeit/compile--group (nth 2 spec)))
             (cg (unzeit/compile--group (nth 3 spec))))
        (when (and (consp spec) (stringp (car spec)) fg lg)
          (push (list (car spec) fg lg cg) table))))
    (nreverse table)))

(defun unzeit/compile--candidates ()
  "扫描整个缓冲区，返回按位置排好序的 (POS FILE LINE COL) 列表。"
  (let (cands)
    (dolist (spec (unzeit/compile--regexp-table))
      (let ((regexp (nth 0 spec))
            (fg (nth 1 spec))
            (lg (nth 2 spec))
            (cg (nth 3 spec)))
        (save-excursion
          (goto-char (point-min))
          (let ((case-fold-search nil))
            (while (re-search-forward regexp nil t)
              (let ((file (match-string-no-properties fg))
                    (line (match-string-no-properties lg))
                    (col (and cg (match-string-no-properties cg))))
                  (when (and file
                             (stringp line)
                             (string-match-p "\\`[0-9]+\\'" line))
                    (push (list (match-beginning 0)
                                file
                                (string-to-number line)
                                (and col (string-to-number col)))
                          cands))))))))
    (sort cands (lambda (a b) (< (car a) (car b))))))

(defun unzeit/compile--find-error (direction)
  "按 DIRECTION 找一条错误（第一次从头算，第一行也不漏）。"
  (let* ((cands (unzeit/compile--candidates))
         (last (and (markerp unzeit/compile-in-terminal--last-marker)
                    (marker-position unzeit/compile-in-terminal--last-marker)))
         pick)
    (if (> direction 0)
        (let ((start (or last (1- (point-min)))))
          (dolist (c cands)
            (when (and (not pick) (> (car c) start))
              (setq pick c))))
      (let ((limit (or last (point-max))))
        (dolist (c cands)
          (when (< (car c) limit)
            (setq pick c)))))
    pick))

(defun unzeit/compile-in-terminal-next-error (&optional n)
  "跳到 Eat 缓冲里的下一条 `file:line:col:' 错误（N 为负数则往上找）。"
  (interactive "p")
  (let ((hit (unzeit/compile--find-error (if (and n (< n 0)) -1 1))))
    (unless hit
      (user-error "没有更多错误了"))
    (pcase-let ((`(,pos ,file ,line ,col) hit))
      ;; marker 建在 Eat 缓冲里，终端后续重绘会带着它走
      (setq unzeit/compile-in-terminal--last-marker (copy-marker pos))
      (let ((path (expand-file-name file default-directory)))
        (unless (file-exists-p path)
          (user-error "错误里的文件不存在：%s" path))
        (find-file-other-window path)
        (goto-char (point-min))
        (forward-line (1- (max 1 line)))
        (when (and col (> col 1))
          (move-to-column (1- col)))
        (recenter)))))

(defun unzeit/compile-in-terminal-previous-error (&optional n)
  "跳到 Eat 缓冲里的上一条错误。"
  (interactive "p")
  (unzeit/compile-in-terminal-next-error (- (or n 1))))

(defvar-keymap unzeit/compile-in-terminal-mode-map
  :doc "Eat 编译终端里跳错误"
  "M-g n" #'unzeit/compile-in-terminal-next-error
  "M-g p" #'unzeit/compile-in-terminal-previous-error
  "C-x `" #'unzeit/compile-in-terminal-next-error)

(define-minor-mode unzeit/compile-in-terminal-mode
  "Eat 编译终端的辅助模式：提供 `M-g n' / `M-g p' 跳错误。"
  :lighter " Compile-TTY"
  :keymap unzeit/compile-in-terminal-mode-map
  (setq unzeit/compile-in-terminal--last-marker nil))

(provide 'compile-rich)
;;; compile-rich.el ends here

;;; doctor.el --- Unzeit: 一处体检（语法 / LSP / 字体 / 字节码 / 启动） -*- lexical-binding: t; -*-

(require 'cl-lib)

(defconst unzeit/doctor-cache-file
  (expand-file-name "unzeit-doctor.el" unzeit/cache-dir)
  "体检报告的机器本地版本戳（EMACS-VERSION . 时间戳）：换过 Emacs 后提醒 elpa 是旧字节码。")

(defun unzeit/doctor--read-stamp ()
  "读回上次体检时的 Emacs 版本；没有就返回 nil。"
  (when (file-readable-p unzeit/doctor-cache-file)
    (condition-case nil
        (with-temp-buffer
          (insert-file-contents unzeit/doctor-cache-file)
          (car (read (current-buffer))))
      (error nil))))

(defun unzeit/doctor--write-stamp ()
  "把当前 Emacs 版本写进版本戳文件。"
  (ignore-errors
    (with-temp-file unzeit/doctor-cache-file
      (prin1 (cons emacs-version (float-time)) (current-buffer)))))

;;; ---- 各节检查 ------------------------------------------------------

(defun unzeit/doctor--grammars ()
  "返回 (已装 . 缺失) 语法，只看本配置登记过的语言。"
  (let (ok missing)
    (dolist (lang unzeit/treesit-languages)
      (if (treesit-language-available-p lang)
          (push lang ok)
        (push lang missing)))
    (cons (nreverse ok) (nreverse missing))))

(defun unzeit/doctor--our-modes ()
  "本配置真会用到的主模式（各语言服务器 + 当前缓冲）。"
  (let (modes)
    (dolist (spec unzeit/eglot-registered-servers)
      (let ((m (car spec)))
        (dolist (mode (if (listp m) m (list m)))
          (push mode modes))))
    (dolist (buf (buffer-list))
      (push (buffer-local-value 'major-mode buf) modes))
    (delete-dups modes)))

(defun unzeit/doctor--servers ()
  "返回会用但 exec-path 上找不到的 LSP 程序（跳过函数型 contact）。"
  (let ((modes (unzeit/doctor--our-modes))
        missing)
    (when (require 'eglot nil t)
      (dolist (entry eglot-server-programs)
        (when (seq-intersection (ensure-list (car entry)) modes)
          (let* ((contact (cdr entry))
                 (prog (cond ((stringp contact) contact)
                             ((proper-list-p contact)
                              (seq-find #'stringp contact)))))
            (when (and prog (not (executable-find prog)))
              (cl-pushnew prog missing :test #'equal))))))
    (sort missing #'string<)))

(defconst unzeit/doctor-fonts
  '(("Maple Mono NF CN" . "正文 + 中文 + Nerd 图标（core.el 的 fontset）")
    ("LXGW WenKai Mono" . "org 缓冲（init-org.el 的 face-remap）"))
  "体检时要确认存在的字体族：(族名 . 用途)。")

(defun unzeit/doctor--fonts ()
  "返回缺失字体列表；无图形帧时跳过。"
  (if (not (display-graphic-p))
      '()
    (seq-remove (lambda (font)
                  (find-font (font-spec :family (car font))))
                unzeit/doctor-fonts)))

(defun unzeit/doctor--elc-version (file)
  "读 .elc 头里的 Emacs 版本，读不出返回 nil。"
  (condition-case nil
      (with-temp-buffer
        (insert-file-contents-literally file nil 0 200)
        (goto-char (point-min))
        (when (re-search-forward "in Emacs version \\([0-9][0-9.]+\\)" nil t)
          (match-string 1)))
    (error nil)))

(defun unzeit/doctor--stale-elc ()
  "返回 elc 编译版本 ≠ 当前 Emacs 的包名列表。"
  (let (stale)
    (dolist (dir (directory-files package-user-dir t "\\`[^.]"))
      (when (file-directory-p dir)
        (let ((bad nil))
          (dolist (elc (directory-files dir t "\\.elc\\'"))
            (let ((v (unzeit/doctor--elc-version elc)))
              (when (and v (not (version= v emacs-version)))
                (setq bad (cons v bad)))))
          (when bad
            (push (cons (file-name-nondirectory dir) (delete-dups bad)) stale)))))
    (nreverse stale)))

(defun unzeit/doctor--duplicates ()
  "返回有多个来源/版本的包（elpa 与 Guix site-lisp 并存）。"
  (let (out)
    (dolist (cell package-alist)
      (when (> (length (cdr cell)) 1)
        (push (cons (car cell)
                    (mapcar (lambda (desc)
                              (cons (package-desc-version desc)
                                    (if (string-prefix-p "/gnu/store"
                                                         (package-desc-dir desc))
                                        'Guix 'elpa)))
                            (cdr cell)))
              out)))
    (nreverse out)))

(defun unzeit/doctor--warnings ()
  "最近几条警告（从 `*Messages*' 里捞，最多 5 条）。"
  (let ((buf (get-buffer "*Messages*")))
    (when buf
      (with-current-buffer buf
        (save-excursion
          (goto-char (point-max))
          (let (lines)
            (while (and (< (length lines) 5)
                        (re-search-backward "^.*[Ww]arning.*$" nil t))
              (push (match-string 0) lines))
            lines))))))

(defun unzeit/doctor--hook-costs (&optional n)
  "量 post-command-hook 每个函数的单次耗时（毫秒）。"
  (let ((n (or n 100))
        out)
    (dolist (f post-command-hook)
      (when (functionp f)
        (let ((ms (ignore-errors
                    (* 1000 (/ (car (benchmark-run n (funcall f)))
                               (float n))))))
          (when ms (push (cons f ms) out)))))
    (sort out (lambda (a b) (> (cdr a) (cdr b))))))

;;; ---- 报告 ----------------------------------------------------------

(defun unzeit/doctor--insert-list (items &optional okp)
  "插入 ITEMS，每行前面加 ✔ 或 ✘（OKP 为真时是 ✔）。"
  (if (null items)
      (insert "    ✔ 无\n")
    (dolist (item items)
      (insert (if okp "    ✔ " "    ✘ ") (format "%s" item) "\n"))))

(defun unzeit/doctor ()
  "Unzeit 体检：语法/LSP/字体/字节码/包/启动；C-u 先重编 elc。"
  (interactive "P")
  (when current-prefix-arg
    (message "Unzeit：重编 elpa 字节码（这一步会慢一阵）…")
    (package-recompile-all)
    (package-quickstart-refresh))
  (let* ((grammars (unzeit/doctor--grammars))
         (servers (unzeit/doctor--servers))
         (fonts (unzeit/doctor--fonts))
         (stale (unzeit/doctor--stale-elc))
         (dups (unzeit/doctor--duplicates))
         (warnings (unzeit/doctor--warnings))
         (prev (unzeit/doctor--read-stamp))
         (buf (get-buffer-create "*Unzeit 体检*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Unzeit 体检  ·  Emacs %s  ·  %s\n\n"
                        emacs-version (format-time-string "%F %H:%M")))
        (when (and prev (not (version= prev emacs-version)))
          (insert (format "★★ 上次体检是 Emacs %s，现在是 %s —— elpa 的字节码可能
   全是旧版本编的，先跑 M-x package-recompile-all（或 C-u M-x unzeit/doctor）。\n\n"
                          prev emacs-version)))
        ;; 1. 启动
        (insert "■ 启动\n")
        (insert (format "    初始化耗时 %s（GUI 实例的真实数值看这里；batch 偏小）\n\n"
                        (or (ignore-errors (emacs-init-time)) "—")))
        ;; 1b. 每命令开销
        (insert (format "■ 每个命令的固定开销（`post-command-hook'，100 次平均）\n"))
        (let ((costs (unzeit/doctor--hook-costs)))
          (if costs
              (dolist (c costs)
                (insert (format "    %-46s %6.2f ms%s\n"
                                (if (symbolp (car c)) (car c) "<lambda>")
                                (cdr c)
                                (if (> (cdr c) 1.0) "  ← 偏贵" ""))))
            (insert "    （当前缓冲没有每命令钩子）\n")))
        (insert "    提示：这里 >1ms 的那些就是「每次按键/移动都变卡」的嫌疑人；\n")
        (insert "    关掉对应功能或换成 idle 驱动的版本。\n\n")

        ;; 2. 语法
        (insert (format "■ tree-sitter 语法（登记 %d 个）\n"
                        (+ (length (car grammars)) (length (cdr grammars)))))
        (if (cdr grammars)
            (progn (insert "    缺：\n")
                   (unzeit/doctor--insert-list (cdr grammars))
                   (insert "    修法：M-x treesit-install-language-grammar，或把对应
    tree-sitter-<语言> 加进 home/lang/lang.scm 的 %packages。\n\n"))
          (insert "    ✔ 全部可用\n\n"))
        ;; 3. LSP
        (insert "■ LSP 服务器（eglot-server-programs 里点名的可执行文件）\n")
        (if servers
            (progn (insert "    找不到：\n")
                   (unzeit/doctor--insert-list servers)
                   (insert "    注意：Emacs 31 的内置表比本树登记的更多，`ols' /
    `lua-language-server' 这类就算 langs/ 里没写也会被 eglot 调用。\n\n"))
          (insert "    ✔ 全部找得到\n\n"))
        ;; 4. 字体
        (insert "■ 字体\n")
        (if fonts
            (dolist (font fonts)
              (insert (format "    ✘ %s —— %s\n" (car font) (cdr font))))
          (insert "    ✔ 三个族都在\n"))
        (insert "\n")
        ;; 4b. 现代层
        (insert "■ 现代层（Centaur 风格）\n")
        (let ((off (seq-filter (lambda (s) (not (symbol-value s)))
                               '(unzeit/modern-scroll unzeit/modern-gc
                                 unzeit/modern-posframe unzeit/modern-vertico-posframe
                                 unzeit/modern-solaire unzeit/modern-dividers
                                 unzeit/modern-hl-line unzeit/modern-corfu
                                 unzeit/modern-consult-preview
                                 unzeit/modern-inline-diagnostics
                                 unzeit/modern-eldoc-mouse
                                 unzeit/modern-line-number-fast-path))))
          (insert (format "    开关：%s\n"
                          (if off (format "关掉 %S" off) "全开"))))
        (let ((missing (seq-remove #'package-installed-p unzeit/modern-packages)))
          (insert (format "    包：%s\n"
                          (if missing
                              (format "缺 %S（跑 tests/preinstall-modern.sh）" missing)
                            "齐全"))))
        (insert (format "    行号：%s；GC 百分比 %.2f；treesit-enabled-modes %s 个\n"
                        (if (bound-and-true-p global-display-line-numbers-mode)
                            "全局（异常）" "仅 prog/conf/yaml/toml")
                        gc-cons-percentage
                        (if (boundp 'treesit-enabled-modes)
                            (length treesit-enabled-modes) "—")))
        (insert "\n")
        (insert (format "■ 字节码（package-user-dir: %s）\n" package-user-dir))
        (if stale
            (progn
              (insert (format "    ✘ %d 个包的 .elc 不是 %s 编的：\n"
                              (length stale) emacs-version))
              (dolist (s (seq-take stale 12))
                (insert (format "      %s（%s）\n" (car s)
                                (mapconcat #'identity (cdr s) ", "))))
              (when (> (length stale) 12)
                (insert (format "      … 还有 %d 个\n" (- (length stale) 12))))
              (insert "    修法：C-u M-x unzeit/doctor（= package-recompile-all）\n\n"))
          (insert "    ✔ 全部与当前 Emacs 匹配\n\n"))
        ;; 6. 包
        (insert (format "■ 包（%d 个目录，%d 个包名）\n"
                        (length (directory-files package-user-dir nil "\\`[^.]"))
                        (length package-alist)))
        (if dups
            (progn (insert "    多份并存（elpa 里多版本 / Guix 与 elpa 各一份）：\n")
                   (dolist (d dups)
                     (insert (format "      %s → %s\n" (car d)
                                     (mapconcat (lambda (v)
                                                  (format "%s[%s]"
                                                          (package-version-join (car v))
                                                          (cdr v)))
                                                (cdr d) "  ")))))
          (insert "    ✔ 无重复版本\n"))
        (insert "\n")
        ;; 7. 警告
        (insert "■ 最近的警告（*Messages*）\n")
        (if warnings
            (dolist (w warnings) (insert "    " w "\n"))
          (insert "    ✔ 没有\n"))
        (insert "\n（只读报告 · q 关闭 · C-c D 再来一次）\n")
        (goto-char (point-min))
        (special-mode)
        (setq-local truncate-lines t)
        (display-line-numbers-mode -1))
      (unzeit/doctor--write-stamp))
    (switch-to-buffer buf)))

(defun unzeit/doctor-toggle (&optional arg)
  "体检报告开关；C-u 先重编 elpa 字节码。"
  (interactive "P")
  (let ((win (get-buffer-window "*Unzeit 体检*")))
    (if (and (null arg) win)
        (quit-window nil win)
      (let ((current-prefix-arg arg))
        (unzeit/doctor)))))

(provide 'doctor)
;;; doctor.el ends here

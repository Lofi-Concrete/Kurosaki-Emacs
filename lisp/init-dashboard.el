;;; init-dashboard.el --- Unzeit: dashboard 包主屏 -*- lexical-binding: t; -*-

;;; Commentary:
;; 用久经考验的 `dashboard' 包（MELPA），替换之前手写的
;; unzeit-dashboard.el那个自绘的版本会把内容画到 window-size hook
;; 触发时当前所在的缓冲里，可能用主屏内容覆盖刚创建的文件缓冲
;; （换成该包后解决）
;;
;; 布局沿用 nano-emacs 的启动屏精神：紧凑居中的横幅、克制的垂直间距，
;; 以及底部一行帮助（类似 nano-quick-help），而不是堆满内容
;; 标题：UNZEIT ASCII 横幅拼出 “UNZEIT”；下方文字（“不合时宜的”）补全它
;; 强调色沿用 nano-dark 调色板（见 unzeit-theme.el）

;;; Code:

;; UNZEIT logo 用 figlet “ANSI Shadow” 字形：UN 用强调色（动作），
;; ZEIT 用白色（信息）
(defconst unzeit/dashboard-letters
  ;; 字符 -> 6 行字符串向量（figlet “ANSI Shadow” 字体）
  '((?U . ("██╗   ██╗" "██║   ██║" "██║   ██║" "██║   ██║" "╚██████╔╝" " ╚═════╝ "))
    (?N . ("███╗   ██╗" "████╗  ██║" "██╔██╗ ██║" "██║╚██╗██║" "██║ ╚████║" "╚═╝  ╚═══╝"))
    (?Z . ("███████╗" "╚══███╔╝" "  ███╔╝ " " ███╔╝  " "███████╗" "╚══════╝"))
    (?E . ("███████╗" "██╔════╝" "█████╗  " "██╔══╝  " "███████╗" "╚══════╝"))
    (?I . ("██╗" "██║" "██║" "██║" "██║" "╚═╝"))
    (?T . ("████████╗" "╚══██╔══╝" "   ██║   " "   ██║   " "   ██║   " "   ╚═╝   "))))

(defun unzeit/dashboard-insert-logo ()
  "居中插入 UNZEIT logo：UN 强调色、ZEIT 白色
所有行都经由一次 dashboard-insert-center 调用，使整个横幅share同一个
居中前缀（line-prefix）若逐行各自居中，会因为各行宽度不同
（93/94/84/85/92/89）而让字母列左右错开"
  (let (rows)
    (dotimes (row 6)
      (let ((line ""))
        (dotimes (i 6)
          (let* ((ch (aref "UNZEIT" i))
                 (letter (cdr (assq ch unzeit/dashboard-letters)))
                 (face (if (< i 2) 'unzeit-dashboard-logo-red 'unzeit-dashboard-logo)))
            (unless (string= line "")
              (setq line (concat line " ")))
            (setq line (concat line (propertize (nth row letter) 'face face)))))
        (push line rows)))
    (dashboard-insert-center (mapconcat #'identity (nreverse rows) "\n") "\n")))

;; nano 风格底部帮助：常用的 leader 快捷键两列对齐网格（每行两个）；
;; SPC o m 打开 ~/org/操作手册.org
(defconst unzeit/dashboard-shortcuts
  '(("SPC o m" . "操作手册")
    ("SPC h" . "主页")
    ("SPC m ?" . "meow 速查")
    ("SPC f f" . "打开文件")
    ("SPC f d" . "Dired")
    ("SPC p f" . "项目文件")
    ("SPC b b" . "切换缓冲")
    ("SPC s g" . "全局搜索")
    ("SPC w v" . "左右分屏")
    ("SPC g s" . "git 状态")
    ("SPC c c" . "打开配置")
    ("SPC l d" . "跳转定义")
    ("SPC z +" . "放大字体")
    ("SPC t" . "eshell")
    ("C-x C-f" . "打开")
    ("C-s" . "搜索")))

(defun unzeit/dashboard-help-key (key)
  "把 KEY 以主屏快捷键样式（强调色加粗）返回"
  (propertize key 'face 'unzeit-dashboard-key))

(require 'seq)

(defun unzeit/dashboard-col-widths (cells)
  "返回非 nil CELLS 的 (键宽 . 标签宽)，按 string-width 计算"
  (let ((cells (remove nil cells)))
    (cons (seq-max (mapcar (lambda (c) (string-width (car c))) cells))
          (seq-max (mapcar (lambda (c) (string-width (cdr c))) cells)))))

(defun unzeit/dashboard-align-space (col half-grid)
  "返回一个 display 空格，把下一段文本固定在网格的第 COL 列
COL 从网格左边缘向右数；HALF-GRID 是总网格宽度的一半使用实时 `center'
符号，让网格随窗口尺寸变化保持居中与空格 padding 不同，它把列钉在
同一水平位置（无论 CJK 字形如何渲染），因此两列在每一行都能对齐"
  (propertize " " 'display
              `(space . (:align-to (- center ,(- half-grid col))))))

(defun unzeit/dashboard-manual-hint ()
  "插入一个居中的、每行两个的两列对齐快捷键网格
每个列边界用 :align-to display 空格（相对于窗口中心的绝对列）钉住，
从而使每列的键与标签都能纵向对齐（不受字形宽度影响）行直接插入
（不经过 dashboard-insert-center），因为第一个 :align-to 已提供共享的居中
前缀；若逐行独立居中会把整行左右移动、破坏第二列的对齐"
  (let* ((rows (seq-partition unzeit/dashboard-shortcuts 2))
         (w0 (unzeit/dashboard-col-widths (mapcar #'car rows)))
         (w1 (unzeit/dashboard-col-widths (mapcar #'cadr rows)))
         (kw0 (car w0))
         (lw0 (cdr w0))
         (kw1 (car w1))
         (lw1 (cdr w1))
         (grid-w (+ kw0 1 lw0 4 kw1 1 lw1))
         (half (/ (float grid-w) 2))
         (label0 (+ kw0 1))
         (key1 (+ kw0 1 lw0 4))
         (label1 (+ kw0 1 lw0 4 kw1 1))
         (lines (mapcar (lambda (row)
                          (let ((c0 (car row)) (c1 (cadr row)))
                            (concat
                             (unzeit/dashboard-align-space 0 half)
                             (unzeit/dashboard-help-key (car c0))
                             (unzeit/dashboard-align-space label0 half)
                             (cdr c0)
                             (unzeit/dashboard-align-space key1 half)
                             (unzeit/dashboard-help-key (car c1))
                             (unzeit/dashboard-align-space label1 half)
                             (cdr c1))))
                        rows)))
    (insert (mapconcat #'identity lines "\n"))))

(use-package dashboard
  :ensure t
  :demand t
  :config
  ;; 横幅：使用自定义的 UNZEIT logo（按字母分色），而非内置横幅机制
  (setq dashboard-banner-logo-title nil)
  (setq dashboard-center-content t)
  (setq dashboard-items '((recents . 8)
                          (projects . 5)))
  (setq dashboard-set-heading-icons nil)
  (setq dashboard-set-file-icons nil)
  (setq dashboard-heading-shortcut-keys t)
  (setq dashboard-startupify-list
        '(unzeit/dashboard-pad-top
          unzeit/dashboard-insert-logo
          dashboard-insert-newline
          dashboard-insert-init-info
          unzeit/dashboard-pad-mid
          dashboard-insert-items
          unzeit/dashboard-manual-hint))

  ;; ---- 对 dashboard 各 face 应用 nano-dark 调色板 -------------------
  (dolist (face '((dashboard-heading . unzeit/accent)
                  (dashboard-item-common . unzeit/fg)
                  (dashboard-item-shortcuts . unzeit/accent)
                  (dashboard-item-basenames . unzeit/fg-muted)
                  (dashboard-item-directories . unzeit/fg-faint)
                  (dashboard-navigator . unzeit/fg-muted)
                  (dashboard-footer . unzeit/fg-muted)))
    (when (facep (car face))
      (set-face-foreground (car face) (symbol-value (cdr face)))))
  (set-face-bold-p 'dashboard-heading t)

  ;; ---- 布局 -------------------------------------------------------
  (defun unzeit/dashboard-pad-top ()
    "把主屏内容块往下推到窗口中下部"
    (insert (make-string (max 2 (/ (- (window-height) 34) 2)) ?\n)))
  (defun unzeit/dashboard-pad-mid ()
    "在信息行与内容项之间再加一点呼吸空间"
    (insert "\n"))

  (dashboard-setup-startup-hook))

;; 按需显示主屏（SPC h），以及为空的 emacsclient 会话显示
;;（server-execute 会查询 `initial-buffer-choice'，它必须返回一个活的缓冲）
(defun unzeit/dashboard ()
  "打开主屏缓冲"
  (interactive)
  (require 'dashboard)
  (dashboard-insert-startupify-lists)
  (switch-to-buffer dashboard-buffer-name)
  (get-buffer dashboard-buffer-name))

(setq initial-buffer-choice #'unzeit/dashboard)

(provide 'init-dashboard)
;;; init-dashboard.el ends here

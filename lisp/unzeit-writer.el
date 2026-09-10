;;; unzeit-writer.el --- Unzeit: 专注写作模式（灵感来自 nano-writer） -*- lexical-binding: t; -*-

;;; Commentary:
;; nano-emacs 的 nano-writer 把 org 缓冲变成一张"稿纸"：正文居中留白、
;; 行距舒展、标题放大、行号之类的装饰全部收起。这里保留它的精神，只用
;; Emacs 内置能力实现（face-remap + buffer-local 的左右 margin +
;; line-spacing），不引入任何依赖。
;;
;; 用法：SPC o w 切换（org 前缀），对 org / text / markdown 缓冲都有效。
;; 想让正文换成衬线或手写体，把 `unzeit/writer-font' 设成 "LXGW WenKai"
;; 之类即可；默认不动字体，中文回退仍走 core.el 里的 fontset 设置。
;;
;; 实现要点：margin 记在 buffer-local 的 `left-margin-width' /
;; `right-margin-width' 上，窗口切到别的缓冲时 Emacs 会自动按对方的设置
;; 重算，不会把留白漏到别的 buffer 上

;;; Code:

(defgroup unzeit-writer nil
  "Unzeit：专注写作模式"
  :group 'unzeit
  :prefix "unzeit/writer-")

(defcustom unzeit/writer-column 88
  "写作模式正文的目标列宽。窗口比它宽时，两侧留白把正文居中。"
  :group 'unzeit-writer
  :type 'integer)

(defcustom unzeit/writer-line-spacing 0.4
  "写作模式的行距（0.4 表示字号高度的 40%）。"
  :group 'unzeit-writer
  :type 'number)

(defcustom unzeit/writer-font nil
  "写作模式的正文族；nil 表示不动字体。
例如 \"LXGW WenKai\" 会得到一张偏手写稿纸的感觉。"
  :group 'unzeit-writer
  :type '(choice (const :tag "不改字体" nil) string))

(defconst unzeit/writer--height-faces
  '((org-level-1 . 1.35)
    (org-level-2 . 1.25)
    (org-level-3 . 1.15)
    (org-level-4 . 1.1)
    (org-document-title . 1.5))
  "写作模式下放大的 face 及其相对高度。")

(defvar-local unzeit/writer--saved nil
  "进入写作模式前的缓冲局部状态，退出时按它恢复。")

(defvar-local unzeit/writer--cookies nil
  "`face-remap-add-relative' 的返回值，退出时逐条撤销。")

(defun unzeit/writer--margin ()
  "当前缓冲按 `unzeit/writer-column' 需要的左右留白列数。"
  (max 0 (/ (- (window-body-width (or (get-buffer-window (current-buffer) t)
                                      (selected-window)))
                unzeit/writer-column)
            2)))

(defun unzeit/writer--apply-margins (&rest _)
  "刷新当前缓冲的左右留白（窗口尺寸变化后重算）。"
  (when unzeit/writer-mode
    (let ((margin (unzeit/writer--margin)))
      (unless (and (= margin left-margin-width)
                   (= margin right-margin-width))
        (setq-local left-margin-width margin
                    right-margin-width margin)
        (dolist (window (get-buffer-window-list (current-buffer) nil t))
          (set-window-margins window margin margin))))))

(defun unzeit/writer--enable ()
  "打开写作模式：留白居中、加大行距、收起行号、放大 org 标题。"
  (setq unzeit/writer--saved
        (list :line-spacing line-spacing
              :truncate-lines truncate-lines
              :visual-line visual-line-mode
              ;; display-line-numbers 由 autoload 定义，可能还没加载过，
              ;; 所以要用 bound-and-true-p 读
              :line-numbers (bound-and-true-p display-line-numbers-mode)
              :cursor-type cursor-type
              :margins (cons left-margin-width right-margin-width)))
  (setq line-spacing unzeit/writer-line-spacing)
  (setq truncate-lines nil)
  (unless visual-line-mode (visual-line-mode 1))
  (when (bound-and-true-p display-line-numbers-mode)
    (display-line-numbers-mode -1))
  (setq-local cursor-type 'bar)
  (when unzeit/writer-font
    (push (face-remap-add-relative 'default :family unzeit/writer-font)
          unzeit/writer--cookies))
  (dolist (entry unzeit/writer--height-faces)
    (push (face-remap-add-relative (car entry) :height (cdr entry))
          unzeit/writer--cookies))
  (add-hook 'window-configuration-change-hook #'unzeit/writer--apply-margins nil t)
  (unzeit/writer--apply-margins))

(defun unzeit/writer--disable ()
  "关闭写作模式，按进入前记录的状态恢复。"
  (let ((saved unzeit/writer--saved))
    (when saved
      ;; 先让两个 minor mode 恢复（visual-line-mode 退出时会自己把
      ;; truncate-lines 还原成它记录的值），再写回我们保存的变量，
      ;; 否则会被它覆盖
      (visual-line-mode (if (plist-get saved :visual-line) 1 -1))
      (display-line-numbers-mode (if (plist-get saved :line-numbers) 1 -1))
      (setq line-spacing (plist-get saved :line-spacing)
            truncate-lines (plist-get saved :truncate-lines))
      (setq-local cursor-type (plist-get saved :cursor-type))
      (let ((margins (plist-get saved :margins)))
        (setq-local left-margin-width (car margins)
                    right-margin-width (cdr margins))
        (dolist (window (get-buffer-window-list (current-buffer) nil t))
          (set-window-margins window (car margins) (cdr margins))))))
  (dolist (cookie unzeit/writer--cookies)
    (face-remap-remove-relative cookie))
  (setq unzeit/writer--cookies nil
        unzeit/writer--saved nil)
  (remove-hook 'window-configuration-change-hook #'unzeit/writer--apply-margins t))

;;;###autoload
(define-minor-mode unzeit/writer-mode
  "Unzeit 专注写作模式。
正文按 `unzeit/writer-column' 居中留白、行距加大、行号收起，org 标题
按层级放大；退出时恢复进入前的样子。"
  :lighter " ✎"
  :group 'unzeit-writer
  (if unzeit/writer-mode
      (unzeit/writer--enable)
    (unzeit/writer--disable)))

(defun unzeit/writer-toggle ()
  "在 org / text / markdown 缓冲里切换 `unzeit/writer-mode'。"
  (interactive)
  (unless (derived-mode-p 'org-mode 'text-mode 'markdown-mode)
    (user-error "写作模式只用于 org / text / markdown 缓冲"))
  (unzeit/writer-mode 'toggle))

(provide 'unzeit-writer)
;;; unzeit-writer.el ends here

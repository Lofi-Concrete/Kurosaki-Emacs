;;; unzeit-popups.el --- Unzeit: 浮动弹层 / 视觉层（Centaur 风格） -*- lexical-binding: t; -*-

;;; Commentary:
;; which-key 的 posframe 在 editor.el（紧随 which-key 配置）；这里放其余弹层
;; 与 solaire。所有项都受 unzeit/modern-* 开关控制，无 GUI 时自动跳过。

;;; Code:

(defun unzeit/childframe-workable-p ()
  "当前帧是否适合用 childframe（GUI + 独立 minibuffer 帧）。"
  (and (display-graphic-p)
       (eq (frame-parameter (selected-frame) 'minibuffer) 't)))

;; 非文件 buffer 变暗（Centaur 的 solaire-mode）。
(when unzeit/modern-solaire
  (use-package solaire-mode
    :ensure t
    :demand t
    :config
    (when (boundp 'solaire-mode-remap-alist)
      (add-to-list 'solaire-mode-remap-alist
                   '(ghostel-default . solaire-default-face)))
    (solaire-global-mode 1)))

(defcustom unzeit/vertico-posframe-center t
  "非 nil 时 vertico childframe 水平+垂直居中；nil 时用 Centaur 的 near-bottom。"
  :type 'boolean
  :group 'unzeit/modern)

;; vertico 候选放到 childframe（默认开，居中）。
(when unzeit/modern-vertico-posframe
  (use-package vertico-posframe
    :ensure t
    :demand t
    :custom
    (vertico-posframe-poshandler
     (if unzeit/vertico-posframe-center
         #'posframe-poshandler-frame-center
       #'posframe-poshandler-frame-center-near-bottom))
    (vertico-posframe-border-width 2)
    (vertico-posframe-parameters
     '((left-fringe . 8) (right-fringe . 8)))
    (vertico-posframe-truncate-lines t)
    :config
    (defun unzeit/enable-vertico-posframe (&rest _)
      (when (unzeit/childframe-workable-p)
        (vertico-posframe-mode 1)))
    (add-hook 'window-setup-hook #'unzeit/enable-vertico-posframe 'append)
    (add-hook 'after-make-frame-functions
              #'unzeit/enable-vertico-posframe 'append)))

;; transient（dape / aidermacs 等）也放 childframe。
(when unzeit/modern-posframe
  (use-package transient-posframe
    :ensure t
    :demand t
    :config
    (defun unzeit/enable-transient-posframe (&rest _)
      (when (unzeit/childframe-workable-p)
        (transient-posframe-mode 1)))
    (add-hook 'window-setup-hook #'unzeit/enable-transient-posframe 'append)
    (add-hook 'after-make-frame-functions
              #'unzeit/enable-transient-posframe 'append)))

;; Emacs 31 的 eldoc 默认带 `eldoc-display-in-buffer`，会在旁边开一个
;; *eldoc* 侧窗。这里只阻止它“显示窗口”，仍然创建 *eldoc* 缓冲（eldoc-mouse
;; 的鼠标弹窗要读它）；echo area 也照常。
(defun unzeit/eldoc-no-side-window (orig &rest args)
  "调用 ORIG 但不让 `eldoc-display-in-buffer' 开侧窗。"
  (let ((display-buffer-overriding-action '(display-buffer-no-window)))
    (apply orig args)))

(when (fboundp 'eldoc-display-in-buffer)
  (unless (advice-member-p #'unzeit/eldoc-no-side-window
                           #'eldoc-display-in-buffer)
    (advice-add 'eldoc-display-in-buffer :around
                #'unzeit/eldoc-no-side-window)))

;; 不让 eldoc 的 buffer display 出现在 eldoc-display-functions 里（侧窗来源）。
(defun unzeit/eldoc-no-buffer-display ()
  (setq-local eldoc-display-functions
              (delq 'eldoc-display-in-buffer eldoc-display-functions)))
(add-hook 'prog-mode-hook #'unzeit/eldoc-no-buffer-display)

;; C-h . 的 eldoc 文档用 childframe（Centaur 的 eldoc-mouse）。
;; 这个 minor mode 是 buffer-local，包没有 global 版本，所以挂 prog-mode。
(when unzeit/modern-eldoc-mouse
  (use-package eldoc-mouse
    :ensure t
    :hook (prog-mode . eldoc-mouse-mode)))

;; 正常 eldoc 的 docs 里可能混入 (nil ...)，eldoc-mouse 的 display 函数
;; 会对它 string-match，报 wrong-type-argument stringp nil；加个保护。
(defun unzeit/eldoc-mouse-display-guard (orig docs &rest args)
  (when (and docs (stringp (car-safe (car-safe docs))))
    (apply orig
           (mapcar (lambda (doc)
                     (if (and (consp doc) (stringp (car doc)))
                         (cons (unzeit/eldoc-decode-doc (car doc)) (cdr doc))
                       doc))
                   docs)
           args)))

;; eldoc-mouse 弹窗左右各 8px fringe，默认用更暗的 fringe face，看着像两条空隙。
;; 保留 8px 内边距，但把 fringe 背景改成正文背景。
(with-eval-after-load 'eldoc-mouse
  (set-face-attribute 'fringe nil
                      :background (face-attribute 'default :background nil t)))
(with-eval-after-load 'eldoc-mouse
  (unless (advice-member-p #'unzeit/eldoc-mouse-display-guard
                           #'eldoc-mouse-display-in-posframe)
    (advice-add 'eldoc-mouse-display-in-posframe :around
                #'unzeit/eldoc-mouse-display-guard)))

;; 光标停留的文档：用 eldoc-mouse 自己的 posframe（保留原来的外观），
;; 不经过 eldoc 的 display functions，所以不会开 *eldoc* 侧窗。
(defcustom unzeit/eldoc-dwell-delay 0.7
  "光标在符号上停留多久后弹 eldoc-mouse 的 childframe（秒）。"
  :type 'number
  :group 'unzeit/modern)

(defvar-local unzeit/eldoc-dwell-timer nil
  "当前 buffer 的光标停留 idle timer。")

(defvar-local unzeit/eldoc-dwell-bounds nil
  "当前弹出的文档对应的符号范围。")

(defun unzeit/eldoc-decode-doc (doc)
  "把 UTF-8 原始字节或 \342\200\242 这类八进制转义解回文字。"
  (when (stringp doc)
    (setq doc (replace-regexp-in-string
               "\\\\\\([0-7]\\{3\\}\\)\\\\\\([0-7]\\{3\\}\\)\\\\\\([0-7]\\{3\\}\\)"
               (lambda (m)
                 (decode-coding-string
                  (unibyte-string (string-to-number (match-string 1 m) 8)
                                  (string-to-number (match-string 2 m) 8)
                                  (string-to-number (match-string 3 m) 8))
                  'utf-8))
               doc))
    (if (not (multibyte-string-p doc))
        (condition-case nil
            (decode-coding-string doc 'utf-8)
          (error doc))
      doc)))
(defun unzeit/eldoc-decode-doc-args (args)
  "把 eldoc-mouse 文档参数里的 UTF-8 原始字节解回文字。"
  (cons (unzeit/eldoc-decode-doc (car args)) (cdr args)))

(with-eval-after-load 'eldoc-mouse
  (unless (advice-member-p #'unzeit/eldoc-decode-doc-args
                           #'eldoc-mouse--pop-doc)
    (advice-add 'eldoc-mouse--pop-doc :filter-args
                #'unzeit/eldoc-decode-doc-args)))

(defun unzeit/eldoc-dwell-cancel ()
  "取消当前 buffer 的光标停留 timer。"
  (when (timerp unzeit/eldoc-dwell-timer)
    (cancel-timer unzeit/eldoc-dwell-timer))
  (setq unzeit/eldoc-dwell-timer nil))

(defun unzeit/eldoc-dwell-hide ()
  "点离开符号后清掉 bounds（posframe 由 eldoc-mouse 自己收）。"
  (when (and unzeit/eldoc-dwell-bounds
             (or (< (point) (car unzeit/eldoc-dwell-bounds))
                 (> (point) (cdr unzeit/eldoc-dwell-bounds))))
    (setq unzeit/eldoc-dwell-bounds nil)))

(defun unzeit/eldoc-dwell-show ()
  "光标停留后取 eglot hover 文档，用 eldoc-mouse 的 posframe 显示。"
  (when (and (display-graphic-p)
             (derived-mode-p 'prog-mode)
             (not (active-minibuffer-window))
             (not (region-active-p))
             (not (and (boundp 'corfu--frame)
                       (frame-live-p corfu--frame)
                       (frame-visible-p corfu--frame)))
             (not (bound-and-true-p completion-in-region-mode))
             (thing-at-point 'symbol)
             (bound-and-true-p eglot--managed-mode)
             (fboundp 'eglot-hover-eldoc-function)
             (fboundp 'eldoc-mouse--pop-doc))
    (let* ((bounds (bounds-of-thing-at-point 'symbol))
           (buf (current-buffer)))
      (when (and bounds (not (equal bounds unzeit/eldoc-dwell-bounds)))
        (eglot-hover-eldoc-function
         (lambda (doc &rest _)
           (when (and (stringp doc)
                      (not (string-empty-p (string-trim doc))))
             (when (buffer-live-p buf)
               (with-current-buffer buf
                 (setq-local eldoc-mouse-last-symbol-bounds bounds)
                 (eldoc-mouse--pop-doc
                  (unzeit/eldoc-decode-doc (string-trim doc)))
                 (setq unzeit/eldoc-dwell-bounds bounds))))))))))

(defun unzeit/eldoc-dwell-schedule ()
  "每次命令后重置“光标停留”timer；停够时间才弹。"
  (unzeit/eldoc-dwell-cancel)
  (when (and (display-graphic-p)
             (derived-mode-p 'prog-mode)
             (not (active-minibuffer-window))
             (not (region-active-p))
             (not (and (boundp 'corfu--frame)
                       (frame-live-p corfu--frame)
                       (frame-visible-p corfu--frame)))
             (not (bound-and-true-p completion-in-region-mode))
             (thing-at-point 'symbol)
             (bound-and-true-p eglot--managed-mode))
    (let ((buf (current-buffer)))
      (setq unzeit/eldoc-dwell-timer
            (run-with-idle-timer
             unzeit/eldoc-dwell-delay nil
             (lambda ()
               (when (and (buffer-live-p buf)
                          (eq buf (window-buffer (selected-window))))
                 (with-current-buffer buf
                   (unzeit/eldoc-dwell-show)))))))))

(defun unzeit/eldoc-dwell-setup ()
  "在 prog 缓冲里挂上光标停留触发器。"
  (add-hook 'post-command-hook #'unzeit/eldoc-dwell-schedule nil t)
  (add-hook 'post-command-hook #'unzeit/eldoc-dwell-hide nil t)
  (add-hook 'kill-buffer-hook #'unzeit/eldoc-dwell-cancel nil t))

(add-hook 'prog-mode-hook #'unzeit/eldoc-dwell-setup)

(provide 'unzeit-popups)
;;; unzeit-popups.el ends here

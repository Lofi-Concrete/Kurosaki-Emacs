;;; init-dashboard.el --- 主屏：emacs-dashboard（Centaur 风格） -*- lexical-binding: t; -*-

;;; Commentary:
;; dashboard 包：logo + 随机 galgame 台词 + 最近编辑/项目。
;;; Code:

(require 'unzeit-quotes-galgame)

;;; ---- 语录（galgame 日语原句，见 unzeit-quotes-galgame.el）------------

(defun unzeit/dashboard-insert-quote ()
  "在 logo 下方插入随机 galgame 台词（取代原 UNZEIT 标题）。"
  (when-let* ((quote (unzeit/galgame-quotes-random)))
    (dashboard-insert-center
     (propertize quote 'face 'font-lock-comment-face))
    (insert "\n")))

(defconst unzeit/dashboard-logo-file
  (expand-file-name "images/emacs-logo.png" user-emacs-directory)
  "主屏 logo：随配置部署的 Emacs 娘插画；放在 .emacs.d/images/ 随 guix home 进 store，清理下载目录不丢。
★ 必须是**带 alpha** 的 PNG：原图是不透明 RGB + `#1a1b26' 底色（TokyoNight 时期裁的），
换主题后会在主屏上留一块蓝黑方块；2026-11-13 已沿圆形边缘羽化转成 RGBA（圆外 alpha=0）。")

(defun unzeit/dashboard--logo ()
  "主屏 logo：配置里的文件，其次 ~/下载 的图，最后官方 logo。"
  (cond
   ((file-exists-p unzeit/dashboard-logo-file) unzeit/dashboard-logo-file)
   (t
    (let ((files
           (seq-filter
            (lambda (file)
              (string-match-p "\\.\\(png\\|jpe?g\\|webp\\)\\'" file))
            (apply #'append
                   (mapcar (lambda (pattern)
                             (file-expand-wildcards
                              (expand-file-name pattern)))
                           '("~/下载/retcho*" "~/下载/retouch*"))))))
      (or (car (sort files (lambda (a b) (file-newer-than-file-p a b))))
          'official)))))

;; 主屏只留 logo + 台词 + 最近编辑/项目，不放导航按钮行。

;;; ---- dashboard 本体 -------------------------------------------------

(defun unzeit/dashboard-hide-modeline ()
  "主屏里隐藏模式行、行号和标签栏。"
  (hl-line-mode -1)
  (display-line-numbers-mode -1)
  (setq-local mode-line-format nil
              header-line-format nil
              tab-line-format nil)
  ;; 主屏不隐藏光标（按钮/列表可键盘走）；光标本来就是 box。
  (setq-local track-mouse t))

(use-package dashboard
  :ensure t
  :demand t
  :init
  (setq dashboard-startup-banner (unzeit/dashboard--logo)
        ;; 从 170 放大到 300（源图 360×358，够清晰）
        dashboard-image-banner-max-width 300
        dashboard-image-banner-max-height 300
        ;; 标题行用随机台词替代 UNZEIT（见 startupify-list）
        dashboard-banner-logo-title nil
        dashboard-init-info (lambda ()
                              (format "%d packages · Emacs %s"
                                      (length package-activated-list)
                                      emacs-version))
        dashboard-icon-type 'nerd-icons
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-show-shortcuts nil
        dashboard-set-file-icons t
        dashboard-set-heading-icons t
        dashboard-projects-backend 'project-el
        dashboard-path-style 'truncate-middle
        dashboard-path-max-length 60
        dashboard-items '((recents . 3)
                          (projects . 2))
        dashboard-item-names '(("Recent Files:" . "最近编辑")
                               ("Projects:" . "项目"))
        dashboard-startupify-list '(dashboard-insert-banner
                                    dashboard-insert-newline
                                    unzeit/dashboard-insert-quote
                                    dashboard-insert-newline
                                    dashboard-insert-init-info
                                    dashboard-insert-items))
  :custom-face
  (dashboard-banner-logo-title
   ((t (:inherit font-lock-keyword-face :weight bold))))
  (dashboard-heading
   ((t (:inherit (font-lock-string-face bold)))))
  (dashboard-items-face
   ((t (:weight normal))))
  (dashboard-no-items-face
   ((t (:weight normal))))
  :hook (dashboard-mode . unzeit/dashboard-hide-modeline)
  :bind (:map dashboard-mode-map
              ("q" . unzeit/dashboard-quit)
              ("g" . dashboard-open)
              ("r" . dashboard-open))
  :config
  (dashboard-setup-startup-hook))

;;; ---- 与启动流程 / 开关的衔接 ----------------------------------------

(defun unzeit/dashboard ()
  "打开（或刷新）主屏，并返回它的 buffer。"
  (interactive)
  (delete-other-windows)
  (dashboard-open)
  (let ((buf (get-buffer dashboard-buffer-name)))
    (when (buffer-live-p buf)
      (switch-to-buffer buf))
    buf))

(defun unzeit/dashboard-quit ()
  "离开主屏：回到上一个缓冲并杀掉 dashboard buffer。"
  (interactive)
  (let ((buf (get-buffer dashboard-buffer-name)))
    (unzeit/switch-to-last-buffer)
    (when (buffer-live-p buf)
      (kill-buffer buf))))

(defun unzeit/dashboard-toggle ()
  "主屏开关：已经在主屏就回到上一个缓冲，否则打开主屏。"
  (interactive)
  (if (or (equal (buffer-name) dashboard-buffer-name)
          (derived-mode-p 'dashboard-mode))
      (unzeit/dashboard-quit)
    (unzeit/dashboard)))

(defconst unzeit/startup-option-args
  '("-l" "--load" "--eval" "-L" "--directory" "-f" "--funcall"
    "--insert" "--title" "--name" "-T" "--dump-file")
  "这些启动选项**带一个取值**，取值不是要打开的文件。")

(defun unzeit/startup-file ()
  "返回启动参数里第一个要打开的文件/目录；没有则 nil。"
  (let ((args (cdr command-line-args))
        (after-dash nil)
        found)
    (while (and args (not found))
      (let ((arg (car args)))
        (cond
         ((null arg) (setq args nil))
         (after-dash
          (when (file-exists-p (expand-file-name arg))
            (setq found (expand-file-name arg)))
          (setq args (cdr args)))
         ((string= arg "--") (setq after-dash t args (cdr args)))
         ((member arg unzeit/startup-option-args)
          (setq args (cddr args)))
         ((string-prefix-p "-" arg) (setq args (cdr args)))
         ((string-match-p "\\`\\+[0-9]" arg) (setq args (cdr args)))
         ((file-exists-p (expand-file-name arg))
          (setq found (expand-file-name arg)))
         (t (setq args (cdr args))))))
    found))

(defun unzeit/initial-buffer ()
  "启动时该显示什么：带文件就显示文件，否则显示主屏。"
  (if-let* ((file (unzeit/startup-file)))
      (find-file-noselect file)
    (unzeit/dashboard)))

(setq initial-buffer-choice #'unzeit/initial-buffer)

(provide 'init-dashboard)
;;; init-dashboard.el ends here

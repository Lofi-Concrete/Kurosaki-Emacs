;;; early-init.el --- Unzeit: 启动优化（第一帧形状与启动提速） -*- lexical-binding: t; -*-

(setq gc-cons-percentage 1.0)
(setq gc-cons-threshold most-positive-fixnum)
;; 运行时开关统一在 core.el 的性能节；这里只管启动窗口期（GC、file-name-handler、包初始化）。
(setq package-native-compile t)

(let ((default-file-name-handler-alist file-name-handler-alist)
      (default-load-suffixes load-suffixes))
  (setq file-name-handler-alist nil
        load-suffixes '(".elc" ".el"))
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq file-name-handler-alist default-file-name-handler-alist
                    load-suffixes default-load-suffixes))
            101))

;; 包初始化交给 lisp/init-package.el
(setq package-enable-at-startup nil)
(setq package-quickstart t)

;; 永远不要 GUI 装饰（菜单栏、工具栏、滚动条）
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)
;; 第一帧前清掉 mode line，避免主题生效前的白条（Centaur 同款）。
(setq-default mode-line-format nil)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(internal-border-width . 15) default-frame-alist)

(push '(width . (text-pixels . 1728)) default-frame-alist)
(push '(height . (text-pixels . 972)) default-frame-alist)

;; 一切用 UTF-8
(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")

(defvar unzeit/exec-front '())
(defvar unzeit/exec-tail '())
(defvar unzeit/ld-library-dirs '())

(defun unzeit/expand-dirs (dirs)
  "把 DIRS 展开成绝对路径（按 `~' 解析，支持通配符）。"
  (apply #'append
         (mapcar (lambda (d)
                   (let ((full (expand-file-name d "~")))
                     (or (file-expand-wildcards full) (list full))))
                 dirs)))

(defun unzeit/toolchain-register (plist)
  "登记工具链目录：:front 最优先，:tail 排最后，:ld-library-path 进 LD_LIBRARY_PATH。"
  (let ((front (plist-get plist :front))
        (tail (plist-get plist :tail))
        (ld (plist-get plist :ld-library-path)))
    (when front
      (setq unzeit/exec-front (append unzeit/exec-front (unzeit/expand-dirs front))))
    (when tail
      (setq unzeit/exec-tail (append unzeit/exec-tail (unzeit/expand-dirs tail))))
    (when ld
      (setq unzeit/ld-library-dirs
            (append unzeit/ld-library-dirs (unzeit/expand-dirs ld))))))

(let ((dir (expand-file-name "langs/toolchains" user-emacs-directory)))
  (when (file-directory-p dir)
    (dolist (f (directory-files dir t "\\`[^.#].*\\.el\\'"))
      (condition-case err
          (load f nil t)
        (error (message "Unzeit: 加载工具链配置 %s 失败: %S"
                        (file-name-nondirectory f) err))))))

(let* ((base (append exec-path nil))   ; Emacs 启动时由 $PATH 初始化，保留原顺序
       (exec-dirs nil))
  ;; 只保留真实存在的目录；delete-dups 去重且保留首次出现的位置
  (dolist (d (delete-dups (append unzeit/exec-front base unzeit/exec-tail)))
    (when (file-directory-p d)
      (push d exec-dirs)))
  (setq exec-dirs (nreverse exec-dirs))
  (setq exec-path exec-dirs)
  (setenv "PATH" (mapconcat #'identity exec-dirs ":"))
  (dolist (lib (delete-dups unzeit/ld-library-dirs))
    (when (file-directory-p lib)
      (setenv "LD_LIBRARY_PATH"
              (if (getenv "LD_LIBRARY_PATH")
                  (concat lib ":" (getenv "LD_LIBRARY_PATH"))
                lib)))))

;; 长行/横向滚动的渲染上限，避免超长行卡住 redisplay。
(setq long-line-threshold 1000
      large-hscroll-threshold 1000
      syntax-wholeline-max 1000)

(add-to-list 'default-frame-alist '(font . "Maple Mono NF CN-13"))

;;; early-init.el ends here

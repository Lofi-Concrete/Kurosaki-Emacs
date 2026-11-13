;;; init-package.el --- Unzeit: package.el 引导（镜像测速、归档新鲜度） -*- lexical-binding: t; -*-

(require 'package)

;;; ---- ELPA 镜像测速 -------------------------------------------------

(defconst unzeit/package-official-archives
  '(("gnu" . "https://elpa.gnu.org/packages/")
    ("nongnu" . "https://elpa.nongnu.org/nongnu/")
    ("melpa" . "https://melpa.org/packages/"))
  "官方归档：所有镜像都不可达时的回退（经 mihomo 代理）。")

(defcustom unzeit/package-mirrors
  '(("tuna" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/")
    ("ustc" . "https://mirrors.ustc.edu.cn/elpa/")
    ("bfsu" . "https://mirrors.bfsu.edu.cn/elpa/")
    ("nju" . "https://mirror.nju.edu.cn/elpa/"))
  "候选 ELPA 镜像（名称 . 根 URL）；根下须有 gnu/ nongnu/ melpa/ 三个子目录。
UNZEIT_PACKAGE_MIRROR 可直接指定 base、跳过测速。"
  :group 'package
  :type '(alist :key-type string :value-type string))

(defcustom unzeit/package-mirror-ttl (* 7 24 60 60)
  "镜像测速结果的有效期（秒），默认七天。"
  :group 'package
  :type 'number)

(defcustom unzeit/package-mirror-retry-ttl 3600
  "测速全灭后再试的间隔（秒），默认一小时。"
  :group 'package
  :type 'number)

(defconst unzeit/package-mirror-cache-file
  (expand-file-name ".unzeit-package-mirror" user-emacs-directory)
  "镜像测速结果缓存文件，内容是 (BASE . 时间戳)。")

(defun unzeit/package-mirror-latency (base)
  "用 HEAD 测镜像响应时间；405 算可达。"
  (let* ((url (concat base "gnu/archive-contents"))
         (url-request-method "HEAD")
         (url-automatic-caching nil)
         (url-show-status nil)
         (start (float-time))
         (buffer (condition-case nil
                     (url-retrieve-synchronously url t t 3)
                   (error nil))))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (unwind-protect
            (progn
              (goto-char (point-min))
              (when (re-search-forward "^HTTP/[0-9.]+ \\([0-9]+\\)" nil t)
                (when (member (match-string 1) '("200" "405"))
                  (- (float-time) start))))
          (kill-buffer buffer))))))

(defun unzeit/package-select-mirror ()
  "依次测试 `unzeit/package-mirrors'，返回响应最快的 BASE；全失败返回 nil。"
  (let ((best nil)
        (best-time nil))
    (dolist (mirror unzeit/package-mirrors)
      (let ((time (unzeit/package-mirror-latency (cdr mirror))))
        (when (and time (or (null best-time) (< time best-time)))
          (setq best (cdr mirror)
                best-time time))))
    (if best
        (message "Unzeit：ELPA 镜像选 %s（%.2f 秒）" best best-time)
      (message "Unzeit：ELPA 镜像都不可达，回退官方源"))
    best))

(defun unzeit/package-mirror-cache-read ()
  "读取镜像缓存，返回 (BASE . 时间戳)；文件不存在或损坏时返回 nil。"
  (when (file-readable-p unzeit/package-mirror-cache-file)
    (condition-case nil
        (with-temp-buffer
          (insert-file-contents unzeit/package-mirror-cache-file)
          (goto-char (point-min))
          (let ((entry (read (current-buffer))))
            (when (and (consp entry) (numberp (cdr entry)))
              entry)))
      (error nil))))

(defun unzeit/package-mirror-cache-write (base)
  "把测速结果 BASE（可能为 nil）连同时间戳写进缓存。"
  (condition-case nil
      (with-temp-file unzeit/package-mirror-cache-file
        (prin1 (cons base (float-time)) (current-buffer)))
    (error nil)))

(defun unzeit/package-mirror-entry-fresh-p (entry)
  "缓存条目是否仍在有效期内。"
  (and entry
       (< (- (float-time) (cdr entry))
          (if (car entry)
              unzeit/package-mirror-ttl
            unzeit/package-mirror-retry-ttl))))

(defun unzeit/package-mirror-base ()
  "返回本次要用的镜像 BASE；启动路径上绝不做现场测速。"
  (or (getenv "UNZEIT_PACKAGE_MIRROR")
      (car (unzeit/package-mirror-cache-read))))

(defun unzeit/package-mirror-schedule-probe ()
  "空闲 5 秒后后台重测镜像并切过去。"
  (unless (unzeit/package-mirror-entry-fresh-p
           (unzeit/package-mirror-cache-read))
    (run-with-idle-timer 5 nil #'unzeit/package-mirror-probe)))

;;; ---- 归档 ----------------------------------------------------------

(defun unzeit/package-archives-for (base)
  "把镜像根 URL 展开成 package-archives 形式。"
  (if base
      (mapcar (lambda (archive)
                (cons (car archive) (concat base (car archive) "/")))
              unzeit/package-official-archives)
    unzeit/package-official-archives))

(defun unzeit/package-mirror-probe (&rest _)
  "现场测速、写缓存并切换镜像（只由空闲定时器调）。"
  (let ((base (unzeit/package-select-mirror)))
    (unzeit/package-mirror-cache-write base)
    (setq package-archives (unzeit/package-archives-for base))))

(setq package-archives
      (unzeit/package-archives-for (unzeit/package-mirror-base)))

;; 缓存过期/缺失时，空闲时补测；启动时一个网络请求都不发
(unzeit/package-mirror-schedule-probe)

(setq package-archive-priorities
      '(("melpa" . 100)
        ("gnu" . 10)
        ("nongnu" . 5)))

(defcustom unzeit/package-refresh-days 7
  "归档内容列表（archive-contents）多久算过期（天）。"
  :group 'package
  :type 'number)

(defun unzeit/package-archives-present-p ()
  "所有归档的本地 archive-contents 是否都在（即是否首次运行）。"
  (let ((present t))
    (dolist (archive package-archives present)
      (unless (file-exists-p
               (expand-file-name (format "archives/%s/archive-contents"
                                         (car archive))
                                 package-user-dir))
        (setq present nil)))))

(defun unzeit/package-archives-stale-p ()
  "本地归档缓存是否过期。"
  (let ((limit (* unzeit/package-refresh-days 24 60 60))
        (stale nil))
    (dolist (archive package-archives stale)
      (let ((file (expand-file-name
                   (format "archives/%s/archive-contents" (car archive))
                   package-user-dir)))
        (unless (and (file-exists-p file)
                     (< (- (float-time)
                           (float-time (file-attribute-modification-time
                                        (file-attributes file))))
                        limit))
          (setq stale t))))))

(defun unzeit/package-refresh-if-stale ()
  "归档缓存过期时刷新一次（装包/升级/列包时）。"
  (when (unzeit/package-archives-stale-p)
    (condition-case err
        (with-timeout (15 (message "Unzeit：刷新包归档超时，先用本地缓存"))
          (message "Unzeit：刷新包归档列表…")
          (package-refresh-contents))
      (error (message "Unzeit：刷新包归档失败（%s），先用本地缓存" err)))))

(defun unzeit/package-list-packages ()
  "打开包列表前先按需刷新归档。"
  (interactive)
  (unzeit/package-refresh-if-stale)
  (package-list-packages))

(defun unzeit/package-upgrade-all ()
  "升级全部包之前先按需刷新归档。"
  (interactive)
  (unzeit/package-refresh-if-stale)
  (package-upgrade-all))

(unless (unzeit/package-archives-present-p)
  (unzeit/package-refresh-if-stale))

(package-initialize)

;;; ---- 按需安装（语言包首次打开文件时用）-----------------------------

(defun unzeit/ensure-package (package &optional vc-url)
  "确保包已装、依赖齐全并激活（VC-URL 或 ELPA）。"
  (let ((installed nil))
    (unless (package-installed-p package)
      (message "Unzeit：首次需要 %s，正在安装…" package)
      (if vc-url
          (progn
            (require 'package-vc)
            (if (consp vc-url)
                (package-vc-install (car vc-url) (cdr vc-url))
              (package-vc-install vc-url)))
        (unzeit/package-refresh-if-stale)
        (package-install package))
      (message "Unzeit：%s 安装完成" package)
      (setq installed t))
    (let ((desc (cadr (assq package package-alist))))
      (dolist (req (and desc (package-desc-reqs desc)))
        (unless (package-installed-p (car req))
          (message "Unzeit：为 %s 补装依赖 %s…" package (car req))
          (unzeit/ensure-package (car req))
          (setq installed t))))
    (package-activate package)
    (when installed
      (package-quickstart-refresh))))

;;; ---- use-package ---------------------------------------------------

(require 'use-package)

(setq use-package-always-ensure t
      use-package-always-defer t
      use-package-expand-minimally t
      use-package-enable-imenu-support t
      load-prefer-newer t)

;; 在 package-menu 操作后保持 quickstart 缓存新鲜
(advice-add 'package-menu-execute :after #'package-quickstart-refresh)

;;; init-package.el ends here
(provide 'init-package)

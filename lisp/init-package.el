;;; init-package.el --- Unzeit: package.el 引导（镜像测速、归档新鲜度） -*- lexical-binding: t; -*-

;;; Commentary:
;; 仅用 package.el + use-package不用 straight/elpaca：Guix 已经管理好了
;; 工具链，这里只负责从 ELPA 喂给 Emacs 所需的包
;;
;; 两件跟网络有关的家务都带缓存与兜底，且都不在启动路径上做无谓的请求：
;;   镜像测速（借鉴 centaur-emacs）：候选镜像里挑响应最快的，结果按
;;     `unzeit/package-mirror-ttl' 缓存；全不可达则回退官方源（走代理）
;;   归档新鲜度（借鉴 crafted-emacs）：按 archive-contents 的 mtime 判断，
;;     真正需要（安装/升级/列包）时才刷新，而不是"elpa 目录不在就刷"

;;; Code:

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
  "候选 ELPA 镜像（名称 . 根 URL）。
根 URL 下应能取到 gnu/ nongnu/ melpa/ 三个子目录。环境变量
UNZEIT_PACKAGE_MIRROR 可以直接指定 base，跳过测速。"
  :group 'package
  :type '(alist :key-type string :value-type string))

(defcustom unzeit/package-mirror-ttl (* 7 24 60 60)
  "镜像测速结果的有效期（秒），默认七天。"
  :group 'package
  :type 'number)

(defcustom unzeit/package-mirror-retry-ttl 3600
  "上次测速全军覆没后，隔多久再试（秒），默认一小时。
免得离线环境下每次启动都白等一轮超时。"
  :group 'package
  :type 'number)

(defconst unzeit/package-mirror-cache-file
  (expand-file-name ".unzeit-package-mirror" user-emacs-directory)
  "镜像测速结果缓存文件，内容是 (BASE . 时间戳)。")

(defun unzeit/package-mirror-latency (base)
  "用 HEAD 请求测量镜像 BASE 的响应时间（秒）。
不可达、超时或状态码异常时返回 nil；405（服务器不支持 HEAD）视为
可达 —— 延迟本身仍然说明问题。"
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

(defun unzeit/package-mirror-base ()
  "返回本次要用的镜像 BASE；nil 表示回退官方源。
优先级：环境变量 > 未过期的缓存 > 现场测速。测速结果一律写回缓存，
失败（nil）时用更短的 `unzeit/package-mirror-retry-ttl' 过期。"
  (or (getenv "UNZEIT_PACKAGE_MIRROR")
      (let ((entry (unzeit/package-mirror-cache-read)))
        (if (and entry
                 (< (- (float-time) (cdr entry))
                    (if (car entry)
                        unzeit/package-mirror-ttl
                      unzeit/package-mirror-retry-ttl)))
            (car entry)
          (let ((base (unzeit/package-select-mirror)))
            (unzeit/package-mirror-cache-write base)
            base)))))

;;; ---- 归档 ----------------------------------------------------------

(defun unzeit/package-archives-for (base)
  "把镜像根 URL BASE 展开成 `package-archives' 的形式。
BASE 为 nil 时返回官方源（所有镜像都不可达时的回退）。"
  (if base
      (mapcar (lambda (archive)
                (cons (car archive) (concat base (car archive) "/")))
              unzeit/package-official-archives)
    unzeit/package-official-archives))

(setq package-archives
      (unzeit/package-archives-for (unzeit/package-mirror-base)))

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
  "本地归档缓存是否过期。
任一 archive-contents 缺失，或其修改时间早于 `unzeit/package-refresh-days'
天，都算过期。"
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
  "归档缓存过期时刷新一次。
装包/升级/列包都是「马上要用网络」的时刻，失败了用户立刻就能看到，
所以这里不必讨好启动时间，只保证不阻塞、不报错中断。"
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

;; 首次运行（本地还没有任何归档缓存）才在启动时拉一次列表；此后交给上面
;; 几个按需入口，启动路径上不再有网络请求
(unless (unzeit/package-archives-present-p)
  (unzeit/package-refresh-if-stale))

(package-initialize)

;;; ---- 按需安装（语言包首次打开文件时用）-----------------------------

(defun unzeit/ensure-package (package &optional vc-url)
  "确保 PACKAGE 已安装、依赖齐全且已激活。
缺失时从 VC-URL（git 仓库地址字符串）或 ELPA 安装；声明了却没装的依赖
也一并补上——js2-refactor 就属于这种情况：本机装它时漏掉了
multiple-cursors，于是 `package-activate' 一直跳过它，后续 require 报
file-missing。依赖补齐后重新激活，并刷新 quickstart 缓存，免得下次启动
时新包的 autoloads 还不在缓存里。
只在按需加载语言包时调用（见 init-eglot.el），所以不怕慢。"
  (let ((installed nil))
    (unless (package-installed-p package)
      (message "Unzeit：首次需要 %s，正在安装…" package)
      (if vc-url
          (progn
            (require 'package-vc)
            (package-vc-install vc-url))
        (unzeit/package-refresh-if-stale)
        (package-install package))
      (message "Unzeit：%s 安装完成" package)
      (setq installed t))
    ;; 已安装但依赖缺失：补装（否则 package-activate 会跳过该包）
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

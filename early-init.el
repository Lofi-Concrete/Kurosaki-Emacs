;;; early-init.el --- Unzeit: 启动优化（第一帧形状与启动提速） -*- lexical-binding: t; -*-

;;; Commentary:
;; 在一切加载之前运行（Emacs 27+）所有包管理设置都在 lisp/init-package.el；
;; 这里只做两件事：缩短启动时间 + 塑造第一帧

;;; Code:

;; PERF: 启动时推迟垃圾回收；之后由 lisp/core.el 安装的 `gcmh' 恢复一个
;; 合理的阈值
(setq gc-cons-percentage 1.0)
(setq gc-cons-threshold most-positive-fixnum)
(setq read-process-output-max (* 4 1024 1024))
(setq native-comp-jit-compilation nil)

;; PERF: 大量 elisp 文件 API 调用会查询 `file-name-handler-alist'；
;; 加载配置期间跳过它（以及一些特殊的 load 后缀），启动后再还原
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
(setq frame-inhibit-implied-resize t)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; 一切用 UTF-8
(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")

;; ---- PATH / exec-path（shell 与子进程都要能看见工具链） ----------------
;; dwm autostart 拉起的 emacs（--daemon 或 GUI 实例）只继承 SLiM 给的最小
;; PATH：~/.local/bin、~/.config/guix/current/bin、~/.guix-home/profile、
;; /run/current-system/profile。版本管理器与手装工具（~/tools/bin 的
;; zig/zls/gopls/fix-tools、~/.cargo/bin 的 rust-analyzer、~/.ghcup/bin 的
;; hls、fnm 的 node 全局 bin 里的 typescript-language-server/prettier 等）
;; 全都靠交互式 zshrc 注入，因此 `SPC t` 的 eshell、compile、eglot、apheleia
;; 一律找不到它们（zig 的补全“很差”就是 zls 压根没在 exec-path 上）。
;; 这里在最早的启动阶段把那批目录补回去：exec-path 与 $PATH 一起改 ——
;; 前者给 Emacs 自己找程序，后者给 eshell/compile 拉起的子进程继承。
(let* ((home (file-name-as-directory (expand-file-name "~")))
       ;; 1) 自装工具链（zshrc 里位于最前，优先级高于 guix profile）
       (front (mapcar (lambda (d) (expand-file-name d home))
                      '(".local/bin"
                        "tools/bin" "tools/odin" "tools/c3c"
                        ".cargo/bin" ".ghcup/bin" ".rbenv/bin")))
       ;; 2) exec-path 在 Emacs 启动时由 $PATH 初始化，保留它的原始顺序
       (base (append exec-path nil))
       ;; 3) guix 各 profile 与系统兜底（profile/bin 必须排在 base 之后，
       ;;    否则 guix 里那些同名工具会抢走优先级）
       (tail (mapcar (lambda (d) (expand-file-name d home))
                     '(".guix-home/profile/bin" ".guix-home/profile/sbin"
                       ".guix-profile/bin" ".guix-profile/sbin"
                       ".config/guix/current/bin" ".opencode/bin"
                       ".sdkman/candidates/current/bin"
                       "/run/setuid-programs"
                       "/run/current-system/profile/bin"
                       "/run/current-system/profile/sbin")))
       (exec-dirs nil))
  ;; fnm 的版本目录名会随升级变化，用通配补上所有已安装版本
  (setq front (append front
                      (file-expand-wildcards
                       (expand-file-name ".local/share/fnm/node-versions/*/installation/bin" home) t)))
  ;; 只保留真实存在的目录；delete-dups 去重且保留首次出现的位置
  (dolist (d (delete-dups (append front base tail)))
    (when (file-directory-p d)
      (push d exec-dirs)))
  (setq exec-dirs (nreverse exec-dirs))
  (setq exec-path exec-dirs)
  (setenv "PATH" (mapconcat #'identity exec-dirs ":"))
  ;; patchelf 过的二进制（rust 工具链、node、JDK）需要 ~/tools/lib 里的
  ;; libgcc_s/libz/libstdc++ 等运行库；缺了会直接 exec 失败
  (let ((lib (expand-file-name "tools/lib" home)))
    (when (file-directory-p lib)
      (setenv "LD_LIBRARY_PATH"
              (if (getenv "LD_LIBRARY_PATH")
                  (concat lib ":" (getenv "LD_LIBRARY_PATH"))
                lib)))))

;; 在第一帧创建之前就设好字体，避免瞬间闪烁成错误字体
;; 拉丁 = Iosevka Term；中文/emoji/Nerd 图标等回退字体在 lisp/core.el 用
;; fontset 设置。这里的 “-24” 是磅值（font-spec 解析成 :size 24.0），对应
;; core.el 里正文档的 :height 240（= 24pt）；界面那档（18pt）与标签栏
;; （栏高 20.4pt / 文字 17pt）由 core.el 按 face 单独钉，不受这里影响
(add-to-list 'default-frame-alist '(font . "Iosevka Term-24"))

;;; early-init.el ends here

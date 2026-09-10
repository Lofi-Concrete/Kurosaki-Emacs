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

;; 在第一帧创建之前就设好字体，避免瞬间闪烁成错误字体
;; 中英文等回退字体在 lisp/core.el 设置
(add-to-list 'default-frame-alist '(font . "Maple Mono NF CN-16"))

;;; early-init.el ends here

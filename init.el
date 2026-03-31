;;; init.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Commentary:

;; This file bootstraps the configuration, which is divided into
;; a number of other files.

;;; Code:

;; Add lisp directory to load-path
(let ((default-directory (expand-file-name "lisp" user-emacs-directory)))
  (add-to-list 'load-path default-directory)
  (if (fboundp 'normal-top-level-add-subdirs-to-load-path)
    (normal-top-level-add-subdirs-to-load-path)))

;; Raise GC threshold, increase data throughput, and disable bidi
(setq gc-cons-threshold (* 128 1024 1024))
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)

;; Optimize deferred rendering
(setq jit-lock-defer-time 0)

;; Load initial modules
(require 'init-base)

;; Appearance
(require 'init-appearance-all)

;; Utilities
(require 'init-utilities-all)

;; Completion
(require 'init-completion-all)

;; Programming
(require 'init-programming-all)

;; Prevent duplicate loading
(provide 'init)

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

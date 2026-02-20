Configuration -*- lexical-binding: t -*-

(add-hook 'emacs-startup-hook
  (lambda ()
    (setq gc-cons-threshold (* 16 1024 1024)))))

(setq custom-file
  (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

(setq inhibit-startup-screen t)
(column-number-mode t)
(global-display-line-numbers-mode t)

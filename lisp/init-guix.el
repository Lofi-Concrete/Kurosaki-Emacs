;;; init-guix.el --- Unzeit: Emacs 与 Guix 集成（emacs-guix） -*- lexical-binding: t; -*-

;;; ---- 前缀命令：M-x guix 全家桶 -----------------------------------
(use-package guix
  :ensure nil
  :defer t
  :commands guix)

;;; ---- 包定义 / 服务定义：guix-devel-mode --------------------------
(defun unzeit/guix-devel-maybe ()
  "~/guix 下的 .scm 缓冲开 guix-devel-mode。"
  (when (and buffer-file-name
             (fboundp 'guix-devel-mode)
             (string-prefix-p (expand-file-name "~/guix/")
                              (expand-file-name buffer-file-name))
             (string-suffix-p ".scm" buffer-file-name))
    (with-demoted-errors "Unzeit: guix-devel-mode 失败: %S"
      (guix-devel-mode 1))))

(add-hook 'scheme-mode-hook #'unzeit/guix-devel-maybe)

;;; ---- build log 高亮：guix-build-log-minor-mode -------------------
(add-hook 'shell-mode-hook #'guix-build-log-minor-mode)
(add-hook 'eshell-mode-hook #'guix-build-log-minor-mode)

;;; ---- store 路径美化：global-guix-prettify-mode -------------------
(run-with-idle-timer
 1 nil
 (lambda ()
   (when (require 'guix-prettify nil t)
     (global-guix-prettify-mode 1))))

;;; ---- REPL 程序：优先当前世代，别回退到包里烧死的 store 路径 ------
(with-eval-after-load 'guix-external
  (let ((bin (or (executable-find "guix")
                 (let ((f (expand-file-name "~/.config/guix/current/bin/guix")))
                   (and (file-executable-p f) f)))))
    (when bin
      (setq guix-guile-program (list bin "repl")))))

;;; ---- 绑定：SPC c g / C-c g ---------------------------------------
(with-eval-after-load 'editor
  (keymap-set unzeit/custom-map (kbd "g") #'guix)
  (define-key unzeit/config-map (kbd "g") #'guix)
  (which-key-add-key-based-replacements "SPC c g" "Guix 包 / 世代 / 服务"))

(provide 'init-guix)
;;; init-guix.el ends here

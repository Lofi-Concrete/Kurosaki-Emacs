;;; init-local.el --- Unzeit: 个人、机器本地的定制 -*- lexical-binding: t; -*-

;;; Commentary:
;; 最后加载（见 init.el），因此这里定义的内容会覆盖其余所有配置
;; 本文件不由 Guix 部署：请在每台机器上直接于
;; ~/.emacs.d/lisp/init-local.el 创建它，它会在 reconfigure 后存留

;;; Code:

;; 例如:
;;   (setq org-directory "~/notes")
;;   (global-set-key (kbd "C-c j") #'some-command)

(provide 'init-local)
;;; init-local.el ends here

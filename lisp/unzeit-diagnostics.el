;;; unzeit-diagnostics.el --- Unzeit: 内联诊断（flyover） -*- lexical-binding: t; -*-

;;; Commentary:
;; Centaur 用 flyover 把 flymake 诊断画成内联覆盖层；行尾 chip 仍保留
;; （init-eglot.el），把 unzeit/modern-inline-diagnostics 设 nil 就回到纯 chip。

;;; Code:

(when (and unzeit/modern-inline-diagnostics
           (package-installed-p 'flyover))
  (use-package flyover
    :ensure nil
    :hook (prog-mode . flyover-mode)
    :custom
    (flyover-checkers '(flymake))
    ;; 关键：单行截断，避免长消息折行后左边那条竖线在下一行断掉。
    ;; 完整消息仍在 C-c f / 悬浮 help-echo / eldoc 里。
    (flyover-wrap-messages nil)
    (flyover-background-lightness 35)
    (flyover-icon-background-tint-percent 50)))

(provide 'unzeit-diagnostics)
;;; unzeit-diagnostics.el ends here

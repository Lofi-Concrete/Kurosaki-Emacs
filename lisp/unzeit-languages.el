;;; unzeit-languages.el --- Unzeit: 内置 ts-mode 的补充接线 -*- lexical-binding: t; -*-

;;; Commentary:
;; Centaur 的语言层是“内置 -ts-mode 直接接线”；这里补上 Unzeit 的 langs/
;; 树之外、但 Emacs 31 已经内置且本机有服务器/语法的两门：Lua 与 Ruby。
;; 不引入 treesit-auto，语法仍由 profile 预装。

;;; Code:

;; Lua：内置 lua-ts-mode + profile 里的 lua 语法 + lua-language-server。
(when (fboundp 'lua-ts-mode)
  (add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-ts-mode))
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 '(lua-ts-mode . ("lua-language-server")))))

;; Ruby：内置 ruby-ts-mode + profile 里的 ruby 语法 + solargraph。
(when (fboundp 'ruby-ts-mode)
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 '(ruby-ts-mode . ("solargraph" "stdio")))))

(provide 'unzeit-languages)
;;; unzeit-languages.el ends here

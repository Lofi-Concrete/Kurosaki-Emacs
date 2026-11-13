;;; init.el --- Unzeit: 模态编辑（meow） -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; 包管理 / use-package 引导 (不依赖 unzeit 常量)
(require 'init-package)

;; 现代化层开关 + 包清单（必须先于 core/editor 读）
(require 'unzeit-modern)

(use-package doom-themes
  :ensure t
  :demand t
  :config (doom-themes-org-config))

;;; ---- 主题：Tokyo Night（doom 自带 doom-tokyo-night）------------------
;; 2026-11-13 绕了一圈：doom-tokyo-night → Ember → City Lights → 换回这里。
;; Night 档：底 #1a1b26 / 正文 #c0caf5；关键字品红、函数蓝、字符串绿、注释灰蓝。
;; 跟壁纸无关，SPC c t 可临时换。
(load-theme 'doom-tokyo-night t)

(require 'core)
;; 主屏依赖主题面 + 基础层
(require 'init-dashboard)
(require 'editor)
(require 'completion)
(require 'init-eglot)
(require 'unzeit-popups)
(require 'unzeit-diagnostics)
(require 'init-debug)

(let ((dir (expand-file-name "langs" user-emacs-directory)))
  (when (file-directory-p dir)
    (dolist (f (directory-files dir t "\\`[^.#].*\\.el\\'"))
      (condition-case err
          (load f nil t)
        (error (message "Unzeit: 加载语言配置 %s 失败: %S"
                        (file-name-nondirectory f) err))))))

;; 内置 ts-mode 的补充语言（Lua / Ruby），走 Centaur 的“内置模式直接接线”。
(require 'unzeit-languages)

;; langs/ 都加载完了，把各语言登记的 apheleia formatter 合并进去。
(unzeit/apheleia-merge)

(require 'init-guix)

(require 'init-org)
(require 'unzeit-writer)
(require 'init-misc)
(require 'unzeit-editing)
;; 编译的第二条腿：Eat 终端视图 + 错误跳转（见 lisp/compile-rich.el）
(require 'compile-rich)
;; AI（DeepSeek）：gptel 对话/改写 + aidermacs（见 lisp/init-ai.el）
(require 'init-ai)
(require 'doctor)

(require 'init-local nil t)

(provide 'init)
;;; init.el ends here

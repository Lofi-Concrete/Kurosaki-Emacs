;;; init-debug.el --- 调试（dape / DAP） --- 2026-11 -*- lexical-binding: t; -*-

(require 'transient)

;; 左右 side window 占满整帧
(setq window-sides-vertical t)

(use-package dape
  :ensure t
  :defer t
  :commands (dape dape-breakpoint-toggle dape-continue dape-next
             dape-step-in dape-step-out dape-restart dape-quit
             dape-evaluate-expression dape-repl dape-switch-to-buffer)
  :bind ("<f5>" . dape)
  :custom
  ;; 调试侧栏放**右侧**：左边留给 dirvish 侧栏，两边夹着代码，视线不动。
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  (dape-inlay-hints-variable-name-max 25)
  ;; 断点边栏标记：实心圆点，比默认的字母 "B" 更像现代编辑器
  (dape-breakpoint-margin-string "●")
  :config
  ;; 启动调试前保存所有缓冲，解释型语言尤其需要
  (add-hook 'dape-start-hook (lambda () (save-some-buffers t t)))
  (transient-define-prefix dape-transient ()
    "Dape Menu"
    ["Base"
     ("c" "Continue"         dape-continue)
     ("n" "Next (Step over)" dape-next)
     ("i" "Step in"          dape-step-in)
     ("o" "Step out"         dape-step-out)
     ("p" "Pause"            dape-pause)
     ("r" "Restart"          dape-restart)
     ("q" "Quit"             dape-quit :transient nil)]
    ["Breakpoint"
     ("b" "Toggle breakpoint" dape-breakpoint-toggle)
     ("B" "Remove all"        dape-breakpoint-remove-all)
     ("l" "Log breakpoint"    dape-breakpoint-log)]
    ["Evaluate/Watch"
     ("e" "Evaluate"          dape-evaluate-expression)
     ("w" "Watch"             dape-watch-dwim)
     ("s" "Select stack"      dape-select-stack)]
    ["Others"
     ("i" "Info"              dape-info)])
  ;; 调试会话结束时把侧栏窗口也收掉（默认会留一个空侧栏）
  (add-hook 'dape-terminated-hook
            (lambda (&rest _)
              (when-let* ((win (seq-find (lambda (w)
                                           (with-current-buffer (window-buffer w)
                                             (derived-mode-p 'dape-info-mode
                                                             'dape-repl-mode)))
                                         (window-list))))
                (ignore-errors (delete-window win))))))

(provide 'init-debug)
;;; init-debug.el ends here

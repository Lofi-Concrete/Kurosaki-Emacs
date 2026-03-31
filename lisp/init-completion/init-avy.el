;;; Jump to things in Emacs tree-style
;;; Commentary:
;;; Code:

(keymap-global-unset "C-j")

(use-package avy
 :ensure t
 :defer t
 :config
  (defun avy-action-embark (pt)
	(unwind-protect
  (save-excursion
      (goto-char pt)
      (embark-act))
    (select-window
     (cdr (ring-ref avy-ring 0))))
	t)
  (setf (alist-get ?e avy-dispatch-alist) 'avy-action-embark)
 :bind
 (("C-j C-SPC" . avy-goto-char-timer)))

(provide 'init-avy)

;;; init-avy.el ends here

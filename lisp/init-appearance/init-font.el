;;; Font
;;; Commentary:
;;; code:

;; Check if the fot is installed
(defun font-exist-p (font)
  (if (and (display-graphic-p) (x-list-fonts font))
      t
      nil))

;; My font preference
(defvar font-candidates
    '("Maple Mono NF"
      "Sarasa Mono SC"
      "JetBrainsMono Nerd Font"))
(defvar font-size 14)

;; Set the font in GUI
(when (display-graphic-p)
  (let ((found-font nil))
    (dolist (font font-candidates)
      (when (and (not found-font) (font-exist-p font))
        (setq found-font font)))
    (when found-font
      (let ((font-spec (format "%s-%d" found-font font-size)))
        (set-frame-font font-spec nil t)
        (add-to-list 'default-frame-alist `(font . ,font-spec))
        (add-to-list 'initial-frame-alist `(font . ,font-spec))))))

;; Prevent duplicate loading
(provide 'init-font)

;;; init-font.el end here

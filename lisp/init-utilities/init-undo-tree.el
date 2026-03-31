;;; undo-tree
;;; Commentary:
;;; Code:

(use-package undo-tree
  :ensure t
  :defer t
  :init
  (global-undo-tree-mode)
  :custom
  (undo-tree-auto-save-history nil)
  :config
  ;; 等 hydra 加载完再绑定
  (with-eval-after-load 'hydra
    (bind-key "C-x C-h u" #'hydra-undo-tree/body)
    (defhydra hydra-undo-tree (:hint nil)
      "
_p_: undo  _n_: redo  _s_: save  _l_: load
"
      ("p" undo-tree-undo)
      ("n" undo-tree-redo)
      ("s" undo-tree-save-history)
      ("l" undo-tree-load-history)
      ("u" undo-tree-visualize "visualize" :color blue)
      ("q" nil "quit" :color blue))))

(provide 'init-undo-tree)

;;; init-undo-tree.el ends here

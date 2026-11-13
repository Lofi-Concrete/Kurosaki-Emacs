;;; odin.el --- Unzeit: Odin -*- lexical-binding: t; -*-

(unzeit/treesit-source 'odin "https://github.com/amaanq/tree-sitter-odin")

(unzeit/define-on-demand-mode odin-ts-mode odin-ts-mode "\\.odin\\'"
                              :vc ("https://github.com/Sampie159/odin-ts-mode"
                                   . "138bf6871b5e703ba5ad3f1c3464e2b4ce0fa846"))

(unzeit/eglot-server '(odin-ts-mode . ("ols")))

(unzeit/apheleia-formatter '(odinfmt . ("odinfmt" "-stdin")))
(unzeit/apheleia-mode '((odin-ts-mode . (odinfmt))))

(provide 'unzeit-lang-odin)
;;; odin.el ends here

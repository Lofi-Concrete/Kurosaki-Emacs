;;; node.el --- Unzeit 工具链: Node / fnm -*- lexical-binding: t; -*-

(unzeit/toolchain-register
 '(:front (".local/share/fnm/node-versions/*/installation/bin")))

(provide 'unzeit-toolchain-node)
;;; node.el ends here

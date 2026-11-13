;;; maven.el --- Unzeit 工具链: Maven / sdkman -*- lexical-binding: t; -*-

(unzeit/toolchain-register
 '(:front (".sdkman/candidates/maven/current/bin")))

(provide 'unzeit-toolchain-maven)
;;; maven.el ends here

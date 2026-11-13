;;; java.el --- Unzeit 工具链: Java / sdkman -*- lexical-binding: t; -*-

(unzeit/toolchain-register
 '(:tail (".sdkman/candidates/java/current/bin")))

;; sdkman 的 mvn 脚本要求 JAVA_HOME；GUI Emacs 不读 zshrc，只靠 PATH 里的 java 不够
;; （报「JAVA_HOME is not defined correctly」）。本文件在 early-init 加载，就在此设置。
(let ((home (expand-file-name "~/.sdkman/candidates/java/current")))
  (when (file-directory-p home)
    (setenv "JAVA_HOME" home)))

(provide 'unzeit-toolchain-java)
;;; java.el ends here

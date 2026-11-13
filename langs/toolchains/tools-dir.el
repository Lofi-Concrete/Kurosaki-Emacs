;;; tools-dir.el --- Unzeit 工具链: ~/tools（共享目录） -*- lexical-binding: t; -*-

(unzeit/toolchain-register
 '(:front ("tools/bin") :ld-library-path ("tools/lib")))

(provide 'unzeit-toolchain-tools-dir)
;;; tools-dir.el ends here

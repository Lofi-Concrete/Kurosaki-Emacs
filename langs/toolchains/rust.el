;;; rust.el --- Unzeit 工具链: Rust / rustup -*- lexical-binding: t; -*-

(unzeit/toolchain-register
 '(:front (".cargo/bin")))

(provide 'unzeit-toolchain-rust)
;;; rust.el ends here

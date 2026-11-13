;;; guix-profiles.el --- Unzeit 工具链: guix / 系统 profile（tail 兜底） -*- lexical-binding: t; -*-

(unzeit/toolchain-register
 '(:tail (".guix-home/profile/bin" ".guix-home/profile/sbin"
                 ".guix-profile/bin" ".guix-profile/sbin"
                 ".config/guix/current/bin" ".opencode/bin"
                 "/run/setuid-programs"
                 "/run/current-system/profile/bin"
                 "/run/current-system/profile/sbin")))

(provide 'unzeit-toolchain-guix-profiles)
;;; guix-profiles.el ends here

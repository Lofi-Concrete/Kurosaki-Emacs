;;; unzeit-modern.el --- Unzeit: 现代化层开关与包清单 -*- lexical-binding: t; -*-

;;; Commentary:
;; 按 Centaur ↔ Unzeit 差异清单引入的行为，全部挂在这里的开关上。
;; 默认值即“现代化版本”；想回退某一项，在 init-local.el 里改对应开关即可
;; （在 core/editor 加载之后才读的开关不受影响，见每项注释）。

;;; Code:

(defgroup unzeit/modern nil
  "Unzeit 现代化层：逐项可关。"
  :group 'emacs
  :prefix "unzeit/modern-")

(defcustom unzeit/modern-scroll t
  "非 nil 时用 ultra-scroll 的像素平滑滚动（Centaur 方案）。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-gc t
  "非 nil 时 gc-cons-percentage 保持 1.0（Centaur 方案），nil 回 0.1。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-posframe t
  "非 nil 时 which-key 用 childframe（无 GUI 时自动回退侧窗）。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-vertico-posframe t
  "非 nil 时 vertico 候选放 childframe（默认开，居中显示）。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-solaire t
  "非 nil 时用 solaire-mode 把非文件 buffer 变暗。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-dividers t
  "非 nil 时四边都画 1px 窗口分隔线。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-hl-line t
  "非 nil 时全局高亮当前行（dashboard/term/help 除外）。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-corfu t
  "非 nil 时采用 Centaur 的 corfu 节奏（2 字符 / 0.15s / 10 条）。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-consult-preview t
  "非 nil 时 consult 只在 line/grep 类命令上自动预览。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-inline-diagnostics nil
  "非 nil 时用 flyover 把 flymake 诊断画成内联覆盖层；默认 nil 保留原来的行尾 chip。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-eldoc-mouse t
  "非 nil 时 C-h . 用 childframe 显示 eldoc 文档（鼠标悬停）。"
  :type 'boolean
  :group 'unzeit/modern)

(defcustom unzeit/modern-line-number-fast-path t
  "非 nil 时统一 line-number 与 current-line 的 face，保住移动快路径。"
  :type 'boolean
  :group 'unzeit/modern)

(defconst unzeit/modern-packages
  '(ultra-scroll
    which-key-posframe
    vertico-posframe
    solaire-mode
    default-text-scale
    transient-posframe
    pinyinlib
    mwim
    hungry-delete
    iedit
    expand-region
    vundo
    goto-chg
    anzu
    beginend
    ace-pinyin
    pulsar
    goggles
    multiple-cursors
    page-break-lines
    nerd-icons-corfu
    eldoc-mouse
    flyover)
  "现代化层会按需安装的 ELPA 包（供 doctor/预装脚本用）。")

(provide 'unzeit-modern)
;;; unzeit-modern.el ends here

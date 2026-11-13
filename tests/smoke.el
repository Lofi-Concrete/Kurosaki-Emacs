;;; smoke.el --- Unzeit: 启动冒烟检查（batch） -*- lexical-binding: t; -*-

;;; Commentary:
;; 用仓库源码 + langs/ 拼影子树逐条断言（失败大多静默）；入口 smoke.sh，0 = 全过。

;;; Code:

(defvar unzeit/smoke-failures 0
  "本次冒烟失败的条数。")

(defun unzeit/smoke-check (label form)
  "检查 FORM 求值为真；LABEL 是给人看的一句话。"
  (condition-case err
      (if (eval form t)
          (princ (format "  ok   %s\n" label))
        (setq unzeit/smoke-failures (1+ unzeit/smoke-failures))
        (princ (format "  FAIL %s\n       form: %S\n" label form)))
    (error
     (setq unzeit/smoke-failures (1+ unzeit/smoke-failures))
     (princ (format "  FAIL %s\n       form: %S\n       err:  %S\n"
                    label form err)))))

(defun unzeit/smoke-mode-of (filename)
  "在一个临时缓冲里把 FILENAME 当文件名，返回 `set-auto-mode' 选中的主模式。"
  (with-temp-buffer
    (setq buffer-file-name (expand-file-name filename temporary-file-directory))
    (set-auto-mode)
    major-mode))

(princ "\nUnzeit 冒烟检查\n")

;;; ---- 1. 基本加载 ----------------------------------------------------
(princ "\n[加载]\n")
(unzeit/smoke-check "init 走完（`provide 'init'）" '(featurep 'init))
(unzeit/smoke-check "doctor 已加载（C-c D 的入口）" '(fboundp 'unzeit/doctor))
(unzeit/smoke-check "doom-tokyo-night 已是当前主题"
                    '(eq (car custom-enabled-themes) 'doom-tokyo-night))
(unzeit/smoke-check "meow 全局模式已开（SPC leader 恢复）"
                    '(and (featurep 'meow)
                          (bound-and-true-p meow-global-mode)))
(unzeit/smoke-check "corfu 已开" '(bound-and-true-p global-corfu-mode))
(unzeit/smoke-check "vertico 已开" '(bound-and-true-p vertico-mode))
(unzeit/smoke-check "eglot 自动连接挂在 prog-mode（web-mode 由 wrapper 过滤）"
                    '(memq #'unzeit/eglot-ensure-auto prog-mode-hook))
;; ★ Emacs 31 的默认值 'ask 会在模式体里弹 y-or-n，卡住 find-file 且 eglot 静默不连。
(unzeit/smoke-check "缺语法时不弹安装提示"
                    '(or (not (boundp 'treesit-auto-install-grammar))
                         (null treesit-auto-install-grammar)))
(unzeit/smoke-check "语法搜索路径含 profile 的 lib/tree-sitter"
                    '(seq-some (lambda (dir)
                                 (string-match-p "lib/tree-sitter/?\\'" dir))
                               treesit-extra-load-path))
;; shim 宏必须把 :vc 的 (URL . REV) 当数据传，裸插值会被当成函数调用。
(unzeit/smoke-check "shim 宏把 :vc 实参 quote 成数据"
                    '(let ((form (macroexpand-1
                                  '(unzeit/define-on-demand-mode
                                    smoke-pkg smoke-pkg "\\\\.smoke\\\\'"
                                    :vc ("https://u" . "rev")))))
                       (string-match-p "ensure-package 'smoke-pkg '(\""
                                       (format "%S" form))))

;;; ---- 2. 文件标签栏（VSC 风格）----
(princ "\n[标签栏]\n")
(unzeit/smoke-check "文件标签栏已开（VSC 风格）"
                    '(bound-and-true-p global-tab-line-mode))
(unzeit/smoke-check "标签名用文件名 + 图标"
                    '(and (fboundp 'unzeit/tab-line-name)
                          (eq tab-line-tab-name-function #'unzeit/tab-line-name)))
(unzeit/smoke-check "tab-line 图标保留 nerd-icons 的彩色 face"
                    '(and (advice-member-p #'unzeit/tab-line-name-format
                                           #'tab-line-tab-name-format-default)
                          (with-temp-buffer
                            (setq buffer-file-name "/tmp/unzeit-smoke.zig")
                            (let ((s (unzeit/tab-line-name-format
                                      #'tab-line-tab-name-format-default
                                      (current-buffer) nil)))
                              (and (stringp s)
                                   (string-match-p
                                    "nerd-icons"
                                    (format "%S" (get-text-property 0 'face s))))))))
(unzeit/smoke-check "dired / 侧栏不长 tab-line"
                    '(memq 'dired-mode tab-line-exclude-modes))

;;; ---- 3. 语言：扩展名 → 主模式 -------------------------------------
(princ "\n[语言模式]\n")
(unzeit/smoke-check ".c → c-ts-mode" '(eq (unzeit/smoke-mode-of "x.c") 'c-ts-mode))
(unzeit/smoke-check ".cpp → c++-ts-mode" '(eq (unzeit/smoke-mode-of "x.cpp") 'c++-ts-mode))
(unzeit/smoke-check ".h 走 c-or-c++-ts-mode 的分流"
                    '(memq (unzeit/smoke-mode-of "x.h") '(c-ts-mode c++-ts-mode)))
(unzeit/smoke-check ".rs → rust-ts-mode" '(eq (unzeit/smoke-mode-of "x.rs") 'rust-ts-mode))
(unzeit/smoke-check ".go → go-ts-mode" '(eq (unzeit/smoke-mode-of "x.go") 'go-ts-mode))
(unzeit/smoke-check ".py → python-ts-mode" '(eq (unzeit/smoke-mode-of "x.py") 'python-ts-mode))
(unzeit/smoke-check ".js → js-ts-mode" '(eq (unzeit/smoke-mode-of "x.js") 'js-ts-mode))
(unzeit/smoke-check ".ts → typescript-ts-mode"
                    '(eq (unzeit/smoke-mode-of "x.ts") 'typescript-ts-mode))
(unzeit/smoke-check ".tsx → tsx-ts-mode" '(eq (unzeit/smoke-mode-of "x.tsx") 'tsx-ts-mode))
(unzeit/smoke-check ".zig → zig-mode" '(eq (unzeit/smoke-mode-of "x.zig") 'zig-mode))
(unzeit/smoke-check ".jsp → jsp-mode（web-mode 的 JSP 引擎）"
                    '(eq (unzeit/smoke-mode-of "x.jsp") 'jsp-mode))
(unzeit/smoke-check ".erb 仍是普通 web-mode"
                    '(eq (unzeit/smoke-mode-of "x.erb") 'web-mode))
(unzeit/smoke-check "js2/simpc 已退役"
                    '(and (not (memq 'js2-mode (mapcar #'cdr auto-mode-alist)))
                          (not (fboundp 'simpc-mode))))

;;; ---- 4. LSP 登记 ---------------------------------------------------
(princ "\n[LSP]\n")
(unzeit/smoke-check "clangd 登记到 c-ts-mode"
                    '(progn
                       (require 'eglot)
                       (seq-some (lambda (entry)
                                   (and (memq 'c-ts-mode (ensure-list (car entry)))
                                        't))
                                 eglot-server-programs)))
(unzeit/smoke-check "clangd 在 exec-path 上" '(executable-find "clangd"))
(unzeit/smoke-check "JSP/HTML 登记到 vscode-html-language-server"
                    '(progn
                       (require 'eglot)
                       (seq-some
                        (lambda (entry)
                          (and (seq-some (lambda (m)
                                           (eq (if (consp m) (car m) m) 'jsp-mode))
                                         (ensure-list (car entry)))
                               (equal (nth 1 entry) "vscode-html-language-server")))
                        eglot-server-programs)))
(unzeit/smoke-check "Maven 项目（裸 pom.xml）能被 project.el 识别"
                    '(let ((dir (make-temp-file "unzeit-maven-" t)))
                       (unwind-protect
                           (progn
                             (with-temp-file (expand-file-name "pom.xml" dir)
                               (insert "<project/>"))
                             (equal (project-root (project-current nil dir))
                                    (file-name-as-directory dir)))
                         (delete-directory dir t))))
(unzeit/smoke-check "C-c J 是 Maven/Tomcat 菜单"
                    '(and (eq (lookup-key unzeit/custom-map (kbd "J"))
                              'unzeit/java-menu)
                          (commandp 'unzeit/servlet-menu-open)))
(unzeit/smoke-check "C-c J n 能新建 Maven Web 项目"
                    '(commandp 'unzeit/servlet-new))
(unzeit/smoke-check "JAVA_HOME 已设置（sdkman 的 mvn 需要）"
                    '(and (getenv "JAVA_HOME")
                          (file-directory-p (getenv "JAVA_HOME"))))

;;; ---- 4c. emacs-guix：入口 / 开发模式 / 菜单对齐 --------------------
(princ "\n[Guix]\n")
(unzeit/smoke-check "which-key 精确按像素适配（C-c 末行不再被裁）"
                    '(null which-key-allow-imprecise-window-fit))
(unzeit/smoke-check "C-c g 是 Guix 菜单，且进了 C-c 中文说明表"
                    '(and (eq (lookup-key unzeit/custom-map (kbd "g")) 'guix)
                          (equal (cdr (assoc "g" unzeit/custom-key-descriptions))
                                 "Guix 包 / 世代 / 服务")))
(unzeit/smoke-check "SPC c g 也绑到 guix"
                    '(eq (lookup-key unzeit/config-map (kbd "g")) 'guix))
(unzeit/smoke-check "~/guix 的 .scm 自动开 guix-devel-mode"
                    '(with-temp-buffer
                       (setq buffer-file-name
                             (expand-file-name "~/guix/home/home.scm"))
                       (insert "(define-module (home))\n")
                       (scheme-mode)
                       (bound-and-true-p guix-devel-mode)))
(unzeit/smoke-check "C-c J 菜单两栏像素对齐（所有行同一列起点）"
                    '(progn
                       (require 'transient)
                       (with-temp-buffer
                         (let ((transient--prefix
                                (transient--init-prefix 'unzeit/servlet-menu)))
                           (setq transient--layout
                                 (transient--init-suffixes 'unzeit/servlet-menu))
                           (transient--insert-groups))
                         (let (rows)
                           (goto-char (point-min))
                           (while (not (eobp))
                             (let (row)
                               (while (< (point) (line-end-position))
                                 (let ((d (get-text-property (point) 'display)))
                                   (when (and (consp d) (eq (car d) 'space)
                                              (plist-get (cdr d) :align-to))
                                     (push (plist-get (cdr d) :align-to) row)))
                                 (forward-char 1))
                               (push (nreverse row) rows))
                             (forward-line 1))
                           (setq rows (nreverse rows))
                           (and (= (length rows) 7)
                                (seq-every-p (lambda (r) (= (length r) 1)) rows)
                                (seq-every-p (lambda (r) (equal r (car rows))) rows)
                                (eq (oref (get 'unzeit/servlet-menu
                                               'transient--prefix)
                                          variable-pitch)
                                    t))))))
;;; ---- 7. 文件侧栏（dirvish-side）-----------------------------------
(princ "\n[文件侧栏]\n")
(unzeit/smoke-check "dirvish 已加载" '(featurep 'dirvish))
(unzeit/smoke-check "C-c t 绑到侧栏开关"
                    '(eq (lookup-key unzeit/custom-map (kbd "t"))
                         'unzeit/file-tree-toggle))
(unzeit/smoke-check "dirvish-side 扩展 require 得到（不是 void-function）"
                    '(commandp 'dirvish-side))
(unzeit/smoke-check "侧栏宽度 / 隐藏详情 / 只留便宜属性"
                    '(and (<= 20 dirvish-side-width 32)
                          dirvish-hide-details
                          (memq 'nerd-icons dirvish-side-attributes)
                          ;; vc-state 逐文件跑 `vc-state'，大仓库里是卡顿源
                          (not (memq 'vc-state dirvish-side-attributes))))
;; ★ `C-c t` 是开关（再按收起），`C-c T` 才是跳进侧栏；体检报告同理。
(unzeit/smoke-check "SPC leader 恢复（文件树 / eshell / 退出）"
                    '(and (keymapp unzeit/leader-map)
                          (eq (lookup-key unzeit/file-map (kbd "t"))
                              'unzeit/file-tree-toggle)
                          (eq (lookup-key unzeit/leader-map (kbd "t"))
                              'unzeit/eshell-toggle)
                          (eq (lookup-key unzeit/leader-map (kbd "q"))
                              'save-buffers-kill-terminal)))
(unzeit/smoke-check "正文 13pt / 界面 12pt（对齐 Ghostty font-size 13）"
                    '(and (= unzeit/body-font-height 130)
                          (= unzeit/ui-font-height 120)))
(unzeit/smoke-check "侧栏宽度按内容自适应（20–32）"
                    '(and (fboundp 'unzeit/dirvish-side-fit-width)
                          (<= 20 (unzeit/dirvish-side-fit-width temporary-file-directory) 32)))
(unzeit/smoke-check "C-c t 是开关、C-c T 是跳进去"
                    '(and (eq (lookup-key unzeit/custom-map (kbd "t"))
                              'unzeit/file-tree-toggle)
                          (eq (lookup-key unzeit/custom-map (kbd "T"))
                              'unzeit/file-tree-focus)))
(unzeit/smoke-check "侧栏一键开 / 一键关"
                    '(progn
                       (unzeit/file-tree-toggle)
                       (let ((opened (and (unzeit/file-tree-window) t)))
                         (unzeit/file-tree-toggle)
                         (and opened (null (unzeit/file-tree-window))))))
(unzeit/smoke-check "C-c h 主屏也是开关（再按回上一个缓冲）"
                    '(progn
                       (switch-to-buffer "*scratch*")
                       (unzeit/dashboard-toggle)
                       (let ((on-dash (equal (buffer-name) "*dashboard*")))
                         (unzeit/dashboard-toggle)
                         (and on-dash (equal (buffer-name) "*scratch*")))))
(unzeit/smoke-check "体检报告一键开 / 一键关"
                    '(progn
                       (unzeit/doctor-toggle)
                       (let ((opened (and (get-buffer-window "*Unzeit 体检*") t)))
                         (unzeit/doctor-toggle)
                         (and opened (null (get-buffer-window "*Unzeit 体检*"))))))
(unzeit/smoke-check "C-c d 接上 dirvish 全窗口开关 / fd / 书签"
                    '(and (eq (lookup-key unzeit/custom-map (kbd "d"))
                              'unzeit/dirvish-toggle)
                          (commandp 'dirvish-fd)
                          (commandp 'dirvish-quick-access)))
;; ★ 回归守卫：侧栏要藏权限/时间/大小，普通 dired 保留长格式；dirvish 的
;; `dirvish-hide-details' 管不到 side 会话，靠 dired-mode-hook + advice 补。
(unzeit/smoke-check "侧栏是 dired、藏细节、长名不硬截断"
                    '(progn
                       (dirvish-side)
                       (prog1 (and (eq major-mode 'dired-mode)
                                   (bound-and-true-p dired-hide-details-mode)
                                   (null truncate-lines))  ; 长名换行，不截断
                         (dirvish-side))))         ; 再按一次收起
(unzeit/smoke-check "普通窗口里的 dired 不会被藏细节（长格式保留）"
                    '(progn
                       ;; 上一条检查可能把选中的窗口留在了侧栏上，先换回普通窗口
                       (when-let* ((w (seq-find
                                       (lambda (w)
                                         (null (window-parameter w 'window-side)))
                                       (window-list))))
                         (select-window w))
                       (with-temp-buffer
                         (dired-mode temporary-file-directory)
                         (and (null (window-parameter (selected-window)
                                                      'window-side))
                              (not (bound-and-true-p dired-hide-details-mode))))))
;; 该钩子是 run-hook-with-args-until-success，返回非 nil 会跳过 dirvish 会话初始化。
(unzeit/smoke-check "dirvish-find-entry-hook 里没有会短路的钩子"
                    '(null dirvish-find-entry-hook))
;; ★ 回归：kdl 的 comment-region 本身没问题，坑在调用侧的选区判断。
(unzeit/smoke-check "kdl 三行选区一次注释完整（原生 comment-dwim）"
                    '(progn
                       (require 'kdl-mode nil t)
                       (with-temp-buffer
                         (kdl-mode)
                         (insert "node {\n  a 1\n  b 2\n}\n")
                         (goto-char (point-min))
                         (forward-line 1)
                         (let ((beg (point)))
                           (forward-line 2)
                           ;; ★ mark 放在 beg、point 在末尾；反过来是空选区，注释当然没效果。
                           (set-mark beg)
                           (activate-mark)
                           (comment-dwim nil)
                           (and (save-excursion
                                  (goto-char (point-min))
                                  (search-forward "// a 1" nil t))
                                (save-excursion
                                  (goto-char (point-min))
                                  (search-forward "// b 2" nil t)))))))
;; 调试 / LSP 加速 / dev 工作流
(unzeit/smoke-check "dape 可用且 C-c b 是调试菜单"
                    '(and (fboundp 'dape)
                          (fboundp 'dape-breakpoint-toggle)
                          (eq (lookup-key unzeit/custom-map (kbd "b"))
                              'unzeit/debug-menu)))
(unzeit/smoke-check "F5 启动调试" '(eq (lookup-key global-map (kbd "<f5>")) 'dape))
(unzeit/smoke-check "C-c R 跑测试" '(eq (lookup-key unzeit/custom-map (kbd "R"))
                                          'unzeit/run-tests))
(unzeit/smoke-check "C-c S 是 eat（真终端）" '(eq (lookup-key unzeit/custom-map (kbd "S"))
                                                  'eat))
(unzeit/smoke-check "eglot 会自动关服务器" '(eq eglot-autoshutdown t))
(unzeit/smoke-check "eglot-booster 已加载（Guix 的 elisp + 二进制）"
                    '(and (featurep 'eglot-booster)
                          (bound-and-true-p eglot-booster-mode)))

(unzeit/smoke-check "envrc / magit-delta / colorful / eat 都接上了"
                    '(and (fboundp 'envrc-global-mode)
                          (fboundp 'magit-delta-mode)
                          (fboundp 'colorful-mode)
                          (fboundp 'eat)))

;; 颜色预览只留 colorful 一套（底色块 + 2px 四边内框、无 ● 前缀）
(unzeit/smoke-check "颜色预览只留 colorful 一套（css-mode 自带满底色关掉）"
                    '(null css-fontify-colors))
(unzeit/smoke-check "colorful 色块用底色 + 2px 内框、不用 ● 前缀"
                    '(progn
                       (require 'colorful-mode)
                       (and (null colorful-use-prefix)
                            (equal (plist-get (face-attribute 'colorful-base :box)
                                              :line-width)
                                   -2))))
;; logo 下那行是随机一条 galgame 日语台词，不是标题
(unzeit/smoke-check "dashboard 已接上（自带动画 logo + 台词取代标题、无导航行）"
                    '(and (fboundp 'dashboard-open)
                          (boundp 'dashboard-items)
                          (null dashboard-banner-logo-title)
                          (fboundp 'unzeit/dashboard-insert-quote)
                          (memq 'unzeit/dashboard-insert-quote
                                dashboard-startupify-list)
                          (not (memq 'dashboard-insert-footer
                                     dashboard-startupify-list))
                          ;; 导航按钮行已去掉
                          (not (memq 'dashboard-insert-navigator
                                     dashboard-startupify-list))
                          (stringp (unzeit/galgame-quotes-random))
                          ;; logo 用随配置部署的 images/emacs-logo.png
                          (and (file-exists-p unzeit/dashboard-logo-file)
                               (string= dashboard-startup-banner
                                        unzeit/dashboard-logo-file))
                          (equal (cdr (assq 'recents dashboard-items)) 3)))
(unzeit/smoke-check "无文件启动 → 主屏"
                    '(let ((command-line-args '("emacs")))
                       (let ((name (buffer-name (unzeit/initial-buffer))))
                         (or (equal name "*dashboard*")
                             (error "拿到的是 %S" name)))))
(unzeit/smoke-check "带文件启动 → 文件缓冲而不是主屏"
                    '(let* ((command-line-args '("emacs" "/etc/hostname"))
                            (b (unzeit/initial-buffer)))
                       (not (eq (buffer-name b) "*dashboard*"))))
(unzeit/smoke-check "-l 的取值不被当成启动文件"
                    '(let ((command-line-args '("emacs" "-l" "/etc/hostname")))
                       (null (unzeit/startup-file))))
(unzeit/smoke-check "C-c A 前缀接上 AI map"
                    '(eq (lookup-key unzeit/custom-map "A") unzeit/ai-map))
(unzeit/smoke-check "AI 命令就绪"
                    '(and (fboundp 'unzeit/ai-chat) (fboundp 'unzeit/ai-rewrite)
                          (fboundp 'unzeit/ai-explain) (fboundp 'unzeit/ai-translate)
                          (fboundp 'unzeit/ai-aider)))
(unzeit/smoke-check "没有 key 时 ai-key 安静返回 nil"
                    '(null (unzeit/ai-key)))
(unzeit/smoke-check "treemacs 已退役（包与命令都不在）"
                    '(and (not (featurep 'treemacs))
                          (not (fboundp 'treemacs))))

;;; ---- 4b. 现代 UI（诊断 / 补全图标 / 面包屑 / 缩进线）----------------
(princ "\n[现代 UI]\n")
;; 诊断：无波浪线，改行尾摘要 + fringe + 浮层。'fancy 每次重绘都重排 overlay，
;; 用户报「卡」后降到 'short（只显示最严重那条）。
(unzeit/smoke-check "诊断用行尾摘要（short），不是波浪线"
                    '(eq flymake-show-diagnostics-at-end-of-line 'short))
(unzeit/smoke-check "flymake-error 不再画下划线"
                    '(null (face-attribute 'flymake-error :underline)))
;; 主题是 doom-tokyo-night（语法面全冷色），诊断因此用暖色 + 同色相暗底 + 边框；
;; 不用斜体（本主题斜体 = 注释）。
(unzeit/smoke-check "行尾诊断是暖色色块（底色 + 边框 + 正体，不撞主题 warning）"
                    '(let ((f 'flymake-warning-echo-at-eol))
                       (and (stringp (face-attribute f :background))
                            (consp (face-attribute f :box))
                            (eq 'normal (face-attribute f :slant))
                            (equal (face-attribute f :foreground)
                                   (nth 1 (assq f unzeit/flymake-eol-chips)))
                            (not (equal (face-attribute f :foreground)
                                        (face-attribute 'warning :foreground))))))
;; flymake-popon 每次弹都建 GTK 子框架：Wayland 实测 show≈82ms、hide≈20ms，
;; 光标停在诊断行上就反复建/毁 surface（卡顿源）；行尾色块已够，整套拆除。
(unzeit/smoke-check "flymake-popon 已拆除（不再为诊断建子框架）"
                    '(and (not (memq 'flymake-popon-mode flymake-mode-hook))
                          (not (bound-and-true-p flymake-popon-mode))))
(unzeit/smoke-check "eglot 接管时开 inlay hints"
                    '(memq #'eglot-inlay-hints-mode eglot-managed-mode-hook))
;; Centaur 方案：宽度从 1 开始自适应增长（`display-line-numbers-width-start`），
;; 不再固定 4 位；断言默认值已改为 1 + width-start 打开。
(unzeit/smoke-check "行号栏宽度自适应（width-start，不再固定 4 位）"
                    '(and (= (default-value 'display-line-numbers-width) 1)
                          display-line-numbers-width-start))
;; 行号常显，代价是整窗重绘：必须用绝对行号（relative 下 `try_window_id' 直接
;; GIVE_UP）并让两个 line-number face 显式一致；实测 7.4~8.4 → 1.9ms/次。
(unzeit/smoke-check "prog/文本缓冲默认显示行号"
                    '(and unzeit/line-numbers-in-prog
                          (eq (default-value 'unzeit/line-numbers-in-prog) t)))
(unzeit/smoke-check "行号用绝对号（保住 try_window_id 快路径）"
                    '(eq display-line-numbers-type t))
;; 照 Doom 的 Runtime optimizations 抄的一组，对重绘有直接影响，钉住。
;; ★ 实测 `'left-to-right` 在 Emacs 31.1 仍跑 UAX#9，比 nil 慢一倍（20.0→10.2ms/行），别再学 Doom。
(unzeit/smoke-check "bidi 关掉（nil 才真的不跑 UAX#9）+ 关 BPA"
                    '(and (null (default-value 'bidi-display-reordering))
                          bidi-inhibit-bpa))
(unzeit/smoke-check "Doom 运行时优化：字体缓存 / 输入时 fontify / 滚动近似"
                    '(and inhibit-compacting-font-caches
                          redisplay-skip-fontification-on-input
                          fast-but-imprecise-scrolling))
(unzeit/smoke-check "Doom 运行时优化：PGTK 事件超时降到 1ms"
                    '(or (not (boundp 'pgtk-wait-for-event-timeout))
                         (= pgtk-wait-for-event-timeout 0.001)))
(unzeit/smoke-check "line-number-current-line 与 line-number 显式定义一致"
                    '(or (not (fboundp 'internal-lisp-face-equal-p))
                         (internal-lisp-face-equal-p
                          'line-number 'line-number-current-line nil)))
;; 补全图标 / 面包屑 / 缩进线。kind-icon 从未生效且与 nerd-icons-corfu 重复，
;; 已卸载；这里断言只剩一个 formatter。
(unzeit/smoke-check "corfu 图标只剩一个 formatter（没有双份）"
                    '(<= (length corfu-margin-formatters) 1))
;; 候选旁出文档（corfu-popupinfo）+ minibuffer 候选带图标
(unzeit/smoke-check "corfu-popupinfo 挂在 corfu-mode 上"
                    '(and (fboundp 'corfu-popupinfo-mode)
                          (memq 'corfu-popupinfo-mode corfu-mode-hook)))
(unzeit/smoke-check "nerd-icons-completion 已开（minibuffer 图标）"
                    '(progn (require 'nerd-icons-completion nil t)
                            (bound-and-true-p nerd-icons-completion-mode)))
;; 自定义光标已移除，只保留 doom 主题的原生 cursor face
(unzeit/smoke-check "自定义光标已移除"
                    '(and (not (boundp 'unzeit/cursor-mode))
                          (not (fboundp 'unzeit/cursor-toggle))))
(unzeit/smoke-check "当前行高亮已打开（Centaur）"
                    '(bound-and-true-p global-hl-line-mode))
(unzeit/smoke-check "C-c H 是当前行高亮开关"
                    '(and (eq (lookup-key unzeit/custom-map (kbd "H"))
                              'unzeit/toggle-hl-line)
                          (equal (cdr (assoc "H" unzeit/custom-key-descriptions))
                                 "当前行高亮开关")))
(unzeit/smoke-check "breadcrumb 已退役（没有 proj-mode 钩子）"
                    '(not (memq #'breadcrumb-local-mode prog-mode-hook)))
(unzeit/smoke-check "indent-bars 不挂每命令高亮（post-command-hook 里没有它）"
                    '(and (require 'indent-bars nil t)
                          (null indent-bars-highlight-current-depth)))
(unzeit/smoke-check "缩进线换成 indent-bars" '(and (require 'indent-bars nil t)
                                                   (memq #'indent-bars-mode prog-mode-hook)
                                                   (not (fboundp 'highlight-indent-guides-mode))))

;;; ---- 4d. 现代化层（Centaur 方案）----------------------------------
(princ "\n[现代层]\n")
(unzeit/smoke-check "现代化开关默认都开"
                    '(and unzeit/modern-scroll unzeit/modern-gc
                          unzeit/modern-posframe unzeit/modern-solaire
                          unzeit/modern-dividers unzeit/modern-hl-line
                          unzeit/modern-corfu unzeit/modern-consult-preview
                          unzeit/modern-eldoc-mouse unzeit/modern-vertico-posframe
                          unzeit/modern-line-number-fast-path))
(unzeit/smoke-check "现代化包全部已安装"
                    '(seq-every-p #'package-installed-p unzeit/modern-packages))
(unzeit/smoke-check "ultra-scroll 已装，滚动参数 3/0"
                    '(and (package-installed-p 'ultra-scroll)
                          (= scroll-conservatively 3)
                          (= scroll-margin 0)))
(unzeit/smoke-check "GC 百分比 1.0（Centaur）" '(= gc-cons-percentage 1.0))
(unzeit/smoke-check "编辑默认：逻辑行 / EOL / C-k / 重复弹栈"
                    '(and (null line-move-visual) track-eol
                          kill-whole-line set-mark-command-repeat-pop))
(unzeit/smoke-check "uniquify / trash / 中文句末"
                    '(and (eq uniquify-buffer-name-style 'post-forward-angle-brackets)
                          delete-by-moving-to-trash
                          (string-match-p "。" sentence-end)))
(unzeit/smoke-check "solaire 已开" '(bound-and-true-p solaire-global-mode))
(unzeit/smoke-check "which-key-posframe 已安装（GUI 下启用）"
                    '(package-installed-p 'which-key-posframe))
(unzeit/smoke-check "vertico-posframe 已装且默认居中"
                    '(and (package-installed-p 'vertico-posframe)
                          (require 'posframe nil t)
                          (fboundp 'posframe-poshandler-frame-center)
                          (boundp 'unzeit/vertico-posframe-center)
                          unzeit/vertico-posframe-center))
(unzeit/smoke-check "行号改成 Centaur 方案：global 关、prog 开、text 关、width-start"
                    '(and (not (bound-and-true-p global-display-line-numbers-mode))
                          display-line-numbers-width-start
                          (memq #'unzeit/line-numbers-on prog-mode-hook)
                          (with-temp-buffer (prog-mode)
                                            (bound-and-true-p display-line-numbers-mode))
                          (with-temp-buffer (text-mode)
                                            (not (bound-and-true-p display-line-numbers-mode)))))
(unzeit/smoke-check "corfu 节奏 2/0.15/10"
                    '(and (= corfu-auto-prefix 2)
                          (= corfu-auto-delay 0.15)
                          (= corfu-count 10)))
(unzeit/smoke-check "consult 默认不预览（逐命令开）"
                    '(null consult-preview-key))
(unzeit/smoke-check "flymake 0.15s" '(= flymake-no-changes-timeout 0.15))
(unzeit/smoke-check "eldoc-mouse 在 prog 缓冲启用"
                    '(with-temp-buffer
                       (prog-mode)
                       (bound-and-true-p eldoc-mouse-mode)))
(unzeit/smoke-check "光标停留文档已接线（eldoc-mouse posframe）"
                    '(and (fboundp 'unzeit/eldoc-dwell-show)
                          (memq 'unzeit/eldoc-dwell-setup prog-mode-hook)
                          (boundp 'unzeit/eldoc-dwell-delay)))
(unzeit/smoke-check "which-key posframe 的 poshandler 已定义"
                    '(fboundp 'posframe-poshandler-frame-center-near-bottom))
(unzeit/smoke-check "黄色提示默认用原来的行尾 chip（不启用 flyover）"
                    '(not unzeit/modern-inline-diagnostics))
(unzeit/smoke-check "warning/error 都显示行尾 chip（默认 t）"
                    'unzeit/diagnostics-show-warnings)
;;; ---- 5. tree-sitter 语法（B1：改由 Guix profile 提供）--------------
(princ "\n[tree-sitter 语法]\n")
(unzeit/smoke-check "treesit 可用" '(treesit-available-p))
(unzeit/smoke-check "treesit-enabled-modes 已启用（像 Centaur，但用 31.1 的正确写法）"
                    '(and (boundp 'treesit-enabled-modes)
                          (listp treesit-enabled-modes)
                          (> (length treesit-enabled-modes) 0)
                          (memq 'go-ts-mode treesit-enabled-modes)
                          (not (memq 'rust-ts-mode treesit-enabled-modes))
                          (not (memq 'markdown-ts-mode treesit-enabled-modes))))
(unzeit/smoke-check "Lua/Ruby 走内置 ts-mode + eglot 接线"
                    '(progn
                       (require 'eglot)
                       (and (fboundp 'lua-ts-mode)
                            (fboundp 'ruby-ts-mode)
                            (assq 'lua-ts-mode eglot-server-programs)
                            (assq 'ruby-ts-mode eglot-server-programs))))
(let ((missing (seq-remove #'treesit-language-available-p
                           unzeit/treesit-languages)))
  (if missing
      (progn
        (setq unzeit/smoke-failures (1+ unzeit/smoke-failures))
        (princ (format "  FAIL 缺语法：%S\n       修法：guix home reconfigure（B1 起语法来自 profile），或 M-x treesit-install-language-grammar\n"
                       missing)))
    (princ "  ok   登记过的语法全部可用\n")))
;; c3 是唯一仍手工编译的一份（Guix 没有包），单独提示，不算失败
(unless (treesit-language-available-p 'c3)
  (princ "  note c3 语法不在（Guix 无包；按需 treesit-install-language-grammar）\n"))

;;; ---- 6. 体检本身能跑 ----------------------------------------------
(princ "\n[doctor]\n")
(unzeit/smoke-check "`unzeit/doctor' 跑得动且产出报告"
                    '(progn
                       (unzeit/doctor)
                       (with-current-buffer "*Unzeit 体检*"
                         (> (buffer-size) 0))))

;;; ---- 汇总 ----------------------------------------------------------
(princ (format "\n%s（失败 %d 条）\n"
               (if (> unzeit/smoke-failures 0) "有失败" "全过")
               unzeit/smoke-failures))
(kill-emacs (if (> unzeit/smoke-failures 0) 1 0))

;;; smoke.el ends here

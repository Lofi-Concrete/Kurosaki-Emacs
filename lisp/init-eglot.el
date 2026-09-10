;;; init-eglot.el --- Unzeit: eglot、tree-sitter、apheleia、语言 -*- lexical-binding: t; -*-

;;; Commentary:
;; “IDE”层：tree-sitter 语法模式 + 语言包（zig/haskell/c3/odin）+ LSP
;;（eglot）+ apheleia 格式化语言服务器是外部二进制（见 “本机安装的 LSP
;; 服务器” 一节及 dotfiles/AGENTS.md）诊断由 eglot 内置 flymake 给出，
;; 显示为波浪线 / 当下行 eldoc

;;; Code:

;;; ---- Tree-sitter --------------------------------------------------

;; Emacs 31.0.91 预测试：treesit.el（含 `treesit-ready-p' 与
;; `treesit-language-at'）并不会被内置的 -ts 模式加载；没有这个 require，
;; 下面每个语言模式（haskell/zig/odin/c3）都会以 void-function 失败
(require 'treesit)

;; 语法在首次使用时安装（需要 C 编译器与 git，本 Guix 环境都有）
(setq treesit-language-source-alist
      '((c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
        (java "https://github.com/tree-sitter/tree-sitter-java")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (rust "https://github.com/tree-sitter/tree-sitter-rust")
        (zig "https://github.com/tree-sitter-grammars/tree-sitter-zig")
        (css "https://github.com/tree-sitter/tree-sitter-css")
        (html "https://github.com/tree-sitter/tree-sitter-html")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "tsx/src")
        (toml "https://github.com/tree-sitter/tree-sitter-toml")
        (yaml "https://github.com/tree-sitter-grammars/tree-sitter-yaml")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (ruby "https://github.com/tree-sitter/tree-sitter-ruby")
        (go "https://github.com/tree-sitter/tree-sitter-go")
        (haskell "https://github.com/tree-sitter/tree-sitter-haskell")
        (c3 "https://github.com/c3lang/tree-sitter-c3")
        (odin "https://github.com/amaanq/tree-sitter-odin")))

(setq treesit-font-lock-level 4)

(defun unzeit/treesit-ensure-grammar (&rest _)
  "缺少时安装当前语言的 tree-sitter 语法

绝不弹出提示（模式体内的 y-or-n-p 会阻塞 find-file——在 daemon/帧里直到
应答前表现为卡死，并因 `run-mode-hooks' 永不运行而悄然跳过 eglot 的 hook）
语法源固定在 `treesit-language-source-alist'；需要时用
`treesit-install-language-grammar' 手动安装"
  (when-let* ((lang (treesit-language-at (point)))
              (source (assoc lang treesit-language-source-alist)))
    (unless (treesit-language-available-p lang)
      (message "Unzeit：缺少 %s 的 tree-sitter 语法" lang))))

(advice-add 'treesit-major-mode-setup :after #'unzeit/treesit-ensure-grammar)

;; 优先使用内置模式的 -ts-mode 变体
(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (java-mode . java-ts-mode)
        (python-mode . python-ts-mode)
        (rust-mode . rust-ts-mode)
        (css-mode . css-ts-mode)
        (html-mode . html-ts-mode)
        (js-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (yaml-mode . yaml-ts-mode)
        (toml-mode . toml-ts-mode)
        (ruby-mode . ruby-ts-mode)
        (go-mode . go-ts-mode)
        (json-mode . json-ts-mode)))

;; Emacs 30 这些模式没有 auto-mode-alist 条目；加上它们以实际使用 -ts 模式
(add-to-list 'auto-mode-alist '("\\.toml\\'" . toml-ts-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode))
(add-to-list 'auto-mode-alist '("\\.rb\\'" . ruby-ts-mode))
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))

;; ---- 语言模式（第三方包）----------------------------------------
;; 用各语言官方包替换原先手写的 define-derived-mode，包自带与当前
;; tree-sitter 语法匹配的 font-lock 与缩进规则
;; 注意：官方 zig-mode / haskell-mode 包仅提供经典主模式（zig-mode /
;; haskell-mode，均派生自 prog-mode），不含 -ts-mode 变体，故这里映射到
;; 经典模式而非 ts 模式；语法高亮由各包自身的 font-lock 提供。
;;
;; 这几个包全部按需加载（思路来自 minemacs 的 +make-first-file-hook! 与
;; doom 的 doom-first-*-hook）：启动时只在 auto-mode-alist 里挂一个本配置
;; 的 shim，第一次打开 .zig/.hs/.c3/.odin/.c 文件时才安装 + require 真正的
;; 包——启动路径上连 use-package 的 :ensure 都不用跑。
;;
;; NOTE: 不能在 find-file-hook 里做这件事：文件的主模式是在 find-file-hook
;; 之前就由 set-auto-mode 选定的，那时包尚未加载，模式函数会 void-function。
;; 所以入口必须挂在 auto-mode-alist 上（这正是"首次打开文件"的触发点）

(defmacro unzeit/define-on-demand-mode (mode package regexp &rest args)
  "定义按需加载的语言主模式入口。
MODE 是包提供的主模式函数名，PACKAGE 是包名（同时用作 feature 名），
REGEXP 是匹配文件名的正则，可以是字符串或字符串列表。
ARGS 是关键字参数：
  :vc URL       该包不在 ELPA 上，需要时用 `package-vc-install' 从该 git 源安装
  :also (PKG…)  需要时一并安装并加载的伴随包（如 js2 栈的 js2-refactor、
                xref-js2，以及 js2-refactor 缺失的依赖 multiple-cursors）"
  (declare (indent 2))
  (let* ((entry (intern (format "unzeit/%s" mode)))
         ;; 正则允许写成字符串，或（可能带 quote 的）字符串列表
         (raw (if (and (consp regexp) (eq (car regexp) 'quote))
                  (cadr regexp)
                regexp))
         (regexps (if (listp raw) raw (list raw)))
         (vc-url (plist-get args :vc))
         (also (plist-get args :also)))
    `(progn
       (defun ,entry ()
         ,(format "按需安装并加载 %s，然后进入 %s。" package mode)
         (interactive)
         (condition-case err
             (progn
               (unzeit/ensure-package ',package ,vc-url)
               ,@(mapcar (lambda (pkg) `(unzeit/ensure-package ',pkg)) also)
               (require ',package nil t)
               ,@(mapcar (lambda (pkg) `(require ',pkg nil t)) also)
               (if (fboundp ',mode)
                   (progn
                     ;; 加载成功后把这些 alist 条目换回真正的模式函数：
                     ;; 后续同类文件直接走它，不再经过本 shim
                     (dolist (re ',regexps)
                       (when-let* ((cell (assoc re auto-mode-alist)))
                         (setcdr cell ',mode)))
                     (funcall #',mode))
                 (fundamental-mode)
                 (message "Unzeit：%s 没有提供 %s，暂用 fundamental-mode"
                          ',package ',mode)))
           (error
            (fundamental-mode)
            (message "Unzeit：加载 %s 失败（%s），暂用 fundamental-mode"
                     ',package err))))
       (dolist (re ',regexps)
         (add-to-list 'auto-mode-alist (cons re #',entry))))))

(unzeit/define-on-demand-mode zig-mode zig-mode "\\.zig\\'")
(unzeit/define-on-demand-mode haskell-mode haskell-mode "\\.hs\\'")
(unzeit/define-on-demand-mode c3-ts-mode c3-ts-mode "\\.c3\\'"
                              :vc "https://github.com/c3lang/c3-ts-mode")
(unzeit/define-on-demand-mode odin-ts-mode odin-ts-mode "\\.odin\\'"
                              :vc "https://github.com/Sampie159/odin-ts-mode")
;; C/C++ 用极简 simpc-mode（simpleC）：轻量 font-lock + 简单缩进，适合
;; sqlite3.c / imgui.h 这类超大文件；真正排版交给保存时的 clang-format。
;; eglot/clangd 的补全与诊断（eglot-ensure 挂在 prog-mode）不受影响。
(unzeit/define-on-demand-mode simpc-mode simpc-mode "\\.[hc]\\(pp\\)?\\'"
                              :vc "https://github.com/rexim/simpc-mode")
;; 网页模板：web-mode 覆盖 njk/j2/html（add-to-list 在前，所以比内置
;; html-mode 的条目优先）
(unzeit/define-on-demand-mode web-mode web-mode
                              '("\\.njk\\'" "\\.j2\\'" "\\.html\\'"))
;; JavaScript 栈：js2-mode + js2-refactor + xref-js2 首次打开 .js/.mjs 时
;; 一并安装加载。multiple-cursors 是 js2-refactor 声明却在本机缺失的依赖
;;（缺了它 package-activate 会一直跳过 js2-refactor），由 ensure-package 补
(unzeit/define-on-demand-mode js2-mode js2-mode
                              '("\\.js\\'" "\\.mjs\\'")
                              :also (js2-refactor xref-js2 multiple-cursors))

;; ---- 语言模式（内置 -ts 变体 / 网页 / 脚本）------------------------
(use-package json-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.bowerrc\\'" . json-ts-mode)
         ("\\.jshintrc\\'" . json-ts-mode)
         ("\\.json_schema\\'" . json-ts-mode)
         ("\\.json\\'" . json-ts-mode)))

(use-package typescript-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.ts\\'" . typescript-ts-mode)))

(use-package yaml-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.ya?ml\\'" . yaml-ts-mode)))

(use-package rust-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.rs\\'" . rust-ts-mode)))

(use-package lua-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.lua\\'" . lua-ts-mode)
         ("\\.fuse\\'" . lua-ts-mode)))

(use-package cmake-ts-mode
  :ensure nil
  :defer t
  :mode (("CMakeLists\\.txt\\'" . cmake-ts-mode)
         ("\\.cmake\\'" . cmake-ts-mode)))

;; 包本身由上面的 shim 按需安装加载（:ensure nil 且不再写 :mode ——
;; auto-mode-alist 归 shim 管），这里只声明"加载之后要做什么"
(use-package web-mode
  :ensure nil
  :defer t
  :custom
  (web-mode-enable-control-block-indentation nil))

;; JavaScript 栈：js2-mode + js2-refactor + xref-js2（:hook 会生成
;; autoload + add-hook，包没装也不要紧——shim 会先装好再调用）
(use-package js2-mode
  :ensure nil
  :defer t
  :hook ((js2-mode . js2-imenu-extras-mode)))

(use-package js2-refactor
  :ensure nil
  :defer t
  :config
  (js2r-add-keybindings-with-prefix "C-c C-r")
  :hook ((js2-mode . js2-refactor-mode)))

(use-package xref-js2
  :ensure nil
  :defer t
  :hook ((js2-mode . (lambda ()
                      (add-hook 'xref-backend-functions
                                #'xref-js2-xref-backend nil t))))
  :custom
  (xref-js2-search-program 'rg))

;; ---- 本机安装的 LSP 服务器 -----------------------------------------
;; Guix 未打包这些服务器，所以它们放在 ~/.local（见 dotfiles/AGENTS.md）
;; `unzeit/jdtls-command' 定位 Eclipse 启动器 jar
;;
;; 网页语言（JS/TS/CSS/HTML）：服务器是 fnm node 安装里的 npm 全局包
;;（~/.local/share/fnm/node-versions/<ver>/installation/bin），软链接到
;; ~/tools/bin 使 emacs daemon 能在 PATH 上找到：typescript-language-server
;;（tsserver）、vscode-html-language-server、vscode-css-language-server、
;; prettier（apheleia）fnm 版本更新后请重跑 ~/tools/bin/fix-tools
;;
;; typescript-language-server v6 不会在 npm 全局根目录里搜 typescript，
;; 且它对 npm 包布局的内置查找是坏的——所以需要把 tsserver.path 设为
;; ~/tools/lib/typescript/lib/tsserver.js（fix-tools 维护的软链接）

(defun unzeit/jdtls-command (&rest _)
  "返回用于 Eglot 的 jdtls 命令（来自 profile 的 openjdk）"
  (let* ((jdtls (expand-file-name "~/.local/opt/jdtls"))
         (launcher (car (directory-files
                         (expand-file-name "plugins" jdtls) t
                         "org\\.eclipse\\.equinox\\.launcher_.*\\.jar$")))
         (config (expand-file-name "config_linux" jdtls))
         (workspace (expand-file-name "~/.cache/jdtls")))
    (make-directory workspace t)
    (list (or (executable-find "java") "java")
          "-jar" launcher "-configuration" config "-data" workspace)))

;;; ---- Eglot（补全 + 诊断后端）-------------------------------------
;; eglot 在 prog-mode（及其 ts 变体）下自动联接 LSP server，补全由 corfu
;; 弹窗、诊断经内置 flymake（波浪线 + 当前行 eldoc）server 表里没有的
;; 模式（odin/c3/lua/ruby/elisp 等）eglot-ensure 不作任何事，只保留纯
;; 语法高亮

(use-package eglot
  :ensure nil
  :defer t
  :hook ((prog-mode . eglot-ensure)
         (yaml-ts-mode . eglot-ensure)
         ;; html-mode（和 html-ts-mode）属于 text-mode 家族，而不是
         ;; prog-mode——没有这句 .html 文件就没有 LSP
         (html-mode . eglot-ensure))
  :config
  ;; 为 eglot 默认不知道的 ts 模式显式接线：zig（zls）、java（经
  ;; unzeit/jdtls-command）、haskell（hls）clangd/rust-analyzer/gopls/
  ;; pylsp/ts/css/html 是内置的
  (add-to-list 'eglot-server-programs '(zig-mode . ("zls")))
  (add-to-list 'eglot-server-programs '(java-ts-mode . unzeit/jdtls-command))
  (add-to-list 'eglot-server-programs '(simpc-mode . ("clangd")))
  (add-to-list 'eglot-server-programs
               '(haskell-mode . ("haskell-language-server" "--lsp"))))

(use-package consult-eglot
  :ensure t
  :defer t
  :bind (:map eglot-mode-map
          ("C-M-." . consult-eglot-symbols)))

;;; ---- Apheleia（保存时格式化）--------------------------------------
;; 外部格式化器；apheleia 在保存时运行它们，缺了只显示错误而不阻塞

(use-package apheleia
  :ensure t
  :defer t
  :hook (prog-mode . apheleia-mode)
  :config
  ;; `zigfmt' 不是 apheleia 内置格式化器：没有这条定义，每次保存 zig 都会
  ;; 抛出一个阻塞性 user-error（保存失败、缓冲保持未改、关闭永久询问）
  ;; 注意：必须用 add-to-list —— 用 :custom setq 会清空内置格式化器
  ;;（clang-format、rustfmt、black ...）
  (add-to-list 'apheleia-formatters '(zigfmt . ("zig" "fmt" "--stdin")))
  :custom
  (apheleia-mode-alist
   '((c-mode . (clang-format))
     (c++-mode . (clang-format))
     (c-ts-mode . (clang-format))
     (c++-ts-mode . (clang-format))
     (simpc-mode . (clang-format))
     (zig-mode . (zigfmt))
     (python-ts-mode . (black))
     (go-ts-mode . (gofmt))
     (rust-ts-mode . (rustfmt))
     (js2-mode . (prettier-javascript))
     (js-ts-mode . (prettier-javascript))
     (typescript-ts-mode . (prettier-typescript))
     (tsx-ts-mode . (prettier-typescript))
     (css-ts-mode . (prettier-css))
     (html-mode . (prettier-html))
     (json-ts-mode . (prettier-json))
     (yaml-ts-mode . (prettier-yaml))
     (toml-ts-mode . (taplo)))))

;;; init-eglot.el ends here
(provide 'init-eglot)

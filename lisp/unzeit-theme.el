;;; unzeit-theme.el --- Unzeit: alynx-one-dark 调色板 + 系统冰蓝强调色 -*- lexical-binding: t; -*-

;;; Commentary:
;; 一个暗色主题，调色板直接取自 nano-emacs 的 nano-theme-dark.el
;; （/home/lc/example/emacs_example/nano-emacs/）：这 9 个 nano 颜色映射到
;; Nordface 结构保留 Unzeit 的信息层级语义：
;;
;;   accent  （nano critical，现为 nord8 冰蓝 #88C0D0）选区、光标、搜索、提示、快捷键
;;   red     （nord11 #BF616A）错误、危险、删除
;;   popout  （nano popout  #D08770）警告、字符串、次要强调
;;   salient （nano salient #81A1C1）链接、关键字、类型、常量
;;   faded   （nano faded   #677691）注释、弱化文本
;;
;; 语法配色沿用了 nano-dark 应用的同样低饱和色相
;;（注释=faded 斜体、字符串=popout、关键字/类型/常量=salient、
;; 函数/变量=前景色），让代码保持可读，同时强调色始终显得有的放矢
;;
;; 另外借鉴 nano-emacs 的"七色语义 face"做法：本文件先定一层
;; unzeit-face-* 语义面（见"语义 face"一节）。具体 face 说明"是什么"，
;; 语义 face 说明"派什么用场"；新代码/新包上色时应优先 :inherit 语义面，
;; 而不是直接引用 unzeit/ 调色板常量。本文件里凡是一比一对应的 face 也
;; 已改为继承——换调色板时只需要改语义面那一处

;;; Code:

(deftheme unzeit
  "采用 nano-emacs（Nord）调色板的暗色主题：雪白信息、极光强调")

;; Emacs 30（30.1/30.2）回归问题：`custom-theme-set-faces' 只在
;; `custom--inhibit-theme-enable' 不为 nil（`load-theme' 期间）时才“记录”
;; face 设置，而 `enable-theme' 会跳过尚不存在的 face
;;（`custom-theme-recalc-face' 检查 `facep'）结果：只由主题定义的 face
;; 永远不被创建修复：立即套用——覆盖 inhibit 绑定并把主题标记为
;; `theme-immediate'，这会在设置时强制套用每个 face 规格（并创建该 face）

(put 'unzeit 'theme-immediate t)
(let ((custom--inhibit-theme-enable nil))

;;; ---- 调色板（nano-emacs dark / Nord）---------------------------

(defconst unzeit/bg           "#282C34" "背景（深蓝黑，alynx/hybrid）")
(defconst unzeit/bg-dim       "#2C323C" "略抬升的背景（alynx bg-hl）")
(defconst unzeit/bg-subtle    "#3E4451" "抬升的背景（alynx gray）")
(defconst unzeit/bg-mid       "#4B5363" "中等灰色背景（alynx gutter）")
(defconst unzeit/fg           "#C9D1DC" "前景：明亮、高对比的正文")
(defconst unzeit/fg-bright    "#E4E9F0" "次要文本（强）")
(defconst unzeit/fg-muted     "#828997" "弱化文本（alynx mono-2）")
(defconst unzeit/fg-faint     "#5C6370" "浅淡文本（行号、注释；alynx mono-3）")
(defconst unzeit/accent       "#88C0D0" "动作强调色（系统冰蓝 nord8）：光标/选区/搜索/快捷键")
(defconst unzeit/popout       "#D19A66" "Popout（alynx orange-1）：警告、字符串、次要强调")
(defconst unzeit/red          "#E06C75" "红色（alynx red-1）：错误、危险、删除")
(defconst unzeit/red-bg       "#4B3D48" "暗红色背景：细微的搜索/标记背景")
(defconst unzeit/salient      "#61AFEF" "Salient（alynx blue）：链接、关键字、类型、常量")
(defconst unzeit/border       "#4B5363" "边框与分隔符")
(defconst unzeit/green        "#98C379" "One Dark 绿：字符串、成功")
(defconst unzeit/purple       "#C678DD" "One Dark 紫：关键字")
(defconst unzeit/cyan         "#56B6C2" "One Dark 青：常量、内置")
(defconst unzeit/orange       "#E5C07B" "One Dark 橙-2：类型")

(custom-theme-set-faces
 'unzeit

 ;;; ---- 核心（Core）------------------------------------------------
 `(default ((t (:background ,unzeit/bg :foreground ,unzeit/fg))))
 `(cursor ((t (:background ,unzeit/accent :foreground ,unzeit/bg))))
 `(fixed-pitch ((t (:inherit default))))
 `(fixed-pitch-serif ((t (:inherit default))))
 `(variable-pitch ((t (:inherit default))))
 `(fringe ((t (:background ,unzeit/bg :foreground ,unzeit/fg-faint))))
 `(vertical-border ((t (:foreground ,unzeit/border))))
 `(window-divider ((t (:foreground ,unzeit/border))))
 `(window-divider-first-pixel ((t (:foreground ,unzeit/border))))
 `(window-divider-last-pixel ((t (:foreground ,unzeit/border))))
 `(highlight ((t (:background ,unzeit/bg-mid))))
  `(region ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :extend t))))
 `(secondary-selection ((t (:background ,unzeit/bg-mid :extend t))))
 `(hl-line ((t (:background ,unzeit/bg-dim :extend t))))
 `(success ((t (:foreground ,unzeit/fg))))
 `(error ((t (:inherit unzeit-face-critical))))
 `(warning ((t (:inherit unzeit-face-popout))))
 `(escape-glyph ((t (:foreground ,unzeit/fg-faint))))
 `(homoglyph ((t (:foreground ,unzeit/fg-faint))))
 `(minibuffer-prompt ((t (:inherit unzeit-face-accent))))
 `(header-line ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-muted))))
 `(tooltip ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg
                            :border ,unzeit/border))))
 `(button ((t (:inherit link))))
 `(link ((t (:inherit unzeit-face-salient :underline t))))
 `(link-visited ((t (:inherit unzeit-face-subtle :underline t))))
  `(help-key-binding ((t (:inherit unzeit-face-accent))))
  `(line-number ((t (:inherit unzeit-face-faded))))
 `(line-number-current-line ((t (:inherit unzeit-face-accent))))
 `(line-number-major-tick ((t (:foreground ,unzeit/fg-bright))))
 `(line-number-minor-tick ((t (:inherit unzeit-face-faded))))

 ;;; ---- 语义 face（Semantic faces）-----------------------------------
 ;; 借鉴 nano-emacs：把"用途"从"配色"里拆出来。新代码只认下面这层语义，
 ;; 不认调色板常量；具体 face 若是这些语义的一比一映射，也直接 :inherit
 ;;   default  正文
 ;;   strong   比正文更亮的次级信息（文件名、时间、当前行号）
 ;;   salient  链接、关键字、类型、常量（青蓝）
 ;;   accent   动作强调：光标/选区/搜索/快捷键（冰蓝，唯一的"可操作"色）
 ;;   popout   警告、字符串、次要强调（琥珀）
 ;;   critical 错误、危险、删除（红）
 ;;   subtle   弱化信息（灰）
 ;;   faded    注释、行号、几乎隐形的辅助信息（暗灰）
 `(unzeit-face-default ((t (:foreground ,unzeit/fg :background ,unzeit/bg))))
 `(unzeit-face-strong ((t (:foreground ,unzeit/fg-bright))))
 `(unzeit-face-salient ((t (:foreground ,unzeit/salient))))
 `(unzeit-face-accent ((t (:foreground ,unzeit/accent :weight bold))))
 `(unzeit-face-popout ((t (:foreground ,unzeit/popout :weight bold))))
 `(unzeit-face-critical ((t (:foreground ,unzeit/red :weight bold))))
 `(unzeit-face-subtle ((t (:foreground ,unzeit/fg-muted))))
 `(unzeit-face-faded ((t (:foreground ,unzeit/fg-faint))))

 ;;; ---- 搜索 / 匹配（Search / match）----------------------------------
  `(isearch ((t (:background ,unzeit/bg-mid :foreground ,unzeit/popout :extend t))))
 `(isearch-fail ((t (:background ,unzeit/bg-mid :foreground ,unzeit/red))))
 `(lazy-highlight ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg :extend t))))
 `(match ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg))))
 `(query-replace ((t (:inherit isearch))))
 `(isearch-group-1 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/accent))))
 `(isearch-group-2 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/popout))))

 ;;; ---- 括号（Paren）-----------------------------------------------
 `(show-paren-match ((t (:inherit unzeit-face-popout))))
 `(show-paren-match-expression ((t (:inherit unzeit-face-popout))))
 `(show-paren-mismatch ((t (:background ,unzeit/red :foreground ,unzeit/fg))))

 ;;; ---- 空白符（Whitespace）------------------------------------------
 `(whitespace-space ((t (:foreground ,unzeit/bg-mid))))
 `(whitespace-hspace ((t (:foreground ,unzeit/bg-mid))))
 `(whitespace-tab ((t (:foreground ,unzeit/fg-faint))))
 `(whitespace-newline ((t (:foreground ,unzeit/bg-mid))))
 `(whitespace-trailing ((t (:background ,unzeit/red :foreground ,unzeit/bg :weight bold))))
 `(whitespace-line ((t (:background ,unzeit/red-bg))))
 `(whitespace-space-before-tab ((t (:background ,unzeit/red-bg))))
 `(whitespace-indentation ((t (:background ,unzeit/red-bg))))
 `(whitespace-empty ((t (:background ,unzeit/red-bg))))
 `(whitespace-missing-newline-at-eof ((t (:background ,unzeit/red-bg :foreground ,unzeit/red))))
 `(whitespace-big-indent ((t (:background ,unzeit/red-bg))))

  ;;; ---- 语法（alynx-one-dark 语义）------------------------------------
  ;; 高对比 One Dark 分配：注释=faint(mono-3) 斜体、字符串=绿、关键字=紫、
  ;; 类型=橙、常量/内置=青、函数=冰蓝强调色、变量=红、数字=近白
  `(font-lock-comment-face ((t (:foreground ,unzeit/fg-faint :slant italic))))
  `(font-lock-comment-delimiter-face ((t (:foreground ,unzeit/fg-faint :slant italic))))
  `(font-lock-doc-face ((t (:foreground ,unzeit/fg-faint :slant italic))))
  `(font-lock-string-face ((t (:foreground ,unzeit/green))))
  `(font-lock-keyword-face ((t (:foreground ,unzeit/purple :weight bold))))
  `(font-lock-function-name-face ((t (:foreground ,unzeit/accent))))
  `(font-lock-variable-name-face ((t (:foreground ,unzeit/red))))
  `(font-lock-type-face ((t (:foreground ,unzeit/orange))))
  `(font-lock-constant-face ((t (:foreground ,unzeit/cyan))))
  `(font-lock-builtin-face ((t (:foreground ,unzeit/cyan))))
  `(font-lock-preprocessor-face ((t (:foreground ,unzeit/fg-muted))))
  `(font-lock-number-face ((t (:foreground ,unzeit/fg-bright))))
  `(font-lock-negation-char-face ((t (:foreground ,unzeit/cyan))))
  `(font-lock-regexp-grouping-backslash ((t (:foreground ,unzeit/fg-bright))))
  `(font-lock-regexp-grouping-construct ((t (:foreground ,unzeit/fg-bright))))
  `(font-lock-warning-face ((t (:inherit unzeit-face-critical))))
  `(elisp-shorthand-font-lock-face ((t (:foreground ,unzeit/accent))))

 ;;; ---- 模式行（Mode line）-------------------------------------------
  `(mode-line ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg
                              :box (:line-width 1 :color ,unzeit/bg-subtle)))))
  `(mode-line-inactive ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-muted
                                       :box (:line-width 1 :color ,unzeit/bg-dim)))))
  `(mode-line-highlight ((t (:background ,unzeit/bg-mid))))
  `(mode-line-emphasis ((t (:foreground ,unzeit/fg :weight bold))))
  `(mode-line-buffer-id ((t (:foreground ,unzeit/fg :weight bold))))
  `(unzeit-modeline-buffer ((t (:foreground ,unzeit/fg :weight bold))))
  `(unzeit-modeline-modified ((t (:foreground ,unzeit/popout :weight bold))))
  `(unzeit-modeline-lsp ((t (:foreground ,unzeit/popout :weight bold))))
  `(unzeit-modeline-mode ((t (:foreground ,unzeit/fg :weight bold))))
  `(unzeit-modeline-muted ((t (:foreground ,unzeit/fg-bright))))
  `(unzeit-modeline-position ((t (:foreground ,unzeit/fg-bright))))

 ;;; ---- 主屏（Dashboard）---------------------------------------------
 `(unzeit-dashboard-logo ((t (:foreground ,unzeit/fg :weight bold))))
 `(unzeit-dashboard-logo-red ((t (:foreground ,unzeit/accent :weight bold))))
 `(unzeit-dashboard-key ((t (:foreground ,unzeit/accent :weight bold))))

 ;;; ---- Meow ---------------------------------------------------------
  `(meow-normal-indicator ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg
                            :weight bold
                            :box (:line-width 1 :color ,unzeit/border)))))
  `(meow-insert-indicator ((t (:background ,unzeit/accent :foreground ,unzeit/bg
                           :weight bold
                           :box (:line-width 1 :color ,unzeit/border)))))
  `(meow-motion-indicator ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-bright
                           :weight bold
                           :box (:line-width 1 :color ,unzeit/border)))))
  `(meow-keypad-indicator ((t (:background ,unzeit/accent :foreground ,unzeit/bg
                           :weight bold
                           :box (:line-width 1 :color ,unzeit/border)))))
  `(meow-beacon-indicator ((t (:background ,unzeit/accent :foreground ,unzeit/bg
                           :weight bold
                           :box (:line-width 1 :color ,unzeit/border)))))
 `(meow-normal-cursor ((t (:inherit cursor))))
 `(meow-insert-cursor ((t (:inherit cursor))))
 `(meow-motion-cursor ((t (:inherit cursor))))
 `(meow-keypad-cursor ((t (:inherit cursor))))
 `(meow-beacon-cursor ((t (:inherit cursor))))
 `(meow-region-cursor-1 ((t (:background ,unzeit/accent :foreground ,unzeit/bg))))
 `(meow-region-cursor-2 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/accent))))
 `(meow-region-cursor-3 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/popout))))
 `(meow-search-highlight ((t (:inherit lazy-highlight))))
 `(meow-kmacro-cursor ((t (:background ,unzeit/accent :foreground ,unzeit/bg))))

 ;;; ---- 补全（vertico / corfu / marginalia / embark）------------------
 `(vertico-current ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :extend t))))
 `(vertico-group-title ((t (:foreground ,unzeit/fg-faint :weight bold))))
 `(vertico-multiline ((t (:foreground ,unzeit/fg-muted))))
  `(corfu-current ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/accent :weight bold))))
 `(corfu-default ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg))))
 `(corfu-bar ((t (:background ,unzeit/border))))
 `(corfu-border ((t (:background ,unzeit/border))))
 `(corfu-annotations ((t (:foreground ,unzeit/fg-faint))))
 `(marginalia-documentation ((t (:foreground ,unzeit/fg-faint))))
 `(marginalia-file-name ((t (:foreground ,unzeit/fg-bright))))
 `(marginalia-dir ((t (:foreground ,unzeit/fg-faint))))
 `(marginalia-type ((t (:foreground ,unzeit/accent))))
 `(marginalia-size ((t (:inherit unzeit-face-faded))))
 `(marginalia-date ((t (:inherit unzeit-face-faded))))
 `(marginalia-version ((t (:inherit unzeit-face-faded))))
 `(marginalia-char ((t (:inherit unzeit-face-faded))))
 `(marginalia-project-root ((t (:foreground ,unzeit/popout))))
 `(completions-common-part ((t (:foreground ,unzeit/fg :weight bold))))
 `(completions-first-difference ((t (:foreground ,unzeit/accent :weight bold))))
 `(completions-annotations ((t (:foreground ,unzeit/fg-faint))))
 `(embark-target ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg))))

 ;;; ---- which-key -----------------------------------------------------
 `(which-key-key-face ((t (:foreground ,unzeit/accent :weight bold))))
 `(which-key-group-description-face ((t (:foreground ,unzeit/accent))))
 `(which-key-command-description-face ((t (:foreground ,unzeit/fg))))
 `(which-key-local-map-description-face ((t (:foreground ,unzeit/fg-muted))))
 `(which-key-separator-face ((t (:foreground ,unzeit/fg-faint))))
 `(which-key-note-face ((t (:foreground ,unzeit/fg-faint))))
 `(which-key-special-key-face ((t (:foreground ,unzeit/fg :weight bold))))
 `(which-key-highlighted-command-face ((t (:foreground ,unzeit/accent :weight bold))))
 `(which-key-preview-face ((t (:background ,unzeit/red-bg))))

  ;;; ---- eglot ---------------------------------------------------------
  `(eglot-inlay-hint-face ((t (:foreground ,unzeit/fg-faint))))
 `(eglot-mode-line ((t (:foreground ,unzeit/fg-muted))))
 `(eldoc-highlight-function-argument ((t (:foreground ,unzeit/accent :weight bold))))
 `(xref-file-header ((t (:foreground ,unzeit/fg-faint :weight bold))))
 `(xref-match ((t (:inherit match))))

 ;;; ---- Dired ---------------------------------------------------------
 `(dired-directory ((t (:foreground ,unzeit/fg :weight bold))))
 `(dired-marked ((t (:background ,unzeit/red :foreground ,unzeit/fg :weight bold))))
 `(dired-flagged ((t (:inherit unzeit-face-critical))))
 `(dired-symlink ((t (:foreground ,unzeit/fg-bright))))
 `(dired-perm-write ((t (:foreground ,unzeit/fg-bright))))
 `(dired-ignored ((t (:inherit unzeit-face-faded))))
 `(dired-header ((t (:foreground ,unzeit/fg-muted :weight bold))))
 `(dired-warning ((t (:foreground ,unzeit/popout))))

 ;;; ---- 标签栏（Tab bar）-----------------------------------------------
 `(tab-bar ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-faint))))
 `(tab-bar-tab ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :weight bold))))
 `(tab-bar-tab-inactive ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-faint))))
 `(tab-bar-tab-group-current ((t (:foreground ,unzeit/accent :weight bold))))
 `(tab-bar-tab-group ((t (:foreground ,unzeit/fg-muted))))

 ;;; ---- Org ----------------------------------------------------------
 `(org-level-1 ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-level-2 ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-level-3 ((t (:foreground ,unzeit/fg-bright :weight bold))))
 `(org-level-4 ((t (:foreground ,unzeit/fg-bright))))
 `(org-level-5 ((t (:foreground ,unzeit/fg-muted))))
 `(org-level-6 ((t (:foreground ,unzeit/fg-muted))))
 `(org-level-7 ((t (:foreground ,unzeit/fg-faint))))
 `(org-level-8 ((t (:foreground ,unzeit/fg-faint))))
 `(org-todo ((t (:foreground ,unzeit/accent :weight bold))))
 `(org-done ((t (:inherit unzeit-face-faded))))
 `(org-headline-done ((t (:inherit unzeit-face-faded))))
 `(org-date ((t (:foreground ,unzeit/fg-bright :underline t))))
 `(org-link ((t (:foreground ,unzeit/salient :underline t))))
 `(org-code ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-bright))))
 `(org-block ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-bright))))
 `(org-block-begin-line ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-faint :slant italic))))
 `(org-block-end-line ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-faint :slant italic))))
 `(org-quote ((t (:foreground ,unzeit/fg-bright :slant italic))))
 `(org-verbatim ((t (:foreground ,unzeit/fg-bright))))
 `(org-meta-line ((t (:foreground ,unzeit/fg-muted))))
 `(org-tag ((t (:foreground ,unzeit/fg-faint :weight bold))))
 `(org-document-title ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-document-info ((t (:foreground ,unzeit/fg-muted))))
 `(org-document-info-keyword ((t (:foreground ,unzeit/fg-muted))))
 `(org-hide ((t (:foreground ,unzeit/bg))))
 `(org-indent ((t (:inherit org-hide))))
 ;; 表格文字与 org-modern 画出的网格线共用这个 face（网格线取它的反色），
 ;; 所以用正文色而不是最亮的 fg-bright，网格线才不刺眼
 `(org-table ((t (:foreground ,unzeit/fg))))
 `(org-priority ((t (:inherit unzeit-face-popout))))
 `(org-warning ((t (:inherit unzeit-face-popout))))
 `(org-agenda-structure ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-agenda-date ((t (:foreground ,unzeit/accent :weight bold))))
 `(org-agenda-date-today ((t (:foreground ,unzeit/accent :weight bold :underline t))))
 `(org-agenda-done ((t (:foreground ,unzeit/fg-faint))))
 `(org-agenda-dimmed-todo-face ((t (:inherit unzeit-face-faded))))
 `(org-upcoming-deadline ((t (:foreground ,unzeit/red))))
 `(org-scheduled ((t (:foreground ,unzeit/fg-bright))))
 `(org-scheduled-today ((t (:foreground ,unzeit/fg))))

 ;;; ---- org-modern（方正渲染）-----------------------------------------
 ;; 只给需要配色的部分上色；排版属性（org-modern-label 的 :height/:width）
 ;; 与 org-modern-symbol 的字体由 org-modern 自己管，主题不覆盖——
 ;; 方块星号因此保持 org-level-N 的颜色
 `(org-modern-tag ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg-muted))))
 `(org-modern-done ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-faint))))
 `(org-modern-todo ((t (:inherit org-todo :inverse-video t))))
 `(org-modern-priority ((t (:inherit org-priority :inverse-video t))))
 `(org-modern-date-active ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg-bright))))
 `(org-modern-time-active ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-bright :weight bold))))
 `(org-modern-date-inactive ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-faint))))
 `(org-modern-time-inactive ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-muted))))
 `(org-modern-block-name ((t (:foreground ,unzeit/fg-muted))))
 `(org-modern-progress-complete ((t (:background ,unzeit/accent :foreground ,unzeit/bg))))
 `(org-modern-progress-incomplete ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-muted))))
 `(org-modern-horizontal-rule ((t (:underline ,unzeit/border :extend t))))
 `(org-modern-internal-target ((t (:foreground ,unzeit/fg-faint))))
 `(org-modern-radio-target ((t (:foreground ,unzeit/fg-faint))))

 ;;; ---- Magit --------------------------------------------------------
 `(magit-section-heading ((t (:foreground ,unzeit/fg :weight bold))))
 `(magit-section-secondary-heading ((t (:foreground ,unzeit/fg-muted :weight bold))))
 `(magit-section-highlight ((t (:background ,unzeit/bg-subtle :extend t))))
 `(magit-section-noselect ((t (:inherit unzeit-face-faded))))
 `(magit-branch ((t (:foreground ,unzeit/accent :weight bold))))
 `(magit-branch-current ((t (:foreground ,unzeit/accent :weight bold))))
 `(magit-tag ((t (:foreground ,unzeit/fg-bright))))
 `(magit-hash ((t (:foreground ,unzeit/fg-faint))))
 `(magit-filename ((t (:foreground ,unzeit/fg))))
 `(magit-header-line ((t (:foreground ,unzeit/fg-muted :weight bold))))
 `(magit-diff-added ((t (:foreground ,unzeit/fg-bright :extend t))))
 `(magit-diff-added-highlight ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :extend t))))
 `(magit-diff-removed ((t (:foreground ,unzeit/red :extend t))))
 `(magit-diff-removed-highlight ((t (:background ,unzeit/red-bg :foreground ,unzeit/popout :extend t))))
 `(magit-diff-hunk-heading ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-faint :weight bold))))
 `(magit-diff-hunk-heading-highlight ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg-bright :weight bold))))
 `(magit-diff-file-heading ((t (:foreground ,unzeit/fg :weight bold))))
 `(magit-diff-file-heading-highlight ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :weight bold))))
 `(magit-diff-file-heading-selection ((t (:background ,unzeit/red-bg :foreground ,unzeit/accent :weight bold))))
 `(magit-diff-lines-heading ((t (:background ,unzeit/accent :foreground ,unzeit/bg))))
 `(magit-diff-conflict-heading ((t (:background ,unzeit/red-bg :foreground ,unzeit/red :weight bold))))
 `(magit-diffstat-added ((t (:foreground ,unzeit/fg-bright))))
 `(magit-diffstat-removed ((t (:foreground ,unzeit/red))))
 `(magit-log-author ((t (:foreground ,unzeit/fg-muted))))
 `(magit-log-date ((t (:inherit unzeit-face-faded))))
 `(magit-log-message ((t (:foreground ,unzeit/fg))))
 `(magit-log-graph ((t (:inherit unzeit-face-faded))))
 `(magit-process-ok ((t (:foreground ,unzeit/fg))))
 `(magit-process-ng ((t (:inherit unzeit-face-critical))))
 `(magit-untracked ((t (:foreground ,unzeit/popout))))
 `(magit-cherry-unmatched ((t (:foreground ,unzeit/popout))))
 `(magit-sequence-pick ((t (:foreground ,unzeit/fg))))

 ;;; ---- Hl-todo ------------------------------------------------------
 `(hl-todo ((t (:inherit unzeit-face-critical))))

 ;;; ---- 其它内置（Misc built-ins）-------------------------------------
 `(bookmark-menu-heading ((t (:foreground ,unzeit/fg :weight bold))))
 `(diff-added ((t (:foreground ,unzeit/fg-bright))))
 `(diff-removed ((t (:foreground ,unzeit/red))))
 `(diff-header ((t (:foreground ,unzeit/fg-muted))))
 `(diff-file-header ((t (:foreground ,unzeit/fg :weight bold))))
 `(diff-hunk-header ((t (:foreground ,unzeit/fg-faint :weight bold))))
 `(diff-context ((t (:foreground ,unzeit/fg-faint))))
 `(diff-refine-added ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg))))
 `(diff-refine-removed ((t (:background ,unzeit/red-bg :foreground ,unzeit/popout))))
 `(compilation-error ((t (:inherit unzeit-face-critical))))
 `(compilation-warning ((t (:inherit unzeit-face-popout))))
 `(compilation-info ((t (:foreground ,unzeit/fg-bright))))
 `(compilation-line-number ((t (:foreground ,unzeit/fg-faint))))
 `(compilation-column-number ((t (:foreground ,unzeit/fg-faint))))
 `(compilation-mode-line-exit ((t (:foreground ,unzeit/fg))))
 `(compilation-mode-line-fail ((t (:foreground ,unzeit/red :weight bold))))
 `(compilation-mode-line-run ((t (:foreground ,unzeit/fg-bright))))
 `(next-error ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg :extend t))))
 `(anzu-match-1 ((t (:background ,unzeit/accent :foreground ,unzeit/bg))))
 `(anzu-match-2 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/accent))))
 `(anzu-match-3 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/popout))))
 `(goggles-added ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg))))
 `(goggles-removed ((t (:background ,unzeit/red-bg :foreground ,unzeit/popout))))
 `(goggles-changed ((t (:background ,unzeit/bg-mid :foreground ,unzeit/popout))))
 `(minibuffer-prompt-end ((t (:foreground ,unzeit/fg)))))
;;; custom-theme-set-faces ends here

;; 关闭上面的 `custom--inhibit-theme-enable' 覆盖
)

;; 一些包会查询这些 face 别名
(put 'unzeit 'theme-foreground-color unzeit/fg)
(put 'unzeit 'theme-background-color unzeit/bg)
(put 'unzeit 'theme-link-color unzeit/salient)
(put 'unzeit 'theme-success-color unzeit/fg)
(put 'unzeit 'theme-warning-color unzeit/popout)
(put 'unzeit 'theme-error-color unzeit/red)

(provide-theme 'unzeit)

;;; unzeit-theme.el ends here

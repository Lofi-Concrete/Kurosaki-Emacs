;;; unzeit-theme.el --- Unzeit: Guix/dwm 构成主义高对比主题 -*- lexical-binding: t; -*-

;;; Commentary:
;; 调色板来自 ~/Downloads/guix-dwm-constructivist-theme.md 的规范，并按
;; dwm 状态栏（~/Projects/suckless/dwm/config.h）的实际取值把正文提到纯白：
;;
;;   #101010  ground   基础背景（dwm 条 / 终端底）
;;   #FFFFFF  white    正文 —— dwm 条的普通文字与数值（对比 19.6:1）
;;   #E4DED3  cream    规范里的高亮米白 —— dwm 的「当前标签 / 时间」
;;   #D8D1C6  soft     规范原始主前景（软白）—— 次级正文
;;   #8C887F  gray     规范次要灰提亮一档 —— 注释、行号（5.4:1，保证可读）
;;   #77746D  dim      规范次要灰 —— 分隔细线、装饰
;;   #C83B27  red      唯一强调色 —— 光标、当前、错误、链接
;;
;; 整套只有**一个**彩色：红。其余全靠 白/米白/软白/灰 四档明度，加上字重
;; （粗体）、字形（斜体）和下划线来分语义。红永远只出现在小面积上：
;; 光标方块、mode line 的状态小块、当前匹配、错误、链接 —— 就是 dwm 状态栏
;; 左端那颗红方块的语言。禁止用红色铺大面积底色。
;;
;; 语义 face 层（见下方“语义 face”一节）不变，新代码只认它：
;;   default  正文 | strong 米白强调 | salient 软白 | accent 红（动作）
;;   popout   米白粗体 | critical 红粗体 | subtle 软白 | faded 灰
;;
;; 另：自定义光标的取色常量 unzeit/bg 与 unzeit/accent 被
;; unzeit-cursor.el / core.el 按符号名读取，改名会静默退回兜底色。

;;; Code:

(deftheme unzeit
  "Guix/dwm 构成主义主题：纯黑底 + 纯白正文 + 唯一强调红（高对比）")

;; Emacs 30（30.1/30.2）回归问题：`custom-theme-set-faces' 只在
;; `custom--inhibit-theme-enable' 不为 nil（`load-theme' 期间）时才“记录”
;; face 设置，而 `enable-theme' 会跳过尚不存在的 face
;;（`custom-theme-recalc-face' 检查 `facep'）结果：只由主题定义的 face
;; 永远不被创建修复：立即套用——覆盖 inhibit 绑定并把主题标记为
;; `theme-immediate'，这会在设置时强制套用每个 face 规格（并创建该 face）

(put 'unzeit 'theme-immediate t)
(let ((custom--inhibit-theme-enable nil))

;;; ---- 调色板（构成主义 / dwm 状态栏）-----------------------------

(defconst unzeit/bg           "#101010" "基础背景（构成主义 ground：dwm 条/终端底）")
(defconst unzeit/bg-dim       "#181818" "微微抬升的背景（hl-line、tab bar）")
(defconst unzeit/bg-subtle    "#202020" "抬升面（补全当前项、区块底色）")
(defconst unzeit/bg-mid       "#2E2E2E" "再亮一档（isearch/match 底色、highlight）")
(defconst unzeit/fg           "#FFFFFF" "正文：纯白（对 #101010 对比 19.6:1）")
(defconst unzeit/fg-bright    "#E4DED3" "强调信息：规范里的 cream 米白")
(defconst unzeit/fg-muted     "#D8D1C6" "次要信息：规范原始主前景（软白）")
(defconst unzeit/fg-comment   "#8C887F" "注释、行号：次要灰提亮一档（5.4:1）")
(defconst unzeit/fg-faint     "#77746D" "弱化装饰：规范次要灰（分隔线、空白符标记）")
(defconst unzeit/fg-ghost     "#343434" "几乎隐形（空白符点、缩进引导）")
(defconst unzeit/red          "#C83B27" "唯一强调色（dwm 红）：动作 / 当前 / 错误")
(defconst unzeit/red-bg       "#3A1610" "暗红底（搜索/冲突/标记，绝不铺大面积）")
(defconst unzeit/border       "#333333" "分隔细线")
(defconst unzeit/rule         "#4A4842" "比 border 略亮的分隔线（mode line 上下边）")

;; 旧语义名的再映射：语法面历史上直接引用过这些名字
(defconst unzeit/accent  unzeit/red       "动作强调色（= 唯一强调红）")
(defconst unzeit/salient unzeit/fg-muted  "链接/关键字/类型/常量（软白）")
(defconst unzeit/popout  unzeit/fg-bright "警告/字符串/次要强调（米白）")
(defconst unzeit/green   unzeit/fg-bright "（旧名）字符串：现为米白")
(defconst unzeit/orange  unzeit/fg-bright "（旧名）类型：现为米白")
(defconst unzeit/purple  unzeit/fg        "（旧名）关键字：现为纯白粗体")
(defconst unzeit/cyan    unzeit/fg-muted  "（旧名）常量/内置：现为软白")

(custom-theme-set-faces
 'unzeit

 ;;; ---- 核心（Core）------------------------------------------------
 `(default ((t (:background ,unzeit/bg :foreground ,unzeit/fg))))
 ;; 光标是整张桌面上唯一的「红色小方块」，与 dwm 条左端那颗 ■ 同源
 `(cursor ((t (:background ,unzeit/red :foreground ,unzeit/bg))))
 `(fixed-pitch ((t (:inherit default))))
 `(fixed-pitch-serif ((t (:inherit default))))
 `(variable-pitch ((t (:inherit default))))
 `(fringe ((t (:background ,unzeit/bg :foreground ,unzeit/fg-faint))))
 `(vertical-border ((t (:foreground ,unzeit/fg-ghost))))
 `(window-divider ((t (:foreground ,unzeit/fg-ghost))))
 `(window-divider-first-pixel ((t (:foreground ,unzeit/fg-ghost))))
 `(window-divider-last-pixel ((t (:foreground ,unzeit/fg-ghost))))
 `(highlight ((t (:background ,unzeit/bg-mid))))
 ;; 选区 = 规范里的「高亮米白」实块，黑字；不铺红底
 `(region ((t (:background ,unzeit/fg-muted :foreground ,unzeit/bg :extend t))))
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
 `(link ((t (:inherit unzeit-face-accent :underline t))))
 `(link-visited ((t (:inherit unzeit-face-subtle :underline t))))
  `(help-key-binding ((t (:inherit unzeit-face-accent))))
  ;; 当前行号 = 「当前标签」，用米白；普通行号退到灰
  `(line-number ((t (:inherit unzeit-face-faded))))
 `(line-number-current-line ((t (:foreground ,unzeit/fg-bright :weight bold))))
 `(line-number-major-tick ((t (:foreground ,unzeit/fg))))
 `(line-number-minor-tick ((t (:inherit unzeit-face-faded))))

 ;;; ---- 语义 face（Semantic faces）-----------------------------------
 ;; 把"用途"从"配色"里拆出来。新代码只认下面这层语义，不认调色板常量；
 ;; 具体 face 若是这些语义的一比一映射，也直接 :inherit
 ;;   default  正文（纯白）
 ;;   strong   比正文更"当前"的信息（文件名、时间、当前行号；米白）
 ;;   salient  关键字、类型、常量（软白，靠字重/字形再分层）
 ;;   accent   动作强调：光标/当前项/提示/快捷键（红，唯一的彩色）
 ;;   popout   警告、字符串、次要强调（米白粗体）
 ;;   critical 错误、危险、删除（红粗体）
 ;;   subtle   弱化信息（软白）
 ;;   faded    注释、行号、几乎隐形的辅助信息（灰）
 `(unzeit-face-default ((t (:foreground ,unzeit/fg :background ,unzeit/bg))))
 `(unzeit-face-strong ((t (:foreground ,unzeit/fg-bright))))
 `(unzeit-face-salient ((t (:foreground ,unzeit/fg-muted))))
 `(unzeit-face-accent ((t (:foreground ,unzeit/red :weight bold))))
 `(unzeit-face-popout ((t (:foreground ,unzeit/fg-bright :weight bold))))
 `(unzeit-face-critical ((t (:foreground ,unzeit/red :weight bold))))
 `(unzeit-face-subtle ((t (:foreground ,unzeit/fg-muted))))
 `(unzeit-face-faded ((t (:foreground ,unzeit/fg-comment))))

 ;;; ---- 搜索 / 匹配（Search / match）----------------------------------
 ;; 红只作前景或极小的底：匹配用暗红底 + 米白字，当前匹配用红字
   `(isearch ((t (:background ,unzeit/bg-mid :foreground ,unzeit/red
                              :weight bold :extend t))))
 `(isearch-fail ((t (:background ,unzeit/red :foreground ,unzeit/bg :weight bold))))
 `(lazy-highlight ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg-bright :extend t))))
 `(match ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg-bright))))
 `(query-replace ((t (:inherit isearch))))
 `(isearch-group-1 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/red :weight bold))))
 `(isearch-group-2 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-bright :weight bold))))

 ;;; ---- 括号（Paren）-----------------------------------------------
 `(show-paren-match ((t (:foreground ,unzeit/red :weight bold))))
 `(show-paren-match-expression ((t (:background ,unzeit/bg-mid :extend t))))
 `(show-paren-mismatch ((t (:background ,unzeit/red :foreground ,unzeit/bg :weight bold))))

 ;;; ---- 空白符（Whitespace）------------------------------------------
 ;; 点/箭头几乎隐形；真正要紧的行尾空白与缺尾换行用红标出来
 `(whitespace-space ((t (:foreground ,unzeit/fg-ghost))))
 `(whitespace-hspace ((t (:foreground ,unzeit/fg-ghost))))
 `(whitespace-tab ((t (:foreground ,unzeit/fg-faint))))
 `(whitespace-newline ((t (:foreground ,unzeit/fg-ghost))))
 `(whitespace-trailing ((t (:background ,unzeit/red :foreground ,unzeit/bg :weight bold))))
 `(whitespace-line ((t (:background ,unzeit/red-bg))))
 `(whitespace-space-before-tab ((t (:background ,unzeit/red-bg))))
 `(whitespace-indentation ((t (:background ,unzeit/red-bg))))
 `(whitespace-empty ((t (:background ,unzeit/red-bg))))
 `(whitespace-missing-newline-at-eof ((t (:background ,unzeit/red-bg :foreground ,unzeit/red))))
 `(whitespace-big-indent ((t (:background ,unzeit/red-bg))))

  ;;; ---- 语法（单色构成主义）-------------------------------------------
  ;; 没有第二、第三个颜色可用：注释靠"灰 + 斜体"后退，字符串/常量/内置靠
  ;; 软白，关键字靠"纯白 + 粗体"，函数/类型靠米白 —— 全部落回同一条灰阶。
  ;; 语法高亮因此读起来像一份印刷排版的校样，而不是霓虹灯。
  `(font-lock-comment-face ((t (:foreground ,unzeit/fg-comment :slant italic))))
  `(font-lock-comment-delimiter-face ((t (:foreground ,unzeit/fg-comment :slant italic))))
  `(font-lock-doc-face ((t (:foreground ,unzeit/fg-comment :slant italic))))
  `(font-lock-string-face ((t (:foreground ,unzeit/fg-muted))))
  `(font-lock-keyword-face ((t (:foreground ,unzeit/fg :weight bold))))
  `(font-lock-function-name-face ((t (:foreground ,unzeit/fg-bright))))
  `(font-lock-variable-name-face ((t (:foreground ,unzeit/fg))))
  `(font-lock-type-face ((t (:foreground ,unzeit/fg-bright :weight bold))))
  `(font-lock-constant-face ((t (:foreground ,unzeit/fg-muted))))
  `(font-lock-builtin-face ((t (:foreground ,unzeit/fg-muted))))
  `(font-lock-preprocessor-face ((t (:foreground ,unzeit/fg-comment))))
  `(font-lock-number-face ((t (:foreground ,unzeit/fg))))
  `(font-lock-negation-char-face ((t (:foreground ,unzeit/red :weight bold))))
  `(font-lock-regexp-grouping-backslash ((t (:foreground ,unzeit/fg :weight bold))))
  `(font-lock-regexp-grouping-construct ((t (:foreground ,unzeit/fg :weight bold))))
  `(font-lock-warning-face ((t (:inherit unzeit-face-critical))))
  `(elisp-shorthand-font-lock-face ((t (:foreground ,unzeit/fg-muted))))

 ;;; ---- 模式行（Mode line）-------------------------------------------
 ;; 就是把 dwm 状态栏搬到 Emacs 底部：同色 #101010 的底、纯白正文、
 ;; 一条印刷细线分界，唯一的红色只出现在 meow 状态小块上
  `(mode-line ((t (:background ,unzeit/bg :foreground ,unzeit/fg
                               :box (:line-width 1 :color ,unzeit/rule)))))
  `(mode-line-inactive ((t (:background ,unzeit/bg :foreground ,unzeit/fg-comment
                                        :box (:line-width 1 :color ,unzeit/border)))))
  `(mode-line-highlight ((t (:background ,unzeit/bg-mid))))
  `(mode-line-emphasis ((t (:foreground ,unzeit/fg :weight bold))))
  `(mode-line-buffer-id ((t (:foreground ,unzeit/fg :weight bold))))
  `(unzeit-modeline-buffer ((t (:foreground ,unzeit/fg :weight bold))))
  ;; 有改动 = 需要动作 = 红
  `(unzeit-modeline-modified ((t (:foreground ,unzeit/red :weight bold))))
  `(unzeit-modeline-lsp ((t (:foreground ,unzeit/fg-bright :weight bold))))
  `(unzeit-modeline-mode ((t (:foreground ,unzeit/fg :weight bold))))
  `(unzeit-modeline-muted ((t (:foreground ,unzeit/fg-muted))))
  ;; 百分比/行列/时钟 = dwm 条右端的时间，用米白
  `(unzeit-modeline-position ((t (:foreground ,unzeit/fg-bright))))

 ;;; ---- 主屏（Dashboard）---------------------------------------------
 ;; logo 的 "UN" 就是那颗红方块，"ZEIT" 纯白；快捷键标红
 `(unzeit-dashboard-logo ((t (:foreground ,unzeit/fg :weight bold))))
 `(unzeit-dashboard-logo-red ((t (:foreground ,unzeit/red :weight bold))))
 `(unzeit-dashboard-key ((t (:foreground ,unzeit/red :weight bold))))

 ;;; ---- Meow ---------------------------------------------------------
 ;; 状态指示器 = dwm 条的红色小方块：红底黑字；次态退成白块/灰块
  `(meow-normal-indicator ((t (:background ,unzeit/red :foreground ,unzeit/bg
                            :weight bold
                            :box (:line-width 1 :color ,unzeit/red)))))
  `(meow-insert-indicator ((t (:background ,unzeit/fg :foreground ,unzeit/bg
                            :weight bold
                            :box (:line-width 1 :color ,unzeit/fg)))))
  `(meow-motion-indicator ((t (:background ,unzeit/fg-faint :foreground ,unzeit/bg
                            :weight bold
                            :box (:line-width 1 :color ,unzeit/fg-faint)))))
  `(meow-keypad-indicator ((t (:background ,unzeit/red :foreground ,unzeit/bg
                            :weight bold
                            :box (:line-width 1 :color ,unzeit/red)))))
  `(meow-beacon-indicator ((t (:background ,unzeit/red :foreground ,unzeit/bg
                            :weight bold
                            :box (:line-width 1 :color ,unzeit/red)))))
 `(meow-normal-cursor ((t (:inherit cursor))))
 `(meow-insert-cursor ((t (:inherit cursor))))
 `(meow-motion-cursor ((t (:inherit cursor))))
 `(meow-keypad-cursor ((t (:inherit cursor))))
 `(meow-beacon-cursor ((t (:inherit cursor))))
 ;; meow 在 minibuffer / 未知状态用这个 face 取光标颜色；不定义的话它会退到
 ;; `default' 的前景色（白），光标就不是红方块了
 `(meow-unknown-cursor ((t (:inherit cursor))))
 `(meow-region-cursor-1 ((t (:background ,unzeit/red :foreground ,unzeit/bg))))
 `(meow-region-cursor-2 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/red))))
 `(meow-region-cursor-3 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-bright))))
 `(meow-search-highlight ((t (:inherit lazy-highlight))))
 `(meow-kmacro-cursor ((t (:background ,unzeit/red :foreground ,unzeit/bg))))

 ;;; ---- 补全（vertico / corfu / marginalia / embark）------------------
 ;; 候选当前项：白字灰底 + 粗体 —— 不用红铺底（红留给光标与错误）
 `(vertico-current ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg
                                   :weight bold :extend t))))
 `(vertico-group-title ((t (:foreground ,unzeit/fg-comment :weight bold))))
 `(vertico-multiline ((t (:foreground ,unzeit/fg-muted))))
  `(corfu-current ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg :weight bold))))
  `(corfu-default ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg))))
  `(corfu-bar ((t (:background ,unzeit/border))))
  `(corfu-border ((t (:background ,unzeit/border))))
  `(corfu-annotations ((t (:foreground ,unzeit/fg-comment))))
  `(marginalia-documentation ((t (:foreground ,unzeit/fg-comment))))
  `(marginalia-file-name ((t (:foreground ,unzeit/fg))))
  `(marginalia-dir ((t (:foreground ,unzeit/fg-comment))))
  `(marginalia-type ((t (:foreground ,unzeit/fg-bright))))
  `(marginalia-size ((t (:inherit unzeit-face-faded))))
  `(marginalia-date ((t (:inherit unzeit-face-faded))))
  `(marginalia-version ((t (:inherit unzeit-face-faded))))
  `(marginalia-char ((t (:inherit unzeit-face-faded))))
  `(marginalia-project-root ((t (:foreground ,unzeit/fg-muted))))
  `(completions-common-part ((t (:foreground ,unzeit/fg :weight bold))))
  `(completions-first-difference ((t (:foreground ,unzeit/red :weight bold))))
  `(completions-annotations ((t (:foreground ,unzeit/fg-comment))))
  `(embark-target ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg-bright))))

 ;;; ---- which-key -----------------------------------------------------
 ;; 快捷键 = 可操作 = 红
 `(which-key-key-face ((t (:foreground ,unzeit/red :weight bold))))
 `(which-key-group-description-face ((t (:foreground ,unzeit/fg-muted))))
 `(which-key-command-description-face ((t (:foreground ,unzeit/fg))))
 `(which-key-local-map-description-face ((t (:foreground ,unzeit/fg-comment))))
 `(which-key-separator-face ((t (:foreground ,unzeit/fg-ghost))))
 `(which-key-note-face ((t (:foreground ,unzeit/fg-comment))))
 `(which-key-special-key-face ((t (:foreground ,unzeit/fg :weight bold))))
 `(which-key-highlighted-command-face ((t (:foreground ,unzeit/red :weight bold))))
 `(which-key-preview-face ((t (:background ,unzeit/red-bg))))

  ;;; ---- eglot ---------------------------------------------------------
  `(eglot-inlay-hint-face ((t (:foreground ,unzeit/fg-comment))))
 `(eglot-mode-line ((t (:foreground ,unzeit/fg-muted))))
 `(eldoc-highlight-function-argument ((t (:foreground ,unzeit/red :weight bold))))
 `(xref-file-header ((t (:foreground ,unzeit/fg-comment :weight bold))))
 `(xref-match ((t (:inherit match))))

 ;;; ---- Dired ---------------------------------------------------------
 ;; 标记一整行不铺红，用灰底 + 红字（红只占文字那么宽）
 `(dired-directory ((t (:foreground ,unzeit/fg :weight bold))))
 `(dired-marked ((t (:background ,unzeit/bg-mid :foreground ,unzeit/red :weight bold))))
 `(dired-flagged ((t (:inherit unzeit-face-critical))))
 `(dired-symlink ((t (:foreground ,unzeit/fg-bright))))
 `(dired-perm-write ((t (:foreground ,unzeit/fg-bright))))
 `(dired-ignored ((t (:inherit unzeit-face-faded))))
 `(dired-header ((t (:foreground ,unzeit/fg-muted :weight bold))))
 `(dired-warning ((t (:foreground ,unzeit/fg-bright :weight bold))))

 ;;; ---- 标签栏（Tab bar）-----------------------------------------------
 `(tab-bar ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-comment))))
 `(tab-bar-tab ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg :weight bold))))
 `(tab-bar-tab-inactive ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-comment))))
 `(tab-bar-tab-group-current ((t (:foreground ,unzeit/fg-bright :weight bold))))
 `(tab-bar-tab-group ((t (:foreground ,unzeit/fg-muted))))

 ;;; ---- Org ----------------------------------------------------------
 `(org-level-1 ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-level-2 ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-level-3 ((t (:foreground ,unzeit/fg-bright :weight bold))))
 `(org-level-4 ((t (:foreground ,unzeit/fg-bright))))
 `(org-level-5 ((t (:foreground ,unzeit/fg-muted))))
 `(org-level-6 ((t (:foreground ,unzeit/fg-muted))))
 `(org-level-7 ((t (:foreground ,unzeit/fg-comment))))
 `(org-level-8 ((t (:foreground ,unzeit/fg-comment))))
 ;; 待办 = 需要动作 = 红
 `(org-todo ((t (:foreground ,unzeit/red :weight bold))))
 `(org-done ((t (:inherit unzeit-face-faded))))
 `(org-headline-done ((t (:inherit unzeit-face-faded))))
 `(org-date ((t (:foreground ,unzeit/fg-bright :underline t))))
 `(org-link ((t (:foreground ,unzeit/red :underline t))))
 `(org-code ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-bright))))
 `(org-block ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-bright))))
 `(org-block-begin-line ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-comment :slant italic))))
 `(org-block-end-line ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-comment :slant italic))))
 `(org-quote ((t (:foreground ,unzeit/fg-bright :slant italic))))
 `(org-verbatim ((t (:foreground ,unzeit/fg-bright))))
 `(org-meta-line ((t (:foreground ,unzeit/fg-muted))))
 `(org-tag ((t (:foreground ,unzeit/fg-comment :weight bold))))
 `(org-document-title ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-document-info ((t (:foreground ,unzeit/fg-muted))))
 `(org-document-info-keyword ((t (:foreground ,unzeit/fg-muted))))
 `(org-hide ((t (:foreground ,unzeit/bg))))
 `(org-indent ((t (:inherit org-hide))))
 ;; 表格文字与 org-modern 画出的网格线共用这个 face（网格线取它的反色），
 ;; 所以用正文色而不是最亮的米白，网格线才不刺眼
 `(org-table ((t (:foreground ,unzeit/fg))))
 `(org-priority ((t (:inherit unzeit-face-critical))))
 `(org-warning ((t (:inherit unzeit-face-popout))))
 `(org-agenda-structure ((t (:foreground ,unzeit/fg :weight bold))))
 `(org-agenda-date ((t (:foreground ,unzeit/red :weight bold))))
 `(org-agenda-date-today ((t (:foreground ,unzeit/red :weight bold :underline t))))
 `(org-agenda-done ((t (:foreground ,unzeit/fg-comment))))
 `(org-agenda-dimmed-todo-face ((t (:inherit unzeit-face-faded))))
 `(org-upcoming-deadline ((t (:foreground ,unzeit/red))))
 `(org-scheduled ((t (:foreground ,unzeit/fg-bright))))
 `(org-scheduled-today ((t (:foreground ,unzeit/fg))))

 ;;; ---- org-modern（方正渲染）-----------------------------------------
 ;; 只给需要配色的部分上色；排版属性（org-modern-label 的 :height/:width）
 ;; 与 org-modern-symbol 的字体由 org-modern 自己管，主题不覆盖——
 ;; 方块星号因此保持 org-level-N 的颜色
 `(org-modern-tag ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg-muted))))
 `(org-modern-done ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-comment))))
 `(org-modern-todo ((t (:inherit org-todo :inverse-video t))))
 `(org-modern-priority ((t (:inherit org-priority :inverse-video t))))
 `(org-modern-date-active ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg))))
 `(org-modern-time-active ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg :weight bold))))
 `(org-modern-date-inactive ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-comment))))
 `(org-modern-time-inactive ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-muted))))
 `(org-modern-block-name ((t (:foreground ,unzeit/fg-muted))))
 `(org-modern-progress-complete ((t (:background ,unzeit/red :foreground ,unzeit/bg))))
 `(org-modern-progress-incomplete ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-muted))))
 `(org-modern-horizontal-rule ((t (:underline ,unzeit/border :extend t))))
 `(org-modern-internal-target ((t (:foreground ,unzeit/fg-comment))))
 `(org-modern-radio-target ((t (:foreground ,unzeit/fg-comment))))

 ;;; ---- Magit --------------------------------------------------------
 `(magit-section-heading ((t (:foreground ,unzeit/fg :weight bold))))
 `(magit-section-secondary-heading ((t (:foreground ,unzeit/fg-muted :weight bold))))
 `(magit-section-highlight ((t (:background ,unzeit/bg-subtle :extend t))))
 `(magit-section-noselect ((t (:inherit unzeit-face-faded))))
 `(magit-branch ((t (:foreground ,unzeit/red :weight bold))))
 `(magit-branch-current ((t (:foreground ,unzeit/red :weight bold))))
 `(magit-tag ((t (:foreground ,unzeit/fg-bright))))
 `(magit-hash ((t (:foreground ,unzeit/fg-comment))))
 `(magit-filename ((t (:foreground ,unzeit/fg))))
 `(magit-header-line ((t (:foreground ,unzeit/fg-muted :weight bold))))
 ;; 增/删都不上色，靠米白 vs 红区分（红 = 删除/危险）
 `(magit-diff-added ((t (:foreground ,unzeit/fg-bright :extend t))))
 `(magit-diff-added-highlight ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :extend t))))
 `(magit-diff-removed ((t (:foreground ,unzeit/red :extend t))))
 `(magit-diff-removed-highlight ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg-bright :extend t))))
 `(magit-diff-hunk-heading ((t (:background ,unzeit/bg-dim :foreground ,unzeit/fg-comment :weight bold))))
 `(magit-diff-hunk-heading-highlight ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :weight bold))))
 `(magit-diff-file-heading ((t (:foreground ,unzeit/fg :weight bold))))
 `(magit-diff-file-heading-highlight ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg :weight bold))))
 `(magit-diff-file-heading-selection ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/red :weight bold))))
 `(magit-diff-lines-heading ((t (:background ,unzeit/red :foreground ,unzeit/bg))))
 `(magit-diff-conflict-heading ((t (:background ,unzeit/red-bg :foreground ,unzeit/red :weight bold))))
 `(magit-diffstat-added ((t (:foreground ,unzeit/fg-bright))))
 `(magit-diffstat-removed ((t (:foreground ,unzeit/red))))
 `(magit-log-author ((t (:foreground ,unzeit/fg-muted))))
 `(magit-log-date ((t (:inherit unzeit-face-faded))))
 `(magit-log-message ((t (:foreground ,unzeit/fg))))
 `(magit-log-graph ((t (:inherit unzeit-face-faded))))
 `(magit-process-ok ((t (:foreground ,unzeit/fg))))
 `(magit-process-ng ((t (:inherit unzeit-face-critical))))
 `(magit-untracked ((t (:foreground ,unzeit/fg-bright))))
 `(magit-cherry-unmatched ((t (:foreground ,unzeit/fg-bright))))
 `(magit-sequence-pick ((t (:foreground ,unzeit/fg))))

 ;;; ---- Hl-todo ------------------------------------------------------
 ;; TODO/FIXME 也是「需要动作」，与 org-todo 同一档红
 `(hl-todo ((t (:inherit unzeit-face-critical))))

 ;;; ---- 其它内置（Misc built-ins）-------------------------------------
 `(bookmark-menu-heading ((t (:foreground ,unzeit/fg :weight bold))))
 `(diff-added ((t (:foreground ,unzeit/fg-bright))))
 `(diff-removed ((t (:foreground ,unzeit/red))))
 `(diff-header ((t (:foreground ,unzeit/fg-muted))))
 `(diff-file-header ((t (:foreground ,unzeit/fg :weight bold))))
 `(diff-hunk-header ((t (:foreground ,unzeit/fg-comment :weight bold))))
 `(diff-context ((t (:foreground ,unzeit/fg-comment))))
 `(diff-refine-added ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg))))
 `(diff-refine-removed ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg-bright))))
 `(compilation-error ((t (:inherit unzeit-face-critical))))
 `(compilation-warning ((t (:inherit unzeit-face-popout))))
 `(compilation-info ((t (:foreground ,unzeit/fg-bright))))
 `(compilation-line-number ((t (:foreground ,unzeit/fg-comment))))
 `(compilation-column-number ((t (:foreground ,unzeit/fg-comment))))
 `(compilation-mode-line-exit ((t (:foreground ,unzeit/fg))))
 `(compilation-mode-line-fail ((t (:foreground ,unzeit/red :weight bold))))
 `(compilation-mode-line-run ((t (:foreground ,unzeit/fg-bright))))
 `(next-error ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg-bright :extend t))))
 `(anzu-match-1 ((t (:background ,unzeit/red :foreground ,unzeit/bg))))
 `(anzu-match-2 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/red))))
 `(anzu-match-3 ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-bright))))
 `(goggles-added ((t (:background ,unzeit/bg-subtle :foreground ,unzeit/fg))))
 `(goggles-removed ((t (:background ,unzeit/red-bg :foreground ,unzeit/fg-bright))))
 `(goggles-changed ((t (:background ,unzeit/bg-mid :foreground ,unzeit/fg-bright))))
 `(minibuffer-prompt-end ((t (:foreground ,unzeit/fg)))))
;;; custom-theme-set-faces ends here

;; 关闭上面的 `custom--inhibit-theme-enable' 覆盖
)

;; 一些包会查询这些 face 别名
(put 'unzeit 'theme-foreground-color unzeit/fg)
(put 'unzeit 'theme-background-color unzeit/bg)
(put 'unzeit 'theme-link-color unzeit/accent)
(put 'unzeit 'theme-success-color unzeit/fg)
(put 'unzeit 'theme-warning-color unzeit/popout)
(put 'unzeit 'theme-error-color unzeit/red)

(provide-theme 'unzeit)

;;; unzeit-theme.el ends here

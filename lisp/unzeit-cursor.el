;;; unzeit-cursor.el --- Unzeit: 光标拖尾与跳跃脉冲（纯 Elisp 动画层） -*- lexical-binding: t; -*-

;;; Commentary:
;; VS Code、Zed、Neovide 的光标动起来是带尾迹的。Emacs 的重绘引擎不会替
;; 我们做这件事，但它给的两样东西够用了：改一个覆盖层（overlay）的属性就能
;; 立刻变色，`post-command-hook' 能告诉你光标每次落在哪
;;
;; 于是有了两个效果：
;;
;;   拖尾  光标在同一处附近连续移动时，身后留下一串逐渐变暗的格子。走一步
;;         留一格余晖；一次跨过好几个字符（`meow-next-word' 之类）就把沿途
;;         每一格都点亮，出生时间按距离错开，于是尾巴自然地从新到旧暗下去，
;;         看起来像一颗彗星掠过
;;
;;   脉冲  光标跨行跳走时（搜索、xref、imenu、`M-<'……）在落点整行闪一下，
;;         回答「我这是跳到哪儿了」（这一半是 `beacon' 做的事，只是这里不引入
;;         依赖，颜色也直接跟着主题走）
;;
;; 两个效果其实是同一种东西：一串覆盖层 + 一套共同的衰减参数。差别只有铺一
;; 格还是铺一整行、最多留几格、以及什么时候触发，所以参数全收在
;; `unzeit/cursor--spec' 一张表里；绘制侧只剩三个纯粹做列表的函数——
;; `unzeit/cursor--spawn'（造一格）、`unzeit/cursor--fade'（按年龄重画一帧、
;; 顺手清掉过期的）、`unzeit/cursor--clip'（砍掉超额的旧格子）——状态就是
;; 两个普通的变量，好读也好 grep
;;
;; 手法：覆盖层没有 alpha 通道，所以「透明」是自己在 RGB 空间里混出来的
;; （`unzeit/cursor--blend'：底色按衰减系数向强调色插值）。好处是拖尾永远是
;; 「发光的背景」，底下的字还是原来的字，不会读不出来
;;
;; 开销：`post-command-hook' 里只做一次「点动没动」的比较；上色由一根定时器
;; 驱动，而且只在真的有东西要画时才存在（见 `unzeit/cursor--ensure-timer'），
;; 停下来就自己关掉，空闲时零开销
;;
;; 不做动画的几种情况，以及各自的判定依据：
;;   - 黑白终端与 batch：`display-color-p' 为 nil，画不出明暗
;;   - 打字/粘贴/撤销：这些命令改了 buffer 文字。身后拖一片光纯属干扰，
;;     判定靠 `buffer-chars-modified-tick'，不靠维护命令黑名单
;;   - 滚轮与 `C-v'：整屏都在动，再闪就成了频闪灯。判定靠命令上的
;;     `scroll-command' 属性，所以「光标自己走到窗口边缘顺带引起的滚动」
;;     不会被误伤
;;
;; 覆盖层优先级取 1：压得住 `hl-line'（-50），又低于 isearch 的 1000/1001，
;; 因此搜索命中不会被动画盖掉

;;; Code:

(require 'color)                        ; 只用于颜色名兜底（见 unzeit/cursor--rgb）

(defgroup unzeit-cursor nil
  "Unzeit 的光标动画：拖尾与跳跃脉冲。"
  :group 'unzeit)

;;; ---- 可调项 --------------------------------------------------------

(defcustom unzeit/cursor-trail-enabled t
  "是否为光标画拖尾。"
  :type 'boolean
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-pulse-enabled t
  "光标跨行跳走时是否在落点闪一下。"
  :type 'boolean
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-trail-length 12
  "拖尾最多保留多少格。
每格来自一次移动，所以这个数也就是彗尾最长能拖多长；同时也是一次
命令里「沿途铺满」的上限——超过这个距离就只留一格余晖，免得拉出一条
长彩带。"
  :type 'natnum
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-trail-lifetime 0.22
  "拖尾从最亮到完全消失所需的秒数。"
  :type 'number
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-trail-intensity 0.60
  "拖尾最亮处的不透明度（0~1）。
1.0 意味着刚离开的那一格完全用强调色填满，会盖住底下的文字，所以默认
留一点余地，让它读起来像「发光」而不是「色块」。"
  :type 'number
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-trail-falloff 1.4
  "拖尾亮度随年龄衰减的指数。越大，尾巴收得越快，越像彗星而不是涂抹。"
  :type 'number
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-pulse-intensity 0.22
  "跳跃脉冲最亮时的不透明度（0~1）。
它铺满一整行，所以要比拖尾克制得多。"
  :type 'number
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-pulse-lifetime 0.35
  "跳跃脉冲从最亮到消失所需的秒数。"
  :type 'number
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-pulse-falloff 2.0
  "跳跃脉冲的衰减指数。比拖尾收得更急，闪一下就走。"
  :type 'number
  :group 'unzeit-cursor)

(defcustom unzeit/cursor-interval 0.03
  "动画的重绘间隔（秒）。默认约 33 帧/秒，够顺滑，也不至于让 Emacs 忙着
重绘而影响输入响应。"
  :type 'number
  :group 'unzeit-cursor)

;;; ---- 状态 ----------------------------------------------------------

(defvar unzeit/cursor--trail nil
  "活动中的拖尾：动画格子 (覆盖层 . 出生时间) 的列表，最新的在前。")

(defvar unzeit/cursor--pulse nil
  "活动中的脉冲：格式同 `unzeit/cursor--trail'。")

(defvar unzeit/cursor--timer nil
  "驱动动画的定时器；没有东西要画时为 nil。")

(defvar unzeit/cursor--anchor nil
  "上一次命令结束时的 (BUFFER POINT 修改计数)，用来判断光标是否移动。")

(defvar unzeit/cursor--palette-cache nil
  "缓存的 (底色 . 强调色)，已解析成 0~1 的浮点三元组；换主题时清空。
每帧要给每一格上色，所以这两个颜色只解析一次。")

;; 真正的定义在文件末尾的 `define-minor-mode' 那里；这里提前声明一句，
;; 免得 `unzeit/cursor--active-p' 引用它时字节编译器把它当成自由变量
(defvar unzeit/cursor-mode)

;;; ---- 参数表（两个效果的差别全在这里）-------------------------------

(defun unzeit/cursor--spec (effect)
  "返回 EFFECT 这一层的衰减参数 plist。
拖尾和脉冲的差别就这三样：寿命与亮度、要不要铺满整行（:extend）、最多留
几格（:max）。参数现取现读，所以 Customize 改完立刻生效，不必重载。"
  (pcase effect
    ('trail (list :lifetime unzeit/cursor-trail-lifetime
                  :intensity unzeit/cursor-trail-intensity
                  :falloff unzeit/cursor-trail-falloff
                  :extend nil
                  :max unzeit/cursor-trail-length))
    ('pulse (list :lifetime unzeit/cursor-pulse-lifetime
                  :intensity unzeit/cursor-pulse-intensity
                  :falloff unzeit/cursor-pulse-falloff
                  :extend t
                  :max nil))))

;;; ---- 取色 ----------------------------------------------------------

(defun unzeit/cursor--palette ()
  "返回 (底色 . 强调色)，都是 0~1 的浮点三元组。
主题没加载时退回 face 属性，再不行给一对兜底值——动画不该因为取不到色
就报错。"
  (or unzeit/cursor--palette-cache
      (setq unzeit/cursor--palette-cache
            (cons (unzeit/cursor--rgb
                   (unzeit/cursor--theme-color 'unzeit/bg 'default "#101010"))
                  (unzeit/cursor--rgb
                   (unzeit/cursor--theme-color 'unzeit/accent 'cursor "#C83B27"))))))

(defun unzeit/cursor--theme-color (variable face fallback)
  "取一个主题颜色：优先调色板常量 VARIABLE，其次 FACE 的背景色，最后 FALLBACK。"
  (or (and (boundp variable) (symbol-value variable))
      (let ((color (ignore-errors (face-attribute face :background nil t))))
        (and (stringp color) color))
      fallback))

(defun unzeit/cursor--rgb (color)
  "把 COLOR 解析成 (R G B) 浮点三元组（各 0~1）。
十六进制自己解：`color-name-to-rgb' 在没有图形帧时会给出错误的近似值
（batch 下 \"#C83B27\" 会被解析成纯红色）。只有颜色名才交给它兜底。"
  (if (and (stringp color)
           (string-match
            "\\`#\\([[:xdigit:]]\\{2\\}\\)\\([[:xdigit:]]\\{2\\}\\)\\([[:xdigit:]]\\{2\\}\\)\\'"
            color))
      (list (/ (string-to-number (match-string 1 color) 16) 255.0)
            (/ (string-to-number (match-string 2 color) 16) 255.0)
            (/ (string-to-number (match-string 3 color) 16) 255.0))
    (or (ignore-errors (color-name-to-rgb color))
        '(0.5 0.5 0.5))))

(defun unzeit/cursor--blend (base glow alpha)
  "把 GLOW 按 ALPHA 叠到 BASE 上（两者都是浮点三元组），返回 \"#RRGGBB\"。
这就是覆盖层缺的那个 alpha 通道：手算一次线性插值。ALPHA 为 0 得到 BASE
（也就是看不见），为 1 得到 GLOW。"
  ;; `seq-mapn' 而不是 `mapcar'：后者的 C 实现只吃一个序列
  (apply #'unzeit/cursor--hex
         (seq-mapn (lambda (x y) (+ x (* alpha (- y x)))) base glow)))

(defun unzeit/cursor--hex (r g b)
  "把三个 0~1 的分量拼成 \"#RRGGBB\"（各自夹到 0~255）。"
  (format "#%02x%02x%02x"
          (max 0 (min 255 (round (* 255.0 r))))
          (max 0 (min 255 (round (* 255.0 g))))
          (max 0 (min 255 (round (* 255.0 b))))))

(defun unzeit/cursor--invalidate-colors (&rest _)
  "换主题后丢掉缓存的颜色（`enable-theme-functions' 上）。"
  (setq unzeit/cursor--palette-cache nil))

(add-hook 'enable-theme-functions #'unzeit/cursor--invalidate-colors)

;;; ---- 什么时候该动 --------------------------------------------------

(defun unzeit/cursor--active-p ()
  "这次命令要不要做动画。
只要所在帧是彩色的就画——GUI 帧和现代终端都算。用 `display-color-p' 而不是
`display-graphic-p'：终端帧一样能把明暗画出来（颜色会被终端调色板量化，
256 色以上够用了），而黑白终端和 batch 会被它挡掉。
minibuffer 里不画：vertico、corfu 在那儿高频重绘，加动画只会让人眼花。"
  (and unzeit/cursor-mode
       (display-color-p)
       (not (minibufferp))
       (not (window-minibuffer-p))))

(defun unzeit/cursor--scroll-p ()
  "当前命令是不是在滚动窗口。
Emacs 给滚动命令打了 `scroll-command' 属性（滚轮、`C-v'、`pixel-scroll'…
都是），所以这里不必维护命令黑名单。"
  (or (get this-command 'scroll-command)
      (memq this-command '(mwheel-scroll pixel-scroll-precision
                           recenter-top-bottom))))

(defun unzeit/cursor--local-p (from to)
  "FROM 到 TO 算不算「在同一处挪动」（相邻三行之内）。
只用一个行首/行尾的范围来判断，比 `line-number-at-pos' 便宜得多——后者在
大文件里要一路数换行，而这个最多扫三行。"
  (let ((low (max (point-min)
                  (save-excursion (goto-char from) (line-beginning-position 0))))
        (high (min (point-max)
                   (save-excursion (goto-char from) (line-end-position 2)))))
    (and (>= to low) (<= to high))))

;;; ---- 绘制（三个纯列表函数，状态由调用方持有）-------------------------

(defun unzeit/cursor--spawn (start end birth)
  "造一个覆盖 [START, END) 的动画格子，出生时间 BIRTH，返回 (覆盖层 . 出生时间)。
覆盖层先不带 face——上色统一交给 `unzeit/cursor--fade'，省得两处各算一遍
亮度。"
  (let ((overlay (make-overlay start end)))
    (overlay-put overlay 'unzeit-cursor t)
    ;; 优先级 1：压得住 hl-line（-50），又低于 isearch 的 1000/1001，
    ;; 这样搜索命中不会被动画盖掉
    (overlay-put overlay 'priority 1)
    (cons overlay birth)))

(defun unzeit/cursor--fade (cells now spec)
  "按年龄重画 CELLS，返回仍然存活的那些。
年龄到了 :lifetime 的覆盖层就地删除（buffer 被杀掉的也算）；其余的按
(1 - 年龄/寿命) ^ :falloff 衰减，把底色往强调色方向插值——越老越接近底色，
也就越看不见。"
  (let ((palette (unzeit/cursor--palette))
        (lifetime (plist-get spec :lifetime))
        (intensity (plist-get spec :intensity))
        (falloff (plist-get spec :falloff))
        (extend (plist-get spec :extend))
        (alive nil))
    (dolist (cell cells)
      (let ((overlay (car cell))
            (age (- now (cdr cell))))
        (if (or (>= age lifetime)
                (null (overlay-buffer overlay)))
            (when (overlayp overlay)
              (delete-overlay overlay))
          (let* ((life (max 0.0 (min 1.0 (- 1.0 (/ age lifetime)))))
                 (alpha (* intensity (expt life falloff))))
            (overlay-put overlay 'face
                         (list :extend extend
                               :background (unzeit/cursor--blend
                                            (car palette) (cdr palette) alpha))))
          (push cell alive))))
    (nreverse alive)))

(defun unzeit/cursor--clip (cells max)
  "砍掉 CELLS 里超出 MAX 的旧格子，返回留下的部分。
列表最新在前，所以砍的是尾部；被砍掉的覆盖层顺手删干净。"
  (let ((excess (- (length cells) max)))
    (if (<= excess 0)
        cells
      (dolist (cell (last cells excess))
        (let ((overlay (car cell)))
          (when (overlayp overlay) (delete-overlay overlay))))
      (butlast cells excess))))

(defun unzeit/cursor--ensure-timer ()
  "确保动画定时器在跑。"
  (unless (timerp unzeit/cursor--timer)
    (setq unzeit/cursor--timer
          (run-with-timer 0 unzeit/cursor-interval #'unzeit/cursor--tick-safe))))

(defun unzeit/cursor--stop-timer ()
  "停掉动画定时器。"
  (when (timerp unzeit/cursor--timer)
    (cancel-timer unzeit/cursor--timer))
  (setq unzeit/cursor--timer nil))

(defun unzeit/cursor--clear ()
  "删掉所有动画覆盖层并停表。"
  (unzeit/cursor--stop-timer)
  (dolist (cells (list unzeit/cursor--trail unzeit/cursor--pulse))
    (dolist (cell cells)
      (when (overlayp (car cell)) (delete-overlay (car cell)))))
  (setq unzeit/cursor--trail nil
        unzeit/cursor--pulse nil))

(defun unzeit/cursor--tick ()
  "重画一帧；没有东西可画时顺手把定时器关掉。"
  (let ((now (float-time)))
    (setq unzeit/cursor--trail
          (unzeit/cursor--fade unzeit/cursor--trail now
                               (unzeit/cursor--spec 'trail)))
    (setq unzeit/cursor--pulse
          (unzeit/cursor--fade unzeit/cursor--pulse now
                               (unzeit/cursor--spec 'pulse)))
    (unless (or unzeit/cursor--trail unzeit/cursor--pulse)
      (unzeit/cursor--stop-timer))))

(defun unzeit/cursor--tick-safe ()
  "定时器回调。
动画出问题不该打断编辑，但也不能每 30 毫秒静默报错一次，所以出错就收摊
并说明原因，让人知道动画已经停了。"
  (condition-case err
      (unzeit/cursor--tick)
    (error
     (unzeit/cursor--clear)
     (message "unzeit-cursor：动画已停止（%S）" err))))

;;; ---- 两个效果的触发 ------------------------------------------------

(defun unzeit/cursor--path (from to)
  "返回 FROM → TO 这段移动该留下的位置，最旧的在前。
跨了好几个字符、又没远到该交给脉冲时，把沿途每一格都算上；否则只留 FROM
一处余晖。"
  (let ((span (abs (- to from))))
    (if (and (> span 1) (<= span unzeit/cursor-trail-length))
        (let ((step (if (< from to) 1 -1))
              (path nil))
          (dotimes (i span)
            (push (+ from (* i step)) path))
          (nreverse path))
      (list from))))

(defun unzeit/cursor--streak (from to)
  "返回 FROM → TO 该留下的格子：(START END BIRTH) 的列表，最旧的在前。
出生时间按距离错开，于是离 TO 越远的格子越老、越暗，整条尾巴自然呈现出
从新到旧的梯度，而不是一根亮度均匀的色条。"
  (let* ((now (float-time))
         (positions (unzeit/cursor--path from to))
         (count (length positions))
         ;; 错开量固定按「满格」算，而不是按本次实际格数：这样同样一段距离，
         ;; 不管跨了几格，整条尾巴的明暗节奏是一致的
         (stagger (/ unzeit/cursor-trail-lifetime
                     (float (1+ unzeit/cursor-trail-length)))))
    (seq-map-indexed
     (lambda (pos index)
       (list pos (min (1+ pos) (point-max))
             (- now (* (- count 1 index) stagger))))
     positions)))

(defun unzeit/cursor--trail-push (from to)
  "在上一处落点 FROM 与当前落点 TO 之间留下拖尾。"
  (when unzeit/cursor-trail-enabled
    (let ((cells unzeit/cursor--trail))
      (dolist (cell (unzeit/cursor--streak from to))
        (push (apply #'unzeit/cursor--spawn cell) cells))
      (setq unzeit/cursor--trail
            (unzeit/cursor--clip cells unzeit/cursor-trail-length)))
    ;; 这里刻意不调 `unzeit/cursor--fade'：上色交给定时器。
    ;; 一条命令画一帧的话，连按十次就白画十遍（中间的渐变谁也看不见），
    ;; 实测每次按键要多吃 1.6ms。交给定时器之后，连按期间一帧不画，手一停，
    ;; 第一帧就按各自的真实年龄把整条尾巴一次画对——既省又更准
    (unzeit/cursor--ensure-timer)))

(defun unzeit/cursor--pulse-push ()
  "在光标当前所在行闪一下。
「铺满整行」由参数表里的 :extend 负责，字后面那段空白才会跟着亮，否则
闪光看着像被截断。"
  (when unzeit/cursor-pulse-enabled
    (push (unzeit/cursor--spawn (line-beginning-position)
                                (line-beginning-position 2)
                                (float-time))
          unzeit/cursor--pulse)
    (unzeit/cursor--ensure-timer)))

;;; ---- 挂钩子 --------------------------------------------------------

(defun unzeit/cursor--post-command ()
  "记下光标落点，并在它移动后触发拖尾或脉冲。"
  (when (unzeit/cursor--active-p)
    (let ((buf (current-buffer))
          (pt (point))
          (tick (buffer-chars-modified-tick)))
      (with-demoted-errors "unzeit-cursor: %S"
        (pcase unzeit/cursor--anchor
          (`(,prev-buf ,prev-pt ,prev-tick)
           ;; 三个条件缺一不可：同一个 buffer、这次命令没改动文字、光标确实
           ;; 挪了窝。打字/粘贴/撤销都会动 tick，于是自动被排除；滚轮和 C-v
           ;; 则靠 `scroll-command' 属性排除
           (when (and (eq prev-buf buf)
                      (= prev-tick tick)
                      (/= prev-pt pt)
                      (not (unzeit/cursor--scroll-p)))
             (if (unzeit/cursor--local-p prev-pt pt)
                 (unzeit/cursor--trail-push prev-pt pt)
               (unzeit/cursor--pulse-push))))))
      (setq unzeit/cursor--anchor (list buf pt tick)))))

;;;###autoload
(define-minor-mode unzeit/cursor-mode
  "全局次模式：给光标加上拖尾与跳跃脉冲（见本文件 Commentary）。
GUI 帧和彩色终端都能画；黑白终端与 batch 下自动静默。"
  :global t
  :group 'unzeit-cursor
  (if unzeit/cursor-mode
      (add-hook 'post-command-hook #'unzeit/cursor--post-command 'append)
    (remove-hook 'post-command-hook #'unzeit/cursor--post-command)
    (setq unzeit/cursor--anchor nil)
    (unzeit/cursor--clear)))

;;;###autoload
(defun unzeit/cursor-toggle ()
  "开关光标动画（SPC c a），并在回显区说明结果。
包一层是为了 which-key 里显示这句短说明，而不是 `unzeit/cursor-mode'
那段较长的 docstring。"
  (interactive)
  (unzeit/cursor-mode 'toggle)
  (message "光标动画：%s" (if unzeit/cursor-mode "开" "关")))

(provide 'unzeit-cursor)
;;; unzeit-cursor.el ends here

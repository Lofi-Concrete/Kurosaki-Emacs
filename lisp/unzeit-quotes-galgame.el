;;; unzeit-quotes-galgame.el --- 主屏语录：Galgame 日语原句 -*- lexical-binding: t; -*-

;;; Commentary:
;; 来源：知乎台词帖，只收能核实日文原句的 24 条；格式 ("日语原句" "《作品》")。
;;; Code:

;;; --- quotes-begin（下面这块由 .tmp/gen_elisp.py 生成，别手改）---
(defconst unzeit/galgame-quotes
  '(
    ("人間はね、思い出がないと生きていけないんだよ。\nでもね、それなのに…思い出だけでは生きていけない"
     "AIR")
    ("地球に私も含まれますか？\nお前が地球の中心だ"
     "ATRI -My Dear Moments-")
    ("「一昨日は兎をみたの。昨日は鹿。今日はあなた」"
     "CLANNAD")
    ("「泣いていいのは、おトイレかパパの胸の中」"
     "CLANNAD")
    ("わからないことがあるから、希望を持てるのかもな・・・"
     "Rewrite")
    ("忘れないで\nあなたはどの世界線にいてもひとりじゃない\n私がいる"
     "STEINS;GATE")
    ("「あなたは、治せる人を直してあげてね。わたしの傷はもう…あなたには専門外だから」"
     "WHITE ALBUM2")
    ("あたしが、先だった…先だったんだ…キスしたのも、抱き合ったのも。そいつのこと好きになったのも。"
     "WHITE ALBUM2")
    ("この世に奇跡ってものは存在しない。あるのは偶然と必然、そして誰が何をしたか。それだけだ"
     "ef - a fairy tale of the two.")
    ("もしも……今、わたしが海に入っていったなら……あなた止める?"
     "narcissu")
    ("あんたの悪いところは100個言える\nだけど、いいところは101個言える"
     "アマガミ")
    ("この世界は、前を向けば「未来」、振り向けば「思い出」、どこか一部を切り取れば「物語」となる。"
     "グリザイアの果実")
    ("薄っぺらな天才は、才能が透けて見える。\n天才は、才能を忘れさせる"
     "サクラノ詩 -櫻の森の上を舞う-")
    ("明日失うとわかっているなら、その日が一番幸せなんだ。"
     "塵骸魔京")
    ("「他人の好意は楽を与えてくれる、けれど、楽は慣れてしまうもの、慣れてしまえば他人の好意が当然となってしまう。そうして楽はいつしか怠惰を産み落とす、私はそれが恐ろしい。」"
     "天使の羽根を踏まないでっ")
    ("「それはね、その砂漠に――たった一人だけでも、花を愛してくれる人がいるって知ったとき。」"
     "沙耶の唄")
    ("「無知ゆえの無為は許されると思う」\n「だが、知った上での無為は罪だ」"
     "穢翼のユースティア")
    ("「絶望とは、幸福の中で溺れる事が出来る人にだけ与えられた特権だな\nだからこそ人は言葉を手に入れた\n空を美しいと感じた。よき世界になれと祈れるようになった\n言葉と美しさと祈り\n三つの力とともに、素晴らしい日々を手に入れた。\n人よ、幸福たれ！」"
     "素晴らしき日々～不連続存在～")
    ("「愚者は平等と言う！」\n「しかし皆知っている、世界が平等でない事を」\n「愚者は自由と言う！」\n「しかし皆知っている、世界に自由がない事を」\n「愚者は愛と言う！」\n「しかし皆知っている、愛が人を裏切る事を」\n「愚者は人を殺すなと言う！」\n「しかし皆知っている、世界が殺人で満ちている事を」\n「愚者は嘘を付くなと言う！」\n「しかし皆知っている、愚者こそが嘘付きである事を」\n「愚者の嘘を鵜のみにした者は馬鹿をみる」"
     "素晴らしき日々～不連続存在～")
    ("「やっぱり……いい女には、たばこと屋上と……そしてヒラヒラ服だわね……」"
     "素晴らしき日々～不連続存在～")
    ("「ボクたちはただ名ばかりでシャボン玉の様にふくらんでしまった……\nそんな空想の恋人に恋いこがれている……。\nさぁ、君、取りたまえ。」"
     "素晴らしき日々～不連続存在～")
    ("「鬼に逢うては鬼を斬る 仏に逢うては仏を斬る ツルギの理ここに在り」"
     "装甲悪鬼村正")
    ("「万物は流転する。そこに多少の善悪があろうとも、今日も太陽は東から昇ってくる。」\n「それはまるで…車輪のように。」"
     "車輪の国、向日葵の少女")
    ("「…そこをどけ豚共。私はこれから最愛の人に、会いに行かねばぁならんのだ…！！」"
     "車輪の国、向日葵の少女")
    )
  "主屏语录：galgame 日语原句 ＋ 作品名。
每条都在日文页面核对过（出处见 git 历史）。")
;; 出处：逐条核对页（24 条日文原句）留在 2026-11 前的 git 历史；格式 ("日语原句" "《作品》")。

(defcustom unzeit/galgame-quotes-width 64
  "语录折行的最大列数（CJK 算两列）。"
  :group 'unzeit
  :type 'integer)

(defconst unzeit/galgame-quotes--no-line-start
  (string-to-list "、。，．・：；？！゛゜ヽヾゝゞ々ー）」』】〕〉》”’…‥ぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮ")
  "不能出现在行首的字符（简易禁则）。")

(defconst unzeit/galgame-quotes--no-line-end
  (string-to-list "（「『【〔〈《“‘")
  "不能出现在行尾的字符（简易禁则）。")

(defun unzeit/galgame-quotes--wrap (line width)
  "把 LINE 折成每行不超过 WIDTH 列，带极简禁则。"
  (if (<= (string-width line) width)
      (list line)
    (let ((lines nil)
          (cur "")
          (cur-width 0))
      (dolist (ch (string-to-list line))
        (let* ((s (char-to-string ch))
               (w (string-width s)))
          (when (and (> (+ cur-width w) width)
                     (> (length cur) 0))
            ;; 句读/小假名不落行首：宁可让这一行「追い込み」多出一两格
            (unless (memq ch unzeit/galgame-quotes--no-line-start)
              ;; 开引号不落行尾：把行尾那些开引号挪到下一行
              (let ((carry ""))
                (while (and (> (length cur) 0)
                            (memq (aref cur (1- (length cur)))
                                  unzeit/galgame-quotes--no-line-end))
                  (setq carry (concat (char-to-string
                                       (aref cur (1- (length cur))))
                                      carry)
                        cur (substring cur 0 -1)))
                (setq cur-width (string-width cur))
                (when (> (length cur) 0)
                  (push cur lines))
                (setq cur carry
                      cur-width (string-width carry)))))
          (setq cur (concat cur s)
                cur-width (+ cur-width w))))
      (when (> (length cur) 0)
        (push cur lines))
      (nreverse lines))))

(defun unzeit/galgame-quotes--usable-width ()
  "给语录折行用的列数：窗口宽度留出边距，再受 `unzeit/galgame-quotes-width' 限制。"
  (let ((win (cond ((and (fboundp 'window-body-width) (windowp (selected-window)))
                    (floor (window-body-width nil t)))
                   ((and (fboundp 'frame-width) (framep (selected-frame)))
                    (frame-width))
                   (t unzeit/galgame-quotes-width))))
    (max 24 (min unzeit/galgame-quotes-width (- win 12)))))

(defcustom unzeit/galgame-quotes-max-lines 5
  "一条语录最多显示几行正文。"
  :group 'unzeit
  :type 'integer)

(defun unzeit/galgame-quotes--format (entry)
  "把一条语录 ENTRY 排版成多行文本：正文折行、超长截断，末行右对齐标出处。"
  (let* ((jp (car entry))
         (src (cadr entry))
         (width (unzeit/galgame-quotes--usable-width))
         (lines (mapcan (lambda (l) (unzeit/galgame-quotes--wrap l width))
                        (split-string jp "\n" t)))
         (lines (if (> (length lines) unzeit/galgame-quotes-max-lines)
                    (let ((kept (butlast lines (- (length lines)
                                                  unzeit/galgame-quotes-max-lines))))
                      (append (butlast kept)
                              (list (concat (car (last kept)) "……"))))
                  lines))
         (attr (concat "—— 『" src "』"))
         (block (max (apply #'max (mapcar #'string-width lines))
                     (string-width attr))))
    (concat (mapconcat #'identity lines "\n")
            "\n"
            (make-string (max 0 (- block (string-width attr))) ?\s)
            attr)))

(defun unzeit/galgame-quotes-random ()
  "随机取一条语录并排版；列表为空时返回 nil。"
  (when unzeit/galgame-quotes
    (unzeit/galgame-quotes--format
     (nth (random (length unzeit/galgame-quotes)) unzeit/galgame-quotes))))

(provide 'unzeit-quotes-galgame)
;;; unzeit-quotes-galgame.el ends here

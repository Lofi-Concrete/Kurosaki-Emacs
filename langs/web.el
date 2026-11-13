;;; web.el --- Unzeit: HTML / CSS / 网页模板 -*- lexical-binding: t; -*-

(unzeit/treesit-source 'css "https://github.com/tree-sitter/tree-sitter-css")
(unzeit/treesit-source 'html "https://github.com/tree-sitter/tree-sitter-html")

(unzeit/remap-mode 'css-mode 'css-ts-mode)
(unzeit/remap-mode 'html-mode 'mhtml-ts-mode)

(use-package mhtml-ts-mode
  :ensure nil
  :defer t
  :mode (("\\.html?\\'" . mhtml-ts-mode))
  :hook
  (mhtml-ts-mode
   . (lambda ()
       (remove-hook 'flymake-diagnostic-functions
                    #'mhtml-ts-mode-flymake-mhtml t))))

(unzeit/define-on-demand-mode web-mode web-mode
                              '("\\.njk\\'" "\\.j2\\'" "\\.erb\\'" "\\.hbs\\'"))

(use-package web-mode
  :ensure nil
  :defer t
  :custom
  (web-mode-enable-control-block-indentation nil))

;;; ---- JSP：web-mode 的 jsp 引擎 + 独立主模式 -----------------------
;; 为什么单独一个 jsp-mode：eglot 按**主模式**记 managed-modes，若把 web-mode 登记给 html server，开过 JSP 后同项目 ERB/Jinja 也被接管；兄弟模式不会连带。
(with-eval-after-load 'web-mode
  (define-derived-mode jsp-mode web-mode "JSP"
    "JSP 文件：web-mode 的 JSP 引擎 + HTML language server。"
    (setq-local web-mode-engine "jsp")))

(unzeit/define-on-demand-mode jsp-mode web-mode '("\\.jsp\\'" "\\.jspf\\'"))

;; JSP 接 html-language-server：内嵌 `<style>`/`<script>` 由它自带服务补全，`<% … %>` 当普通文本
;; （用 index.jsp 实测 0 条诊断）。
(unzeit/eglot-server
 '(((html-ts-mode :language-id "html")
    (mhtml-ts-mode :language-id "html")
    (html-mode :language-id "html")
    (jsp-mode :language-id "html"))
   "vscode-html-language-server" "--stdio"
   :initializationOptions
   (:embeddedLanguages (:css t :javascript t))))

(unzeit/apheleia-mode '((css-ts-mode . (prettier-css))
                        (html-mode . (prettier-html))))

;;; ---- JSP 标签名补全（没有 JSP LSP，只能自己补）--------------------
;; 只匹配**已打出冒号**的前缀（`<c:` 才轮到这张表，`<h` 仍归 html-ls）；Java scriptlet/EL 没有开源 LSP，要补全就把逻辑放回 .java。
(defconst unzeit/jsp-tag-names
  '("c:forEach" "c:if" "c:choose" "c:when" "c:otherwise" "c:out" "c:set"
    "c:remove" "c:url" "c:param" "c:import" "c:redirect" "c:catch"
    "fmt:formatDate" "fmt:formatNumber" "fmt:message" "fmt:setBundle"
    "fmt:setLocale" "fn:length" "fn:contains" "fn:escapeXml" "fn:join"
    "jsp:include" "jsp:forward" "jsp:useBean" "jsp:setProperty"
    "jsp:getProperty" "spring:url" "spring:message" "spring:escapeBody"
    "form:form" "form:input" "form:password" "form:hidden" "form:errors"
    "sec:authorize")
  "JSP 里常用的 JSTL / JSP 标准动作 / Spring 标签名。")

(defun unzeit/jsp-tag-capf ()
  "在 JSP 的 `<c:` / `<fmt:` 之类前缀后补标签名。"
  (when (and (derived-mode-p 'jsp-mode)
             (looking-back "<\\([[:alnum:]_.-]+:\\)"
                           (max (point-min) (- (point) 200))))
    (let* ((beg (match-beginning 1))
           (prefix (match-string 1))
           (names (seq-filter (lambda (s) (string-prefix-p prefix s))
                              unzeit/jsp-tag-names)))
      (when names
        (list beg (point) names :exclusive 'no)))))

(defun unzeit/jsp-capf-setup ()
  "JSP 缓冲里挂上 `unzeit/jsp-tag-capf'。
★ eglot 接管后会把 `completion-at-point-functions' 整个换掉，所以 hook 里也要再挂一次。"
  (when (derived-mode-p 'jsp-mode)
    (add-hook 'completion-at-point-functions #'unzeit/jsp-tag-capf 5 t)))

(add-hook 'jsp-mode-hook #'unzeit/jsp-capf-setup)
;; ★ 必须 append 到 eglot-managed-mode-hook 末尾：`unzeit/eglot-capf` 会先把
;;   completion-at-point-functions 整个换成 cape-capf-super，早跑就被覆盖。
(add-hook 'eglot-managed-mode-hook #'unzeit/jsp-capf-setup t)


;;; ---- SCSS：经典 scss-mode + vscode-css-language-server -----------------
(unzeit/define-on-demand-mode scss-mode scss-mode "\\.scss\\'")

(unzeit/eglot-server
 '(((scss-mode :language-id "scss"))
   "vscode-css-language-server" "--stdio"))

(unzeit/apheleia-mode '((scss-mode . (prettier-css))))

(provide 'unzeit-lang-web)
;;; web.el ends here

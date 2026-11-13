;;; java.el --- Unzeit: Java -*- lexical-binding: t; -*-

(unzeit/treesit-source 'java "https://github.com/tree-sitter/tree-sitter-java")

(unzeit/remap-mode 'java-mode 'java-ts-mode)

;;; ---- jdtls 路径与初始化参数 --------------------------------------

(defvar unzeit/jdtls-install-dir (expand-file-name "~/.local/opt/jdtls")
  "手装的 eclipse.jdt.ls（milestone 解包目录，含 plugins/ 与 config_linux/）。")

(defvar unzeit/jdtls-debug-bundle
  (expand-file-name "bundles/com.microsoft.java.debug.plugin-0.53.1.jar"
                    unzeit/jdtls-install-dir)
  "java-debug 的 DAP adapter（GitHub 的 0.53.2 没有二进制资产，Central 最新 0.53.1）；
java-server 的 HCR / dape 挂接靠它作为 jdtls 的 bundle 载入。")

(defvar unzeit/jdtls-runtime-home
  (or (getenv "JAVA_HOME") (expand-file-name "~/.sdkman/candidates/java/current"))
  "jdtls 用的运行时 JDK（必须 21+，本机是 sdkman 的 26）。")

(defvar unzeit/jdtls-runtime-name "JavaSE-1.8"
  "把这个唯一的 JDK 注册成 JavaSE-1.8，只为消掉 JDT 的
「Build path specifies … there are no JREs…」；真正的字节码版本由 pom 的 maven.compiler.release 决定。")

(defvar unzeit/jdtls-workspace (expand-file-name "~/.cache/jdtls")
  "jdtls 的 -data 工作区（每个工作区一份 .metadata，放 cache 里免得污染家目录）。")

(defun unzeit/jdtls-init-opts (_server _jdt-class)
  "交给 `eglot-java-user-init-opts-fn' 的初始化选项（plist）。
eglot-java 用**浅合并**（`eglot-java--plist-merge'），:settings 必须整段写全 —— 否则连 java.home 一起丢，故显式补回。"
  `(:bundles
    ,(when (file-exists-p unzeit/jdtls-debug-bundle)
       (vector unzeit/jdtls-debug-bundle))
    :settings
    (:java
     (:home ,unzeit/jdtls-runtime-home
      :configuration (:runtimes [(:name ,unzeit/jdtls-runtime-name
                                     :path ,unzeit/jdtls-runtime-home
                                     :default t)])
      :import (:maven (:enabled t) :gradle (:enabled :json-false))
      :maven (:downloadSources t)
      :references (:includeDecompiledSources t)
      :completion (:maxResults 50)))))

(defun unzeit/jdtls-contact (&rest _)
  "返回 eglot 用的 jdtls contact。
能 require 到 eglot-java 就用 `eglot-java-eclipse-jdt'（带 `java.apply.workspaceEdit' 修正），否则退回普通列表并把选项挂 `:initializationOptions'。"
  (let* ((jdtls unzeit/jdtls-install-dir)
         (launcher (car (directory-files
                         (expand-file-name "plugins" jdtls) t
                         "org\\.eclipse\\.equinox\\.launcher_.*\\.jar$")))
         (config (expand-file-name "config_linux" jdtls))
         (workspace unzeit/jdtls-workspace)
         (program (or (executable-find "java") "java"))
         (args (list "-Declipse.application=org.eclipse.jdt.ls.core.id1"
                     "-Dosgi.bundles.defaultStartLevel=4"
                     "-Declipse.product=org.eclipse.jdt.ls.core.product"
                     "-Xmx1G"
                     "--add-modules=ALL-SYSTEM"
                     "--add-opens" "java.base/java.util=ALL-UNNAMED"
                     "--add-opens" "java.base/java.lang=ALL-UNNAMED"
                     "-jar" launcher "-configuration" config "-data" workspace)))
    (make-directory workspace t)
    (if (require 'eglot-java nil t)
        (progn
          ;; jdt:// 源码跳转的补丁；已打过就自己短路（内部有 applied 标志）
          (ignore-errors (eglot-java--init))
          (cons 'eglot-java-eclipse-jdt (cons program args)))
      (append (cons program args)
              (list :initializationOptions (unzeit/jdtls-init-opts nil nil))))))

(unzeit/eglot-server '((java-ts-mode java-mode) . unzeit/jdtls-contact))

;;; ---- eglot-java：Maven 项目 / 构建 / 运行 / 测试 ------------------

(use-package eglot-java
  :ensure t
  :defer t
  :hook (java-ts-mode . eglot-java-mode)
  :custom
  (eglot-java-eglot-server-programs-manual-updates t)
  (eglot-java-server-install-dir unzeit/jdtls-install-dir)
  (eglot-java-user-init-opts-fn #'unzeit/jdtls-init-opts)
  (eglot-java-workspace-folder (expand-file-name "~/Projects"))
  (eglot-java-maven-repo-root-url "https://maven.aliyun.com/repository/public"))

;;; ---- java-server：Tomcat 调试挂接 + 热替换（可选层）---------------
(use-package java-server
  :vc (:url "https://github.com/LuciusChen/java-server"
            :rev "69d54bf185d6c9a61470f1636c48700058926a43")
  :defer t
  :commands (java-server-hot-replace java-server-tomcat-stop
                                     java-server-select-jdk java-server-auto-select-jdk)
  :custom
  (java-server-tomcat-instances-dir (expand-file-name "~/.cache/java-server/tomcat/"))
  (java-server-debug-adapters-dir (expand-file-name "~/.cache/java-server/debug-adapters/"))
  (java-server-tomcat-sync-classes-on-hcr t))

;;; ---- 修 jdt:// 源码跳转（上游不认"能找到源码"时的 URI 形状）--------

(defun unzeit/jdt-uri-handler (_operation &rest args)
  "处理 jdtls 的 `jdt://' URI：把类源码落到项目根的 .eglot-java/ 下再打开。
★ `eglot-java--jdt-uri-handler' 只认 `.../<Class>.class?<query>'，开了 downloadSources 后返回 `.../<Class>.java?<query>'（实测都不匹配 → `M-.' 报错）；两种都要认，`.java?' **先判**。"
  (let* ((uri (car args))
         (cache-dir (expand-file-name ".eglot-java"
                                      (project-root (project-current t))))
         (rel (save-match-data
                (cond
                 ((string-match "jdt://contents/[^/]+/\\(.*?\\)\\.java\\?" uri)
                  (match-string 1 uri))
                 ((string-match "jdt://contents/[^/]+/\\(.*\\)\\.class" uri)
                  (match-string 1 uri)))))
         (source-file (when rel
                        (expand-file-name
                         (concat (replace-regexp-in-string "/" "." rel t t) ".java")
                         cache-dir))))
    (unless rel
      (error "Unzeit：看不懂的 jdt:// URI（jdtls 又换形状了？）：%s" uri))
    (if (file-readable-p source-file)
        source-file
      (let ((content (jsonrpc-request (eglot-java--find-server)
                                      :java/classFileContents (list :uri uri)))
            (metadata-file (format "%s.%s.metadata"
                                   (file-name-directory source-file)
                                   (file-name-base source-file))))
        (unless (file-directory-p cache-dir) (make-directory cache-dir t))
        (with-temp-file source-file (insert content))
        (with-temp-file metadata-file (insert uri))
        source-file))))

(with-eval-after-load 'eglot-java
  (add-to-list 'file-name-handler-alist
               (cons "\\`jdt://" #'unzeit/jdt-uri-handler))
  ;; IDEA 手感：C-c C-r 运行 main、C-c C-t 跑测试、C-c C-d 起 dape（内置 jdtls 适配器）；
  ;; eglot-java 只提供命令、不绑键。
  (define-key eglot-java-mode-map (kbd "C-c C-r") #'eglot-java-run-main)
  (define-key eglot-java-mode-map (kbd "C-c C-t") #'eglot-java-run-test)
  (define-key eglot-java-mode-map (kbd "C-c C-d") #'dape))

(provide 'unzeit-lang-java)
;;; java.el ends here

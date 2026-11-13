;;; servlet.el --- Unzeit: Maven Web / Tomcat 9 工作流 -*- lexical-binding: t; -*-

(require 'project)

;;; ---- Maven 项目后端（project.el）----------------------------------
;; 内建项目后端只认 VC，Maven 目录常没有 .git（实测 web-course 就是裸 pom.xml）；放列表末尾，有 git 的仍优先 VC（懂 .gitignore）。
(defun unzeit/maven-project-try (dir)
  "把含 pom.xml 的目录识别成 project.el 项目。"
  (when-let* ((root (locate-dominating-file dir "pom.xml")))
    (cons 'transient (file-name-as-directory (expand-file-name root)))))
(add-to-list 'project-find-functions #'unzeit/maven-project-try t)

(defvar unzeit/servlet-catalina-home (expand-file-name "~/.local/opt/tomcat9")
  "Tomcat 9 安装目录（CATALINA_HOME，只当模板读，不被写）。")

(defvar unzeit/servlet-base-root (expand-file-name "~/.cache/tomcat-base/")
  "每个项目一个隔离 CATALINA_BASE 的根目录。
刻意放 ~/.cache 而不是项目里：项目树只留 pom/源码，不塞 Tomcat 的运行时垃圾。")

(defvar unzeit/servlet-http-port 8080)
(defvar unzeit/servlet-shutdown-port 8005)

(defun unzeit/servlet-root-soft ()
  "当前项目根，不在项目里返回 nil（给 after-save-hook 用，别在存盘时抛错）。
★ 不能只靠 `project-current'：VC 系后端认不出无 git 的 Maven 目录，再兜一层从 `default-directory' 往上找 pom.xml。"
  (or (ignore-errors (when-let* ((p (project-current))) (project-root p)))
      (when-let* ((d (locate-dominating-file default-directory "pom.xml")))
        (expand-file-name d))))

(defun unzeit/servlet-root ()
  "当前项目根；不在项目里就报错。"
  (or (unzeit/servlet-root-soft)
      (user-error "Unzeit：不在 Maven 项目里（%s 往上找不到 pom.xml）"
                  default-directory)))

;;; ---- 新建 Maven Web 项目（不用手写 pom / 建目录）------------------

(defvar unzeit/servlet-default-group-id "cn.edu.course")
(defvar unzeit/servlet-default-artifact-id "my-webapp")

(defun unzeit/servlet--fill (template values)
  "把 TEMPLATE 里的 @KEY@ 换成 VALUES 里的值（alist）。"
  (let ((s template))
    (dolist (pair values s)
      (setq s (replace-regexp-in-string
               (regexp-quote (format "@%s@" (car pair)))
               (cdr pair) s t t)))))

(defun unzeit/servlet--put (file content)
  "写 FILE，父目录不存在就一起建。"
  (make-directory (file-name-directory file) t)
  (with-temp-file file (insert content)))

(defconst unzeit/servlet-pom-template
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<project xmlns=\"http://maven.apache.org/POM/4.0.0\"
         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd\">
  <modelVersion>4.0.0</modelVersion>
  <groupId>@GROUP@</groupId>
  <artifactId>@ARTIFACT@</artifactId>
  <version>1.0-SNAPSHOT</version>
  <packaging>war</packaging>
  <name>@ARTIFACT@</name>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    <!-- 课程要 Java 8 的产物；本机 JDK 26 用 compiler release=8 产出 major 52 -->
    <maven.compiler.release>8</maven.compiler.release>
  </properties>

  <dependencies>
    <!-- Tomcat 9 自带，必须 provided -->
    <dependency>
      <groupId>javax.servlet</groupId>
      <artifactId>javax.servlet-api</artifactId>
      <version>4.0.1</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>javax.servlet.jsp</groupId>
      <artifactId>javax.servlet.jsp-api</artifactId>
      <version>2.3.3</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>javax.servlet</groupId>
      <artifactId>jstl</artifactId>
      <version>1.2</version>
      <!-- jstl 1.2 会把 servlet-api 2.5 拖进 WEB-INF/lib，Tomcat 9 禁止 -->
      <exclusions>
        <exclusion>
          <groupId>javax.servlet</groupId>
          <artifactId>servlet-api</artifactId>
        </exclusion>
      </exclusions>
    </dependency>
  </dependencies>

  <build>
    <finalName>@FINAL@</finalName>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.13.0</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-war-plugin</artifactId>
        <version>3.4.0</version>
      </plugin>
    </plugins>
  </build>
</project>
"
  "Maven Web 项目的 pom 模板。")

(defconst unzeit/servlet-webxml-template
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<web-app xmlns=\"http://xmlns.jcp.org/xml/ns/javaee\"
         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
         xsi:schemaLocation=\"http://xmlns.jcp.org/xml/ns/javaee
                             http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd\"
         version=\"4.0\">
  <display-name>@ARTIFACT@</display-name>
  <!-- Servlet 用 @WebServlet 注解声明；这里只定欢迎页 -->
  <welcome-file-list>
    <welcome-file>index.jsp</welcome-file>
  </welcome-file-list>
</web-app>
"
  "Servlet 4.0 的 web.xml 模板（Tomcat 9 用 javax）。")

(defconst unzeit/servlet-jsp-template
  "<%@ page contentType=\"text/html;charset=UTF-8\" language=\"java\" pageEncoding=\"UTF-8\" %>
<!DOCTYPE html>
<html lang=\"zh\">
<head>
  <meta charset=\"UTF-8\">
  <title>@ARTIFACT@</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 3rem auto; }
    code { background: #f2f2f2; padding: 0 .3em; }
  </style>
</head>
<body>
  <h1>@ARTIFACT@ 已启动</h1>

  <%-- 改 JSP 存盘后刷新浏览器，时间戳应立刻变化（Tomcat 自动重编译 JSP） --%>
  <p>JSP 编译时间：<%= new java.text.SimpleDateFormat(\"yyyy-MM-dd HH:mm:ss.SSS\").format(new java.util.Date()) %></p>

  <ul>
    <li><a href=\"hello\">HelloServlet（@WebServlet(\"/hello\")）</a></li>
    <li><a href=\"hello?name=Emacs\">带参数：hello?name=Emacs</a></li>
  </ul>
</body>
</html>
"
  "首页 JSP 模板。")

(defconst unzeit/servlet-java-template
  "package @PACKAGE@;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * @ARTIFACT@ 的示例 Servlet。
 *
 * <p>改 GREETING → C-c J c（mvn compile）→ 约 0.35 秒后刷新页面，
 * 用来验证 Tomcat 的 reloadable 热重载。
 */
@WebServlet(\"/hello\")
public class HelloServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** 改这一行的值来验证热 reload。 */
    private static final String GREETING = \"@ARTIFACT@ v1\";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType(\"text/html;charset=UTF-8\");

        String name = req.getParameter(\"name\");
        if (name == null || name.trim().isEmpty()) {
            name = \"同学\";
        }

        String now = LocalDateTime.now()
                .format(DateTimeFormatter.ofPattern(\"yyyy-MM-dd HH:mm:ss\"));

        try (PrintWriter out = resp.getWriter()) {
            out.println(\"<!DOCTYPE html>\");
            out.println(\"<html lang=\\\"zh\\\"><head><meta charset=\\\"UTF-8\\\">\");
            out.println(\"<title>\" + GREETING + \"</title></head><body>\");
            out.println(\"<h1>\" + GREETING + \"</h1>\");
            out.println(\"<p>你好，\" + name + \"。服务器时间：\" + now + \"</p>\");
            out.println(\"<p><a href=\\\"index.jsp\\\">回首页</a></p>\");
            out.println(\"</body></html>\");
        }
    }
}
"
  "示例 Servlet 模板（Servlet 4.0 / javax，Tomcat 9）。")

(defconst unzeit/servlet-gitignore-template
  "# Maven
target/

# 依赖 jar 是 mvn dependency:copy-dependencies 拷进来的，不是源码
src/main/webapp/WEB-INF/lib/

# 编辑器 / IDE
.eglot-java/
.classpath
.project
.settings/
.idea/
*.iml
"
  "Maven Web 项目的 .gitignore 模板。")

(defun unzeit/servlet-new (group-id artifact-id package root final-name)
  "生成一个可直接跑 Tomcat 9 的 Maven Web 项目骨架。
写 pom.xml、web.xml、index.jsp、HelloServlet.java、.gitignore；GROUP-ID / ARTIFACT-ID / PACKAGE / ROOT / FINAL-NAME 全由交互提示给出。"
  (interactive
   (let* ((g (read-string "groupId: " unzeit/servlet-default-group-id))
          (a (read-string "artifactId: " unzeit/servlet-default-artifact-id))
          (p (read-string "Java 包名: " g))
          (r (read-string "项目目录: " (expand-file-name a "~/Projects/")))
          (f (read-string "WAR/context 名: " a)))
     (list g a p r f)))
  (let* ((root (file-name-as-directory (expand-file-name root)))
         (final-name (if (string-empty-p final-name) artifact-id final-name))
         (pkg-path (replace-regexp-in-string "\\." "/" package))
         (values `(("GROUP" . ,group-id)
                   ("ARTIFACT" . ,artifact-id)
                   ("PACKAGE" . ,package)
                   ("FINAL" . ,final-name))))
    (when (string-empty-p package)
      (user-error "Unzeit：Java 包名不能为空"))
    (when (and (file-directory-p root)
               (directory-files root nil "\\`[^.]"))
      (user-error "Unzeit：目录非空，换个目录：%s" root))
    (when (and (file-exists-p root) (not (file-directory-p root)))
      (user-error "Unzeit：%s 是个文件，不是目录" root))
    (unzeit/servlet--put (expand-file-name "pom.xml" root)
                         (unzeit/servlet--fill unzeit/servlet-pom-template values))
    (unzeit/servlet--put (expand-file-name ".gitignore" root)
                         unzeit/servlet-gitignore-template)
    (unzeit/servlet--put (expand-file-name "src/main/webapp/WEB-INF/web.xml" root)
                         (unzeit/servlet--fill unzeit/servlet-webxml-template values))
    (unzeit/servlet--put (expand-file-name "src/main/webapp/index.jsp" root)
                         (unzeit/servlet--fill unzeit/servlet-jsp-template values))
    (unzeit/servlet--put (expand-file-name
                          (format "src/main/java/%s/HelloServlet.java" pkg-path)
                          root)
                         (unzeit/servlet--fill unzeit/servlet-java-template values))
    (find-file (expand-file-name "src/main/webapp/index.jsp" root))
    (message "Unzeit：已生成 %s\n下一步：C-c J s 准备 Tomcat → C-c J r 启动 → C-c J b 打开首页"
             root)))

(defun unzeit/servlet-name ()
  "context 名 = pom.xml 的 <finalName>（缺省用项目目录名）。
★ 必须**先把 XML 注释剥掉**再找：否则匹配到注释里的词，实测吃出过「算」；并要求闭合标签。"
  (let* ((root (unzeit/servlet-root))
         (pom (expand-file-name "pom.xml" root)))
    (or (when (file-exists-p pom)
          (with-temp-buffer
            (insert-file-contents pom)
            (goto-char (point-min))
            (while (search-forward "<!--" nil t)
              (let ((beg (match-beginning 0)))
                (when (search-forward "-->" nil t)
                  (delete-region beg (point))
                  (goto-char beg))))
            (goto-char (point-min))
            (when (re-search-forward
                   "<finalName>[[:space:]]*\\([^<[:space:]]+\\)[[:space:]]*</finalName>"
                   nil t)
              (match-string 1))))
        (file-name-nondirectory (directory-file-name root)))))

(defun unzeit/servlet-base ()
  "本项目隔离的 CATALINA_BASE（不存在的目录也能算出来）。"
  (expand-file-name
   (file-name-nondirectory (directory-file-name (unzeit/servlet-root)))
   unzeit/servlet-base-root))

(defun unzeit/servlet-env ()
  "给子进程用的 `process-environment'（只影响本次调用起的进程）。
JAVA_HOME 保持全局值（sdkman 的 26，jdtls/mvn/tomcat 都用它），只补 CATALINA_HOME / CATALINA_BASE。"
  (let ((rest (seq-remove (lambda (s)
                            (string-match-p "\\`\\(CATALINA_HOME\\|CATALINA_BASE\\)=" s))
                          process-environment)))
    (cons (concat "CATALINA_HOME=" unzeit/servlet-catalina-home)
          (cons (concat "CATALINA_BASE=" (unzeit/servlet-base)) rest))))

(defun unzeit/servlet-setup ()
  "准备隔离 CATALINA_BASE 并写零拷贝 context 描述符。幂等，可反复执行。"
  (interactive)
  (let* ((root (unzeit/servlet-root))
         (base (unzeit/servlet-base))
         (name (unzeit/servlet-name))
         (webapp (expand-file-name "src/main/webapp" root))
         (classes (expand-file-name "target/classes" root))
         (conf (expand-file-name "conf" base)))
    (unless (file-directory-p unzeit/servlet-catalina-home)
      (user-error "Unzeit：找不到 %s（Tomcat 9 没装？）" unzeit/servlet-catalina-home))
    (unless (file-directory-p webapp)
      (user-error "Unzeit：%s 不存在，这不像 Maven Web 项目" webapp))
    (dolist (d '("logs" "temp" "webapps" "work"))
      (make-directory (expand-file-name d base) t))
    (let ((server-xml (expand-file-name "server.xml" conf)))
      (unless (file-exists-p server-xml)
        (when (file-directory-p conf)
          (delete-directory conf t))
        (copy-directory (expand-file-name "conf" unzeit/servlet-catalina-home) conf))
      (with-temp-buffer
        (insert-file-contents server-xml)
        (dolist (pair `(("port=\"8080\"" . ,unzeit/servlet-http-port)
                        ("port=\"8005\"" . ,unzeit/servlet-shutdown-port)))
          (goto-char (point-min))
          (while (re-search-forward (car pair) nil t)
            (replace-match (format "port=\"%d\"" (cdr pair)))))
        (write-region (point-min) (point-max) server-xml)))
    (let ((desc (expand-file-name (format "Catalina/localhost/%s.xml" name) conf)))
      (make-directory (file-name-directory desc) t)
      (with-temp-file desc
        (insert "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                "<!-- Unzeit servlet.el 生成：零拷贝 + 改 Java 自动 reload。\n"
                "     别手改这个文件，改 unzeit/servlet-setup 里的模板。 -->\n"
                (format "<Context docBase=\"%s\"\n" webapp)
                "         reloadable=\"true\"\n"
                "         backgroundProcessorDelay=\"1\">\n"
                "  <Resources>\n"
                "    <PreResources className=\"org.apache.catalina.webresources.DirResourceSet\"\n"
                (format "                  base=\"%s\"\n" classes)
                "                  webAppMount=\"/WEB-INF/classes\"/>\n"
                "  </Resources>\n"
                "</Context>\n"))
      (message "Unzeit：context 就绪 → %s\n  URL http://localhost:%d/%s/"
               desc unzeit/servlet-http-port name)
      desc)))

(defun unzeit/servlet-run ()
  "起 Tomcat（`catalina.sh run'，前台进程；日志进 *tomcat* 缓冲，可随时搜）。"
  (interactive)
  (unzeit/servlet-setup)
  (let ((process-environment (unzeit/servlet-env))
        (default-directory (unzeit/servlet-base)))
    (async-shell-command
     (concat (expand-file-name "bin/catalina.sh" unzeit/servlet-catalina-home) " run")
     "*tomcat*")
    (message "Unzeit：Tomcat 启动中，日志看 *tomcat*；就绪后 http://localhost:%d/%s/"
             unzeit/servlet-http-port (unzeit/servlet-name))))

(defun unzeit/servlet-stop ()
  "停 Tomcat（用 CATALINA_BASE 里那份 conf 的 shutdown 端口）。"
  (interactive)
  (let ((process-environment (unzeit/servlet-env))
        (default-directory (unzeit/servlet-base)))
    (async-shell-command
     (concat (expand-file-name "bin/catalina.sh" unzeit/servlet-catalina-home) " stop")
     "*tomcat*")))

(defun unzeit/servlet-mvn (args &optional label)
  "在项目根跑 `mvn ARGS'。LABEL 只用于回显。"
  (let ((process-environment (unzeit/servlet-env))
        (default-directory (unzeit/servlet-root)))
    (when label (message "Unzeit：%s" label))
    (compile (concat "mvn " args) t)))

(defun unzeit/servlet-update ()
  "改完 Java 跑这个：`mvn -q compile'，Tomcat 会在 ~0.35s 后自动 reload 上下文。"
  (interactive)
  (unzeit/servlet-mvn "-q compile" "编译中（改 Java 后跑；Tomcat 会自动 reload）"))

(defun unzeit/servlet-deps ()
  "把依赖 jar 拷进源码树的 WEB-INF/lib（依赖变化时才需要）。
★ 记得把 src/main/webapp/WEB-INF/lib/ 放进 .gitignore。"
  (interactive)
  (unzeit/servlet-mvn
   "-q dependency:copy-dependencies -DoutputDirectory=src/main/webapp/WEB-INF/lib"
   "同步依赖到 WEB-INF/lib…"))

(defun unzeit/servlet-package ()
  "交作业/部署用：`mvn -q clean package'（产出 target/<finalName>.war）。"
  (interactive)
  (unzeit/servlet-mvn "-q clean package -DskipTests" "打包 WAR…"))

(defun unzeit/servlet-test ()
  "跑本项目的测试：`mvn test'（输出进 *compilation*，`M-g n' 跳到失败行）。"
  (interactive)
  (unzeit/servlet-mvn "test" "测试中…"))

(defun unzeit/servlet-browse ()
  "浏览器打开本项目首页。"
  (interactive)
  (browse-url (format "http://localhost:%d/%s/"
                      unzeit/servlet-http-port (unzeit/servlet-name))))

(defun unzeit/servlet-log ()
  "打开本项目 Tomcat 最新那份 catalina 日志。"
  (interactive)
  (let* ((dir (expand-file-name "logs" (unzeit/servlet-base)))
         (files (seq-filter #'file-regular-p
                            (directory-files dir t "catalina\\..*\\.log\\'")))
         (mtime (lambda (f) (file-attribute-modification-time (file-attributes f))))
         (newest (car (sort files (lambda (a b)
                                    (time-less-p (funcall mtime b) (funcall mtime a)))))))
    (find-file (or newest dir))))

;;; ---- 可选：存盘自动 compile --------------------------------------

(defun unzeit/servlet-compile-on-save ()
  "保存 .java 后自动 `mvn -q compile'（只在该项目有 pom.xml 时）。"
  (when (and (derived-mode-p 'java-mode)
             buffer-file-name
             (when-let* ((root (unzeit/servlet-root-soft)))
               (file-exists-p (expand-file-name "pom.xml" root))))
    (ignore-errors (unzeit/servlet-update))))

(define-minor-mode unzeit/servlet-compile-on-save-mode
  "存盘自动 `mvn -q compile'（默认关；开了才有这个便利，代价是每次存盘一次构建）。"
  :global t
  :lighter nil
  (if unzeit/servlet-compile-on-save-mode
      (add-hook 'after-save-hook #'unzeit/servlet-compile-on-save)
    (remove-hook 'after-save-hook #'unzeit/servlet-compile-on-save)))

;;; ---- transient 菜单（transient 是 :defer 的，包一层）--------------

(defun unzeit/servlet-menu-open ()
  "打开 Maven Web / Tomcat 菜单（`C-c J'）。"
  (interactive)
  (require 'transient)
  (unzeit/servlet-menu))

(defconst unzeit/servlet-menu-rule (make-string 26 ?─)
  "C-c J 菜单的分隔线；Iosevka 里 ─ 是单宽。")

(with-eval-after-load 'transient
  (transient-define-prefix unzeit/servlet-menu ()
    "Maven Web / Tomcat 9"
    ;; transient 默认按 length（字符数）分栏，CJK 占两列 → 每行被顶歪；
    ;; :variable-pitch 让它按像素宽度算列、按 :align-to 对齐。
    :variable-pitch t
    [["项目 / 构建"
      unzeit/servlet-menu-rule
      ("n" "新建 Maven Web 项目…" unzeit/servlet-new)
      ("c" "编译（改 Java 后）" unzeit/servlet-update)
      ("t" "测试（mvn test）" unzeit/servlet-test)
      ("d" "同步依赖 → WEB-INF/lib" unzeit/servlet-deps)
      ("p" "打包 WAR" unzeit/servlet-package)]
     ["Tomcat / 浏览"
      unzeit/servlet-menu-rule
      ("s" "准备 context（幂等）" unzeit/servlet-setup)
      ("r" "启动" unzeit/servlet-run)
      ("k" "停止" unzeit/servlet-stop)
      ("l" "看日志" unzeit/servlet-log)
      ("b" "打开首页" unzeit/servlet-browse)]]))



;; 语言文件在 `editor.el' 之后加载，leader map 这时已经存在。
(when (boundp 'unzeit/leader-map)
  (define-key unzeit/leader-map (kbd "j") #'unzeit/servlet-menu-open))

(provide 'unzeit-lang-servlet)
;;; servlet.el ends here

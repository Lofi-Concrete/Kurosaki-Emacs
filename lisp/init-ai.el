;;; init-ai.el --- DeepSeek AI（gptel 对话 / 选区改写 / aider） -*- lexical-binding: t; -*-

;;; Commentary:
;; DeepSeek API（OpenAI 兼容），key 读 ~/.authinfo.gpg；只在按键时请求。
;;; Code:

(require 'auth-source)

(defgroup unzeit-ai nil
  "Unzeit 的 AI 集成（DeepSeek）。"
  :group 'unzeit
  :prefix "unzeit/ai-")

(defcustom unzeit/ai-host "api.deepseek.com"
  "DeepSeek API 主机名（auth-source 也按这个名字找 key）。"
  :type 'string)

(defcustom unzeit/ai-chat-model "deepseek-chat"
  "对话默认模型。"
  :type 'string)

(defcustom unzeit/ai-reasoner-model "deepseek-reasoner"
  "推理模型名（在 gptel 里可切换）。"
  :type 'string)

(defcustom unzeit/ai-settings-file (expand-file-name "ai-settings.el" user-emacs-directory)
  "本机 AI 覆盖配置（可选）：改模型名、host 等，不随仓库部署。"
  :type 'file)

(defvar unzeit/ai--key-cache :unset
  "会话内缓存的 API key。")

(defun unzeit/ai-key (&optional refresh)
  "从 `auth-source' 取 DeepSeek 的 API key；取不到返回 nil。"
  (when (or refresh (eq unzeit/ai--key-cache :unset))
    (setq unzeit/ai--key-cache
          (condition-case nil
              (let ((entry (car (auth-source-search :host unzeit/ai-host
                                                    :require '(:secret)
                                                    :max 1))))
                (when entry
                  (let ((secret (plist-get entry :secret)))
                    (if (functionp secret) (funcall secret) secret))))
            (error nil))))
  (if (eq unzeit/ai--key-cache :unset) nil unzeit/ai--key-cache))

(defun unzeit/ai-reset-key ()
  "重新从 auth-source 读一次 key（改完 ~/.authinfo.gpg 后用）。"
  (interactive)
  (if (unzeit/ai-key t)
      (message "DeepSeek key 已重新读取")
    (user-error "仍没读到 key：检查 ~/.authinfo.gpg 里的 machine %s" unzeit/ai-host)))

(defun unzeit/ai--ensure-key ()
  "没有 key 就给出明确的添加方法。"
  (or (unzeit/ai-key)
      (user-error "没有 DeepSeek API key：在 ~/.authinfo.gpg 加一行
  machine %s login apikey password sk-...
然后 M-x unzeit/ai-key 刷新" unzeit/ai-host)))

;;; ---- gptel：对话 + 选区改写 ------------------------------------------

(use-package gptel
  :ensure t
  :defer t
  :custom
  (gptel-default-mode 'org-mode)
  (gptel-use-curl t)
  :config
  (gptel-make-openai "DeepSeek"
    :host unzeit/ai-host
    :endpoint "/chat/completions"
    :stream t
    :key #'unzeit/ai-key
    :models (list unzeit/ai-chat-model unzeit/ai-reasoner-model))
  (setq gptel-backend (gptel-get-backend "DeepSeek")
        gptel-model unzeit/ai-chat-model))

(defun unzeit/ai-chat ()
  "打开 AI 对话（gptel）。"
  (interactive)
  (unzeit/ai--ensure-key)
  (require 'gptel)
  (call-interactively #'gptel))

(defun unzeit/ai-rewrite ()
  "对选中区域做 AI 改写/重构（gptel-rewrite，带 diff 预览）。"
  (interactive)
  (unzeit/ai--ensure-key)
  (unless (use-region-p)
    (user-error "先选中要改写的区域"))
  (require 'gptel-rewrite)
  (call-interactively #'gptel-rewrite))

(defun unzeit/ai--ask (prompt)
  "把选区发给模型，回答写进 *AI* 缓冲。"
  (unzeit/ai--ensure-key)
  (unless (use-region-p)
    (user-error "先选中一段内容"))
  (let* ((text (buffer-substring-no-properties (region-beginning) (region-end)))
         (lang (symbol-name major-mode))
         (buf (get-buffer-create "*AI*"))
         (full (format "%s\n\n```%s\n%s\n```" prompt lang text)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "# %s\n\n" prompt))
        (insert "（请求中…）\n"))
      (special-mode))
    (display-buffer buf)
    (gptel-request
     full
     :system "你是资深程序员，回答简洁、直接、给可执行的结论。"
     :callback
     (lambda (response _info)
       (with-current-buffer buf
         (let ((inhibit-read-only t))
           (erase-buffer)
           (insert (format "# %s\n\n" prompt))
           (insert (or response "（没有返回；看 *Messages* 或网络）"))))
       (message "AI 回答已写入 *AI*")))
    (message "已发送给 DeepSeek：%s" prompt)))

(defun unzeit/ai-explain ()
  "解释选中区域（代码或文字）。"
  (interactive)
  (unzeit/ai--ask "解释下面这段内容：它在做什么、关键点是什么"))

(defun unzeit/ai-translate ()
  "把选中区域翻译成中文（已是中文则翻成英文）。"
  (interactive)
  (unzeit/ai--ask "翻译下面这段内容；如果原文是中文就翻成英文，否则翻成中文"))

;;; ---- aidermacs：整仓库改代码 -----------------------------------------

(use-package aidermacs
  :ensure t
  :defer t
  :commands (aidermacs-transient-menu)
  :custom
  (aidermacs-default-model "deepseek/deepseek-chat")
  (aidermacs-use-architect-mode nil))

(defun unzeit/ai-aider ()
  "在项目根开 aider 会话（整仓库改代码）。"
  (interactive)
  (unless (executable-find "aider")
    (user-error "没装 aider：先在终端跑 `uv tool install aider-chat'"))
  (unzeit/ai--ensure-key)
  (setenv "DEEPSEEK_API_KEY" (unzeit/ai-key))
  (require 'aidermacs)
  (call-interactively #'aidermacs-transient-menu))

(when (file-exists-p unzeit/ai-settings-file)
  (load unzeit/ai-settings-file nil t))

(provide 'init-ai)
;;; init-ai.el ends here

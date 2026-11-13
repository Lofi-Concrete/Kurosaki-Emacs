# 🧙 Kurosaki-emacs

<div align="center">

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GNU Emacs](https://img.shields.io/badge/Emacs-31.1-7F5AB6?logo=gnu&logoColor=white)](https://www.gnu.org/software/emacs/)
[![Platform](https://img.shields.io/badge/Platform-Guix%20System%20%7C%20Wayland-informational)](#-prerequisites)
[![Editing](https://img.shields.io/badge/Editing-Meow-7aa2f7)](#-features)

</div>

<div align="center">

![Kurosaki-emacs](images/emacs-logo.png)

</div>

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->

## Table of Contents

  - [✨ Features](#-features)
  - [🧰 Prerequisites](#-prerequisites)
    - [Operating System](#operating-system)
    - [GNU Emacs](#gnu-emacs)
    - [Fonts](#fonts)
  - [🚀 Quick Start](#-quick-start)
    - [Guix Home](#guix-home)
    - [Standalone](#standalone)
    - [First Startup](#first-startup)
  - [⬆️ Updating](#️-updating)
  - [⚙️ Customization](#️-customization)
  - [⌨️ Keybindings](#️-keybindings)
  - [📸 Screenshots](#-screenshots)
  - [❓ FAQ](#-faq)
  - [💖 Acknowledgements](#-acknowledgements)
  - [📄 License](#-license)

<!-- markdown-toc end -->

Kurosaki-emacs is a personal Emacs distribution for **Guix System + Wayland**,
built around **meow**, **vertico + corfu + consult + embark**, **eglot +
tree-sitter**, **org-roam**, **magit** and a calm **Tokyo Night** interface.

It is not a generic starter kit. It is the exact configuration I use every day,
kept in one repository so it can be cloned on any machine without pulling the
whole Guix home-manager setup.

The internal namespace is still `unzeit/` for historical reasons; the project
name is **Kurosaki-emacs**.

## ✨ Features

- **Modal editing with meow**: `SPC` is the leader in normal/motion state;
  `C-c` remains a stateless prefix for the same commands.
- **Modern completion**: vertico + orderless + marginalia + consult + embark,
  corfu + cape + yasnippet, centered child-frame popups, consult extensions and
  wgrep/link-hint/browse-kill-ring helpers.
- **LSP and tree-sitter**: eglot + tree-sitter + apheleia for completion,
  diagnostics and formatting; graceful fallback when a server is missing.
- **Multi-language support**: C/C++, Go, Python, Rust, Java, JavaScript/TypeScript,
  Web/JSP, Zig, Haskell, C3, Odin, Ruby, Lua, Dart, Julia, PHP, Scala, Swift,
  PowerShell, CMake, CSV, Fish, Protobuf, SCSS, RON, Markdown.
- **File management**: treemacs on `SPC f t/T`; the existing dirvish-side on
  `SPC f v/V`; dired and dirvish helpers.
- **Git**: magit + magit-todos + git-timemachine + browse-at-remote +
  git-messenger + git-modes; `SPC g` is the git prefix.
- **Notes**: org + org-roam + org-roam-ui; roam database uses Emacs 31's built-in
  SQLite (no external `sqlite3` required).
- **Polished UI**: Tokyo Night theme, Maple Mono NF CN, dashboard, centered
  which-key/transient/vertico child frames, ultra-scroll, solaire-mode,
  eol diagnostic chips and an eldoc-mouse point-dwell popup.
- **Emacs as a Guix tool**: emacs-guix, `guix-devel-mode`, build-log highlighting
  and store-path prettifying.
- **Chinese-first**: Chinese font sets, pinyin-aware search and CJK spacing.

## 🧰 Prerequisites

### Operating System

- **Guix System** is the primary target (the home module is in this repository's
  `home/editor/editor.scm` and `home/lang/lang.scm`).
- **Linux + Wayland** is the tested display setup (niri + Noctalia).
- Any Emacs 31.1 build with pgtk should work for the standalone setup; pgtk is
  required for native Wayland clipboard and child-frame behaviour.

### GNU Emacs

**GNU Emacs 31.1 or newer** is required. The configuration relies on:

- native tree-sitter (`treesit`)
- native JSON and SQLite
- pgtk (Wayland)
- `libgccjit` for native compilation (optional but recommended)

### Fonts

- **Maple Mono NF CN** — body, CJK and Nerd icons
- **LXGW WenKai Mono** — org writing
- **Noto Color Emoji** — emoji

### External tools

The configuration degrades gracefully when these are absent, but the full
experience needs:

- language servers: `clangd`, `gopls`, `rust-analyzer`, `zls`, `hls`,
  `solargraph`, `lua-language-server`, `typescript-language-server`,
  `vscode-html-language-server`, `vscode-css-language-server`
- formatters: `clang-format`, `gofmt`/`gofumpt`, `rustfmt`, `zig fmt`, `prettier`
- tree-sitter grammars from the Guix profile

## 🚀 Quick Start

### Guix Home

The configuration is consumed as a **git submodule** by the Guix home repo:

```sh
git clone ssh://git@codeberg.org/Lofi_Concrete/lc-guix-home-manager.git ~/guix
git -C ~/guix submodule update --init --recursive
guix home reconfigure ~/guix/home/home.scm \
  --load-path="$HOME/Projects/lc-guix-channels/guix" --fallback
```

The `--load-path` is required because the home config imports packages from the
`lc-guix` channel. The submodule live at `home/editor/.emacs.d`.

### Standalone

To use the Emacs configuration without the Guix home layer:

```sh
mv ~/.emacs.d ~/.emacs.d.bak
git clone <Kurosaki-emacs-url> ~/.emacs.d
~/.emacs.d/tests/preinstall-modern.sh
~/.emacs.d/tests/preinstall-features.sh
cp ~/.emacs.d/lisp/init-local.example.el ~/.emacs.d/lisp/init-local.el
```

Then install the fonts and the external tools listed above. Start Emacs; the
first startup probes the ELPA mirrors and installs anything still missing.

### First Startup

- The package mirror is probed in the background; no network request is made on
  the critical startup path.
- `M-x unzeit/doctor` prints a health report: fonts, language servers, tree-sitter
  grammars, package state and the active configuration.
- If something looks stale, remember: `~/.emacs.d` is deployed from the store in
  the Guix setup; edit the repository, `guix home reconfigure`, then restart Emacs.

## ⬆️ Updating

Standalone:

```sh
git -C ~/.emacs.d pull --ff-only
emacs --batch -Q --eval '(progn (package-initialize) (package-quickstart-refresh))'
```

Guix home:

```sh
git -C ~/guix submodule update --remote --merge
guix home reconfigure ~/guix/home/home.scm \
  --load-path="$HOME/Projects/lc-guix-channels/guix" --fallback
```

Restart Emacs after the reconfigure; the running instance keeps its old store.

## ⚙️ Customization

- **`unzeit/modern-*`**: toggles for the modern layer (scroll, GC, posframe,
  vertico-posframe, solaire, diagnostics). `M-x customize-group unzeit/modern`.
- **`init-local.el`**: machine-local overrides, never deployed by Guix; copy
  `lisp/init-local.example.el` and edit it.
- **Fonts**: `unzeit/body-font-height` and `unzeit/ui-font-height` in
  `lisp/core.el`; the frame font string in `early-init.el`.
- **Languages**: every language lives in its own file under `langs/`; add a new
  `.el` file and it is loaded automatically.
- **Theme**: a single fixed Tokyo Night palette in `lisp/unzeit-theme.el`.

## ⌨️ Keybindings

`SPC` is the leader in meow normal/motion state; `C-c` exposes the same custom
commands without a state prefix.

| Key | Action |
|-----|--------|
| `SPC f t` / `SPC f T` | treemacs toggle / focus |
| `SPC f v` / `SPC f V` | dirvish-side toggle / focus |
| `SPC f f` / `SPC f s` / `SPC f o` | find file / save / other window |
| `SPC f e` | consult-dir |
| `SPC s s` / `SPC s g` | consult-line / consult-ripgrep |
| `SPC s y` / `SPC s T` / `SPC s F` | consult-yasnippet / todo / flyspell |
| `SPC g s` / `SPC g l` / `SPC g d` | magit status / log / diff |
| `SPC g T` / `SPC g t` / `SPC g o` / `SPC g m` | magit-todos / timemachine / browse-at-remote / git-messenger |
| `SPC o r` / `SPC o i` / `SPC o b` | org-roam node-find / insert / buffer-toggle |
| `SPC o d` / `SPC o u` | org-roam dailies / org-roam-ui |
| `SPC o a` / `SPC o c` | org-agenda / org-capture |
| `SPC l d` / `SPC l r` / `SPC l o` | xref definition / references / link-hint |
| `SPC y` | browse-kill-ring |
| `SPC c g` | Guix packages / generations / services |
| `SPC ?` | help commands |
| `C-c t` / `C-c v` | treemacs / dirvish-side |
| `C-c a` / `C-c c` | org-agenda / org-capture |
| `C-c g` | Guix popup |

## 📸 Screenshots

<div align="center">

![Kurosaki-emacs logo](images/emacs-logo.png)

</div>

The dashboard, the centered vertico popup, the eldoc-mouse point-dwell popup and
the treemacs side window are the main visual pieces. A screenshot set will be
added as the configuration settles.

## ❓ FAQ

**Is `~/.emacs.d` a git repository?**
In the Guix setup, no: it is a deployed store symlink. The source of truth is
`~/guix/home/editor/.emacs.d` (a git submodule pointing at this repository).
In the standalone setup, `~/.emacs.d` *is* this repository.

**Why is the configuration still using `unzeit/`?**
The project was previously called Unzeit. The prefix is kept to avoid breaking
years of muscle memory and every language file; the display name is
Kurosaki-emacs.

**A language has no completion.**
Check the language server and the tree-sitter grammar. Missing servers are not
registered, so eglot will not error; install the server, or add it to
`langs/<language>.el`. Missing grammars can be installed with
`M-x treesit-install-language-grammar` or `guix home reconfigure`.

**org-roam fails to open its database.**
The config uses Emacs 31's built-in SQLite (`sqlite-builtin`); no external
`sqlite3` is needed. If your Emacs was built without SQLite, switch
`org-roam-database-connector` to `sqlite` and install the `sqlite` package.

**The clipboard does not work.**
Use a pgtk build; `select-enable-clipboard` is on and `meow-use-clipboard` is
enabled. Wayland only lets a focused client own the clipboard.

**How do I try it without touching my Guix home?**
Clone this repository to a temporary directory and start Emacs with
`emacs --init-directory /path/to/Kurosaki-emacs`.

## 💖 Acknowledgements

- [Centaur Emacs](https://github.com/seagle0128/.emacs.d) — the README layout and
  several UI ideas are inspired by it.
- The Emacs, Guix, meow, vertico, corfu, consult, embark, eglot, magit and
  org-roam communities.
- Maple Mono, LXGW WenKai and the Tokyo Night theme.

## 📄 License

GPL-3.0. See [LICENSE](LICENSE) or
<https://www.gnu.org/licenses/gpl-3.0>.

# alacritty config

Gruvbox Material theme for [Alacritty](https://alacritty.org).

Colours and window opacity are not here: `alacritty.toml` imports
`~/.cache/alacritty-theme.toml`, which the i3 repo's `~/.i3rc/scripts/theme.sh`
rewrites on every dark/light toggle. Font, cursor and keybindings live here.

## Install

```sh
git clone git@github.com:Spuppateddu/configuration-alacritty.git ~/linux-configuration/alacritty
ln -sfn ~/linux-configuration/alacritty ~/.alacritty

cd ~/.alacritty && ./install.sh      # --dry-run to see what it would do first
```

That installs `alacritty`, `fontconfig`, [Cascadia Code NF](#font), and links
`alacritty.toml` into `~/.config/alacritty/`. It is idempotent, so re-run it
after a `git pull`.

Clone to `~/linux-configuration/alacritty` with `~/.alacritty` as a symlink, not
straight to `~/.alacritty` —
[best-linux-environment](https://github.com/Spuppateddu/best-linux-environment)
refuses to adopt a real checkout at that path and skips the tool. It manages this
repo and runs `./install.sh` itself, so on a full machine setup there is nothing
to do here.

Alacritty does not read this directory. It reads, in order:

1. `$XDG_CONFIG_HOME/alacritty/alacritty.toml`
2. `$XDG_CONFIG_HOME/alacritty.toml`
3. `~/.config/alacritty/alacritty.toml`
4. `~/.alacritty.toml`
5. `/etc/alacritty/alacritty.toml`

`./install.sh` links into the third. By hand:

```sh
mkdir -p ~/.config/alacritty
ln -sfn ~/.alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
```

`alacritty.toml` is re-read on save, so edits reach open windows.

## Font

**Cascadia Code NF**, with no fallback family behind it — and none needed. NF is
upstream's own Nerd-Font build: the same face as plain Cascadia Code, with the
icon range patched in, so powerline separators, git glyphs and Material Design
icons all come out of the one file. A codepoint outside even that coverage still
renders as a tofu box; that is deliberate.

Install it from [upstream's own
release](https://github.com/microsoft/cascadia-code/releases), taking the four
**static** TTFs (`ttf/static/CascadiaCodeNF-{Regular,Bold,Italic,BoldItalic}.ttf`)
— **not** the variable `ttf/CascadiaCodeNF.ttf`, which reports neither
`style=Bold` nor `style=Italic`, so the four `[font]` lines would all land on
Regular. `./install.sh` does this for you.

```sh
fc-list : family | grep -qx 'Cascadia Code NF' && echo "font installed"
fc-match "Cascadia Code NF"                  # want Cascadia Code NF, not a substitute
```

If the font is on disk but unlisted, the cache is stale — `fc-cache -rf`.

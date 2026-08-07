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

That installs `alacritty`, `fontconfig`, [Courier Prime](#font), and links
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

**Courier Prime**, with no fallback family behind it. Courier Prime carries no
icon range, so every codepoint outside its coverage renders as a tofu box:
powerline separators, git glyphs, Material Design icons, and U+23F8/U+23F5 (the
pause/play pair Claude Code uses as its mode indicator). Deliberate — restoring
any of them means adding a second family.

Install it from [upstream's own
TTFs](https://github.com/quoteunquoteapps/CourierPrime), **not apt's
`fonts-courier-prime`** — that package reports `style=Light`, `weight=50`,
`slant=0` on all four faces, so bold and italic silently resolve to Regular.
`./install.sh` does this for you.

```sh
fc-list : family | grep -qx 'Courier Prime' && echo "font installed"
fc-match "Courier Prime"                     # want Courier Prime, not a substitute
```

If the font is on disk but unlisted, the cache is stale — `fc-cache -rf`.

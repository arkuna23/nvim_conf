# Personal Neovim Configuration

Personal neovim config, with high flexibility.

## Installation

```bash
cd ~/.config
mv nvim nvim.bak
git clone https://github.com/arkuna23/nvim_conf nvim
cd nvim
./install.sh
```

## Switch plugins

Use `TogglePluginsEnabled` command in neovim to disable/enable plugin loader.

You can enable specified plugins in `conf/plugins_loaded.json`.

-   If you want to enable all plugins, set `enable-all` to true.

    ```json
    {
        "enable-all": true
    }
    ```

-   If you want to enable plugins in specified categories, set correspoding category key.

    ```json
    {
        "some-category": {
            "enabled": ["plugin name"]
        }
    }
    ```

    enable all plugins in specified category:

    ```json
    {
        "some-category": true
    }
    ```

-   A category may has sub-categories, same rules as above
    ```json
    {
        "some-category": {
            "enabled": ["plugin in parent category"],
            "sub-category": {
                "enabled": ["plugin name"]
            },
            "another-sub-category": true
        }
    }
    ```

## Runtime and language tools

The configuration targets Neovim 0.12.5 and the versions in `lazy-lock.json`.
After the first plugin installation, prepare language tools from this directory:

```bash
nvim --clean --headless -i NONE -l lua/install_mason.lua
rustup component add rust-analyzer
```

The Mason script waits for installations to finish and reports package-specific errors.
It also accepts package names, for example:

```bash
nvim --clean --headless -i NONE -l lua/install_mason.lua black vue-language-server codelldb kotlin-debug-adapter
```

Treesitter installs the selected parsers on startup. Use `:TSUpdate` when updating the plugin.
Rust components belong to the active toolchain; run the rustup command again after changing toolchains.

External runtimes and desktop providers:

| Feature | Prerequisites |
| --- | --- |
| JavaScript, Vue and web tools | Node.js and npm |
| C# / OmniSharp | .NET SDK |
| Haskell language server and debugger | GHC, ghcup and cabal |
| Java and Kotlin | A JDK compatible with the language server and project |
| Rust | rustup, Cargo, rust-analyzer and Clippy components |
| Go | Go toolchain |
| C/C++ debug checks | GCC and the Mason codelldb package |
| Local Wayland clipboard | `wl-copy` and `wl-paste` (wl-clipboard) |
| Local X11 clipboard | xclip or xsel |

`editor_lang = nil` enables all languages. Existing `js` / `js/ts` and `cpp` / `c/cpp`
spellings are accepted. Rust and Haskell clients are managed by their dedicated plugins.

## Project settings and formatting

Project settings keep the `.neoconf.json` format:

```json
{
    "lspconfig": {
        "lua_ls": {
            "Lua.runtime.special": { "lazy_require": "require" }
        },
        "intelephense": false
    }
}
```

The existing `<server>.disable = true` setting is also supported. Settings are merged
in this order: built-in configuration, imported global/project editor settings,
global Neoconf server settings, then project Neoconf server settings. Restart Neovim
to apply changes to running language services. Rust uses the `rust_analyzer` key;
Haskell uses `hls`.

For JS/TS, JSX/TSX, CSS, JSON/JSONC and GraphQL, a project Biome configuration selects
Biome; otherwise Prettier is selected. HTML, Vue, Svelte, Astro, SCSS, Less, YAML,
Handlebars and Markdown use Prettier. Project Prettier configuration takes priority;
the default is `conf/.prettierrc.json`. Other languages retain their external
formatters, with LSP formatting as fallback.

`<leader>f` formats manually. Saving formats synchronously with a two-second formatter
timeout; Markdown, Vue and Kotlin retain their manual-formatting preference.
Treesitter selection uses Enter to select/expand, Backspace to shrink, and Tab to
expand to a scope (or a larger named node when scope queries are unavailable).

## Clipboard

Local desktop sessions use the system clipboard; Neovide retains its integration.
In SSH sessions, use `"+y` to copy through OSC52 and the terminal paste shortcut to
paste from the local desktop. Ordinary `y` / `p` use Neovim registers. Explicit
clipboard-register reads return the last value copied to that register in this session.
OSC52 transport through tmux depends on terminal passthrough support.

## Checks

After preparing plugins, parsers and language tools:

```bash
nvim --clean --headless -i NONE -l tests/check.lua
nvim --clean --headless -i NONE -l tests/integration.lua
```

The focused checks cover project settings, formatter selection, Unicode syntax
selection, debug argument parsing and clipboard transport. Integration checks start
Lua, PHP, Go, Vue/TypeScript, Rust and TOML clients, format Python, and debug a small
compiled C program. They use temporary projects and clean them up after execution.
The Vue fixture installs Vue 3 into its temporary project via npm; the first run
requires access to the npm registry.

C# and Haskell project checks additionally require the runtimes listed above.
The pinned rustaceanvim v5 can emit a `client.request` deprecation notice on Neovim 0.12.
Avante defaults to the Copilot provider. Its startup requires the corresponding
GitHub Copilot OAuth setup; an existing authenticated provider can instead be selected
with `avante.chat_provider` and `avante.suggestions_provider` in `lua/user_config.lua`.

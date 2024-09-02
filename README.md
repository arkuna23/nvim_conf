# Personal Neovim Configuration

Personal neovim config, with high flexibility.

## Installation

```bash
cd ~/.config
mv nvim nvim.bak
git clone https://github.com/arkuna23/nvim_conf nvim
cd nvim_conf
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

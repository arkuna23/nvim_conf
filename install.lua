-- install.lua

-- 0. Load Config & Initialize
local util = require("lib.util")
local user_config = require("user_config")
local editor_lang = util.array_to_hash(user_config.editor_lang)

local distro = arg[1]
if not distro then
	print("Error: No distro ID provided.")
	os.exit(1)
end

-- 1. Define Package Lists
local packages = {
	common = { "jq", "ripgrep", "git", "curl", "tar" },
	arch = { "base-devel" },
	debian = { "build-essential" },
	ubuntu = { "build-essential" },
	aur = {
		rust = "rustup",
		haskell = "ghcup-hs-bin",
	},
}

-- 2. Utility functions
local function run_cmd(cmd)
	-- Smart sudo: remove sudo if running as root (common in Docker)
	if os.execute("id -u > /dev/null 2>&1") == 0 then
		cmd = cmd:gsub("sudo ", "")
	end
	print(">> Executing: " .. cmd)
	local res = os.execute(cmd)
	return res == 0 or res == true
end

local function install_latest_neovim()
	print("--- Installing Latest Stable Neovim (v0.10+) ---")
	local archive = "nvim-linux-x86_64.tar.gz"
	local url = "https://github.com/neovim/neovim/releases/latest/download/" .. archive

	local download_cmd = string.format("cd /tmp && curl -LO %s", url)

	if run_cmd(download_cmd) then
		run_cmd("sudo tar -C /usr/local --strip-components 1 -xzf /tmp/" .. archive)
		run_cmd("rm /tmp/" .. archive)
		return true
	end
	return false
end

-- 3. Package List Builder
local function get_install_list(include_aur)
	local list = {}
	for _, p in ipairs(packages.common) do
		table.insert(list, p)
	end

	local distro_pkgs = packages[distro] or {}
	for _, p in ipairs(distro_pkgs) do
		table.insert(list, p)
	end

	if distro == "arch" and include_aur then
		for lang, pkg in pairs(packages.aur) do
			if not editor_lang or editor_lang[lang] then
				table.insert(list, pkg)
			end
		end
	end
	return list
end

-- 4. Main Logic Sections
local function handle_arch(use_aur)
	local helper = nil
	if use_aur then
		for _, h in ipairs({ "paru", "yay" }) do
			if os.execute("command -v " .. h .. " > /dev/null 2>&1") then
				helper = h
				break
			end
		end
	end

	if helper then
		print("--- Using AUR helper: " .. helper .. " ---")
		return run_cmd(
			helper .. " -S --needed --noconfirm " .. table.concat(get_install_list(true), " ")
		)
	else
		print("--- Using pacman ---")
		-- Arch can also use official repo neovim or manual install
		return run_cmd(
			"sudo pacman -S --needed --noconfirm "
				.. table.concat(get_install_list(false), " ")
				.. " neovim"
		)
	end
end

local function handle_debian_ubuntu()
	print("--- Using apt-get ---")
	local pkgs_str = table.concat(get_install_list(false), " ")
	local ok = run_cmd("sudo apt-get update && sudo apt-get install -y " .. pkgs_str)
	if ok then
		return install_latest_neovim()
	end
	return false
end

print("Language: " .. table.concat(user_config.editor_lang or { "All" }, ", "))

-- 5. Execution Flow
print("--- Starting Environment Setup for " .. distro .. " ---")

local use_aur = false
for i = 2, #arg do
	if arg[i] == "--aur" then
		use_aur = true
		break
	end
end

local success = false
if distro == "arch" then
	success = handle_arch(use_aur)
elseif distro == "debian" or distro == "ubuntu" then
	success = handle_debian_ubuntu()
end

if success then
	-- Install Language Runtimes
	print("--- Installing External Language Tools ---")
	if not editor_lang or editor_lang["rust"] then
		if not (os.execute("command -v rustup > /dev/null 2>&1")) then
			run_cmd("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")
		end
	end

	if not editor_lang or editor_lang["haskell"] then
		if not (os.execute("command -v ghcup > /dev/null 2>&1")) then
			local ghcup_cmd = [[
                export BOOTSTRAP_HASKELL_NONINTERACTIVE=1;
                export BOOTSTRAP_HASKELL_GHC_VERSION=latest;
                curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
            ]]
			run_cmd(ghcup_cmd)
		end
	end

	print("\n--- [SUCCESS] All tasks completed! ---")
else
	print("\n--- [ERROR] Installation failed ---")
	os.exit(1)
end

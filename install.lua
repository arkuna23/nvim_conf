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
	common = { "jq", "neovim", "ripgrep", "git", "curl" },
	arch = { "base-devel" },
	debian = { "build-essential" },
	ubuntu = { "build-essential" },
	aur = {
		rust = "rustup",
		haskell = "ghcup-hs-bin",
	},
}

-- 2. Build Master List (English comments)
local function get_install_list(include_aur)
	local list = {}
	-- Add common packages
	for _, p in ipairs(packages.common) do
		table.insert(list, p)
	end

	-- Add distro specific
	local distro_pkgs = packages[distro] or {}
	for _, p in ipairs(distro_pkgs) do
		table.insert(list, p)
	end

	-- Add AUR/Language specific if on Arch
	if distro == "arch" and include_aur then
		for lang, pkg in pairs(packages.aur) do
			if not editor_lang or editor_lang[lang] then
				table.insert(list, pkg)
			end
		end
	end
	return list
end

-- 3. Utility functions
local function run_cmd(cmd)
	print(">> Executing: " .. cmd)
	local res = os.execute(cmd)
	return res == 0 or res == true -- Compatible with Lua 5.1 and 5.4
end

local function get_aur_helper()
	if distro ~= "arch" then
		return nil
	end
	for _, helper in ipairs({ "paru", "yay" }) do
		if os.execute("command -v " .. helper .. " > /dev/null 2>&1") then
			return helper
		end
	end
	return nil
end

-- 4. Main Installation Logic
local function do_install()
	local use_aur = false
	for i = 2, #arg do
		if arg[i] == "--aur" then
			use_aur = true
			break
		end
	end

	local helper = get_aur_helper()
	local install_done = false

	-- Case A: Arch with AUR helper
	if distro == "arch" and use_aur and helper then
		print("--- Using AUR helper: " .. helper .. " ---")
		local full_list = get_install_list(true)
		install_done =
			run_cmd(helper .. " -S --needed --noconfirm " .. table.concat(full_list, " "))

	-- Case B: Standard System Package Manager
	else
		print("--- Using standard package manager ---")
		local base_list = get_install_list(false)
		local pkgs_str = table.concat(base_list, " ")

		if distro == "arch" then
			install_done = run_cmd("sudo pacman -S --needed --noconfirm " .. pkgs_str)
		elseif distro == "debian" or distro == "ubuntu" then
			install_done = run_cmd("sudo apt-get update && sudo apt-get install -y " .. pkgs_str)
		end
	end

	return install_done
end

-- 5. External Tools (Binary Scripts)
local function install_external_tools()
	print("--- Checking Language Runtimes ---")

	-- Rustup
	if not editor_lang or editor_lang["rust"] then
		if not (distro == "arch" and os.execute("command -v rustup > /dev/null 2>&1")) then
			run_cmd("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")
		end
	end

	-- GHCup
	if not editor_lang or editor_lang["haskell"] then
		if not (distro == "arch" and os.execute("command -v ghcup > /dev/null 2>&1")) then
			local ghcup_cmd = [[
                export BOOTSTRAP_HASKELL_NONINTERACTIVE=1;
                export BOOTSTRAP_HASKELL_GHC_VERSION=latest;
                curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
            ]]
			run_cmd(ghcup_cmd)
		end
	end
end

-- --- Execution ---
print("--- Initializing Installation for " .. distro .. " ---")

if do_install() then
	install_external_tools()
	print("\n--- [SUCCESS] All tasks completed! ---")
	print("Note: Please restart your shell to update PATH.")
else
	print("\n--- [ERROR] System installation failed ---")
	os.exit(1)
end

local version = ZOI.VERSION or "1.4.0"
local url = "https://registry.npmjs.org/@zillowe/zeno/-/zeno-" .. version .. ".tgz"
local archive = "zeno-" .. version .. ".tar.gz"

local function get_font_dir()
	if SYSTEM.OS == "linux" then
		return (PKG.scope == "system") and "${usrroot}/usr/share/fonts/TTF" or "${usrhome}/.local/share/fonts"
	elseif SYSTEM.OS == "macos" then
		return (PKG.scope == "system") and "${usrroot}/Library/Fonts" or "${usrhome}/Library/Fonts"
	elseif SYSTEM.OS == "windows" then
		return (PKG.scope == "system") and "${usrroot}/Windows/Fonts"
			or "${usrhome}/AppData/Local/Microsoft/Windows/Fonts"
	end
	return "${pkgstore}/share/fonts"
end

local function get_license_dir()
	if SYSTEM.OS == "linux" then
		return "${usrroot}/usr/share/licenses/ttf-zeno"
	elseif SYSTEM.OS == "macos" then
		return "${usrroot}/Library/Application Support/Zoi/Licenses/zeno"
	elseif SYSTEM.OS == "windows" then
		return "${usrroot}/ProgramData/Zoi/Licenses/zeno"
	end
	return "${pkgstore}/share/licenses"
end

metadata({
	name = "zeno",
	repo = "zillowe",
	version = version,
	revision = "4",
	description = "The typography system for the Zillowe Foundation",
	website = "https://zillowe.qzz.io/docs/zowdy/zeno",
	git = "https://gitlab.com/zillowe/zillwen/zowdy/zeno",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	license = "OFL-1.1",
	types = { "pre-compiled" },
	scope = "system",
	tags = { "zillowe", "zeno", "font", "ttf" },
	platforms = { "linux", "macos" },
})

function prepare()
	UTILS.FILE(url, archive)
	UTILS.EXTRACT(archive, "source")
end

function verify()
	return verifyHash(
		archive,
		"sha512-097fcc7c9086cf4ed8422632419444ddffdda19e8115d2b3db55d7c4e9c3c0d923cee48fb72c9b7092d078a24b377f7d83ce1a8be8642fa3a9d95fdffeb2c6e3"
	)
end

function package()
	local font_dir = get_font_dir()
	local fonts = {
		"ZenoMonoCode.ttf",
		"ZenoMonoNerd.ttf",
		"ZenoMonoTerminal.ttf",
		"ZenoMonoText.ttf",
		"ZenoSansDisplay.ttf",
		"ZenoSansText.ttf",
		"ZenoSansUI.ttf",
		"ZenoSerifCaption.ttf",
		"ZenoSerifDisplay.ttf",
		"ZenoSerifText.ttf",
	}

	for _, font in ipairs(fonts) do
		zcp("source/package/dist/" .. font, font_dir .. "/" .. font)
	end

	zcp("source/package/LICENSE", get_license_dir() .. "/LICENSE")
end

function uninstall() end

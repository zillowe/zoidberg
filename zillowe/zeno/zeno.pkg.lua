local version = ZOI.VERSION or "1.3.0"
local url = "https://registry.npmjs.org/@zillowe/zeno/-/zeno-" .. version .. ".tgz"
local archive = "zeno-" .. version .. ".tar.gz"

metadata({
	name = "zeno",
	repo = "zillowe",
	version = version,
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
	tags = { "zeno", "font", "ttf", "zillowe" },
})

function prepare()
	UTILS.FILE(url, archive)
	UTILS.EXTRACT(archive, "source")
end

function verify()
	return verifyHash(
		archive,
		"sha512-30bb0f39d1de9c8e836fb4bd291c684b7478568b97aa73ea0663446a5034aa6a748260bccc89474d843f5d2d43b85fe1856d7c2c3fa157993bf6d449e2d18110"
	)
end

function package()
	zcp("source/package/dist/ZenoMonoCode.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoMonoCode.ttf")
	zcp("source/package/dist/ZenoMonoNerd.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoMonoNerd.ttf")
	zcp("source/package/dist/ZenoMonoTerminal.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoMonoTerminal.ttf")
	zcp("source/package/dist/ZenoMonoText.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoMonoText.ttf")
	zcp("source/package/dist/ZenoSansDisplay.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoSansDisplay.ttf")
	zcp("source/package/dist/ZenoSansText.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoSansText.ttf")
	zcp("source/package/dist/ZenoSansUI.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoSansUI.ttf")
	zcp("source/package/dist/ZenoSerifCaption.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoSerifCaption.ttf")
	zcp("source/package/dist/ZenoSerifDisplay.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoSerifDisplay.ttf")
	zcp("source/package/dist/ZenoSerifText.ttf", "${usrroot}/usr/share/fonts/TTF/ZenoSerifText.ttf")

	zcp("source/package/LICENSE", "${usrroot}/usr/share/licenses/ttf-zeno/LICENSE")
end

function uninstall() end

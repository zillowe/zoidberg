local version = ZOI.VERSION or "1.1.0"
local url = "https://registry.npmjs.org/@zillowe/zeno/-/zeno-" .. version .. ".tgz"
local archive = "zeno-" .. version .. ".tar.gz"

metadata({
	name = "zeno",
	repo = "zillowe",
	version = version,
	description = "The typography system for the Zillowe Foundation",
	website = "https://zillowe.qzz.io/docs/zowdy/zeno",
	git = "https://gitlab.com/Zillowe/Zillwen/Zowdy/Zeno",
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
})

function prepare()
	UTILS.FILE(url, archive)
	UTILS.EXTRACT(archive, "source")
end

function verify()
	return verifyHash(
		archive,
		"sha512-ca6126e0a4d517676df021128971ce75fa853d35b49f814fa1521f99c143831f2b2fbd4a3399f77ab834adcb19874c464a2c9ff2f48fa7d57283464ca62ede60"
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

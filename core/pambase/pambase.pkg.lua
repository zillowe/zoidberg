local version = ZOI.VERSION or "20260616"

metadata({
	name = "pambase",
	repo = "core",
	version = version,
	revision = "5",
	description = "Base PAM configuration for services",
	website = "https://zillowe.qzz.io/docs/parlex/linux",
	license = "GPL-3.0-or-later",
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
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/pam.d/system-auth",
		"${usrroot}/etc/pam.d/system-local-login",
		"${usrroot}/etc/pam.d/system-login",
		"${usrroot}/etc/pam.d/system-remote-login",
		"${usrroot}/etc/pam.d/system-services",
		"${usrroot}/etc/pam.d/other",
	},
})

local files = {
	"system-auth",
	"system-local-login",
	"system-login",
	"system-remote-login",
	"system-services",
	"other",
}

function prepare()
	-- Configuration files ship alongside this package definition
end

function package()
	for _, f in ipairs(files) do
		zcp("${pkgluadir}/files/" .. f, "${usrroot}/etc/pam.d/" .. f)
	end
	-- These configuration files have no upstream source tree, so the license
	-- text they are distributed under is committed next to this recipe.
	zlicense("${pkgluadir}/files/LICENSE.GPL-3.0-or-later", "LICENSE")
end

function test()
	-- zcp operations are staged after package() returns, so check the files
	-- this package ships rather than the staged root.
	for _, f in ipairs(files) do
		cmd([[test -s "$PKGLUADIR/files/$F"]], { check = true, env = { F = f } })
	end
	return true
end

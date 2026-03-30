local repo_owner = "athasdev"
local repo_name = "athas"
local version = ZOI.VERSION or "0.4.4"
local base_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. "/releases/download/v" .. version

metadata({
	name = "athas",
	repo = "main",
	version = version,
	description = "Lightweight code editor built with React, TypeScript, and Tauri",
	website = "https://athas.dev",
	git = "https://github.com/athasdev/athas",
	license = "AGPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = { name = "Athas Industries", website = "https://athas.dev" },
	bins = { "athas" },
	types = { "pre-compiled" },
	platforms = { "linux-amd64", "linux-arm64" },
	tags = { "editor", "ide", "tauri", "code" },
})

dependencies({
	runtime = {
		required = {
			"native:zlib",
			"native:gdk-pixbuf2",
			"native:libsoup3",
			"native:xz",
			"native:cairo",
			"native:gtk3",
			"native:glib2",
			"native:webkit2gtk-4.1",
			"native:hicolor-icon-theme",
		},
	},
})

function prepare()
	local arch = (SYSTEM.ARCH == "amd64") and "amd64" or "arm64"
	local url = string.format("%s/Athas_%s_%s.deb", base_url, version, arch)

	UTILS.EXTRACT(url, "extracted")
end

function package()
	zcp("extracted/usr/bin/athas", "${pkgstore}/bin/athas")
	zcp("extracted/usr/lib/Athas", "${usrroot}/lib/Athas")

	local desktop_file = "extracted/usr/share/applications/Athas.desktop"
	if UTILS.FS.exists(desktop_file) then
		cmd("sed -i -e 's/Categories=/Categories=TextEditor;Development;IDE;/g' " .. desktop_file)
		zcp(desktop_file, "${usrroot}/usr/share/applications/Athas.desktop")
	end

	zcp("extracted/usr/share/icons", "${usrroot}/usr/share/icons")
end

function verify()
	local arch = (SYSTEM.ARCH == "amd64") and "amd64" or "arm64"
	local filename = string.format("Athas_%s_%s.deb", version, arch)

	if arch == "amd64" then
		return verifyHash(filename, "sha256-fd36e7d785ee80018f89a58ee7147974a9c360b6612024dd17668dc3a3ffe6a1")
	end

	return true
end

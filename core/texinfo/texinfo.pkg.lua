local version = ZOI.VERSION or "7.3"

metadata({
	name = "texinfo",
	repo = "core",
	version = version,
	revision = "1",
	description = "GNU documentation system for on-line information and printed output",
	website = "https://www.gnu.org/software/texinfo/",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = {
		"info",
		"install-info",
		"makeinfo",
		"pdftexi2dvi",
		"pod2texi",
		"texi2any",
		"texi2dvi",
		"texi2pdf",
		"texindex",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:ncurses",
					"pacman:perl",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/gzip",
			"zoi:@core/ncurses",
			"zoi:@core/perl",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d "texinfo-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/pub/gnu/texinfo/texinfo-$VER.tar.xz" -o "texinfo-$VER.tar.xz"
			echo "51f74eb0f51cfa9873b85264dfdd5d46e8957ec95b88f0fb762f63d9e164c72e  texinfo-$VER.tar.xz" | sha256sum -c -
			tar -xf "texinfo-$VER.tar.xz"
		fi
	]])
end

function build()
	sh([[
		cd "texinfo-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "texinfo-$VER" DESTDIR="$ROOT" install
	]])

	-- Keeps /usr/share/info/dir in sync whenever info pages change
	zcp("${pkgluadir}/hooks/texinfo-info-dir.hook.yaml", "${pkgstore}/hooks/texinfo-info-dir.hook.yaml")
end

function test()
	cmd([[
		/usr/bin/makeinfo --version || makeinfo --version
	]])
end

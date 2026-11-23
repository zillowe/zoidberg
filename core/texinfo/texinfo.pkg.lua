local version = ZOI.VERSION or "7.3"
local sha512 = "fb1a16df67f870e79c31f4b96d8431d9c944eb84e5aa71e9d94890417ce63047918d55620fa63bd582232c47e9b412a6f95a11a2479f53f40e92e49bc018d926"
-- Release signing key (Gavin Smith), listed in Arch Linux's validpgpkeys.
local signing_key = "EAF669B31E31E1DECBD11513DDBC579DAB37FBA9"

metadata({
	name = "texinfo",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "texinfo-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/texinfo" \
				"https://mirrors.kernel.org/gnu/texinfo" \
				"https://ftp.gnu.org/gnu/texinfo"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "texinfo-$VER.tar.xz"
		fetch "texinfo-$VER.tar.xz.sig"
		echo "$SHA512  texinfo-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "texinfo-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "texinfo-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "texinfo-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("texinfo-" .. version .. "/COPYING")

	-- Keeps /usr/share/info/dir in sync whenever info pages change
	zcp("${pkgluadir}/hooks/texinfo-info-dir.hook.yaml", "${pkgstore}/hooks/texinfo-info-dir.hook.yaml")
end

function test()
	cmd([[
		/usr/bin/makeinfo --version || makeinfo --version
	]])
end

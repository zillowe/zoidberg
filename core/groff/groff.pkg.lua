local version = ZOI.VERSION or "1.25.0"
local sha512 = "a99dc11ff2398c13a2b644dca42b128e59e1ddb6ff73bfabd720953c785f85eda09a76d2ce92bc850365a658334af862c22d4ea00e1136616c50695eaa2b1e63"
-- Release signing key (G. Branden Robinson), listed in Arch Linux's validpgpkeys.
local signing_key = "8773D61D68E30E072B10DC1AD19E9C7D71266DCE"

metadata({
	name = "groff",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "GNU troff text-formatting system",
	website = "https://www.gnu.org/software/groff/groff.html",
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
		"eqn",
		"geqn",
		"groff",
		"grops",
		"grotty",
		"gtbl",
		"neqn",
		"nroff",
		"pic",
		"preconv",
		"soelim",
		"tbl",
		"troff",
		"zsoelim",
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
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:bison",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:m4",
					"pacman:make",
					"pacman:netpbm",
					"pacman:perl",
					"pacman:psutils",
					"pacman:texinfo",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
			"zoi:@core/perl",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "groff-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/groff" \
				"https://mirrors.kernel.org/gnu/groff" \
				"https://ftp.gnu.org/gnu/groff"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "groff-$VER.tar.gz"
		fetch "groff-$VER.tar.gz.sig"
		echo "$SHA512  groff-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "groff-$VER.tar.gz"]], opts)
end

function build()
	-- Parlex has no X11 or uchardet, so gxditview and preconv's charset
	-- detection are disabled rather than linked against the build host.
	-- Serial make: groff's build is not reliably parallel.
	cmd(
		[[
		cd "groff-$VER"
		./configure \
			--prefix=/usr \
			--without-x \
			--without-uchardet
		make
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "groff-$VER" DESTDIR="$ROOT" install

		# Compatibility symlinks
		ln -sf eqn "$ROOT/usr/bin/geqn"
		ln -sf tbl "$ROOT/usr/bin/gtbl"
		ln -sf soelim "$ROOT/usr/bin/zsoelim"

		cat "$PKGLUADIR/files/site.tmac" >> "$ROOT/usr/share/groff/site-tmac/man.local"
		cat "$PKGLUADIR/files/site.tmac" >> "$ROOT/usr/share/groff/site-tmac/mdoc.local"

		# No docs, no empty directories
		rm -rf "$ROOT/usr/share/doc"
		find "$ROOT" -type d -empty -delete
	]],
		opts
	)

	-- GPL-3.0-or-later overall; the man pages are also under the FDL, two
	-- libgroff files under the LGPLv3. LICENSES lists which file is under
	-- what, including the public-domain and BSD-style parts.
	local src = "groff-" .. version
	zlicense(src .. "/COPYING")
	zlicense(src .. "/FDL")
	zlicense(src .. "/LGPLv3")
	zlicense(src .. "/LICENSES")
end

function test()
	cmd([[
		/usr/bin/groff --version || groff --version
	]])
end

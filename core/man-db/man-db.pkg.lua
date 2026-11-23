local version = ZOI.VERSION or "2.13.3"
local sha512 = "e97bf13f0e37e4f7cb3d7ee7c32cf87874d311e17c4658ff050bfe34ec1cf5028dee254afa97aa6e49f096099f6b0a82266f277d1465edc416bb139e0fef474f"
-- Release signing key (Colin Watson), from upstream's published keys.
local signing_key = "AC0A4FF12611B6FCCF01C111393587D97D86500B"

metadata({
	name = "man-db",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "A utility for reading man pages",
	website = "https://man-db.gitlab.io/man-db/",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Colin Watson",
		website = "https://man-db.gitlab.io/man-db/",
	},
	bins = { "man", "apropos", "whatis", "mandb" },
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
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gdbm",
					"pacman:groff",
					"pacman:libpipeline",
					"pacman:libseccomp",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/gdbm",
			"zoi:@core/glibc",
			"zoi:@core/groff",
			"zoi:@core/less",
			"zoi:@core/libpipeline",
			"zoi:@core/libseccomp",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "man-db-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://download.savannah.nongnu.org/releases/man-db" \
				"https://download-mirror.savannah.gnu.org/releases/man-db"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "man-db-$VER.tar.xz"
		fetch "man-db-$VER.tar.xz.asc"
		echo "$SHA512  man-db-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "man-db-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "man-db-$VER"
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--sysconfdir=/etc \
			--libexecdir=/usr/lib \
			--with-systemdsystemunitdir=/usr/lib/systemd/system \
			--with-db=gdbm \
			--disable-setuid \
			--enable-cache-owner=root \
			--enable-mandirs=GNU \
			--with-sections="1 1p n l 8 3 3p 0 0p 2 3type 5 4 9 6 7"
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "man-db-$VER"
		make DESTDIR="$ROOT" install
		# Part of groff
		rm -f "$ROOT/usr/bin/zsoelim" "$ROOT/usr/share/man/man1/zsoelim.1"
	]],
		opts
	)
	-- COPYING is GPL-3; the GPL-2 text man-db is licensed under and the
	-- LGPL-2.1 of its bundled library code live in docs/.
	local src = "man-db-" .. version
	zlicense(src .. "/COPYING")
	zlicense(src .. "/docs/COPYING.GPLv2")
	zlicense(src .. "/docs/COPYING.LIB")
	-- Keeps the index `apropos` and `whatis` read up to date.
	zcp("${pkgluadir}/hooks/man-db.hook.yaml", "${pkgstore}/hooks/man-db.hook.yaml")
end

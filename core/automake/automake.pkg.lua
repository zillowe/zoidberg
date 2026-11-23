local version = ZOI.VERSION or "1.20"
local sha512 =
	"10a1836e4dc50b2b75da8892ce0a21451d2c001e46344c69d29c7d0c26d4910ba035c115aca55b9913761f7ff6d861db0619a0ff9c23be833d84c101867efadd"
-- Release signing key (Kamila Szewczyk), listed in Arch Linux's validpgpkeys.
local signing_key = "6C222EA6B2BD216AA406516AC868F0B6DE38409D"

metadata({
	name = "automake",
	repo = "core",
	version = version,
	revision = "1",
	description = "A GNU tool for automatically creating Makefiles",
	website = "https://www.gnu.org/software/automake",
	license = "GPL-2.0-or-later",
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
		"aclocal",
		"aclocal-" .. version,
		"automake",
		"automake-" .. version,
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
					"pacman:autoconf",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:patch",
					"pacman:perl",
					"pacman:texinfo",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/perl",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "automake-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/automake" \
				"https://mirrors.kernel.org/gnu/automake" \
				"https://ftp.gnu.org/gnu/automake"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "automake-$VER.tar.xz"
		fetch "automake-$VER.tar.xz.sig"
		echo "$SHA512  automake-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "automake-$VER.tar.xz"
		cd "automake-$VER"

		# Make tarballs from automake-generated `make dist` reproducible
		# (together with GZIP_ENV below)
		patch -Np1 -i "$PKGLUADIR/patches/enable-reproducible-builds.patch"
		# The patch only changes the installed tar.m4 macro. Keep its old
		# timestamp so make does not try to regenerate automake's own
		# aclocal.m4 and configure from it.
		touch -r aclocal.m4 m4/tar.m4
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "automake-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)" GZIP_ENV='-9 -n'
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "automake-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("automake-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/automake --version || automake --version
	]])
end

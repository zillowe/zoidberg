local version = ZOI.VERSION or "2.73"
local sha512 =
	"be051d542f9bd93752eccbdc9b1f3cf1fa4069a153ef34edd5303bfdf162e24d56e33e70df1b978cebb8d1139a82417bb8299cfe6c38cff8613040a829cc624f"
-- Release signing key (Zack Weinberg), listed in Arch Linux's validpgpkeys.
local signing_key = "82F854F3CE73174B8B63174091FCC32B6769AA64"

metadata({
	name = "autoconf",
	repo = "core",
	version = version,
	revision = "4",
	description = "A GNU tool for automatically configuring source code",
	website = "https://www.gnu.org/software/autoconf",
	license = "GPL-2.0-or-later AND GPL-3.0-or-later WITH Autoconf-exception-3.0",
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
		"autoconf",
		"autoheader",
		"autom4te",
		"autoreconf",
		"autoscan",
		"autoupdate",
		"ifnames",
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
					"pacman:m4",
					"pacman:make",
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
			"zoi:@core/diffutils",
			"zoi:@core/gawk",
			"zoi:@core/m4",
			"zoi:@core/perl",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "autoconf-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/autoconf" \
				"https://mirrors.kernel.org/gnu/autoconf" \
				"https://ftp.gnu.org/gnu/autoconf"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "autoconf-$VER.tar.xz"
		fetch "autoconf-$VER.tar.xz.sig"
		echo "$SHA512  autoconf-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "autoconf-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "autoconf-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "autoconf-$VER" DESTDIR="$ROOT" install

		# Don't ship the GNU coding standards manual
		rm -f "$ROOT/usr/share/info/standards.info"
	]],
		opts
	)

	zlicense("autoconf-" .. version .. "/COPYING")
	zlicense("autoconf-" .. version .. "/COPYINGv3")
	zlicense("autoconf-" .. version .. "/COPYING.EXCEPTION")
end

function test()
	cmd([[
		/usr/bin/autoconf --version || autoconf --version
	]])
end

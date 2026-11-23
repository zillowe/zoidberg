local version = ZOI.VERSION or "3.12"
local sha512 =
	"10b17cf1dcdfa9ca0e5db91d62c4a079ebe9fd7eafa3aaebd4eb7e6206e4d753f348496622aa281e1bd7f7fcde65ce4a886dcc4acbb59332ef980f224197b4e4"
-- Release signing key (Jim Meyering), listed in the GNU keyring.
local signing_key = "155D3FC500C834486D1EEA677FD9FCCB000BEEEE"

metadata({
	name = "diffutils",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Utility programs used for creating patch files",
	website = "https://www.gnu.org/software/diffutils",
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
	bins = { "cmp", "diff", "diff3", "sdiff" },
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
					"pacman:make",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "diffutils-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/diffutils" \
				"https://mirrors.kernel.org/gnu/diffutils" \
				"https://ftp.gnu.org/gnu/diffutils"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "diffutils-$VER.tar.xz"
		fetch "diffutils-$VER.tar.xz.sig"
		echo "$SHA512  diffutils-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "diffutils-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "diffutils-$VER"
		./configure \
			--prefix=/usr \
			--disable-gcc-warnings
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "diffutils-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("diffutils-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/diff --version || diff --version
	]])
end

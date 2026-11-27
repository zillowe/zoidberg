local version = ZOI.VERSION or "1.08.2"
local sha512 = "0876a4c5bfc23da79479519c6a8e03ac9f59ae54077eb71ffdcc6ddaccb76c4b7595b088e89e6ad82d833c072eeff5b378178084276584813c00eedace4c6f8c"
-- Release signing key (Ken Pizzini), as listed by Arch Linux.
local signing_key = "325B54E4653F935A25CF32BDA186278D426A38E9"

metadata({
	name = "bc",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "An arbitrary precision calculator language",
	website = "https://www.gnu.org/software/bc/",
	license = "GPL-3.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "bc", "dc" },
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
					-- The build edits generated sources with ed.
					"pacman:ed",
					"pacman:gcc",
					"pacman:make",
					"pacman:readline",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/readline",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "bc-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/bc" \
				"https://mirrors.kernel.org/gnu/bc" \
				"https://ftp.gnu.org/gnu/bc"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "bc-$VER.tar.gz"
		fetch "bc-$VER.tar.gz.sig"
		echo "$SHA512  bc-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "bc-$VER.tar.gz"]], opts)
end

function build()
	-- Options follow Arch Linux's PKGBUILD, including its serial make.
	cmd(
		[[
		cd "bc-$VER"
		./configure \
			--prefix=/usr \
			--mandir=/usr/share/man \
			--infodir=/usr/share/info \
			--with-readline
		make -j1
		echo quit | ./bc/bc -l Test/checklib.b
	]],
		opts
	)
end

function package()
	cmd([[make -C "bc-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("bc-" .. version .. "/COPYING")
end

function test()
	cmd([[echo '2^64' | "$ROOT/usr/bin/bc" | grep -qx 18446744073709551616]], opts)
	return true
end

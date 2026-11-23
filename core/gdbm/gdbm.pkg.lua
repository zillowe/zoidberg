local version = ZOI.VERSION or "1.26"
local sha512 = "44aafe254f0950a8f5215d8f1337674f07b19f2a375f6eb19a7e39690028c80c3774b705c2b76b470ae74042b21f2ca77d02f6f57aa2ee50296db801220a3352"
-- Release signing key (Sergey Poznyakoff), from upstream's published keys.
local signing_key = "4BE4E62655488EB92ABB468F79FFD94BFCE230B1"

metadata({
	name = "gdbm",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "GNU database library",
	website = "https://www.gnu.org/software/gdbm/",
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
	bins = { "gdbmtool", "gdbm_dump", "gdbm_load" },
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
	local tarball = "gdbm-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/gdbm" \
				"https://mirrors.kernel.org/gnu/gdbm" \
				"https://ftp.gnu.org/gnu/gdbm"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "gdbm-$VER.tar.gz"
		fetch "gdbm-$VER.tar.gz.sig"
		echo "$SHA512  gdbm-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "gdbm-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "gdbm-$VER"
		./configure --prefix=/usr --disable-static --enable-libgdbm-compat
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "gdbm-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "gdbm-" .. version
	zlicense(src .. "/COPYING")
	zdoc(src .. "/AUTHORS")
	zdoc(src .. "/NEWS")
	zdoc(src .. "/README")
end

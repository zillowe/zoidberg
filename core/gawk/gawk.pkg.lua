local version = ZOI.VERSION or "5.4.2"
local sha512 = "2d51e9788d1e39b3b6528a5c15d14282582c6c54bcf2678d0c57936556e65da6eed903bad03c8ddbde33322af5754710ea7dcaaa451a225b6f4271f10fb810ae"
-- Upstream signs releases (key D1967C63788713177D861ED7DF597815937EC0D2, Arnold Robbins),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "gawk",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "GNU version of awk",
	website = "https://www.gnu.org/software/gawk/",
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
	bins = { "gawk", "awk" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "awk" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:make",
					"pacman:mpfr",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/gmp",
			"zoi:@core/mpfr",
			"zoi:@core/readline",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/gawk" \
				"https://mirrors.kernel.org/gnu/gawk" \
				"https://ftp.gnu.org/gnu/gawk"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "gawk-$VER.tar.xz"
		echo "$SHA512  gawk-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "gawk-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "gawk-$VER"
		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--sysconfdir=/etc \
			--without-libsigsegv
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "gawk-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("gawk-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/gawk --version || gawk --version
	]])
end

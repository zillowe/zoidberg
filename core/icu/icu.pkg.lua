local version = ZOI.VERSION or "79.1"
local sha512 = "9098adf9ba7fbe11d92963415cc80bf09de39ce1372414dbc2561e5f8ef57479a9fe4b6f7abc61911e4659e5953be987c459297d29e61b064d1931a16195a973"
-- Release signing key (ICU Release Robot), matching Arch Linux's
-- validpgpkeys. The hash is upstream's, from the release's SHASUM512.txt,
-- whose signature by this key was checked when it was recorded.
local signing_key = "E52F07877A5805F9AF4AB0ACD46C5610D06E7001"

metadata({
	name = "icu",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "International Components for Unicode library",
	website = "https://icu.unicode.org",
	license = "Unicode-3.0 AND BSD-2-Clause AND BSD-3-Clause AND NAIST-2003",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Unicode, Inc.",
		website = "https://github.com/unicode-org/icu",
	},
	bins = {
		"derb",
		"genbrk",
		"gencfu",
		"gencnval",
		"gendict",
		"genrb",
		"icuexportdata",
		"icuinfo",
		"makeconv",
		"pkgdata",
		"uconv",
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
					"pacman:python",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "icu4c-" .. version .. "-sources.tgz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/unicode-org/icu/releases/download/release-$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "icu4c-$VER-sources.tgz"
		fetch "icu4c-$VER-sources.tgz.asc"
		echo "$SHA512  icu4c-$VER-sources.tgz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "icu4c-$VER-sources.tgz"]], opts)
end

function build()
	-- Options as Arch.
	cmd(
		[[
		# ICU's makefiles use $(TARGET); a TARGET in the environment (CI
		# sets one) would replace it and break the build.
		unset TARGET
		cd icu/source
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--mandir=/usr/share/man \
			--sbindir=/usr/bin
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		unset TARGET
		make -C icu/source DESTDIR="$ROOT" install
	]],
		opts
	)
	zlicense("icu/LICENSE")
end

function test()
	cmd([[
		/usr/bin/uconv --version || uconv --version
	]])
end

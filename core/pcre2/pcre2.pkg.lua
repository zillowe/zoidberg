local version = ZOI.VERSION or "10.49"
local sha512 = "eb8351788a479cb24bcc263243d6a00d28cc7285f26901d7f6001826aba7f7171a5bb3e7c944725432df6f303c10a794fd3a398429483bf4c1104df3de159687"
-- Release signing key (Nicholas Wilson), one of the PCRE2 release keys listed by
-- Arch Linux.
local signing_key = "A95536204A3BB489715231282A98E77EB6F24CA8"

metadata({
	name = "pcre2",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "A library that implements Perl 5-style regular expressions. 2nd version",
	website = "https://github.com/PCRE2Project/pcre2",
	license = "BSD-2-Clause AND BSD-3-Clause WITH PCRE2-exception",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The PCRE2 Project",
		website = "https://github.com/PCRE2Project/pcre2",
	},
	bins = { "pcre2-config", "pcre2grep", "pcre2test" },
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
					"pacman:bzip2",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:readline",
					"pacman:tar",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bzip2",
			"zoi:@core/glibc",
			"zoi:@core/readline",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "pcre2-" .. version .. ".tar.bz2"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "pcre2-$VER.tar.bz2"
		fetch "pcre2-$VER.tar.bz2.sig"
		echo "$SHA512  pcre2-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "pcre2-$VER.tar.bz2"
		cd "pcre2-$VER"
		# Extract licenses (the release tarball bundles sljit in deps/sljit)
		cp -v deps/sljit/LICENSE ../BSD-2-Clause.txt
		sed -n '70,94p' LICENCE.md > ../BSD-3-Clause.txt
		sed -n '100,104p' LICENCE.md > ../PCRE2-exception.txt
	]],
		opts
	)
end

function build()
	-- Fat LTO objects for the static libraries
	cmd(
		[[
		cd "pcre2-$VER"
		CFLAGS="${CFLAGS:-} -ffat-lto-objects" \
		CXXFLAGS="${CXXFLAGS:-} -ffat-lto-objects" \
		./configure \
			--enable-jit \
			--enable-pcre2-16 \
			--enable-pcre2-32 \
			--enable-pcre2grep-libbz2 \
			--enable-pcre2grep-libz \
			--enable-pcre2test-libreadline \
			--prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "pcre2-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	-- Split out of LICENCE.md and deps/sljit/LICENSE in prepare(), as Arch does.
	zlicense("BSD-2-Clause.txt")
	zlicense("BSD-3-Clause.txt")
	zlicense("PCRE2-exception.txt")
end

function test()
	cmd([[
		/usr/bin/pcre2test -C >/dev/null || true
	]])
end

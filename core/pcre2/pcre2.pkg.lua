local version = ZOI.VERSION or "10.49"

metadata({
	name = "pcre2",
	repo = "core",
	version = version,
	revision = "1",
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:bzip2",
					"pacman:gcc",
					"pacman:git",
					"pacman:libtool",
					"pacman:make",
					"pacman:readline",
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

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d pcre2 ]; then
			git clone --depth 1 --branch "pcre2-$VER" https://github.com/PCRE2Project/pcre2.git pcre2
			cd pcre2
			# Pulls sljit (deps/sljit)
			git submodule update --init
			./autogen.sh

			# Extract licenses
			cp -v deps/sljit/LICENSE ../BSD-2-Clause.txt
			sed -n '70,94p' LICENCE.md > ../BSD-3-Clause.txt
			sed -n '100,104p' LICENCE.md > ../PCRE2-exception.txt
		fi
	]])
end

function build()
	-- Fat LTO objects for the static libraries
	sh([[
		cd pcre2
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
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C pcre2 DESTDIR="$ROOT" install
		install -Dm644 BSD-2-Clause.txt BSD-3-Clause.txt PCRE2-exception.txt -t "$ROOT/usr/share/licenses/pcre2/"
	]])
end

function test()
	cmd([[
		/usr/bin/pcre2test -C >/dev/null || true
	]])
end

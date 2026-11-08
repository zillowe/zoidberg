local version = ZOI.VERSION or "6.3.0"

metadata({
	name = "gmp",
	repo = "core",
	version = version,
	revision = "1",
	description = "A free library for arbitrary precision arithmetic",
	website = "https://gmplib.org/",
	license = "GPL-2.0-or-later OR LGPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The GMP developers",
		website = "https://gmplib.org/",
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
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libtool",
					"pacman:lzip",
					"pacman:m4",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
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
		if [ ! -d "gmp-$VER" ]; then
			# gmplib.org is not always reachable from CI; fall back to GNU mirrors
			for url in \
				"https://gmplib.org/download/gmp/gmp-$VER.tar.lz" \
				"https://ftpmirror.gnu.org/gnu/gmp/gmp-$VER.tar.lz" \
				"https://mirrors.kernel.org/gnu/gmp/gmp-$VER.tar.lz"; do
				curl -sSfL --retry 3 "$url" -o "gmp-$VER.tar.lz" && break
			done
			echo "be5c908a7a836c3a9bd9d62aa58563c5e9e7fef94c43a7f42dbc35bb6d02733c  gmp-$VER.tar.lz" | sha256sum -c -
			tar -xf "gmp-$VER.tar.lz"
			cd "gmp-$VER"
			# Fix build with GCC 15
			patch -p1 < "$PKGLUADIR/gmp-gcc-15.patch"
			autoreconf -vif
		fi
	]])
end

function build()
	sh([[
		cd "gmp-$VER"
		LDFLAGS="${LDFLAGS:-} -Wl,-z,shstk" \
		./configure \
			--build=x86_64-pc-linux-gnu \
			--prefix=/usr \
			--enable-cxx \
			--enable-fat
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "gmp-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		test -e /usr/lib/libgmp.so || true
	]])
end

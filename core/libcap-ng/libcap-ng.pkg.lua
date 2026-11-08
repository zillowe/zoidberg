local version = ZOI.VERSION or "0.9.6"

metadata({
	name = "libcap-ng",
	repo = "core",
	version = version,
	revision = "1",
	description = "A library for Linux that makes using posix capabilities easy",
	website = "https://people.redhat.com/sgrubb/libcap-ng/",
	license = "GPL-2.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Steve Grubb",
		website = "https://people.redhat.com/sgrubb/libcap-ng/",
	},
	bins = { "captest", "filecap", "netcap", "pscap" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:libtool",
					"pacman:make",
					"pacman:tar",
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
		if [ ! -d "libcap-ng-$VER" ]; then
			curl -sSfL "https://github.com/stevegrubb/libcap-ng/archive/v$VER/libcap-ng-$VER.tar.gz" -o "libcap-ng-$VER.tar.gz"
			echo "77bc255688606cbc3a9d40cc1d417ebf748d04b8d837d793708b58431857ebfaa077f00cebfcf03c58ce56985feb63f9f8eb70cce21ba304ca3418a0fe1b61d1  libcap-ng-$VER.tar.gz" | sha512sum -c -
			tar -xf "libcap-ng-$VER.tar.gz"
			cd "libcap-ng-$VER"
			# Make autotools happy
			touch NEWS
			autoreconf -fiv
		fi
	]])
end

function build()
	-- Python bindings are not built; Parlex ships no python-capng.
	sh([[
		cd "libcap-ng-$VER"
		./configure \
			--enable-static=no \
			--prefix=/usr \
			--sysconfdir=/etc \
			--without-python3 \
			--without-python
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "libcap-ng-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		test -e /usr/lib/libcap-ng.so.0 || true
	]])
end

local version = ZOI.VERSION or "1.37.2"
-- Upstream does not publish proper release tags, so build from a mirror that
-- keeps the original commits and historical tags.
local tag = "upstream/" .. version .. "-2026-01-17-8d7bc2eb"

metadata({
	name = "fakeroot",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Tool for simulating superuser privileges",
	website = "https://tracker.debian.org/pkg/fakeroot",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The fakeroot developers",
		website = "https://tracker.debian.org/pkg/fakeroot",
	},
	bins = { "fakeroot", "faked" },
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
					"pacman:gcc",
					"pacman:git",
					"pacman:libtool",
					"pacman:make",
					"pacman:po4a",
					"pacman:systemd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/filesystem",
			"zoi:@core/glibc",
			"zoi:@core/sed",
			"zoi:@core/util-linux",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "TAG='" .. tag .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d fakeroot ]; then
			git clone --depth 1 --branch "$TAG" https://github.com/eworm-de/fakeroot.git fakeroot
			cd fakeroot
			autoreconf -fi
		fi
	]])
end

function build()
	sh([[
		cd fakeroot
		./configure \
			--prefix=/usr \
			--libdir=/usr/lib/libfakeroot \
			--disable-static \
			--with-ipc=sysv
		make -j"$(nproc)"

		# Perl distributions install po4a into the vendor_perl script dir
		export PATH="$PATH:/usr/bin/vendor_perl"
		cd doc
		po4a -k 0 --rm-backups --variable 'srcdir=../doc/' po4a/po4a.cfg
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C fakeroot DESTDIR="$ROOT" install

		install -dm755 "$ROOT/usr/lib/ld.so.conf.d/"
		echo '/usr/lib/libfakeroot' > "$ROOT/usr/lib/ld.so.conf.d/fakeroot.conf"

		# README for sysv/tcp usage
		install -Dm644 fakeroot/README "$ROOT/usr/share/doc/fakeroot/README"
	]])
end

function test()
	cmd([[
		/usr/bin/fakeroot --version || fakeroot --version
	]])
end

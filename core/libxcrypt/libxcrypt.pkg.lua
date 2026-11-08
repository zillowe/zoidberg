local version = ZOI.VERSION or "4.5.2"

metadata({
	name = "libxcrypt",
	repo = "core",
	version = version,
	revision = "1",
	description = "Modern library for one-way hashing of passwords",
	website = "https://github.com/besser82/libxcrypt/",
	license = "LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Björn Esser",
		website = "https://github.com/besser82/libxcrypt/",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "compat" },
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:perl",
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
		sub_packages = {
			main = {
				required = {
					"zoi:@core/glibc",
				},
			},
			compat = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/libxcrypt",
				},
			},
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
		if [ ! -d "libxcrypt-$VER" ]; then
			curl -sSfL "https://github.com/besser82/libxcrypt/releases/download/v$VER/libxcrypt-$VER.tar.xz" -o "libxcrypt-$VER.tar.xz"
			echo "71513a31c01a428bccd5367a32fd95f115d6dac50fb5b60c779d5c7942aec071  libxcrypt-$VER.tar.xz" | sha256sum -c -
			tar -xf "libxcrypt-$VER.tar.xz"
		fi
	]])
end

function build()
	-- GCC 16 with glibc's C23 strchr() flags -Wdiscarded-qualifiers in the
	-- yescrypt sources, which upstream builds with -Werror (configure has no
	-- switch for it), so demote just that warning.
	sh([[
		mkdir -p build-libxcrypt build-libxcrypt-compat
		export CFLAGS="${CFLAGS:--O2 -pipe} -Wno-error=discarded-qualifiers"

		cd build-libxcrypt
		"../libxcrypt-$VER/configure" \
			--prefix=/usr \
			--disable-static \
			--enable-hashes=strong,glibc \
			--enable-obsolete-api=no \
			--disable-failure-tokens
		make -j"$(nproc)"

		cd ../build-libxcrypt-compat
		"../libxcrypt-$VER/configure" \
			--prefix=/usr \
			--disable-static \
			--enable-hashes=strong,glibc \
			--enable-obsolete-api=glibc \
			--disable-failure-tokens
		make -j"$(nproc)"
	]])
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "compat" then
		-- Legacy API (libcrypt.so.1) only; headers and dev files come from main
		sh([[
			mkdir -p "$ROOT"
			make -C build-libxcrypt-compat DESTDIR="$ROOT" install
			rm -rf "$ROOT/usr/include" "$ROOT/usr/share" "$ROOT/usr/lib/pkgconfig"
			rm -f "$ROOT"/usr/lib/lib*.so
		]])
	else
		sh([[
			mkdir -p "$ROOT"
			make -C build-libxcrypt DESTDIR="$ROOT" install
		]])
	end
end

function test()
	cmd([[
		test -e /usr/lib/libcrypt.so.2 || true
	]])
end

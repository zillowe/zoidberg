local version = ZOI.VERSION or "4.5.2"
local sha512 = "87b363e2bdc03ea993a9d154eb59a75ef77edd0490a9b58d443de4e1b4eec5196408a1eb9b739718fd92f565fe5157469c1ea3d336a4a54ac0947750b16c44c1"
-- Release signing key (Björn Esser), as published with the release.
local signing_key = "678CE3FEE430311596DB8C16F52E98007594C21D"

metadata({
	name = "libxcrypt",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libxcrypt-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/besser82/libxcrypt/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libxcrypt-$VER.tar.xz"
		fetch "libxcrypt-$VER.tar.xz.asc"
		echo "$SHA512  libxcrypt-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libxcrypt-$VER.tar.xz"]], opts)
end

function build()
	-- GCC 16 with glibc's C23 strchr() flags -Wdiscarded-qualifiers in the
	-- yescrypt sources, which upstream builds with -Werror (configure has no
	-- switch for it), so demote just that warning.
	cmd(
		[[
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
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	-- Both sub-packages ship libcrypt: LGPL-2.1 text plus the per-file
	-- license inventory.
	zlicense("libxcrypt-" .. version .. "/COPYING.LIB")
	zlicense("libxcrypt-" .. version .. "/LICENSING")

	if sub == "compat" then
		-- Legacy API (libcrypt.so.1) only; headers and dev files come from main
		cmd(
			[[
			make -C build-libxcrypt-compat DESTDIR="$ROOT" install
			rm -rf "$ROOT/usr/include" "$ROOT/usr/share" "$ROOT/usr/lib/pkgconfig"
			rm -f "$ROOT"/usr/lib/lib*.so
		]],
			opts
		)
	else
		cmd(
			[[
			make -C build-libxcrypt DESTDIR="$ROOT" install
		]],
			opts
		)
	end
end

function test()
	cmd([[
		test -e /usr/lib/libcrypt.so.2 || true
	]])
end

local version = ZOI.VERSION or "0.26.6"
local sha512 = "bba7e5fdb6ad9805bfecf813b1308e7723c6d611e889864bd374a91db1a7100e001aa29fc635fe2dbc90975d32bc067e09d5310fabab0b3972fc50b763533838"
-- Release signing key (Zoltan Fridrich), from upstream's published keys.
local signing_key = "5D46CB0F763405A7053556F47A75A648B3F9220C"

metadata({
	name = "p11-kit",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Loads and enumerates PKCS#11 modules, and provides the system trust store",
	website = "https://p11-glue.github.io/p11-glue/p11-kit.html",
	license = "BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The p11-glue project",
		website = "https://p11-glue.github.io/p11-glue/",
	},
	bins = { "p11-kit", "trust" },
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
					"pacman:libffi",
					"pacman:libtasn1",
					"pacman:meson",
					"pacman:ninja",
					"pacman:pkgconf",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libffi",
			"zoi:@core/libtasn1",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	local tarball = "p11-kit-" .. version .. ".tar.xz"
	sh([[
		fetch() {
			for base in \
				"https://github.com/p11-glue/p11-kit/releases/download/$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "p11-kit-$VER.tar.xz"
		fetch "p11-kit-$VER.tar.xz.sig"
		echo "$SHA512  p11-kit-$VER.tar.xz" | sha512sum -c -
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "p11-kit-$VER.tar.xz"]])
end

function build()
	sh([[
		cd "p11-kit-$VER"
		meson setup _build \
			--prefix=/usr \
			--buildtype=plain \
			--libexecdir=lib \
			-Dtrust_paths=/etc/ca-certificates/trust-source:/usr/share/ca-certificates/trust-source \
			-Dlibffi=enabled \
			-Dsystemd=disabled \
			-Dbash_completion=disabled \
			-Dzsh_completion=disabled \
			-Dgtk_doc=false \
			-Dman=false \
			-Dtest=false
		meson compile -C _build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "p11-kit-$VER"
		meson install -C _build --destdir "$ROOT"
		ln -sf ../../bin/update-ca-trust "$ROOT/usr/lib/p11-kit/trust-extract-compat"
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/p11-kit/$(basename "$f")"
		done
		true
	]])
end

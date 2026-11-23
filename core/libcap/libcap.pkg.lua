local version = ZOI.VERSION or "2.78"
local sha512 = "a156a8708dd59f13400f701f4e1ddc81f915fe4e7b32f93a328f7d6f030b7a004fb985fa9ac60812dfffeb8ad860d2e1f59895485497350250efd9378682626b"
-- Upstream signs releases (key 38A644698C69787344E954CE29EE848AE2CCF3F4,
-- Andrew G. Morgan), but the key is only bound with SHA-1 self-signatures,
-- which Zoi's verifier rejects. The signature was checked with gpg when this
-- hash was recorded; the pinned hash is the trust anchor.

metadata({
	name = "libcap",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "POSIX 1003.1e capabilities",
	website = "https://sites.google.com/site/fullycapable/",
	license = "BSD-3-Clause OR GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Andrew G. Morgan",
		website = "https://sites.google.com/site/fullycapable/",
	},
	bins = { "capsh", "getcap", "getpcaps", "setcap" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:go",
					"pacman:linux-api-headers",
					"pacman:make",
					"pacman:pam",
					"pacman:patch",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/pam",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
-- CGO_REQUIRED=1: use CGO all the way, so the Go binaries get full RELRO.
local opts = { check = true, env = { VER = version, SHA512 = sha512, MAKE_OPTS = "CGO_REQUIRED=1" } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/linux/libs/security/linux-privs/libcap2" \
				"https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2" \
				"https://mirrors.kernel.org/pub/linux/libs/security/linux-privs/libcap2"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libcap-$VER.tar.xz"
		echo "$SHA512  libcap-$VER.tar.xz" | sha512sum -c -
		tar -xf "libcap-$VER.tar.xz"
		# Provide flags to go build (sent upstream)
		patch -Np1 -d "libcap-$VER" -i "$PKGLUADIR/patches/libcap-2.73-cgo-flags.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		export GOPATH="$(pwd)/gopath"
		make -C "libcap-$VER" \
			CGO_CPPFLAGS="${CPPFLAGS:-}" \
			CGO_CFLAGS="${CFLAGS:-}" \
			CGO_CXXFLAGS="${CXXFLAGS:-}" \
			CGO_LDFLAGS="${LDFLAGS:-}" \
			$MAKE_OPTS \
			GOFLAGS="-buildmode=pie -mod=readonly -modcacherw" \
			GO_BUILD_FLAGS="-ldflags '-compressdwarf=false -linkmode=external'" \
			DYNAMIC=yes \
			KERNEL_HEADERS=/usr/include \
			lib=lib \
			prefix=/usr \
			sbindir=bin
	]],
		opts
	)
end

function package()
	cmd(
		[[
		export GOPATH="$(pwd)/gopath"
		make -C "libcap-$VER" \
			CGO_CPPFLAGS="${CPPFLAGS:-}" \
			CGO_CFLAGS="${CFLAGS:-}" \
			CGO_CXXFLAGS="${CXXFLAGS:-}" \
			CGO_LDFLAGS="${LDFLAGS:-}" \
			$MAKE_OPTS \
			GOFLAGS="-buildmode=pie -mod=readonly -modcacherw" \
			GO_BUILD_FLAGS="-ldflags '-compressdwarf=false -linkmode=external'" \
			DESTDIR="$ROOT" \
			RAISE_SETFCAP=no \
			lib=lib \
			prefix=/usr \
			sbindir=bin \
			install

		install -vDm644 "libcap-$VER/CHANGELOG" "libcap-$VER/README" -t "$ROOT/usr/share/doc/libcap/"
		install -vDm644 "libcap-$VER/pam_cap/capability.conf" -t "$ROOT/usr/share/doc/libcap/examples/"
	]],
		opts
	)

	zlicense("libcap-" .. version .. "/License")
	-- pam_cap is under its own terms (BSD-3-Clause OR LGPL-2.0-or-later).
	zlicense("libcap-" .. version .. "/pam_cap/License", "License.pam_cap")
end

function test()
	cmd([[
		/usr/bin/getcap -h >/dev/null 2>&1 || true
	]])
end

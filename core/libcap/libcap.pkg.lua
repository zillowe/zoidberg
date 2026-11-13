local version = ZOI.VERSION or "2.78"

metadata({
	name = "libcap",
	repo = "core",
	version = version,
	revision = "2",
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
					"pacman:gcc",
					"pacman:git",
					"pacman:go",
					"pacman:linux-api-headers",
					"pacman:make",
					"pacman:pam",
					"pacman:patch",
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

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "ROOT='" .. root .. "'\n"
		-- Use CGO all the way, so the Go binaries get full RELRO
		.. "export GOPATH=\"$(pwd)/gopath\"\n"
		.. "MAKE_OPTS='CGO_REQUIRED=1'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d libcap ]; then
			git clone --depth 1 --branch "sig-libcap-$VER" https://git.kernel.org/pub/scm/libs/libcap/libcap.git libcap
			# Provide flags to go build (sent upstream)
			patch -Np1 -d libcap -i "$PKGLUADIR/libcap-2.73-cgo-flags.patch"
		fi
	]])
end

function build()
	sh([[
		make -C libcap \
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
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C libcap \
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

		install -vDm644 libcap/CHANGELOG libcap/README -t "$ROOT/usr/share/doc/libcap/"
		install -vDm644 libcap/License -t "$ROOT/usr/share/licenses/libcap/"
		install -vDm644 libcap/pam_cap/capability.conf -t "$ROOT/usr/share/doc/libcap/examples/"
	]])
end

function test()
	cmd([[
		/usr/bin/getcap -h >/dev/null 2>&1 || true
	]])
end

local version = ZOI.VERSION or "0.28"

metadata({
	name = "libisl",
	repo = "core",
	version = version,
	revision = "1",
	description = "Library for manipulating sets and relations of integer points bounded by linear constraints",
	website = "https://libisl.sourceforge.io",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Sven Verdoolaege",
		website = "https://libisl.sourceforge.io",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "isl" },
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
					"pacman:gmp",
					"pacman:make",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/gmp",
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
		if [ ! -d "isl-$VER" ]; then
			# libisl.sourceforge.io rejects some CI networks; fall back to the
			# SourceForge download mirrors
			for url in \
				"https://libisl.sourceforge.io/isl-$VER.tar.xz" \
				"https://downloads.sourceforge.net/project/libisl/isl-$VER.tar.xz"; do
				curl -sSfL --retry 3 "$url" -o "isl-$VER.tar.xz" && break
			done
			echo "8d14052a11bbba409b163e979652e489000e3ab9a13a70f9c6088757da47079eb79128ae59513727214e2906f82e6416d7f91444f0f80121bfbb5085a9f44647  isl-$VER.tar.xz" | b2sum -c -
			tar -xf "isl-$VER.tar.xz"
		fi
	]])
end

function build()
	sh([[
		cd "isl-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "isl-$VER" DESTDIR="$ROOT" install

		install -dm755 "$ROOT/usr/share/gdb/auto-load/usr/lib/"
		mv "$ROOT"/usr/lib/libisl.so.*-gdb.py "$ROOT/usr/share/gdb/auto-load/usr/lib/"

		install -Dm644 "isl-$VER/LICENSE" "$ROOT/usr/share/licenses/libisl/LICENSE"
	]])
end

function test()
	cmd([[
		test -e /usr/lib/libisl.so || true
	]])
end

local version = ZOI.VERSION or "3.12"

metadata({
	name = "diffutils",
	repo = "core",
	version = version,
	revision = "1",
	description = "Utility programs used for creating patch files",
	website = "https://www.gnu.org/software/diffutils",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "cmp", "diff", "diff3", "sdiff" },
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
					"pacman:gettext",
					"pacman:git",
					"pacman:gperf",
					"pacman:help2man",
					"pacman:make",
					"pacman:python",
					"pacman:tar",
					"pacman:texinfo",
					"pacman:wget",
					"pacman:xz",
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
		if [ ! -d diffutils ]; then
			git clone --branch "v$VER" https://git.savannah.gnu.org/git/diffutils.git diffutils
			cd diffutils
			git submodule update --init
			# Translations come from the release tarball below
			./bootstrap --skip-po
			cd ..
		fi

		if [ ! -d "diffutils-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/gnu/diffutils/diffutils-$VER.tar.xz" -o "diffutils-$VER.tar.xz"
			tar -xf "diffutils-$VER.tar.xz"
		fi
	]])
end

function build()
	sh([[
		cd diffutils
		./configure \
			--prefix=/usr \
			--disable-gcc-warnings
		make -j"$(nproc)"

		# Generate diffutils mo files from the dist tarball
		cd "../diffutils-$VER/po"
		for po in *.po; do
			msgfmt "$po" -o "${po%.po}.mo"
		done
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C diffutils DESTDIR="$ROOT" install

		cd "diffutils-$VER/po"
		for mo in *.mo; do
			install -Dm644 "$mo" "$ROOT/usr/share/locale/${mo%.mo}/LC_MESSAGES/diffutils.mo"
		done
	]])
end

function test()
	cmd([[
		/usr/bin/diff --version || diff --version
	]])
end

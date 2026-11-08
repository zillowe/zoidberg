local version = ZOI.VERSION or "1.4.21"

metadata({
	name = "m4",
	repo = "core",
	version = version,
	revision = "1",
	description = "The GNU macro processor",
	website = "https://www.gnu.org/software/m4",
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
	bins = { "m4" },
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
		if [ ! -d m4 ]; then
			git clone --branch "v$VER" https://git.savannah.gnu.org/git/m4.git m4
			cd m4
			git submodule update --init
			# Translations come from the release tarball below
			./bootstrap --skip-po
			cd ..
		fi

		if [ ! -d "m4-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/gnu/m4/m4-$VER.tar.xz" -o "m4-$VER.tar.xz"
			tar -xf "m4-$VER.tar.xz"
		fi
	]])
end

function build()
	sh([[
		cd m4
		# git builds set -Werror and -fanalyzer, both of which fail
		./configure \
			--prefix=/usr \
			--disable-gcc-warnings
		make -j"$(nproc)"

		# Generate m4 mo files from the dist tarball
		cd "../m4-$VER/po"
		for po in *.po; do
			msgfmt "$po" -o "${po%.po}.mo"
		done
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C m4 DESTDIR="$ROOT" install

		cd "m4-$VER/po"
		for mo in *.mo; do
			install -Dm644 "$mo" "$ROOT/usr/share/locale/${mo%.mo}/LC_MESSAGES/m4.mo"
		done
	]])
end

function test()
	cmd([[
		/usr/bin/m4 --version || m4 --version
	]])
end

local version = ZOI.VERSION or "1.24.2"

metadata({
	name = "groff",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "GNU troff text-formatting system",
	website = "https://www.gnu.org/software/groff/groff.html",
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
	bins = {
		"eqn",
		"geqn",
		"groff",
		"grops",
		"grotty",
		"gtbl",
		"neqn",
		"nroff",
		"pic",
		"preconv",
		"soelim",
		"tbl",
		"troff",
		"zsoelim",
	},
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
					"pacman:bison",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:m4",
					"pacman:make",
					"pacman:netpbm",
					"pacman:perl",
					"pacman:psutils",
					"pacman:texinfo",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
			"zoi:@core/perl",
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
		if [ ! -d groff ]; then
			git clone --branch "$VER" https://git.savannah.gnu.org/git/groff.git groff
			cd groff
			git submodule update --init
			./bootstrap
		fi
	]])
end

function build()
	-- Parlex has no X11 or uchardet, so gxditview and preconv's charset
	-- detection are disabled rather than linked against the build host.
	-- Serial make: groff's build is not reliably parallel.
	sh([[
		cd groff
		./configure \
			--prefix=/usr \
			--without-x \
			--without-uchardet
		make
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C groff DESTDIR="$ROOT" install

		# Compatibility symlinks
		ln -sf eqn "$ROOT/usr/bin/geqn"
		ln -sf tbl "$ROOT/usr/bin/gtbl"
		ln -sf soelim "$ROOT/usr/bin/zsoelim"

		cat "$PKGLUADIR/site.tmac" >> "$ROOT/usr/share/groff/site-tmac/man.local"
		cat "$PKGLUADIR/site.tmac" >> "$ROOT/usr/share/groff/site-tmac/mdoc.local"

		# No docs, no empty directories
		rm -rf "$ROOT/usr/share/doc"
		find "$ROOT" -type d -empty -delete
	]])
end

function test()
	cmd([[
		/usr/bin/groff --version || groff --version
	]])
end

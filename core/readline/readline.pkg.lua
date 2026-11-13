local version = ZOI.VERSION or "8.3.6"
local patchlevel = string.match(version, "%.(%d+)$") or "0"
local basever = string.gsub(version, "%.%d+$", "")
if basever == version then
	basever = version
	patchlevel = "0"
end

local tar_url = string.format("https://ftp.gnu.org/gnu/readline/readline-%s.tar.gz", basever)

metadata({
	name = "readline",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "GNU readline library",
	website = "https://tiswww.case.edu/php/chet/readline/rltop.html",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Chet Ramey",
		website = "https://tiswww.case.edu/php/chet/readline/rltop.html",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/inputrc",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:make",
					"pacman:ncurses",
					"pacman:patch",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "readline-%s" ]; then
			curl -sSL "%s" -o "readline-%s.tar.gz"
			tar -xf "readline-%s.tar.gz"
		fi

		cd "readline-%s"

		# Download and apply official GNU point patches
		_plevel=%s
		_bver_flat=$(echo "%s" | tr -d '.')
		for (( _p=1; _p <= _plevel; _p++ )); do
			_patch_num=$(printf "%%03d" $_p)
			_patch_name="readline${_bver_flat}-${_patch_num}"
			if [ ! -f ".applied_${_patch_name}" ]; then
				echo "Applying $_patch_name..."
				curl -sSL "https://ftp.gnu.org/gnu/readline/readline-%s-patches/${_patch_name}" | patch -p0 || true
				touch ".applied_${_patch_name}"
			fi
		done

		# Remove RPATH from shared objects
		sed -i 's|-Wl,-rpath,$(libdir) ||g' support/shobj-conf
	]],
		basever,
		tar_url,
		basever,
		basever,
		basever,
		patchlevel,
		basever,
		basever
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "readline-%s"

		CFLAGS="${CFLAGS} -fPIC"
		./configure --prefix=/usr
		make -j"$(nproc)" SHLIB_LIBS=-lncurses
	]],
		basever
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")
	local pkgdir = LOCATION.PKGLUADIR or "."

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		PKGLUADIR="%s"
		mkdir -p "$ROOT/etc"

		make -C "readline-%s" DESTDIR="$ROOT" install
		install -m644 "${PKGLUADIR}/inputrc" "$ROOT/etc/inputrc"
	]],
		root,
		pkgdir,
		basever
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		test -f /usr/lib/libreadline.so || true
	]])
end

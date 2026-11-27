local version = ZOI.VERSION or "9.2.1202"
local sha512 = "2ab35cb6bcc33e25b7e24d279e7b287f33b46abcbc74d2a43eaf4f7f0693cb195d76bc1ca7d8c763010e811ae803c7872814a9fbac448a501e01e9f5b8b5b472"
-- Upstream publishes no release tarballs, only signed git tags; this is
-- GitHub's archive of the tag, pinned by hash. The hash matches Gentoo's
-- Manifest (sha512), which may pin a few patch levels past Arch Linux.
-- The runtime directory is named after the major and minor version (vim92).
local major, minor = string.match(version, "^(%d+)%.(%d+)")
local versiondir = (major or "9") .. (minor or "2")

metadata({
	name = "vim",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Vi Improved, a highly configurable, improved version of the vi text editor",
	website = "https://www.vim.org",
	license = "Vim",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Bram Moolenaar and the Vim contributors",
		website = "https://www.vim.org",
	},
	-- ex and view are left to vi, as in Arch Linux.
	bins = { "vim", "vimdiff", "vimtutor", "rvim", "rview", "xxd" },
	provides = { "xxd" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/vimrc",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:acl",
					"pacman:gawk",
					"pacman:gcc",
					"pacman:libgcrypt",
					"pacman:make",
					"pacman:ncurses",
					"pacman:zlib",
					-- Headers for the interpreters vim loads with dlopen()
					-- when present; none becomes a hard dependency.
					"pacman:lua",
					"pacman:perl",
					"pacman:python",
					"pacman:ruby",
					"pacman:tcl",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/acl",
			"zoi:@core/glibc",
			"zoi:@core/libgcrypt",
			"zoi:@core/ncurses",
			"zoi:@core/zlib",
		},
		optional = {
			"zoi:@core/perl: Perl language support",
			"zoi:@core/python: Python language support",
			"zoi:@core/tcl: Tcl language support",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = { VER = version, SHA512 = sha512, VERSIONDIR = versiondir },
}

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/vim/vim/archive/refs/tags/v$VER.tar.gz" \
			-o "vim-$VER.tar.gz"
		echo "$SHA512  vim-$VER.tar.gz" | sha512sum -c -
		tar -xf "vim-$VER.tar.gz"
		cd "vim-$VER/src"
		# As Arch Linux: the global vimrc is /etc/vimrc.
		sed -E 's|^.*(#define SYS_.*VIMRC_FILE.*").*$|\1|g' -i feature.h
		sed -E 's|^.*(#define VIMRC_FILE.*").*$|\1|g' -i feature.h
		autoconf
	]],
		opts
	)
end

function build()
	-- Options follow Arch Linux's terminal vim, except: gpm (console mouse)
	-- is off because Zoidberg has no gpm package, and the build is credited
	-- to Zoidberg. Arch's GUI build (gvim) needs GTK and is not packaged.
	cmd(
		[[
		cd "vim-$VER"
		./configure \
			--prefix=/usr \
			--localstatedir=/var/lib/vim \
			--with-features=huge \
			--with-compiledby='Zoidberg (ZoiOS)' \
			--with-wayland=no \
			--disable-gpm \
			--enable-acl \
			--with-x=no \
			--disable-gui \
			--disable-pixman \
			--enable-multibyte \
			--enable-cscope \
			--enable-netbeans \
			--enable-perlinterp=dynamic \
			--enable-python3interp=dynamic \
			--enable-rubyinterp=dynamic \
			--enable-luainterp=dynamic \
			--enable-tclinterp=dynamic \
			--disable-canberra
		make
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "vim-$VER"
		make -j1 VIMRCLOC=/etc DESTDIR="$ROOT" install

		# ex and view come from vi, as in Arch Linux; evim needs a GUI.
		rm "$ROOT"/usr/bin/ex "$ROOT"/usr/bin/view
		find "$ROOT/usr/share/man" -type d -name man1 | while read -r mandir; do
			rm -f "$mandir/ex.1" "$mandir/view.1" "$mandir/evim.1"
		done
		rm -f "$ROOT/usr/share/applications/gvim.desktop"

		install -Dm644 runtime/ftplugin/logtalk.dict \
			"$ROOT/usr/share/vim/vim$VERSIONDIR/ftplugin/logtalk.dict"
		install -Dm644 "$PKGLUADIR/files/vimrc" "$ROOT/etc/vimrc"
		install -Dm644 "$PKGLUADIR/files/zoios.vim" \
			"$ROOT/usr/share/vim/vimfiles/zoios.vim"
	]],
		opts
	)
	-- Regenerates the help tags of plugins installed into vimfiles/doc
	zcp("${pkgluadir}/hooks/vimdoc.hook.yaml", "${pkgstore}/hooks/vim-helptags.hook.yaml")

	zlicense("vim-" .. version .. "/runtime/doc/uganda.txt", "license.txt")
end

function test()
	cmd([["$ROOT/usr/bin/vim" --version | head -n 1 | grep -q 'VIM - Vi IMproved']], opts)
	return true
end

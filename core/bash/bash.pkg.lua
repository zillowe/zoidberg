local version = ZOI.VERSION or "5.3.20"
local basever = string.match(version, "^(%d+%.%d+)")
local patchlevel = string.match(version, "^%d+%.%d+%.(%d+)$") or "0"
local sha512 =
	"426702c8b0fb9e0c9956259973ce5b657890fd47f4f807a64febf20077bb48d0b91474ed6e843d2ef277186b46c5fffa79b808da9b48d4ec027d5e2de1b28ed8"
-- Upstream signs releases and patches (key 7C0135FB088AAF6C66C650B9BB5869F064EA74AB,
-- Chet Ramey), but the key is only bound with SHA-1 self-signatures, which
-- Zoi's verifier rejects. The signatures were checked with gpg when this hash
-- and the patches were recorded; the pinned hash is the trust anchor.

metadata({
	name = "bash",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "The GNU Bourne Again shell",
	website = "https://www.gnu.org/software/bash/bash.html",
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
	bins = { "bash", "sh", "rbash" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/bash.bashrc",
		"${usrroot}/etc/bash.bash_logout",
		"${usrroot}/etc/skel/.bashrc",
		"${usrroot}/etc/skel/.bash_profile",
		"${usrroot}/etc/skel/.bash_logout",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:bison",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:make",
					"pacman:ncurses",
					"pacman:patch",
					"pacman:readline",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
			"zoi:@core/readline",
		},
	},
})

hooks({
	post_install = {
		"[ -f /etc/shells ] && grep -qe '^/bin/bash$' /etc/shells || echo '/bin/bash' >> /etc/shells",
		"[ -f /etc/shells ] && grep -qe '^/usr/bin/bash$' /etc/shells || echo '/usr/bin/bash' >> /etc/shells",
		"[ -f /etc/shells ] && grep -qe '^/bin/sh$' /etc/shells || echo '/bin/sh' >> /etc/shells",
		"[ -f /etc/shells ] && grep -qe '^/usr/bin/sh$' /etc/shells || echo '/usr/bin/sh' >> /etc/shells",
	},
	post_upgrade = {
		"[ -f /etc/shells ] && grep -qe '^/bin/bash$' /etc/shells || echo '/bin/bash' >> /etc/shells",
		"[ -f /etc/shells ] && grep -qe '^/usr/bin/bash$' /etc/shells || echo '/usr/bin/bash' >> /etc/shells",
		"[ -f /etc/shells ] && grep -qe '^/bin/sh$' /etc/shells || echo '/bin/sh' >> /etc/shells",
		"[ -f /etc/shells ] && grep -qe '^/usr/bin/sh$' /etc/shells || echo '/usr/bin/sh' >> /etc/shells",
	},
})

local opts = { check = true, env = { BASEVER = basever, PLEVEL = patchlevel, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/bash" \
				"https://ftp.gnu.org/gnu/bash" \
				"https://mirrors.kernel.org/gnu/bash"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "bash-$BASEVER.tar.gz"
		echo "$SHA512  bash-$BASEVER.tar.gz" | sha512sum -c -
		tar -xf "bash-$BASEVER.tar.gz"
	]],
		opts
	)
	cmd(
		[[
		cd "bash-$BASEVER"
		flat=$(echo "$BASEVER" | tr -d '.')
		p=1
		while [ "$p" -le "$PLEVEL" ]; do
			patch -p0 -i "$PKGLUADIR/patches/bash$flat-$(printf '%03d' "$p")"
			p=$((p + 1))
		done
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "bash-$BASEVER"

		_bashconfig=(
			-DDEFAULT_PATH_VALUE=\'\"/usr/local/sbin:/usr/local/bin:/usr/bin\"\'
			-DSTANDARD_UTILS_PATH=\'\"/usr/bin\"\'
			-DSYS_BASHRC=\'\"/etc/bash.bashrc\"\'
			-DSYS_BASH_LOGOUT=\'\"/etc/bash.bash_logout\"\'
			-DNON_INTERACTIVE_LOGIN_SHELLS
			-std=gnu17
		)
		export CFLAGS="${CFLAGS} ${_bashconfig[@]}"

		touch -c aclocal.m4 configure Makefile.in y.tab.c y.tab.h

		./configure \
			--prefix=/usr \
			--with-curses \
			--enable-readline \
			--without-bash-malloc \
			--with-installed-readline

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/usr/bin "$ROOT"/etc/skel

		make -C "bash-$BASEVER" DESTDIR="$ROOT" install
		ln -sf bash "$ROOT/usr/bin/sh"
		ln -sf bash "$ROOT/usr/bin/rbash"

		# System-wide configuration files
		install -m644 "$PKGLUADIR/files/system.bashrc" "$ROOT/etc/bash.bashrc"
		install -m644 "$PKGLUADIR/files/system.bash_logout" "$ROOT/etc/bash.bash_logout"

		# User configuration file skeletons
		install -m644 "$PKGLUADIR/files/dot.bashrc" "$ROOT/etc/skel/.bashrc"
		install -m644 "$PKGLUADIR/files/dot.bash_profile" "$ROOT/etc/skel/.bash_profile"
		install -m644 "$PKGLUADIR/files/dot.bash_logout" "$ROOT/etc/skel/.bash_logout"
	]],
		opts
	)

	zlicense("bash-" .. basever .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/bash --version || bash --version
	]])
end

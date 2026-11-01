local version = ZOI.VERSION or "5.3.20"
local patchlevel = string.match(version, "%.(%d+)$") or "0"
local basever = string.gsub(version, "%.%d+$", "")
if basever == version then
	basever = version
	patchlevel = "0"
end

local tar_url = string.format("https://ftp.gnu.org/gnu/bash/bash-%s.tar.gz", basever)

metadata({
	name = "bash",
	repo = "core",
	version = version,
	revision = "1",
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
	platforms = { "linux" },
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "bash-%s" ]; then
			curl -sSL "%s" -o "bash-%s.tar.gz"
			tar -xf "bash-%s.tar.gz"
		fi

		cd "bash-%s"

		# Download and apply official GNU point patches
		_plevel=%s
		_bver_flat=$(echo "%s" | tr -d '.')
		for (( _p=1; _p <= _plevel; _p++ )); do
			_patch_num=$(printf "%%03d" $_p)
			_patch_name="bash${_bver_flat}-${_patch_num}"
			if [ ! -f ".applied_${_patch_name}" ]; then
				echo "Applying $_patch_name..."
				curl -sSL "https://ftp.gnu.org/gnu/bash/bash-%s-patches/${_patch_name}" | patch -p0 || true
				touch ".applied_${_patch_name}"
			fi
		done
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
		cd "bash-%s"

		_bashconfig=(
			-DDEFAULT_PATH_VALUE='"/usr/local/sbin:/usr/local/bin:/usr/bin"'
			-DSTANDARD_UTILS_PATH='"/usr/bin"'
			-DSYS_BASHRC='"/etc/bash.bashrc"'
			-DSYS_BASH_LOGOUT='"/etc/bash.bash_logout"'
			-DNON_INTERACTIVE_LOGIN_SHELLS
			-std=gnu17
		)
		export CFLAGS="${CFLAGS} ${_bashconfig[*]}"

		./configure \
			--prefix=/usr \
			--with-curses \
			--enable-readline \
			--without-bash-malloc \
			--with-installed-readline

		make -j"$(nproc)"
	]],
		basever
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"/usr/bin "$ROOT"/etc/skel

		make -C "bash-%s" DESTDIR="$ROOT" install
		ln -sf bash "$ROOT/usr/bin/sh"
		ln -sf bash "$ROOT/usr/bin/rbash"

		# System-wide configuration files
		install -m644 "${PKGLUADIR}/system.bashrc" "$ROOT/etc/bash.bashrc"
		install -m644 "${PKGLUADIR}/system.bash_logout" "$ROOT/etc/bash.bash_logout"

		# User configuration file skeletons
		install -m644 "${PKGLUADIR}/dot.bashrc" "$ROOT/etc/skel/.bashrc"
		install -m644 "${PKGLUADIR}/dot.bash_profile" "$ROOT/etc/skel/.bash_profile"
		install -m644 "${PKGLUADIR}/dot.bash_logout" "$ROOT/etc/skel/.bash_logout"
	]],
		root,
		basever
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/bash --version || bash --version
	]])
end

local version = ZOI.VERSION or "2.16"
local tag = "grub-" .. version
local git_url = "https://gitlab.freedesktop.org/gnu-grub/grub.git"

metadata({
	name = "grub",
	repo = "core",
	version = version,
	revision = "1",
	description = "GNU GRand Unified Bootloader (2)",
	website = "https://www.gnu.org/software/grub/",
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
		"grub-editenv",
		"grub-fstest",
		"grub-glue-efi",
		"grub-install",
		"grub-kbdcomp",
		"grub-macbless",
		"grub-menulst2cfg",
		"grub-mkconfig",
		"grub-mkfont",
		"grub-mkimage",
		"grub-mklayout",
		"grub-mknetdir",
		"grub-mkpasswd-pbkdf2",
		"grub-mkrelpath",
		"grub-mkrescue",
		"grub-mkstandalone",
		"grub-mount",
		"grub-probe",
		"grub-reboot",
		"grub-render-label",
		"grub-script-check",
		"grub-set-default",
		"grub-syslinux2cfg",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/default/grub",
		"${usrroot}/etc/grub.d/40_custom",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:autogen",
					"pacman:bison",
					"pacman:device-mapper",
					"pacman:flex",
					"pacman:freetype2",
					"pacman:fuse3",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:help2man",
					"pacman:libusb",
					"pacman:make",
					"pacman:python",
					"pacman:rsync",
					"pacman:texinfo",
					"pacman:ttf-dejavu",
					"pacman:wget",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/xz",
		},
	},
})

hooks({
	post_install = {
		[[
		echo ":: Install your bootloader and generate configuration with:"
		echo "     # grub-install /dev/sdX (or --target=x86_64-efi --efi-directory=/boot)"
		echo "     # grub-mkconfig -o /boot/grub/grub.cfg"
		]],
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d grub ]; then
			git clone --depth 1 --branch "%s" "%s" grub
		fi

		cd grub
		if [ -f "${PKGLUADIR}/0001-00_header-add-GRUB_COLOR_-variables.patch" ]; then
			patch -Np1 -i "${PKGLUADIR}/0001-00_header-add-GRUB_COLOR_-variables.patch" || true
		fi
		if [ -f "${PKGLUADIR}/0002-10_linux-detect-parlex-initramfs.patch" ]; then
			patch -Np1 -i "${PKGLUADIR}/0002-10_linux-detect-parlex-initramfs.patch" || true
		fi
		if [ -f "${PKGLUADIR}/0003-support-dropins-for-default-configuration.patch" ]; then
			patch -Np1 -i "${PKGLUADIR}/0003-support-dropins-for-default-configuration.patch" || true
		fi

		sed -i 's|GNU/Linux|Linux|' util/grub.d/10_linux.in 2>/dev/null || true
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd grub

		./autogen.sh || true

		# x86_64-efi build
		./configure \
			--prefix=/usr \
			--bindir=/usr/bin \
			--sbindir=/usr/bin \
			--mandir=/usr/share/man \
			--infodir=/usr/share/info \
			--sysconfdir=/etc \
			--with-bootdir=boot \
			--with-grubdir=grub \
			--with-platform=efi \
			--target=x86_64 \
			--enable-boot-time \
			--enable-cache-stats

		make -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"/etc/default "$ROOT"/etc/grub.d "$ROOT"/boot/grub
		make -C grub DESTDIR="$ROOT" bashcompletiondir="/usr/share/bash-completion/completions" install

		if [ -f "${PKGLUADIR}/grub.default" ]; then
			install -m644 "${PKGLUADIR}/grub.default" "$ROOT"/etc/default/grub
		fi
		if [ -f "${PKGLUADIR}/sbat.csv" ]; then
			mkdir -p "$ROOT"/usr/share/grub
			install -m644 "${PKGLUADIR}/sbat.csv" "$ROOT"/usr/share/grub/sbat.csv
		fi
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/grub-mkconfig --version || grub-mkconfig --version || true
	]])
end

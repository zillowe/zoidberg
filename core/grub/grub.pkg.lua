local version = ZOI.VERSION or "2.16"
local sha512 = "a6b3fd592cc6458bb3796fb0b197ff10fed4ed746a51f50705af5761fdde235981f871bb42b831522ec5a274aa67e9c94a98383302ebd2dcf0b195d6e3126978"
-- Release signing key (Leonardo Sandoval), GRUB release manager; listed as a
-- valid key by Arch Linux and Gentoo.
local signing_key = "DFB62CC1A987E6C76EBF8143916EC0708CDFDDFD"

metadata({
	name = "grub",
	repo = "core",
	version = version,
	revision = "6",
	-- GRUB's modules and kernel images are loaded and relocated by GRUB
	-- itself, which needs their symbols; only the host tools are stripped.
	debug = {
		sub_package = true,
		exclude = { "usr/lib/grub/**" },
	},
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
	platforms = { "linux-amd64" },
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
					"pacman:bison",
					"pacman:curl",
					"pacman:device-mapper",
					"pacman:flex",
					"pacman:freetype2",
					"pacman:fuse3",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:help2man",
					"pacman:libusb",
					"pacman:make",
					"pacman:patch",
					"pacman:python",
					"pacman:texinfo",
					"pacman:ttf-dejavu",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "grub-" .. version .. ".tar.xz"
	-- GRUB moved to freedesktop.org; releases from 2.16 on are published
	-- there as generic package assets, no longer on ftp.gnu.org.
	cmd(
		[[
		fetch() {
			for base in \
				"https://gitlab.freedesktop.org/api/v4/projects/26558/packages/generic/source-assets/grub-$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "grub-$VER.tar.xz"
		fetch "grub-$VER.tar.xz.sig"
		echo "$SHA512  grub-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "grub-$VER.tar.xz"
		cd "grub-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/0001-00_header-add-GRUB_COLOR_-variables.patch"
		patch -Np1 -i "$PKGLUADIR/patches/0002-10_linux-detect-parlex-initramfs.patch"
		patch -Np1 -i "$PKGLUADIR/patches/0003-support-dropins-for-default-configuration.patch"

		sed -i 's|GNU/Linux|Linux|' util/grub.d/10_linux.in
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "grub-$VER"

		# The patches only touch scripts; keep make from regenerating the
		# shipped build system.
		find . -type f \( -name "config.hin" -o -name "configh.in" -o -name "config.h.in" -o -name "Makefile.in" -o -name "aclocal.m4" -o -name "configure" \) -exec touch -c {} +

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
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/etc/default "$ROOT"/etc/grub.d "$ROOT"/boot/grub
		make -C "grub-$VER" DESTDIR="$ROOT" bashcompletiondir="/usr/share/bash-completion/completions" install

		install -m644 "${PKGLUADIR}/files/grub.default" "$ROOT"/etc/default/grub
		mkdir -p "$ROOT"/usr/share/grub
		install -m644 "${PKGLUADIR}/files/sbat.csv" "$ROOT"/usr/share/grub/sbat.csv
	]],
		opts
	)

	zlicense("grub-" .. version .. "/COPYING")
	-- files/grub.default and files/sbat.csv come from Arch Linux's grub
	-- package, distributed under 0BSD.
	zlicense("${pkgluadir}/files/LICENSE.0BSD", "LICENSE.0BSD")
end

function test()
	cmd([[
		/usr/bin/grub-mkconfig --version || grub-mkconfig --version || true
	]])
end

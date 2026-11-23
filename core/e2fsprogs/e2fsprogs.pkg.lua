local version = ZOI.VERSION or "1.47.4"
local sha512 =
	"c316ce38d73786fb45b3728cd31991fe81b14a1e61dae645f3471c3f35983c4394e4606b47194c3e607897b7ae5a5ef1d376adb204383afa8c4219db8617d970"
-- Release signing key (Theodore Ts'o), matches Arch's validpgpkeys.
local signing_key = "3AB057B7E78D945C8C5591FBD36F769BC11804F0"

metadata({
	name = "e2fsprogs",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Ext2/3/4 filesystem utilities",
	website = "https://e2fsprogs.sourceforge.net",
	license = "GPL-2.0-only AND LGPL-2.0-only AND MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Theodore Ts'o",
		website = "https://e2fsprogs.sourceforge.net",
	},
	bins = {
		"badblocks",
		"chattr",
		"compile_et",
		"debugfs",
		"dumpe2fs",
		"e2freefrag",
		"e2fsck",
		"e2image",
		"e2label",
		"e2mmpstatus",
		"e2scrub",
		"e2scrub_all",
		"e2undo",
		"e4crypt",
		"e4defrag",
		"filefrag",
		"fsck.ext2",
		"fsck.ext3",
		"fsck.ext4",
		"logsave",
		"lsattr",
		"mk_cmds",
		"mke2fs",
		"mkfs.ext2",
		"mkfs.ext3",
		"mkfs.ext4",
		"mklost+found",
		"resize2fs",
		"tune2fs",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/mke2fs.conf",
		"${usrroot}/etc/e2scrub.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:systemd",
					"pacman:tar",
					"pacman:util-linux",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/util-linux:libs",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "e2fsprogs-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v$VER" \
				"https://www.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v$VER" \
				"https://mirrors.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "e2fsprogs-$VER.tar.xz"
		fetch "e2fsprogs-$VER.tar.sign"
		echo "$SHA512  e2fsprogs-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	cmd([[xz -dk "e2fsprogs-$VER.tar.xz"]], opts)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "e2fsprogs-$VER.tar.xz"
		cd "e2fsprogs-$VER"
		# Remove the unnecessary init.d directory
		sed -i '/init\.d/s|^|#|' misc/Makefile.in
	]],
		opts
	)
end

function build()
	-- libuuid/libblkid come from util-linux. fuse2fs is not built: Parlex
	-- ships no fuse3 (Arch packages it separately).
	cmd(
		[[
		cd "e2fsprogs-$VER"
		./configure \
			--prefix=/usr \
			--with-root-prefix="" \
			--libdir=/usr/lib \
			--libexecdir=/usr/lib \
			--sbindir=/usr/bin \
			--enable-elf-shlibs \
			--disable-fsck \
			--disable-uuidd \
			--disable-libuuid \
			--disable-libblkid \
			--disable-fuse2fs
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "e2fsprogs-$VER"
		make -j1 DESTDIR="$ROOT" install install-libs

		sed -i -e 's/^AWK=.*/AWK=awk/' "$ROOT/usr/bin/compile_et"

		# Remove references to the build directory
		sed -i -e 's#^DIR=.*#DIR="/usr/share/ss"#' "$ROOT/usr/bin/mk_cmds"
		sed -i -e 's#^DIR=.*#DIR="/usr/share/et"#' "$ROOT/usr/bin/compile_et"

		# Remove static libraries with a shared counterpart
		rm "$ROOT"/usr/lib/lib{com_err,e2p,ext2fs,ss}.a
	]],
		opts
	)
	zlicense("e2fsprogs-" .. version .. "/NOTICE")
end

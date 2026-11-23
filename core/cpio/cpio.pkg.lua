local version = ZOI.VERSION or "2.15"
local sha512 =
	"e3c3d0344d13d540887198ee5d6209a9254ed34b87c3b3cabe6dc3ce22ef94d3f380bb60d3395eee44e4b0ec8460b957032c6251f101b4a9fbc5951a701aadff"
-- Upstream signs releases (key 325F650C4C2B6AD58807327A3602B07F55D0C732, Sergey Poznyakoff),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "cpio",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "A tool to copy files into or out of a cpio or tar archive",
	website = "https://www.gnu.org/software/cpio",
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
	bins = { "cpio" },
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
					"pacman:base-devel",
					"pacman:bzip2",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
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

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/cpio" \
				"https://mirrors.kernel.org/gnu/cpio" \
				"https://ftp.gnu.org/gnu/cpio"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "cpio-$VER.tar.bz2"
		echo "$SHA512  cpio-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	cmd(
		[[
		tar -xf "cpio-$VER.tar.bz2"
		cd "cpio-$VER"
		# C23 conformity fix from upstream commit f42137f5 (not in 2.15).
		patch -Np1 -i "$PKGLUADIR/patches/fix-c23-conformity.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "cpio-$VER"
		./configure \
			--prefix=/usr \
			--mandir=/usr/share/man \
			--with-rmt=/dev/null
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "cpio-$VER" DESTDIR="$ROOT" install
		find "$ROOT" -type d -empty -delete
	]],
		opts
	)

	zlicense("cpio-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/cpio --version || cpio --version
	]])
end

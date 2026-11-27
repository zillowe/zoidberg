local version = ZOI.VERSION or "1.22.6"
local sha512 = "50917800c9a27cc3eb131b79f3833b0090ff99fe9cf78f639d706db4bb1eb6568517c04911576a6f1f23e9b1fa5364af1bf2ca50091b7a84d15daa6f30249191"
-- Upstream signs releases with SHA-1 signatures, which Zoi's signature
-- policy (Sequoia's standard policy) rejects. The release is pinned by the
-- hash instead, which matches Arch Linux's checksum; the signature was
-- checked with GnuPG against Antonio Diaz Diaz's key
-- (1E5AEE0B18C0DEB45D64AA0325B62C9821501AA0) when the hash was pinned.

metadata({
	name = "ed",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A POSIX-compliant line-oriented text editor",
	website = "https://www.gnu.org/software/ed/ed.html",
	-- The sources say "version 2 of the License, or (at your option) any
	-- later version" (Arch lists GPL-2.0-only).
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Antonio Diaz Diaz",
		website = "https://www.gnu.org/software/ed/ed.html",
	},
	bins = { "ed", "red" },
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
					"pacman:gcc",
					"pacman:lzip",
					"pacman:make",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/ed" \
				"https://mirrors.kernel.org/gnu/ed" \
				"https://ftp.gnu.org/gnu/ed"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "ed-$VER.tar.lz"
		echo "$SHA512  ed-$VER.tar.lz" | sha512sum -c -
		tar --lzip -xf "ed-$VER.tar.lz"
	]],
		opts
	)
end

function build()
	-- Options follow Arch Linux's PKGBUILD.
	cmd(
		[[
		cd "ed-$VER"
		./configure \
			--prefix=/ \
			--bindir=/usr/bin \
			--mandir=/usr/share/man \
			--infodir=/usr/share/info \
			"CPPFLAGS=$CPPFLAGS" \
			"CFLAGS=$CFLAGS" \
			"LDFLAGS=$LDFLAGS"
		make
		make check
	]],
		opts
	)
end

function package()
	cmd([[make -C "ed-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("ed-" .. version .. "/COPYING")
end

function test()
	cmd([[printf 'a\nhello\n.\np\nq\n' | "$ROOT/usr/bin/ed" -s | grep -qx hello]], opts)
	return true
end

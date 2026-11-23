local version = ZOI.VERSION or "5.48"
local sha512 = "9672504f9473e41ed047bb019f1a003965b3f12e16b77d090e819e094805e42d66d07582402eb9df6be98932161ee6a014a549dbcca9cef10c236b0a3a71a642"
-- Upstream signs releases (key BE04995BA8F90ED0C0C176C471112AB16CB33B3A, Christos Zoulas),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "file",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
	description = "File type identification utility",
	website = "https://www.darwinsys.com/file/",
	license = "BSD-2-Clause-Darwin",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Ian Darwin and Christos Zoulas",
		website = "https://www.darwinsys.com/file/",
	},
	bins = { "file" },
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
					"pacman:bzip2",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:libseccomp",
					"pacman:make",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bzip2",
			"zoi:@core/glibc",
			"zoi:@core/libseccomp",
			"zoi:@core/xz",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
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
				"https://astron.com/pub/file" \
				"https://ftp.astron.com/pub/file"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "file-$VER.tar.gz"
		echo "$SHA512  file-$VER.tar.gz" | sha512sum -c -
		tar -xf "file-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "file-$VER"

		export CFLAGS="${CFLAGS:-} -pthread"
		./configure \
			--prefix=/usr \
			--datadir=/usr/share/file \
			--enable-fsect-man5 \
			--enable-libseccomp

		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"

		make -C "file-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("file-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/file --version || file --version
	]])
end

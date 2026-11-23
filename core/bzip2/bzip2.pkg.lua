local version = ZOI.VERSION or "1.0.8"
local sha512 =
	"083f5e675d73f3233c7930ebe20425a533feedeaaa9d8cc86831312a6581cefbe6ed0d08d2fa89be81082f2a5abdabca8b3c080bf97218a1bd59dc118a30b9f3"
-- Release signing key (Mark Wielaard; signed by subkey
-- 12768A96795990107A0D2FDFFC57E3CCACD99A78), matches Arch's validpgpkeys.
local signing_key = "EC3CFE88F6CA0788774F5C1D1AA44BE649DE760A"

metadata({
	name = "bzip2",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "A high-quality data compression program",
	website = "https://sourceware.org/bzip2/",
	license = "bzip2-1.0.6",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Julian Seward",
		website = "https://sourceware.org/bzip2/",
	},
	bins = { "bzip2", "bunzip2", "bzcat", "bzip2recover", "bzdiff", "bzgrep", "bzmore" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:sed",
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
	local tarball = "bzip2-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://mirrors.kernel.org/sourceware/bzip2" \
				"https://sourceware.org/pub/bzip2"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "bzip2-$VER.tar.gz"
		fetch "bzip2-$VER.tar.gz.sig"
		echo "$SHA512  bzip2-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "bzip2-$VER.tar.gz"
		cd "bzip2-$VER"
		cp "$PKGLUADIR/files/bzip2.pc" bzip2.pc
		sed "s|@VERSION@|$VER|" -i bzip2.pc
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "bzip2-$VER"

		make -f Makefile-libbz2_so CC="gcc $CFLAGS $CPPFLAGS $LDFLAGS"
		make bzip2 bzip2recover CC="gcc $CFLAGS $CPPFLAGS $LDFLAGS"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/lib/pkgconfig "$ROOT"/usr/include "$ROOT"/usr/share/man/man1

		cd "bzip2-$VER"

		install -m755 bzip2-shared "$ROOT"/usr/bin/bzip2
		install -m755 bzip2recover bzdiff bzgrep bzmore "$ROOT"/usr/bin/
		ln -sf bzip2 "$ROOT"/usr/bin/bunzip2
		ln -sf bzip2 "$ROOT"/usr/bin/bzcat

		cp -a libbz2.so* "$ROOT"/usr/lib/
		ln -sf "libbz2.so.$VER" "$ROOT"/usr/lib/libbz2.so
		ln -sf "libbz2.so.$VER" "$ROOT"/usr/lib/libbz2.so.1

		install -m644 bzlib.h "$ROOT"/usr/include/

		install -m644 bzip2.1 "$ROOT"/usr/share/man/man1/
		ln -sf bzip2.1 "$ROOT"/usr/share/man/man1/bunzip2.1
		ln -sf bzip2.1 "$ROOT"/usr/share/man/man1/bzcat.1
		ln -sf bzip2.1 "$ROOT"/usr/share/man/man1/bzip2recover.1

		sed "s|@VERSION@|$VER|" "$PKGLUADIR/files/bzip2.pc" > "$ROOT"/usr/lib/pkgconfig/bzip2.pc
	]],
		opts
	)

	zlicense("bzip2-" .. version .. "/LICENSE")
end

function test()
	cmd([[
		/usr/bin/bzip2 --help || bzip2 --help
	]])
end

local version = ZOI.VERSION or "1.0.8"
local tar_url = string.format("https://sourceware.org/pub/bzip2/bzip2-%s.tar.gz", version)

metadata({
	name = "bzip2",
	repo = "core",
	version = version,
	revision = "2",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "bzip2-%s" ]; then
			curl -sSL "%s" -o "bzip2-%s.tar.gz"
			tar -xf "bzip2-%s.tar.gz"
		fi

		cd "bzip2-%s"
		cp "${PKGLUADIR}/bzip2.pc" bzip2.pc
		sed "s|@VERSION@|%s|" -i bzip2.pc
	]],
		version,
		tar_url,
		version,
		version,
		version,
		version
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "bzip2-%s"

		make -f Makefile-libbz2_so CC="gcc $CFLAGS $CPPFLAGS $LDFLAGS"
		make bzip2 bzip2recover CC="gcc $CFLAGS $CPPFLAGS $LDFLAGS"
	]],
		version
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")
	local pkgdir = LOCATION.PKGLUADIR or "."

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		PKGLUADIR="%s"
		mkdir -p "$ROOT"/usr/{bin,lib,include,share/man/man1,lib/pkgconfig}

		cd "bzip2-%s"

		install -m755 bzip2-shared "$ROOT"/usr/bin/bzip2
		install -m755 bzip2recover bzdiff bzgrep bzmore "$ROOT"/usr/bin/
		ln -sf bzip2 "$ROOT"/usr/bin/bunzip2
		ln -sf bzip2 "$ROOT"/usr/bin/bzcat

		cp -a libbz2.so* "$ROOT"/usr/lib/
		ln -sf "libbz2.so.%s" "$ROOT"/usr/lib/libbz2.so
		ln -sf "libbz2.so.%s" "$ROOT"/usr/lib/libbz2.so.1

		install -m644 bzlib.h "$ROOT"/usr/include/

		install -m644 bzip2.1 "$ROOT"/usr/share/man/man1/
		ln -sf bzip2.1 "$ROOT"/usr/share/man/man1/bunzip2.1
		ln -sf bzip2.1 "$ROOT"/usr/share/man/man1/bzcat.1
		ln -sf bzip2.1 "$ROOT"/usr/share/man/man1/bzip2recover.1

		sed "s|@VERSION@|%s|" "$PKGLUADIR/bzip2.pc" > "$ROOT"/usr/lib/pkgconfig/bzip2.pc
	]],
		root,
		pkgdir,
		version,
		version,
		version,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/bzip2 --help || bzip2 --help
	]])
end

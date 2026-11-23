local version = ZOI.VERSION or "0.197"
local sha512 =
	"66287a189cf939216e87781e3376908f5ac7ae0c1ba9f20424bbcf1696257475de736b01727ca3d1eba5c57197e141c6e46633546dd3aac30b7faed9b40f0782"
-- Release signing key (Aaron Merey), matching Arch Linux's validpgpkeys.
local signing_key = "6C2B631563B8D330578D3CB474FD3FA2779E7073"

metadata({
	name = "elfutils",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Handle ELF object files and DWARF debugging information",
	website = "https://sourceware.org/elfutils/",
	license = "GPL-3.0-or-later AND (GPL-2.0-or-later OR LGPL-3.0-or-later)",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The elfutils developers",
		website = "https://sourceware.org/elfutils/",
	},
	bins = {
		"eu-addr2line",
		"eu-ar",
		"eu-elfclassify",
		"eu-elfcmp",
		"eu-elfcompress",
		"eu-elflint",
		"eu-findtextrel",
		"eu-make-debug-archive",
		"eu-nm",
		"eu-objdump",
		"eu-ranlib",
		"eu-readelf",
		"eu-size",
		"eu-srcfiles",
		"eu-stack",
		"eu-stackprof",
		"eu-strings",
		"eu-strip",
		"eu-unstrip",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "libelf", "debuginfod" },
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:bison",
					"pacman:bzip2",
					"pacman:curl",
					"pacman:flex",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:json-c",
					"pacman:libarchive",
					"pacman:libmicrohttpd",
					"pacman:m4",
					"pacman:make",
					"pacman:sqlite",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/bash",
					"zoi:@core/elfutils:libelf",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
					"zoi:@core/glibc",
					"zoi:@core/json-c",
					"zoi:@core/libarchive",
				},
			},
			libelf = {
				required = {
					"zoi:@core/bzip2",
					"zoi:@core/curl",
					"zoi:@core/glibc",
					"zoi:@core/json-c",
					"zoi:@core/xz",
					"zoi:@core/zlib",
					"zoi:@core/zstd",
				},
			},
			debuginfod = {
				required = {
					"zoi:@core/elfutils:libelf",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
					"zoi:@core/glibc",
					"zoi:@core/json-c",
					"zoi:@core/libarchive",
					"zoi:@core/libmicrohttpd",
					"zoi:@core/sqlite",
					"zoi:@core/xz",
				},
			},
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "elfutils-" .. version .. ".tar.bz2"
	cmd(
		[[
		fetch() {
			for base in \
				"https://mirrors.kernel.org/sourceware/elfutils/$VER" \
				"https://sourceware.org/pub/elfutils/$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "elfutils-$VER.tar.bz2"
		fetch "elfutils-$VER.tar.bz2.sig"
		echo "$SHA512  elfutils-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "elfutils-$VER.tar.bz2"]], opts)
end

function build()
	-- debuginfod as Arch: the client library (libdebuginfod, curl + json-c)
	-- goes to libelf, the server and debuginfod-find to the debuginfod
	-- sub-package (libmicrohttpd, sqlite, libarchive). eu-stackprof
	-- (json-c) and eu-srcfiles (libarchive) are in main.
	-- IMA signature verification is off (it needs librpm); the cache
	-- variables stop configure from linking libcrypto/librpm (only used for
	-- it) or an optional host libpfm into the binaries.
	-- fat-lto-objects is required for non-mangled .a files in libelf.
	cmd(
		[[
		cd "elfutils-$VER"
		CFLAGS="${CFLAGS:-} -ffat-lto-objects -g" \
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--program-prefix="eu-" \
			--enable-deterministic-archives \
			--enable-maintainer-mode \
			--enable-libdebuginfod \
			--enable-debuginfod \
			--disable-debuginfod-ima-verification \
			--enable-stackprof \
			--with-libarchive \
			ac_cv_lib_rpm_headerGet=no \
			ac_cv_lib_crypto_EVP_MD_CTX_new=no \
			ac_cv_lib_pfm_pfm_get_os_event_encoding=no \
			ac_cv_header_perfmon_pfmlib_perf_event_h=no
		make -j"$(nproc)"
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	-- Install once into a scratch tree, then split it between sub-packages.
	cmd(
		[[
		DEST="$(pwd)/elfutils-dest"
		if [ ! -d "$DEST" ]; then
			make -C "elfutils-$VER" DESTDIR="$DEST" install
		fi
	]],
		opts
	)

	-- Split as Arch: libelf gets the libraries (including libdebuginfod),
	-- headers, /etc/debuginfod and the profile.d snippets; debuginfod gets
	-- the server, debuginfod-find and their man pages and fish snippet;
	-- main gets the rest.
	if sub == "libelf" then
		cmd(
			[[
			DEST="$(pwd)/elfutils-dest"
			SRC="elfutils-$VER"
			mkdir -p "$ROOT/usr"
			cp -a "$DEST/etc" "$ROOT/"
			cp -a "$DEST/usr/include" "$DEST/usr/lib" "$ROOT/usr/"
			for dir in "$DEST"/usr/share/man/man*; do
				for page in "$dir"/*; do
					case "$(basename "$page")" in
						elf*|gelf*|libelf*)
							mkdir -p "$ROOT/usr/share/man/$(basename "$dir")"
							cp -a "$page" "$ROOT/usr/share/man/$(basename "$dir")/"
							;;
					esac
				done
			done
			install -Dm644 -t "$ROOT/usr/share/doc/libelf/" \
				"$SRC/AUTHORS" "$SRC/ChangeLog" "$SRC/NEWS" "$SRC/NOTES" "$SRC/README"
		]],
			opts
		)
		zlicense("elfutils-" .. version .. "/COPYING-GPLV2")
		zlicense("elfutils-" .. version .. "/COPYING-LGPLV3")
	elseif sub == "debuginfod" then
		cmd(
			[[
			DEST="$(pwd)/elfutils-dest"
			SRC="elfutils-$VER"
			mkdir -p "$ROOT/usr/bin" "$ROOT/usr/share/fish/vendor_conf.d"
			cp -a "$DEST"/usr/bin/debuginfod* "$ROOT/usr/bin/"
			cp -a "$DEST/usr/share/fish/vendor_conf.d/debuginfod.fish" "$ROOT/usr/share/fish/vendor_conf.d/"
			for dir in "$DEST"/usr/share/man/man*; do
				for page in "$dir"/debuginfod*; do
					[ -e "$page" ] || continue
					mkdir -p "$ROOT/usr/share/man/$(basename "$dir")"
					cp -a "$page" "$ROOT/usr/share/man/$(basename "$dir")/"
				done
			done
			install -Dm644 -t "$ROOT/usr/share/doc/debuginfod/" \
				"$SRC/AUTHORS" "$SRC/ChangeLog" "$SRC/NEWS" "$SRC/NOTES" "$SRC/README"
		]],
			opts
		)
		zlicense("elfutils-" .. version .. "/COPYING")
	else
		cmd(
			[[
			DEST="$(pwd)/elfutils-dest"
			SRC="elfutils-$VER"
			mkdir -p "$ROOT/usr"
			cp -a "$DEST/usr/bin" "$DEST/usr/share" "$ROOT/usr/"
			rm -f "$ROOT"/usr/bin/debuginfod*
			rm -f "$ROOT"/usr/share/fish/vendor_conf.d/debuginfod.fish
			rm -f "$ROOT"/usr/share/man/man*/elf* "$ROOT"/usr/share/man/man*/gelf* \
				"$ROOT"/usr/share/man/man*/libelf* "$ROOT"/usr/share/man/man*/debuginfod*
			find "$ROOT" -type d -empty -delete
			install -Dm644 -t "$ROOT/usr/share/doc/elfutils/" \
				"$SRC/AUTHORS" "$SRC/ChangeLog" "$SRC/NEWS" "$SRC/NOTES" "$SRC/README"
		]],
			opts
		)
		zlicense("elfutils-" .. version .. "/COPYING")
	end
end

function test()
	cmd([[
		/usr/bin/eu-readelf --version || eu-readelf --version
	]])
end

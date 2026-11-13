local version = ZOI.VERSION or "0.197"
local git_url = "https://forge.sourceware.org/elfutils/elfutils-mirror.git"

metadata({
	name = "elfutils",
	repo = "core",
	version = version,
	revision = "2",
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
		"eu-strings",
		"eu-strip",
		"eu-unstrip",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "libelf" },
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:autoconf",
					"pacman:automake",
					"pacman:bison",
					"pacman:bzip2",
					"pacman:flex",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:m4",
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
				},
			},
			libelf = {
				required = {
					"zoi:@core/bzip2",
					"zoi:@core/glibc",
					"zoi:@core/xz",
					"zoi:@core/zlib",
					"zoi:@core/zstd",
				},
			},
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "GIT_URL='" .. git_url .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d elfutils ]; then
			git clone --depth 1 --branch "elfutils-$VER" "$GIT_URL" elfutils
			cd elfutils

			# Skip tests failing due to missing PT_GNU_SFRAME support; see
			# https://sourceware.org/bugzilla/show_bug.cgi?id=34459
			sed \
				-e 's/run-strip-strmerge.sh//g' \
				-e 's/run-elflint-self.sh//g' \
				-e 's/run-reverse-sections-self.sh//g' \
				-i tests/Makefile.am

			autoreconf -fiv
		fi
	]])
end

function build()
	-- debuginfod (server and client library) is disabled: it would pull in
	-- curl, json-c, libarchive, libmicrohttpd and sqlite at runtime.
	-- fat-lto-objects is required for non-mangled .a files in libelf.
	sh([[
		cd elfutils
		CFLAGS="${CFLAGS:-} -ffat-lto-objects -g" \
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--program-prefix="eu-" \
			--enable-deterministic-archives \
			--enable-maintainer-mode \
			--disable-debuginfod \
			--disable-libdebuginfod
		make -j"$(nproc)"
	]])
end

function package(args)
	local sub = (args and args.sub) or "main"

	-- Install once into a scratch tree, then split it between sub-packages.
	sh([[
		DEST="$(pwd)/elfutils-dest"
		if [ ! -d "$DEST" ]; then
			make -C elfutils DESTDIR="$DEST" install
		fi
	]])

	if sub == "libelf" then
		sh([[
			DEST="$(pwd)/elfutils-dest"
			mkdir -p "$ROOT/usr/share/man/man3"
			cp -a "$DEST/usr/include" "$DEST/usr/lib" "$ROOT/usr/"
			for page in "$DEST"/usr/share/man/man3/*; do
				case "$(basename "$page")" in
					elf*|gelf*|libelf*) cp -a "$page" "$ROOT/usr/share/man/man3/" ;;
				esac
			done
			install -Dm644 -t "$ROOT/usr/share/doc/libelf/" \
				elfutils/AUTHORS elfutils/ChangeLog elfutils/NEWS elfutils/NOTES elfutils/README
		]])
	else
		sh([[
			DEST="$(pwd)/elfutils-dest"
			mkdir -p "$ROOT/usr"
			cp -a "$DEST/usr/bin" "$DEST/usr/share" "$ROOT/usr/"
			rm -f "$ROOT"/usr/share/man/man3/elf* "$ROOT"/usr/share/man/man3/gelf* "$ROOT"/usr/share/man/man3/libelf*
			find "$ROOT" -type d -empty -delete
			install -Dm644 -t "$ROOT/usr/share/doc/elfutils/" \
				elfutils/AUTHORS elfutils/ChangeLog elfutils/NEWS elfutils/NOTES elfutils/README
		]])
	end
end

function test()
	cmd([[
		/usr/bin/eu-readelf --version || eu-readelf --version
	]])
end

-- Toolchain build order: linux-api-headers -> glibc -> binutils -> gcc -> glibc -> binutils -> gcc
local version = ZOI.VERSION or "2.47"
local commit = "6ce87bbc521cf46eaee9a1f7ef61cee2cdfb3e32"
local git_url = "https://forge.sourceware.org/binutils-gdb/binutils-gdb-mirror"

metadata({
	name = "binutils",
	repo = "core",
	version = version,
	revision = "1",
	description = "A set of programs to assemble and manipulate binary and object files",
	website = "https://www.gnu.org/software/binutils/",
	license = "GPL-2.0-or-later AND GPL-3.0-or-later AND LGPL-2.0-or-later AND LGPL-3.0-or-later AND GFDL-1.3-only AND FSFAP",
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
		"addr2line",
		"ar",
		"as",
		"c++filt",
		"elfedit",
		"gp-archive",
		"gp-collect-app",
		"gp-display-html",
		"gp-display-src",
		"gp-display-text",
		"gprof",
		"gprofng",
		"ld",
		"ld.bfd",
		"ld.gold",
		"nm",
		"objcopy",
		"objdump",
		"ranlib",
		"readelf",
		"size",
		"strings",
		"strip",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	ci = {
		tags = {
			["linux-amd64"] = "saas-linux-xlarge-amd64",
			linux = "saas-linux-xlarge-amd64",
		},
	},
	types = { "source" },
	quiet = { "build" },
	zoios = true,
	backup = {
		"${usrroot}/etc/gprofng.rc",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:bison",
					"pacman:flex",
					"pacman:gcc",
					"pacman:git",
					"pacman:make",
					"pacman:patch",
					"pacman:texinfo",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "COMMIT='" .. commit .. "'\n"
		.. "GIT_URL='" .. git_url .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d binutils-gdb ]; then
			mkdir binutils-gdb
			cd binutils-gdb
			git init -q
			git remote add origin "$GIT_URL"
			# Fetch only the pinned commit; the full history is several GB
			if ! git fetch --depth 1 origin "$COMMIT"; then
				git fetch origin
			fi
			git checkout -q "$COMMIT"

			# Turn off development mode (-Werror, gas run-time checks, date in sonames)
			sed -i '/^development=/s/true/false/' bfd/development.sh

			# Only warn about unsupported gold targets, so BPF support can be enabled
			patch -Np1 < "$PKGLUADIR/gold-warn-unsupported.patch"
			cd ..
		fi
		mkdir -p binutils-build
	]])
end

function build()
	-- Parlex ships no jansson or debuginfod, so both are disabled explicitly
	-- instead of auto-detecting the build host's copies.
	sh([[
		cd binutils-build

		../binutils-gdb/configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-lib-path=/usr/lib:/usr/local/lib \
			--with-bugurl=https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/issues \
			--enable-cet \
			--enable-colored-disassembly \
			--enable-default-execstack=no \
			--enable-deterministic-archives \
			--enable-gold \
			--enable-install-libiberty \
			--disable-jansson \
			--enable-ld=default \
			--enable-new-dtags \
			--enable-pgo-build=lto \
			--enable-plugins \
			--enable-relro \
			--enable-shared \
			--enable-targets=x86_64-pep,bpf-unknown-none \
			--enable-threads \
			--disable-gdb \
			--disable-gdbserver \
			--disable-libdecnumber \
			--disable-readline \
			--disable-sim \
			--disable-werror \
			--without-debuginfod \
			--with-pic \
			--with-system-zlib

		make -O -j"$(nproc)" tooldir=/usr

		# Extract the FSF All Permissive License used for some linker scripts
		tail -n 5 ../binutils-gdb/ld/scripttempl/README > FSFAP
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd binutils-build
		make DESTDIR="$ROOT" tooldir=/usr install

		# Install the PIC version of libiberty
		install -m644 libiberty/pic/libiberty.a "$ROOT/usr/lib"

		# Remove unwanted files
		rm -f "$ROOT"/usr/share/man/man1/dlltool* "$ROOT"/usr/share/man/man1/windres* "$ROOT"/usr/share/man/man1/windmc*

		# No shared linking to these files outside binutils
		rm -f "$ROOT/usr/lib/libbfd.so" "$ROOT/usr/lib/libopcodes.so"
		cat > "$ROOT/usr/lib/libbfd.so" <<'EOS'
/* GNU ld script */

INPUT( /usr/lib/libbfd.a -lsframe -liberty -lz -lzstd -ldl )
EOS
		cat > "$ROOT/usr/lib/libopcodes.so" <<'EOS'
/* GNU ld script */

INPUT( /usr/lib/libopcodes.a -lbfd )
EOS

		install -Dm644 -t "$ROOT/usr/share/licenses/binutils/" FSFAP
	]])
end

function test()
	cmd([[
		/usr/bin/ld --version || ld --version
	]])
end

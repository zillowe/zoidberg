-- Toolchain build order: linux-api-headers -> glibc -> binutils -> gcc -> glibc -> binutils -> gcc
local version = ZOI.VERSION or "2.47"
local sha512 =
	"3126a1064374d8da40d4d70630c204ed1e75d542c447d53fca9778c7ceff095c28e9b445e15a313fef9729082d7966471ee6b5b715d479aa6d568528743e1d98"
-- Upstream signs releases (key 3A24BC1E8FB409FA9F14371813FCEF89DD9E3C4F, Nick
-- Clifton, listed in the GNU keyring and Arch Linux's validpgpkeys), but the
-- key is only bound with SHA-1 self-signatures, which Zoi's verifier rejects.
-- The pinned hash matches Gentoo's Manifest for this file (Gentoo verifies the
-- signature); the pinned hash is the trust anchor.

metadata({
	name = "binutils",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
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
	zsa = false,
	backup = {
		"${usrroot}/etc/gprofng.rc",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:bison",
					"pacman:curl",
					"pacman:flex",
					"pacman:gcc",
					"pacman:jansson",
					"pacman:make",
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
			"zoi:@core/jansson",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/binutils" \
				"https://mirrors.kernel.org/gnu/binutils" \
				"https://ftp.gnu.org/gnu/binutils"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "binutils-$VER.tar.xz"
		echo "$SHA512  binutils-$VER.tar.xz" | sha512sum -c -
		tar -xf "binutils-$VER.tar.xz"
		mkdir -p binutils-build
	]],
		opts
	)
end

function build()
	-- jansson (JSON support in ld, e.g. --package-metadata) is enabled as on
	-- Arch. Arch also builds the debuginfod client (libdebuginfod from
	-- elfutils); it stays disabled explicitly here instead of auto-detecting
	-- the build host's copy.
	cmd(
		[[
		cd binutils-build

		../binutils-$VER/configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-lib-path=/usr/lib:/usr/local/lib \
			--with-bugurl=https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/issues \
			--enable-cet \
			--enable-colored-disassembly \
			--enable-default-execstack=no \
			--enable-deterministic-archives \
			--enable-install-libiberty \
			--enable-jansson \
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
		tail -n 5 "../binutils-$VER/ld/scripttempl/README" > FSFAP
	]],
		opts
	)
end

function package()
	cmd(
		[[
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
	]],
		opts
	)
	local src = "binutils-" .. version
	zlicense(src .. "/COPYING")
	zlicense(src .. "/COPYING.LIB")
	zlicense(src .. "/COPYING3")
	zlicense(src .. "/COPYING3.LIB")
	zlicense("binutils-build/FSFAP")
end

function test()
	cmd([[
		/usr/bin/ld --version || ld --version
	]])
end

local version = ZOI.VERSION or "16.2.1+r23+gd564253eb6c8"
local commit = "d564253eb6c859e266d3cae18e82fb4db9a88316"
local git_url = "https://forge.sourceware.org/gcc/gcc"

metadata({
	name = "gcc",
	repo = "core",
	version = version,
	revision = "2",
	description = "The GNU Compiler Collection - C and C++ frontends and runtimes",
	website = "https://gcc.gnu.org",
	license = "GPL-3.0-or-later WITH GCC-exception-3.1 AND GFDL-1.3-or-later",
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
		"c++",
		"c89",
		"c99",
		"cc",
		"g++",
		"gcc",
		"gcc-ar",
		"gcc-nm",
		"gcc-ranlib",
		"gcov",
		"gcov-dump",
		"gcov-tool",
		"lto-dump",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	zsa = false,
	sub_packages = {
		"main",
		"gcc-libs",
		"libgcc",
		"libstdc++",
		"libatomic",
		"libgomp",
		"libquadmath",
		"libitm",
		"libasan",
		"libubsan",
		"libtsan",
		"liblsan",
		"libhwasan",
		"lib32-gcc-libs",
		"gcc-fortran",
		"libgfortran",
		"gcc-go",
		"libgo",
		"gcc-ada",
		"gcc-d",
		"libgphobos",
		"gcc-objc",
		"libobjc",
		"gcc-rust",
		"gcc-m2",
		"libgm2",
		"gcc-gcobol",
		"libgcobol",
		"libgccjit",
		"lto-dump",
	},
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:binutils",
					"pacman:diffutils",
					"pacman:doxygen",
					"pacman:gawk",
					"pacman:gcc-ada",
					"pacman:gcc-d",
					"pacman:git",
					"pacman:gmp",
					"pacman:lib32-gcc-libs",
					"pacman:lib32-glibc",
					"pacman:libisl",
					"pacman:libmpc",
					"pacman:make",
					"pacman:mpfr",
					"pacman:patch",
					"pacman:python",
					"pacman:rust",
					"pacman:sed",
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
					"zoi:@core/binutils",
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
					"zoi:@core/gcc:libatomic",
					"zoi:@core/gcc:libgomp",
					"zoi:@core/gcc:libasan",
					"zoi:@core/gcc:libubsan",
					"zoi:@core/gcc:libtsan",
					"zoi:@core/gcc:liblsan",
					"zoi:@core/gcc:libhwasan",
				},
			},
			libgcc = {
				required = {
					"zoi:@core/glibc",
				},
			},
			["libstdc++"] = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
				},
			},
			["gcc-libs"] = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
					"zoi:@core/gcc:libatomic",
					"zoi:@core/gcc:libgomp",
					"zoi:@core/gcc:libquadmath",
					"zoi:@core/gcc:libitm",
					"zoi:@core/gcc:libasan",
					"zoi:@core/gcc:libubsan",
					"zoi:@core/gcc:libtsan",
					"zoi:@core/gcc:liblsan",
					"zoi:@core/gcc:libhwasan",
				},
			},
			["lib32-gcc-libs"] = {
				required = {
					"zoi:@core/glibc:lib32",
				},
			},
			libatomic = {
				required = {
					"zoi:@core/glibc",
				},
			},
			libgomp = {
				required = {
					"zoi:@core/glibc",
				},
			},
			libquadmath = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
				},
			},
			libitm = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
				},
			},
			libasan = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
				},
			},
			libubsan = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
				},
			},
			libtsan = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
				},
			},
			liblsan = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
				},
			},
			libhwasan = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
				},
			},
			["gcc-fortran"] = {
				required = {
					"zoi:@core/gcc:main",
					"zoi:@core/gcc:libgfortran",
				},
			},
			libgfortran = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
				},
			},
			["gcc-go"] = {
				required = {
					"zoi:@core/gcc:main",
					"zoi:@core/gcc:libgo",
				},
			},
			libgo = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
				},
			},
			["gcc-ada"] = {
				required = {
					"zoi:@core/gcc:main",
				},
			},
			["gcc-d"] = {
				required = {
					"zoi:@core/gcc:main",
					"zoi:@core/gcc:libgphobos",
				},
			},
			libgphobos = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
				},
			},
			["gcc-objc"] = {
				required = {
					"zoi:@core/gcc:main",
					"zoi:@core/gcc:libobjc",
				},
			},
			libobjc = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
				},
			},
			["gcc-rust"] = {
				required = {
					"zoi:@core/gcc:main",
				},
			},
			["gcc-m2"] = {
				required = {
					"zoi:@core/gcc:main",
					"zoi:@core/gcc:libgm2",
				},
			},
			libgm2 = {
				required = {
					"zoi:@core/glibc",
				},
			},
			["gcc-gcobol"] = {
				required = {
					"zoi:@core/gcc:main",
					"zoi:@core/gcc:libgcobol",
				},
			},
			libgcobol = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
				},
			},
			libgccjit = {
				required = {
					"zoi:@core/gcc:main",
				},
			},
			["lto-dump"] = {
				required = {
					"zoi:@core/gcc:main",
				},
			},
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d gcc ]; then
			git clone %s gcc
			cd gcc
			git checkout %s
			cd ..
		fi

		cd gcc
		# Arch Linux installs x86_64 libraries into /usr/lib rather than /usr/lib64
		sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64

		# Reproducible gcc-ada
		patch -Np0 < "${PKGLUADIR}/gcc-ada-repro.patch"

		# Tune branch prediction cost
		patch -Np1 < "${PKGLUADIR}/tune_branch_prediction_cost.patch"
		cd ..

		mkdir -p gcc-build libgccjit-build split
	]],
		git_url,
		commit
	))
end

function build()
	cmd([[
		set -e

		CHOST="${CHOST:-x86_64-pc-linux-gnu}"
		CARCH="${CARCH:-x86_64}"
		_pkgver="16.2.1"
		_libdir="usr/lib/gcc/$CHOST/${_pkgver%%.*}"

		_confflags=(
			--prefix=/usr
			--libdir=/usr/lib
			--libexecdir=/usr/lib
			--mandir=/usr/share/man
			--infodir=/usr/share/info
			--with-bugurl=https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/issues
			--with-build-config=bootstrap-lto
			--with-gcc-major-version-only
			--with-linker-hash-style=gnu
			--with-system-zlib
			--enable-cet=auto
			--enable-checking=release
			--enable-clocale=gnu
			--enable-default-pie
			--enable-default-ssp
			--enable-gnu-indirect-function
			--enable-gnu-unique-object
			--enable-libstdcxx-backtrace
			--enable-link-serialization=1
			--enable-linker-build-id
			--enable-lto
			--enable-multilib
			--enable-plugin
			--enable-shared
			--enable-threads=posix
			--disable-fixincludes
			--disable-libssp
			--disable-libstdcxx-pch
			--disable-werror
		)

		if [ ! -f gcc-build/gcc/xgcc ]; then
			cd gcc-build
			CFLAGS=${CFLAGS/-Werror=format-security/}
			CXXFLAGS=${CXXFLAGS/-Werror=format-security/}

			../gcc/configure \
				--enable-languages=ada,c,c++,d,fortran,go,lto,m2,objc,obj-c++,rust,cobol \
				--enable-bootstrap \
				"${_confflags[@]}"

			make -O -j"$(nproc)" STAGE1_CFLAGS="-O2" \
				BOOT_CFLAGS="$CFLAGS" \
				BOOT_LDFLAGS="$LDFLAGS" \
				LDFLAGS_FOR_TARGET="$LDFLAGS" \
				bootstrap

			# Documentation
			make -O -C "$CHOST/libstdc++-v3/doc" doc-man-doxygen || true
			cd ..
		fi

		# Build libgccjit separately
		if [ ! -f libgccjit-build/gcc/libgccjit.so ]; then
			cd libgccjit-build
			../gcc/configure \
				--enable-languages=jit \
				--disable-bootstrap \
				--enable-host-shared \
				"${_confflags[@]}"

			make -O -j"$(nproc)" all-gcc
			cp -a gcc/libgccjit.so* ../gcc-build/gcc/
			cd ..
		fi

		# Perform complete staging and splitting
		SPLIT_ROOT="$(pwd)/split_root"
		rm -rf "$SPLIT_ROOT" split
		mkdir -p "$SPLIT_ROOT" split

		make -C gcc-build DESTDIR="$SPLIT_ROOT" install
		make -C gcc-build/gcc DESTDIR="$SPLIT_ROOT" jit.install-common jit.install-info

		_pick() {
			local p="$1"; shift
			for f in "$@"; do
				[ -e "$f" ] || [ -L "$f" ] || continue
				local rel="${f#$SPLIT_ROOT/}"
				local d="$(pwd)/split/$p/$rel"
				mkdir -p "$(dirname "$d")"
				mv "$f" "$d"
				rmdir -p --ignore-fail-on-non-empty "$(dirname "$f")" 2>/dev/null || true
			done
		}

		(
			cd "$SPLIT_ROOT"

			# Internal *.so symlinks to ensure shared linking
			for _so in libatomic.so libstdc++.so libgdruntime.so libgphobos.so; do
				mkdir -p "$_libdir" "$_libdir/32"
				[ -f "usr/lib/$_so" ] && ln -sf "../../$_so" "$_libdir/$_so"
				[ -f "usr/lib32/$_so" ] && ln -sf "../../../lib32/$_so" "$_libdir/32/$_so"
			done

			# Sub-package splitting
			_pick gcc-ada usr/bin/gnat*
			_pick gcc-ada $_libdir/ada_target_properties $_libdir/32/ada_target_properties
			_pick gcc-ada $_libdir/adainclude $_libdir/adalib $_libdir/32/adainclude $_libdir/32/adalib
			_pick gcc-ada $_libdir/gnat1
			_pick gcc-ada usr/share/info/gnat*

			_pick gcc-d usr/bin/gdc usr/bin/*-gdc
			_pick gcc-d $_libdir/d21 $_libdir/include/d
			_pick gcc-d $_libdir/libgdruntime.so $_libdir/libgphobos.so $_libdir/32/libgdruntime.so $_libdir/32/libgphobos.so
			_pick gcc-d usr/lib/libgdruntime.a usr/lib/libgphobos.a usr/lib32/libgdruntime.a usr/lib32/libgphobos.a
			_pick gcc-d usr/lib/libgphobos.spec usr/lib32/libgphobos.spec
			_pick gcc-d usr/share/info/gdc.info usr/share/man/man1/gdc.1

			_pick gcc-fortran usr/bin/gfortran usr/bin/*-gfortran
			_pick gcc-fortran $_libdir/finclude $_libdir/32/finclude
			_pick gcc-fortran $_libdir/libcaf_shmem.a $_libdir/libcaf_single.a $_libdir/32/libcaf_shmem.a $_libdir/32/libcaf_single.a
			_pick gcc-fortran $_libdir/f951 $_libdir/include/ISO_Fortran_binding.h
			_pick gcc-fortran usr/lib/libgfortran.spec usr/lib32/libgfortran.spec
			_pick gcc-fortran usr/share/info/gfortran.info usr/share/man/man1/gfortran.1

			_pick gcc-gcobol usr/bin/gcobc usr/bin/gcobol usr/bin/*-gcobc usr/bin/*-gcobol
			_pick gcc-gcobol $_libdir/cobol $_libdir/cobol1
			_pick gcc-gcobol usr/lib/libgcobol.spec
			_pick gcc-gcobol usr/share/man/man1/gcobol.1 usr/share/man/man3/gcobol-io.3

			_pick gcc-go usr/bin/gccgo usr/bin/go usr/bin/gofmt usr/bin/*-gccgo
			_pick gcc-go $_libdir/buildid $_libdir/cgo $_libdir/go1 $_libdir/test2json $_libdir/vet
			_pick gcc-go usr/lib/go usr/lib32/go usr/lib/libgo*.a usr/lib32/libgo*.a
			_pick gcc-go usr/share/info/gccgo.info usr/share/man/man1/gccgo.1 usr/share/man/man1/go.1 usr/share/man/man1/gofmt.1

			_pick gcc-m2 usr/bin/gm2 usr/bin/*-gm2 $_libdir/cc1gm2 usr/share/info/m2.info usr/share/man/man1/gm2.1

			_pick gcc-objc $_libdir/include/objc $_libdir/cc1obj*

			_pick gcc-rust usr/bin/gccrs usr/bin/*-gccrs $_libdir/crab1

			_pick lib32-gcc-libs usr/lib32/libasan.* usr/lib32/libatomic.* $_libdir/32/libatomic.so
			_pick lib32-gcc-libs usr/lib32/libgcc_s.so* usr/lib32/libgdruntime.* usr/lib32/libgfortran.*
			_pick lib32-gcc-libs usr/lib32/libgo.* usr/lib32/libgomp.* usr/lib32/libgphobos.*
			_pick lib32-gcc-libs usr/lib32/libitm.* usr/lib32/libobjc.* usr/lib32/libquadmath.*
			_pick lib32-gcc-libs usr/lib32/libstdc++.* usr/lib32/libubsan.*

			_pick libasan usr/lib/libasan.*
			_pick libatomic usr/lib/libatomic.* $_libdir/libatomic.so
			_pick libgcc usr/lib/libgcc_s.so.*
			_pick libgccjit usr/include/libgccjit* usr/lib/libgccjit.* usr/share/info/libgccjit.info
			_pick libgcobol usr/lib/libgcobol.*
			_pick libgfortran usr/lib/libgfortran.*
			_pick libgm2 $_libdir/m2 $_libdir/32/m2 usr/lib/libm2* usr/lib32/libm2*
			_pick libgo usr/lib/libgo.*
			_pick libgomp usr/lib/libgomp.* usr/share/info/libgomp.info
			_pick libgphobos usr/lib/libgdruntime.* usr/lib/libgphobos.*
			_pick libhwasan usr/lib/libhwasan.*
			_pick libitm usr/lib/libitm.* usr/share/info/libitm.info
			_pick liblsan usr/lib/liblsan.*
			_pick libobjc usr/lib/libobjc.*
			_pick libquadmath usr/lib/libquadmath.* usr/share/info/libquadmath.info
			_pick libstdc++ usr/lib/libstdc++.* usr/share/locale/*/LC_MESSAGES/libstdc++.mo
			_pick libtsan usr/lib/libtsan.*
			_pick libubsan usr/lib/libubsan.*
			_pick lto-dump usr/bin/lto-dump usr/share/man/man1/lto-dump.1

			# Internal library files moved into _libdir
			mv usr/lib/libgcc_s*.so "$_libdir/" 2>/dev/null || true
			mv usr/lib32/libgcc_s*.so "$_libdir/32/" 2>/dev/null || true
			mv usr/lib/libatomic*.a usr/lib/libatomic_asneeded.so "$_libdir/" 2>/dev/null || true
			mv usr/lib32/libatomic*.a usr/lib32/libatomic_asneeded.so "$_libdir/32/" 2>/dev/null || true
			mv usr/lib/*_preinit.o "$_libdir/" 2>/dev/null || true
			mv usr/lib32/*_preinit.o "$_libdir/32/" 2>/dev/null || true
			mv usr/lib/*.spec "$_libdir/" 2>/dev/null || true
			mv usr/lib32/*.spec "$_libdir/32/" 2>/dev/null || true
			mv usr/lib/libstdc++*.a "$_libdir/" 2>/dev/null || true
			mv usr/lib32/libstdc++*.a "$_libdir/32/" 2>/dev/null || true
			mv usr/lib/libsupc++.a "$_libdir/" 2>/dev/null || true
			mv usr/lib32/libsupc++.a "$_libdir/32/" 2>/dev/null || true
		)

		# Sub-package post-processing
		# 1. gcc-ada
		if [ -d split/gcc-ada ]; then
			ln -sf gcc split/gcc-ada/usr/bin/gnatgcc
			mkdir -p split/gcc-ada/usr/lib split/gcc-ada/usr/lib32
			mv split/gcc-ada/$_libdir/adalib/libgna*-[0-9]*.so split/gcc-ada/usr/lib/ 2>/dev/null || true
			mv split/gcc-ada/$_libdir/32/adalib/libgna*-[0-9]*.so split/gcc-ada/usr/lib32/ 2>/dev/null || true
		fi

		# 2. gcc-d
		if [ -d split/gcc-d ]; then
			mkdir -p "split/gcc-d/$_libdir/32"
			mv split/gcc-d/usr/lib/libg*.a "split/gcc-d/$_libdir/" 2>/dev/null || true
			mv split/gcc-d/usr/lib32/libg*.a "split/gcc-d/$_libdir/32/" 2>/dev/null || true
			mv split/gcc-d/usr/lib/libgphobos.spec "split/gcc-d/$_libdir/" 2>/dev/null || true
			mv split/gcc-d/usr/lib32/libgphobos.spec "split/gcc-d/$_libdir/32/" 2>/dev/null || true
		fi

		# 3. gcc-fortran
		if [ -d split/gcc-fortran ]; then
			ln -sf gfortran split/gcc-fortran/usr/bin/f95
			mv split/gcc-fortran/usr/lib/libgfortran.spec "split/gcc-fortran/$_libdir/" 2>/dev/null || true
			mv split/gcc-fortran/usr/lib32/libgfortran.spec "split/gcc-fortran/$_libdir/32/" 2>/dev/null || true
		fi

		# 4. gcc-gcobol
		if [ -d split/gcc-gcobol ]; then
			mv split/gcc-gcobol/usr/lib/libgcobol.spec "split/gcc-gcobol/$_libdir/" 2>/dev/null || true
		fi

		# 5. lib32-gcc-libs
		if [ -d split/lib32-gcc-libs ]; then
			rm -f split/lib32-gcc-libs/usr/lib32/libstdc++.so.*-gdb.py
		fi

		# Remainder in SPLIT_ROOT is the main "gcc" compiler package
		mkdir -p split/main
		cp -a "$SPLIT_ROOT"/* split/main/

		# Main GCC compiler adjustments
		mkdir -p split/main/usr/share/gdb/auto-load/usr/lib split/main/usr/lib/bfd-plugins
		if [ -d split/libstdc++ ]; then
			mv split/libstdc++/usr/lib/libstdc++.so.*-gdb.py split/main/usr/share/gdb/auto-load/usr/lib/ 2>/dev/null || true
		fi
		ln -sf "/$_libdir/liblto_plugin.so" split/main/usr/lib/bfd-plugins/liblto_plugin.so
		ln -sf gcc split/main/usr/bin/cc

		for binary in c++ g++ gcc gcc-ar gcc-nm gcc-ranlib; do
			ln -sf "/usr/bin/$binary" "split/main/usr/bin/$CARCH-linux-gnu-$binary"
		done

		install -Dm755 "${PKGLUADIR}/c89" split/main/usr/bin/c89
		install -Dm755 "${PKGLUADIR}/c99" split/main/usr/bin/c99

		make -C "gcc-build/$CHOST/libstdc++-v3/doc" DESTDIR="$(pwd)/split/main" doc-install-man || true

		python3 -m compileall "split/main/usr/share/gcc-${_pkgver%%.*}/" 2>/dev/null || true
		python3 -O -m compileall "split/main/usr/share/gcc-${_pkgver%%.*}/" 2>/dev/null || true
	]])
end

function package(args)
	local sub = (args and args.sub) or "main"
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	if sub == "main" or sub == "" then
		cmd(string.format(
			[[
			ROOT="%s"
			mkdir -p "$ROOT"
			if [ -d split/main ]; then
				cp -a split/main/* "$ROOT/"
			fi
		]],
			root
		))
	elseif sub == "gcc-libs" then
		cmd(string.format(
			[[
			ROOT="%s"
			mkdir -p "$ROOT"
			# Metapackage placeholder
		]],
			root
		))
	else
		cmd(string.format(
			[[
			ROOT="%s"
			mkdir -p "$ROOT"
			if [ -d "split/%s" ]; then
				cp -a "split/%s"/* "$ROOT/"
			fi
		]],
			root,
			sub,
			sub
		))
	end

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/gcc --version || gcc --version
	]])
end

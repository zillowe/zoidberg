local version = ZOI.VERSION or "2.44"
local sha512 = "963dc0275f7738653379909b64ee32e28f13cca77440f2cf9bd0ab82cb183f6cd1f7376d25cc5442de69b972713bd81bf0e38dbcca9b2a4d6649843e76fd50a5"
-- Release signing key (Andreas K. Huettel, glibc release manager), from
-- upstream's published location https://www.akhuettel.de/key-atwork.txt (the
-- key Gentoo's sec-keys/openpgp-keys-glibc verifies releases with).
local signing_key = "35B17DF5752577CA0C541CEB94BFDF4484AD142F"

metadata({
	name = "glibc",
	repo = "core",
	version = version,
	revision = "1",
	-- The dynamic loader, libc and libthread_db keep their symbols and debug
	-- info: valgrind needs the loader's symbols and gdb needs libthread_db's
	-- to debug threads.
	debug = {
		sub_package = true,
		exclude = {
			"usr/lib/ld-linux*.so*",
			"usr/lib/libc.so*",
			"usr/lib/libthread_db.so*",
			"usr/lib32/ld-linux*.so*",
			"usr/lib32/libc.so*",
			"usr/lib32/libthread_db.so*",
		},
	},
	description = "GNU C Library for Parlex Linux",
	website = "https://www.gnu.org/software/libc",
	license = "GPL-2.0-or-later AND LGPL-2.1-or-later",
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
		"gencat",
		"getconf",
		"getent",
		"iconv",
		"ldconfig",
		"locale-gen",
		"localedef",
		"makedb",
		"rpcgen",
		"sprof",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	zsa = false,
	sub_packages = { "main", "lib32", "locales" },
	main_subs = { "main" },
	backup = {
		"${usrroot}/etc/gai.conf",
		"${usrroot}/etc/locale.gen",
		"${usrroot}/etc/tunables.conf",
		"${usrroot}/etc/tunables.conf.d/shstk.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:patch",
					"pacman:python",
					"pacman:gcc",
					"pacman:make",
					"pacman:bison",
					"pacman:gawk",
					"pacman:sed",
					"pacman:texinfo",
					"pacman:gettext",
					"pacman:diffutils",
					"pacman:perl",
					"pacman:lib32-gcc-libs",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/filesystem",
			"zoi:@core/iana-etc",
		},
		sub_packages = {
			lib32 = {
				required = {
					"zoi:@core/glibc",
				},
			},
			locales = {
				required = {
					"zoi:@core/glibc",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "glibc-" .. version .. ".tar.xz"
	cmd(
		[[
		# prepare() runs again for every sub-package in the same build
		# directory; download, unpack and patch only once.
		if [ -f "glibc-$VER/.zoi-prepared" ]; then
			exit 0
		fi
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/glibc" \
				"https://mirrors.kernel.org/gnu/glibc" \
				"https://ftp.gnu.org/gnu/glibc"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "glibc-$VER.tar.xz"
		fetch "glibc-$VER.tar.xz.sig"
		echo "$SHA512  glibc-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		# prepare() runs again for every sub-package in the same build
		# directory; the tree is unpacked and patched only once.
		if [ -f "glibc-$VER/.zoi-prepared" ]; then
			exit 0
		fi
		tar -xf "glibc-$VER.tar.xz"
		cd "glibc-$VER"
		# Fixes from the release/2.44/master branch made after the release
		patch -Np1 -i "$PKGLUADIR/patches/0001-backports-from-release-2.44-master.patch"
		# The patch updates these configure scripts together with their
		# configure.ac; keep the scripts newer so make never reruns autoconf.
		touch sysdeps/ieee754/ldbl-opt/configure \
			sysdeps/unix/sysv/linux/powerpc/configure
		touch .zoi-prepared
		cd ..
		mkdir -p glibc-build lib32-glibc-build locales
	]],
		opts
	)
end

function build()
	cmd(
		[[
		_configure_flags=(
			--prefix=/usr
			--with-headers=/usr/include
			--with-bugurl=https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/work_items
			--enable-bind-now
			--enable-fortify-source
			--enable-kernel=4.4
			--enable-multi-arch
			--enable-stack-protector=strong
			--enable-systemtap
			--disable-nscd
			--disable-profile
			--disable-werror
			# memusagestat would link libgd/libpng, which ZoiOS does not ship.
			--without-gd
		)

		CFLAGS="${CFLAGS/-Wp,-D_FORTIFY_SOURCE=3/}"

		# 64-bit build
		cd glibc-build
		echo "slibdir=/usr/lib" >> configparms
		echo "rtlddir=/usr/lib" >> configparms
		echo "sbindir=/usr/bin" >> configparms
		echo "rootsbindir=/usr/bin" >> configparms

		../glibc-$VER/configure \
			--libdir=/usr/lib \
			--libexecdir=/usr/lib \
			--enable-cet \
			--enable-sframe \
			"${_configure_flags[@]}"

		make -O -j"$(nproc)"
		make info
		cd ..

		# 32-bit build for x86_64
		if [ "$(uname -m)" = "x86_64" ]; then
			cd lib32-glibc-build
			export CC="gcc -m32 -mstackrealign"
			export CXX="g++ -m32 -mstackrealign"
			CFLAGS="${CFLAGS/-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer/}"

			echo "slibdir=/usr/lib32" >> configparms
			echo "rtlddir=/usr/lib32" >> configparms
			echo "sbindir=/usr/bin" >> configparms
			echo "rootsbindir=/usr/bin" >> configparms

			../glibc-$VER/configure \
				--host=i686-pc-linux-gnu \
				--libdir=/usr/lib32 \
				--libexecdir=/usr/lib32 \
				"${_configure_flags[@]}"

			make -O -j"$(nproc)"
			cd ..
		fi

		# Pregenerate locales
		make -C "glibc-$VER/localedata" objdir="$(pwd)/glibc-build" \
			DESTDIR="$(pwd)/locales" install-locale-files
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			mkdir -p "$ROOT"

			make -C glibc-build DESTDIR="$ROOT" install
			# The Info index is generated on the target, never shipped.
			rm -f "$ROOT/usr/share/info/dir"
			rm -f "$ROOT/etc/ld.so.cache"
			rm -f "$ROOT"/usr/bin/{tzselect,zdump,zic}

			mkdir -p "$ROOT/usr/lib/locale" "$ROOT/etc/tunables.conf.d" "$ROOT/usr/share/i18n" "$ROOT/usr/include/sys"

			# Gai configuration
			install -m644 "glibc-$VER/posix/gai.conf" "$ROOT/etc/gai.conf"

			# locale-gen utility and locale.gen definition
			install -m755 "${PKGLUADIR}/files/locale-gen" "$ROOT/usr/bin/locale-gen"
			install -m644 "${PKGLUADIR}/files/locale.gen.txt" "$ROOT/etc/locale.gen"
			sed -e '1,3d' -e 's|/| |g' -e 's|\\| |g' -e 's|^|#|g' \
				"glibc-$VER/localedata/SUPPORTED" >> "$ROOT/etc/locale.gen"

			sed -e '1,3d' -e 's|/| |g' -e 's| \\||g' \
				"glibc-$VER/localedata/SUPPORTED" > "$ROOT/usr/share/i18n/SUPPORTED"

			# Always include C.utf8
			cp -r locales/usr/lib/locale/C.utf8 "$ROOT/usr/lib/locale/C.utf8"
			sed -i '/#C\.UTF-8 /d' "$ROOT/etc/locale.gen"

			# SDT tracing headers
			install -m644 "${PKGLUADIR}/files/sdt.h" "$ROOT/usr/include/sys/sdt.h"
			install -m644 "${PKGLUADIR}/files/sdt-config.h" "$ROOT/usr/include/sys/sdt-config.h"

			# Tunables
			install -m644 "${PKGLUADIR}/files/tunables.conf" "$ROOT/etc/tunables.conf"
			install -m644 "${PKGLUADIR}/files/shstk.conf" "$ROOT/etc/tunables.conf.d/shstk.conf"

			# No lib64/ here: @core/filesystem makes /lib64 a symlink to usr/lib,
			# so /lib64/ld-linux-x86-64.so.2 already resolves to the real loader.
			# Shipping lib64/ld-linux-x86-64.so.2 -> ../usr/lib/... wrote that
			# symlink through /lib64 onto the loader itself, breaking every
			# program in the system.
		]],
			opts
		)

		zcp("${pkgluadir}/hooks/locale-gen.hook.yaml", "${pkgstore}/hooks/glibc-locale-gen.hook.yaml")
		zcp(
			"${pkgluadir}/hooks/remove-locale-archive.hook.yaml",
			"${pkgstore}/hooks/glibc-remove-locale-archive.hook.yaml"
		)
		zcp("${pkgluadir}/hooks/ldconfig.hook.yaml", "${pkgstore}/hooks/glibc-ldconfig.hook.yaml")
		zcp(
			"${pkgluadir}/hooks/remove-ldconfig-cache.hook.yaml",
			"${pkgstore}/hooks/glibc-remove-ldconfig-cache.hook.yaml"
		)
		zcp("${pkgluadir}/hooks/iconvconfig.hook.yaml", "${pkgstore}/hooks/glibc-iconvconfig.hook.yaml")
		zcp(
			"${pkgluadir}/hooks/remove-iconvconfig-cache.hook.yaml",
			"${pkgstore}/hooks/glibc-remove-iconvconfig-cache.hook.yaml"
		)

	elseif sub == "lib32" then
		cmd(
			[[
			mkdir -p "$ROOT"

			if [ -d lib32-glibc-build ]; then
				make -C lib32-glibc-build DESTDIR="$ROOT" install
				rm -rf "$ROOT"/{etc,sbin,var}
				rm -rf "$ROOT"/usr/{bin,sbin,share}

				# Keep only 32-bit specific headers
				find "$ROOT"/usr/include -type f -not -name '*-32.h' -delete

				# 32-bit dynamic linker symlink
				mkdir -p "$ROOT/usr/lib" "$ROOT/etc/ld.so.conf.d"
				ln -sf ../lib32/ld-linux.so.2 "$ROOT/usr/lib/ld-linux.so.2"
				install -m644 "${PKGLUADIR}/files/lib32-glibc.conf" "$ROOT/etc/ld.so.conf.d/lib32-glibc.conf"

				# Locale symlink to /usr/lib/locale
				mkdir -p "$ROOT/usr/lib32"
				ln -sf ../lib/locale "$ROOT/usr/lib32/locale"
			fi
		]],
			opts
		)

		zcp("${pkgluadir}/hooks/lib32-iconvconfig.hook.yaml", "${pkgstore}/hooks/lib32-glibc-iconvconfig.hook.yaml")
		zcp(
			"${pkgluadir}/hooks/lib32-remove-iconvconfig-cache.hook.yaml",
			"${pkgstore}/hooks/lib32-glibc-remove-iconvconfig-cache.hook.yaml"
		)
	elseif sub == "locales" then
		cmd(
			[[
			mkdir -p "$ROOT/usr/lib/locale"

			if [ -d locales/usr/lib/locale ]; then
				cp -r locales/usr/lib/locale/* "$ROOT/usr/lib/locale/"
				rm -rf "$ROOT/usr/lib/locale/C.utf8"
			fi
		]],
			opts
		)
	end

	-- Every sub-package gets its own copy (sub-packages never share files).
	-- LICENSES holds the notices for the parts under other licenses.
	local src = "glibc-" .. version
	zlicense(src .. "/COPYINGv2")
	zlicense(src .. "/COPYINGv3")
	zlicense(src .. "/COPYING.LIB")
	zlicense(src .. "/COPYING.LESSERv2")
	zlicense(src .. "/LICENSES")
end

function test()
	cmd([[
		/usr/bin/locale-gen --help || true
	]])
end

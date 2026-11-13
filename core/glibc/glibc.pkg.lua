local version = ZOI.VERSION or "2.44+r50+g1848099f063e"
local commit = "1848099f063e99d4ffecbd7667766d54862398b9"
local git_url = "https://forge.sourceware.org/glibc/glibc-mirror"

metadata({
	name = "glibc",
	repo = "core",
	version = version,
	revision = "4",
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
					"pacman:gd",
					"pacman:git",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d glibc ]; then
			git clone %s glibc
			cd glibc
			git checkout %s
			cd ..
		fi
		mkdir -p glibc-build lib32-glibc-build locales
	]],
		git_url,
		commit
	))
end

function build()
	cmd([[
		set -e

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
		)

		CFLAGS="${CFLAGS/-Wp,-D_FORTIFY_SOURCE=3/}"

		# 64-bit build
		cd glibc-build
		echo "slibdir=/usr/lib" >> configparms
		echo "rtlddir=/usr/lib" >> configparms
		echo "sbindir=/usr/bin" >> configparms
		echo "rootsbindir=/usr/bin" >> configparms

		../glibc/configure \
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

			../glibc/configure \
				--host=i686-pc-linux-gnu \
				--libdir=/usr/lib32 \
				--libexecdir=/usr/lib32 \
				"${_configure_flags[@]}"

			make -O -j"$(nproc)"
			cd ..
		fi

		# Pregenerate locales
		make -C glibc/localedata objdir="$(pwd)/glibc-build" \
			DESTDIR="$(pwd)/locales" install-locale-files
	]])
end

function package(args)
	local sub = (args and args.sub) or "main"
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")
	local pkgdir = LOCATION.PKGLUADIR or "."

	if sub == "main" or sub == "" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			PKGLUADIR="%s"
			mkdir -p "$ROOT"

			make -C glibc-build DESTDIR="$ROOT" install
			# The Info index is generated on the target, never shipped.
			rm -f "$ROOT/usr/share/info/dir"
			rm -f "$ROOT/etc/ld.so.cache"
			rm -f "$ROOT"/usr/bin/{tzselect,zdump,zic}

			mkdir -p "$ROOT/usr/lib/locale" "$ROOT/etc/tunables.conf.d" "$ROOT/usr/share/i18n" "$ROOT/usr/include/sys"

			# Gai configuration
			install -m644 glibc/posix/gai.conf "$ROOT/etc/gai.conf"

			# locale-gen utility and locale.gen definition
			install -m755 "${PKGLUADIR}/locale-gen" "$ROOT/usr/bin/locale-gen"
			install -m644 "${PKGLUADIR}/locale.gen.txt" "$ROOT/etc/locale.gen"
			sed -e '1,3d' -e 's|/| |g' -e 's|\\| |g' -e 's|^|#|g' \
				glibc/localedata/SUPPORTED >> "$ROOT/etc/locale.gen"

			sed -e '1,3d' -e 's|/| |g' -e 's| \\||g' \
				glibc/localedata/SUPPORTED > "$ROOT/usr/share/i18n/SUPPORTED"

			# Always include C.utf8
			cp -r locales/usr/lib/locale/C.utf8 "$ROOT/usr/lib/locale/C.utf8"
			sed -i '/#C\.UTF-8 /d' "$ROOT/etc/locale.gen"

			# SDT tracing headers
			install -m644 "${PKGLUADIR}/sdt.h" "$ROOT/usr/include/sys/sdt.h"
			install -m644 "${PKGLUADIR}/sdt-config.h" "$ROOT/usr/include/sys/sdt-config.h"

			# Tunables
			install -m644 "${PKGLUADIR}/tunables.conf" "$ROOT/etc/tunables.conf"
			install -m644 "${PKGLUADIR}/shstk.conf" "$ROOT/etc/tunables.conf.d/shstk.conf"

			# Ensure standard /lib64 interpreter symlink for x86_64
			if [ "$(uname -m)" = "x86_64" ]; then
				mkdir -p "$ROOT/lib64"
				ln -sf ../usr/lib/ld-linux-x86-64.so.2 "$ROOT/lib64/ld-linux-x86-64.so.2"
			fi
		]],
			root,
			pkgdir
		))

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

		-- zlicense("LICENSE")
	elseif sub == "lib32" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			PKGLUADIR="%s"
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
				install -m644 "${PKGLUADIR}/lib32-glibc.conf" "$ROOT/etc/ld.so.conf.d/lib32-glibc.conf"

				# Locale symlink to /usr/lib/locale
				mkdir -p "$ROOT/usr/lib32"
				ln -sf ../lib/locale "$ROOT/usr/lib32/locale"
			fi
		]],
			root,
			pkgdir
		))

		zcp("${pkgluadir}/hooks/lib32-iconvconfig.hook.yaml", "${pkgstore}/hooks/lib32-glibc-iconvconfig.hook.yaml")
		zcp(
			"${pkgluadir}/hooks/lib32-remove-iconvconfig-cache.hook.yaml",
			"${pkgstore}/hooks/lib32-glibc-remove-iconvconfig-cache.hook.yaml"
		)
	elseif sub == "locales" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT/usr/lib/locale"

			if [ -d locales/usr/lib/locale ]; then
				cp -r locales/usr/lib/locale/* "$ROOT/usr/lib/locale/"
				rm -rf "$ROOT/usr/lib/locale/C.utf8"
			fi
		]],
			root,
			pkgdir
		))
	end
end

function test()
	cmd([[
		/usr/bin/locale-gen --help || true
	]])
end

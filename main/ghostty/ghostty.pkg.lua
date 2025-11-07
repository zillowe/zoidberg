metadata({
	name = "ghostty",
	repo = "main",
	version = ZOI.VERSION or "1.2.3",
	description = "Fast, native, feature-rich terminal emulator pushing modern features.",
	sub_packages = {
		"main",
		"shell-integration",
		"terminfo",
	},
	main_subs = {
		"main",
		"shell-integration",
		"terminfo",
	},
	website = "https://ghostty.org",
	git = "https://github.com/ghostty-org/ghostty",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Mitchell Hashimoto",
		website = "https://mitchellh.com",
	},
	license = "MIT",
	bins = { "ghostty" },
	conflicts = { "ghostty" },
	types = { "source" },
})

dependencies({
	build = {
		required = { "native:zig@0.14", "native:blueprint-compiler", "native:pandoc-cli" },
	},
	runtime = {
		required = {
			"native:bzip2",
			"native:fontconfig",
			"native:freetype2",
			"native:gcc-libs",
			"native:glibc",
			"native:glib2",
			"native:gtk4",
			"native:gtk4-layer-shell",
			"native:libx11",
			"native:harfbuzz",
			"native:libadwaita",
			"native:libpng",
			"native:oniguruma",
			"native:pixman",
			"native:wayland",
			"native:zlib",
		},
	},
})

function prepare()
	UTILS.EXTRACT(
		"https://release.files.ghostty.org/" .. PKG.version .. "/ghostty-" .. PKG.version .. ".tar.gz",
		"ghostty-dir"
	)

	cmd(
		"cd ghostty-dir && ZIG_GLOBAL_CACHE_DIR="
			.. BUILD_DIR
			.. "/zig-global-cache/ ./nix/build-support/fetch-zig-cache.sh"
	)
end

function package(args)
	cmd(
		"cd ghostty-dir && DESTDIR="
			.. BUILD_DIR
			.. "/build zig build --summary all --prefix '/usr' --system '"
			.. BUILD_DIR
			.. "/zig-global-cache/p' -Doptimize=ReleaseFast -Dgtk-x11=true -Dcpu=baseline -Dpie=true -Demit-docs -Dversion-string='"
			.. PKG.version
			.. "'"
	)

	if args.sub == "main" then
		zcp("build/usr/bin/", "${usrroot}/usr/bin/")
		zcp("build/usr/share/applications/", "${usrroot}/usr/share/applications/")
		zcp("build/usr/share/icons/", "${usrroot}/usr/share/icons/")
		zcp("build/usr/share/licenses/", "${usrroot}/usr/share/licenses/")
		zcp("build/usr/share/man/", "${usrroot}/usr/share/man/")
		zcp("build/usr/share/metainfo/", "${usrroot}/usr/share/metainfo/")
	elseif args.sub == "shell-integration" then
		zcp("build/usr/share/ghostty/shell-integration/", "${usrroot}/usr/share/ghostty/shell-integration/")
	elseif args.sub == "terminfo" then
		zcp("build/usr/share/terminfo/", "${usrroot}/usr/share/terminfo/")
	end
end

function verify()
	return true
end

function uninstall() end

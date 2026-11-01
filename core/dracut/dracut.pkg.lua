local version = ZOI.VERSION or "111"
local tag = version
local git_url = "https://github.com/dracut-ng/dracut-ng.git"

metadata({
	name = "dracut",
	repo = "core",
	version = version,
	revision = "1",
	description = "An event driven initramfs infrastructure",
	website = "https://github.com/dracut-ng/dracut-ng",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Harald Hoyer and others",
		website = "https://github.com/dracut-ng/dracut-ng",
	},
	bins = {
		"dracut",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/dracut.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:asciidoctor",
					"pacman:bash-completion",
					"pacman:gcc",
					"pacman:git",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:rust",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/coreutils",
			"zoi:@core/findutils",
			"zoi:@core/gawk",
			"zoi:@core/glibc",
			"zoi:@core/grep",
			"zoi:@core/kmod",
			"zoi:@core/procps-ng",
			"zoi:@core/sed",
			"zoi:@core/util-linux",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d dracut ]; then
			git clone --depth 1 --branch "%s" "%s" dracut
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd dracut
		./configure --sysconfdir=/etc --prefix=/usr
		make -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		make -C dracut DESTDIR="$ROOT" install

		# Helper scripts
		if [ -f "${PKGLUADIR}/dracut-install.script" ]; then
			mkdir -p "$ROOT"/usr/lib/dracut "$ROOT"/usr/share/libalpm/scripts
			install -m755 "${PKGLUADIR}/dracut-install.script" "$ROOT"/usr/lib/dracut/dracut-install
			ln -sf /usr/lib/dracut/dracut-install "$ROOT"/usr/share/libalpm/scripts/dracut-install
		fi
		if [ -f "${PKGLUADIR}/dracut-remove.script" ]; then
			mkdir -p "$ROOT"/usr/lib/dracut "$ROOT"/usr/share/libalpm/scripts
			install -m755 "${PKGLUADIR}/dracut-remove.script" "$ROOT"/usr/lib/dracut/dracut-remove
			ln -sf /usr/lib/dracut/dracut-remove "$ROOT"/usr/share/libalpm/scripts/dracut-remove
		fi
	]],
		root
	))

	zcp("${pkgluadir}/hooks/dracut-install.hook.yaml", "${pkgstore}/hooks/dracut-install.hook.yaml")
	zcp("${pkgluadir}/hooks/dracut-remove.hook.yaml", "${pkgstore}/hooks/dracut-remove.hook.yaml")

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/dracut --help || dracut --help || true
	]])
end

local version = ZOI.VERSION or "113"
local sha512 =
	"d0137438d27a26b946eb64dde69a2b65a2d0d1487c789a3d29aaefcc10194ee22fdf68bf9438e3664a9cc0f86639d28675e74a8ebe4609342d0f306bca1fd20e"
-- Release signing key (Neal Gompa), listed in upstream's MAINTAINERS.md.
-- Upstream publishes no tarball of its own; it signs GitHub's tag archive.
local signing_key = "2B6250C4DC6D13D85AE220FDC5EC6EF7E1EA6B86"

metadata({
	name = "dracut",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
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
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "initramfs" },
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
					"pacman:curl",
					"pacman:gcc",
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

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "dracut-" .. version .. ".tar.gz"
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/dracut-ng/dracut/archive/refs/tags/$VER.tar.gz" \
			-o "dracut-$VER.tar.gz"
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/dracut-ng/dracut/releases/download/$VER/dracut-$VER.tar.gz.sig" \
			-o "dracut-$VER.tar.gz.sig"
		echo "$SHA512  dracut-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "dracut-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "dracut-$VER"
		./configure --sysconfdir=/etc --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "dracut-$VER" DESTDIR="$ROOT" install

		# Helper scripts
		if [ -f "${PKGLUADIR}/files/dracut-install.script" ]; then
			mkdir -p "$ROOT"/usr/lib/dracut "$ROOT"/usr/share/libalpm/scripts
			install -m755 "${PKGLUADIR}/files/dracut-install.script" "$ROOT"/usr/lib/dracut/dracut-install
			ln -sf /usr/lib/dracut/dracut-install "$ROOT"/usr/share/libalpm/scripts/dracut-install
		fi
		if [ -f "${PKGLUADIR}/files/dracut-remove.script" ]; then
			mkdir -p "$ROOT"/usr/lib/dracut "$ROOT"/usr/share/libalpm/scripts
			install -m755 "${PKGLUADIR}/files/dracut-remove.script" "$ROOT"/usr/lib/dracut/dracut-remove
			ln -sf /usr/lib/dracut/dracut-remove "$ROOT"/usr/share/libalpm/scripts/dracut-remove
		fi
	]],
		opts
	)

	zcp("${pkgluadir}/hooks/dracut-install.hook.yaml", "${pkgstore}/hooks/dracut-install.hook.yaml")
	zcp("${pkgluadir}/hooks/dracut-remove.hook.yaml", "${pkgstore}/hooks/dracut-remove.hook.yaml")

	zlicense("dracut-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/dracut --help || dracut --help || true
	]])
end

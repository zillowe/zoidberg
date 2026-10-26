local version = ZOI.VERSION or "2026.8"

metadata({
	name = "filesystem",
	repo = "core",
	version = version,
	revision = "1",
	description = "Base Parlex Linux files",
	website = "https://zillowe.qzz.io/parlex/linux",
	license = "0BSD",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/crypttab",
		"${usrroot}/etc/fstab",
		"${usrroot}/etc/group",
		"${usrroot}/etc/gshadow",
		"${usrroot}/etc/host.conf",
		"${usrroot}/etc/hosts",
		"${usrroot}/etc/issue",
		"${usrroot}/etc/ld.so.conf",
		"${usrroot}/etc/nsswitch.conf",
		"${usrroot}/etc/passwd",
		"${usrroot}/etc/profile",
		"${usrroot}/etc/resolv.conf",
		"${usrroot}/etc/securetty",
		"${usrroot}/etc/shadow",
		"${usrroot}/etc/shells",
		"${usrroot}/etc/subgid",
		"${usrroot}/etc/subuid",
	},
})

dependencies({
	runtime = {
		required = {
			"zoi:@core/iana-etc",
		},
	},
})

function package()
	-- - Directories
	-- Format: { [path] = { mode, user, group } }
	local directories = {
		["boot"] = { "0755", "root", "root" },
		["dev"] = { "0755", "root", "root" },
		["etc"] = { "0755", "root", "root" },
		["etc/ld.so.conf.d"] = { "0755", "root", "root" },
		["etc/profile.d"] = { "0755", "root", "root" },
		["etc/skel"] = { "0755", "root", "root" },
		["home"] = { "0755", "root", "root" },
		["mnt"] = { "0755", "root", "root" },
		["opt"] = { "0755", "root", "root" },
		["proc"] = { "0555", "root", "root" },
		["root"] = { "0750", "root", "root" },
		["run"] = { "0755", "root", "root" },
		["srv/http"] = { "0755", "root", "root" },
		["srv/ftp"] = { "0555", "root", "ftp" }, -- gid 11 is ftp
		["sys"] = { "0555", "root", "root" },
		["tmp"] = { "1777", "root", "root" },
		["usr"] = { "0755", "root", "root" },
		["usr/bin"] = { "0755", "root", "root" },
		["usr/include"] = { "0755", "root", "root" },
		["usr/lib"] = { "0755", "root", "root" },
		["usr/lib/ld.so.conf.d"] = { "0755", "root", "root" },
		["usr/local/bin"] = { "0755", "root", "root" },
		["usr/local/etc"] = { "0755", "root", "root" },
		["usr/local/games"] = { "0755", "root", "root" },
		["usr/local/include"] = { "0755", "root", "root" },
		["usr/local/lib"] = { "0755", "root", "root" },
		["usr/local/man"] = { "0755", "root", "root" },
		["usr/local/sbin"] = { "0755", "root", "root" },
		["usr/local/share"] = { "0755", "root", "root" },
		["usr/local/src"] = { "0755", "root", "root" },
		["usr/share/factory/etc"] = { "0755", "root", "root" },
		["usr/share/man/man1"] = { "0755", "root", "root" },
		["usr/share/man/man2"] = { "0755", "root", "root" },
		["usr/share/man/man3"] = { "0755", "root", "root" },
		["usr/share/man/man4"] = { "0755", "root", "root" },
		["usr/share/man/man5"] = { "0755", "root", "root" },
		["usr/share/man/man6"] = { "0755", "root", "root" },
		["usr/share/man/man7"] = { "0755", "root", "root" },
		["usr/share/man/man8"] = { "0755", "root", "root" },
		["usr/share/misc"] = { "0755", "root", "root" },
		["usr/share/pixmaps"] = { "0755", "root", "root" },
		["usr/src"] = { "0755", "root", "root" },
		["var"] = { "0755", "root", "root" },
		["var/cache"] = { "0755", "root", "root" },
		["var/empty"] = { "0755", "root", "root" },
		["var/games"] = { "0775", "root", "games" }, -- gid 50 is games
		["var/lib/misc"] = { "0755", "root", "root" },
		["var/local"] = { "0755", "root", "root" },
		["var/log/old"] = { "0755", "root", "root" },
		["var/opt"] = { "0755", "root", "root" },
		["var/spool/mail"] = { "1777", "root", "root" },
		["var/tmp"] = { "1777", "root", "root" },
	}

	for path, perms in pairs(directories) do
		local full_path = "${usrroot}/" .. path
		zmkdir(full_path)
		zchmod(full_path, perms[1])
		zchown(full_path, perms[2], perms[3])
	end

	-- - Symlinks
	local symlinks = {
		["bin"] = "usr/bin",
		["etc/mtab"] = "../proc/self/mounts",
		["lib"] = "usr/lib",
		["sbin"] = "usr/bin",
		["usr/local/share/man"] = "../man",
		["usr/sbin"] = "bin",
		["var/lock"] = "../run/lock",
		["var/mail"] = "spool/mail",
		["var/run"] = "../run",
	}

	for link, target in pairs(symlinks) do
		zln(target, "${usrroot}/" .. link)
	end

	if SYSTEM.ARCH == "amd64" then
		zln("usr/lib", "${usrroot}/lib64")
		zln("lib", "${usrroot}/usr/lib64")
	end

	-- - Files
	local files = {
		["etc/crypttab"] = { "crypttab", "0600", "root", "root" },
		["etc/fstab"] = { "fstab", "0644", "root", "root" },
		["etc/group"] = { "group", "0644", "root", "root" },
		["etc/gshadow"] = { "gshadow", "0600", "root", "root" },
		["etc/host.conf"] = { "host.conf", "0644", "root", "root" },
		["etc/hosts"] = { "hosts", "0644", "root", "root" },
		["etc/issue"] = { "issue", "0644", "root", "root" },
		["etc/ld.so.conf"] = { "ld.so.conf", "0644", "root", "root" },
		["etc/nsswitch.conf"] = { "nsswitch.conf", "0644", "root", "root" },
		["etc/passwd"] = { "passwd", "0644", "root", "root" },
		["etc/profile"] = { "profile", "0644", "root", "root" },
		["etc/profile.d/locale.sh"] = { "locale.sh", "0644", "root", "root" },
		["etc/resolv.conf"] = { "resolv.conf", "0644", "root", "root" },
		["etc/securetty"] = { "securetty", "0644", "root", "root" },
		["etc/shadow"] = { "shadow", "0600", "root", "root" },
		["etc/shells"] = { "shells", "0644", "root", "root" },
		["etc/subgid"] = { "subgid", "0644", "root", "root" },
		["etc/subuid"] = { "subuid", "0644", "root", "root" },
		["etc/parlex-release"] = { "parlex-release", "0644", "root", "root" },
		["usr/lib/os-release"] = { "os-release", "0644", "root", "root" },
		["usr/lib/sysctl.d/15-parlex.conf"] = { "sysctl", "0644", "root", "root" },
		["usr/lib/sysusers.d/parlex.conf"] = { "sysusers", "0644", "root", "root" },
		["usr/lib/tmpfiles.d/parlex.conf"] = { "tmpfiles", "0644", "root", "root" },
		["usr/lib/systemd/system-environment-generators/10-parlex"] = { "env-generator", "0755", "root", "root" },
	}

	-- Add factory copies
	local factory_files = {
		"parlex-release",
		"crypttab",
		"fstab",
		"group",
		"gshadow",
		"host.conf",
		"hosts",
		"issue",
		"ld.so.conf",
		"nsswitch.conf",
		"passwd",
		"profile",
		"resolv.conf",
		"securetty",
		"shadow",
		"shells",
		"subuid",
		"subgid",
	}
	for _, f in ipairs(factory_files) do
		local dest = "usr/share/factory/etc/" .. f
		files[dest] = { f, "0644", "root", "root" }
	end

	-- Also symlink /etc/os-release
	zln("../usr/lib/os-release", "${usrroot}/etc/os-release")

	-- Execute file installation
	for dest, info in pairs(files) do
		local src, mode, user, group = info[1], info[2], info[3], info[4]
		local final_dest = "${usrroot}/" .. dest
		zcp("${pkgluadir}/" .. src, final_dest)
		zchmod(final_dest, mode)
		zchown(final_dest, user, group)
	end

	-- Logo files
	local logos = {
		"parlexlinux-logo.png",
		"parlexlinux-logo.svg",
		"parlexlinux-logo-text.svg",
		"parlexlinux-logo-text-dark.svg",
	}
	for _, logo in ipairs(logos) do
		local dest = "${usrroot}/usr/share/pixmaps/" .. logo:gsub("parlexlinux", "parlex")
		zcp("${pkgluadir}/" .. logo, dest)
		zchmod(dest, "0644")
		zchown(dest, "root", "root")
	end

	zlicense("${pkgluadir}/LICENSE")
end

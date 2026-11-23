local version = ZOI.VERSION or "2026f"
local sha512_code = "eefcea60c37857214e1eba768d1bbd096de2a8f5afc9a776555552922cc174b32892d7442097b699b77efcba4d85649ed7d13e752ffdbcaad1050749c6c7b5aa"
local sha512_data = "26189803c8b3e903dcc467404e2feefb7d190cb1870249a23577ce31e9dcbf187e4704e0b45c8d1366d1c501bb5b53a2e80f8e2828b2163be15e532f6acab52d"
-- Release signing key (Paul Eggert), from keys.openpgp.org (the copy on
-- keyserver.ubuntu.com still carries the 2026-09-01 expiry).
local signing_key = "7E3792A9D8ACF7D633BC1588ED97E90E62AA7E34"

metadata({
	name = "tzdata",
	repo = "core",
	version = version,
	revision = "1",
	description = "Sources for time zone and daylight saving time data",
	website = "https://www.iana.org/time-zones",
	license = "LicenseRef-tz",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Internet Assigned Numbers Authority",
		website = "https://www.iana.org/time-zones",
	},
	bins = { "tzselect", "zdump", "zic" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = {
		VER = version,
		SHA512_CODE = sha512_code,
		SHA512_DATA = sha512_data,
		-- Same zone source files Arch compiles.
		ZONES = "africa antarctica asia australasia europe northamerica southamerica etcetera backward factory",
	},
}

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://data.iana.org/time-zones/releases" \
				"https://www.iana.org/time-zones/repository/releases"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "tzcode$VER.tar.gz"
		fetch "tzcode$VER.tar.gz.asc"
		fetch "tzdata$VER.tar.gz"
		fetch "tzdata$VER.tar.gz.asc"
		echo "$SHA512_CODE  tzcode$VER.tar.gz" | sha512sum -c -
		echo "$SHA512_DATA  tzdata$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	for _, tarball in ipairs({ "tzcode" .. version .. ".tar.gz", "tzdata" .. version .. ".tar.gz" }) do
		if not verifySignature(tarball, tarball .. ".asc", key) then
			error("bad upstream signature on " .. tarball)
		end
	end
	-- Both tarballs have no top-level directory; unpack them into one tree.
	cmd(
		[[
		mkdir "tzdb-$VER"
		tar -xzf "tzcode$VER.tar.gz" -C "tzdb-$VER"
		tar -xzf "tzdata$VER.tar.gz" -C "tzdb-$VER"
		# Install zic into /usr/bin, not /usr/sbin.
		sed -i "s:sbin:bin:g" "tzdb-$VER/Makefile"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "tzdb-$VER"
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "tzdb-$VER"
		# zic, zdump, tzselect, their man pages, tzdata.zi, leapseconds and
		# the zone tables.
		make DESTDIR="$ROOT" install

		# Compiled zones, plus the posix/ and right/ (leap second) variants.
		./zic -b fat -d "$ROOT/usr/share/zoneinfo" $ZONES
		./zic -b fat -d "$ROOT/usr/share/zoneinfo/posix" $ZONES
		./zic -b fat -d "$ROOT/usr/share/zoneinfo/right" -L leapseconds $ZONES
		# posixrules: POSIX requires the US daylight saving rules.
		./zic -b fat -d "$ROOT/usr/share/zoneinfo" -p America/New_York
		install -m644 -t "$ROOT/usr/share/zoneinfo" \
			iso3166.tab leap-seconds.list zone1970.tab zone.tab SECURITY

		# /etc/localtime belongs to the system configuration, and the static
		# libtz.a is not shipped (as on Arch).
		rm "$ROOT/etc/localtime"
		rmdir "$ROOT/etc"
		rm "$ROOT/usr/lib/libtz.a"
		rmdir "$ROOT/usr/lib"
	]],
		opts
	)

	zlicense("tzdb-" .. version .. "/LICENSE")
end

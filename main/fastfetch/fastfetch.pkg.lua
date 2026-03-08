local version = ZOI.VERSION or "2.60.0"
local release_base = "https://github.com/fastfetch-cli/fastfetch/releases/download/" .. version

INCLUDE("hashes.pkg.lua")

metadata({
  name = "fastfetch",
  repo = "main",
  version = version,
  description = "A feature-rich and performance oriented neofetch like system information tool",
  website = "https://github.com/fastfetch-cli/fastfetch",
  git = "https://github.com/fastfetch-cli/fastfetch.git",
  license = "MIT",
  maintainer = { name = "Zillowe Foundation", email = "contact@zillowe.qzz.io" },
  bins = { "fastfetch" },
  types = { "source", "pre-compiled" },
  tags = { "cli", "system-info", "neofetch", "utility" },
  scope = "system",
})

dependencies({
  build = {
    types = {
      source = {
        required = {
          "native:cmake",
          "native:pkg-config",
          "native:gcc",
          "native:yyjson",
          "native:sqlite",
          "native:zlib",
        },
        optional = {
          "native:imagemagick",
          "native:chafa",
          "native:dbus",
          "native:vulkan-loader",
          "native:wayland",
          "native:libxcb",
          "native:dconf",
          "native:ddcutil",
          "native:libpulse",
          "native:libxrandr",
          "native:ocl-icd",
          "native:xfconf",
          "native:libglvnd",
        },
      },
    },
  },
  runtime = {
    required = { "native:yyjson" },
  },
})

function prepare()
  if BUILD_TYPE == "pre-compiled" then
    local filenames = {
      ["linux-amd64"] = "fastfetch-linux-amd64.tar.gz",
      ["linux-arm64"] = "fastfetch-linux-aarch64.tar.gz",
      ["macos-amd64"] = "fastfetch-macos-amd64.tar.gz",
      ["macos-arm64"] = "fastfetch-macos-aarch64.tar.gz",
      ["windows-amd64"] = "fastfetch-windows-amd64.zip",
      ["windows-arm64"] = "fastfetch-windows-aarch64.zip",
    }

    local current = SYSTEM.OS .. "-" .. SYSTEM.ARCH
    local file_name = filenames[current] or error("Unsupported platform for pre-compiled binary: " .. current)

    local url = release_base .. "/" .. file_name
    UTILS.EXTRACT(url, "precompiled")
  else
    cmd("git clone --depth 1 --branch " .. version .. " " .. PKG.git .. " source")
  end
end

function package()
  if BUILD_TYPE == "source" then
    local build_args = "-DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr "
        .. "-DBUILD_FLASHFETCH=OFF -DBUILD_TESTS=OFF -DENABLE_SQLITE3=ON "
        .. "-DENABLE_RPM=OFF -DENABLE_IMAGEMAGICK6=OFF -DENABLE_SYSTEM_YYJSON=ON "
        .. "-DPACKAGES_DISABLE_APK=ON -DPACKAGES_DISABLE_DPKG=ON -DPACKAGES_DISABLE_EMERGE=ON "
        .. "-DPACKAGES_DISABLE_EOPKG=ON -DPACKAGES_DISABLE_GUIX=ON -DPACKAGES_DISABLE_LINGLONG=ON "
        .. "-DPACKAGES_DISABLE_LPKG=ON -DPACKAGES_DISABLE_LPKGBUILD=ON -DPACKAGES_DISABLE_OPKG=ON "
        .. "-DPACKAGES_DISABLE_PACSTALL=ON -DPACKAGES_DISABLE_PALUDIS=ON -DPACKAGES_DISABLE_PKG=ON "
        .. "-DPACKAGES_DISABLE_PKGTOOL=ON -DPACKAGES_DISABLE_RPM=ON -DPACKAGES_DISABLE_SORCERY=ON "
        .. "-DPACKAGES_DISABLE_XBPS=ON -Wno-dev"

    cmd("cmake -S source -B build " .. build_args)
    cmd("cmake --build build --parallel " .. (ZOI.parallel_jobs or 2))
    cmd("DESTDIR=" .. STAGING_DIR .. " cmake --install build")

    zcp(STAGING_DIR .. "/usr/bin/fastfetch", "${usrroot}/usr/bin/fastfetch")
    zcp(STAGING_DIR .. "/usr/share", "${usrroot}/usr/share")
  else
    local bin_ext = (SYSTEM.OS == "windows") and ".exe" or ""
    local arch_suffix = (SYSTEM.ARCH == "arm64" and "aarch64" or "amd64")
    local extract_path = "precompiled/fastfetch-" .. SYSTEM.OS .. "-" .. arch_suffix

    if UTILS.FS.exists(extract_path .. "/usr") then
      zcp(extract_path .. "/usr/bin/fastfetch" .. bin_ext, "${usrroot}/usr/bin/fastfetch" .. bin_ext)
      zcp(extract_path .. "/usr/share", "${usrroot}/usr/share")
    else
      zcp(extract_path .. "/fastfetch" .. bin_ext, "${usrroot}/usr/bin/fastfetch" .. bin_ext)
      if UTILS.FS.exists(extract_path .. "/fastfetch.json") then
        zcp(extract_path .. "/fastfetch.json", "${usrroot}/usr/share/fastfetch/presets/default.json")
      end
    end
  end
end

function verify()
  if BUILD_TYPE == "pre-compiled" then
    local filenames = {
      ["linux-amd64"] = "fastfetch-linux-amd64.tar.gz",
      ["linux-arm64"] = "fastfetch-linux-aarch64.tar.gz",
      ["macos-amd64"] = "fastfetch-macos-amd64.tar.gz",
      ["macos-arm64"] = "fastfetch-macos-aarch64.tar.gz",
      ["windows-amd64"] = "fastfetch-windows-amd64.zip",
      ["windows-arm64"] = "fastfetch-windows-aarch64.zip",
    }

    local current = SYSTEM.OS .. "-" .. SYSTEM.ARCH
    local expected_hash = HASHES[current]
    local archive_name = filenames[current]

    if expected_hash and archive_name then
      return verifyHash(BUILD_DIR .. "/" .. archive_name, "sha512-" .. expected_hash)
    end
  end
  return true
end

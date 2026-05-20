local function execute(cmd)
	local f = io.popen(cmd)
	local s = f:read("*a")
	f:close()
	return s:trim()
end

function string:trim()
	return self:match("^%s*(.-)%s*$")
end

local function serialize_json(val, indent)
	indent = indent or 0
	local pad = string.rep("  ", indent)
	local next_pad = string.rep("  ", indent + 1)

	if type(val) == "string" then
		return '"'
			.. val:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
			.. '"'
	elseif type(val) == "number" then
		return tostring(val)
	elseif type(val) == "boolean" then
		return tostring(val)
	elseif type(val) == "table" then
		local is_array = #val > 0 or (next(val) == nil and val._is_array)
		local parts = {}
		if is_array then
			for _, v in ipairs(val) do
				table.insert(parts, serialize_json(v, indent + 1))
			end
			if #parts == 0 then
				return "[]"
			end
			return "[\n" .. next_pad .. table.concat(parts, ",\n" .. next_pad) .. "\n" .. pad .. "]"
		else
			local keys = {}
			for k in pairs(val) do
				if k ~= "_is_array" then
					table.insert(keys, k)
				end
			end
			table.sort(keys)

			for _, k in ipairs(keys) do
				table.insert(parts, '"' .. k .. '": ' .. serialize_json(val[k], indent + 1))
			end
			if #parts == 0 then
				return "{}"
			end
			return "{\n" .. next_pad .. table.concat(parts, ",\n" .. next_pad) .. "\n" .. pad .. "}"
		end
	else
		return "null"
	end
end

local pkg_collect = {}
_G.metadata = function(t)
	pkg_collect = t
end
_G.dependencies = function() end
_G.updates = function() end
_G.hooks = function() end
_G.service = function() end
_G.SYSTEM = { OS = "linux", ARCH = "amd64" }
_G.ZOI = {}
_G.UTILS = {
	FETCH = {
		GITHUB = {
			LATEST = {
				release = function()
					return nil
				end,
			},
		},
	},
	FS = {
		exists = function()
			return false
		end,
	},
}
_G.BUILD_DIR = "."
_G.STAGING_DIR = "."
_G.BUILD_TYPE = "source"
_G.INCLUDE = function() end
_G.IMPORT = function()
	return ""
end

local advisories_raw = execute("cat advisories.json")
local last_id = tonumber(advisories_raw:match('"last_id":%s*(%d+)')) or 0
local year = tonumber(advisories_raw:match('"year":%s*(%d+)')) or tonumber(os.date("%Y"))
local current_year = tonumber(os.date("%Y"))

if year ~= current_year then
	last_id = 0
	year = current_year
end

local advisory_prefix = execute("yq e '.advisory_prefix // \"ZSA\"' repo.yaml")

local temp_files_raw = execute("find . -name '*TEMP.sec.yaml'")
for file in temp_files_raw:gmatch("[^\n]+") do
	local severity = execute("yq e '.severity' " .. file):lower()
	local sev_char = ({ low = "A", medium = "B", high = "C", critical = "D" })[severity] or "A"

	last_id = last_id + 1
	local id_padding = string.format("%04d", last_id)
	local final_id = string.format("%s-%d-%s%s", advisory_prefix, year, sev_char, id_padding)

	local dir = file:match("(.+)/[^/]+$")
	local final_file = dir .. "/" .. final_id .. ".sec.yaml"

	print("Assigning ID " .. final_id .. " to " .. file)
	os.execute(string.format("yq e -i '.id = \"%s\"' %s", final_id, file))
	os.rename(file, final_file)
end

local advisories_map = {}
local max_id = 0
local all_sec_files = execute("find . -name '*.sec.yaml' ! -name '*TEMP.sec.yaml'")
for file in all_sec_files:gmatch("[^\n]+") do
	local id = execute("yq e '.id' " .. file)
	local pkg = execute("yq e '.package' " .. file)
	local sub = execute("yq e '.sub_package' " .. file)

	local id_num = tonumber(id:match("%d%d%d%d$")) or 0
	if id_num > max_id then
		max_id = id_num
	end

	local pkg_display = pkg
	if sub ~= "null" and sub ~= "" then
		pkg_display = pkg .. ":" .. sub
	end
	advisories_map[string.format("%04d", id_num)] = pkg_display
end

last_id = math.max(last_id, max_id)
local adv_json = {
	version = "1",
	last_id = last_id,
	year = year,
	advisories = advisories_map,
}

local f_adv = io.open("advisories.json", "w")
f_adv:write(serialize_json(adv_json))
f_adv:close()

local packages = {}

local repo_types = {}
local repo_config_raw = execute("yq e -o=json '.repos' repo.yaml")
for item in repo_config_raw:gmatch("{(.-)}") do
	local name = item:match('"name":%s*"([^"]+)"')
	local rtype = item:match('"type":%s*"([^"]+)"')
	if name and rtype then
		repo_types[name] = rtype
	end
end

local pkg_files = execute("find . -name '*.pkg.lua' -not -path '*/.*'")
for file in pkg_files:gmatch("[^\n]+") do
	pkg_collect = {}
	local f_pkg = loadfile(file)
	if f_pkg then
		pcall(f_pkg)
		if pkg_collect.name then
			local dir = file:match("(.+)/[^/]+$")
			local repo_path = dir:gsub("^%./", ""):match("(.+)/[^/]+$") or dir:gsub("^%./", "")
			local major_repo = repo_path:match("^([^/]+)")

			local version = pkg_collect.version
			if not version and pkg_collect.versions then
				version = pkg_collect.versions.stable or pkg_collect.versions[next(pkg_collect.versions)]
			end

			local vulns = { _is_array = true }
			local sec_files = execute("find " .. dir .. " -name '*.sec.yaml' ! -name '*TEMP.sec.yaml'")
			for sec_file in sec_files:gmatch("[^\n]+") do
				local v_id = execute("yq e '.id' " .. sec_file)
				local v_sev = execute("yq e '.severity' " .. sec_file)
				local v_range = execute("yq e '.affected_range' " .. sec_file)
				local v_fixed = execute("yq e '.fixed_in' " .. sec_file)
				local v_summary = execute("yq e '.summary' " .. sec_file)

				table.insert(vulns, {
					id = v_id,
					severity = v_sev,
					affected_range = v_range,
					fixed_in = (v_fixed ~= "null") and v_fixed or nil,
					summary = v_summary,
				})
			end

			packages[pkg_collect.name] = {
				repo = repo_path,
				repo_type = repo_types[major_repo] or "unofficial",
				version = version or "unknown",
				description = pkg_collect.description or "",
				sub_packages = pkg_collect.sub_packages or { _is_array = true },
				vuln = (#vulns > 0) and vulns or nil,
			}

			if pkg_collect.sub_packages then
				packages[pkg_collect.name].sub_packages._is_array = true
			end
		end
	end
end

local final_index = { version = "1", packages = packages }
local f_idx = io.open("packages.json", "w")
f_idx:write(serialize_json(final_index))
f_idx:close()

print("Metadata generation complete: advisories.json and packages.json updated.")

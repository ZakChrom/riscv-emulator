CSRs = {}

local USER = 0
local MACHINE = 3
local READ = 1
local WRITE = 2

---@param csr integer
---@return integer?, string?
function CSRs.read(csr)
	local c = CSRs[csr]
	if c ~= nil then
		if Num.band(c.perms, READ) > 0 then
			return c.read()
		else
			-- TODO: Raise exception
			return nil, "csr does not allow reads"
		end
	end
	-- TODO: Raise exception
	return nil, "invalid csr"
end

---@param csr integer
---@param v integer
---@return boolean, string?
function CSRs.write(csr, v)
	local c = CSRs[csr]
	if c ~= nil then
		if Num.band(c.perms, WRITE) > 0 then
			return c.write(v)
		else
			-- TODO: Raise exception
			return false, "csr does not allow writes"
		end
	end
	-- TODO: Raise exception
	return false, "invalid csr"
end

-- The perms and mode are encoded in the csr number but whatever
-- Example:
-- CSRs[n] = {
-- 	mode = MACHINE,
-- 	perms = READ + WRITE,
-- 	read = function ()
		
-- 	end,
-- 	write = function (v)
		
-- 	end
-- }

-- misa
CSRs[0x301] = {
	mode = MACHINE,
	perms = READ + WRITE,
	read = function ()
		local extensions = 4353 -- ima = (1 << 8) | (1 << 12) | (1 << 0)
		local mxl = 1073741824 -- 1 << 30
		return mxl + extensions
	end,
	write = function (v)
		-- its WARL so you can write whatever but
		-- reads have to be legal so i can ignore it
		return true
	end
}

-- mvendorid
CSRs[0xf11] = {
	mode = MACHINE,
	perms = READ,
	read = function ()
		return 0
	end,
	write = function (v)
		return false -- unreachable
	end
}

-- marchid
CSRs[0xf12] = {
	mode = MACHINE,
	perms = READ,
	read = function ()
		return 0
	end,
	write = function (v)
		return false -- unreachable
	end
}
CSRs = {}

local USER = 0
local MACHINE = 3
local READ = 1
local WRITE = 2

---@param csr integer
---@return integer?
function CSRs.read(csr)
	local c = CSRs[csr]
	if c ~= nil then
		if Num.band(c.perms, READ) > 0 then
			return c.read()
		else
			-- TODO: Raise exception
		end
	else
		-- TODO: Raise exception
	end
end

---@param csr integer
---@param v integer
function CSRs.write(csr, v)
	local c = CSRs[csr]
	if c ~= nil then
		if Num.band(c.perms, WRITE) > 0 then
			c.write(v)
		else
			-- TODO: Raise exception
		end
	else
		-- TODO: Raise exception
	end
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
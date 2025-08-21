CSRs = {}
Mode = {}
Mode.User = 0
Mode.Machine = 3
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
	mode = Mode.Machine,
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
	mode = Mode.Machine,
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
	mode = Mode.Machine,
	perms = READ,
	read = function ()
		return 0
	end,
	write = function (v)
		return false -- unreachable
	end
}

-- mtvec
CSRs[0x305] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x305].v
	end,
	write = function (v)
		if Num.getBits(v, 0, 1) >= 2 then
			-- Mode >= 2 is reserved so reset it to 0
			v = Num.getBits(v, 2, 31) * 4
		end
		CSRs[0x305].v = v
		return true
	end
}

-- mscratch
CSRs[0x340] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x340].v
	end,
	write = function (v)
		CSRs[0x340].v = v
		return true
	end
}

-- mtval
CSRs[0x343] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x343].v
	end,
	write = function (v)
		CSRs[0x343].v = v
		return true
	end
}

-- mepc
CSRs[0x341] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x341].v
	end,
	write = function (v)
		-- Clear bottom bit because we dont support 16 bit aligned instructions
		CSRs[0x341].v = Num.getBits(v, 1, 31) * 2
		return true
	end
}

-- mie
CSRs[0x304] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x304].v
	end,
	write = function (v)
		-- Only support 16 kinds of interupts
		CSRs[0x304].v = Num.getBits(v, 0, 15)
		return true
	end
}

-- mip
CSRs[0x344] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x344].v
	end,
	write = function (v)
		-- Only support 16 kinds of interupts
		CSRs[0x344].v = Num.getBits(v, 0, 15)
		return true
	end
}

-- mcause
CSRs[0x342] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x342].v
	end,
	write = function (v)
		-- Techincally the exception code has to only have legal values but whatever
		CSRs[0x342].v = v
		return true
	end
}

-- I am NOT gonna check for legal values. It has like 20 fields in it
-- mstatus
CSRs[0x300] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x300].v
	end,
	write = function (v)
		CSRs[0x300].v = v
		return true
	end
}
-- mstatush
CSRs[0x310] = {
	v = 0,
	mode = Mode.Machine,
	perms = READ + WRITE,
	read = function ()
		return CSRs[0x310].v
	end,
	write = function (v)
		CSRs[0x310].v = v
		return true
	end
}
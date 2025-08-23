DTB = {}
DTB.base = 0x1000
function DTB.load(filename)
	local file = assert(io.open(filename, "rb"))
	DTB.dtb = file:read("*all")
	DTB.length = #DTB.dtb
	file:close()
end

DTB.load("the2.dtb") -- need it loaded to register it into memory

function DTB.read(addr)
	return DTB.dtb:byte(addr + 1, addr + 1)
end

Memory.register(DTB.base, DTB.length, {
	read = function (addr)
		return DTB.read(addr)
	end,
	write = function (addr, byte)
		-- unreachable
	end,
	validRead = function ()
		return true -- all readable
	end,
	validWrite = function ()
		return false -- no
	end
})
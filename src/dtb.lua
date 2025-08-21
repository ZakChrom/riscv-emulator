DTB = {}
DTB.base = 0x1000
function DTB.load(filename)
	local file = assert(io.open(filename, "rb"))
	DTB.dtb = file:read("a")
	DTB.length = #DTB.dtb
	file:close()
end

function DTB.read(addr)
	return DTB.dtb:byte(addr + 1, addr + 1)
end
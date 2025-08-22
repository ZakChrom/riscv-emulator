Ram = {}
Ram.data = {}
Ram.start = 0x80000000
Ram.length = 0x3ffc000

function Ram.get(addr)
	return Ram.data[addr] or 0
end

function Ram.set(addr, byte)
	if byte == 0 then
		Ram.data[addr] = nil
	else
		Ram.data[addr] = byte
	end
end

Memory.register(Ram.start, Ram.length, {
	read = function (addr)
		return Ram.get(addr)
	end,
	write = function (addr, byte)
		Ram.set(addr, byte)
	end,
	validRead = function ()
		return true -- all ram is readable
	end,
	validWrite = function ()
		return true -- all ram is writable
	end
})
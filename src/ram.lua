Ram = {}
Ram.data = {}
Ram.start = 0x80000000

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
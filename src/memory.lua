Memory = {
	memory = {}
}

---@param addr integer
---@return integer
function Memory.readRaw(addr)
	if addr == UART.io then
		return UART.read()
	elseif addr == UART.status then
		return UART.status
	end

	return Memory.memory[addr] or 0
end

---@param addr integer
---@param byte integer
function Memory.writeRaw(addr, byte)
	if addr == UART.io then
		UART.write(byte)
	elseif addr == UART.status then
		return; -- no thanks
	end

	if byte == 0 then
		Memory.memory[addr] = nil
	else
		Memory.memory[addr] = byte
	end
end

---@param addr integer
---@param n_bytes integer?
---@return integer
function Memory.read(addr, n_bytes)
	if n_bytes == nil then
		n_bytes = 1
	end

	local num = 0;
	for i = 0, n_bytes-1 do
		num = num + Num.lshift(Memory.readRaw(addr + i), i * 8)
	end

	return num
end

---@param addr integer
---@param v integer
---@param n_bytes integer?
function Memory.write(addr, v, n_bytes)
	if n_bytes == nil then
		n_bytes = 1
	end

	for i = 0, n_bytes-1 do
		local real = Num.rshift(v, i * 8) % 256
		Memory.writeRaw(addr + 1, real)
	end
end

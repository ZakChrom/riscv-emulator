Memory = {}

function Memory.validWrite(staddr, len)
	len = len or 1
	for i = 0,len-1 do
		local addr = staddr + i
		local ok = false
		if addr == UART.io then
			ok = true
		elseif addr == UART.status then
			ok = true
		elseif addr >= UART.base and addr < (UART.base + 0x100) then
			ok = true
		elseif addr >= Ram.start then
			ok = true
		end

		if not ok then return false end
	end

	return true
end

function Memory.validRead(staddr, len)
	len = len or 1
	for i = 0,len-1 do
		local addr = staddr + i
		local ok = false
		if addr == UART.io then
			ok = true
		elseif addr == UART.status then
			ok = true
		elseif addr >= UART.base and addr < (UART.base + 0x100) then
			ok = true
		elseif addr >= DTB.base and addr < (DTB.base + DTB.length) then
			ok = true
		elseif addr >= Ram.start then
			ok = true
		end

		if not ok then return false end
	end

	return true
end

---@param addr integer
---@return integer
function Memory.readRaw(addr)
	if addr == UART.io then
		return UART.read()
	elseif addr == UART.status then
		return UART.status2()
	elseif addr >= UART.base and addr < (UART.base + 0x100) then
		return 0
	elseif addr >= DTB.base and addr < (DTB.base + DTB.length) then
		return DTB.read(addr - DTB.base)
	elseif addr >= Ram.start then
		return Ram.get(addr - Ram.start)
	end

	return false
end

---@param addr integer
---@param byte integer
function Memory.writeRaw(addr, byte)
	if addr == UART.io then
		UART.write(byte)
		return true
	elseif addr == UART.status then
		-- no thanks
		return true -- definitely succeeded
	elseif addr >= UART.base and addr < (UART.base + 0x100) then
		return true -- nuh uh
	elseif addr >= Ram.start then
		Ram.set(addr - Ram.start, byte)
		return true
	end

	return false
end

---@param addr integer
---@param n_bytes integer?
---@return integer
function Memory.read(addr, n_bytes)
	if not Memory.validRead(addr, n_bytes) then
		return false
	end

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
	if not Memory.validWrite(addr, n_bytes) then
		return false
	end

	if n_bytes == nil then
		n_bytes = 1
	end

	for i = 0, n_bytes-1 do
		local real = Num.rshift(v, i * 8) % 256
		Memory.writeRaw(addr + i, real) -- no checking here because we already checked it with validWrite
	end

	return true;
end

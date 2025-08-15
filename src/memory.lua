Memory = {
	memory = {}
}

---@param addr integer
---@param n_bytes integer?
---@return integer
function Memory.read(addr, n_bytes)
	if n_bytes == nil then
		n_bytes = 1
	end

	local num = 0;
	for i = 0, n_bytes-1 do
		num = num + Num.lshift(Memory.memory[addr + i] or 0, i * 8)
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
		local real = Num.rshift(v, i * 8) % 255
		if real == 0 then
			Memory.memory[addr + i] = nil
		else
			Memory.memory[addr + i] = real
		end
	end
end

Memory = {
	memory = string.rep(string.byte(0), 1024)
}

---@param addr integer
---@param n_bytes integer?
---@return integer
function Memory.read(addr, n_bytes)
	if n_bytes == nil then
		n_bytes = 1
	end

	local num = 0;
	for i = 0, #n_bytes do
		num = Num.lshift(Memory.memory:byte(addr + 1 + i, addr + 1 + i), i * 8)
	end

	return num
end

---@param addr integer
---@param v integer
function Memory.write(addr, v)
	Memory.memory = Memory.memory:sub(1, addr - 1 + 1) .. string.byte(v) .. Memory.memory:sub(addr + 1 + 1)
end

Memory = {
	memory = string.rep(string.byte(0), 1024)
}

---@param addr integer
---@return integer
function Memory.read(addr)
	return Memory.memory:byte(addr + 1, addr + 1)
end

---@param addr integer
---@param v integer
function Memory.write(addr, v)
	Memory.memory = Memory.memory:sub(1, addr - 1 + 1) .. string.byte(v) .. Memory.memory:sub(addr + 1 + 1)
end

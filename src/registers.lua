Registers = {
	x = {}
}

for i = 0, 31 do
	Registers.x[i] = 0
end

---@param reg integer
---@return integer
function Registers.read(reg)
	return Registers.x[reg]
end

---@param reg integer
---@param v integer
function Registers.write(reg, v)
	if reg ~= 0 then
		Registers.x[reg] = v
	end
end
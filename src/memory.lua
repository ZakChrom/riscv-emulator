Memory = {}
Memory.blocks = {} -- "block" here is just a group of shit because idk what else to name it

function Memory.register(st,size,callbacks)
	Memory.blocks[#Memory.blocks+1] = {st,size,callbacks}
end

function Memory.validWrite(staddr, len)
	len = len or 1
	for i = 0,len-1 do
		local addr = staddr + i
		local foundblock = false

		for j = 1,#Memory.blocks do
			local block = Memory.blocks[j]
			local st,size = block[1],block[2]
			local cbs = block[3]

			if addr >= st and addr < st+size then
				local localaddr = addr - st

				if not cbs.validWrite(localaddr) then return false end
				foundblock = true;

				break -- no other blocks needed
			end
		end

		if not foundblock then return false end
	end

	return true
end

function Memory.validRead(staddr, len)
	len = len or 1
	for i = 0,len-1 do
		local addr = staddr + i
		local foundblock = false

		for j = 1,#Memory.blocks do
			local block = Memory.blocks[j]
			local st,size = block[1],block[2]
			local cbs = block[3]

			if addr >= st and addr < st+size then
				local localaddr = addr - st

				if not cbs.validRead(localaddr) then return false end
				foundblock = true;

				break -- no other blocks needed
			end
		end

		if not foundblock then return false end
	end

	return true
end

---@param addr integer
---@return integer
function Memory.readRaw(addr) -- raw functions assume you've already checked it's valid
	for j = 1,#Memory.blocks do
		local block = Memory.blocks[j]
		local st,size = block[1],block[2]
		local cbs = block[3]

		if addr >= st and addr < st+size then
			local localaddr = addr - st
			return cbs.read(localaddr)
		end
	end

	return false
end

---@param addr integer
---@param byte integer
function Memory.writeRaw(addr, byte)
	for j = 1,#Memory.blocks do
		local block = Memory.blocks[j]
		local st,size = block[1],block[2]
		local cbs = block[3]

		if addr >= st and addr < st+size then
			local localaddr = addr - st
			cbs.write(localaddr, byte)
			return true
		end
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

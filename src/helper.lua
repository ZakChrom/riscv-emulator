
Num = {} -- a little thing for operations that limit to 32 bits.. and a bit more
-- assumed unsigned!

function Num.add(a,b)
	return (a+b) % (2^32) -- limit to 32 bits
end

function Num.isneg(a)
	return a >= 2^31
end

function Num.sub(a,b)
	-- return Num.add(a, Num.negate(b))
	return (a - b) % 2^32
end

function Num.negate(a) -- the number is stored as **unsigned** in lua.
	return (2^32 - a) % (2^32)
end

---@param a integer
---@param bits integer
---@return integer
function Num.signed(a, bits)
	if a >= 2^(bits - 1) then
		return a - 2^bits
	end

	return a;
end

function Num.rshift(a, amount)
	assert(amount >= 0)
	return math.floor(a / (2^amount))
end

function Num.lshift(a, amount)
	assert(amount >= 0)
	a = a * 2^amount
	return a % (2^32)
end

function Num.band(a,b)
	local res = 0
	for i = 0,31 do
		local ba,bb = a%2,b%2
		if ba == 1 and bb == 1 then
			res = res + 2^i
		end
		a,b = math.floor(a/2),math.floor(b/2)
	end
	return res
end

function Num.bor(a,b)
	local res = 0
	for i = 0,31 do
		local ba,bb = a%2,b%2
		if ba == 1 or bb == 1 then
			res = res + 2^i
		end
		a,b = math.floor(a/2),math.floor(b/2)
	end
	return res
end

function Num.bxor(a,b)
	local res = 0
	for i = 0,31 do
		local ba,bb = a%2,b%2
		if ba ~= bb then
			res = res + 2^i
		end
		a,b = math.floor(a/2),math.floor(b/2)
	end
	return res
end

function Num.getBits(a, pos1, pos2) -- starts at 0. example: getBits(0b1010, 0, 1) == 0b10, getBits(0b1010, 1,2) == 0b01
	a = Num.rshift(a, pos1)

	local offset = pos2-pos1
	a = a % (2^(offset + 1))

	return a
end

function Num.multiply(a,b) -- returns the less significant part first.
	-- here for precision concerns.

	-- turn it into a bunch of 16bit chunks
	local al = a % (2^16)
	local ah = math.floor(a / (2^16))

	local bl = b % (2^16)
	local bh = math.floor(b / (2^16))

	-- now: multiplication we do could only result in up to 32 bits, meaning it's safe to do

	local p0 = al*bl
	local p1 = al*bh
	local p2 = ah*bl
	local p3 = ah*bh

	-- no, i don't understand it either: but i think it works (?)
	local mid = p1+p2 -- max 33 bits (i think)
	local midl = mid % (2^16) -- lower 32 bits
	local midh = math.floor(mid / (2^16)) -- 1 upper bit (lol)

	local shit = (p0 + midl * (2^16)) -- 32 bits + 32 bits = max 33 bits

	local lo = shit % (2^32) -- get rid of the 33rd bit
	local carry = math.floor(shit / (2^32)) -- the 33rd bit

	local hi = (p3 + midh + carry) % (2^32) -- 32 bits + 1 bit + 1 bit: max 33 bits

	return lo,hi
end
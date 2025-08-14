
Num = {} -- a little thing for operations that limit to 32 bits.. and a bit more
-- assumed unsigned!

function Num.add(a,b)
	return (a+b) % (2^32) -- limit to 32 bits
end

function Num.signed(a)
	assert(a < 2^32) -- idk just in case

	if a >= 2^31 then
		return (-(2^31)) + (a - (2^31))
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
	local mid = p1+p2
	local midl = mid % (2^16)
	local midh = math.floor(mid / (2^16))

	local shit = (p0 + midl * (2^16))

	local lo = shit % (2^32)
	local carry = math.floor(shit / (2^32))

	local hi = (p3 + midh + carry) % (2^32)

	return lo,hi
end
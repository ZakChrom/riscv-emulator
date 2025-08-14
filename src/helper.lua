
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
	-- for now: bullshit method
	-- TODO: method that doesn't lose precision.
	local mult = a*b

	local ret1 = math.floor(mult % (2^32))
	local ret2 = math.floor(mult / (2^32))

	return ret1, ret2
end
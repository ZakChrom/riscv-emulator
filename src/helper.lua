
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
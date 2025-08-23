CLINT = {}
CLINT.start = 0x11000000
CLINT.length = 0x10000
CLINT.timer_lo = 0
CLINT.timer_hi = 0
CLINT.cmp_lo = 0xFFFFFFFF
CLINT.cmp_hi = 0xFFFFFFFF
CLINT.msip = 0

CLINT.hz = 10000000

local function get_byte(num, byte)
	return Num.getBits(num, byte*8, byte*8 + 7)
end

local function set_byte(num, location, newbyte)
	return Num.clear(num, Num.lshift(0xff, location*8)) + Num.lshift(newbyte, location*8)
end

function CLINT.update(ticks) -- set the timer value and things
	CLINT.timer_lo = CLINT.timer_lo + ticks

	if CLINT.timer_lo >= 0x100000000 then
		CLINT.timer_hi = CLINT.timer_hi + math.floor(CLINT.timer_lo / 0x100000000)
		CLINT.timer_lo = CLINT.timer_lo % 0x100000000
	end

	if (CLINT.timer_hi > CLINT.cmp_hi) or
	   (CLINT.timer_hi == CLINT.cmp_hi and CLINT.timer_lo >= CLINT.cmp_lo) then
		
		-- TODO: interrupt for timer
	end
end

Memory.register(CLINT.start, CLINT.length, {
	read = function (addr)
		if addr >= 0 and addr <= 0x3 then -- msip
			return get_byte(CLINT.msip, addr)
		elseif addr >= 0x4000 and addr <= 0x4003 then -- mtimecmp low
			local byte = addr - 0x4000
			return get_byte(CLINT.cmp_lo, byte)
		elseif addr >= 0x4004 and addr <= 0x4007 then -- mtimecmp hi
			local byte = addr - 0x4004
			return get_byte(CLINT.cmp_hi, byte)
		elseif addr >= 0xBFF8 and addr <= 0xBFFB then -- mtime lo
			local byte = addr - 0xBFF8
			return get_byte(CLINT.timer_lo, byte)
		elseif addr >= 0xBFFC and addr <= 0xBFFF then
			local byte = addr - 0xBFFC
			return get_byte(CLINT.timer_hi, byte)
		end

		return 0
	end,
	write = function (addr, byte)
		if addr >= 0 and addr <= 0x3 then -- msip
			CLINT.msip = set_byte(CLINT.msip, addr, byte)
		elseif addr >= 0x4000 and addr <= 0x4003 then -- mtimecmp low
			local where = addr - 0x4000
			set_byte(CLINT.cmp_lo, where, byte)
		elseif addr >= 0x4004 and addr <= 0x4007 then -- mtimecmp hi
			local where = addr - 0x4004
			set_byte(CLINT.cmp_hi, where, byte)
		end
	end,
	validRead = function ()
		return true -- eh i'll just return 0 if it's not something i know
	end,
	validWrite = function ()
		return true -- ignore ones i don't know: because it's easier
	end
})

-- print(Memory.read(0x11000000 + 0xBFF8, 4))
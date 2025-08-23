UART = {}
UART.inputBuffer = {}

UART.base = 0x10000000
UART.length = 0x100

local stdin_waiting = require('src.nonblock')

function UART.update()
	if stdin_waiting and stdin_waiting() then
		local char = io.read(1)

		UART.inputBuffer[#UART.inputBuffer+1] = char
	end
end

function UART.getStatus()
	local val = 0x60 -- says we're ready to receive output
	if #UART.inputBuffer > 0 then
		val = val + 0x01 -- says we're ready to feed it data
	end

	return val
end

function UART.read()
	if #UART.inputBuffer > 0 then
		local val = UART.inputBuffer[1]
		table.remove(UART.inputBuffer,1)
		return val
	else
		return 0 -- shouldn't happen, but whatever.
	end
end

function UART.write(byte)
	io.write(string.char(byte))
	io.flush()
end

Memory.register(UART.base, UART.length, {
	read = function (addr)
		if addr == 0 then
			return UART.read()
		elseif addr == 5 then
			return UART.getStatus()
		end
		return 0 -- you can have a 0
	end,
	write = function (addr, byte)
		if addr == 0 then -- io
			UART.write(byte)
		end
		-- ignore
	end,
	validRead = function ()
		return true -- just ignore anything we don't have implemented :)
	end,
	validWrite = function ()
		return true -- again, ignore what we don't have implemented: act like it's there
	end
})
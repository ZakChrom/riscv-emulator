UART = {}
UART.inputBuffer = {}

UART.base = 0x10000000
UART.io = UART.base
UART.status = UART.base + 0x05

local stdin_waiting = require('src.nonblock')

function UART.update()
	if stdin_waiting and stdin_waiting() then
		local char = io.read(1)

		UART.inputBuffer[#UART.inputBuffer+1] = char
	end
end

function UART.status()
	local val = 0x20 -- says we're ready to receive output
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
	io.write(byte)
end
require("src.helper")
require("src.memory")

local pc = 0

while true do
	local inst = Memory.read(pc, 4)

	if Num.getBits(inst, 0,1) == 3 then -- normal 32-bit instruction
		
	else
		-- raise illegal instruction... or handle c extension if we do that... or other stuff
	end

	pc = pc + 4
end
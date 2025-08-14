require("src.helper")
require("src.memory")

local pc = 0

while true do
	local inst = Memory.read(pc, 4)

	if Num.getBits(inst, 0,1) == 3 then -- normal 32-bit instruction
		local opcode = Num.getBits(inst, 0,6)

		if opcode == 55 then -- 0b0110111, LUI
		elseif opcode == 23 then -- 0010111, AUIPC
		elseif opcode == 111 then -- 0b1101111, JAL
		elseif opcode == 103 then -- 0b1100111, JALR
		elseif opcode == 99 then -- 0b1100011, BRANCH
		elseif opcode == 3 then -- 0b0000011, LOAD
		elseif opcode == 35 then -- 0b0100011, STORE
		elseif opcode == 19 then -- 0b0010011, immediate register stuff
		elseif opcode == 51 then -- 0b0110011, register register stuff (but also mul/div from `m`)
		elseif opcode == 15 then -- 0b0001111, fence.i
		elseif opcode == 115 then -- 0b1110011 system (ecall, ebreak, Zicsr stuff)
		elseif opcode == 47 then -- 0b0101111, AMO
		end
	else
		-- raise illegal instruction... or handle c extension if we do that... or other stuff
	end

	pc = pc + 4
end
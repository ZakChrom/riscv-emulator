require("src.helper")
require("src.memory")
require("src.registers")

local pc = 0

while true do
	local inst = Memory.read(pc, 4)

	if Num.getBits(inst, 0,1) == 3 then -- normal 32-bit instruction
		local opcode = Num.getBits(inst, 0,6)

		if opcode == 55 then -- 0b0110111, LUI
			local rd = Num.getBits(inst, 7, 11)
			local imm = Num.getBits(inst, 12, 31)

			imm = Num.lshift(imm, 12) -- fill lowest 12 bits with zeroes

			Registers.write(rd, imm)
		elseif opcode == 23 then -- 0010111, AUIPC
			local rd = Num.getBits(inst, 7, 11)
			local imm = Num.getBits(inst, 12, 31)

			imm = Num.lshift(imm, 12)

			Registers.write(rd, imm + pc)
		elseif opcode == 111 then -- 0b1101111, JAL
			local rd = Num.getBits(inst, 7, 11)
		elseif opcode == 103 then -- 0b1100111, JALR
			local funct3 = Num.getBits(inst, 12, 14)
		elseif opcode == 99 then -- 0b1100011, BRANCH
			local funct3 = Num.getBits(inst, 12, 14)

			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)
		elseif opcode == 3 then -- 0b0000011, LOAD
			local rd = Num.getBits(inst, 7, 11)
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
		elseif opcode == 35 then -- 0b0100011, STORE
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)
		elseif opcode == 19 then -- 0b0010011, immediate register stuff
			local funct3 = Num.getBits(inst, 12, 14)
			local rd = Num.getBits(inst, 7, 11)
			local rs1 = Num.getBits(inst, 15, 19)
		elseif opcode == 51 then -- 0b0110011, register register stuff (but also mul/div from `m`)
			local rd = Num.getBits(inst, 7, 11)
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)

			local funct7 = Num.getBits(inst, 25, 31)

			if (funct7 % 2) == 1 then
				local rs1v, rs2v = Registers.read(rs1), Registers.read(rs2)
				-- M extension
				if funct3 == 0 then -- MUL: signed x signed lower bits
					local lo,hi = Num.multiply(rs1v, rs2v)

					Registers.write(rd, lo)
				elseif funct3 == 1 then -- MULH: signed x signed upper bits
					local lo,hi = Num.multiply(rs1v, rs2v)

					local newhi = hi
					if Num.isneg(rs1v) then -- shenanigans that i read about somewhere that may or may not work
						newhi = newhi - rs2v
					end
					if Num.isneg(rs2v) then
						newhi = newhi - rs1v
					end

					newhi = newhi % (2^ 32)

					Registers.write(rd, newhi)
				elseif funct3 == 2 then -- MULHSU: signed x unsigned upper bits
					local lo,hi = Num.multiply(rs1v, rs2v)

					local newhi = hi
					if Num.isneg(rs1v) then -- shenanigans again
						newhi = newhi - rs2v
					end

					newhi = newhi % (2^ 32)

					Registers.write(rd, newhi)
				elseif funct3 == 3 then -- MULHU: unsigned x unsigned upper bits
					local lo,hi = Num.multiply(rs1v, rs2v)

					Registers.write(rd, hi)
				end
			else
				if funct3 == 0 then -- ADD/SUB
					if funct7 == 0 then -- add
						Registers.write(rd, Num.add(Registers.read(rs1), Registers.read(rs2)))
					elseif funct7 == 32 then -- 0b0100000 sub
						Registers.write(rd, Num.sub(Registers.read(rs1), Registers.read(rs2)))
					end
				elseif funct3 == 1 then -- SLL
					if funct7 == 0 then
						Registers.write(rd, Num.lshift(Registers.read(rs1), Registers.read(rs2)))
					end
				-- TODO: the rest
				end
			end
		elseif opcode == 15 then -- 0b0001111, fence.i
		elseif opcode == 115 then -- 0b1110011 system (ecall, ebreak, Zicsr stuff)
			local funct3 = Num.getBits(inst, 12, 14)
			local rd = Num.getBits(inst, 7, 11)
			local rs1 = Num.getBits(inst, 15, 19)
		elseif opcode == 47 then -- 0b0101111, AMO
			local rd = Num.getBits(inst, 7, 11)
			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)
			local funct3 = Num.getBits(inst, 12, 14)
			local funct5 = Num.getBits(inst, 27, 31)

			local rl = Num.getBits(25,25)
			local aq = Num.getBits(26,26)
		end
	else
		-- raise illegal instruction... or handle c extension if we do that... or other stuff
	end

	pc = pc + 4
end
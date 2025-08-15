require("src.helper")
require("src.memory")
require("src.registers")

---@param inst integer
---@return integer
local function b_type_imm(inst)
	return (Num.getBits(inst, 31, 31) << 12) + (Num.getBits(inst, 7, 7) << 11) + (Num.getBits(inst, 25, 30) << 5) + (Num.getBits(inst, 8, 11) << 1)
end

---@param inst integer
---@return integer
local function s_type_imm(inst)
	return (Num.getBits(inst, 25, 31) << 5) + Num.getBits(inst, 7, 11)
end

local pc = 0

while true do
	local inst = Memory.read(pc, 4)
	local pc_inc_amount = 4

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

			local imm20 = Num.getBits(inst, 31, 31)
			local imm10_1 = Num.getBits(inst, 21, 30)
			local imm11 = Num.getBits(inst, 20,20)
			local imm19_12 = Num.getBits(inst, 12,19)

			local imm = imm20 * 2^20 + imm19_12 * 2^12 + imm11 * 2^11 + imm10_1 * 2^1 -- i have no fucking clue if this works :thubm_pu:

			if imm20 > 0 then -- sign bit fuck
				imm = imm - 2^21
			end

			Registers.write(rd, pc + 4)

			pc_inc_amount = imm
		elseif opcode == 103 then -- 0b1100111, JALR
			local rd = Num.getBits(inst, 7, 11)
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
			local imm = Num.getBits(20, 31)

			if Num.getBits(imm, 11, 11) == 1 then -- sign bit
				imm = imm - 2^12
			end

			local base = Registers.read(rs1)
			local target = base + imm

			target = target - (target % 2) -- the spec tells me to clear this bit so i do (idk why honestly but apparently they wanted it to work that way)

			Registers.write(rd, pc + 4)
			pc = target
			pc_inc_amount = 0
		elseif opcode == 99 then -- 0b1100011, BRANCH
			local funct3 = Num.getBits(inst, 12, 14)

			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)
			local a = Registers.read(rs1)
			local b = Registers.read(rs2)
			local sa = Num.signed(a, 32)
			local sb = Num.signed(b, 32)

			local imm = b_type_imm(inst)
			local inc = Num.signed(imm, 12)
			if funct3 == 0 then -- BEQ
				if a == b then
					pc_inc_amount = inc
				end
			elseif funct3 == 1 then -- BNE
				if a ~= b then
					pc_inc_amount = inc
				end
			elseif funct3 == 4 then -- BLT
				if sa < sb then
					pc_inc_amount = inc
				end
			elseif funct3 == 5 then -- BGE
				if sa > sb then
					pc_inc_amount = inc
				end
			elseif funct3 == 6 then -- BLTU
				if a < b then
					pc_inc_amount = inc
				end
			elseif funct3 == 7 then -- BGEU
				if a >= b then
					pc_inc_amount = inc
				end
			end
		elseif opcode == 3 then -- 0b0000011, LOAD
			local rd = Num.getBits(inst, 7, 11)
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
			local imm = Num.getBits(inst, 20, 31)
			local addr = (rs1 + Num.sext(imm, 12)) % (2^32)
			if funct3 == 0 then -- LB
				Registers.write(rd, Num.sext(Memory.read(addr, 1), 8))
			elseif funct3 == 1 then -- LH
				Registers.write(rd, Num.sext(Memory.read(addr, 2), 16))
			elseif funct3 == 2 then -- LW
				Registers.write(rd, Memory.read(addr, 4))
			elseif funct3 == 4 then -- LBU
				Registers.write(rd, Memory.read(addr, 1))
			elseif funct3 == 5 then -- LHU
				Registers.write(rd, Memory.read(addr, 2))
			end
		elseif opcode == 35 then -- 0b0100011, STORE
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)
			local imm = s_type_imm(inst)
			local addr = (rs1 + Num.sext(imm, 12)) % (2^32)
			if funct3 == 0 then -- SB
				Memory.write(addr, Registers.read(rs2), 1)
			elseif funct3 == 1 then -- SH
				Memory.write(addr, Registers.read(rs2), 2)
			elseif funct3 == 2 then -- SW
				Memory.write(addr, Registers.read(rs2), 4)
			end
		elseif opcode == 19 then -- 0b0010011, register-immediate stuff
			local funct3 = Num.getBits(inst, 12, 14)
			local rd = Num.getBits(inst, 7, 11)
			local rs1 = Num.getBits(inst, 15, 19)
			local immediate = Num.getBits(20,31)

			local a = Registers.read(rs1)
			local sa = Num.signed(a, 32)

			if Num.getBits(immediate, 11, 11) == 1 then -- oh fuck off sign bit
				immediate = immediate + 4294965248
			end

			if funct3 == 0 then -- ADDI
				Registers.write(rd, Num.add(Registers.read(rs1), immediate))
			elseif funct3 == 2 then -- SLTI
				Registers.write(rd, (sa < immediate) and 1 or 0)
			elseif funct3 == 3 then -- SLTIU
				Registers.write(rd, (a < immediate) and 1 or 0)
			elseif funct3 == 4 then -- XORI
				Registers.write(rd, Num.bxor(a, immediate))
			elseif funct3 == 6 then -- ORI
				Registers.write(rd, Num.bor(a, immediate))
			elseif funct3 == 7 then -- ANDI
				Registers.write(rd, Num.band(a, immediate))

			elseif funct3 == 1 then -- SLLI
				local shift_amount = Num.getBits(immediate, 0,4)

				Registers.write(rd, Num.lshift(a, shift_amount))
			elseif funct3 == 5 then -- SRLI/SRAI
				local shift_amount = Num.getBits(immediate, 0,4)
				if Num.getBits(inst, 30, 30) == 1 then -- SRAI
					local is_signed = Num.isneg(a)

					local newval = Num.rshift(a, shift_amount)

					if is_signed then
						local tval = 2^shift_amount - 1
						tval = Num.lshift(tval, 32 - shift_amount)

						newval = newval + tval
					end

					Registers.write(rd, newval)
				else -- SRLI
					Registers.write(rd, Num.rshift(a, shift_amount))
				end
			end
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
				-- TODO: division & remainder
				end
			else
				if funct3 == 0 then -- ADD/SUB
					if funct7 == 0 then -- add
						Registers.write(rd, Num.add(Registers.read(rs1), Registers.read(rs2)))
					elseif funct7 == 32 then -- 0b0100000 sub
						Registers.write(rd, Num.sub(Registers.read(rs1), Registers.read(rs2)))
					end
				elseif funct3 == 1 then -- SLL
					-- if funct7 == 0 then -- this if statement is probably never false so like who cares
						Registers.write(rd, Num.lshift(Registers.read(rs1), Registers.read(rs2)))
					-- end
				elseif funct3 == 2 then -- SLT
					local signeda = Num.signed(Registers.read(rs1), 32)
					local signedb = Num.signed(Registers.read(rs2), 32)
					Registers.write(rd, (signeda < signedb) and 1 or 0)
				elseif funct3 == 3 then
					Registers.write(rd, (Registers.read(rs1) < Registers.read(rs2)) and 1 or 0)
				elseif funct3 == 4 then -- XOR
					Registers.write(rd, Num.bxor(Registers.read(rs1), Registers.read(rs2)))
				elseif funct3 == 5 then -- SRL, SRA
					if Num.getBits(inst, 30, 30) == 1 then -- SRA
						local a = Registers.read(rs1)
						local b = Registers.read(rs2)
						local is_signed = Num.isneg(a)

						local newval = Num.rshift(a, b)

						if is_signed then
							local tval = 2^b - 1
							tval = Num.lshift(tval, 32 - b)

							newval = newval + tval
						end

						Registers.write(rd, newval)
					else -- SRL
						Registers.write(rd, Num.rshift(Registers.read(rs1), Registers.read(rs2)))
					end
				elseif funct3 == 6 then -- OR
					Registers.write(rd, Num.bor(Registers.read(rs1), Registers.read(rs2)))
				elseif funct3 == 7 then -- AND
					Registers.write(rd, Num.band(Registers.read(rs1), Registers.read(rs2)))
				end
				-- TODO: the rest
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

	pc = pc + pc_inc_amount
end
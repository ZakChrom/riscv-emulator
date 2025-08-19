require("src.helper")
require("src.uart")
require("src.memory")
require("src.registers")
require("src.csrs")
require("src.trap")

---@param inst integer
---@return integer
local function b_type_imm(inst)
	return Num.lshift(Num.getBits(inst, 31, 31), 12) + Num.lshift(Num.getBits(inst, 7, 7), 11) + Num.lshift(Num.getBits(inst, 25, 30), 5) + (Num.getBits(inst, 8, 11) * 2)
end

---@param inst integer
---@return integer
local function s_type_imm(inst)
	return Num.lshift(Num.getBits(inst, 25, 31), 5) + Num.getBits(inst, 7, 11)
end

Hart = {}
Hart.pc = 0

while true do
	local inst = Memory.read(Hart.pc, 4)
	Hart.pc_inc_amount = 4

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

			Registers.write(rd, imm + Hart.pc)
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

			Registers.write(rd, Hart.pc + 4)

			Hart.pc_inc_amount = imm
		elseif opcode == 103 then -- 0b1100111, JALR
			local rd = Num.getBits(inst, 7, 11)
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
			local imm = Num.getBits(inst, 20, 31)

			if Num.getBits(imm, 11, 11) == 1 then -- sign bit
				imm = imm - 2^12
			end

			local base = Registers.read(rs1)
			local target = base + imm

			target = target - (target % 2) -- the spec tells me to clear this bit so i do (idk why honestly but apparently they wanted it to work that way)

			Registers.write(rd, Hart.pc + 4)
			Hart.pc = target
			Hart.pc_inc_amount = 0
		elseif opcode == 99 then -- 0b1100011, BRANCH
			local funct3 = Num.getBits(inst, 12, 14)

			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)
			local a = Registers.read(rs1)
			local b = Registers.read(rs2)
			local sa = Num.signed(a, 32)
			local sb = Num.signed(b, 32)

			local imm = b_type_imm(inst)
			local inc = Num.signed(imm, 13)
			if funct3 == 0 then -- BEQ
				if a == b then
					Hart.pc_inc_amount = inc
				end
			elseif funct3 == 1 then -- BNE
				if a ~= b then
					Hart.pc_inc_amount = inc
				end
			elseif funct3 == 4 then -- BLT
				if sa < sb then
					Hart.pc_inc_amount = inc
				end
			elseif funct3 == 5 then -- BGE
				if sa > sb then
					Hart.pc_inc_amount = inc
				end
			elseif funct3 == 6 then -- BLTU
				if a < b then
					Hart.pc_inc_amount = inc
				end
			elseif funct3 == 7 then -- BGEU
				if a >= b then
					Hart.pc_inc_amount = inc
				end
			end
		elseif opcode == 3 then -- 0b0000011, LOAD
			local rd = Num.getBits(inst, 7, 11)
			local funct3 = Num.getBits(inst, 12, 14)
			local rs1 = Num.getBits(inst, 15, 19)
			local imm = Num.getBits(inst, 20, 31)
			local addr = (Registers.read(rs1) + Num.sext(imm, 12)) % (2^32)
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
			local addr = (Registers.read(rs1) + Num.sext(imm, 12)) % (2^32)
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
			local immediate = Num.getBits(inst, 20,31)
			local simmediate = immediate

			local a = Registers.read(rs1)
			local sa = Num.signed(a, 32)

			if Num.getBits(immediate, 11, 11) == 1 then -- oh fuck off sign bit
				immediate = immediate + 4294963200
				simmediate = simmediate - 2^12
			end

			if funct3 == 0 then -- ADDI
				Registers.write(rd, Num.add(Registers.read(rs1), immediate))
			elseif funct3 == 2 then -- SLTI
				Registers.write(rd, (sa < simmediate) and 1 or 0)
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
				elseif funct3 == 4 then -- DIV
					-- signed integer division my beloved

					local srs1v, srs2v = Num.signed(rs1v, 32), Num.signed(rs2v, 32) -- get the signed ints for lua

					local val
					if rs1v == 2^31 and rs2v == 2^32 - 1 then -- overflow case: max negative number divided by -1
						val = rs1v
					elseif rs2v == 0 then
						val = 2^32 - 1 -- -1
					else
						val = srs1v / srs2v -- calculate
	
						if val >= 0 then -- round towards 0 (i think that's what the spec wants?)
							val = math.floor(val)
						else
							val = math.ceil(val)
						end
	
						if val < 0 then
							val = val + 2^32
						end
					end

					Registers.write(rd, val)
				elseif funct3 == 5 then -- DIVU
					local val = math.floor(rs1v / rs2v) -- should be precise enough

					if rs2v == 0 then
						val = 2^32 - 1
					end

					Registers.write(rd, val)
				elseif funct3 == 6 then -- REM
					-- signed remainder stab me
					local srs1v, srs2v = Num.signed(rs1v, 32), Num.signed(rs2v, 32)

					local val
					if rs1v == 2^31 and rs2v == 2^32 - 1 then -- overflow case: max negative number divided by -1
						val = 0
					elseif rs2v == 0 then -- division by 0 case
						val = rs1v
					else
						-- since lua disagrees on how modulo works
						-- we gotta do fucked up crap
						local div = srs1v / srs2v -- calculate division result
	
						if div >= 0 then -- round towards 0 (i think that's what the spec wants?)
							div = math.floor(div)
						else
							div = math.ceil(div)
						end

						local r = srs1v - div * srs2v -- kill me: oh yeah also this is uhh... probably not gonna lose precision :shrug: TODO: make sure lol

						if r < 0 then
							r = r + 2^32
						end

						val = r
					end

					Registers.write(rd, val)
				elseif funct3 == 7 then -- REMU
					-- thank god it's unsigned

					local val = rs1v % rs2v -- ngl that should *just* work

					if rs2v == 0 then -- division by 0 case
						val = rs1v
					end

					Registers.write(rd, val)
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
			end
		elseif opcode == 15 then -- 0b0001111, fence
		elseif opcode == 115 then -- 0b1110011 system (ecall, ebreak, Zicsr stuff)
			local funct3 = Num.getBits(inst, 12, 14)
			local rd = Num.getBits(inst, 7, 11)
			local rs1 = Num.getBits(inst, 15, 19)
			local funct12 = Num.getBits(inst, 20, 31)

			if funct3 == 0 then -- ECALL, EBREAK
				if funct12 == 0 then -- ECALL

				elseif funct12 == 1 then -- EBREAK

				end
			elseif funct3 == 1 then -- CSRRW
				if rd ~= 0 then
					local ocsr = CSRs.read(funct12)
					Registers.write(rd, ocsr)
				end
				local newval = Registers.read(rs1)
				CSRs.write(funct12, newval)
			elseif funct3 == 2 then -- CSRRS
				local ocsr = CSRs.read(funct12)
				Registers.write(rd, ocsr)
				if rs1 ~= 0 then
					local modval = Registers.read(rs1)
					CSRs.write(funct12, Num.bor(ocsr, modval))
				end
			elseif funct3 == 3 then -- CSRRC
				local ocsr = CSRs.read(funct12)
				Registers.write(rd, ocsr)
				if rs1 ~= 0 then
					local modval = Registers.read(rs1)
					CSRs.write(funct12, Num.clear(ocsr, modval))
				end
			elseif funct3 == 5 then -- CSRRWI
				local imm = rs1
				if rd ~= 0 then
					local ocsr = CSRs.read(funct12)
					Registers.write(rd, ocsr)
				end
				CSRs.write(funct12, imm)
			elseif funct3 == 6 then -- CSRRSI
				local imm = rs1
				local ocsr = CSRs.read(funct12)
				Registers.write(rd, ocsr)
				if imm ~= 0 then
					CSRs.write(funct12, Num.bor(ocsr, imm))
				end
			elseif funct3 == 7 then -- CSRRCI
				local imm = rs1
				local ocsr = CSRs.read(funct12)
				Registers.write(rd, ocsr)
				if imm ~= 0 then
					CSRs.write(funct12, Num.clear(ocsr, imm))
				end
			end
		elseif opcode == 47 then -- 0b0101111, AMO
			local rd = Num.getBits(inst, 7, 11)
			local rs1 = Num.getBits(inst, 15, 19)
			local rs2 = Num.getBits(inst, 20, 24)
			local funct3 = Num.getBits(inst, 12, 14)
			local funct5 = Num.getBits(inst, 27, 31)

			local rl = Num.getBits(inst, 25,25)
			local aq = Num.getBits(inst, 26,26)

			if funct5 == 2 then -- LR.W
				local data = Memory.read(Registers.read(rs1), 4)

				Registers.write(rd, data)
			elseif funct5 == 3 then -- SC.W
				local addr = Registers.read(rs1)
				local data = Registers.read(rs2)

				Memory.write(addr, data, 4)

				Registers.write(rd, 0)
			elseif funct5 == 1 then -- AMOSWAP.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				Memory.write(addr, rs2v, 4)

				Registers.write(rd, data)
			elseif funct5 == 0 then -- AMOADD.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				Memory.write(addr, Num.add(data, rs2v), 4)

				Registers.write(rd, data)
			elseif funct5 == 4 then -- AMOXOR.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				Memory.write(addr, Num.bxor(data, rs2v), 4)

				Registers.write(rd, data)
			elseif funct5 == 12 then -- AMOAND.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				Memory.write(addr, Num.band(data, rs2v), 4)

				Registers.write(rd, data)
			elseif funct5 == 8 then -- AMOOR.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				Memory.write(addr, Num.bor(data, rs2v), 4)

				Registers.write(rd, data)
			elseif funct5 == 16 then -- AMOMIN.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				if Num.signed(data, 32) < Num.signed(rs2v, 32) then
					Memory.write(addr, data, 4)
				else
					Memory.write(addr, rs2v, 4)
				end

				Registers.write(rd, data)
			elseif funct5 == 20 then -- AMOMAX.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				if Num.signed(data, 32) > Num.signed(rs2v, 32) then
					Memory.write(addr, data, 4)
				else
					Memory.write(addr, rs2v, 4)
				end

				Registers.write(rd, data)
			elseif funct5 == 24 then -- AMOMINU.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				if data < rs2v then
					Memory.write(addr, data, 4)
				else
					Memory.write(addr, rs2v, 4)
				end

				Registers.write(rd, data)
			elseif funct5 == 28 then -- AMOMAXU.W
				local addr = Registers.read(rs1)
				local data = Memory.read(addr, 4)
				local rs2v = Registers.read(rs2)

				if data > rs2v then
					Memory.write(addr, data, 4)
				else
					Memory.write(addr, rs2v, 4)
				end

				Registers.write(rd, data)
			end
		end
	else
		print("illegal instruction at " .. tostring(Hart.pc))
		Trap.raise(2, 0)
	end

	Hart.pc = Hart.pc + Hart.pc_inc_amount
end
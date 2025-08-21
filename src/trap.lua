Trap = {}

function Trap.raise(trap, value)
	assert(CSRs.write(0x342, trap)); -- mcause
	assert(CSRs.write(0x343, value)); -- mtval
	assert(CSRs.write(0x341, Hart.pc)) -- mepc

	local mstatus = assert(CSRs.read(0x300))
	local mie = Num.getBits(mstatus, 3, 3)
	assert(CSRs.write(0x300, Num.clear(mstatus, 6272) + (mie * 128) + (Hart.mode * 2048)))
	Hart.mode = Mode.Machine

	local mtvec = assert(CSRs.read(0x305))
	local base = Num.clear(mtvec, 3)
	local mode = Num.getBits(mtvec, 0, 1)
	assert(mode == 0 or mode == 1)
	if mode == 1 then
		Hart.pc = base + (4 * Num.getBits(trap, 0, 30))
	else
		Hart.pc = base
	end
	Hart.pc_inc_amount = 0
end
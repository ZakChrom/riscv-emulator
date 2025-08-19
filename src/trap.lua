Trap = {}

function Trap.raise(trap, value)
	assert(CSRs.write(0x342, trap)); -- mcause
	assert(CSRs.write(0x343, value)); -- mtval
	assert(CSRs.write(0x341, Hart.pc)) -- mepc
	Hart.pc = Num.clear(assert(CSRs.read(0x305)), 3) -- mtvec
	Hart.pc_inc_amount = 0
end
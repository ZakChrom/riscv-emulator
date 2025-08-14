require("src.helper")
require("src.memory")

local pc = 0

while true do
	local inst = Memory.read(pc, 4)
	pc = pc + 1
end
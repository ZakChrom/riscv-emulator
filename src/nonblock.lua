local has_ffi, ffi = pcall(require, 'ffi')

local stdin_waiting

if has_ffi then
	ffi.cdef[[
		typedef struct {
			long tv_sec;
			long tv_usec;
		} timeval;

		typedef struct {
			uint64_t fds_bits[16];
		} fd_set;

		int select(int nfds, fd_set *readfds, void *writefds, void *exceptfds, timeval *timeout);

		typedef uint32_t tcflag_t;
		typedef struct {
			tcflag_t c_iflag;
			tcflag_t c_oflag;
			tcflag_t c_cflag;
			tcflag_t c_lflag;
			char c_line;
			unsigned char c_cc[32];
			int c_ispeed;
			int c_ospeed;
		} termios;

		int tcgetattr(int fd, termios *termios_p);
		int tcsetattr(int fd, int optional_actions, const termios *termios_p);
		int fcntl(int fd, int cmd, ...);

		enum {
			TCSANOW = 0,
			ICANON = 0000002,
			ECHO = 0000010,
			F_GETFL = 3,
			F_SETFL = 4,
			O_NONBLOCK = 04000
		};
	]]

	-- Macros
	local function FD_ZERO(set)
		for i = 0, 15 do set.fds_bits[i] = 0 end
	end

	local function FD_SET(fd, set)
		local index = math.floor(fd / 64)
		local mask = bit.lshift(1, fd % 64)
		set.fds_bits[index] = bit.bor(set.fds_bits[index], mask)
	end

	local function set_stdin_noncanonical()
		local termios = ffi.new("termios")
		ffi.C.tcgetattr(0, termios)
		termios.c_lflag = bit.band(termios.c_lflag, bit.bnot(ffi.C.ICANON))
		termios.c_lflag = bit.band(termios.c_lflag, bit.bnot(ffi.C.ECHO))
		termios.c_cc[6] = 1  -- VMIN = 1
		termios.c_cc[5] = 0  -- VTIME = 0
		ffi.C.tcsetattr(0, ffi.C.TCSANOW, termios)

		local flags = ffi.C.fcntl(0, ffi.C.F_GETFL, 0)
		ffi.C.fcntl(0, ffi.C.F_SETFL, bit.bor(flags, ffi.C.O_NONBLOCK))
	end

	function stdin_waiting(timeout_sec)
		local readfds = ffi.new("fd_set")
		FD_ZERO(readfds)
		FD_SET(0, readfds)  -- 0 = stdin

		local timeout = ffi.new("timeval")
		timeout.tv_sec = timeout_sec or 0
		timeout.tv_usec = 0

		local result = ffi.C.select(1, readfds, nil, nil, timeout)
		return result > 0
	end

	set_stdin_noncanonical()
else
	local has_posix, posix = pcall(require, 'posix')
	if has_posix then -- i love comparing strings
		local termio = require("posix.termio")
		local fcntl = require("posix.fcntl")

		local bit_or, bit_not, bit_and
		if bit32 then
			bit_or, bit_not, bit_and = bit32.bor, bit32.bnot, bit32.band
		elseif bit then
			bit_or, bit_not, bit_and = bit.bor, bit.bnot, bit.band
		elseif _VERSION >= "Lua 5.3" then
			bit_or, bit_not, bit_and = load("return function(a,b) return a|b end")(), load("return function(a) return ~a end")(), load("return function(a,b) return a&b end")()
		end

		local function set_stdin_raw()
			local raw = termio.tcgetattr(0)
			raw.lflag = bit_and(raw.lflag, bit_not(bit_or(termio.ICANON, termio.ECHO)))
			raw.cc[termio.VMIN] = 1
			raw.cc[termio.VTIME] = 0
			termio.tcsetattr(0, termio.TCSANOW, raw)

			local flags = fcntl.fcntl(0, fcntl.F_GETFL, 0)
			fcntl.fcntl(0, fcntl.F_SETFL, bit_or(flags, fcntl.O_NONBLOCK))
		end

		function stdin_waiting(timeout_sec)
			timeout_sec = timeout_sec or 0
			local pollfds = {{fd = 0, events = {IN = true}}}
			local result = posix.poll(pollfds, timeout_sec * 1000)
			return result and pollfds[1].revents and pollfds[1].revents.IN
		end

		set_stdin_raw()
	else
		-- give up: no input :(

		-- io.stdin:setvbuf('no')
		-- function stdin_waiting() -- must use blocking, just always assume there's something... i guess
		-- 	return true
		-- end

		-- local on_posix = package.config:sub(1,1) == "/"

		-- if on_posix then
		-- 	-- at least disable echo
		-- 	os.execute("stty -icanon -echo min 1 time 0")
		-- end

		stdin_waiting = false;
	end
end

return stdin_waiting
--This is a new bios.lua--
--Basically:--
--[[
	Check for the os.lst file on the harddrive
	If it exists, select the os as the one currently located in os.lst
	Else, load CraftOS from /rom/craftos.bin
]]--
--Safe Version as depicted in the original bios.lua (now craftos.bin)--
function pairs( _t )
	local typeT = type( _t )
	if typeT ~= "table" then
		error( "bad argument #1 to pairs (table expected, got "..typeT..")", 2 )
	end
	return next, _t, nil
end

function ipairs( _t )
	local typeT = type( _t )
	if typeT ~= "table" then
		error( "bad argument #1 to ipairs (table expected, got "..typeT..")", 2 )
	end
	return function( t, var )
		var = var + 1
		local value = t[var] 
		if value == nil then
			return
		end
		return var, value
	end, _t, 0
end

function coroutine.wrap( _fn )
	local typeT = type( _fn )
	if typeT ~= "function" then
		error( "bad argument #1 to coroutine.wrap (function expected, got "..typeT..")", 2 )
	end
	local co = coroutine.create( _fn )
	return function( ... )
		local tResults = { coroutine.resume( co, ... ) }
		if tResults[1] then
			return unpack( tResults, 2 )
		else
			error( tResults[2], 2 )
		end
	end
end

function string.gmatch( _s, _pattern )
	local type1 = type( _s )
	if type1 ~= "string" then
		error( "bad argument #1 to string.gmatch (string expected, got "..type1..")", 2 )
	end
	local type2 = type( _pattern )
	if type2 ~= "string" then
		error( "bad argument #2 to string.gmatch (string expected, got "..type2..")", 2 )
	end
	
	local nPos = 1
	return function()
		local nFirst, nLast = string.find( _s, _pattern, nPos )
		if nFirst == nil then
			return
		end		
		nPos = nLast + 1
		return string.match( _s, _pattern, nFirst )
	end
end

local nativesetmetatable = setmetatable
function setmetatable( _o, _t )
	if _t and type(_t) == "table" then
		local idx = rawget( _t, "__index" )
		if idx and type( idx ) == "table" then
			rawset( _t, "__index", function( t, k ) return idx[k] end )
		end
		local newidx = rawget( _t, "__newindex" )
		if newidx and type( newidx ) == "table" then
			rawset( _t, "__newindex", function( t, k, v ) newidx[k] = v end )
		end
	end
	return nativesetmetatable( _o, _t )
end

local ta = 1

local cos = {}
cos.name = "CraftOS"
cos.bin = "/rom/craftos.bin"
cos.alt = false

if fs.exists("os.lst") then
	local fh = fs.open("os.lst","r")
	cos.name = fh.readLine() or cos.name
	cos.bin = fh.readLine() or cos.bin
	cos.alt = cos.bin ~= "/rom/craftos.bin"
	fh.close()
end

local function write(s)
	term.setCursorPos(1,ta)
	term.write(s)
	ta = ta+1
end

if cos.alt then
	write("Found alternative OS - "..cos.name)
	write("Press space to abort loading "..cos.name)
	local tim = os.startTimer(2)
	local abort = false
	while true do
		local e, p1 = coroutine.yield()
		if e == "timer" then
			if p1 == tim then
				break
			end
		elseif e == "key" then
			if p1 == 57 then
				abort = true
				coroutine.yield("char")
				write("Aborting loading of "..cos.name..", loading CraftOS")
				break
			end
		end
	end
	if not fs.exists(cos.bin) and not abort then
		write(cos.name.." bootloader does not exist! Aborting!")
		abort = true
	end
	if abort then
		cos.name = "CraftOS"
		cos.bin = "/rom/craftos.bin"
		cos.alt = false
	end
end

write("Loading "..cos.name)
write("Loading bootloader")
local fh = fs.open(cos.bin,"r")
local c = fh.readAll()
fh.close()
local func, err = loadstring(c)
if not func then
	write(cos.name.." bootloader syntax error!")
	write(err)
	coroutine.yield("Random Event FTW")
else
	term.clear()
	term.setCursorPos(1,1)
	local s, err = pcall(func)
	if not s then
		term.clear()
		term.setCursorPos(1,1)
		term.write(err)
		coroutine.yield("Random Event FTW")
	end
end
os.shutdown()

local skynet    = require "skynet"
local skymgr	= require "skynet.manager"
local socket 	= require "skynet.socket"

--gate服务句柄
local gate
--命令处理
local CMD = {}
--客户端连接处理
local SOCKET = {}
--fd到agent的映射
local agents = {}
--聊天室 有个default作为默认聊天室
local rooms = {}
rooms["dft"] = {}

function print_table(t)
	for k, v in pairs(t) do
		skynet.error(k, v)
	end
end

--command处理
function CMD.broadcast(room, msg)
	for fd, _ in pairs(rooms[room]) do
		skynet.error('send to room', room, fd, rooms[room][fd])
		send_package(fd, msg)
	end
end

function CMD.room(fd, old_room, new_room)
	skynet.error(old_room, new_room)
	if rooms[old_room] ~= nil then
		skynet.error('delete old room ', old_room, fd)
		rooms[old_room][fd] = nil
		skynet.error('after delete...', old_room, rooms[old_room][fd])
		print_table(rooms[old_room])
		skynet.error('room fd', rooms[old_room][fd])
		print_table(rooms)
		for fdd, _ in pairs(rooms[old_room]) do
			skynet.error('send to room', old_room, fdd, rooms[old_room][fdd])
			send_package(fdd, "test msg")
		end
		print_table(rooms[old_room])
		print_table(rooms)
		CMD.broadcast(old_room, "test msg2")
	end
	if rooms[new_room] == nil then
		rooms[new_room] = {}
	end
	rooms[new_room][fd] = 1
end

--socket事件处理
function SOCKET.open(fd, addr)
	skynet.call(gate, "lua", "accept", fd)
	chatagent = skynet.newservice('agent', fd, "dft")
	agents[fd] = chatagent
	rooms["dft"][fd] = 1
	skynet.call(gate, "lua", "forward", fd, 0, chatagent)
	skynet.error("client"..fd, "connected: ", addr)
end

function SOCKET.close(fd)
	skynet.error("client"..fd, "disconnected")
	skynet.kill(agents[fd])
	agents[fd] = nil
	for room, val in pairs(rooms) do
		val[fd] = nil
	end
end

function SOCKET.error(fd, msg)
	skynet.error("client"..fd, "disconnected: ", msg)
	skynet.kill(agents[fd])
	agents[fd] = nil
end

function SOCKET.data(fd, msg)
	-- should never call this...
	skynet.error("client"..fd, "says: ", msg)
	socket.write(fd, msg)
end

function send_package(fd, msg)
	data = string.pack(">s2", msg)
	skynet.error("send_package", msg, data)
	socket.write(fd, data)
end

--服务入口
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			if f then
				f(...)
			else
				skynet.error("unknown socket command: ", subcmd)
			end
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.error('...', ...)
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	--启动gate服务
	gate = assert(skymgr.uniqueservice("gate"))
	skynet.call(gate, "lua", "open",{
	    address = skynet.getenv("app_server_ip"), 	-- 监听地址
	    port 	= skynet.getenv("app_server_port"), -- 监听端口
	    maxclient = 1024,   -- 最多允许 1024 个外部连接同时建立
	    nodelay = true,     -- 给外部连接设置  TCP_NODELAY 属性
	})
end)

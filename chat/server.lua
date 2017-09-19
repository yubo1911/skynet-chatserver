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

--command处理
function CMD.broadcast(msg)
	send_package(msg)
end

--socket事件处理
function SOCKET.open(fd, addr)
	skynet.call(gate, "lua", "accept", fd)
	chatagent = skynet.newservice('agent')
	agents[fd] = chatagent
	skynet.call(gate, "lua", "forward", fd, 0, chatagent)
	skynet.error("client"..fd, "connected: ", addr)
end

function SOCKET.close(fd)
	skynet.error("client"..fd, "disconnected")
	skynet.kill(agents[fd])
	agents[fd] = nil
end

function SOCKET.error(fd, msg)
	skynet.error("client"..fd, "disconnected: ", msg)
	skynet.kill(agents[fd])
	agents[fd] = nil
end

function SOCKET.data(fd, msg)
	skynet.error("client"..fd, "says: ", msg)
	socket.write(fd, msg)
end

function send_package(msg)
	data = string.pack(">s2", msg)
	for fd, _ in pairs(agents) do
		socket.write(fd, data)
	end
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

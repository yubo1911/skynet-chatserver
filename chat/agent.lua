local skynet = require "skynet"

local CMD = {}
local LUA_CMD = {}

local CONF = {}

function CMD.name(new_name)
	CONF.client_name = new_name
end

function CMD.room(new_room)
	local old_room = CONF.cur_room
	skynet.call('.server', 'lua', 'room', CONF.fd, old_room, new_room) 
	CONF.cur_room = new_room
end

function CMD.busy(t)
	t = tonumber(t)
	cur_time = os.time()
	skynet.error(CONF.client_name, 'in busy loop')
	while true do
		if os.time() - cur_time > t then
			break
		end
	end
	skynet.error(CONF.client_name, 'out busy loop')
end

function process_cmd(content)
	pattern = "(%w+)=(%w+)"
	for k, v in string.gmatch(content, pattern) do
		local f = CMD[k]
		if f ~= nil then
			f(v)
		end
	end
end

function process_data(data)
	prefix = string.sub(data, 1, 2)
	content = string.sub(data, 3)
	if prefix == 'd:' then
		content = 'client ['..CONF.client_name..'] says: '..content
		skynet.call('.server', 'lua', 'broadcast', CONF.cur_room, content) 
	else
		if prefix == 'c:' then
			process_cmd(content)
		end
	end
end

function LUA_CMD.init(conf)
	CONF.fd = conf.fd
	CONF.cur_room = conf.cur_room
	CONF.client_name = conf.client_name
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return skynet.tostring(msg, sz)
	end,
	dispatch = function (_, _, data, ...)
        process_data(data)
	end
}
--服务入口
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(LUA_CMD[cmd])
		skynet.ret(skynet.pack(f(...)))
	end)
end)

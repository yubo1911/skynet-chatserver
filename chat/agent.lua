local skynet = require "skynet"

local CMD = {}

local fd, cur_room = ...
local client_name = fd

function CMD.name(new_name)
	client_name = new_name
end

function CMD.room(new_room)
	local old_room = cur_room
	skynet.call('.server', 'lua', 'room', fd, old_room, new_room) 
	cur_room = new_room
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
		content = 'client ['..client_name..'] says: '..content
		skynet.call('.server', 'lua', 'broadcast', cur_room, content) 
	else
		if prefix == 'c:' then
			process_cmd(content)
		end
	end
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
	--skynet.call('.server', 'lua', 'room', fd, "None", cur_room) 
end)

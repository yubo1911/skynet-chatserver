local skynet = require "skynet"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return skynet.tostring(msg, sz)
	end,
	dispatch = function (_, _, data, ...)
		skynet.error("client msg", data, ...)
		skynet.call('.server', 'lua', 'broadcast', data) 
	end
}
--服务入口
skynet.start(function()
end)

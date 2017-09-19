local skynet    = require "skynet"
local skymgr    = require "skynet.manager"
local snax      = require "skynet.snax"

skynet.start(function()
    --初始化随机数
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
    
    --启动console服务，并命名为 .console
    skymgr.name(".server", skynet.newservice("server"))

    --启动好了，没事做就退出
    skynet.exit()
end)

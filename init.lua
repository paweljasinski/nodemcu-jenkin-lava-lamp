function setupWifi()
    print("Setting up wifi ")
    wifi.setmode(wifi.STATION)
    station_cfg = {}
    station_cfg.ssid = AP_SSID
    station_cfg.pwd = AP_PASSWORD
    wifi.sta.config(station_cfg)
    local verify_timer = tmr.create()
    verify_timer:alarm(1000, tmr.ALARM_AUTO, function(timer)
        if (wifi.sta.getip() == nil) then
            print(".")
        else
            print("IP: "..wifi.sta.getip())
            timer:unregister()
            sntp.sync(nil,
                function(sec, usec, server, info)
                    print('sync', sec, usec, server)
                end,
                function()
                    print('time sync failed')
                end)
        end
    end)
end

dofile("config.lua")
setupWifi()
dofile("lava.lua")

function configure_output()
    gpio.mode(1, gpio.OUTPUT) -- green
    gpio.write(1, gpio.HIGH)  -- low active
    gpio.mode(2, gpio.OUTPUT) -- red
    gpio.write(2, gpio.HIGH)  -- low active
    gpio.mode(5, gpio.OUTPUT) -- buzzer
    gpio.write(5, gpio.LOW)   -- high active
    gpio.mode(4, gpio.OUTPUT) -- on board led
    gpio.write(4, gpio.HIGH)  -- low active
end

function blink()
    local blink_timer = tmr.create()
    gpio.write(4, 0)
    blink_timer:alarm(25, tmr.ALARM_SINGLE, function()
        gpio.write(4, 1)
    end)
end

function start()
    start_timer = tmr.create()
    start_timer:alarm(3000, tmr.ALARM_SINGLE, function(timer)
        -- have a chance to nuke init.lua
        dofile("lava.lua")
    end)
end

function setupWifi()
    print("Setting up wifi ")
    wifi.setmode(wifi.STATION)
    station_cfg = {}
    station_cfg.ssid = AP_SSID
    station_cfg.pwd = AP_PASSWORD
    wifi.sta.config(station_cfg)
    local verify_timer = tmr.create()
    verify_timer:alarm(3000, tmr.ALARM_AUTO, function(timer)
        if (wifi.sta.getip() == nil) then
            blink()
        else
            print("IP: "..wifi.sta.getip())
            timer:unregister()
            sntp.sync(nil, start, start)
        end
    end)
end

dofile("config.lua")
configure_output()
setupWifi()

function is_daylight_saving(dtm)
    if dtm["mon"] < 3 or dtm["mon"] > 10 then
        return false
    end
    if dtm["mon"] > 3 and dtm["mon"] < 10 then
        return true
    end
    local wdayNew
    if tm["wday"] == 1 then
        wdayNew = 7
    else
        wdayNew = dtm["wday"] - 1
    end
    local previousSunday = dtm["day"] - wdayNew
    if dtm["mon"] == 3 then
        return previousSunday >= 25
    end
    if dtm["mon"] == 10 then
        return previousSunday < 25
    end
end

function is_office_time()
    -- uncomment to debug after hours
    -- do return true end
    if rtctime.get() == 0 then return true end -- no time available
    local utc = rtctime.epoch2cal(rtctime.get())
    local delta = is_daylight_saving(utc) and 7200 or 3600
    local cet = rtctime.epoch2cal(rtctime.get() + delta)
    print(string.format("%04d/%02d/%02d %02d:%02d:%02d %02d",
                        cet["year"], cet["mon"], cet["day"], cet["hour"], cet["min"], cet["sec"], cet["wday"]))
    return cet["wday"] ~= 1
       and cet["wday"] ~= 7
       and cet["hour"] > 7
       and cet["hour"] < 20
end

output_color = "green"
build_color = "green"

function update_output()
    if output_color ~= build_color then
        -- something changed
        beep(100)
    end
    shine(build_color)
    output_color = build_color
end

http_error_count = 0

function handle_error()
    http_error_count = http_error_count + 1
    if (http_error_count > 30) then
        build_color = "both"
    end
end

-- avoid calling get more then once
pending_get = false

function str_starts_with(str, start)
   return string.sub(str, 1, string.len(start)) == start
end

function process_http_response(code, data)
    pending_get = false
    gpio.write(4, 1) -- off once we have feedback
    if code < 0 then
        print("HTTP request failed with internal error: "..code)
        handle_error()
    elseif code == 200 then
        http_error_count = 0
        result = sjson.decode(data)
        build_color = "green"
        for k, job in pairs(result["jobs"]) do
            -- blue and blue_anime are good colors
            if (not str_starts_with(job["color"], "blue")) and job["color"] ~= "disabled" then
                build_color = "red"
                break
            end
        end
    else
        print("unexpected HTTP status code: "..code)
        handle_error()
    end
    update_output()
end

function main_loop()
    if not is_office_time() then
        shine("off")
        return
    end
    if pending_get then
        return
    end
    pending_get = true
    gpio.write(4, 0) -- led on once request scheduled
    http.get(API_URL, nil, process_http_response)
end


function shine(color)
    print("shine: "..color)
    if color == "green" then
        gpio.write(1, gpio.LOW)
        gpio.write(2, gpio.HIGH)
    elseif color == "red" then
        gpio.write(1, gpio.HIGH)
        gpio.write(2, gpio.LOW)
    elseif color == "both" then
        gpio.write(1, gpio.LOW)
        gpio.write(2, gpio.LOW)
    else
        gpio.write(1, gpio.HIGH)
        gpio.write(2, gpio.HIGH)
    end
end

function beep(length)
    gpio.write(5, gpio.HIGH)
    t = tmr.create()
    t:alarm(length, tmr.ALARM_SINGLE, function()
        gpio.write(5, gpio.LOW)
    end)
end

function blinker_on(count)
    if count == 0 then return end
    gpio.write(4, 0)
    one_shot = tmr.create()
    one_shot:alarm(25, tmr.ALARM_SINGLE, function()
        blinker_off(count)
    end)
end

function blinker_off(count)
    gpio.write(4, 1)
    one_shot = tmr.create()
    one_shot:alarm(100, tmr.ALARM_SINGLE, function()
        blinker_on(count-1)
    end)
end

sjson = require "sjson"
main_timer = tmr.create()
main_loop()
-- this time should be more than 10s (10000) which is http timeout
main_timer:alarm(15000, tmr.ALARM_AUTO, function()
    main_loop()
end)


function configure_output()
    gpio.mode(1, gpio.OUTPUT)
    gpio.mode(2, gpio.OUTPUT)
    gpio.mode(5, gpio.OUTPUT)
    gpio.write(1, gpio.HIGH)
    gpio.write(2, gpio.HIGH)
    gpio.write(5, gpio.LOW)
end

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
    --do return true end
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

function process_http_response(code, data)
    pending_get = false
    if code < 0 then
        print("HTTP request failed with internal error: "..code)
        handle_error()
    elseif code == 200 then
        http_error_count = 0
        result = sjson.decode(data)
        build_color = "green"
        for k, job in pairs(result["jobs"]) do
            if (job["color"] ~= "blue" and job["color"] ~= "disabled") then
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

configure_output()
sjson = require "sjson"
main_timer = tmr.create()
-- this time should be more than 10s (10000) which is http timeout
main_timer:alarm(15000, tmr.ALARM_AUTO, function()
    main_loop()
end)


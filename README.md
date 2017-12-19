# nodemcu-jenkins-lava-lamp
Lua scripts to let esp8266 controller display jenkins status using 2 lava lamps.

What you need:
- esp8266 controller, with 4MB flash (e.g. wemos D1 mini, or lolin v3)
- relay breakout board (TODO: link item from ali, add schematic)
- 2 lava lamps
- power cables, patch cables
- usb power supplier
- buzzer
- env to flash esp/upload code to esp (pc)
It is also assumed, there is jenkins server and wifi which allows access to the server and
internet connection to sync clock (it may work with local ntp server).

Wiring:
- D0 - green (low is active)
- D1 - red   (low is active)
- D5 - buzzer (high is active)

What needs to be configured in config.lue:
- access point name and key
- url of the jenkins view containg projects to be watched
Note: version 2.1.0 together with 2.98.2 (Jetty 9.4.z-SNAPSHOT) has trouble with
hostnames (request header is not valid). Entering ip address makes it happy.

What is hardcoded:
- device is only active during business hours (7am-8pm), timezone is CET
- pooling interval is 15s.
- green lamp is on if all project in jenkins view are green (blue) or inactive
- red lamp is on when any project has status red or yellow
- when lamps are switched on/off, there is a beep
- after 30 failed communication attempts, both lamps will be active

esp8266 has to be flased with nodemcu firmware version 2.1.0.

enabled modules: encoder,file,gpio,http,net,node,rtctime,sjson,sntp,tmr,uart,wifi

What happens on boot:
1. wifi is up, ip is obtained
2. time is synchronized using ntp
3. pool and display forever

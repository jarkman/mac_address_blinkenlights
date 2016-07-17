-- docs:  https://nodemcu.readthedocs.io/en/dev/en/modules/ws2812/

-- ws2812 is a library to handle ws2812-like led strips. It works at least on WS2812, WS2812b, APA104, SK6812 (RGB or RGBW).

-- The library uses UART1 routed on GPIO2 (Pin D4 on NodeMCU DEVKIT) to generate the bitstream.

-- I'm using three strings of 49 leds

-- globals. Ugh.

m_red = 0
m_green = 0
m_blue = 0

red_v = 0
green_v = 0
blue_v = 0

direction = 1

function fade_leds()
    if direction == 1 then
        red_v = red_v + 25
        if (m_red - red_v) < 25 then
            red_v = 0
        end
        green_v = green_v + 25
        if (m_green - green_v) < 25 then
            green_v = 0
        end  
        blue_v = blue_v + 25
        if (m_blue - blue_v) < 25 then
            blue_v = 0
        end
    end

    if direction == -1 then
        red_v = red_v - 25
        if (red_v - m_red) < 25 then
            red_v = 1023
        end
        green_v = green_v - 25
        if (green_v - m_green) < 25 then
            green_v = 1023
        end  
        blue_v = blue_v - 25
        if (blue_v - m_blue) < 25 then
            blue_v = 1023
        end
    end

    led_s1(red_v,green_v,blue_v)
end
    
    


function led_s1(r,g,b)
    -- print("r:"..r.." g:"..g.." b:"..b)
    -- print("Mr:"..m_red.." Mg:"..m_green.." Mb:"..m_blue)
    pwm.setduty(1,r)
    pwm.setduty(2,g)
    pwm.setduty(3,b)
end


function main()
    print('in main')
    i=0
    probes={}  -- array of recent MAC addresses
    bestMac="00:00:00:00:00:00" -- MAC we're currently showing

    pwm.setup(1,1000,1023);
    pwm.start(1);
    pwm.setup(2,1000,1023);
    pwm.start(2);
    pwm.setup(3,1000,1023);
    pwm.start(3);
           
    wifi.setmode(wifi.SOFTAP)
    cfg={}
    cfg.ssid="mac_address_blinkenlights" 
    cfg.pwd="the_ESP8266_WIFI_password" 
    wifi.ap.config(cfg) 
    
    tmr.alarm(2,50,tmr.ALARM_AUTO,function()
        fade_leds()
    end)
    
    wifi.eventmon.register(wifi.eventmon.AP_PROBEREQRECVED, function(T) 
        handleProbe(T.MAC)
    end)
end

function handleProbe(mac)  -- if this never gets called, reboot your ESP
    -- print("\nProbe from "..mac)
    now=tmr.now()/1000000 -- convert uS to S
    newMac=false
    
    if(probes[mac]==nil) then
        print("\nNew probe from "..mac)
        probes[mac]={}
        probes[mac].frame=0 
        probes[mac].time=0
        newMac=true       
    else
       age=now-probes[mac].time
       if age>5 then                -- many clients probe several times in a row, ignore repeats
        print("\nOld Probe from "..mac.." age : "..age)
        newMac=true
       end 
    end
    
    if newMac then 
        -- showFrame(probes[mac].frame)  
        print("bestMac: " .. mac )

        rnd = math.random(2)
        -- print("rnd:".. rnd)

        if (rnd ==1) then
            direction = 1
        else
            direction = -1
        end
        
        bestMac=mac
        makeMacPixels() 
        probes[mac].time=now
        probes[mac].frame=probes[mac].frame+1  
    end
end


function makeMacPixels() -- make up 8 pixels form a mac

    rgbs=split(bestMac,"\:")
    
    m_red = tonumber(rgbs[3],16)*4
    m_green = tonumber(rgbs[4],16)*4
    m_blue = tonumber(rgbs[5],16)*4

    if direction == 1 then
        led_s1(0,0,0)
    else
        led_s1(1023,1023,1023)
    end
end

function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

print("\ncalling main()\n");
main()
print("\ncalled main()\n");



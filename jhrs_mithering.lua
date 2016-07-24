-- MAC-responsive driver for RGB LED strip for EMF2016
-- Specifically, digit 6 in the sign.

-- globals. Ugh.

m1_red = 0
m1_green = 0
m1_blue = 0

red_v1 = 0
green_v1 = 0
blue_v1 = 0

m2_red = 0
m2_green = 0
m2_blue = 0

red_v2 = 0
green_v2 = 0
blue_v2 = 0

direction = 1

function fade_leds1()
    if direction == 1 then
        red_v1 = red_v1 + 25
        if (m1_red - red_v1) < 25 then
            red_v1 = 0
        end
        green_v1 = green_v1 + 25
        if (m1_green - green_v1) < 25 then
            green_v1 = 0
        end  
        blue_v1 = blue_v1 + 25
        if (m1_blue - blue_v1) < 25 then
            blue_v1 = 0
        end
    end

    if direction == -1 then
        red_v1 = red_v1 - 25
        if (red_v1 - m1_red) < 25 then
            red_v1 = 1023
        end
        green_v1 = green_v1 - 25
        if (green_v1 - m1_green) < 25 then
            green_v1 = 1023
        end  
        blue_v1 = blue_v1 - 25
        if (blue_v1 - m1_blue) < 25 then
            blue_v1 = 1023
        end
    end

    led_s1(red_v1,green_v1,blue_v1)
end

function fade_leds2()
    if direction == 1 then
        red_v2 = red_v2 + 25
        if (m2_red - red_v2) < 25 then
            red_v2 = 0
        end
        green_v2 = green_v2 + 25
        if (m2_green - green_v2) < 25 then
            green_v2 = 0
        end  
        blue_v2 = blue_v2 + 25
        if (m2_blue - blue_v2) < 25 then
            blue_v2 = 0
        end
    end

    if direction == -1 then
        red_v2 = red_v2 - 25
        if (red_v2 - m2_red) < 25 then
            red_v2 = 1023
        end
        green_v2 = green_v2 - 25
        if (green_v2 - m2_green) < 25 then
            green_v2 = 1023
        end  
        blue_v2 = blue_v2 - 25
        if (blue_v2 - m2_blue) < 25 then
            blue_v2 = 1023
        end
    end

    led_s2(red_v2,green_v2,blue_v2)
end
    
function led_s1(r,g,b) 
    -- print("1 - r:"..r.." g:"..g.." b:"..b)
    -- print("Mr:"..m_red.." Mg:"..m_green.." Mb:"..m_blue)
    pwm.setduty(1,g)
    pwm.setduty(2,r)
    pwm.setduty(3,b)
    -- print("1 done");
end

function led_s2(r,g,b)
    -- print("2 - r:"..r.." g:"..g.." b:"..b)
    -- print("Mr:"..m_red.." Mg:"..m_green.." Mb:"..m_blue)
    pwm.setduty(5,g)
    pwm.setduty(6,r)
    pwm.setduty(7,b)
    -- print("2 done");
end


function main()
    print('in main')
    i=0
    probes={}  -- array of recent MAC addresses
    bestMac="00:00:00:00:00:00" -- MAC we're currently showing

    pwmFrequency = 100 -- Hz
    
    pwm.setup(1,100,1023);
    pwm.start(1);
    pwm.setup(2,100,1023);
    pwm.start(2);
    pwm.setup(3,100,1023);
    pwm.start(3);

    pwm.setup(5,100,1023);
    pwm.start(5);
    pwm.setup(6,100,1023);
    pwm.start(6);
    pwm.setup(7,100,1023);
    pwm.start(7);
    
    wifi.setmode(wifi.SOFTAP)
    cfg={}
    cfg.ssid="the_6_shows_your_MAC" 
    cfg.pwd="the_ESP8266_WIFI_password" 
    wifi.ap.config(cfg) 

    startSelftest()

end

selftestState = 0

function nextSelftest()

    print("\nSelftest "..selftestState)
    
    if selftestState == 0 then 
         led_s1(128,128,128)
        led_s2(128,128,128)
    elseif selftestState == 1 then
        led_s1(512,512,512)
        led_s2(512,512,512)
    elseif selftestState == 2 then
       led_s1(1023,1023,1023)
        led_s2(1023,1023,1023)
    elseif selftestState == 3 then
        led_s1(1020,0,0) -- green
        led_s2(1020,0,0)
    elseif selftestState == 4 then
        led_s1(0,1020,0)  -- red
        led_s2(0,1020,0)
    elseif selftestState == 5 then
        led_s1(0,0,1020)  -- blue
        led_s2(0,0,1020)
    else
        startWork() 
    end
    
    if selftestState <=  5 then
        selftestState = selftestState + 1
               
        tmr.alarm(2,2000,tmr.ALARM_SINGLE,function()
                nextSelftest()
            end)
    end
end

function startSelftest()
    selftestState = 0
    nextSelftest()
end

function startWork()
    print("\startWork")
 
    tmr.alarm(2,250,tmr.ALARM_AUTO,function()
        fade_leds1()
        fade_leds2()
        tmr.wdclr()
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

        direction = 1 -- always fade up, not down, because that is more colourful
        --rnd = math.random(2) 
        -- print("rnd:".. rnd)

        --if (rnd ==1) then
        --    direction = 1
        --else
        --    direction = -1
        --end
        
        bestMac=mac
        makeMacPixels() 
        probes[mac].time=now
        probes[mac].frame=probes[mac].frame+1  
    end
end


function makeMacPixels() -- make up 8 pixels form a mac

    rgbs=split(bestMac,"\:")
    
    m1_red = tonumber(rgbs[1],16)*4
    m1_green = tonumber(rgbs[2],16)*4
    m1_blue = tonumber(rgbs[3],16)*4

    m2_red = tonumber(rgbs[4],16)*4
    m2_green = tonumber(rgbs[5],16)*4
    m2_blue = tonumber(rgbs[6],16)*4

    if direction == 1 then
        led_s1(0,0,0)
        led_s2(0,0,0)
    else
        led_s1(1023,1023,1023)
        led_s2(1023,1023,1023)
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



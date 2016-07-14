-- docs:  https://nodemcu.readthedocs.io/en/dev/en/modules/ws2812/

-- ws2812 is a library to handle ws2812-like led strips. It works at least on WS2812, WS2812b, APA104, SK6812 (RGB or RGBW).

-- The library uses UART1 routed on GPIO2 (Pin D4 on NodeMCU DEVKIT) to generate the bitstream.

-- I'm using three strings of 49 leds

local dummy, buff = 0, ws2812.newBuffer(3*49,3)    

i = 0



function main()
    print('in main')
    i=0
    probes={}  -- array of recent MAC addresses
    bestMac="00:00:00:00:00:00" -- MAC we're currently showing
    macPixels=ws2812.newBuffer(16,3)  -- pixel RGBs we've made from the current MAC
    makeMacPixels()
       
    wifi.setmode(wifi.SOFTAP)
    cfg={}
    cfg.ssid="mac_address_blinkenlights" 
    cfg.pwd="the_ESP8266_WIFI_password" 
    wifi.ap.config(cfg) 
    
    ws2812.init()      
    
    
     
    buff:fill(255,255,255)
    buff:write()
    
    tmr.alarm(0, 70, tmr.ALARM_AUTO, function()
            handleTimer()
    end)
    
    wifi.eventmon.register(wifi.eventmon.AP_PROBEREQRECVED, function(T) 
    -- print("\n\tAP - PROBE".."\n\tMAC: ".. T.MAC.."\n\tRSSI: "..T.RSSI)
    handleProbe(T.MAC)
    end)
end




function handleTimer()
    
    scroll() 

    --print("\n i before is "..i.."\n\n") 
    i=i+1

    --print("\n i after is "..i.."\n\n") 

    offset = i % 16 
    offset = offset+1

    --print("\n offset is "..offset.."\n\n")  
    --print("\n macPixels is "..macPixels:size().."\n\n")   

    buff:set(1, macPixels:get(offset))
    --buff:set(1, 0, 0, 255)
        
        -- buff:fade(2)
        -- buff:set(i%b:size()+1, 0, 0, 255)
        buff:write()
end

function scroll()
    for j = (buff:size()-1), 1, -1  
    do
    buff:set(j+1,buff:get(j))
        --g, r, b = buff:get(j)
        --buff:set(j+1, g, r, b)
    end
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
        print("\nbestMac: " .. mac )
        
        bestMac=mac
        makeMacPixels() 
        probes[mac].time=now
        probes[mac].frame=probes[mac].frame+1  
    end
end


function makeMacPixels() -- make up 8 pixels form a mac

    rgbs=split(bestMac,"\:")
        
    for n = 1,7
    do
        macPixels:set(n,tonumber(rgbs[1], 16),tonumber(rgbs[2], 16),tonumber(rgbs[3], 16))
    end
    for n = 8,14
    do
        macPixels:set(n,tonumber(rgbs[4], 16),tonumber(rgbs[5], 16),tonumber(rgbs[6], 16))
    end
    for n = 15,16
    do
        macPixels:set(n, 0,0,0 )
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



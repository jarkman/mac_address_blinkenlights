
-- defer work to another file after a delay, 
-- so that we can recover the ESP if we write idiotic startup-time bugs
function bootup()   
    print('in bootup, waiting 20 secs')   
    dofile('jhrs_mithering.lua')
    --dofile('mac_address_blinkenlights.lua')
end

tmr.alarm(0,20000,0,bootup)   

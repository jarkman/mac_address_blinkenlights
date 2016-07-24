print("PWM Function test")
pwm.setup(1,1000,1023);
pwm.start(1);
pwm.setup(2,1000,1023);
pwm.start(2);
pwm.setup(3,1000,1023);
pwm.start(3);

function led_s1(r,g,b)
    pwm.setduty(1,r)
    pwm.setduty(2,g)
    pwm.setduty(3,b)
end


local r=512;
local flag=1;
tmr.alarm(2,50,1,function()
    
    led_s1(r,1023-r,r);
    
    if flag==1 then 
        r=r-50;        if r < 0 then flag=0 r=0 end
    else
        r= r+50;    if r>1023 then flag=1 r=1023 end
   end
end)

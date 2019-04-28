pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
-- made with super-fast-framework

------------------------- start imports
function bbox(w,h,xoff1,yoff1,xoff2,yoff2)
    local bbox={}
    bbox.offsets={xoff1 or 0,yoff1 or 0,xoff2 or 0,yoff2 or 0}
    bbox.w=w
    bbox.h=h
    bbox.xoff1=bbox.offsets[1]
    bbox.yoff1=bbox.offsets[2]
    bbox.xoff2=bbox.offsets[3]
    bbox.yoff2=bbox.offsets[4]
    function bbox:setx(x)
        self.xoff1=x+self.offsets[1]
        self.xoff2=x+self.w-self.offsets[3]
    end
    function bbox:sety(y)
        self.yoff1=y+self.offsets[2]
        self.yoff2=y+self.h-self.offsets[4]
    end
    function bbox:printbounds()
        rect(self.xoff1, self.yoff1, self.xoff2, self.yoff2, 8)
    end
    return bbox
end
function anim()
    local a={}
	a.list={}
	a.current=false
	a.tick=0
    function a:_get_fr(one_shot, callback)
		local anim=self.current
		local aspeed=anim.speed
		local fq=anim.fr_cant		
		local st=anim.first_fr
		local step=flr(self.tick)*anim.w
		local sp=st+step
		self.tick+=aspeed
		local new_step=flr(flr(self.tick)*anim.w)		
		if st+new_step >= st+(fq*anim.w) then 
		    if one_shot then
		        self.tick-=aspeed  
		        callback()
		    else
		        self.tick=0
		    end
		end
		return sp
    end
    function a:set_anim(idx)
        if (self.currentidx == nil or idx != self.currentidx) self.tick=0 
        self.current=self.list[idx]
        self.currentidx=idx
    end
	function a:add(first_fr, fr_cant, speed, zoomw, zoomh, one_shot, callback)
		local a={}
		a.first_fr=first_fr
		a.fr_cant=fr_cant
		a.speed=speed
		a.w=zoomw
        a.h=zoomh
        a.callback=callback or function()end
        a.one_shot=one_shot or false
		add(self.list, a)
	end
	function a:draw(x,y,flipx,flipy)
		local anim=self.current
		if( not anim )then
			rectfill(0,117, 128,128, 8)
			print("err: obj without animation!!!", 2, 119, 10)
			return
		end
		spr(self:_get_fr(self.current.one_shot, self.current.callback),x,y,anim.w,anim.h,flipx,flipy)
    end
	return a
end
function entity(anim_obj)
    local e={}
    e.x=0
    e.y=0
    e.anim_obj=anim_obj
    e.debugbounds, e.flipx, e.flipy = false
    e.bounds=nil
    e.flickerer={}
    e.flickerer.timer=0
    e.flickerer.duration=0          
    e.flickerer.slowness=3
    e.flickerer.is_flickering=false 
    function e.flickerer:flicker()
        if(self.timer > self.duration) then
            self.timer=0 
            self.is_flickering=false
        else
            self.timer+=1
        end
    end
    function e:setx(x)
        self.x=x
        if(self.bounds != nil) self.bounds:setx(x)
    end
    function e:sety(y)
        self.y=y
        if(self.bounds != nil) self.bounds:sety(y)
    end
    function e:setpos(x,y)
        self:setx(x)
        self:sety(y)
    end
    function e:set_anim(idx)
		self.anim_obj:set_anim(idx)
    end
    function e:set_bounds(bounds)
        self.bounds = bounds
        self:setpos(self.x, self.y)
    end
    function e:flicker(duration)
        if(not self.flickerer.is_flickering)then
            self.flickerer.duration=duration
            self.flickerer.is_flickering=true
            self.flickerer:flicker()
        end
        return self.flickerer.is_flickering
    end
    function e:draw()
        if(self.flickerer.timer % self.flickerer.slowness == 0)then
            self.anim_obj:draw(self.x,self.y,self.flipx,self.flipy)
        end
        if(self.flickerer.is_flickering) self.flickerer:flicker()        
		if(self.debugbounds) self.bounds:printbounds()
    end
    return e
end

function timer(updatables, step, ticks, max_runs, func)
    local t={}
    t.tick=0
    t.step=step
    t.trigger_tick=ticks
    t.func=func
    t.count=0
    t.max=max_runs
    t.timers=updatables
    function t:update()
        self.tick+=self.step
        if(self.tick >= self.trigger_tick)then
            self.func()
            self.count+=1
            if(self.max>0 and self.count>=self.max and self.timers ~= nil)then
                del(self.timers,self) 
            else
                self.tick=0
            end
        end
    end
    function t:kill()
        del(self.timers, self)
    end
    add(updatables,t) 
    return t
end

function tutils(args)
	local s={}
	s.private={}
	s.private.tick=0
	s.private.blink_speed=1
	s.height=10 
	s.text=args.text or ""
	s._x=args.x or 2
	s._y=args.y or 2
	s._fg=args.fg or 7
	s._bg=args.bg or 2
	s._sh=args.sh or 3 	
	s._bordered=args.bordered or false
	s._shadowed=args.shadowed or false
	s._centerx=args.centerx or false
	s._centery=args.centery or false
	s._blink=args.blink or false
	s._blink_on=args.on_time or 5
	s._blink_off=args.off_time or 5
	function s:draw()
		if self._centerx then self._x =  64-flr((#self.text*4)/2) end
		if self._centery then self._y = 64-(4/2) end
		if self._blink then 
			self.private.tick+=1
			local offtime=self._blink_on+self._blink_off 
			if(self.private.tick>offtime) then self.private.tick=0 end
			local blink_enabled_on = false
			if(self.private.tick<self._blink_on)then
				blink_enabled_on = true
			end
			if(not blink_enabled_on) then
				return
			end
		end
		local yoffset=1
		if self._bordered then 
			yoffset=2
		end
		if self._bordered then
			local x=max(self._x,1)
			local y=max(self._y,1)
			if(self._shadowed)then
				for i=-1, 1 do	
					print(self.text, x+i, self._y+2, self._sh)
				end
			end
			for i=-1, 1 do
				for j=-1, 1 do
					print(self.text, x+i, y+j, self._bg)
				end
			end
		elseif self._shadowed then
			print(self.text, self._x, self._y+1, self._sh)
		end
		print(self.text, self._x, self._y, self._fg)
    end
	return s
end

--  --<*sff/collision.lua
--  --<*sff/explosions.lua
--  --<*sff/buttons.lua

local tick_dance=0
local step_dance=0
function dance_bkg(delay,color)
    local sp=delay
    local pat=0b1110010110110101
    tick_dance+=1
    if(tick_dance>=sp)then
        tick_dance=0
        step_dance+=1
        if(step_dance>=16)then step_dance = 0 end
    end
    fillp(bxor(shl(pat,step_dance), shr(pat,16-step_dance)))
    rectfill(0,0,64,64,color)
    rectfill(64,64,128,128,color)
    fillp(bxor(shr(pat,step_dance), shl(pat,16-step_dance)))
    rectfill(64,0,128,64,color)
    rectfill(0,64,64,128,color)
    fillp() 
end
function menu_state()
    local state={}
    local texts={}
	add(texts, tutils({text="ghost avenger",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="rombosaur studios",centerx=true,y=99,fg=9,sh=2,shadowed=true}))
	add(texts, tutils({text="press ❎ to start", blink=true, on_time=15, centerx=true,y=80,fg=0,bg=1,shadowed=true, sh=7}))
	add(texts, tutils({text="v0.1", x=106, y=97}))
	local ypos = 111
	add(texts, tutils({text="🅾️             ❎  ", centerx=true, y=ypos, shadowed=true, bordered=true, fg=8, bg=0, sh=2}))
	add(texts, tutils({text="  buttons  ", centerx=true, y=ypos, shadowed=true, fg=7, sh=0}))
    add(texts, tutils({text="  z         x  ", centerx=true, bordered=true, y=ypos+3, fg=8, bg=0}))
    ypos+=10
	add(texts, tutils({text="  remap  ", centerx=true, y=ypos, shadowed=true, fg=7, sh=0}))
	local x1=28 
	local y1=128-19 
	local x2=128-x1-2 
	local y2=128 
	local frbkg=1
	local frfg=6
	state.update=function()
        if(btnp(5)) curstate=game_state(1) 
	end
	cls()
	state.draw=function()
		dance_bkg(10,frbkg)
		rectfill(3,2, 128-4, 104, 7)
		rectfill(2,3, 128-3, 103, 7)
		rectfill(4,3, 128-5, 103, 0)
		rectfill(3,4, 128-4, 102, 0)
		rectfill(5,4, 128-6, 102, frfg)
		rectfill(4,5, 128-5, 101, frfg)
		rectfill(25,97,  101, 111, frbkg)
		rectfill(24,98,  102, 111, frbkg)
		pset(23,104,frbkg)
		pset(103,104,frbkg)
        rectfill(x1,y1-1,  x2,y2+1, 0)
		rectfill(x1-1,y1,  x2+1,y2, 0)
		rectfill(x1,y1,  x2,y2, 6)
		local y=122
		rectfill(75-1,y+1-1, 120+1-8,y+1+1, 0)
		rectfill(121-1-8,y+1-1, 121+1-8,128+1, 0)
		rectfill(75,y+1, 120-8,y+1, 8)
		rectfill(121-8,y+1, 121-8,128, 8)
        for t in all(texts) do
            t:draw()
        end
	end
	return state
end
function game_state(lvl)
    local s={}
    local updas={}
    local draws={}
    function hero(x,y)
        local anim_obj=anim()
        anim_obj:add(64,7,0.05,1,1)
        anim_obj:add(55,4,0.3,1,1)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8,1,0,2,0)
        e:set_bounds(bounds_obj)
        e.debugbounds=false
        e.health=10
        function e:update()
            if e.health <= 0 then
            end
            local s=1
            local im=btn(0)or btn(1)or btn(2)or btn(3)
            if btn(0) then     
                e:setx(e.x-s)
                e.flipx=true
            elseif btn(1) then 
                e:setx(e.x+s)
                e.flipx=false
            end
            if btn(2) then          
                e:sety(e.y-s)
            elseif btn(3) then  
                e:sety(e.y+s)
            end
            if(e.x < 8)e:setx(8)
            if(e.x > 240)e:setx(240)
            if(e.y<8)e:sety(8)
            if(e.y>112)e:sety(112)
            if btnp(4) then 
            end
            if btnp(5) then 
            end
            if im then 
                e:set_anim(2)
            else
                e:set_anim(1)
            end
        end
        return e
    end
    function zombie(x,y,h)
        local anim_obj=anim()
        anim_obj:add(39,4,0.2,1,1)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8,1,0,2,0)
        e:set_bounds(bounds_obj)
        e.debugbounds=false
        function e:update()
            local s=0.3 
            if h.x > e.x then
                e.flipx=false
                e:setx(e.x+s)
            elseif h.x < e.x then
                e.flipx=true
                e:setx(e.x-s)
            end
            if h.y > e.y then
                e:sety(e.y+s)
            elseif h.y < e.y then
                e:sety(e.y-s)
            end
        end
        return e
    end
    function spawner(x,y,h,fq)
        local anim_obj=anim()
        anim_obj:add(37,1,0.1,2,2)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.tick=0
        e.f=0       
        e.co=fq+30  
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        function e:update()
            e.tick+=0.1
            if e.tick > fq then
                if e.f == 0 then
                    local z=zombie(x,y,h) add(updas,z) add(draws,z)
                end
                e.f=1
                if e.tick > e.co then 
                    e.tick=0
                    e.f=0
                end
            end
        end
        return e
    end
    function ghost(x,y)
        local anim_obj=anim()
        anim_obj:add(8,4,0.2,2,2)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.mhealth=100 
        e.health=80
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        function e:update()
        end
        e._draw=e.draw
        function e:draw()
            spr(6, x,y+8, 2, 2) 
            e:_draw()    
            local hbl=15 
            local hb=e.health*hbl/e.mhealth 
            rectfill(x,y-2, x+hbl, y-1, 9)
            rectfill(x,y-2, x+hb,  y-1, 3)
        end
        return e
    end
    local h = hero(10,10) add(updas, h) add(draws, h)
    local g = ghost(120,48) add(updas, g) add(draws, g)
    local sp1 = spawner(16,16,h,5) add(updas, sp1) add(draws, sp1)
    local sp2 = spawner(224,16,h,7) add(updas, sp2) add(draws, sp2)
    local sp3 = spawner(224,96,h,11) add(updas, sp3) add(draws, sp3)
    local sp4 = spawner(16,96,h,6) add(updas, sp4) add(draws, sp4)
    s.update=function()
        local cx=0
        if(h.x > 64)cx=h.x-64
        if(h.x > 192)cx=128
        camera(cx,0)
        sort(draws)
        for u in all(updas) do
            u:update()
        end
    end
    s.draw=function()
        cls()
        map(0,0,0,0)
        for d in all(draws) do
            d:draw()
        end
    end
    function sort(a)
        for i=1,#a do
            local j = i
            while j > 1 and a[j-1].y > a[j].y do
                a[j],a[j-1] = a[j-1],a[j]
                j = j - 1
            end
        end
    end
    return s
end
function gameover_state()
    local s={}
    local texts={}
    local timeout=2 
    local frbkg=8
    local frfg=6
    music(-1)
    sfx(-1)
    local ty=15
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    local restart_msg = "press ❎ to restart"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=game_state() 
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        if(timeout > 0)then
            local t = flr(timeout) + 1
            msg.text = "wait for it... ("..t..")"
        else
            msg.text = restart_msg
        end
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end
function win_state()
    local s={}
    local texts={}
    local timeout=2 
    local frbkg=11
    local frfg=6
    music(-1)
    sfx(-1)
    local ty=15
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    local restart_msg = "press ❎ to restart"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=game_state() 
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        if(timeout > 0)then
            local t = flr(timeout) + 1
            msg.text = "wait for it... ("..t..")"
        else
            msg.text = restart_msg
        end
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end
--------------------------- end imports

-- to enable mouse support uncomment all of the following commented lines:
-- poke(0x5f2d, 1) -- enables mouse support
function _init()
    curstate=menu_state()
end

function _update()
    -- mouse utility global variables
    -- mousex=stat(32)
    -- mousey=stat(33)
    -- lclick=stat(34)==1
    -- rclick=stat(34)==2
    -- mclick=stat(34)==4
	curstate.update()
end

function _draw()
    curstate.draw()
    -- pset(mousex,mousey, 12) -- draw your pointer here
end
__gfx__
000000000000000022442224444422224442222442224422000000000000000000000000000000000000d00d0000d00000000000000000000000000000000000
000000000000000024444444224422224444224444444442000000000000000000000d00d0000000000d00d00dd0d00000d00dd0000d00000000d00d0000d000
00000000000000004422244222244224422444422442224400000000000000000d0d00d00d00d0d00dddd0d00d0dddd000ddd0d00d0ddd00000d00d00dd0d000
000000000000000042222242222444442222444224222224000000000000000000ddd0d00d0ddd00000dddddddddd00d000ddddddddddd000dddd0d00d0dddd0
0000000000000000422222442244224422224444442222240000000000000000000dddddddddd0000d0dddddddddd00000ddddddddddd0d0000dddddddddd00d
0000000000000000442224444442222442244444444222440000000000000000000dddddddddd000d0ddddddddddddd00dddddddddddddd00d0dddddddddd000
0000000000000000444444222442222444444442224444440000000000000000d0dd66dddd66dd0d0ddddddddddddd0d0ddddddddd66ddd0d0ddddddddddddd0
00000000000000004444422222442244442244222224444400992222222299000ddd66dddd66ddd00ddd66dddd66ddd00ddd66dddd66ddd00ddd66dddddddd0d
000000000000000042224222224422444422442222242224044999222244499000dddddddddddd000dddddddddddddd00dddddddddddddd00ddd66dddd66ddd0
0000000000000000222224222442222444444442224222220044999444499900d0dddddddddddd0d0dddddddddddddd00dddddddddddddd00dddddddddddddd0
00000000000000002222244444422224422444444442222200044999999990000dddddddddddddd00dddddddddddddd00dddddddddddddd00dddddddddddddd0
00000000000000004222444444442244222244444444222400004998899900000dddddddddddddd0000dddddddddd000000dddddddddd0000dddddddddddddd0
0000000000000000444444444224444422224442444444440000449889990000000dddddddddd00000000dddddd0000000000dddddd00000000dddddddddd000
000000000000000044442224422442244224444242224444000449999999900000000dddddd000000000000dd00000000000000dd000000000000dddddd00000
00000000000000002442222244442222444422442222244200444449999999000000000dd0000000000000000000000000000000000000000000000dd0000000
00000000000000002242222244242222444222242222242200444444444449000000000000000000000000000000000000000000000000000000000000000000
1d11111111111d111111111111111d11111111110000000000000000003333000003330000333300003330000033330000000000000000000000000000000000
dd11111dd1111111111111111111111111111111000000000000000000338300003338000033830000333800003383000000000bb00000000000000000000000
d1111111dd111111d1111111111111111111111100000000000000000033330000383300003333000033330000333300000000bb7b0000000000000bb0000000
111111111111111d111111111111111d1111111100000000000000000033300000333000003330000003300000333000000000bbbb000000000000bb7b000000
1111111111111111111111111111111111111111000005555550000000044430000445300004443000044430000444300000000bb0000000000000bbbb000000
11111111111111111111111111111111111111110000556668550000000440000004430000044500005440000004450000000000000000000000000bb0000000
1111111dd11111111111111111111111111111110005256686565000000440000004440000044000003440000004400000000444444000000000044444400000
111111ddd11111111111111111111111111111110005625555685000000530000050030000305000000050000030500000004499994400000000449999440000
111111dd111111111111111111111111000006670005265665865000004444000044440000444400004444000000000000049499994940000004949999494000
111111d11111111111111111111111110000067600526256656865000044fd00004fdf0000fdfd00004fdf000000000000049494494940000004949449494000
1111111111111111111111111111111100006766005625666656650000ffff0000ffff0000ffff0000ffff000000000000499949949994000049994994999400
11111111111111111111111111111111050676000562656666566650000bfff0000bb0000ffbb660000fb0000000000000499499994994000049949999499400
11111111111111111111111111111111556760000526256666566650066bb000000bff000f0bb00000fbb6000000000000499499994994000049949999499400
1111111dd11111111111111dd1111111057600000052656666566500000cccc0000bb000000c5550000bb0000000000000499499994994000049949999499400
11111111d11111d111111111d1111111055550000005526666655000005550c0000cc00000cc0050000c50000000000000049499994940000004949999494000
1d11111111111dd11d111111111111115005000000005555555500000000000000500c000000000000c005000000000000004444444400000000444444440000
00444400004444000044440000000000000000000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000
004fdf0000fdfd00004fdf0000444400004444000044440000fdfd00000000000000000000000000000000000000000000000000000000000000000000000000
00ffff0000ffff0000ffff0000fdfd0000dfdf0000fdfd0000ffff00000000000000000000000000000000000000000000000000000000000000000000000000
000bb00000bbbb00000bb00000ffff0000ffff0000ffff0000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000
00fbbf000f0bb0f000fbbf0000bbbb0000bbbb0000bbbb000f0bb0f0000000000000000000000000000000000000000000000000000000000000000000000000
0f0bb0f0000bb0000f0bb0f000fbbf0000fbbf0000fbbf00000bb000000000000000000000000000000000000000000000000000000000000000000000000000
000cc000000cc000000cc000000bb000000bb000000bb000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
000cc000000cc000000cc00000c0c000000cc000000cc000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0203040502030405020304050203040502030405020304050203040502030405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213141512131415121314151213141512131415121314151213141512131415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

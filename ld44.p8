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

function collides(ent1, ent2)
    local e1b=ent1.bounds
    local e2b=ent2.bounds
    if  ((e1b.xoff1 <= e2b.xoff2 and e1b.xoff2 >= e2b.xoff1)
    and (e1b.yoff1 <= e2b.yoff2 and e1b.yoff2 >= e2b.yoff1)) then 
        return true
    end
    return false
end
function point_collides(x,y, ent)
    local eb=ent.bounds
    if  ((eb.xoff1 <= x and eb.xoff2 >= x)
    and (eb.yoff1 <= y and eb.yoff2 >= y)) then 
        return true
    end
    return false
end
function circle_explo()
	local ex={}
	ex.circles={}
	function ex:explode(x,y)
		add(self.circles,{x=x,y=y,t=0,s=2})
	end
	function ex:multiexplode(x,y)
		local time=0
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1 }) time-=2
		add(self.circles,{x=x+7,y=y-3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x-7,y=y+3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x+7,y=y+3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x-7,y=y-3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1}) time-=2
	end
	function ex:update()
		for ex in all(self.circles) do
			ex.t+=ex.s
			if ex.t >= 20 then
				del(self.circles, ex)
			end
		end
	end
	function ex:draw()
		for ex in all(self.circles) do
			circ(ex.x,ex.y,ex.t/2,8+ex.t%3)
		end
	end
	return ex
end
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
	music(0)
	add(texts, tutils({text="ghost avenger",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="rombosaur studios",centerx=true,y=99,fg=9,sh=2,shadowed=true}))
	add(texts, tutils({text="ludum dare 44",centerx=true,y=16,fg=4,sh=2,shadowed=true}))
	add(texts, tutils({text="sword:❎",x=12,y=60-15, fg=0,bg=1,shadowed=true, sh=7}))
	add(texts, tutils({text="bomb: 🅾️" ,x=12,y=68-15, fg=0,bg=1,shadowed=true, sh=7}))
	add(texts, tutils({text="move: ⬅️➡️⬆️⬇️",x=12,y=76-15, fg=0,bg=1,shadowed=true, sh=7}))
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
		camera(0,0)
        if(btnp(5)) curstate=instructions_state() 
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
    local spawns={}
    local zmbs={}
    local clos={}
    local shake=0
    local exp=circle_explo()
    local zkills=0  
    local bt=0      
    local bf=true   
    local t=0       
    local ct=0      
    local p=0       
    local bootsf=true
    music(-1)
    music(6)
    function sword(x,y,h)
        local anim_obj=anim()
        anim_obj:add(52,1,1,1,1) 
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        ad=function()
            h:stop_atk()
            e:set_anim(1) 
            e:setx(h.x)
            e:sety(h.y)
        end
        anim_obj:add(84,4,0.75,1,2,true,ad) 
        local bounds_obj=bbox(8,16, 0,0,0,4)
        e:set_bounds(bounds_obj)
        e.dmg=1
        function e:update()
            local xo=0
            local yo=0
            local fx=1
            if(h.flipx)fx=-1
            if h.atk then
                xo=8*fx
                yo=-3
                for z in all(zmbs) do
                    if collides(z,e) then
                        z:hurt(e.dmg)
                    end
                end
                for s in all(spawns) do
                    if collides(s,e) then
                        s:hurt(e.dmg)
                    end
                end
            end
            e.flipx=h.flipx
            e:setx(h.x+xo)
            e:sety(h.y+yo)
        end
        function e:atk()
            e:setx(e.x+16)
            e:set_anim(2)
        end
        return e
    end
    function hero(x,y,g)
        local anim_obj=anim()
        anim_obj:add(64,7,0.05,1,1) 
        anim_obj:add(55,4,0.3,1,1)  
        anim_obj:add(88,1,0.3,1,1)  
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8,1,0,2,0)
        e:set_bounds(bounds_obj)
        e.debugbounds=false
        e.mhealth=5 
        e.health=5
        e.atk=false  
        e.swrd=sword(x,y,e)
        e.spdb=false
        e.spd=1
        function e:update()
            if(e.health > e.mhealth) e.health=e.mhealth
            if e.health <= 0 then
                curstate=gameover_state(p,zkills,false)
            end
            if not e.atk then
                local s=e.spd
                if(e.spdb)s+=1.5
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
            end
            if(e.x < 8)e:setx(8)
            if(e.x > 240)e:setx(240)
            if(e.y<8)e:sety(8)
            if(e.y>112)e:sety(112)
            if btnp(4) then 
                if g.health > g.mhealth/4 then
                    shake=15
                    for z in all(zmbs) do
                        z:hurt(100)
                    end
                    g:usebomb()
                    sfx(6)
                end
            end
            if btnp(5) then 
                if(not e.atk)sfx(3)
                e.atk=true
                e.swrd:atk()
                e:set_anim(3) 
            end
            if not e.atk then
                if btn(0)or btn(1)or btn(2)or btn(3) then 
                    e:set_anim(2) 
                else
                    e:set_anim(1) 
                end
            end
            e.swrd:update()
        end
        e._draw=e.draw
        function e:draw()
            if(not e.atk)e.swrd:draw()
            e:_draw()
            if(e.atk)e.swrd:draw()
            local hbl=7 
            local hb=e.health*hbl/e.mhealth 
            rectfill(e.x,e.y-4, e.x+hbl, e.y-3, 8)
            rectfill(e.x,e.y-4, e.x+hb,  e.y-3, 3)
        end
        function e:stop_atk()
            e.atk=false   
        end
        function e:hurt(dmg)
            if not self.flickerer.is_flickering then
                sfx(1)
                e:flicker(15)
                if(e.health>0)e.health-=dmg
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
        e.mhealth=10 
        e.health=10
        e.tick=0
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        function e:update()
            if(e.health > e.mhealth) e.health=e.mhealth
            e.tick+=0.1
            if e.health <= 0 then
                curstate=gameover_state(p,zkills,true)
            end
            if e.health<=e.mhealth and e.tick > 50 then
                e.tick=0
            end
        end
        e._draw=e.draw
        function e:draw()
            spr(6, x,y+8, 2, 2) 
            e:_draw()    
            local hbl=15 
            local hb=e.health*hbl/e.mhealth 
            rectfill(x,y-2, x+hbl, y-1, 8)
            rectfill(x,y-2, x+hb,  y-1, 3)
        end
        function e:hurt(dmg)
            if not self.flickerer.is_flickering then
                e:flicker(15)
                if(e.health>0)e.health-=dmg
                sfx(2)
            end
        end
        function e:usebomb()
            e.health-=e.mhealth/4
        end
        return e
    end
    function zombie(x,y,h,g)
        local anim_obj=anim()
        anim_obj:add(39,4,0.2,1,1) 
        anim_obj:add(71,4,0.1,1,1) 
        anim_obj:add(80,4,0.3,1,1) 
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        add(zmbs, e)
        local bounds_obj=bbox(8,8,1,0,2,0)
        e:set_bounds(bounds_obj)
        e.debugbounds=false
        e.dmg=1   
        e.arr=false 
        e.ct=5      
        e.tick=0
        e.hp=3      
        e.fr=false  
        function e:update()
            if e.hp <= 0 then
                del(updas, e)
                del(draws, e)
                del(zmbs, e)
                exp:multiexplode(e.x,e.y)
                if(shake==0)shake=2
                zkills+=1
                bt+=1
                ct+=1
                p+=3
                sfx(4)
                return
            end
            if not e.fr then
                local s=0.3 
                local cx=e.x+4
                local cy=e.y+4
                local dy=abs(cy-(h.y+4))
                local dx=abs(cx-(h.x+4))
                local m=max(dy,dx)  dy=dy/m  dx=dx/m
                local hd=abs(sqrt((dy*dy)+(dx*dx)))  
                dy=cy-(g.y+16)
                dx=cx-(g.x+8)
                m=max(dy,dx)  dy=dy/m  dx=dx/m
                local gd=abs(sqrt((dy*dy)+(dx*dx)))  
                local t=h   
                local d=hd  
                local tx=h.x+4 
                local ty=h.y+4
                if hd > gd or (h.x< 64 and e.x > 128)then
                    t=g  d=gd
                    tx=g.x+8  ty=g.y+16
                end
                if(e.arr)e.tick+=0.1
                if e.tick > e.ct then
                    e.tick=0  e.arr=false 
                    e:set_anim(1) 
                end
                if not self.flickerer.is_flickering then
                    if abs(e.x-tx)<=7 and abs(e.y-ty)<=7 then
                        e.arr=true    
                        e:set_anim(3) 
                        t:hurt(e.dmg)
                    elseif not e.arr then
                        local ang=atan2(cx-tx,cy-ty)
                        local fx=abs(cos(ang)*s)
                        local fy=abs(sin(ang)*s)
                        if tx > e.x then
                            e:setx(e.x+fx) e.flipx=false
                        elseif tx < e.x then
                            e:setx(e.x-fx) e.flipx=true
                        end
                        if ty > e.y then
                            e:sety(e.y+fy)
                        elseif ty < e.y then
                            e:sety(e.y-fy)
                        end
                    else
                        e:set_anim(2) 
                    end
                else
                    e:set_anim(2) 
                end
            end
        end
        e._draw=e.draw
        function e:draw()
            e:_draw()
            local xx = e.x+2
            for h=1,e.hp do
                pset(xx,e.y-2, 8)
                xx+=2
            end
        end
        function e:hurt(d)
            if d > 99 or not self.flickerer.is_flickering then
                e:flicker(15)
                e.hp-=d
                sfx(5)
            end
        end
        function e:freeze(flag)
            e.fr=flag
        end
        return e
    end
    function spawner(x,y,h,fq,g)
        local anim_obj=anim()
        anim_obj:add(37,1,0.1,2,2)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        e.tick=0
        e.f=0       
        e.co=fq+3  
        e.fr=false  
        e.health=250
        e.mhealth=250
        e.fq=fq
        function e:update()
            if t % 1000 == 0 then
                e.fq-=3
                if(e.fq < 1)e.fq=1
                e.co=e.fq+10
            end
            if e.health <=0 then
                exp:multiexplode(e.x,e.y)
                shake=10
                del(updas,e)
                del(draws,e)
                del(spawns,e)
                p+=100
                sfx(6)
                sfx(10)
                local h=health(e.x-4, e.y-4, h,g) add(updas, h) add(draws, h)
            end
            if not e.fr then
                e.tick+=0.1
                if e.tick > e.fq then
                    if e.f == 0 then
                        local z=zombie(x+8,y+8,h,g) add(updas,z) add(draws,z)
                        sfx(0)
                    end
                    e.f=1
                    if e.tick > e.co then 
                        e.tick=0
                        e.f=0
                    end
                end
            end
        end
        e._draw=e.draw
        function e:draw()
            e:_draw()
            local hbl=15 
            local hb=e.health*hbl/e.mhealth 
            rectfill(e.x,e.y-3, e.x+hbl, e.y-2, 8)
            rectfill(e.x,e.y-3, e.x+hb,  e.y-2, 3)
        end
        function e:hurt(d)
            e:flicker(3)
            e.health-=d
            sfx(5)
        end
        function e:freeze(flag)
            e.fr=flag
        end
        return e
    end
    function bomb(x,y,h)
        local anim_obj=anim()
        anim_obj:add(1,1,1,1,1)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.kill=false
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        function e:update()
            if e.kill then
                del(updas, e)
                del(draws, e)
                bt=0
                bf=true
                p+=10
            end
            if collides(h,e) then
                exp:multiexplode(e.x,e.y)
                shake=10
                for z in all(zmbs) do
                    z:hurt(100)
                end
                e.kill=true 
                sfx(6)
            end
        end
        return e
    end
    function clock(x,y,h)
        local anim_obj=anim()
        anim_obj:add(75,1,1,1,1)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        e.f=true    
        e.t=0
        e.expiry=200 
        function e:update()
            if not e.f then
                e.t+=1
                if e.t >= e.expiry then
                    for z in all(zmbs) do
                        z:freeze(false)
                    end
                    for s in all(spawns) do
                        s:freeze(false)
                    end
                    ct=0
                    del(updas, e)
                    del(draws, e)
                    del(clos, e)
                    p+=50
                    sfx(8)
                    h.spdb=false
                end
            end
            if collides(h,e) and e.f then
                e.f = false
                shake=2
                for z in all(zmbs) do
                    z:freeze(true)
                end
                for s in all(spawns) do
                    s:freeze(true)
                end
                e:flicker(e.expiry)
                sfx(7)
                h.spdb=true 
            end
        end
        return e
    end
    function health(x,y,h,g)
        local anim_obj=anim()
        anim_obj:add(16,1,1,1,1)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        function e:update()
            if collides(h,e) then
                del(updas, e)
                del(draws, e)
                g.health+=g.mhealth/4
                h.health+=h.mhealth/4
                sfx(7)
            end
        end
        return e
    end
    function boots(x,y,h)
        local anim_obj=anim()
        anim_obj:add(77,1,1,1,1)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        e.f=true
        function e:update()
            if collides(h,e) and e.f then
                del(updas, e)
                del(draws, e)
                h.spd+=1
                sfx(7)
                e.f=false
            end
        end
        return e
    end
    local g = ghost(120, 48) add(updas, g) add(draws, g)
    local h = hero(120,80,g) add(updas, h) add(draws, h)
    local sp1 = spawner(16 ,16,h,5 ,g) add(updas, sp1) add(draws, sp1) add(spawns, sp1)
    local sp2 = spawner(224,16,h,7 ,g) add(updas, sp2) add(draws, sp2) add(spawns, sp2)
    local sp3 = spawner(224,96,h,11,g) add(updas, sp3) add(draws, sp3) add(spawns, sp3)
    local sp4 = spawner(16 ,96,h,6 ,g) add(updas, sp4) add(draws, sp4) add(spawns, sp4)
    s.update=function()
        if #spawns == 0 then
            curstate=win_state(p,zkills)
        end
        t+=1
        local cx=0
        if(h.x > 64)cx=h.x-64
        if(h.x > 192)cx=128
        camera(cx,0)
        cam_shake(cx)
        exp:update()
        for u in all(updas) do
            u:update()
        end
        local xx=rnd(40)+100
        local yy=rnd(40)+70
        if bt > 10 and bf then
            bf = false
            sfx(9)
            local b=bomb(xx,yy,h) add(updas,b) add(draws,b)
        end
        if ct > 20 and #clos==0 then
            sfx(9)
            local c=clock(xx,yy,h) add(updas,c) add(draws,c) add(clos, c)
        end
        if zkills > 50 and bootsf then
            bootsf=false
            sfx(9)
            local b=boots(xx,yy,h) add(updas,b) add(draws,b)
        end
        sort(draws)
    end
    s.draw=function()
        cls()
        map(0,0,0,0)
        exp:draw()
        for d in all(draws) do
            d:draw()
        end
        camera(0,0)
        rectfill(1,0,50,6, 0)
        print("kills: "..zkills,2,1,7)
        rectfill(69,0,120,6, 0)
        print("points: "..p,70,1,7)
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
    function cam_shake(cx)
        if shake>0 then
            if shake>0.1 then
                shake*=0.9
            else
                shake=0
            end
            camera(cx+(rnd()*shake),rnd()*shake)
        end
    end
    return s
end

function gameover_state(points, kills, ghostdied)
    local s={}
    local texts={}
    local timeout=2 
    local frbkg=8
    local frfg=6
    music(-1)
    sfx(-1)
    music(0)
    local ty=15
    local msg="you died"
    if(ghostdied)msg="the ghost died"
    add(texts, tutils({text="game over",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text=msg,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="points:                  ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
    add(texts, tutils({text="        "..points,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="kills:                   ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
    add(texts, tutils({text="        "..kills,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    local restart_msg = "press ❎ to restart"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        camera(0,0)
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=menu_state() 
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
function win_state(points,kills)
    local s={}
    local texts={}
    local timeout=2 
    local frbkg=11
    local frfg=6
    music(-1)
    sfx(-1)
    music(0)
    local ty=15
    add(texts, tutils({text="congratulations",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="you've beaten the game" ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="points:                  ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
    add(texts, tutils({text="        "..points,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="kills:                   ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
    add(texts, tutils({text="        "..kills,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    local restart_msg = "press ❎ to restart"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        camera(0,0)
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=menu_state() 
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
function instructions_state()
    local s={}
    local texts={}
    local frbkg=1
    local frfg=6
    local ty=15
    add(texts, tutils({text="instructions",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="-protect the ghost       ",centerx=true,y=ty,fg=0,bg=0,bordered=false,shadowed=false,sh=2}))ty+=10
    add(texts, tutils({text="-destroy all the spawners",centerx=true,y=ty,fg=0,bg=0,bordered=false,shadowed=false,sh=2})) ty+=10
    add(texts, tutils({text="-🅾️ button takes life from",centerx=true,y=ty,fg=0,bg=0,bordered=false,shadowed=false,sh=2})) ty+=10
    add(texts, tutils({text=" the ghost. use it wisely",centerx=true,y=ty,fg=0,bg=0,bordered=false,shadowed=false,sh=2}))ty+=10
    local cmsg = "press ❎ to continue"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        camera(0,0)
        if(btnp(5)) curstate=game_state() 
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
		msg.text = cmsg
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
    --curstate=gameover_state(544,11,true)
    -- curstate=win_state(543,140)
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
000000000000778022442224444422224442222442224422000000000000000000000000000000000000d00d0000d00000000000000000000000000000000000
000000000007000024444444224422224444224444444442000000000000000000000d00d0000000000d00d00dd0d00000d00dd0000d00000000d00d0000d000
00000000000220004422244222244224422444422442224400000000000000000d0d00d00d00d0d00dddd0d00d0dddd000ddd0d00d0ddd00000d00d00dd0d000
000000000022d20042222242222444442222444224222224000000000000000000ddd0d00d0ddd00000dddddddddd00d000ddddddddddd000dddd0d00d0dddd0
0000000002222d20422222442244224422224444442222240000000000000000000dddddddddd0000d0dddddddddd00000ddddddddddd0d0000dddddddddd00d
0000000002222d20442224444442222442244444444222440000000000000000000dddddddddd000d0ddddddddddddd00dddddddddddddd00d0dddddddddd000
0000000002222220444444222442222444444442224444440000000000000000d0dd66dddd66dd0d0ddddddddddddd0d0ddddddddd66ddd0d0ddddddddddddd0
00000000002222004444422222442244442244222224444400992222222299000ddd66dddd66ddd00ddd66dddd66ddd00ddd66dddd66ddd00ddd66dddddddd0d
777887770000000042224222224422444422442222242224044999222244499000dddddddddddd000dddddddddddddd00dddddddddddddd00ddd66dddd66ddd0
7778877700000000222224222442222444444442224222220044999444499900d0dddddddddddd0d0dddddddddddddd00dddddddddddddd00dddddddddddddd0
77788777007887002222244444422224422444444442222200044999999990000dddddddddddddd00dddddddddddddd00dddddddddddddd00dddddddddddddd0
88888888008888004222444444442244222244444444222400004998899900000dddddddddddddd0000dddddddddd000000dddddddddd0000dddddddddddddd0
8888888800888800444444444224444422224442444444440000449889990000000dddddddddd00000000dddddd0000000000dddddd00000000dddddddddd000
777887770078870044442224422442244224444242224444000449999999900000000dddddd000000000000dd00000000000000dd000000000000dddddd00000
77788777000000002442222244442222444422442222244200444449999999000000000dd0000000000000000000000000000000000000000000000dd0000000
77788777000000002242222244242222444222242222242200444444444449000000000000000000000000000000000000000000000000000000000000000000
1d11111111111d111111111111111d11111111110000000000000000003333000003330000333300003330000033330000000000000000000000000000000000
dd11111111111111111111111111111111111111000000000000000000338300003338000033830000333800003383000000000bb00000000000000000000000
d111111111111111d1111111111111111111111100000000000000000033330000383300003333000033330000333300000000bb7b0000000000000bb0000000
111111111111111d111111111111111d1111111100000000000000000033300000333000003330000003300000333000000000bbbb000000000000bb7b000000
1111111111111111111111111111111111111111000005555550000000044430000445300004443000044430000444300000000bb0000000000000bbbb000000
11111111111111111111111111111111111111110000556668550000000440000004430000044500005440000004450000000000000000000000000bb0000000
11111111111111111111111111111111111111110005256686565000000440000004440000044000003440000004400000000444444000000000044444400000
11111111111111111111111111111111111111110005625555685000000530000050030000305000000050000030500000004499994400000000449999440000
11111111111111111111111111111111000020020005265665865000004444000044440000444400004444001d1111dd00049499994940000004949999494000
111111111111111111111111111111110002222000526256656865000044fd00004fdf0000fdfd00004fdf00d111111100049494494940000004949449494000
1111111111111111111111111111111100005620005625666656650000ffff0000ffff0000ffff0000ffff001111111100499949949994000049994994999400
11111111111111111111111111111111000565220562656666566650000bfff0000bb0000ffbb660000fb0001111111d00499499994994000049949999499400
11111111111111111111111111111111005650200526256666566650066bb000000bff000f0bb00000fbb6001111111d00499499994994000049949999499400
11111111d11111111111111dd1111111556500000052656666566500000cccc0000bb000000c5550000bb0001111111100499499994994000049949999499400
11111111d11111d111111111d1111111565000000005526666655000005550c0000cc00000cc0050000c5000d111111d00049499994940000004949999494000
1d11111111111dd11d111111111111116550000000005555555500000000000000500c000000000000c00500dd1111dd00004444444400000000444444440000
00444400004444000044440000000000000000000000000000444400000333000033330000333300003333000055550011111111777799770000000000000000
004fdf0000fdfd00004fdf0000444400004444000044440000fdfd0000333800003838000083830000383800057777501d111111799797970000000000000000
00ffff0000ffff0000ffff0000fdfd0000dfdf0000fdfd0000ffff0000383300003333000033330000333300577577751d111111797799770000000000000000
000bb00000bbbb00000bb00000ffff0000ffff0000ffff0000bbbb000033300000044300003440000004430057757775dd111111797797790000000000000000
00fbbf000f0bb0f000fbbf0000bbbb0000bbbb0000bbbb000f0bb0f00004430000344000000443000034400057755575d1111111799797790000000000000000
0f0bb0f0000bb0000f0bb0f000fbbf0000fbbf0000fbbf00000bb000003440000004400000044000000440005777777511111111779777990000000000000000
000cc000000cc000000cc000000bb000000bb000000bb000000cc000000440000004400000044000000440000577775011111dd1779779790000000000000000
000cc000000cc000000cc00000c0c000000cc000000cc000000cc000000530000005300000053000000530000055550011111d11799779990000000000000000
00383800000033000038330000003300000000000000000000000600000000000004444000000000000000000000000000000000000000000000000000000000
303333000003833308333e000003833306676000000600600060000000000000000fdfd000000000000000000000000000000000000000000000000000000000
0303ee00003333800333eee00033338060667600600060060000600600060000000ffff000000000000000000000000000000000000000000000000000000000
00343300003333330333eee30033333306067600060006670600060000000600000bbb0000000000000000000000000000000000000000000000000000000000
0004400000433eee0033333300433eee00076000006067760000060600600000000bbbf500000000000000000000000000000000000000000000000000000000
0004400000433ee00043335000433ee006676000006676600006666600000606000bb00000000000000000000000000000000000000000000000000000000000
00044000004433e000444000004433e056766000567760005666777755500600000cccc000000000000000000000000000000000000000000000000000000000
005003000503000000503000050300005566000057660000577766665666006000cc00c000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555000005550000055560000576666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000567766660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000006676600000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000667660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000766670000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077770000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000
__map__
0203040502030405020304050203040502030405020304050203040502030405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
124c242424242424242424242424242424242424242424242424242131242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022424243b24242424242424242424242424242424242424243b243121243105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224222424242424242424242424242424242424242424242424242433242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02242431242424242424242424242424242424242424242424243b2433302405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
122424242424244c242424242424242424242424242424242424242424312415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0230242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224242424242424242424242424242424242424242424242424242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
12242420242424242424242424242424242424242424242424242424243b2415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
023b242424242424242424242424242424242424242424242124242424242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1224242424242424242424242424242424242424242424242424242424312415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02242324243b2424242424242424242424242424242424242424242324242405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
12322424242432242424242424242424242424242424242424213b2421242415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224244c24242424242424242424242424242424242424242424242424243105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213141512131415121314151213141512131415121314151213141512131415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001d0301f000000001b03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001d2501325024050000001b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001b0500f1501b0500f1501b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000036300363005630076300c63011630166301f630276302e630296302763024630226301b6200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002405029050166001b4500a6000a6000560007600056000560005600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001345013450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001f6501d6501d6501b6501b65013650116500f6500f6500f6501165011650096500c6500c6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002733027320000002733016300163301633000000163200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600002e4502e4002e430000002e410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000350503a0503305000000270502b050240500000000000130501605011050000001d050220501f05000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001105011050110500c0500c0500c0500000007050070500705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000c0530c300000000c300170530c30000000000000c053000000c05300000170531030010300000000c053000000000000000170531130011300113000c0530c0530c0530c053170530e3000c0530e300
010f00000005000050000000000000000000000705007050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f0000000500005000000000000000000000070500705000000000000c0500c0500905009050000000000009050090500000000000090500905000000000000205002050020500205002050000000205000000
010f00000000000000000500000000000000000005000000000000000000050000000000000000000500000000000000500000000050103100000000310000000b21000000093100000000000000000000000000
010f000000000000000000000000000000000000000000000000000000000000000000000000000000000000103101031000000103100e3100000010310000000e210000000c3100000000000073100000007310
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 40400c0b
00 40400d0b
00 40400c0b
00 40400d0b
00 400e0c0b
02 400f0d0b
03 4040400b
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000


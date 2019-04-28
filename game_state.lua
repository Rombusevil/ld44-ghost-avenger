function game_state(lvl)
    local s={}
    local updas={}
    local draws={}
    local spawns={}
    local zmbs={}
    local clos={}
    local shake=0
    local exp=circle_explo()
    local zkills=0  -- zombies killed
    local bt=0      -- bomb trigger
    local bf=true   -- bomb fuse
    local t=0       -- ticker
    local ct=0      -- clock trigger
    local p=0       -- points

    function sword(x,y,h)
        local anim_obj=anim()
        anim_obj:add(52,1,1,1,1) --idle
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)

        ad=function()
            h:stop_atk()
            e:set_anim(1) -- idle
            e:setx(h.x)
            e:sety(h.y)
        end
        anim_obj:add(84,4,0.75,1,2,true,ad) --attacking
    
        local bounds_obj=bbox(8,16, 0,0,0,4)
        e:set_bounds(bounds_obj)
        --e.debugbounds=true
        e.dmg=1
        
        function e:update()
            local xo=0
            local yo=0
            local fx=1
            if(h.flipx)fx=-1

            if h.atk then
                xo=8*fx
                yo=-3

                -- kill zombies
                for z in all(zmbs) do
                    if collides(z,e) then
                        z:hurt(e.dmg)
                    end
                end

                -- kill spawners
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
        anim_obj:add(64,7,0.05,1,1) -- idle
        anim_obj:add(55,4,0.3,1,1)  -- run
        anim_obj:add(88,1,0.3,1,1)  -- attack
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(8,8,1,0,2,0)
        e:set_bounds(bounds_obj)
        e.debugbounds=false
        e.mhealth=10 -- max health
        e.health=10
        e.atk=false  -- is attacking
        e.swrd=sword(x,y,e)
        
        function e:update()
            if e.health <= 0 then
                curstate=gameover_state(p,zkills,false)
            end

            -- movement
            if not e.atk then
                local s=1
                if btn(0) then     --left
                    e:setx(e.x-s)
                    e.flipx=true
                elseif btn(1) then --right
                    e:setx(e.x+s)
                    e.flipx=false
                end
                
                if btn(2) then      --up
                    e:sety(e.y-s)
                elseif btn(3) then  --down
                    e:sety(e.y+s)
                end
            end
            
            -- Check for wall collision
            if(e.x < 8)e:setx(8)
            if(e.x > 240)e:setx(240)
            if(e.y<8)e:sety(8)
            if(e.y>112)e:sety(112)
            -- -
            
            if btnp(4) then -- "O"
                -- Explode everyone with ghost's health
                if g.health > g.mhealth/4 then
                    shake=15
                    for z in all(zmbs) do
                        z:hurt(100)
                    end
                                        
                    g:hurt(g.mhealth/4)
                    sfx(6)
                end
            end
            
            if btnp(5) then -- "X"
                if(not e.atk)sfx(3)
                e.atk=true
                e.swrd:atk()
                e:set_anim(3) -- attack
            end

            if not e.atk then
                if btn(0)or btn(1)or btn(2)or btn(3) then 
                    e:set_anim(2) -- run
                else
                    e:set_anim(1) -- idle
                end
            end

            e.swrd:update()
        end

        e._draw=e.draw
        function e:draw()
            if(not e.atk)e.swrd:draw()
            e:_draw()
            if(e.atk)e.swrd:draw()

            -- Draw life bar
            local hbl=7 -- health bar length (in px)
            local hb=e.health*hbl/e.mhealth --health bar
            rectfill(e.x,e.y-4, e.x+hbl, e.y-3, 8)
            rectfill(e.x,e.y-4, e.x+hb,  e.y-3, 3)
            -- 
        end

        function e:stop_atk()
            e.atk=false   -- set idle anim
        end

        function e:hurt(dmg)
            if not self.flickerer.is_flickering then
                e:flicker(10)
                if(e.health>0)e.health-=dmg
                sfx(1)
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
        e.mhealth=100 -- max health
        e.health=100
        e.tick=0
    
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true
        
        function e:update()
            e.tick+=0.1
            if e.health <= 0 then
                curstate=gameover_state(p,zkills,true)
            end

            if e.health<=e.mhealth and e.tick > 50 then
                e.tick=0
                e.health+=1 -- health regen
            end
        end

        e._draw=e.draw
        function e:draw()
            spr(6, x,y+8, 2, 2) -- altar
            e:_draw()    -- ghost
            local hbl=15 -- health bar length (in px)
            local hb=e.health*hbl/e.mhealth --health bar
            rectfill(x,y-2, x+hbl, y-1, 8)
            rectfill(x,y-2, x+hb,  y-1, 3)
        end

        function e:hurt(dmg)
            if not self.flickerer.is_flickering then
                e:flicker(4)
                if(e.health>0)e.health-=dmg
                sfx(2)
            end
        end

        return e
    end

    function zombie(x,y,h,g)
        -- @args: x,y, hero, ghost
        local anim_obj=anim()
        anim_obj:add(39,4,0.2,1,1) -- walk
        anim_obj:add(71,4,0.1,1,1) -- idle/confused
        anim_obj:add(80,4,0.3,1,1) -- attack
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        add(zmbs, e)
    
        local bounds_obj=bbox(8,8,1,0,2,0)
        e:set_bounds(bounds_obj)
        e.debugbounds=false
        e.dmg=0.4   -- damage
        e.arr=false -- arrived to destination
        e.ct=5      -- cool off timer
        e.tick=0
        e.hp=3      -- hit points
        e.fr=false  -- freezed
        
        function e:update()
            if e.hp <= 0 then
                del(updas, e)
                del(draws, e)
                del(zmbs, e)
                -- TOOD MAKE DEATH SOUND
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
                local s=0.3 -- speed
        
                -- zombie center
                local cx=e.x+4
                local cy=e.y+4
                -- 
                local dy=abs(cy-(h.y+4))
                local dx=abs(cx-(h.x+4))
                local m=max(dy,dx)  dy=dy/m  dx=dx/m
                local hd=abs(sqrt((dy*dy)+(dx*dx)))  -- hero distance

                dy=cy-(g.y+16)
                dx=cx-(g.x+8)
                m=max(dy,dx)  dy=dy/m  dx=dx/m
                local gd=abs(sqrt((dy*dy)+(dx*dx)))  -- ghost distance

                -- target: hero or ghost?
                local t=h   -- target obj
                local d=hd  -- distance to target
                local tx=h.x+4 
                local ty=h.y+4
                if hd > gd or (h.x< 64 and e.x > 128)then
                    t=g  d=gd
                    tx=g.x+8  ty=g.y+16
                end

                -- movement towards target
                if(e.arr)e.tick+=0.1
                if e.tick > e.ct then
                    e.tick=0  e.arr=false 
                    e:set_anim(1) -- walk
                end

                if not self.flickerer.is_flickering then
                    if abs(e.x-tx)<=7 and abs(e.y-ty)<=7 then
                        e.arr=true    -- arrived
                        e:set_anim(3) -- attack
                        t:hurt(e.dmg)
                    elseif not e.arr then
                        -- move to target
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
                        -- in cool off mode, but not close to target
                        e:set_anim(2) -- idle
                    end
                else
                    e:set_anim(2) -- idle/confused
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
        -- @args: x,y, hero, frequency for spawning, ghost

        local anim_obj=anim()
        anim_obj:add(37,1,0.1,2,2)
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
            
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true

        e.tick=0
        e.f=0       -- fuse
        e.co=fq+10  -- cool off time
        e.fr=false  -- freezed
        e.health=250
        e.mhealth=250
        
        function e:update()
            if e.health <=0 then
                exp:multiexplode(e.x,e.y)
                shake=10
                del(updas,e)
                del(draws,e)
                del(spawns,e)
                p+=100
            end

            if not e.fr then
                e.tick+=0.1
                if e.tick > fq then
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

            -- Draw life bar
            local hbl=15 -- health bar length (in px)
            local hb=e.health*hbl/e.mhealth --health bar
            rectfill(e.x,e.y-3, e.x+hbl, e.y-2, 8)
            rectfill(e.x,e.y-3, e.x+hb,  e.y-2, 3)
            -- 
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
        -- e.debugbounds=true
        
        function e:update()
            if e.kill then
                del(updas, e)
                del(draws, e)
                bt=0
                bf=true
                p+=10
            end

            -- if collides with hero explode
            if collides(h,e) then
                exp:multiexplode(e.x,e.y)
                shake=10
                for z in all(zmbs) do
                    z:hurt(100)
                end
                e.kill=true -- defer killing to next tick
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
        e.f=true    -- fuse
        e.t=0
        e.expiry=200 -- expiry time/ freeze time in ticks
        
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

        -- Spawn Bomb
        if bt > 10 and bf then
            bf = false
            local xx=rnd(40)+100
            local yy=rnd(40)+70
            local b=bomb(xx,yy,h) add(updas,b) add(draws,b)
        end

        -- Spawn Freeze Clock
        if ct > 20 and #clos==0 then
            local xx=rnd(32)+192
            local yy=rnd(40)+70
            local c=clock(xx,yy,h) add(updas,c) add(draws,c) add(clos, c)
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

        -- hud
        camera(0,0)
        rectfill(1,0,50,6, 0)
        print("kills: "..zkills,2,1,7)

        rectfill(69,0,120,6, 0)
        print("points: "..p,70,1,7)
    end

    -- y sort draws 
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

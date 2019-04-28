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
        e.mhealth=10 -- max health
        e.health=10
        
        function e:update()
            if e.health <= 0 then
                -- GAME OVER SCREEN
            end

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

            -- Check for moving bounds
            if(e.x < 8)e:setx(8)
            if(e.x > 240)e:setx(240)
            if(e.y<8)e:sety(8)
            if(e.y>112)e:sety(112)
            -- -
            
            if btnp(4) then -- "O"
            
            end
            
            if btnp(5) then -- "X"
            
            end

            if btn(0)or btn(1)or btn(2)or btn(3) then 
                e:set_anim(2)
            else
                e:set_anim(1)
            end

        end

        e._draw=e.draw
        function e:draw()
            e:_draw()
            -- Draw life bar
            local hbl=7 -- health bar length (in px)
            local hb=e.health*hbl/e.mhealth --health bar
            rectfill(e.x,e.y-4, e.x+hbl, e.y-3, 9)
            rectfill(e.x,e.y-4, e.x+hb,  e.y-3, 3)
        end

        return e
    end

    function zombie(x,y,h,g)
        -- @args: x,y, hero, ghost
        local anim_obj=anim()
        anim_obj:add(39,4,0.2,1,1) -- walk
        anim_obj:add(71,4,0.1,1,1) -- idle/confused
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(8,8,1,0,2,0)
        e:set_bounds(bounds_obj)
        e.debugbounds=false
        e.arr=false -- arrived to destination
        e.ct=5      -- cool off timer
        e.tick=0
        
        function e:update()
            local s=0.3 -- speed
      
            -- zombie center
            local cx=e.x+4
            local cy=e.y+4

            local dy=cy-(h.y+4)
            local dx=cx-(h.x+4)
            local hd=abs(sqrt((dy*dy)+(dx*dx)))  -- hero distance
            dy=cy-(g.y+16)
            dx=cx-(g.x+8)
            local gd=abs(sqrt((dy*dy)+(dx*dx)))  -- ghost distance

            -- target: hero or ghost?
            local tx=h.x+4 
            local ty=h.y+4
            local d=hd
            if hd > gd then
                tx=g.x+8
                ty=g.y+16
                d=gd
            end

            -- movement towards target
            if(e.arr)e.tick+=0.1
            if e.tick > e.ct then
                e.tick=0  e.arr=false 
                e:set_anim(1) -- walk
            end

            if d <= 2 then -- arrived
                e.arr=true
                -- ATTACK ANIM
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
        end

        -- e._draw=e.draw
        -- function e:draw()
        --     e:_draw()    -- ghost
        -- end

        return e
    end
    
    function spawner(x,y,h,fq,g)
        -- @args: x,y, hero, frequency for spawning, ghost

        local anim_obj=anim()
        anim_obj:add(37,1,0.1,2,2)
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)

        e.tick=0
        e.f=0       -- fuse
        e.co=fq+30  -- cool off time
            
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true
        
        function e:update()
            e.tick+=0.1
            if e.tick > fq then
                if e.f == 0 then
                    local z=zombie(x,y,h,g) add(updas,z) add(draws,z)
                end

                e.f=1

                if e.tick > e.co then 
                    e.tick=0
                    --e.f=0 TODO: DEBUG
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
        e.mhealth=100 -- max health
        e.health=100
    
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true
        
        function e:update()
            
        end

        e._draw=e.draw
        function e:draw()
            spr(6, x,y+8, 2, 2) -- altar
            e:_draw()    -- ghost
            local hbl=15 -- health bar length (in px)
            local hb=e.health*hbl/e.mhealth --health bar
            rectfill(x,y-2, x+hbl, y-1, 9)
            rectfill(x,y-2, x+hb,  y-1, 3)
        end
        return e
    end
    
    local h = hero(10,10) add(updas, h) add(draws, h)
    local g = ghost(120,48) add(updas, g) add(draws, g)

    local sp1 = spawner(16,16,h,5,g)   add(updas, sp1) add(draws, sp1)
    -- local sp2 = spawner(224,16,h,7,g)  add(updas, sp2) add(draws, sp2)
    -- local sp3 = spawner(224,96,h,11,g) add(updas, sp3) add(draws, sp3)
    -- local sp4 = spawner(16,96,h,6,g)   add(updas, sp4) add(draws, sp4)

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

    return s
end
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
                -- GAME OVER SCREEN
            end

            local s=1
            local im=btn(0)or btn(1)or btn(2)or btn(3)
            if btn(0) then     --left
                e:setx(e.x-s)
                e.flipx=true
            elseif btn(1) then --right
                e:setx(e.x+s)
                e.flipx=false
            end
            
            if btn(2) then          --up
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
            local s=0.3 -- speed
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
        -- @args: x,y, hero, frequency for spawning

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
        e.mhealth=100 -- max health
        e.health=80
    
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
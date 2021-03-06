-- state
function instructions_state()
    local s={}
    local texts={}
	
	-- graphical frame 
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
        if(btnp(5)) curstate=game_state() -- "X"
    end

    cls()
    s.draw=function()
        -- bkg
        dance_bkg(10,frbkg)
        
        -- frame
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        -- white frame
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        -- black frame
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        -- main frame
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
                
        -- draw texts
		msg.text = cmsg

        for t in all(texts) do
            t:draw()
        end
    end

    return s
end
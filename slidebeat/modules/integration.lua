local I={}
I.__index=I
local host=game
local Main=MainMenuState
local Freeplay=FreeplayState
local Base=State
local meta=getmetatable
local setmeta=setmetatable
local pairs_=pairs
local remove=table.remove
local min=math.min
function I.new(id)
    local self=setmetatable({id=id,freeplays=setmetatable({},{__mode='k'}),menus=setmetatable({},{__mode='k'}),active=true},I)
    self.Profile=requireAddon(id,'profile')
    self.Mode=requireAddon(id,'state').create(id)
    return self
end
function I:lobby() host.switchState(self.Mode(self,'home')) end
function I:select()
    self.selecting=true
    host.switchState(Freeplay())
end
function I:beforeState(st)
    if not self.active then return end
    if st.is and st:is(Main) then self.selecting=false end
    if self.selecting and st.is and st:is(Freeplay) and not self.freeplays[st] then
        local originalOpen,originalDiff=st.openSong,st.changeDiff
        self.freeplays[st]={openSong=originalOpen,changeDiff=originalDiff}
        local owner=self
        st.openSong=function(selection,song)
            if not owner.active then return originalOpen(selection,song) end
            local difficulty=tostring(song.diffs[Freeplay.curDifficulty] or 'normal'):lower()
            host.switchState(owner.Mode(owner,'song',{song=song.songName,difficulty=difficulty,metadata=song.meta}))
            return true
        end
        st.changeDiff=function(selection,change)
            originalDiff(selection,change)
            if not selection.songs or #selection.songs.members==0 then return end
            local song=selection.songs:getSelected()
            local difficulty=tostring(song.diffs[Freeplay.curDifficulty] or 'normal'):lower()
            local record=owner.Profile.get().records[owner.Profile.key(song.songName,difficulty)]
            selection.intendedScore=record and record.score or 0
        end
    end
end
function I:update()
    if not self.active then return end
    local st=host.getState()
    if st and st.is and st:is(Main) and st.menuList and not self.menus[st] then
        self.menus[st]=true
        local owner=self
        st:addMenuButton('slidebeat','SlideBeat',function() owner:lobby() return true end,{useText=true,stay=true})
    end
end
function I:dispose()
    if not self.active then return end
    self.active=false
    for st,saved in pairs_(self.freeplays) do
        st.openSong,st.changeDiff=saved.openSong,saved.changeDiff
        if st.songs then
            local original=saved.openSong
            st.songs.selectCallback=function(song) return original(st,song) end
        end
    end
    for st in pairs_(self.menus) do
        if st.menuList then
            for i=#st.menuItems,1,-1 do
                if st.menuItems[i]=='slidebeat' then
                    remove(st.menuItems,i)
                    local item=remove(st.menuList.members,i)
                    if item and item.destroy then item:destroy() end
                end
            end
            for i,item in pairs_(st.menuList.members) do item.ID=i end
            st.menuList.curSelected=min(st.menuList.curSelected,#st.menuList.members)
            if st.triggerChoices then st.triggerChoices.slidebeat=nil end
        end
    end
    local current=host.getState()
    if current and meta(current)==self.Mode then
        current:dispose()
        setmeta(current,Base)
        host.switchState(Main(),true)
    end
    self.selecting=false
end
return I

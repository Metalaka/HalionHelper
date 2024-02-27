local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.corporeality.ui = module

function module:Initialize()

    local CORPOREALITY_DURATION = 15
    local DELAY_AFTER_NEW_CORPOREALITY = 1 -- 1s of freeze after new corporeality
    local checkTimer = 7 -- send a message at this remaining time, todo config

    local core = AddOn.modules.corporeality.core
    local uiHelper = AddOn.modules.bar
    
    local dto = nil

    -- functions

    local function OnUpdateColor(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < AddOn.SLEEP_DELAY or frame.elapsed < (frame.startDelay or 0) then
            return
        end

        frame.elapsed = 0
        frame.startDelay = 0

        if core:HasData() then
            
            dto = core:BuildDto()
            local r, g, b = unpack(dto.states[dto.side].color)

            frame:SetValue(1)
            frame:SetStatusBarColor(r, g, b)
            frame.timeText:SetText(dto.amount .. " - " .. dto.states[dto.side].message)
        else
            frame:SetValue(0)
            frame.timeText:SetText("")
        end
    end

    local function OnUpdateTimer(frame, elapsed)

        frame.remaining = (frame.remaining or 0) - elapsed
        if frame.remaining < 0 and UnitAffectingCombat('player') then
            -- Sometimes the corporeality doesn't update, tracking is restarted by this hack
            AddOn:Print("NewCorporeality hack")
            core:NewCorporeality(AddOn.NPC_ID_HALION_PHYSICAL, core.corporeality[AddOn.NPC_ID_HALION_PHYSICAL])
            core:NewCorporeality(AddOn.NPC_ID_HALION_TWILIGHT, core.corporeality[AddOn.NPC_ID_HALION_TWILIGHT])

            return
        end

        -- send RAID_WARNING if we must stop
        if AddOn:IsElected() and not (frame.triggered or false) and frame.remaining < checkTimer then
            
            if dto ~= nil and core:ShouldStop(dto) and UnitAffectingCombat('player') then
                
                frame.triggered = true
                core:SendStopMessage(dto)
            end
        end

        frame:SetValue(frame.remaining)
    end

    -- frame

    local uiFrame = CreateFrame("Frame", AddOn.NAME .. "_corporeality_uiFrame", UIParent)
    self.uiFrame = uiFrame -- used by slashCommands
    uiFrame:Hide()
    uiFrame:SetPoint(AddOn.db.profile.ui.origin, AddOn.db.profile.ui.x, AddOn.db.profile.ui.y)
    uiFrame:SetSize(170, 30)

    -- main bar with color
    local colorBar = uiHelper:NewBar(AddOn.NAME .. "_corporeality_corporealityBar", uiFrame)
    colorBar:SetPoint("TOP")
    colorBar:SetHeight(25)
    colorBar:SetValue(1)

    -- timer that indicate the next corporeality
    local timer = uiHelper:NewBar(AddOn.NAME .. "_corporeality_Timer", uiFrame)
    timer:SetPoint("BOTTOM")
    timer:SetHeight(5)

    -- public API

    function self:StartTimer(time)
        timer.triggered = false
        timer.remaining = time
        timer:SetMinMaxValues(0, time)
        timer:SetValue(time)

        if not uiFrame:IsShown() then
            uiFrame:Show()
        end
    end

    function self:StopTimer()
        uiFrame:Hide()
    end

    function self:StartMonitor()

        colorBar.startDelay = DELAY_AFTER_NEW_CORPOREALITY
        self:StartTimer(CORPOREALITY_DURATION)
    end

    --

    function self:Enable()
        colorBar:SetScript("OnUpdate", OnUpdateColor)
        timer:SetScript("OnUpdate", OnUpdateTimer)
    end

    function self:Disable()
        colorBar:SetScript("OnUpdate", nil)
        timer:SetScript("OnUpdate", nil)
        self:StopTimer()
    end
end

local _, ns = ...

local AddOn = ns.AddOn
local module = {
    dto = nil
}
AddOn.modules.corporeality.ui = module
local L = ns.L

function module:Initialize()

    local CORPOREALITY_DURATION = 15
    local DELAY_AFTER_NEW_CORPOREALITY = 1 -- 1s of freeze after new corporeality
    local preferGoTwilight = true -- goal is 60-50 in twilight, todo config
    local checkTimer = 7 -- send a message at this remaining time, todo config

    local core = AddOn.modules.corporeality.core
    local uiHelper = AddOn.modules.bar

    -- functions

    local function GetOtherSide(side)
        return side == AddOn.NPC_ID_HALION_PHYSICAL and AddOn.NPC_ID_HALION_PHYSICAL or AddOn.NPC_ID_HALION_TWILIGHT
    end
    
    local function HasData()
        return core.amount[AddOn.NPC_ID_HALION_PHYSICAL] > 0
                and core.amount[AddOn.NPC_ID_HALION_TWILIGHT] > 0
    end

    local function GetSideThatMustPush()

        local physicalCorporeality = core.corporeality[AddOn.NPC_ID_HALION_PHYSICAL]

        -- more damage to go to 50%
        if physicalCorporeality.dealt > 1 then
            return AddOn.NPC_ID_HALION_PHYSICAL
        end

        if physicalCorporeality.dealt < 1 then
            return AddOn.NPC_ID_HALION_TWILIGHT
        end

        -- more damage according to our preference if 50%
        if preferGoTwilight then
            return AddOn.NPC_ID_HALION_PHYSICAL
        else
            return AddOn.NPC_ID_HALION_TWILIGHT
        end
    end

    local function GetSideWithMoreDamage()

        return core.amount[AddOn.NPC_ID_HALION_PHYSICAL] > core.amount[AddOn.NPC_ID_HALION_TWILIGHT]
                and AddOn.NPC_ID_HALION_PHYSICAL
                or AddOn.NPC_ID_HALION_TWILIGHT
    end

    -- return the damage diff between both realm
    local function GetAmount(side)

        local amount = core.amount[side] - core.amount[GetOtherSide(side)]

        amount = amount / 1000

        if math.abs(amount) > 1000 then
            return string.format("%.1f M", amount / 1000)
        end

        return string.format("%.0f K", amount)
    end

    local function GetColor(side)
        local sideThatMustPush = GetSideThatMustPush()
        local sideWithMoreDamage = GetSideWithMoreDamage()

        if sideThatMustPush == sideWithMoreDamage then
            -- green - continue
            return core.states.push
        end

        if sideThatMustPush == side then
            -- blue - do more, others have red
            return core.states.pushMore
        end

        -- red - stop
        return core.states.stop
    end

    local function ShouldStop(dto)
        return HasData()
                and (dto.states[AddOn.NPC_ID_HALION_PHYSICAL] == core.states.stop
                or dto.states[AddOn.NPC_ID_HALION_TWILIGHT] == core.states.stop)
    end

    local function SendStopMessage(dto)
        local channel = ns.HasRaidWarningRight() and "RAID_WARNING" or "RAID"
        local sideName = dto.states[AddOn.NPC_ID_HALION_PHYSICAL] == core.states.stop and L["Physical"] or L["Twilight"]

        AddOn:Print(string.format(L["AnnounceStop"], sideName))
        --SendChatMessage(string.format(L["AnnounceStop"], sideName), channel)
    end

    local function BuildDto()

        local dto = {
            -- amount as formatted string
            -- our corporeality (not yet used) - display value
            --- our side
            -- states (color, message) - send message to ppl without addon
            --- sideWithMoreDamage
            --- ShouldDoMoreDamage
        }

        dto.side = ns.IsInTwilightRealm() and AddOn.NPC_ID_HALION_TWILIGHT or AddOn.NPC_ID_HALION_PHYSICAL
        dto.corporeality = core.corporeality[dto.side]
        dto.amount = GetAmount(dto.side) -- formatted
        dto.states = {
            [AddOn.NPC_ID_HALION_PHYSICAL] = GetColor(AddOn.NPC_ID_HALION_PHYSICAL),
            [AddOn.NPC_ID_HALION_TWILIGHT] = GetColor(AddOn.NPC_ID_HALION_TWILIGHT),
        }

        return dto
    end

    local function OnUpdateColor(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < AddOn.SLEEP_DELAY or frame.elapsed < (frame.startDelay or 0) then
            return
        end

        frame.elapsed = 0
        frame.startDelay = 0

        if HasData() then
            
            module.dto = BuildDto()
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
        if module.dto ~= nil and
                AddOn:IsElected() and
                not (frame.triggered or false) and
                frame.remaining < checkTimer then
            
            if ShouldStop(module.dto) then
                
                frame.triggered = true
                SendStopMessage(module.dto)
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

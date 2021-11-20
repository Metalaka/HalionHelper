local mod = _G.HalionHelper

mod.modules.corporeality.ui = {
    minDiff = 0.05, -- todo config
    iconsSets = {
        ["REALM"] = {
            --            twilight = 75486, -- Dusk Shroud
            twilight = 74807, -- Twilight Realm
            physical = 75949, -- Meteor Strike
        },
        ["SPELL"] = {
            twilight = 77846, -- Twilight Cutter
            physical = 75887, -- Blazing Aura
        },
    },
    shouldDoMoreDamage = true,
    preferGoTwilight = true, -- goal is 60-50 in twilight, todo config
    checkTimer = 7, -- send a message at this remaining time, todo config
}

function mod.modules.corporeality.ui:Initialize()

    function self:Enable()
    end

    function self:Disable()
        self:StopTimer()
    end

    --

    local CORPOREALITY_DURATION = 15
    local DELAY_AFTER_NEW_CORPOREALITY = 1 -- 1s of freeze after new corporeality

    local _self = self
    local core = mod.modules.corporeality.core
    local uiHelper = mod.modules.bar
    local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

    -- functions

    local function IsInPhysical()
        return core.side.npcId == mod.NPC_ID_HALION_PHYSICAL
    end

    local function IsInTwilight()
        return core.side.npcId == mod.NPC_ID_HALION_TWILIGHT
    end

    --- Changes icons depending of which side take more damage
    local function UpdateIcons(uiFrame)

        if core.side.corporeality.dealt == 1 then
            uiHelper:SetIcon(uiFrame.left, _self.iconsSets[mod.db.profile.iconsSet].twilight)
            uiHelper:SetIcon(uiFrame.right, _self.iconsSets[mod.db.profile.iconsSet].physical)
        elseif (IsInTwilight() and core.side.corporeality.dealt > 1)
                or (IsInPhysical() and core.side.corporeality.dealt < 1) then
            uiHelper:SetIcon(uiFrame.left, _self.iconsSets[mod.db.profile.iconsSet].twilight)
            uiHelper:SetIcon(uiFrame.right, _self.iconsSets[mod.db.profile.iconsSet].twilight)
        else
            uiHelper:SetIcon(uiFrame.left, _self.iconsSets[mod.db.profile.iconsSet].physical)
            uiHelper:SetIcon(uiFrame.right, _self.iconsSets[mod.db.profile.iconsSet].physical)
        end
    end

    local function HasData()
        return core.amount[mod.NPC_ID_HALION_PHYSICAL] > 0
                and core.amount[mod.NPC_ID_HALION_TWILIGHT] > 0
    end

    local function ShouldDoMoreDamage()
        local corporeality = core.side.corporeality

        -- more damage to go to 50%
        if corporeality.dealt > 1 then
            return true
        elseif corporeality.dealt < 1 then
            return false
        end

        -- more damage according to our preference if 50%
        if (IsInTwilight() and core.preferGoTwilight)
                or (IsInPhysical() and not core.preferGoTwilight) then
            return false
        else
            return true
        end
    end

    local function IsMoreDamageOurSide()

        local sideWithMoreDamage = core.amount[mod.NPC_ID_HALION_PHYSICAL] > core.amount[mod.NPC_ID_HALION_TWILIGHT]
                and mod.NPC_ID_HALION_PHYSICAL
                or mod.NPC_ID_HALION_TWILIGHT

        return sideWithMoreDamage == core.side.npcId
    end

    local function GetAmount()

        local amount = IsInPhysical()
                and (core.amount[mod.NPC_ID_HALION_PHYSICAL] - core.amount[mod.NPC_ID_HALION_TWILIGHT])
                or (core.amount[mod.NPC_ID_HALION_TWILIGHT] - core.amount[mod.NPC_ID_HALION_PHYSICAL])

        amount = amount / 1000

        if amount > 1000 then
            return string.format("%.1f M", amount / 1000)
        end

        return string.format("%.0f K", amount)
    end

    local function GetColor()
        local isMoreDamageOurSide = IsMoreDamageOurSide()

        if (_self.shouldDoMoreDamage and isMoreDamageOurSide)
                or (not _self.shouldDoMoreDamage and not isMoreDamageOurSide) then
            -- green - continue
            return 0, 1, 0
        end

        if _self.shouldDoMoreDamage and not isMoreDamageOurSide then
            -- blue - do more, others have red
            return 0, 0, 1
        end

        if not _self.shouldDoMoreDamage and isMoreDamageOurSide then
            -- red - stop
            return 1, 0, 0
        end
    end

    local function IsDifferenceGreaterThanExpected()

        local master = core.amount[mod.NPC_ID_HALION_PHYSICAL] > core.amount[mod.NPC_ID_HALION_TWILIGHT]
                and mod.NPC_ID_HALION_PHYSICAL
                or mod.NPC_ID_HALION_TWILIGHT
        local other = master == mod.NPC_ID_HALION_TWILIGHT and mod.NPC_ID_HALION_PHYSICAL or mod.NPC_ID_HALION_TWILIGHT

        return (core.amount[master] / (core.amount[other] or 1)) >= (1 + _self.minDiff)
    end

    local function GetColorWithDetail()
        local diff = IsDifferenceGreaterThanExpected()
        local isMoreDamageOurSide = IsMoreDamageOurSide()

        if (_self.shouldDoMoreDamage and isMoreDamageOurSide and diff)
                or (not _self.shouldDoMoreDamage and not isMoreDamageOurSide and diff) then
            -- green - continue
            return 0, 1, 0
        end

        if _self.shouldDoMoreDamage and isMoreDamageOurSide and not diff then
            -- purple - ok but not safe
            return 1, 0, 1
        end

        if _self.shouldDoMoreDamage and not isMoreDamageOurSide then
            -- blue - do more, others have red
            return 0, 0, 1
        end

        if not _self.shouldDoMoreDamage and isMoreDamageOurSide then
            -- red - stop
            return 1, 0, 0
        end

        if not _self.shouldDoMoreDamage and not isMoreDamageOurSide and not diff then
            -- orange - ok but not safe, slow
            return 1, 0.95, 0
            -- orange (1, 0.6, 0.05)
        end
    end

    local function ShouldStop()
        return HasData()
                and not _self.shouldDoMoreDamage
                and IsMoreDamageOurSide()
                and core.side.corporeality.dealt ~= 1
    end

    local function SendStopMessage()
        local channel = mod:HasRaidWarningRight() and "RAID_WARNING" or "RAID"
        local sideName = IsInPhysical() and L["Physical"] or L["Twilight"]

        SendChatMessage(string.format(L["AnnounceStop"], sideName), channel)
    end

    local function OnUpdateColor(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < mod.SLEEP_DELAY or frame.elapsed < (frame.startDelay or 0) then
            return
        end

        frame.elapsed = 0
        frame.startDelay = 0

        if HasData() then
            local r, g, b = GetColor()

            frame:SetValue(1)
            frame:SetStatusBarColor(r, g, b)
        else
            frame:SetValue(0)
            --frame.timeText:SetText("…")
        end

        frame.timeText:SetText(GetAmount())
    end

    local function OnUpdateTimer(frame, elapsed)

        frame.remaining = (frame.remaining or 0) - elapsed
        if frame.remaining < 0 then
            return
        end

        -- send AR if we must stop
        if not (frame.triggered or false) and frame.remaining < _self.checkTimer and ShouldStop() then
            frame.triggered = true
            SendStopMessage()
        end

        frame:SetValue(frame.remaining)
    end

    -- frame

    local uiFrame = CreateFrame("Frame", mod.ADDON_NAME .. "_corporeality_uiFrame", UIParent)
    self.uiFrame = uiFrame -- used by slashCommands
    uiFrame:Hide()
    uiFrame:SetPoint(mod.db.profile.ui.origin, mod.db.profile.ui.x, mod.db.profile.ui.y)
    uiFrame:SetSize(170 + 60, 30)

    uiFrame.left = CreateFrame("Button", nil, uiFrame)
    uiFrame.left:SetHeight(30)
    uiFrame.left:SetWidth(30)
    uiFrame.left:SetPoint("LEFT")
    uiHelper:SetIcon(uiFrame.left, _self.iconsSets[mod.db.profile.iconsSet].twilight)
    uiFrame.left:EnableMouse(false)

    uiFrame.right = CreateFrame("Button", nil, uiFrame)
    uiFrame.right:SetHeight(30)
    uiFrame.right:SetWidth(30)
    uiFrame.right:SetPoint("RIGHT")
    uiHelper:SetIcon(uiFrame.right, _self.iconsSets[mod.db.profile.iconsSet].physical)
    uiFrame.right:EnableMouse(false)

    -- main bar with color
    local colorBar = uiHelper:NewBar(mod.ADDON_NAME .. "_corporeality_corporealityBar", uiFrame)
    colorBar:SetPoint("TOP")
    colorBar:SetHeight(25)
    colorBar:SetValue(1)

    -- timer that indicate the next corporeality
    local timer = uiHelper:NewBar(mod.ADDON_NAME .. "_corporeality_Timer", uiFrame)
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

        _self.shouldDoMoreDamage = ShouldDoMoreDamage()
        colorBar.startDelay = DELAY_AFTER_NEW_CORPOREALITY
        UpdateIcons(uiFrame)

        self:StartTimer(CORPOREALITY_DURATION)
    end

    -- init OnUpdate

    colorBar:SetScript("OnUpdate", OnUpdateColor)
    timer:SetScript("OnUpdate", OnUpdateTimer)
end

local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.corporeality.ui = module
local L = ns.L

function module:Initialize()

    local CORPOREALITY_DURATION = 15
    local DELAY_AFTER_NEW_CORPOREALITY = 1 -- 1s of freeze after new corporeality
    local minDiff = 0.05 -- todo config
    local preferGoTwilight = true -- goal is 60-50 in twilight, todo config
    local checkTimer = 7 -- send a message at this remaining time, todo config
    local iconsSet = {
        ["REALM"] = {
            --            twilight = 75486, -- Dusk Shroud
            twilight = 74807, -- Twilight Realm
            physical = 75949, -- Meteor Strike
        },
        ["SPELL"] = {
            twilight = 77846, -- Twilight Cutter
            physical = 75887, -- Blazing Aura
        },
    }
    local shouldDoMoreDamage = true

    local core = AddOn.modules.corporeality.core
    local uiHelper = AddOn.modules.bar

    -- functions

    local function IsInPhysical()
        return core.side.npcId == AddOn.NPC_ID_HALION_PHYSICAL
    end

    local function IsInTwilight()
        return core.side.npcId == AddOn.NPC_ID_HALION_TWILIGHT
    end

    --- Changes icons depending of which side take more damage
    local function UpdateIcons(uiFrame)

        if core.side.corporeality.dealt == 1 then
            uiHelper:SetIcon(uiFrame.left, iconsSet[AddOn.db.profile.iconsSet].twilight)
            uiHelper:SetIcon(uiFrame.right, iconsSet[AddOn.db.profile.iconsSet].physical)
        elseif (IsInTwilight() and core.side.corporeality.dealt > 1)
                or (IsInPhysical() and core.side.corporeality.dealt < 1) then
            uiHelper:SetIcon(uiFrame.left, iconsSet[AddOn.db.profile.iconsSet].twilight)
            uiHelper:SetIcon(uiFrame.right, iconsSet[AddOn.db.profile.iconsSet].twilight)
        else
            uiHelper:SetIcon(uiFrame.left, iconsSet[AddOn.db.profile.iconsSet].physical)
            uiHelper:SetIcon(uiFrame.right, iconsSet[AddOn.db.profile.iconsSet].physical)
        end
    end

    local function HasData()
        return core.amount[AddOn.NPC_ID_HALION_PHYSICAL] > 0
                and core.amount[AddOn.NPC_ID_HALION_TWILIGHT] > 0
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
        if (IsInTwilight() and preferGoTwilight)
                or (IsInPhysical() and not preferGoTwilight) then
            return false
        else
            return true
        end
    end

    local function IsMoreDamageOurSide()

        local sideWithMoreDamage = core.amount[AddOn.NPC_ID_HALION_PHYSICAL] > core.amount[AddOn.NPC_ID_HALION_TWILIGHT]
                and AddOn.NPC_ID_HALION_PHYSICAL
                or AddOn.NPC_ID_HALION_TWILIGHT

        return sideWithMoreDamage == core.side.npcId
    end

    local function GetAmount()

        local amount = IsInPhysical()
                and (core.amount[AddOn.NPC_ID_HALION_PHYSICAL] - core.amount[AddOn.NPC_ID_HALION_TWILIGHT])
                or (core.amount[AddOn.NPC_ID_HALION_TWILIGHT] - core.amount[AddOn.NPC_ID_HALION_PHYSICAL])

        amount = amount / 1000

        if math.abs(amount) > 1000 then
            return string.format("%.1f M", amount / 1000)
        end

        return string.format("%.0f K", amount)
    end

    local function GetColor()
        local isMoreDamageOurSide = IsMoreDamageOurSide()

        if (shouldDoMoreDamage and isMoreDamageOurSide)
                or (not shouldDoMoreDamage and not isMoreDamageOurSide) then
            -- green - continue
            return 0, 1, 0
        end

        if shouldDoMoreDamage and not isMoreDamageOurSide then
            -- blue - do more, others have red
            return 0, 0, 1
        end

        if not shouldDoMoreDamage and isMoreDamageOurSide then
            -- red - stop
            return 1, 0, 0
        end
    end

    local function IsDifferenceGreaterThanExpected()

        local realmWithMoreDamage = core.amount[AddOn.NPC_ID_HALION_PHYSICAL] > core.amount[AddOn.NPC_ID_HALION_TWILIGHT]
                and AddOn.NPC_ID_HALION_PHYSICAL
                or AddOn.NPC_ID_HALION_TWILIGHT
        local otherRealm = realmWithMoreDamage == AddOn.NPC_ID_HALION_TWILIGHT
                and AddOn.NPC_ID_HALION_PHYSICAL
                or AddOn.NPC_ID_HALION_TWILIGHT

        return (core.amount[realmWithMoreDamage] / (core.amount[otherRealm] or 1)) >= (1 + minDiff)
    end

    local function GetColorWithDetail()
        local diff = IsDifferenceGreaterThanExpected()
        local isMoreDamageOurSide = IsMoreDamageOurSide()

        if (shouldDoMoreDamage and isMoreDamageOurSide and diff)
                or (not shouldDoMoreDamage and not isMoreDamageOurSide and diff) then
            -- green - continue
            return 0, 1, 0
        end

        if shouldDoMoreDamage and isMoreDamageOurSide and not diff then
            -- purple - ok but not safe
            return 1, 0, 1
        end

        if shouldDoMoreDamage and not isMoreDamageOurSide then
            -- blue - do more, others have red
            return 0, 0, 1
        end

        if not shouldDoMoreDamage and isMoreDamageOurSide then
            -- red - stop
            return 1, 0, 0
        end

        if not shouldDoMoreDamage and not isMoreDamageOurSide and not diff then
            -- orange - ok but not safe, slow
            return 1, 0.95, 0
            -- orange (1, 0.6, 0.05)
        end
    end

    local function ShouldStop()
        return HasData()
                and not shouldDoMoreDamage
                and IsMoreDamageOurSide()
                and core.side.corporeality.dealt ~= 1
    end

    local function SendStopMessage()
        local channel = ns.HasRaidWarningRight() and "RAID_WARNING" or "RAID"
        local sideName = IsInPhysical() and L["Physical"] or L["Twilight"]

        SendChatMessage(string.format(L["AnnounceStop"], sideName), channel)
    end

    local function OnUpdateColor(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < AddOn.SLEEP_DELAY or frame.elapsed < (frame.startDelay or 0) then
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
        if frame.remaining < 0 and UnitAffectingCombat('player') then
            -- Sometimes the corporeality doesn't update, tracking is restart by this hack
            core:NewCorporeality(core.side.npcId, core.side.corporeality)

            return
        end

        -- send AR if we must stop
        if AddOn:IsElected() and not (frame.triggered or false) and frame.remaining < checkTimer and ShouldStop() then
            frame.triggered = true
            SendStopMessage()
        end

        frame:SetValue(frame.remaining)
    end

    -- frame

    local uiFrame = CreateFrame("Frame", AddOn.NAME .. "_corporeality_uiFrame", UIParent)
    self.uiFrame = uiFrame -- used by slashCommands
    uiFrame:Hide()
    uiFrame:SetPoint(AddOn.db.profile.ui.origin, AddOn.db.profile.ui.x, AddOn.db.profile.ui.y)
    uiFrame:SetSize(170 + 60, 30)

    uiFrame.left = CreateFrame("Button", nil, uiFrame)
    uiFrame.left:SetHeight(30)
    uiFrame.left:SetWidth(30)
    uiFrame.left:SetPoint("LEFT")
    uiHelper:SetIcon(uiFrame.left, iconsSet[AddOn.db.profile.iconsSet].twilight)
    uiFrame.left:EnableMouse(false)

    uiFrame.right = CreateFrame("Button", nil, uiFrame)
    uiFrame.right:SetHeight(30)
    uiFrame.right:SetWidth(30)
    uiFrame.right:SetPoint("RIGHT")
    uiHelper:SetIcon(uiFrame.right, iconsSet[AddOn.db.profile.iconsSet].physical)
    uiFrame.right:EnableMouse(false)

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

        UpdateIcons(uiFrame)
    end

    function self:StartMonitor()

        shouldDoMoreDamage = ShouldDoMoreDamage()
        colorBar.startDelay = DELAY_AFTER_NEW_CORPOREALITY
        UpdateIcons(uiFrame)

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

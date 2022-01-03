local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.twilightCutter = module
local L = ns.L

function module:Initialize()

    local CUTTER_TIMER = 30
    local ANNOUNCE_CUTTER_DELAY = 5
    local FIRST_CUTTER_DELAY = 10
    local SPELL_CUTTER = 77846

    --- 44 seconds for 360°
    local orbRotationSpeed = 44
    local delayOrb_180 = orbRotationSpeed / 2
    local delayOrb_90 = orbRotationSpeed / 4
    local safeZoneOffset = orbRotationSpeed / 8

    -- Orbs UI
    local uiFrame = AddOn.modules.bar:NewBar(AddOn.NAME .. "_twilightCutter", nil)
    uiFrame:SetPoint(AddOn.db.profile.ui.origin, AddOn.db.profile.ui.x, AddOn.db.profile.ui.y - 40)
    uiFrame:SetValue(0)
    uiFrame:Hide()

    uiFrame.centerMark = uiFrame:CreateTexture(nil, "OVERLAY")
    uiFrame.centerMark:SetTexture(AddOn.db.profile.texture)
    uiFrame.centerMark:SetPoint("BOTTOM")
    uiFrame.centerMark:SetVertexColor(1, 0, 0, 1)
    uiFrame.centerMark:SetWidth(4)
    uiFrame.centerMark:SetHeight(25)

    uiFrame.iconLeft = CreateFrame("Button", nil, uiFrame)
    uiFrame.iconLeft:SetHeight(20)
    uiFrame.iconLeft:SetWidth(20)
    uiFrame.iconLeft:SetPoint("CENTER", -20, 0)
    AddOn.modules.bar:SetIcon(uiFrame.iconLeft, SPELL_CUTTER)
    uiFrame.iconLeft:EnableMouse(false)

    uiFrame.iconRight = CreateFrame("Button", nil, uiFrame)
    uiFrame.iconRight:SetHeight(20)
    uiFrame.iconRight:SetWidth(20)
    uiFrame.iconRight:SetPoint("CENTER", 50, 0)
    AddOn.modules.bar:SetIcon(uiFrame.iconRight, SPELL_CUTTER)
    uiFrame.iconRight:EnableMouse(false)

    -- Timer
    local timer = AddOn.modules.bar:NewBar(AddOn.NAME .. "_twilightCutter_Timer", uiFrame)
    timer:SetPoint("BOTTOM", 0, -3)
    timer:SetHeight(3)
    timer:SetMinMaxValues(0, CUTTER_TIMER)

    local isHeroicFight = false
    local frameWidth = uiFrame:GetWidth() - 20


    local function HideUI()
        uiFrame:Hide()
        timer:SetScript("OnUpdate", nil)
    end

    local function GetPosition(time, width, s)

        return -math.fmod((time + s + safeZoneOffset) / delayOrb_180 * width, width)
    end

    local function ComputePositions(time, width)

        return GetPosition(time, width, delayOrb_90), GetPosition(time, width, 0)
    end

    local function SetColor(frame)

        if frame.remaining > 21 then
            -- cutter active
            frame:SetStatusBarColor(1, 0, 0)
        elseif frame.remaining < 5 then
            -- cutter soon
            frame:SetStatusBarColor(1, 0.95, 0)
        else
            frame:SetStatusBarColor(1, 1, 1)
        end
    end

    local function UpdateUi(frame, elapsed)

        frame.remaining = (frame.remaining or 0) - elapsed
        if frame.remaining < 0 then
            return
        end

        frame:SetValue(frame.remaining)

        local left, right = ComputePositions(frame.remaining, frameWidth)

        uiFrame.iconLeft:SetPoint("RIGHT", left, 0)
        uiFrame.iconRight:SetPoint("RIGHT", right, 0)

        SetColor(frame)
    end

    local function TrackCutter()

        if not UnitAffectingCombat('player') then
            return HideUI()
        end

        timer.remaining = CUTTER_TIMER

        if not uiFrame:IsShown() then
            uiFrame:Show()
            timer:SetScript("OnUpdate", UpdateUi)
        end
    end

    -- event

    function uiFrame:CHAT_MSG_MONSTER_YELL(message)

        -- This event should occur only one time per fight
        -- We use it to start script and set isHeroicFight
        if message == L["Yell_Phase2"] or message:find(L["Yell_Phase2"]) then

            isHeroicFight = ns.IsDifficulty("heroic10", "heroic25")

            if not isHeroicFight then
                uiFrame.iconRight:Hide()
            end

            AddOn:ScheduleTimer(function()
                TrackCutter()
            end, FIRST_CUTTER_DELAY)
        end
    end

    function uiFrame:CHAT_MSG_RAID_BOSS_EMOTE(message)

        if ns.IsInTwilightRealm() and (message == L["Announce_TwilightCutter"] or message:find(L["Announce_TwilightCutter"])) then
            AddOn:ScheduleTimer(function()
                TrackCutter()
            end, ANNOUNCE_CUTTER_DELAY)
        end
    end

    function uiFrame:PLAYER_REGEN_ENABLED()
        HideUI()
        uiFrame.iconRight:Show()
    end

    --

    function self:Enable()

        if AddOn.db.profile.showCutterFrame then
            uiFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
            uiFrame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
            uiFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
    end

    function self:Disable()

        uiFrame:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
        uiFrame:UnregisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
        uiFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end


local mod = _G.HalionHelper

mod.modules.twilightCutter = {
    isHeroicFight = false
}

function mod.modules.twilightCutter:Initialize()

    function self:Enable()

        if mod.db.profile.showCutterFrame then
            self.uiFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
            self.uiFrame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
            self.uiFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
    end

    function self:Disable()

        self.uiFrame:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
        self.uiFrame:UnregisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
        self.uiFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end

    --

    local CUTTER_TIMER = 30
    local ANNOUNCE_CUTTER_DELAY = 5
    local FIRST_CUTTER_DELAY = 10
    local SPELL_CUTTER = 77846

    --- 44 seconds for 360°
    local orbRotationSpeed = 44
    local delayOrb_180 = orbRotationSpeed / 2
    local delayOrb_90 = orbRotationSpeed / 4
    local safeZoneOffset = orbRotationSpeed / 8

    local _self = self
    local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

    local function HideUI()
        _self.uiFrame:Hide()
    end

    local function TrackCutter()

        if not UnitAffectingCombat('player') then
            return HideUI()
        end

        _self.timer.remaining = CUTTER_TIMER

        if not _self.uiFrame:IsShown() then
            _self.uiFrame:Show()
        end
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

    -- Orbs UI
    self.uiFrame = mod.modules.bar:NewBar(mod.ADDON_NAME .. "_twilightCutter", nil)
    self.uiFrame:SetPoint(mod.db.profile.ui.origin, mod.db.profile.ui.x, mod.db.profile.ui.y - 40)
    self.uiFrame:SetValue(0)
    self.uiFrame:Hide()

    self.uiFrame.centerMark = self.uiFrame:CreateTexture(nil, "OVERLAY")
    self.uiFrame.centerMark:SetTexture(mod.db.profile.texture)
    self.uiFrame.centerMark:SetPoint("BOTTOM")
    self.uiFrame.centerMark:SetVertexColor(1, 0, 0, 1)
    self.uiFrame.centerMark:SetWidth(4)
    self.uiFrame.centerMark:SetHeight(25)

    self.uiFrame.iconLeft = CreateFrame("Button", nil, self.uiFrame)
    self.uiFrame.iconLeft:SetHeight(20)
    self.uiFrame.iconLeft:SetWidth(20)
    self.uiFrame.iconLeft:SetPoint("CENTER", -20, 0)
    mod.modules.bar:SetIcon(self.uiFrame.iconLeft, SPELL_CUTTER)
    self.uiFrame.iconLeft:EnableMouse(false)

    self.uiFrame.iconRight = CreateFrame("Button", nil, self.uiFrame)
    self.uiFrame.iconRight:SetHeight(20)
    self.uiFrame.iconRight:SetWidth(20)
    self.uiFrame.iconRight:SetPoint("CENTER", 50, 0)
    mod.modules.bar:SetIcon(self.uiFrame.iconRight, SPELL_CUTTER)
    self.uiFrame.iconRight:EnableMouse(false)

    -- Timer
    self.timer = mod.modules.bar:NewBar(mod.ADDON_NAME .. "_twilightCutter_Timer", self.uiFrame)
    self.timer:SetPoint("BOTTOM", 0, -3)
    self.timer:SetHeight(3)
    self.timer:SetMinMaxValues(0, CUTTER_TIMER)

    local frameWidth = self.uiFrame:GetWidth() - 20

    local function UpdateUi(frame, elapsed)

        frame.remaining = (frame.remaining or 0) - elapsed
        if frame.remaining < 0 then
            return
        end

        frame:SetValue(frame.remaining)

        local left, right = ComputePositions(frame.remaining, frameWidth)

        _self.uiFrame.iconLeft:SetPoint("RIGHT", left, 0)
        _self.uiFrame.iconRight:SetPoint("RIGHT", right, 0)

        SetColor(frame)
    end

    -- event

    function self.uiFrame:CHAT_MSG_MONSTER_YELL(message)

        -- This event should occur only one time per fight
        -- We use it to start script and set isHeroicFight
        if message == L["Yell_Phase2"] or message:find(L["Yell_Phase2"]) then

            _self.isHeroicFight = mod:IsDifficulty("heroic10", "heroic25")

            if not _self.isHeroicFight then
                _self.uiFrame.iconRight:Hide()
            end

            mod:ScheduleTimer(function()
                TrackCutter()
            end, FIRST_CUTTER_DELAY)

            _self.timer:SetScript("OnUpdate", UpdateUi)
        end
    end

    function self.uiFrame:CHAT_MSG_RAID_BOSS_EMOTE(message)

        if mod:IsInTwilightRealm() and (message == L["Announce_TwilightCutter"] or message:find(L["Announce_TwilightCutter"])) then
            mod:ScheduleTimer(function()
                TrackCutter()
            end, ANNOUNCE_CUTTER_DELAY)
        end
    end

    function self.uiFrame:PLAYER_REGEN_ENABLED()
        HideUI()
        _self.uiFrame.iconRight:Show()
    end
end


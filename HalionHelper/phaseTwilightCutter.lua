local mod = _G.HalionHelper

mod.modules.phaseTwilightCutter = {}

function mod.modules.phaseTwilightCutter:Initialize()

    function self:Enable()
        self.uiFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
        self.uiFrame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
        self.uiFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    function self:Disable()
        self.uiFrame:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
        self.uiFrame:UnregisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
        self.uiFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end

    --

    local _self = self

    local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

    local CUTTER_TIMER = 30

    function self:InitializeUi()

        function self:SetIcon(frame, spellId)
            if not frame then return end

            local icon = select(3, GetSpellInfo(spellId))

            frame:SetNormalTexture(icon)
            if (icon) then
                frame:GetNormalTexture():SetTexCoord(.07, .93, .07, .93)
            end
        end

        self.uiFrame = mod.modules.bar:NewBar("HalionHelper_phaseTwilightCutter", nil)
        self.uiFrame:SetPoint(mod.db.profile.ui.point, mod.db.profile.ui.x, mod.db.profile.ui.y - 40)
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
        self:SetIcon(self.uiFrame.iconLeft, 77846)
        self.uiFrame.iconLeft:EnableMouse(false)

        self.uiFrame.iconRight = CreateFrame("Button", nil, self.uiFrame)
        self.uiFrame.iconRight:SetHeight(20)
        self.uiFrame.iconRight:SetWidth(20)
        self.uiFrame.iconRight:SetPoint("CENTER", 50, 0)
        self:SetIcon(self.uiFrame.iconRight, 77846)
        self.uiFrame.iconRight:EnableMouse(false)


        local orbRotationSpeed = 44 -- 44 seconds for 360°
        local delayOrb_180 = orbRotationSpeed / 2
        local delayOrb_90 = orbRotationSpeed / 4
        local displayOffset = orbRotationSpeed / 8

        local frameWidth = self.uiFrame:GetWidth() - 20

        function self:UpdateUi(time)
            local t = time + displayOffset

            if t >= delayOrb_90 then
                t = math.fmod(t, delayOrb_90)
            end

            local positionOffset = frameWidth * t / delayOrb_180

            self.uiFrame.iconLeft:SetPoint("CENTER", positionOffset - frameWidth / 2, 0)
            self.uiFrame.iconRight:SetPoint("CENTER", positionOffset, 0)

            if time > 21 then
                self.timer:SetStatusBarColor(1, 0, 0)
                -- cutter
            elseif time < 5 then
                self.timer:SetStatusBarColor(1, 0.95, 0)
                -- cutter soon
            else
                self.timer:SetStatusBarColor(1, 1, 1)
            end
        end

        -- timer
        self.timer = mod.modules.bar:NewBar("HalionHelper_phaseTwilightCutter_Timer", self.uiFrame)
        self.timer:SetPoint("BOTTOM", 0, -3)
        self.timer:SetHeight(3)
        self.timer.expire = 0

        self.timer:SetScript("OnUpdate", function(self)
            local left = self.expire - GetTime()

            if (left < 0) then
                self.expire = 0
            else
                self:SetValue(left)
                _self:UpdateUi(left)
            end
        end)

        function self.timer:StartTimer(time)
            self.expire = GetTime() + time
            self:SetMinMaxValues(0, time)
            self:SetValue(time)

            if not _self.uiFrame:IsShown() and mod:IsInTwilightRealm() then
                _self.uiFrame:Show()
            end
        end

        function self.timer:StopTimer()
            self.expire = 0
            _self.uiFrame:Hide()
        end
    end

    self:InitializeUi()

    function self.uiFrame:CHAT_MSG_MONSTER_YELL(msg)
        if mod.db.profile.showCutterFrame and msg == L["Phase2"] or msg:find(L["Phase2"]) then
            if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then

                mod:ScheduleTimer(function()
                    _self.timer:StartTimer(CUTTER_TIMER)
                end, 10)
            else
                --[[mod:ScheduleTimer(function()
                    _self.timer:StartTimer(CUTTER_TIMER)
                end, 15)]]
            end
        end
    end

    function self.uiFrame:CHAT_MSG_RAID_BOSS_EMOTE(msg)
        if mod.db.profile.showCutterFrame and mod:IsInTwilightRealm() and (msg == L["twilightcutter"] or msg:find(L["twilightcutter"])) then
            mod:ScheduleTimer(function()
                _self.timer:StartTimer(CUTTER_TIMER)
            end, 5)
        end
    end

    function self.uiFrame:PLAYER_REGEN_ENABLED()

        _self.timer:StopTimer()
    end
end


local mod = _G.HalionHelper

mod.modules.phase2Ui = {}

function mod.modules.phase2Ui:Initialize()

    function self:Enable()
        self.healthBar:RegisterEvent("CHAT_MSG_ADDON")
        self.healthBar:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    function self:Disable()
        self.healthBar:UnregisterEvent("CHAT_MSG_ADDON")
        self.healthBar:UnregisterEvent("PLAYER_REGEN_ENABLED")

        self.healthBar:Hide()
        self.healthBar:SetScript("OnUpdate", nil)
    end

    -- functions

    local _self = self

    self.healthBar = mod.modules.bar:NewBar("HalionHelper_phase2Ui", nil)
    self.healthBar:SetPoint(mod.db.profile.ui.point, mod.db.profile.ui.x, mod.db.profile.ui.y)
    self.healthBar:SetStatusBarColor(0, 1, 0)
    self.healthBar:Hide()

    local function HideWhenNoData(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < (mod.SLEEP_DELAY * 10) then
            return
        end

        frame.elapsed = 0
        if frame:IsShown() then
            frame:Hide()
        end
    end

    local function SetHealthValue(value)

        if mod:IsInTwilightRealm() or value > mod.PHASE2_HEALTH_THRESHOLD or value < mod.PHASE3_HEALTH_THRESHOLD then
            if _self.healthBar:IsShown() then
                _self.healthBar:Hide()
                _self.healthBar:SetScript("OnUpdate", nil)
            end

            return
        end

        _self.healthBar.elapsed = 0
        _self.healthBar:SetValue(value)
        _self.healthBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")

        if not _self.healthBar:IsShown() then
            _self.healthBar:Show()
            _self.healthBar:SetScript("OnUpdate", HideWhenNoData)
        end
    end

    -- event

    function self.healthBar:CHAT_MSG_ADDON(prefix, message)

        if (prefix == mod.ADDON_MESSAGE_PREFIX_P2_DATA) then
            SetHealthValue(tonumber(message))
        end
    end

    function self.healthBar:PLAYER_REGEN_ENABLED()

        self:Hide()
        self:SetScript("OnUpdate", nil)
    end
end


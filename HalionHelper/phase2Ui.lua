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
    end

    -- functions

    local _self = self

    self.healthBar = mod.modules.bar:NewBar("HalionHelper_phase2Ui", nil)
    self.healthBar:SetPoint(mod.db.profile.ui.point, mod.db.profile.ui.x, mod.db.profile.ui.y)
    self.healthBar:SetStatusBarColor(0, 1, 0)
    self.healthBar:Hide()

    local function SetHealthValue(value)

        if value > mod.PHASE2_HEALTH_TRESHOLD or value < mod.PHASE3_HEALTH_TRESHOLD or mod:IsInTwilightRealm() then
            if _self.healthBar:IsShown() then
                _self.healthBar:Hide()
            end

            return
        end

        _self.healthBar:SetValue(value)
        _self.healthBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")

        if not _self.healthBar:IsShown() then
            _self.healthBar:Show()
        end
    end

    -- event

    function self.healthBar:CHAT_MSG_ADDON(prefix, message)
        if (prefix == mod.ADDON_MESSAGE_PREFIX_P2_END) then
            SetHealthValue(0)
        elseif (prefix == mod.ADDON_MESSAGE_PREFIX_P2_DATA) then
            SetHealthValue(tonumber(message))
        end
    end

    function self.healthBar:PLAYER_REGEN_ENABLED()

        self:Hide()
    end
end


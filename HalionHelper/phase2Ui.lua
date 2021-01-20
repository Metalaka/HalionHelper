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
        self:SetHealthValue(0)
    end

    -- functions

    local _self = self

    self.healthBar = mod.modules.bar:NewBar("HalionHelper_phase2Ui", nil)
    self.healthBar:SetPoint(mod.db.profile.ui.point, mod.db.profile.ui.x, mod.db.profile.ui.y)
    self.healthBar:SetStatusBarColor(0, 1, 0)
    self.healthBar:Hide()

    function self:SetHealthValue(value)

        if value > 0.75 or value < 0.5 or mod:IsInTwilightRealm() then
            if self.healthBar:IsShown() then
                self.healthBar:Hide()
            end
        else
            self.healthBar:SetValue(value)
            self.healthBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")

            if not self.healthBar:IsShown() then
                self.healthBar:Show()
            end
        end
    end

    -- event

    function self.healthBar:CHAT_MSG_ADDON(prefix, message)
        if (prefix == mod.ADDON_MESSAGE_PREFIX_P2_END) then
            _self:SetHealthValue(0)
        elseif (prefix == mod.ADDON_MESSAGE_PREFIX_P2_DATA) then
            _self:SetHealthValue(tonumber(message))
        end
    end

    function self.healthBar:PLAYER_REGEN_ENABLED()

        _self:SetHealthValue(0)
    end
end


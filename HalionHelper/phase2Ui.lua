local mod = _G.HalionHelper

mod.modules.phase2Ui = {}

function mod.modules.phase2Ui:Initialize()

    function self:Enable()
        self.progressBar:RegisterEvent("CHAT_MSG_ADDON")
        self.progressBar:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    function self:Disable()
        self.progressBar:UnregisterEvent("CHAT_MSG_ADDON")
        self.progressBar:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.progressBar:SetValue(0)
    end

    --

    local _self = self

    self.progressBar = mod.modules.bar:NewBar("HalionHelper_phase2Ui", nil)
    self.progressBar:SetPoint(mod.db.profile.P2.point, mod.db.profile.P2.x, mod.db.profile.P2.y)
    self.progressBar.statusBar:SetStatusBarColor(0, 1, 0)

    function self.progressBar:SetValue(value)

        if value > 0.75 or value < 0.5 or mod:IsInTwilightRealm() then
            if self:IsShown() then
                self:Hide()
            end
        else
            self.statusBar:SetValue(value)
            self.statusBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")

            if not self:IsShown() then
                self:Show()
            end
        end
    end

    -- init
    function self.progressBar:CHAT_MSG_ADDON(prefix, message)
        if (prefix == mod.ADDON_MESSAGE_PREFIX_P2_END) then
            self:SetValue(0)
        elseif (prefix == mod.ADDON_MESSAGE_PREFIX_P2_DATA) then
            self:SetValue(tonumber(message))
        end
    end

    function self.progressBar:PLAYER_REGEN_ENABLED()

        self:SetValue(0)
    end
end


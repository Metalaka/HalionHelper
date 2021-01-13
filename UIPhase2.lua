local mod = _G.HalionHelper

mod.modules.UIPhase2 = {}

function mod.modules.UIPhase2:Initialize()

    function self:Enable()
        self.progressBar:RegisterEvent("CHAT_MSG_ADDON")
    end

    function self:Disable()
        self.progressBar:UnregisterEvent("CHAT_MSG_ADDON")
        self.progressBar:SetValue(0)
    end

--

    self.progressBar = mod.modules.Bar:NewBar("HalionHelper_UIPhase2")

    function self.progressBar:SetValue(value)

        if value > 0.75 or value < 0.5 or mod:IsInTwilightRealm() then
            if self:IsShown() then
                self:Hide()
            end
        else
            self.StatusBar:SetValue(value)
            self.StatusBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")

            if not self:IsShown() then
                self:Show()
            end
        end
    end

    -- init
    function self.progressBar:CHAT_MSG_ADDON(prefix, message)
        if (prefix == mod.ADDON_MESSAGE_PREFIX_END) then
            self:SetValue(0)
        elseif (prefix == mod.ADDON_MESSAGE_PREFIX_DATA) then
            self:SetValue(tonumber(message))
        end
    end

end


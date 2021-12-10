local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.phase2Ui = module

function module:Initialize()

    local healthBar = AddOn.modules.bar:NewBar(AddOn.NAME .. "_phase2Ui", nil)
    healthBar:SetPoint(AddOn.db.profile.ui.origin, AddOn.db.profile.ui.x, AddOn.db.profile.ui.y)
    healthBar:SetStatusBarColor(0, 1, 0)
    healthBar:Hide()

    local function HideUI()

        if healthBar:IsShown() then
            healthBar:Hide()
        end

        healthBar:SetScript("OnUpdate", nil)
    end

    --- Hide UI when no data was received since a long time.
    local function HideWhenNoData(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < (AddOn.SLEEP_DELAY * 10) then
            return
        end

        frame.elapsed = 0

        HideUI()
    end

    local function SetHealthValue(value)

        if ns.IsInTwilightRealm() or value > AddOn.PHASE2_HEALTH_THRESHOLD or value < AddOn.PHASE3_HEALTH_THRESHOLD then
            HideUI()

            return
        end

        healthBar.elapsed = 0
        healthBar:SetValue(value)
        healthBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")

        if not healthBar:IsShown() then
            healthBar:Show()
            healthBar:SetScript("OnUpdate", HideWhenNoData)
        end
    end

    -- event

    function healthBar:CHAT_MSG_ADDON(prefix, message)

        if (prefix == AddOn.ADDON_MESSAGE_PREFIX_TWILIGHT_HEALTH_DATA) then
            SetHealthValue(tonumber(message))
        end
    end

    function healthBar:PLAYER_REGEN_DISABLED()

        self:RegisterEvent("CHAT_MSG_ADDON")
    end

    function healthBar:PLAYER_REGEN_ENABLED()

        self:UnregisterEvent("CHAT_MSG_ADDON")
        HideUI()
    end

    --

    function self:Enable()

        healthBar:RegisterEvent("PLAYER_REGEN_DISABLED")
        healthBar:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    function self:Disable()

        healthBar:UnregisterEvent("PLAYER_REGEN_DISABLED")
        healthBar:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end


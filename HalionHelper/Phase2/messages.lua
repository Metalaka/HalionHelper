local _, ns = ...

local AddOn = ns.AddOn
local module = {
    announce51 = false,
    announce55 = false,
}
AddOn.modules.phase2Messages = module

function module:Initialize()

    local ANNOUNCE_51_THRESHOLD = 0.51
    local ANNOUNCE_55_THRESHOLD = 0.55

    -- frame

    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    local function Reset()

        module.announce51 = false
        module.announce55 = false
    end

    -- say health inside physical realm
    local function SayPercentage(value)

        if not AddOn:IsElected() then
            return
        end

        if ns.IsInTwilightRealm() or value > AddOn.PHASE2_HEALTH_THRESHOLD or value < AddOn.PHASE3_HEALTH_THRESHOLD then
            return
        end

        if module.announce51 then
            return
        end

        if value <= ANNOUNCE_51_THRESHOLD then
            module.announce51 = true
            SendChatMessage("51%", "SAY")
        end

        if module.announce55 then
            return
        end

        if value <= ANNOUNCE_55_THRESHOLD then
            module.announce55 = true
            SendChatMessage("55%", "SAY")
        end

    end
    
    -- event

    function frame:CHAT_MSG_ADDON(prefix, message)

        if (prefix == AddOn.ADDON_MESSAGE_PREFIX_TWILIGHT_HEALTH_DATA) then
            SayPercentage(tonumber(message))
        end
    end

    function frame:PLAYER_REGEN_DISABLED()

        self:RegisterEvent("CHAT_MSG_ADDON")
        Reset()
    end

    function frame:PLAYER_REGEN_ENABLED()

        self:UnregisterEvent("CHAT_MSG_ADDON")
    end

    --

    function self:Enable()

        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    function self:Disable()

        frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end


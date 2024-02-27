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

    -- functions

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

    local function CollectHealth(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > AddOn.SLEEP_DELAY then
            frame.elapsed = 0

            if not UnitExists("boss2") then
                return
            end

            local percent = UnitHealth("boss2") / UnitHealthMax("boss2")

            if percent > AddOn.PHASE2_HEALTH_THRESHOLD then
                return
            end

            if percent < AddOn.PHASE3_HEALTH_THRESHOLD then
                -- Stop collect in P3
                frame:SetScript("OnUpdate", nil)
            end

            SayPercentage(percent)
        end
    end

    -- frame

    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- event

    function frame:PLAYER_REGEN_DISABLED()

        Reset()
        self:SetScript("OnUpdate", CollectHealth)
    end

    function frame:PLAYER_REGEN_ENABLED()

        self:SetScript("OnUpdate", nil)
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


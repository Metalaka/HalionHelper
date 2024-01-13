local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.phase2CollectHealth = module

function module:Initialize()

    -- functions

    local function CollectAndSendData(frame, elapsed)

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

            if not AddOn:IsElected() then
                return
            end

            C_ChatInfo.SendAddonMessage(AddOn.ADDON_MESSAGE_PREFIX_TWILIGHT_HEALTH_DATA, percent, "RAID")
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
        self:SetScript("OnUpdate", CollectAndSendData)
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

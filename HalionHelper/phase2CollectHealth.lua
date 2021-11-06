local mod = _G.HalionHelper

mod.modules.phase2CollectHealth = {}

function mod.modules.phase2CollectHealth:Initialize()

    function self:Enable()

        self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    function self:Disable()

        self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end

    -- functions

    local _self = self

    local function CollectAndSendData(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0

            if not UnitExists("boss2") then
                return
            end

            local percent = UnitHealth("boss2") / UnitHealthMax("boss2")

            if percent > mod.PHASE2_HEALTH_THRESHOLD then
                return
            end

            if percent < mod.PHASE3_HEALTH_THRESHOLD then
                -- Stop collect in P3
                frame:SetScript("OnUpdate", nil)
            end

            if not mod:IsElected() then
                return
            end

            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_DATA, percent, "RAID")
        end
    end

    -- frame

    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- event

    function self.frame:PLAYER_REGEN_DISABLED()
        self:SetScript("OnUpdate", CollectAndSendData)
    end

    function self.frame:PLAYER_REGEN_ENABLED()
        self:SetScript("OnUpdate", nil)
    end
end

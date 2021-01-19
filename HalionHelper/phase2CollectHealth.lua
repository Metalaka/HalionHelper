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

    --

    local _self = self

    -- init
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

    function self:CollectAndSendData(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0

            if not UnitExists("boss2") then
                return
            end

            local percent = UnitHealth("boss2") / UnitHealthMax("boss2")

            if percent > 0.75 then
                return
            end

            if percent < 0.5 then
                -- stop script in P3
                SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_END, nil, "RAID")
                frame:SetScript("OnUpdate", nil)
            end

            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_DATA, percent, "RAID")
        end
    end

    function self.frame:PLAYER_REGEN_DISABLED()
        self.frame:SetScript("OnUpdate", self.CollectAndSendData)
    end

    function self.frame:PLAYER_REGEN_ENABLED()
        self.frame:SetScript("OnUpdate", nil)
    end
end

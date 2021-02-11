local mod = _G.HalionHelper

mod.modules.phase2CollectHealth = {
    enableCollect = false,
}

function mod.modules.phase2CollectHealth:Initialize()

    function self:Enable()
        self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterEvent("RAID_ROSTER_UPDATE")

        self:ManageCollectActivation()
    end

    function self:Disable()
        self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:UnregisterEvent("RAID_ROSTER_UPDATE")

        self:ManageCollectActivation()
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

            if percent > mod.PHASE2_HEALTH_TRESHOLD then
                return
            end

            if percent < mod.PHASE3_HEALTH_TRESHOLD then
                -- stop collect in P3
                SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_END, nil, "RAID")

                _self.enableCollect = false
                frame:SetScript("OnUpdate", nil)

                return
            end

            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_DATA, percent, "RAID")
        end
    end

    function self:ManageCollectActivation()
        if not self.enableCollect and mod:IsRemarkablePlayer() then
            self.enableCollect = true
            self.frame:SetScript("OnUpdate", CollectAndSendData)
        elseif self.enableCollect and not mod:IsRemarkablePlayer() then
            self.enableCollect = false
            self.frame:SetScript("OnUpdate", nil)
        end
    end

    -- frame

    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

    -- event

    function self.frame:PLAYER_REGEN_DISABLED()
        _self:ManageCollectActivation()
    end

    function self.frame:PLAYER_REGEN_ENABLED()
        _self:ManageCollectActivation()
    end

    function self.frame:RAID_ROSTER_UPDATE()
        _self:ManageCollectActivation()
    end
end

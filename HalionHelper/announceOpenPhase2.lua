local mod = _G.HalionHelper

mod.modules.announceOpenPhase2 = {}

function mod.modules.announceOpenPhase2:Initialize()

    function self:Enable()

        self.frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    function self:Disable()

        self.frame:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
        self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    --

    local _self = self
    local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

    local function IsTank()
        return GetPartyAssignment("MAINTANK", "player") ~= nil
                or GetPartyAssignment("MAINASSIST", "player") ~= nil
    end

    local function IsPlayerDamageAgainstHalion(eventType, dstGUID, srcGUID)
        return eventType == "SPELL_DAMAGE"
                and mod:GetNpcId(dstGUID) == mod.NPC_ID_HALION_TWILIGHT
                and srcGUID == UnitGUID("player")
    end

    -- frame

    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- event

    function self.frame:COMBAT_LOG_EVENT_UNFILTERED(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID)

        if IsPlayerDamageAgainstHalion(eventType, dstGUID, srcGUID) then
            -- event triggered, stop watch logs
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

            local channel = mod:HasRaidWarningRight() and "RAID_WARNING" or "RAID"
            SendChatMessage(L["AnnounceTwilightBossEngaged"], channel)
        end
    end

    function self.frame:CHAT_MSG_MONSTER_YELL(message)

        if message == L["Yell_Phase2"] or message:find(L["Yell_Phase2"]) then
            if not IsTank() then
                return
            end

            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end

    function self.frame:PLAYER_REGEN_ENABLED()
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

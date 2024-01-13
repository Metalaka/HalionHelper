local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.announceOpenPhase2 = module
local L = ns.L

function module:Initialize()

    local function IsPlayerDamageAgainstHalion(eventType, dstGUID, srcGUID)
        return eventType == "SPELL_DAMAGE"
                and ns.GetNpcId(dstGUID) == AddOn.NPC_ID_HALION_TWILIGHT
                and srcGUID == UnitGUID("player")
    end

    -- frame

    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- event

    function frame:COMBAT_LOG_EVENT_UNFILTERED(_, eventType, _, srcGUID, _, _, _, dstGUID)

        if IsPlayerDamageAgainstHalion(eventType, dstGUID, srcGUID) then
            -- event triggered, stop watch logs
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

            local channel = ns.HasRaidWarningRight() and "RAID_WARNING" or "RAID"
            SendChatMessage(L["AnnounceTwilightBossEngaged"], channel)
        end
    end

    function frame:CHAT_MSG_MONSTER_YELL(message)

        if message == L["Yell_Phase2"] or message:find(L["Yell_Phase2"]) then
            if not ns.IsTank() then
                return
            end

            -- start to watch logs at the beginning of phase 2 if i am tank
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end

    function frame:PLAYER_REGEN_ENABLED()
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    --

    function self:Enable()

        if AddOn.db.profile.announceOpenPhase2 then
            frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
    end

    function self:Disable()

        frame:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

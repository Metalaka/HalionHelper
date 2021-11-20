local mod = _G.HalionHelper

mod.modules.corporeality = {}
mod.modules.corporeality.core = {
    amount = {
        [mod.NPC_ID_HALION_PHYSICAL] = 0,
        [mod.NPC_ID_HALION_TWILIGHT] = 0,
    },
    side = {
        npcId = nil,
        corporeality = nil,
    },
    isInPhase3 = false,
    --
    corporealityAuras = {
        [74836] = { dealt = -70, taken = -100, }, -- 70% less dealt, 100% less taken
        [74835] = { dealt = -50, taken = -80, }, --  50% less dealt,  80% less taken
        [74834] = { dealt = -30, taken = -50, }, --  30% less dealt,  50% less taken
        [74833] = { dealt = -20, taken = -30, }, --  20% less dealt,  30% less taken
        [74832] = { dealt = -10, taken = -15, }, --  10% less dealt,  15% less taken
        [mod.CORPOREALITY_AURA] = { dealt = 1, taken = 1, }, --  normal
        [74827] = { dealt = 15, taken = 20, }, --    15% more dealt,  20% more taken
        [74828] = { dealt = 30, taken = 50, }, --    30% more dealt,  50% more taken
        [74829] = { dealt = 60, taken = 100, }, --   60% more dealt, 100% more taken
        [74830] = { dealt = 100, taken = 200, }, -- 100% more dealt, 200% more taken
        [74831] = { dealt = 200, taken = 400, }, -- 200% more dealt, 400% more taken
    },
}

function mod.modules.corporeality.core:Initialize()

    function self:Enable()
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterEvent("CHAT_MSG_ADDON")
        self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        mod.modules.corporeality.collect:Enable()
        mod.modules.corporeality.ui:Enable()
    end

    function self:Disable()
        self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:UnregisterEvent("CHAT_MSG_ADDON")
        self.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        mod.modules.corporeality.collect:Disable()
        mod.modules.corporeality.ui:Disable()
    end

    --

    local SEPARATOR = ":"
    local _self = self

    -- functions

    local function SendData(frame, elapsed)

        if not mod:IsElected() or not _self.side.npcId or _self.amount[_self.side.npcId] == 0 then
            return
        end

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0

            local payload = _self.side.npcId .. SEPARATOR .. _self.amount[_self.side.npcId]
            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3_DATA, payload, "RAID")
        end
    end

    --- Physical Realm Boss start phase 3 without a Corporeality aura.
    --- This hack start the phase 3 from the Twilight aura event
    local function IsStartOfPhase3(event)
        return event == mod.ADDON_MESSAGE_PREFIX_P3_START
                and not _self.isInPhase3
                and not mod:IsInTwilightRealm()
    end

    -- frame

    self.frame = CreateFrame("Frame", mod.ADDON_NAME .. "_corporeality")
    self.frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    function self:NewCorporeality(npcId, aura)

        _self.side.npcId = npcId
        _self.side.corporeality = aura
        _self.amount[mod.NPC_ID_HALION_PHYSICAL] = 0
        _self.amount[mod.NPC_ID_HALION_TWILIGHT] = 0

        if _self.isInPhase3 then
            mod.modules.corporeality.ui:StartMonitor()
        else
            _self.isInPhase3 = true
            self.frame:SetScript("OnUpdate", SendData)

            mod.modules.corporeality.ui:StartTimer(5) -- display 5sec wait timer
            mod:ScheduleTimer(function()
                mod.modules.corporeality.ui:StartMonitor()
            end, 5)

            if mod:IsElected() and mod:IsInTwilightRealm() then
                -- Send transition event to Physical Realm
                SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3_START, nil, "RAID")
            end
        end
    end

    function self.frame:CHAT_MSG_ADDON(prefix, message)

        if IsStartOfPhase3(prefix) then
            _self:NewCorporeality(
                    mod.NPC_ID_HALION_PHYSICAL,
                    _self.corporealityAuras[mod.CORPOREALITY_AURA]
            )
        elseif prefix == mod.ADDON_MESSAGE_PREFIX_P3_DATA then

            local npcId, amount = mod:cut(message, SEPARATOR)
            npcId = tonumber(npcId)

            if _self.side.npcId == npcId then
                -- Don't change our data
                return
            end

            _self.amount[npcId] = tonumber(amount)
        end
    end

    function self.frame:PLAYER_REGEN_ENABLED()

        _self.isInPhase3 = false
        self:SetScript("OnUpdate", nil)
        mod.modules.corporeality.ui:StopTimer()
    end

    -- init
    _self.side.corporeality = _self.corporealityAuras[mod.CORPOREALITY_AURA]
    mod.modules.corporeality.collect:Initialize()
    mod.modules.corporeality.ui:Initialize()
end

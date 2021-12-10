local _, ns = ...

local AddOn = ns.AddOn
local module = {
    amount = {
        [AddOn.NPC_ID_HALION_PHYSICAL] = 0,
        [AddOn.NPC_ID_HALION_TWILIGHT] = 0,
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
        [AddOn.CORPOREALITY_AURA] = { dealt = 1, taken = 1, }, --  normal
        [74827] = { dealt = 15, taken = 20, }, --    15% more dealt,  20% more taken
        [74828] = { dealt = 30, taken = 50, }, --    30% more dealt,  50% more taken
        [74829] = { dealt = 60, taken = 100, }, --   60% more dealt, 100% more taken
        [74830] = { dealt = 100, taken = 200, }, -- 100% more dealt, 200% more taken
        [74831] = { dealt = 200, taken = 400, }, -- 200% more dealt, 400% more taken
    },
}
AddOn.modules.corporeality = {

}
AddOn.modules.corporeality.core = module

function module:Initialize()

    local SEPARATOR = ":"

    local frame = CreateFrame("Frame", AddOn.NAME .. "_corporeality")
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- functions

    local function SendData(frame, elapsed)

        if not AddOn:IsElected() or not module.side.npcId or module.amount[module.side.npcId] == 0 then
            return
        end

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > AddOn.SLEEP_DELAY then
            frame.elapsed = 0

            local payload = module.side.npcId .. SEPARATOR .. module.amount[module.side.npcId]
            SendAddonMessage(AddOn.ADDON_MESSAGE_PREFIX_CORPOREALITY_DATA, payload, "RAID")
        end
    end

    --- Physical Realm Boss start phase 3 without a Corporeality aura.
    --- This hack start the phase 3 from the Twilight aura event
    local function IsStartOfPhase3(event)
        return event == AddOn.ADDON_MESSAGE_PREFIX_P3_START
                and not module.isInPhase3
                and not ns.IsInTwilightRealm()
    end

    function self:NewCorporeality(npcId, aura)

        module.side.npcId = npcId
        module.side.corporeality = aura
        module.amount[AddOn.NPC_ID_HALION_PHYSICAL] = 0
        module.amount[AddOn.NPC_ID_HALION_TWILIGHT] = 0

        if not module.isInPhase3 then
            return module:StartP3(npcId, aura)
        end

        AddOn.modules.corporeality.ui:StartMonitor()
    end

    function self:StartP3(npcId, aura)

        module.isInPhase3 = true
        frame:SetScript("OnUpdate", SendData)

        AddOn.modules.corporeality.ui:StartTimer(5) -- display 5sec wait timer
        AddOn:ScheduleTimer(function()
            module:NewCorporeality(npcId, aura)
        end, 5)

        if AddOn:IsElected() and ns.IsInTwilightRealm() then
            -- Send transition event to Physical Realm
            SendAddonMessage(AddOn.ADDON_MESSAGE_PREFIX_P3_START, nil, "RAID")
        end
    end

    function frame:CHAT_MSG_ADDON(prefix, message)

        if prefix == AddOn.ADDON_MESSAGE_PREFIX_P3_START then
            AddOn:Print(message)
        end

        if IsStartOfPhase3(prefix) then
            module:NewCorporeality(
                    AddOn.NPC_ID_HALION_PHYSICAL,
                    module.corporealityAuras[AddOn.CORPOREALITY_AURA]
            )
        elseif prefix == AddOn.ADDON_MESSAGE_PREFIX_CORPOREALITY_DATA then

            local npcId, amount = ns.cut(message, SEPARATOR)
            npcId = tonumber(npcId)

            if module.side.npcId == npcId then
                -- Don't change our data
                return
            end

            module.amount[npcId] = tonumber(amount)
        end
    end

    function frame:PLAYER_REGEN_ENABLED()

        module.isInPhase3 = false
        module.side.corporeality = module.corporealityAuras[AddOn.CORPOREALITY_AURA]
        self:SetScript("OnUpdate", nil)

        AddOn.modules.corporeality.ui:StopTimer()
    end

    -- init
    module.side.corporeality = module.corporealityAuras[AddOn.CORPOREALITY_AURA]
    AddOn.modules.corporeality.collect:Initialize()
    AddOn.modules.corporeality.ui:Initialize()

    --

    function self:Enable()
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("CHAT_MSG_ADDON")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        AddOn.modules.corporeality.collect:Enable()
        AddOn.modules.corporeality.ui:Enable()
    end

    function self:Disable()
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        frame:UnregisterEvent("CHAT_MSG_ADDON")
        frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        AddOn.modules.corporeality.collect:Disable()
        AddOn.modules.corporeality.ui:Disable()
    end

end

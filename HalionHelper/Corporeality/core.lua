local _, ns = ...

local AddOn = ns.AddOn
local module = {
    amount = {
        [AddOn.NPC_ID_HALION_PHYSICAL] = 0,
        [AddOn.NPC_ID_HALION_TWILIGHT] = 0,
    },
    corporeality = {
        [AddOn.NPC_ID_HALION_PHYSICAL] = nil,
        [AddOn.NPC_ID_HALION_TWILIGHT] = nil,
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
    states = {
        push = { message = "PUSH", color = { 0, 1, 0 }, }, -- green
        stop = { message = "STOP", color = { 1, 0, 0 }, }, -- red
        pushMore = { message = "PUSH", color = { 0, 0, 1 }, }, -- blue - other have red
    }
}
AddOn.modules.corporeality = {}
AddOn.modules.corporeality.core = module

function module:Initialize()

    -- functions

    function self:NewCorporeality(npcId, aura)

        if not UnitAffectingCombat('player') then
            return
        end

        module.isInPhase3 = true
        module.amount[AddOn.NPC_ID_HALION_PHYSICAL] = 0
        module.amount[AddOn.NPC_ID_HALION_TWILIGHT] = 0
        module.corporeality[npcId] = aura

        AddOn.modules.corporeality.ui:StartMonitor()
    end

    -- event

    local frame = CreateFrame("Frame", AddOn.NAME .. "_corporeality")
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    function frame:PLAYER_REGEN_ENABLED()

        module.isInPhase3 = false
        module.corporeality[AddOn.NPC_ID_HALION_PHYSICAL] = module.corporealityAuras[AddOn.CORPOREALITY_AURA]
        module.corporeality[AddOn.NPC_ID_HALION_TWILIGHT] = module.corporealityAuras[AddOn.CORPOREALITY_AURA]

        AddOn.modules.corporeality.ui:StopTimer()
    end

    -- init
    module.corporeality[AddOn.NPC_ID_HALION_PHYSICAL] = module.corporealityAuras[AddOn.CORPOREALITY_AURA]
    module.corporeality[AddOn.NPC_ID_HALION_TWILIGHT] = module.corporealityAuras[AddOn.CORPOREALITY_AURA]
    AddOn.modules.corporeality.collect:Initialize()
    AddOn.modules.corporeality.ui:Initialize()

    --

    function self:Enable()
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")

        AddOn.modules.corporeality.collect:Enable()
        AddOn.modules.corporeality.ui:Enable()
    end

    function self:Disable()
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")

        AddOn.modules.corporeality.collect:Disable()
        AddOn.modules.corporeality.ui:Disable()
    end

end

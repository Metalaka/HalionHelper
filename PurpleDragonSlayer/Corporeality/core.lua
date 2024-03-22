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
    -- config
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
local L = ns.L

function module:Initialize()

    local preferGoTwilight = true -- goal is 60-50 in twilight, todo config

    -- functions

    local function GetOtherSide(side)
        return side == AddOn.NPC_ID_HALION_PHYSICAL and AddOn.NPC_ID_HALION_TWILIGHT or AddOn.NPC_ID_HALION_PHYSICAL
    end

    local function GetSideThatMustPush()

        local physicalCorporeality = module.corporeality[AddOn.NPC_ID_HALION_PHYSICAL]

        -- more damage to go to 50%
        if physicalCorporeality.dealt > 1 then
            return AddOn.NPC_ID_HALION_PHYSICAL
        end

        if physicalCorporeality.dealt < 1 then
            return AddOn.NPC_ID_HALION_TWILIGHT
        end

        -- more damage according to our preference if 50%
        if preferGoTwilight then
            return AddOn.NPC_ID_HALION_PHYSICAL
        else
            return AddOn.NPC_ID_HALION_TWILIGHT
        end
    end

    local function GetSideWithMoreDamage()

        return module.amount[AddOn.NPC_ID_HALION_PHYSICAL] > module.amount[AddOn.NPC_ID_HALION_TWILIGHT]
                and AddOn.NPC_ID_HALION_PHYSICAL
                or AddOn.NPC_ID_HALION_TWILIGHT
    end

    -- return the damage diff between both realm
    local function GetAmount(side)

        local amount = module.amount[side] - module.amount[GetOtherSide(side)]

        amount = amount / 1000

        if math.abs(amount) > 1000 then
            return string.format("%.1f M", amount / 1000)
        end

        return string.format("%.0f K", amount)
    end

    local function GetColor(side)
        local sideThatMustPush = GetSideThatMustPush()
        local sideWithMoreDamage = GetSideWithMoreDamage()

        if sideThatMustPush == sideWithMoreDamage then
            -- green - continue
            return module.states.push
        end

        if sideThatMustPush == side then
            -- blue - do more, others have red
            return module.states.pushMore
        end

        -- red - stop
        return module.states.stop
    end

    -- public API

    function self:HasData()
        return module.amount[AddOn.NPC_ID_HALION_PHYSICAL] > 0
                and module.amount[AddOn.NPC_ID_HALION_TWILIGHT] > 0
    end

    function self:ShouldStop(dto)
        return self:HasData()
                and (dto.states[AddOn.NPC_ID_HALION_PHYSICAL] == module.states.stop
                or dto.states[AddOn.NPC_ID_HALION_TWILIGHT] == module.states.stop)
    end

    function self:SendStopMessage(dto)
        local channel = ns.HasRaidWarningRight() and "RAID_WARNING" or "RAID"
        local sideName = dto.states[AddOn.NPC_ID_HALION_PHYSICAL] == module.states.stop and L["Physical"] or L["Twilight"]

        AddOn:Print(string.format(L["AnnounceStop"], sideName))
        --SendChatMessage(string.format(L["AnnounceStop"], sideName), channel)
    end

    function self:BuildDto()

        local dto = {
            -- amount as formatted string
            -- our corporeality (not yet used) - display value
            --- our side
            -- states (color, message) - send message to ppl without addon
            --- sideWithMoreDamage
            --- ShouldDoMoreDamage
        }

        dto.side = ns.IsInTwilightRealm() and AddOn.NPC_ID_HALION_TWILIGHT or AddOn.NPC_ID_HALION_PHYSICAL
        dto.corporeality = module.corporeality[dto.side]
        dto.amount = GetAmount(dto.side) -- formatted
        dto.states = {
            [AddOn.NPC_ID_HALION_PHYSICAL] = GetColor(AddOn.NPC_ID_HALION_PHYSICAL),
            [AddOn.NPC_ID_HALION_TWILIGHT] = GetColor(AddOn.NPC_ID_HALION_TWILIGHT),
        }

        return dto
    end

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

    -- init
    module.corporeality[AddOn.NPC_ID_HALION_PHYSICAL] = module.corporealityAuras[AddOn.CORPOREALITY_AURA]
    module.corporeality[AddOn.NPC_ID_HALION_TWILIGHT] = module.corporealityAuras[AddOn.CORPOREALITY_AURA]
    AddOn.modules.corporeality.collect:Initialize()
    AddOn.modules.corporeality.ui:Initialize()

    --

    function self:Enable()
        AddOn.modules.corporeality.collect:Enable()
        AddOn.modules.corporeality.ui:Enable()
    end

    function self:Disable()
        AddOn.modules.corporeality.collect:Disable()
        AddOn.modules.corporeality.ui:Disable()
    end

end

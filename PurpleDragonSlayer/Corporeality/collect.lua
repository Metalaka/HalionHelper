local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.corporeality.collect = module

function module:Initialize()

    local core = AddOn.modules.corporeality.core

    local frame = CreateFrame("Frame", AddOn.NAME .. "_corporeality")
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- functions

    local function AddDamageData(dstGUID, amount)

        local npcId = ns.GetNpcId(dstGUID)
        core.amount[npcId] = core.amount[npcId] + amount
    end

    local function SwingDamage()

        local dstGUID = select(8, CombatLogGetCurrentEventInfo())
        local amount = select(12, CombatLogGetCurrentEventInfo())
        AddDamageData(dstGUID, amount)
    end

    local function SpellDamage()

        local dstGUID = select(8, CombatLogGetCurrentEventInfo())
        local amount = select(15, CombatLogGetCurrentEventInfo())
        AddDamageData(dstGUID, amount)
    end

    local function EnvironmentalDamage()

        local dstGUID = select(8, CombatLogGetCurrentEventInfo())
        local amount = select(13, CombatLogGetCurrentEventInfo())
        AddDamageData(dstGUID, amount)
    end

    local function SpellAura()

        local spellId = select(12, CombatLogGetCurrentEventInfo())
        local aura = core.corporealityAuras[spellId]

        -- skip non corporeality aura
        if not aura then
            return
        end

        AddOn:Print("NewCorporeality from aura")
        local dstGUID = select(8, CombatLogGetCurrentEventInfo())
        core:NewCorporeality(ns.GetNpcId(dstGUID), aura)
    end

    local EventParse = {
        ["SWING_DAMAGE"] = SwingDamage,
        ["RANGE_DAMAGE"] = SpellDamage,
        ["SPELL_DAMAGE"] = SpellDamage,
        ["SPELL_PERIODIC_DAMAGE"] = SpellDamage,
        ["DAMAGE_SHIELD"] = SpellDamage,
        ["DAMAGE_SPLIT"] = SpellDamage,
        ["ENVIRONMENTAL_DAMAGE"] = EnvironmentalDamage,
        ["SPELL_AURA_APPLIED"] = SpellAura,
    }

    local function IsCorporealityAura(eventType)

        if eventType ~= "SPELL_AURA_APPLIED" then
            return false
        end

        local spellId = select(12, CombatLogGetCurrentEventInfo())

        return core.corporealityAuras[spellId] ~= nil
    end

    local function CombatLogEvent()
        local subevent = select(2, CombatLogGetCurrentEventInfo())
        local destName = select(9, CombatLogGetCurrentEventInfo())

        if destName ~= AddOn.BOSS_NAME then
            return
        end

        if not core.isInPhase3 and not IsCorporealityAura(subevent) then
            return
        end

        local parseFunc = EventParse[subevent]

        if parseFunc then
            parseFunc()
        end
    end

    function frame:COMBAT_LOG_EVENT_UNFILTERED()
        CombatLogEvent()
    end


    function frame:PLAYER_REGEN_ENABLED()

        core.isInPhase3 = false
        core.corporeality[AddOn.NPC_ID_HALION_PHYSICAL] = core.corporealityAuras[AddOn.CORPOREALITY_AURA]
        core.corporeality[AddOn.NPC_ID_HALION_TWILIGHT] = core.corporealityAuras[AddOn.CORPOREALITY_AURA]
        core.amount[AddOn.NPC_ID_HALION_PHYSICAL] = 0
        core.amount[AddOn.NPC_ID_HALION_TWILIGHT] = 0
    end

    --

    function self:Enable()
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    function self:Disable()
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

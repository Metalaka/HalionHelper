local mod = _G.HalionHelper

mod.modules.corporeality.collect = {}

function mod.modules.corporeality.collect:Initialize()

    local _self = self
    local core = mod.modules.corporeality.core

    function self:Enable()
        core.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    function self:Disable()
        core.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    -- functions

    local function AddDamageData(dstGUID, amount)

        local npcId = mod:GetNpcId(dstGUID)
        core.amount[npcId] = core.amount[npcId] + amount
    end

    local function SwingDamage(_, _, _, _, _, dstGUID, _, _, amount, _, _, _, _, _, _, _, _)
        AddDamageData(dstGUID, amount)
    end

    local function SpellDamage(_, _, _, _, _, dstGUID, _, _, _, _, _, amount, _, _, _, _, _, _, _, _)
        AddDamageData(dstGUID, amount)
    end

    local function EnvironmentalDamage(_, _, _, _, _, dstGUID, _, _, _, amount, _, _, _, _, _, _, _, _)
        AddDamageData(dstGUID, amount)
    end

    local function SpellAura(_, _, _, _, _, dstGUID, _, _, spellId, _, _, _)

        local aura = core.corporealityAuras[spellId]

        if not aura then
            return
        end

        core:NewCorporeality(mod:GetNpcId(dstGUID), aura)
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

    local function IsCorporealityAura(eventType, spellId)
        return eventType == "SPELL_AURA_APPLIED"
                and core.corporealityAuras[spellId] ~= nil
    end

    local function CombatLogEvent(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, ...)

        if dstName ~= mod.BOSS_NAME then
            return
        end

        if not core.isInPhase3 and not IsCorporealityAura(eventType, spellId) then
            return
        end

        local parseFunc = EventParse[eventType]

        if parseFunc then
            parseFunc(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, ...)
        end
    end

    function core.frame:COMBAT_LOG_EVENT_UNFILTERED(...)
        CombatLogEvent(...)
    end
end

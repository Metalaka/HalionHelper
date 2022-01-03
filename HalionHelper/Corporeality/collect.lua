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

        if core.side.npcId ~= npcId then
            core.side.npcId = npcId

            local spellName, _ = GetSpellInfo(AddOn.CORPOREALITY_AURA)
            local _, _, _, _, _, _, _, _, _, _, spellId = UnitAura("boss1", spellName) or UnitAura("boss2", spellName)
            core.side.corporeality = core.corporealityAuras[spellId] or core.corporealityAuras[AddOn.CORPOREALITY_AURA]
        end

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

    local function IsCorporealityAura(eventType, spellId)
        return eventType == "SPELL_AURA_APPLIED"
                and core.corporealityAuras[spellId] ~= nil
    end

    local function CombatLogEvent(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, ...)

        if dstName ~= AddOn.BOSS_NAME then
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

    function frame:COMBAT_LOG_EVENT_UNFILTERED(...)
        CombatLogEvent(...)
    end

    --

    function self:Enable()
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    function self:Disable()
        frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

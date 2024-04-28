local _, ns = ...

-- Utilities

function ns.cut(ftext, fcursor)

    local find = string.find(ftext, fcursor)

    return string.sub(ftext, 0, find - 1), string.sub(ftext, find + 1)
end

function ns.max(a, b)

    if a > b then
        return a
    end

    return b
end

function ns.IsInTwilightRealm()

    local spellName = GetSpellInfo(74807) -- 74807 "Twilight Realm" aura
    
    return AuraUtil.FindAuraByName(spellName, "player") ~= nil 
end

function ns.GetNpcId(guid)

    local unitType, _, _, _, _, npcID, _ = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" then
        return tonumber(npcID)
    end
    
    return nil
end

function ns.GetDifficulty()

    local _, instanceType, difficultyID, _, _, _, _ = GetInstanceInfo()
    if instanceType == "raid" then
        if difficultyID == 3 then
            return "normal10"
        elseif difficultyID == 4 then
            return "normal25"
        elseif difficultyID == 5 then
            return "heroic10"
        elseif difficultyID == 6 then
            return "heroic25"
        end
    end

    return "unknown"
end

function ns.IsDifficulty(...)

    local difficulty = ns.GetDifficulty()

    for i = 1, select("#", ...) do
        if difficulty == select(i, ...) then
            return true
        end
    end

    return false
end

function ns.HasRaidWarningRight()
    return UnitIsGroupLeader("player") == true
            or UnitIsGroupAssistant("player") == true
end

function ns.IsTank()
    return GetPartyAssignment("MAINTANK", "player") ~= nil
            or GetPartyAssignment("MAINASSIST", "player") ~= nil
            or UnitGroupRolesAssigned("player") == "TANK"
end

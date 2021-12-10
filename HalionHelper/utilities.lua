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

    local spellName = GetSpellInfo(74807)

    return UnitAura("player", spellName) ~= nil
end

function ns.GetNpcId(guid)
    return tonumber(guid:sub(-12, -7), 16)
end

function ns.GetDifficulty()

    local _, instanceType, difficulty, _, _, playerDifficulty, isDynamicInstance = GetInstanceInfo() -- todo: pb difficulty ?
    if instanceType == "raid" and isDynamicInstance then
        -- "new" instance (ICC)
        if difficulty == 1 or difficulty == 3 then
            -- 10 men
            return playerDifficulty == 0 and "normal10" or playerDifficulty == 1 and "heroic10" or "unknown"
        elseif difficulty == 2 or difficulty == 4 then
            -- 25 men
            return playerDifficulty == 0 and "normal25" or playerDifficulty == 1 and "heroic25" or "unknown"
        end
    else
        -- support for "old" instances
        --[[if GetInstanceDifficulty() == 1 then
            return (self.modId == "DBM-Party-WotLK" or self.modId == "DBM-Party-BC") and "normal5" or
                    self.hasHeroic and "normal10" or "heroic10"
        elseif GetInstanceDifficulty() == 2 then
            return (self.modId == "DBM-Party-WotLK" or self.modId == "DBM-Party-BC") and "heroic5" or
                    self.hasHeroic and "normal25" or "heroic25"
        elseif GetInstanceDifficulty() == 3 then
            return "heroic10"
        elseif GetInstanceDifficulty() == 4 then
            return "heroic25"
        end]]
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
    return IsRaidLeader() ~= nil
            or IsRaidOfficer() ~= nil
end

function ns.IsTank()
    return GetPartyAssignment("MAINTANK", "player") ~= nil
            or GetPartyAssignment("MAINASSIST", "player") ~= nil
end

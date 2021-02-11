HalionHelper = LibStub("AceAddon-3.0"):NewAddon("HalionHelper", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
HalionHelper.MINOR_VERSION = tonumber(("$Revision: 07 $"):match("%d+"))

local mod = _G.HalionHelper

mod.initialized = 0
mod.enabled = false
mod.modules = {}


-- constants

mod.ADDON_NAME = "HalionHelper"
mod.BOSS_NAME = "Halion"
mod.SLEEP_DELAY = 0.2
mod.PHASE2_HEALTH_TRESHOLD = 0.75
mod.PHASE3_HEALTH_TRESHOLD = 0.5
mod.ADDON_MESSAGE_PREFIX_P2_DATA = "HH_P2_DATA"
mod.ADDON_MESSAGE_PREFIX_P2_END = "HH_P2_END"
mod.ADDON_MESSAGE_PREFIX_P3_DATA = "HH_P3_DATA"
mod.ADDON_MESSAGE_PREFIX_P3_TRANSITION = "HH_P3_TRANSI"

mod.NPC_ID_HALION_PHYSICAL = 39863
mod.NPC_ID_HALION_TWILIGHT = 40142
mod.CORPOREALITY_AURA = 74826

mod.defaults = {
    profile = {
        ui = {
            point = "CENTER",
            x = 0,
            y = 200,
        },
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        iconsSet = "REALM",
        showCutterFrame = false,
        forceDataCollect = false,
    }
}

local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

-- functions

function mod:InitializeAddon()

    if self.initialized > 0 then
        return
    end

    self.initialized = 1
    self.enabled = false
    self.frame:UnregisterEvent("ADDON_LOADED")

    self.db = LibStub("AceDB-3.0"):New("HalionHelperDB", mod.defaults, true)

    -- go
    self.modules.bar:Initialize()
    self.modules.phase2CollectHealth:Initialize()
    self.modules.phase2Ui:Initialize()
    self.modules.phase3CollectLog:Initialize()
    self.modules.phaseTwilightCutter:Initialize()

    self.initialized = 2
    self:OnZoneChange()
end

function mod:EnableModules()
    if self.initialized ~= 2 then
        return
    end

    self.enabled = true

    self.modules.bar:Enable()
    self.modules.phase2CollectHealth:Enable()
    self.modules.phase2Ui:Enable()
    self.modules.phase3CollectLog:Enable()
    self.modules.phaseTwilightCutter:Enable()

    self:Print(L["Loaded"])
end

function mod:DisableModules()
    if self.initialized ~= 2 then
        return
    end

    self.enabled = false

    self.modules.bar:Disable()
    self.modules.phase2CollectHealth:Disable()
    self.modules.phase2Ui:Disable()
    self.modules.phase3CollectLog:Disable()
    self.modules.phaseTwilightCutter:Disable()
end

function mod:ShouldEnableAddon()

    return GetRealZoneText() == L["ZoneName"]
end

function mod:OnZoneChange()

    if self:ShouldEnableAddon() and not self.enabled then
        self:EnableModules()
    elseif not self:ShouldEnableAddon() and self.enabled then
        self:DisableModules()
    end
end

-- frame

mod.frame = CreateFrame("Frame", "HalionHelper_AddonMainFrame")
mod.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

-- event

function mod.frame:ADDON_LOADED(addon)
    if addon ~= mod.ADDON_NAME then
        return
    end

    mod:InitializeAddon()
end

function mod.frame:PLAYER_ENTERING_WORLD()
    mod:OnZoneChange()
end

function mod.frame:ZONE_CHANGED_NEW_AREA()
    mod:OnZoneChange()
end

-- Helpers functions

function mod:IsInTwilightRealm()
    local name = GetSpellInfo(74807)

    return UnitAura("player", name)
end

function mod:IsRemarkablePlayer()
    return self.db.profile.forceDataCollect
            or IsRaidLeader()
            or IsRaidOfficer()
            or GetPartyAssignment("MAINTANK", "player")
            or GetPartyAssignment("MAINASSIST", "player")
end

-- Utils

function mod:cut(ftext, fcursor)
    local find = string.find(ftext, fcursor)
    return string.sub(ftext, 0, find - 1), string.sub(ftext, find + 1)
end

function mod:max(a, b)
    if a > b then return a end
    return b
end

function mod:GetNpcId(guid)
    return tonumber(guid:sub(-12, -7), 16)
end

function mod:GetDifficulty()
    local _, instanceType, difficulty, _, _, playerDifficulty, isDynamicInstance = GetInstanceInfo() -- todo: pb difficulty ?
    if instanceType == "raid" and isDynamicInstance then -- "new" instance (ICC)
        if difficulty == 1 or difficulty == 3 then -- 10 men
            return playerDifficulty == 0 and "normal10" or playerDifficulty == 1 and "heroic10" or "unknown"
        elseif difficulty == 2 or difficulty == 4 then -- 25 men
            return playerDifficulty == 0 and "normal25" or playerDifficulty == 1 and "heroic25" or "unknown"
        end
    else -- support for "old" instances
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

function mod:IsDifficulty(...)
    local diff = self:GetDifficulty()
    for i = 1, select("#", ...) do
        if diff == select(i, ...) then
            return true
        end
    end
    return false
end

-- Start addon

mod.frame:RegisterEvent("ADDON_LOADED")
mod.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
mod.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- todo: update check, disable if major diff
-- todo: UI P2 can be shown out of combat after a BR

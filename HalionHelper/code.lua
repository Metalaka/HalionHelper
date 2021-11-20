HalionHelper = LibStub("AceAddon-3.0"):NewAddon("HalionHelper", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
HalionHelper.MINOR_VERSION = 20001

local mod = _G.HalionHelper

mod.initialized = 0
mod.enabled = false
mod.modules = {}
mod.versionMax = mod.MINOR_VERSION

-- constants

mod.ADDON_NAME = "HalionHelper"
mod.BOSS_NAME = "Halion"
mod.SLEEP_DELAY = 0.2
mod.ELECTION_DELAY = 5
mod.PHASE2_HEALTH_THRESHOLD = 0.75
mod.PHASE3_HEALTH_THRESHOLD = 0.5
mod.ADDON_MESSAGE_PREFIX_P2_DATA = mod.ADDON_NAME .. "_P2_DATA"
mod.ADDON_MESSAGE_PREFIX_P3_DATA = mod.ADDON_NAME .. "_P3_DATA"
mod.ADDON_MESSAGE_PREFIX_P3_START = mod.ADDON_NAME .. "_P3_START"
mod.ADDON_MESSAGE_PREFIX_ELECTION = mod.ADDON_NAME .. "_ELECTION_INSCRIPTION"
mod.ADDON_MESSAGE_PREFIX_HELLO = mod.ADDON_NAME .. "_CLIENT_HELLO"
mod.ADDON_UPDATE_URL = "…"

mod.NPC_ID_HALION_PHYSICAL = 39863
mod.NPC_ID_HALION_TWILIGHT = 40142
mod.CORPOREALITY_AURA = 74826

mod.defaults = {
    profile = {
        ui = {
            origin = "CENTER",
            x = 0,
            y = 0,
        },
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        iconsSet = "REALM",
        showCutterFrame = false,
        enable = true,
    }
}

local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

-- frame

mod.frame = CreateFrame("Frame", mod.ADDON_NAME .. "_MainFrame")
mod.frame:SetScript("OnEvent", function(self, event, ...)

    if self[event] then
        return self[event](self, ...)
    end
end)


-- functions

function mod:InitializeAddon()

    if self.initialized > 0 then
        return
    end

    self.initialized = 1
    self.enabled = false
    self.frame:UnregisterEvent("ADDON_LOADED")

    self.db = LibStub("AceDB-3.0"):New(mod.ADDON_NAME .. "DB", mod.defaults, true)

    -- go
    self.modules.bar:Initialize()
    self.modules.election:Initialize()
    self.modules.announceOpenPhase2:Initialize()
    self.modules.phase2CollectHealth:Initialize()
    self.modules.phase2Ui:Initialize()
    self.modules.corporeality.core:Initialize()
    self.modules.twilightCutter:Initialize()
    self.modules.slashCommands:Initialize()

    self.initialized = 2

    function self.frame:PLAYER_ENTERING_WORLD()
        mod:OnZoneChange()
    end

    function self.frame:ZONE_CHANGED_NEW_AREA()
        mod:OnZoneChange()
    end

    function self.frame:CHAT_MSG_ADDON(prefix, message)
        if prefix == mod.ADDON_MESSAGE_PREFIX_HELLO then
            mod:OnClientHello(tonumber(message))
        end
    end

    SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_HELLO, mod.MINOR_VERSION, "RAID")

    self:OnZoneChange()
end

function mod:EnableModules()

    if self.initialized ~= 2 then
        return
    end

    self.enabled = true

    self.modules.bar:Enable()
    self.modules.election:Enable()
    self.modules.announceOpenPhase2:Enable()
    self.modules.phase2CollectHealth:Enable()
    self.modules.phase2Ui:Enable()
    self.modules.corporeality.core:Enable()
    self.modules.twilightCutter:Enable()

    self:Print(L["Loaded"])
end

function mod:DisableModules()

    if self.initialized ~= 2 then
        return
    end

    self.enabled = false

    self.modules.bar:Disable()
    self.modules.election:Disable()
    self.modules.announceOpenPhase2:Disable()
    self.modules.phase2CollectHealth:Disable()
    self.modules.phase2Ui:Disable()
    self.modules.corporeality.core:Disable()
    self.modules.twilightCutter:Disable()
end

function mod:ShouldEnableAddon()
    return self.db.profile.enable and GetRealZoneText() == L["ZoneName"]
end

function mod:OnZoneChange()

    if self:ShouldEnableAddon() and not self.enabled then
        self:EnableModules()
    elseif not self:ShouldEnableAddon() and self.enabled then
        self:DisableModules()
    end
end

function mod:OnClientHello(version)

    if self.versionMax < version then
        self.versionMax = version
        self:Printf(L["Update"], mod.ADDON_UPDATE_URL)

        -- Disable addon
        self:DisableModules()
        self.initialized = 3

        self.frame:UnregisterEvent("CHAT_MSG_ADDON")
        self.frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self.frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    end
end

-- event

function mod.frame:ADDON_LOADED(addon)

    if addon ~= mod.ADDON_NAME then
        return
    end

    mod:InitializeAddon()
end

-- Helpers functions

function mod:IsInTwilightRealm()

    local name = GetSpellInfo(74807)

    return UnitAura("player", name) ~= nil
end

function mod:IsElected()
    return self.modules.election.elected
end

-- Utils

function mod:cut(ftext, fcursor)

    local find = string.find(ftext, fcursor)

    return string.sub(ftext, 0, find - 1), string.sub(ftext, find + 1)
end

function mod:max(a, b)

    if a > b then
        return a
    end

    return b
end

function mod:GetNpcId(guid)
    return tonumber(guid:sub(-12, -7), 16)
end

function mod:GetDifficulty()

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

function mod:IsDifficulty(...)

    local difficulty = self:GetDifficulty()

    for i = 1, select("#", ...) do
        if difficulty == select(i, ...) then
            return true
        end
    end

    return false
end

function mod:HasRaidWarningRight()
    return IsRaidLeader() ~= nil
            or IsRaidOfficer() ~= nil
end


-- Start addon

mod.frame:RegisterEvent("ADDON_LOADED")
mod.frame:RegisterEvent("CHAT_MSG_ADDON")
mod.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
mod.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

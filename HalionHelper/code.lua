local name, ns = ...

local LibStub = assert(LibStub, name .. " requires LibStub.")

local AddOn = LibStub("AceAddon-3.0"):NewAddon(name, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
ns.AddOn = AddOn

local L = LibStub("AceLocale-3.0"):GetLocale(name)
ns.L = L

-- constants

AddOn.NAME = name
AddOn.VERSION = 30000
AddOn.ADDON_MESSAGE_PREFIX_TWILIGHT_HEALTH_DATA = AddOn.NAME .. "_TWILIGHT_HEALTH_DATA"
AddOn.ADDON_MESSAGE_PREFIX_CORPOREALITY_DATA = AddOn.NAME .. "_CORPOREALITY_DATA"
AddOn.ADDON_MESSAGE_PREFIX_P3_START = AddOn.NAME .. "_P3_START"
AddOn.ADDON_MESSAGE_PREFIX_ELECTION = AddOn.NAME .. "_ELECTION_INSCRIPTION"
AddOn.ADDON_MESSAGE_PREFIX_HELLO = AddOn.NAME .. "_CLIENT_HELLO"
AddOn.ADDON_UPDATE_URL = "https://github.com/Metalaka/HalionHelper/releases"

AddOn.BOSS_NAME = "Halion"
AddOn.NPC_ID_HALION_PHYSICAL = 39863
AddOn.NPC_ID_HALION_TWILIGHT = 40142
AddOn.CORPOREALITY_AURA = 74826
AddOn.SLEEP_DELAY = 0.2
AddOn.ELECTION_DELAY = 5
AddOn.PHASE2_HEALTH_THRESHOLD = 0.75
AddOn.PHASE3_HEALTH_THRESHOLD = 0.5
AddOn.INSTANCE_ID = 724

AddOn.defaultDb = {
    profile = {
        ui = {
            origin = "CENTER",
            x = 0,
            y = 0,
        },
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        enable = true,
        announceOpenPhase2 = false,
        showCutterFrame = false,
    }
}


AddOn.modules = {}

local NOT_INITIALIZED = 0
local INITIALIZING = 1
local INITIALIZED = 2
local DISABLED = 3
local initialized = NOT_INITIALIZED
local updateMessageTriggered = false

-- frame

local frame = CreateFrame("Frame", AddOn.NAME .. "_MainFrame")
frame:SetScript("OnEvent", function(self, event, ...)

    if self[event] then
        return self[event](self, ...)
    end
end)

-- functions

function AddOn:InitializeAddon()

    if initialized > NOT_INITIALIZED then
        return
    end

    initialized = INITIALIZING
    frame:UnregisterEvent("ADDON_LOADED")
    local enabled = false

    self.db = LibStub("AceDB-3.0"):New(AddOn.NAME .. "DB", AddOn.defaultDb, true)

    -- initialize modules
    self.modules.bar:Initialize()
    self.modules.election:Initialize()
    self.modules.announceOpenPhase2:Initialize()
    self.modules.phase2Messages:Initialize()
    self.modules.corporeality.core:Initialize()
    self.modules.twilightCutter:Initialize()
    self.modules.options:Initialize()

    local function EnableModules()

        if initialized ~= INITIALIZED then
            return
        end

        enabled = true

        AddOn.modules.bar:Enable()
        AddOn.modules.election:Enable()
        AddOn.modules.announceOpenPhase2:Enable()
        AddOn.modules.phase2Messages:Enable()
        AddOn.modules.corporeality.core:Enable()
        AddOn.modules.twilightCutter:Enable()

        AddOn:Print(L["Loaded"])
    end

    local function DisableModules()

        if initialized < INITIALIZED then
            return
        end

        enabled = false

        AddOn.modules.bar:Disable()
        AddOn.modules.election:Disable()
        AddOn.modules.announceOpenPhase2:Disable()
        AddOn.modules.phase2Messages:Disable()
        AddOn.modules.corporeality.core:Disable()
        AddOn.modules.twilightCutter:Disable()
    end

    local function ShouldEnableAddon()
        
        local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()

        return AddOn.db.profile.enable and instanceID == AddOn.INSTANCE_ID
    end

    -- events

    function frame:PLAYER_ENTERING_WORLD()
        AddOn:OnZoneChange()
    end

    function frame:ZONE_CHANGED_NEW_AREA()
        AddOn:OnZoneChange()
    end

    function frame:CHAT_MSG_ADDON(prefix, message)
        if prefix == AddOn.ADDON_MESSAGE_PREFIX_HELLO then
            AddOn:OnClientHello(tonumber(message))
        end
    end

    function self:OnZoneChange()

        if not enabled and ShouldEnableAddon() then
            EnableModules()
        elseif enabled and not ShouldEnableAddon() then
            DisableModules()
        end
    end

    function self:OnClientHello(version)

        if AddOn.VERSION < version then

            if math.floor(AddOn.VERSION / 10000) < math.floor(version / 10000) then

                self:Printf(L["UpdateRequired"], AddOn.ADDON_UPDATE_URL)
                initialized = DISABLED

                DisableModules()
                frame:UnregisterEvent("CHAT_MSG_ADDON")
                frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
                frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
                return
            end

            if updateMessageTriggered then
                return
            end

            updateMessageTriggered = true

            self:Printf(L["NewVersion"], AddOn.ADDON_UPDATE_URL)
        end

    end

    function self:IsElected()
        return self.modules.election.elected
    end

    -- initialized, run

    initialized = INITIALIZED

    C_ChatInfo.SendAddonMessage(AddOn.ADDON_MESSAGE_PREFIX_HELLO, AddOn.VERSION, "RAID")

    self:OnZoneChange()
end

-- event

function frame:ADDON_LOADED(addon)

    if addon ~= AddOn.NAME then
        return
    end

    AddOn:InitializeAddon()
end

-- Start addon

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

HalionHelper = LibStub("AceAddon-3.0"):NewAddon("HalionHelper", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
HalionHelper.MINOR_VERSION = tonumber(("$Revision: 02 $"):match("%d+"))

local mod = _G.HalionHelper

mod.initialized = 0
mod.enabled = false
mod.modules = {}


-- constants
mod.ADDON_NAME = "HalionHelper"
mod.BOSS_NAME = "Halion"
mod.SLEEP_DELAY = 0.2
mod.ADDON_MESSAGE_PREFIX_P2_DATA = "HH_P2_DATA"
mod.ADDON_MESSAGE_PREFIX_P2_END = "HH_P2_END"
mod.ADDON_MESSAGE_PREFIX_P3_DATA = "HH_P3_DATA"
mod.ADDON_MESSAGE_PREFIX_P3_TRANSITION = "HH_P3_TRANSI"

mod.NPC_ID_HALION_PHYSICAL = 39863
mod.NPC_ID_HALION_TWILIGHT = 40142
mod.CORPOREALITY_AURA = 74826

mod.defaults = {
    profile = {
        P2 = {
            point = "CENTER",
            x = 0,
            y = 200,
        },
        P3 = {
            point = "CENTER",
            x = 0,
            y = 300,
        },
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
    }
}

-- Main Frame
mod.frame = CreateFrame("Frame", "HalionHelper_AddonMainFrame")
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

function mod:ShouldEnableAddon()

    local name = GetRealZoneText()
--todo: localize
    return name == "The Ruby Sanctum" or name == "Le sanctum Rubis"
end

function mod:OnZoneChange()

    if self.ShouldEnableAddon() and not self.enabled then
        self:EnableModules()
    elseif self.enabled then
        self:DisableModules()
    end
end

mod.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)
mod.frame:RegisterEvent("ADDON_LOADED")
mod.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
mod.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Initialize
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

    self:Print("loaded - Have fun !")
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
end

function mod:IsInTwilightRealm()
    local name = GetSpellInfo(74807)

    return UnitAura("player", name)
end

function mod:cut(ftext, fcursor)
    local find = string.find(ftext, fcursor);
    return string.sub(ftext, 0, find - 1), string.sub(ftext, find + 1);
end

function mod:max(a, b)
    if a > b then return a end
    return b
end
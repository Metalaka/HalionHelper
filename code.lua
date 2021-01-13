HalionHelper = LibStub("AceAddon-3.0"):NewAddon("HalionHelper", "AceEvent-3.0", "AceTimer-3.0")
HalionHelper.MINOR_VERSION = tonumber(("$Revision: 01 $"):match("%d+"))
--local LSM = LibStub("LibSharedMedia-3.0",true)

if not HalionHelper then return end -- No Upgrade needed.

local mod = _G.HalionHelper

mod.Version = tonumber(("$Revision: 01 $"):match("%d+"))
mod.Initialized = false
mod.Enabled = false
mod.modules = {}


-- constants
mod.BOSS_NAME = "Halion"
mod.SLEEP_DELAY = 0.2
mod.ADDON_MESSAGE_PREFIX_DATA = "HH_boss2"
mod.ADDON_MESSAGE_PREFIX_END = "HH_boss2_end"
mod.ADDON_MESSAGE_PREFIX_P3_DATA = "HH_P3_DATA"
mod.ADDON_MESSAGE_PREFIX_P3_TRANSI = "HH_P3_TRANSI"

mod.NPC_ID_HALION_PHYSICAL = 39863
mod.NPC_ID_HALION_TWILIGHT = 40142

-- Main Frame
mod.frame = CreateFrame("Frame", "HalionHelper_AddonFrame")
function mod.frame:ADDON_LOADED(addon)
    if addon ~= "HalionHelper" or not mod.ShouldEnableAddon() then
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

    -- GetCurrentMapAreaID() == = 609+1 PARAGON_OFFSET
    local name = GetRealZoneText()

    return name == "The Ruby Sanctum" or name == "Le Sanctum Ruby"
end

function mod:OnZoneChange()

    if self.ShouldEnableAddon() then

        if not self.Initialized then
            mod:InitializeAddon()
        elseif not self.Enabled then
            self.Enabled = true
        end
    else

        if not self.Initialized then
            return
        elseif self.Enabled then
            self.Enabled = false
        end
    end
end

mod.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)
mod.frame:RegisterEvent("ADDON_LOADED")
mod.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
mod.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Initialize
function mod:InitializeAddon()

    if self.Initialized then
        return
    end

    self.Initialized = true
    self.Enabled = true
    self.frame:UnregisterEvent("ADDON_LOADED")

    --    self.modules.main = {}


    function self:IsInTwilightRealm()
        local name = GetSpellInfo(74807)

        return UnitAura("player", name)
    end

    -- go
    self.modules.Bar:Initialize()
    self.modules.CollectHealthPhase2:Initialize()
    self.modules.UIPhase2:Initialize()
    self.modules.CollectLogPhase3:Initialize()

    self:Enable()
    DEFAULT_CHAT_FRAME:AddMessage("HH loaded")
end

function mod:Enable()
    if not self.Initialized then
        return
    end

    self.Enabled = true

    self.modules.Bar:Enable()
    self.modules.CollectHealthPhase2:Enable()
    self.modules.UIPhase2:Enable()
    self.modules.CollectLogPhase3:Enable()
end

function mod:Disable()
    if not self.Initialized then
        return
    end
    self.Enabled = false

    self.modules.Bar:Disable()
    self.modules.CollectHealthPhase2:Disable()
    self.modules.UIPhase2:Disable()
    self.modules.CollectLogPhase3:Disable()
end


function mod:cut(ftext, fcursor)
    local find = string.find(ftext, fcursor);
    return string.sub(ftext, 0, find - 1), string.sub(ftext, find + 1);
end

function mod:max(a, b)
    if a > b then return a end
    return b
end
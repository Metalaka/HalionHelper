--Register Slash Commands---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

local mod = _G.HalionHelper

mod.modules.slashCommands = {}
local m = mod.modules.slashCommands

m.frame = CreateFrame("FRAME", "HalionHelperAddonFrame")
m.frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Fired when the player enters the world, enters/leaves an instance, or respawns at a graveyard. Also fires any other time the player sees a loading screen.
m.frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Fired whenever you enter combat, as normal regen rates are disabled during combat. This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action (either as attacker or victim).
--m.frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Fired whenever you enter combat, as normal regen rates are disabled during combat. This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action (either as attacker or victim).
--m.frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
--m.frame:RegisterEvent("UPDATE_WORLD_STATES")
--m.frame:RegisterEvent("CHAT_MSG_ADDON")

m.frame:SetScript("OnEvent", function(self, event, ...)

    print("> " .. event);
    if ... then
        print(...);
    end
end)

function m:InitializeSlashCommands()
    SLASH_HALION_HELPER_TEST1 = "/hh"
    SlashCmdList["HALION_HELPER_TEST"] = function(msg)
        DEFAULT_CHAT_FRAME:AddMessage("HALION_HELPER_TEST call")

        if not mod.Initialized then
            return
        end

        m:MoveUI()
    end
end

function m:MoveUI()

    function self:ToggleMovable(frame)

        if not frame:IsMovable() then
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton")
            frame:SetScript("OnDragStart", frame.StartMoving)
            frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        else
            frame:SetMovable(false)
            frame:EnableMouse(false)
        end
    end

    if not mod.modules.CollectLogPhase3.CorporealityBar:IsShown() then

        self:ToggleMovable(mod.modules.UIPhase2.progressBar)
        self:ToggleMovable(mod.modules.CollectLogPhase3.UIFrame)

        mod.modules.UIPhase2.progressBar:SetValue(0.666)
        mod.modules.CollectLogPhase3.timer:StartTimer(15)
        mod.modules.CollectLogPhase3.CorporealityBar:Show()

        DEFAULT_CHAT_FRAME:AddMessage("HalionHelper: movable mode enabled. Disable it to save potitions.")
    else
        self:ToggleMovable(mod.modules.UIPhase2.progressBar)
        self:ToggleMovable(mod.modules.CollectLogPhase3.UIFrame)

        mod.modules.UIPhase2.progressBar:SetValue(0)
        mod.modules.CollectLogPhase3.timer:StartTimer(0)
        mod.modules.CollectLogPhase3.CorporealityBar:Hide()
    end
end

m:InitializeSlashCommands()

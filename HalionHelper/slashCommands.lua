local mod = _G.HalionHelper

mod.modules.slashCommands = {}

function mod.modules.slashCommands:Initialize()

    local _self = self

    local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

    mod:RegisterChatCommand("halionhelper", "ChatCommand")

    function mod:ChatCommand(args)

        local arg1, arg2 = self:GetArgs(args, 2)

        if arg1 == "enable" or arg1 == "e" then
            _self:toggleAddon()
        elseif arg1 == "move" or arg1 == "m" then
            _self:MoveUI()
        elseif arg1 == "texture" or arg1 == "t" then
            _self:SetTexture(arg2)
        elseif arg1 == "cutter" or arg1 == "c" then
            _self:toggleCutter()
        else
            mod:Print(L["ChatCommand_usage"])
            mod:Printf("|cffffee00/halionhelper help|r - %s", L["ChatCommand_help"])
            mod:Printf("|cffffee00/halionhelper enable|r - %s", L["ChatCommand_enable"])
            mod:Printf("|cffffee00/halionhelper move|r - %s", L["ChatCommand_move"])
            mod:Printf("|cffffee00/halionhelper texture NAME|r - %s", L["ChatCommand_texture"])
            mod:Printf("|cffffee00/halionhelper cutter|r - %s", L["ChatCommand_cutter"])
        end
    end

    function self:toggleAddon()

        if mod.db.profile.enable then
            mod.db.profile.enable = false
        else
            mod.db.profile.enable = true
        end

        mod:OnZoneChange()

        mod:Printf(L["ChatCommand_enable_message"], tostring(mod.db.profile.enable))
    end

    function self:MoveUI()

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

        self:ToggleMovable(mod.modules.phase2Ui.healthBar)
        self:ToggleMovable(mod.modules.phase3CollectLog.ui.uiFrame)

        if not mod.modules.phase3CollectLog.ui.uiFrame:IsShown() then
            mod.modules.phase3CollectLog.ui.timer:StartTimer(15)

            mod:Print(L["ChatCommand_movableMod"])
        else
            mod.modules.phase3CollectLog.ui.timer:StopTimer(0)

            local point, _, _, x, y = mod.modules.phase3CollectLog.ui.uiFrame:GetPoint(1)
            mod.db.profile.ui.point = point
            mod.db.profile.ui.x = x
            mod.db.profile.ui.y = y
        end
    end

    function self:SetTexture(name)

        local LSM = LibStub("LibSharedMedia-3.0", true)

        if not LSM then
            mod:Print(L["ChatCommand_texture_LSM"])

            return
        end

        if LSM:IsValid(LSM.MediaType.STATUSBAR, name) then
            mod.db.profile.texture = LSM:Fetch(LSM.MediaType.STATUSBAR, name)
            mod:Print(L["ChatCommand_texture_OK"])
        else
            mod:Printf(L["ChatCommand_texture_ERROR"], name)
        end
    end

    function self:toggleCutter()

        if mod.db.profile.showCutterFrame then
            mod.db.profile.showCutterFrame = false
        else
            mod.db.profile.showCutterFrame = true
        end

        mod.modules.phaseTwilightCutter:ManageActivation()

        mod:Printf(L["ChatCommand_cutter_message"], tostring(mod.db.profile.showCutterFrame))
    end

end

-- Initialize chat command
mod.modules.slashCommands:Initialize()

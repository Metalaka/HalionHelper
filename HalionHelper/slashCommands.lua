local mod = _G.HalionHelper

mod.modules.slashCommands = {}

function mod.modules.slashCommands:Initialize()

    local _self = self

    local L = LibStub("AceLocale-3.0"):GetLocale(mod.ADDON_NAME)

    mod:RegisterChatCommand("halionhelper", "ChatCommand")

    function mod:ChatCommand(args)

        local command, argument = self:GetArgs(args, 2)

        if command == "enable" or command == "e" then
            _self:toggleAddon()
        elseif command == "move" or command == "m" then
            _self:MoveUI()
        elseif command == "texture" or command == "t" then
            _self:SetTexture(argument)
        elseif command == "cutter" or command == "c" then
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

        local function ToggleMovable(frame)

            if frame:IsMovable() then
                frame:SetMovable(false)
                frame:EnableMouse(false)
            else
                frame:SetMovable(true)
                frame:EnableMouse(true)
                frame:RegisterForDrag("LeftButton")
                frame:SetScript("OnDragStart", frame.StartMoving)
                frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
            end
        end

        ToggleMovable(mod.modules.corporeality.ui.uiFrame)

        if not mod.modules.corporeality.ui.uiFrame:IsShown() then
            mod.modules.corporeality.ui:StartTimer(15)

            mod:Print(L["ChatCommand_movableMod"])
        else
            mod.modules.corporeality.ui:StopTimer()

            -- UI phase 2 / 3 can't be shown at the same time, so we use the same position
            local origin, _, _, x, y = mod.modules.corporeality.ui.uiFrame:GetPoint(1)
            mod.db.profile.ui.origin = origin
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

        mod.db.profile.showCutterFrame = not (mod.db.profile.showCutterFrame or false)

        mod.modules.twilightCutter:Disable()
        mod.modules.twilightCutter:Enable()

        mod:Printf(L["ChatCommand_cutter_message"], tostring(mod.db.profile.showCutterFrame))
    end

end

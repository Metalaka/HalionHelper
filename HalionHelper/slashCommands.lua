local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.slashCommands = module
local L = ns.L

function module:Initialize()

    local function ToggleAddon()

        if AddOn.db.profile.enable then
            AddOn.db.profile.enable = false
        else
            AddOn.db.profile.enable = true
        end

        AddOn:OnZoneChange()

        AddOn:Printf(L["ChatCommand_enable_message"], tostring(AddOn.db.profile.enable))
    end

    local function MoveUI()

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

        ToggleMovable(AddOn.modules.corporeality.ui.uiFrame)

        if not AddOn.modules.corporeality.ui.uiFrame:IsShown() then
            AddOn.modules.corporeality.ui:StartTimer(15)

            AddOn:Print(L["ChatCommand_movableMod"])
        else
            AddOn.modules.corporeality.ui:StopTimer()

            -- UI phase 2 / 3 can't be shown at the same time, so we use the same position
            local origin, _, _, x, y = AddOn.modules.corporeality.ui.uiFrame:GetPoint(1)
            AddOn.db.profile.ui.origin = origin
            AddOn.db.profile.ui.x = x
            AddOn.db.profile.ui.y = y
        end
    end

    local function SetTexture(name)

        local LSM = LibStub("LibSharedMedia-3.0", true)

        if not LSM then
            AddOn:Print(L["ChatCommand_texture_LSM"])

            return
        end

        if LSM:IsValid(LSM.MediaType.STATUSBAR, name) then
            AddOn.db.profile.texture = LSM:Fetch(LSM.MediaType.STATUSBAR, name)
            AddOn:Print(L["ChatCommand_texture_OK"])
        else
            AddOn:Printf(L["ChatCommand_texture_ERROR"], name)
        end
    end

    local function ToggleCutter()

        AddOn.db.profile.showCutterFrame = not (AddOn.db.profile.showCutterFrame or false)

        AddOn.modules.twilightCutter:Disable()
        AddOn.modules.twilightCutter:Enable()

        AddOn:Printf(L["ChatCommand_cutter_message"], tostring(AddOn.db.profile.showCutterFrame))
    end

    function AddOn:ChatCommand(args)

        local command, argument = AddOn:GetArgs(args, 2)

        if command == "enable" or command == "e" then
            ToggleAddon()
        elseif command == "move" or command == "m" then
            MoveUI()
        elseif command == "texture" or command == "t" then
            SetTexture(argument)
        elseif command == "cutter" or command == "c" then
            ToggleCutter()
        else
            AddOn:Print(L["ChatCommand_usage"])
            AddOn:Printf("|cffffee00/halionhelper help|r - %s", L["ChatCommand_help"])
            AddOn:Printf("|cffffee00/halionhelper enable|r - %s", L["ChatCommand_enable"])
            AddOn:Printf("|cffffee00/halionhelper move|r - %s", L["ChatCommand_move"])
            AddOn:Printf("|cffffee00/halionhelper texture NAME|r - %s", L["ChatCommand_texture"])
            AddOn:Printf("|cffffee00/halionhelper cutter|r - %s", L["ChatCommand_cutter"])
        end
    end

    AddOn:RegisterChatCommand("halionhelper", "ChatCommand")
end

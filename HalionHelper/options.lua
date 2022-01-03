local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.options = module
local L = ns.L

function module:Initialize()

    local function ToggleAddon()

        AddOn.db.profile.enable = not (AddOn.db.profile.enable or false)
        AddOn:OnZoneChange()
    end

    local moving = false
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

        if not moving then
            AddOn.modules.corporeality.ui:Enable()
            AddOn.modules.corporeality.ui:StartTimer(15)
        else
            AddOn.modules.corporeality.ui:StopTimer()

            -- UI phase 2 / 3 can't be shown at the same time, so we use the same position
            local origin, _, _, x, y = AddOn.modules.corporeality.ui.uiFrame:GetPoint(1)
            AddOn.db.profile.ui.origin = origin
            AddOn.db.profile.ui.x = x
            AddOn.db.profile.ui.y = y

            AddOn.modules.bar:RefreshUI()
        end

        moving = not moving
    end

    local function ToggleCutter()

        AddOn.db.profile.showCutterFrame = not (AddOn.db.profile.showCutterFrame or false)

        AddOn.modules.twilightCutter:Disable()
        AddOn.modules.twilightCutter:Enable()
    end

    local function ToggleAnnounceOpenPhase2()

        AddOn.db.profile.announceOpenPhase2 = not (AddOn.db.profile.announceOpenPhase2 or false)

        AddOn.modules.announceOpenPhase2:Disable()
        AddOn.modules.announceOpenPhase2:Enable()
    end

    local function GetTexture()

        local LSM = LibStub("LibSharedMedia-3.0", true) or assert(nil, "LibSharedMedia missing")

        for key, texture in pairs(LSM:HashTable(LSM.MediaType.STATUSBAR, AddOn.db.profile.texture)) do
            if texture == AddOn.db.profile.texture then
                return key
            end
        end

        return LSM:GetDefault(LSM.MediaType.STATUSBAR)
    end

    local function SetTexture(_, name)

        local LSM = LibStub("LibSharedMedia-3.0", true) or assert(nil, "LibSharedMedia missing")

        if LSM:IsValid(LSM.MediaType.STATUSBAR, name) then
            AddOn.db.profile.texture = LSM:Fetch(LSM.MediaType.STATUSBAR, name)
            AddOn.modules.bar:RefreshUI()
        else
            AddOn:Printf(L["option_texture_error"], name)
        end
    end

    local statusBarTextures = AceGUIWidgetLSMlists.statusbar or assert(AceGUIWidgetLSMlists, "AceGUIWidgetLSM missing")
    local options = {
        name = L["Settings"],
        handler = module,
        type = "group",
        args = {
            header_text = {
                type = "description",
                order = 10,
                name = L["option_header_desc"],
            },
            enable = {
                type = "toggle",
                width  = "full",
                order = 20,
                name = L["option_enable_name"],
                desc = L["option_enable_desc"],
                get = function() return AddOn.db.profile.enable end,
                set = ToggleAddon,
            },
            move = {
                type = "toggle",
                width  = "full",
                order = 30,
                name = L["option_move_name"],
                desc = L["option_move_desc"],
                get = function() return moving end,
                set = MoveUI,
            },
            cutter = {
                type = "toggle",
                width  = "full",
                order = 40,
                name = L["option_cutter_name"],
                desc = L["option_cutter_desc"],
                descStyle = "inline",
                get = function() return AddOn.db.profile.showCutterFrame end,
                set = ToggleCutter,
            },
            texture = {
                type = "select",
                order = 50,
                dialogControl = "LSM30_Statusbar",
                name = L["option_texture_name"],
                desc = L["option_texture_desc"],
                values = statusBarTextures,
                get = GetTexture,
                set = SetTexture,
            },
            announceOpenPhase2 = {
                type = "toggle",
                width  = "full",
                order = 60,
                name = L["option_announceOpenPhase2_name"],
                desc = L["option_announceOpenPhase2_desc"],
                descStyle = "inline",
                get = function() return AddOn.db.profile.announceOpenPhase2 end,
                set = ToggleAnnounceOpenPhase2,
            },
        },
    }

    local registry = LibStub('AceConfigRegistry-3.0')
    local dialog = LibStub('AceConfigDialog-3.0')
    local profile = LibStub('AceDBOptions-3.0'):GetOptionsTable(AddOn.db)

    registry:RegisterOptionsTable(AddOn.NAME .. 'Options', options)
    registry:RegisterOptionsTable(AddOn.NAME .. 'Profiles', profile)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddOn.NAME, options, { AddOn.NAME, "hh" }) -- just for chat
    dialog:AddToBlizOptions(AddOn.NAME .. 'Options', L["AddonName"])
    dialog:AddToBlizOptions(AddOn.NAME .. 'Profiles', 'Profiles', L["AddonName"])

end

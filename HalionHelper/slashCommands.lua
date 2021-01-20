local mod = _G.HalionHelper

mod.modules.slashCommands = {}

function mod.modules.slashCommands:Initialize()

    local _self = self

    mod:RegisterChatCommand("halionhelper", "ChatCommand")

    function mod:ChatCommand(args)

        local arg1, arg2 = self:GetArgs(args, 2)

        if arg1 == "move" then
            _self:MoveUI()
        elseif arg1 == "texture" then
            _self:SetTexture(arg2)
        elseif arg1 == "forceDataCollect" then
            _self:ForceDataCollect()
        else
            mod:Print("Usage:")
            mod:Print("|cffffee00/halionhelper help|r - List available subcommands")
            mod:Print("|cffffee00/halionhelper move|r - Display addon interfaces to customize frames positions")
            mod:Print("|cffffee00/halionhelper texture NAME|r - Set texture of statusbar")
            mod:Print("|cffffee00/halionhelper forceDataCollect|r - Force the collect of datas. By default, collect are activated for RL, offiers and MT")
        end
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

            mod:Print("movable mode enabled. Disable it to save potition.")
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
            mod:Print("LibSharedMedia not available.")

            return
        end

        if LSM:IsValid(LSM.MediaType.STATUSBAR, name) then
            mod.db.profile.texture = LSM:Fetch(LSM.MediaType.STATUSBAR, name)
            mod:Print("Texture saved! Please reload to apply.")
        else
            mod:Print(name .. " is not available as '" .. LSM.MediaType.STATUSBAR .. "' texture!")
        end
    end

    function self:ForceDataCollect()
        if mod.db.profile.forceDataCollect then
            mod.db.profile.forceDataCollect = false

            mod.modules.phase2CollectHealth:ManageCollectActivation()
            mod.modules.phase3CollectLog:ManageCollectActivation()
        else
            mod.db.profile.forceDataCollect = true

            mod.modules.phase2CollectHealth:ManageCollectActivation()
            mod.modules.phase3CollectLog:ManageCollectActivation()
        end

        mod:Print("Collect of datas forced to: " .. tostring(mod.db.profile.forceDataCollect))
    end
end

-- Initialize chat command
mod.modules.slashCommands:Initialize()

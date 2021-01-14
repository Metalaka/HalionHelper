local mod = _G.HalionHelper

mod.modules.CollectHealthPhase2 = {}

function mod.modules.CollectHealthPhase2:Initialize()

    function self:Enable()
        self.frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end

    function self:Disable()
        local frame = _G["Boss2TargetFrame"]
        if frame then
            frame:SetScript("OnUpdate", nil)
        end
    end

    --

    local _self = mod.modules.CollectHealthPhase2

    function self:SetHandler(frame)

        if UnitExists(frame.unit) --[[and frame.unit == "boss2"]] and UnitName(frame.unit) == mod.BOSS_NAME then
--            DEFAULT_CHAT_FRAME:AddMessage("CollectHealthPhase2 bound on " .. frame.unit)
            frame:SetScript("OnUpdate", self.OnUpdate)
        end
    end

    function self.OnUpdate(frame, elapsed)
        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0
            local _, hmax = frame.healthbar:GetMinMaxValues()
            local percent = frame.healthbar.currValue / hmax

            if percent > 0.75 then
                --                SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_END, nil, "RAID")
                return
            end

            --        DEFAULT_CHAT_FRAME:AddMessage(frame.unit .. ": " .. percent)

            if percent < 0.5 then
                SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_END, nil, "RAID")
                frame:SetScript("OnUpdate", nil)
            end


            -- send addonmsg
            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P2_DATA, percent, "RAID")
        end
    end

    -- init
    self.frame = CreateFrame("Frame")
    function self.frame:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
        local frame = _G["Boss2TargetFrame"]
        if frame then
            _self:SetHandler(frame)
        end
        --[[
                for i = 1, MAX_BOSS_FRAMES do
                    local name = "Boss" .. i .. "TargetFrame"
                    local frame = _G[name]

                    m:SetHandler(frame)
                end
        ]]
    end

    self.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

    --todo: besoin d'un leave combat pour reset en cas de mort ?
end

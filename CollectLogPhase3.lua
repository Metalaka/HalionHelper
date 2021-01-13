local mod = _G.HalionHelper

mod.modules.CollectLogPhase3 = {
    enable = false,
    amount = {
        [mod.NPC_ID_HALION_PHYSICAL] = 0,
        [mod.NPC_ID_HALION_TWILIGHT] = 0,
    },
    isFirstCorporeality = true,
    side = {
        npcId = nil,
        corporeality = nil,
    },
    prefs = {
        iconsSet = "SPELL"
    },
    --
    corporealityAuras = {
        [74836] = { dealt = -70, taken = -100, }, --  70% less dealt, 100% less taken
        [74835] = { dealt = -50, taken = -80, }, --  50% less dealt,  80% less taken
        [74834] = { dealt = -30, taken = -50, }, --  30% less dealt,  50% less taken
        [74833] = { dealt = -20, taken = -30, }, --  20% less dealt,  30% less taken
        [74832] = { dealt = -10, taken = -15, }, --  10% less dealt,  15% less taken
        [74826] = { dealt = 1, taken = 1, }, --  normal
        [74827] = { dealt = 15, taken = 20, }, --  15% more dealt,  20% more taken
        [74828] = { dealt = 30, taken = 50, }, --  30% more dealt,  50% more taken
        [74829] = { dealt = 60, taken = 100, }, --  60% more dealt, 100% more taken
        [74830] = { dealt = 100, taken = 200, }, -- 100% more dealt, 200% more taken
        [74831] = { dealt = 200, taken = 400, }, -- 200% more dealt, 400% more taken
    },
    iconsSets = {
        ["REALM"] = {
            --            Twilight = 75486, -- Dusk Shroud
            Twilight = 74807, -- Twilight Realm
            Physical = 75949, -- Meteor Strike
        },
        ["SPELL"] = {
            Twilight = 77846, -- Twilight Cutter
            Physical = 75887, -- Blazing Aura
        },
    },
}

function mod.modules.CollectLogPhase3:Initialize()

    function self:Enable()

        self:CreateTimer()
        self:CreateCorporealityBar()

        self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterEvent("CHAT_MSG_ADDON")
    end

    function self:Disable()
        self.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:UnregisterEvent("CHAT_MSG_ADDON")

        self.frame:SetScript("OnUpdate", nil)
    end

    --

    local _self = mod.modules.CollectLogPhase3

    function self.side:IsPhysical()
        return self.npcId == mod.NPC_ID_HALION_PHYSICAL
    end

    function self.side:IsTwilight()
        return self.npcId == mod.NPC_ID_HALION_TWILIGHT
    end

    function self:InitializeDataCollect()
        function self:SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:EnvironmentalDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, enviromentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:SpellAuraAppliedRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)

            local aura = self.corporealityAuras[spellId]

            if aura then

                self.side.npcId = tonumber(dstGUID:sub(-12, -7), 16)
                self.side.corporeality = aura

                if self.isFirstCorporeality then
                    self.isFirstCorporeality = false
                    self.enable = true
                    self.timer:StartTimer(5) -- display 5sec wait timer
                    mod:ScheduleTimer(function() _self:StartMonitor() end, 5)
                else
                    self:StartMonitor()
                end
            end
        end

        function self:AddDamageData(dstGUID, amount)

            local npcId = tonumber(dstGUID:sub(-12, -7), 16)

            self.amount[npcId] = self.amount[npcId] + amount
        end

        local EventParse =
        {
            ["SWING_DAMAGE"] = self.SwingDamage,
            ["RANGE_DAMAGE"] = self.SpellDamage,
            ["SPELL_DAMAGE"] = self.SpellDamage,
            ["SPELL_PERIODIC_DAMAGE"] = self.SpellDamage,
            ["DAMAGE_SHIELD"] = self.SpellDamage,
            ["DAMAGE_SPLIT"] = self.SpellDamage,
            ["ENVIRONMENTAL_DAMAGE"] = self.EnvironmentalDamage,
            ["SPELL_AURA_APPLIED"] = self.SpellAuraAppliedRemoved,
        }

        function self:CombatLogEvent(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)

            if dstName ~= mod.BOSS_NAME then
                return
            end
            if not self.enable and not (eventtype == "SPELL_AURA_APPLIED" and srcGUID == dstGUID) then
                return
            end

            local parsefunc = EventParse[eventtype]

            if parsefunc then
                parsefunc(self, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)
            end
        end

        self.frame = CreateFrame("Frame", "HalionHelper_CollectLogPhase3")
        self.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

        function self.frame:COMBAT_LOG_EVENT_UNFILTERED(...)
            _self:CombatLogEvent(...)
        end
    end

    function self:InitializeUI()

        function self:StartMonitor()
            self.amount[self.side.npcId] = 0
            self.timer:StartTimer(15)

            if not self.CorporealityBar:IsShown() then
                self.CorporealityBar:Show()
            end
        end

        function self:CalculatePercent()
            local total = self.amount[mod.NPC_ID_HALION_TWILIGHT] + self.amount[mod.NPC_ID_HALION_PHYSICAL]

            return self.amount[mod.NPC_ID_HALION_PHYSICAL] / mod:max(total, 1)
        end

        function self:ShoudGoTwilight()
            local c = self.side.corporeality

            -- by default go Twilight
            if self.side:IsTwilight() and c.dealt >= 1 then
                return true
            elseif self.side:IsPhysical() and c.dealt <= 1 then
                return true
            else
                return false
            end
        end

        local UIFrame = CreateFrame("Frame", "HalionHelper_CollectLogPhase3_UIFrame", UIParent)
    self.UIFrame = UIFrame
        -- moves
        UIFrame:SetMovable(true)
        UIFrame:EnableMouse(true)
        UIFrame:RegisterForDrag("LeftButton")
        UIFrame:SetScript("OnDragStart", UIFrame.StartMoving)
        UIFrame:SetScript("OnDragStop", UIFrame.StopMovingOrSizing)
        UIFrame:SetPoint("CENTER")
        UIFrame:SetSize(200, 80)

        function self:CreateTimer()

            self.timer = mod.modules.Bar:NewBar("HalionHelper_CollectLogPhase3_Timer", UIFrame)
            self.timer:SetPoint("BOTTOM")
            self.timer.expire = nil

            self.timer:SetScript("OnUpdate", function(self)
                local left = self.expire - GetTime()

                if (left < 0) then
                    self:StopTimer()
                else
                    self:SetValue(left)
                end
            end)

            function self.timer:StartTimer(time)
                self.expire = GetTime() + time
                self.StatusBar:SetMinMaxValues(0, time)
                self.StatusBar:SetValue(time)
                self:Show()
            end

            function self.timer:StopTimer()
                self.expire = nil
                self:Hide()
            end

            function self.timer:SetValue(left)
                self.StatusBar:SetValue(left)
                self.StatusBar.timeText:SetText(self:FormatTime(left) .. " sec")
            end

            function self.timer:FormatTime(left)
                if (not left or not type(left) == 'number' or left < 0) then left = 0 end
                if (left < 10) then
                    return (string.format("%01.1f", left))
                elseif (left < 60) then
                    return (string.format("%d", left))
                else
                    return (string.format("%d:%02d", left / 60, left % 60))
                end
            end
        end

        function self:CreateCorporealityBar()

            function self:SetIcon(entry, spellId)
                if not entry then return end

                local icon = select(3, GetSpellInfo(spellId))

                entry:SetNormalTexture(icon)
                if (icon) then
                    entry:GetNormalTexture():SetTexCoord(.07, .93, .07, .93)
                end
            end

            self.CorporealityBar = mod.modules.Bar:NewBar("HalionHelper_CollectLogPhase3_CorporealityBar", UIFrame)
            self.CorporealityBar:SetPoint("TOP")
            self.CorporealityBar.StatusBar:SetValue(0.5)

            self.CorporealityBar.TwilightIcon = CreateFrame("Button", nil, self.CorporealityBar)
            self.CorporealityBar.TwilightIcon:SetHeight(30)
            self.CorporealityBar.TwilightIcon:SetWidth(30)
            self.CorporealityBar.TwilightIcon:SetPoint("LEFT")
            self:SetIcon(self.CorporealityBar.TwilightIcon, self.iconsSets[self.prefs.iconsSet].Twilight)

            self.CorporealityBar.PhysicalIcon = CreateFrame("Button", nil, self.CorporealityBar)
            self.CorporealityBar.PhysicalIcon:SetHeight(30)
            self.CorporealityBar.PhysicalIcon:SetWidth(30)
            self.CorporealityBar.PhysicalIcon:SetPoint("RIGHT")
            self:SetIcon(self.CorporealityBar.PhysicalIcon, self.iconsSets[self.prefs.iconsSet].Physical)

            self.CorporealityBar:SetScript("OnUpdate", function(frame, elapsed)

                frame.elapsed = (frame.elapsed or 0) + elapsed
                if frame.elapsed > mod.SLEEP_DELAY then
                    frame.elapsed = 0

                    _self.CorporealityBar:SetValue(_self:CalculatePercent())
                end
            end)

            function self.CorporealityBar:SetValue(value)
                self.StatusBar:SetValue(value)
                self.StatusBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")
                local shoudGoTwilight = _self:ShoudGoTwilight()

                if shoudGoTwilight and value > 0.5 and _self.side.corporeality.taken == 1 then
                    self.StatusBar:SetStatusBarColor(1, 0.6, 0.05)
                elseif (shoudGoTwilight and value > 0.5) or (not shoudGoTwilight and value < 0.5) then
                    self.StatusBar:SetStatusBarColor(1, 0, 0)
                else
                    self.StatusBar:SetStatusBarColor(0, 1, 0)
                end
            end
        end
    end

    self:InitializeDataCollect()
    self:InitializeUI()

    self.frame:SetScript("OnUpdate", function(frame, elapsed)

        if not _self.enable or not _self.side.npcId or _self.amount[_self.side.npcId] == 0 then
            return
        end

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0

            local payload = _self.side.npcId .. ":" .. _self.amount[_self.side.npcId]
            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3, payload, "RAID")
        end
    end)

    function self.frame:CHAT_MSG_ADDON(prefix, message)

        if not _self.enable or not _self.side.npcId then
            return
        end

        if (prefix == mod.ADDON_MESSAGE_PREFIX_P3) then
            local npcId, amount = mod:cut(message, ":")
            npcId = tonumber(npcId)

            if _self.side.npcId == npcId then
                -- don't change our data
                return
            end

            _self.amount[npcId] = tonumber(amount)
        end
    end

    function self.frame:PLAYER_REGEN_ENABLED()

        self.enable = false
        self.isFirstCorporeality = false

        if self.CorporealityBar:IsShown() then
            self.CorporealityBar:Hide()
        end
    end
end

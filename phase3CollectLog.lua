local mod = _G.HalionHelper

mod.modules.phase3CollectLog = {
    enable = false,
    amount = {
        [mod.NPC_ID_HALION_PHYSICAL] = 0,
        [mod.NPC_ID_HALION_TWILIGHT] = 0,
    },
    isFirstCorporeality = true,
    shoudGoTwilight = nil,
    side = {
        npcId = nil,
        corporeality = nil,
    },
    prefs = {
        iconsSet = "REALM"
    },
    --
    corporealityAuras = {
        [74836] = { dealt = -70, taken = -100, }, --  70% less dealt, 100% less taken
        [74835] = { dealt = -50, taken = -80, }, --  50% less dealt,  80% less taken
        [74834] = { dealt = -30, taken = -50, }, --  30% less dealt,  50% less taken
        [74833] = { dealt = -20, taken = -30, }, --  20% less dealt,  30% less taken
        [74832] = { dealt = -10, taken = -15, }, --  10% less dealt,  15% less taken
        [mod.CORPOREALITY_AURA] = { dealt = 1, taken = 1, }, --  normal
        [74827] = { dealt = 15, taken = 20, }, --  15% more dealt,  20% more taken
        [74828] = { dealt = 30, taken = 50, }, --  30% more dealt,  50% more taken
        [74829] = { dealt = 60, taken = 100, }, --  60% more dealt, 100% more taken
        [74830] = { dealt = 100, taken = 200, }, -- 100% more dealt, 200% more taken
        [74831] = { dealt = 200, taken = 400, }, -- 200% more dealt, 400% more taken
    },
    iconsSets = {
        ["REALM"] = {
            --            Twilight = 75486, -- Dusk Shroud
            twilight = 74807, -- Twilight Realm
            physical = 75949, -- Meteor Strike
        },
        ["SPELL"] = {
            twilight = 77846, -- Twilight Cutter
            physical = 75887, -- Blazing Aura
        },
    },
}

function mod.modules.phase3CollectLog:Initialize()

    function self:Enable()
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

    local _self = mod.modules.phase3CollectLog
    self.dc, self.ui = {}, {}

    function self.side:IsPhysical()
        return self.npcId == mod.NPC_ID_HALION_PHYSICAL
    end

    function self.side:IsTwilight()
        return self.npcId == mod.NPC_ID_HALION_TWILIGHT
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

    function self.dc:InitializeDataCollect()
        function self:SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:EnvironmentalDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, enviromentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:SpellAura(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)

            local aura = _self.corporealityAuras[spellId]

            if aura then

                _self.side.npcId = tonumber(dstGUID:sub(-12, -7), 16)
                _self.side.corporeality = aura

                if _self.isFirstCorporeality then
                    _self.isFirstCorporeality = false
                    _self.enable = true
                    _self.ui.timer:StartTimer(5) -- display 5sec wait timer
                    mod:ScheduleTimer(function() _self:StartMonitor() end, 5)

                    -- send transition event to Physical Realm
                    SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3_TRANSITION, nil, "RAID")
                else
                    _self:StartMonitor()
                end
            end
        end

        function self:AddDamageData(dstGUID, amount)

            local npcId = tonumber(dstGUID:sub(-12, -7), 16)

            _self.amount[npcId] = _self.amount[npcId] + amount
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
            ["SPELL_AURA_APPLIED"] = self.SpellAura,
        }

        function self:CombatLogEvent(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)

            if dstName ~= mod.BOSS_NAME then
                return
            end
            if not _self.enable and not (eventtype == "SPELL_AURA_APPLIED" and srcGUID == dstGUID) then
                return
            end

            local parsefunc = EventParse[eventtype]

            if parsefunc then
                parsefunc(self, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)
            end
        end

        function _self.frame:COMBAT_LOG_EVENT_UNFILTERED(...)
            _self.dc:CombatLogEvent(...)
        end
    end

    function self.ui:InitializeUI()

        function self:CalculatePercent()
            local total = _self.amount[mod.NPC_ID_HALION_TWILIGHT] + _self.amount[mod.NPC_ID_HALION_PHYSICAL]

            return _self.amount[mod.NPC_ID_HALION_PHYSICAL] / mod:max(total, 1)
        end

        local uiFrame = CreateFrame("Frame", "HalionHelper_phase3CollectLog_uiFrame", UIParent)
        self.uiFrame = uiFrame
        uiFrame:SetPoint(mod.db.profile.P3.point, mod.db.profile.P3.x, mod.db.profile.P3.y)
--        uiFrame:SetPoint("CENTER")
        uiFrame:SetSize(200, 80)

        function self:InitializeTimer()

            self.timer = mod.modules.bar:NewBar("HalionHelper_phase3CollectLog_Timer", self.uiFrame)
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
                self.statusBar:SetMinMaxValues(0, time)
                self.statusBar:SetValue(time)
                self:Show()
            end

            function self.timer:StopTimer()
                self.expire = nil
                self:Hide()
            end

            function self.timer:SetValue(left)
                self.statusBar:SetValue(left)
                self.statusBar.timeText:SetText(self:FormatTime(left) .. " sec")
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

        function self:InitializeCorporealityBar()

            function self:SetIcon(frame, spellId)
                if not frame then return end

                local icon = select(3, GetSpellInfo(spellId))

                frame:SetNormalTexture(icon)
                if (icon) then
                    frame:GetNormalTexture():SetTexCoord(.07, .93, .07, .93)
                end
            end

            self.corporealityBar = mod.modules.bar:NewBar("HalionHelper_phase3CollectLog_corporealityBar", self.uiFrame)
            self.corporealityBar:SetPoint("TOP")
            self.corporealityBar.statusBar:SetValue(0.5)

            self.corporealityBar.twilightIcon = CreateFrame("Button", nil, self.corporealityBar)
            self.corporealityBar.twilightIcon:SetHeight(30)
            self.corporealityBar.twilightIcon:SetWidth(30)
            self.corporealityBar.twilightIcon:SetPoint("LEFT")
            self:SetIcon(self.corporealityBar.twilightIcon, _self.iconsSets[_self.prefs.iconsSet].twilight)
            self.corporealityBar.twilightIcon:EnableMouse(false)
            self.corporealityBar.twilightIcon:SetFrameLevel(self.corporealityBar.statusBar:GetFrameLevel() + 1)


            self.corporealityBar.physicalIcon = CreateFrame("Button", nil, self.corporealityBar)
            self.corporealityBar.physicalIcon:SetHeight(30)
            self.corporealityBar.physicalIcon:SetWidth(30)
            self.corporealityBar.physicalIcon:SetPoint("RIGHT")
            self:SetIcon(self.corporealityBar.physicalIcon, _self.iconsSets[_self.prefs.iconsSet].physical)
            self.corporealityBar.physicalIcon:EnableMouse(false)
            self.corporealityBar.physicalIcon:SetFrameLevel(self.corporealityBar.statusBar:GetFrameLevel() + 1)


            self.corporealityBar.startDelay = 0

            self.corporealityBar:SetScript("OnUpdate", function(frame, elapsed)

                frame.elapsed = (frame.elapsed or 0) + elapsed
                if frame.elapsed > mod.SLEEP_DELAY and frame.elapsed > frame.startDelay then
                    frame.elapsed = 0
                    frame.startDelay = 0

                    _self.ui.corporealityBar:SetValue(_self.ui:CalculatePercent())
                end
            end)

            function self.corporealityBar:SetValue(value)
                self.statusBar:SetValue(value)
                self.statusBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")

                --                if shoudGoTwilight and value > 0.5 and _self.side.corporeality.taken == 1 then
                --                    self.StatusBar:SetStatusBarColor(1, 0.6, 0.05)
                --                else
                if (_self.shoudGoTwilight and value > 0.5) or (not _self.shoudGoTwilight and value < 0.5) then
                    self.statusBar:SetStatusBarColor(1, 0, 0)
                else
                    self.statusBar:SetStatusBarColor(0, 1, 0)
                end
            end
        end

        self:InitializeTimer()
        self:InitializeCorporealityBar()
    end

    function self:StartMonitor()
        self.amount[self.side.npcId] = 0
        self.ui.timer:StartTimer(15)
        self.ui.corporealityBar.startDelay = 0.5

        self.shoudGoTwilight = self:ShoudGoTwilight()
    end

    self.frame = CreateFrame("Frame", "HalionHelper_phase3CollectLog")
    self.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

    self.frame:SetScript("OnUpdate", function(frame, elapsed)

        if not _self.enable or not _self.side.npcId or _self.amount[_self.side.npcId] == 0 then
            return
        end

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0

            local payload = _self.side.npcId .. ":" .. _self.amount[_self.side.npcId]
            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3_DATA, payload, "RAID")
        end
    end)

    function self.frame:CHAT_MSG_ADDON(prefix, message)

        if not _self.enable and prefix == mod.ADDON_MESSAGE_PREFIX_P3_TRANSITION and not mod:IsInTwilightRealm() then
            -- Boss in Physical Realm start P3 without a Corporeality aura.
            -- This hack start the P3 from the Twilight event
            _self.enable = true
            _self.isFirstCorporeality = false
            _self.side.npcId = mod.NPC_ID_HALION_PHYSICAL
            _self.side.corporeality = _self.corporealityAuras[mod.CORPOREALITY_AURA]

            _self.ui.timer:StartTimer(5) -- display 5sec wait timer
            mod:ScheduleTimer(function() _self:StartMonitor() end, 5)

        elseif _self.enable and prefix == mod.ADDON_MESSAGE_PREFIX_P3_DATA then
            local npcId, amount = mod:cut(message, ":")
            npcId = tonumber(npcId)

            if _self.side.npcId == npcId then
                -- don't change our data
                return
            end

            _self.amount[npcId] = tonumber(amount)

            -- Display here, so the bar is only shown where there is one addon in each realm
            if not _self.ui.corporealityBar:IsShown() then
                _self.ui.corporealityBar:Show()
            end
        end
    end

    function self.frame:PLAYER_REGEN_ENABLED()

        _self.enable = false
        _self.isFirstCorporeality = true

        _self.ui.timer:StartTimer(0)
        if _self.ui.corporealityBar:IsShown() then
            _self.ui.corporealityBar:Hide()
        end
    end

    self.dc:InitializeDataCollect()
    self.ui:InitializeUI()
end

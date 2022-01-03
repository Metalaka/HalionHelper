local _, ns = ...

local AddOn = ns.AddOn
local module = {}
AddOn.modules.bar = module

function module:Initialize()

    function self:NewBar(name, parent)

        local frame = CreateFrame("StatusBar", name, parent or UIParent)
        frame:SetHeight(20)
        frame:SetWidth(170)
        frame:SetPoint("CENTER")
        frame:SetStatusBarTexture(AddOn.db.profile.texture)
        frame:GetStatusBarTexture():SetHorizTile(false)
        frame:GetStatusBarTexture():SetVertTile(false)
        frame:SetMinMaxValues(0, 1)

        frame.background = frame:CreateTexture(nil, "BACKGROUND")
        frame.background:SetTexture(AddOn.db.profile.texture)
        frame.background:SetAllPoints()
        frame.background:SetVertexColor(0, 0, 0, 0.33)

        frame.timeText = frame:CreateFontString(nil, "OVERLAY")
        frame.timeText:SetPoint("CENTER")
        frame.timeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        frame.timeText:SetTextColor(1, 1, 1)

        frame:SetScript("OnEvent", function(self, event, ...)
            if self[event] then
                return self[event](self, ...)
            end
        end)
        module:RegisterBar(frame)
        module:RegisterBar(frame.background)

        return frame
    end

    function self:SetIcon(frame, spellId)

        if not frame then
            return
        end

        local icon = select(3, GetSpellInfo(spellId))

        frame:SetNormalTexture(icon)
        if (icon) then
            frame:GetNormalTexture():SetTexCoord(.07, .93, .07, .93)
        end
    end

    local bars = {}
    local callbacks = {}

    --- Register bar to be refreshed.
    function self:RegisterBar(bar)
        table.insert(bars, bar)
    end

    --- Register a callback to refresh a custom UI.
    function self:RegisterCallback(bar)
        table.insert(callbacks, bar)
    end

    --- Refresh UI. To be used after a texture/position changes.
    function self:RefreshUI()
        for _, frame in ipairs(bars) do
            if frame.SetStatusBarTexture then
                frame:SetStatusBarTexture(AddOn.db.profile.texture)
            end
            if frame.SetTexture then
                frame:SetTexture(AddOn.db.profile.texture)
            end
        end
        for _, callback in ipairs(callbacks) do
            callback()
        end
    end

    --

    function self:Enable()
    end

    function self:Disable()
    end
end
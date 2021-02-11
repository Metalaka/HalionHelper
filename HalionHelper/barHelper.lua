local mod = _G.HalionHelper

mod.modules.bar = {}

function mod.modules.bar:Initialize()

    function self:Enable()
    end

    function self:Disable()
    end

    --

    local _self = self

    function self:NewBar(name, parent)

        local frame = CreateFrame("StatusBar", name, parent or UIParent)
        frame:SetHeight(20)
        frame:SetWidth(170)
        frame:SetPoint("CENTER")
        frame:SetStatusBarTexture(mod.db.profile.texture)
        frame:GetStatusBarTexture():SetHorizTile(false)
        frame:GetStatusBarTexture():SetVertTile(false)
        frame:SetMinMaxValues(0, 1)

        frame.background = frame:CreateTexture(nil, "BACKGROUND")
        frame.background:SetTexture(mod.db.profile.texture)
        frame.background:SetAllPoints()
        frame.background:SetVertexColor(0, 0, 0, 0.33)

        frame.timeText = frame:CreateFontString(nil, "OVERLAY")
        frame.timeText:SetPoint("CENTER")
        frame.timeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        frame.timeText:SetTextColor(1, 1, 1)

        frame:SetScript("OnEvent",
            function(self, event, ...) if self[event] then return self[event](self, ...) end end)

        return frame
    end

    function self:SetIcon(frame, spellId)
        if not frame then return end

        local icon = select(3, GetSpellInfo(spellId))

        frame:SetNormalTexture(icon)
        if (icon) then
            frame:GetNormalTexture():SetTexCoord(.07, .93, .07, .93)
        end
    end
end
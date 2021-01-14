local mod = _G.HalionHelper

mod.modules.bar = {
    texture = nil,
}

function mod.modules.bar:Initialize()

    function self:Enable()
    end

    function self:Disable()
    end

    --

    local _self = self

    function self:NewBar(name, parent)

        local frame = CreateFrame("Frame", name, parent or UIParent)

        frame:SetSize(200, 50)

        frame.statusBar = CreateFrame("StatusBar", nil, frame)
        frame.statusBar:SetHeight(20)
        frame.statusBar:SetWidth(200)
        frame.statusBar:SetPoint("LEFT")
        frame.statusBar:SetStatusBarTexture(mod.db.profile.texture)
        frame.statusBar:GetStatusBarTexture():SetHorizTile(false)
        frame.statusBar:GetStatusBarTexture():SetVertTile(false)
        frame.statusBar:SetMinMaxValues(0, 1)

        frame.statusBar.background = frame.statusBar:CreateTexture(nil, "BACKGROUND")
        frame.statusBar.background:SetTexture(self.texture)
        frame.statusBar.background:SetAllPoints()
        frame.statusBar.background:SetVertexColor(0, 0, 0, 0.33)

        frame.statusBar.timeText = frame.statusBar:CreateFontString(nil, "OVERLAY")
        frame.statusBar.timeText:SetPoint("CENTER")
        frame.statusBar.timeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        frame.statusBar.timeText:SetTextColor(1, 1, 1)

        frame:Hide()

        frame:SetScript("OnEvent",
            function(self, event, ...) if self[event] then return self[event](self, ...) end end)

        return frame
    end
end
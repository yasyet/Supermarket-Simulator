local Plot = {}
Plot.__index = Plot

function Plot:UpdatePlotVisual()

    local FrontGui = self.Plot.FrontGuiPart.FrontGui
    local OwnerText = FrontGui.OwnerText
    OwnerText.Text = self.Owner.Name .. "'s Plot"

end

function Plot.new(plot, player)
    local self = setmetatable({}, Plot)

    plot:SetAttribute("Owner", player.UserId)
    player:SetAttribute("Plot", plot.Name)

    self.Owner = player
    self.Plot = plot

    self:UpdatePlotVisual()

    return self
end

return Plot

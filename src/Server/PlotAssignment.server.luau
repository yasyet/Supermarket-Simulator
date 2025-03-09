local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Plot = require(ReplicatedStorage.Classes.Plot)
local PlotFolder = workspace.Plots
local AllPlots = PlotFolder:GetChildren()

local function ClaimPlot(player, plot)
    if plot:GetAttribute("Owner") == nil then
        return true
    end
    return false
end

Players.PlayerAdded:Connect(function(player)
    for _, plot in ipairs(AllPlots) do

        if ClaimPlot(player, plot) then
            local newPlot = Plot.new(plot, player)
            break
        end

    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ReplicatedStorage Content
local Modules = ReplicatedStorage.Modules
local Remote = ReplicatedStorage.Remote
local Assets = ReplicatedStorage.Assets

-- Modules
local Utility = require(Modules.Utility)

-- Remote Events
local PlaceFurniture = Remote.PlaceFurnitureRemote

-- Handle Furniture Placement
PlaceFurniture.OnServerEvent:Connect(function(player, plotName, itemName, modelCFrame)
    -- Validate plot ownership
    local plot = Utility.GetPlotByName(plotName)
    if plot:GetAttribute("Owner") ~= player.UserId then
        warn("Player", player.Name, "attempted to place furniture in plot they don't own")
        return
    end

    -- Validate plot exists
    if not plot or not plot:IsA("Model") then
        warn("Invalid plot received from", player.Name)
        return
    end

    -- Find item model in ReplicatedStorage by name
    local itemTemplate = Assets.Furniture:FindFirstChild(itemName)
    if not itemTemplate then
        warn("Item not found:", itemName)
        return
    end

    -- Create new model instance server-side
    local placedModel = itemTemplate:Clone() -- Set attributes

    local overideAttributes = {
        Owner = player.UserId,
        PlacedTime = os.time(),
        PrimaryCFrame = modelCFrame,
        ModelName = itemName
    }

    Utility.SetFurnitureAttribute(placedModel, player, overideAttributes)

    -- Position the model
    if placedModel.PrimaryPart then
        placedModel:SetPrimaryPartCFrame(modelCFrame)
    else
        warn("Model has no PrimaryPart:", itemName)
        return
    end

    -- Parent to plot
    placedModel.Parent = plot
end)

local Utility = {}

-- Function to return raycast result of item from screen position
function Utility.ShootRaycast(camera, direction, player, MAX_DISTANCE)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Liste aller zu ignorierenden Objekte
    local filterList = {camera}

    -- Füge alle Spielercharaktere hinzu
    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
        if p.Character then
            table.insert(filterList, p.Character)
        end
    end

    rayParams.FilterDescendantsInstances = filterList

    local raycastResult = workspace:Raycast(camera.CFrame.Position, direction * MAX_DISTANCE, rayParams)
    return raycastResult
end

-- Function to check if object is in part
function Utility.IsObstructed(part, blacklist)
    -- If blacklist is not a table, convert it to a table
    if type(blacklist) ~= "table" then
        blacklist = blacklist and {blacklist} or {}
    end

    -- Get part properties
    local partCFrame = part.CFrame
    local partSize = part.Size

    -- Set overlap parameters
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
    overlapParams.FilterDescendantsInstances = blacklist

    -- Get parts in box
    local partsInBox = workspace:GetPartBoundsInBox(partCFrame, partSize, overlapParams)

    -- Return true if partsInBox is not empty
    return #partsInBox > 1
end

-- Set attributes of model & serialze it
function Utility.SetFurnitureAttribute(model, player, overideAttributes)

    if overideAttributes then
        for key, value in pairs(overideAttributes) do
            model:SetAttribute(key, value)
        end
        return
    end

    model:SetAttribute("Owner", player.UserId)
    model:SetAttribute("PlacedTime", os.time())
    model:SetAttribute("PrimaryCFrame", model.PrimaryPart.CFrame)
    model:SetAttribute("ModelName", model.Name)
end

-- Get plot by name
function Utility.GetPlotByName(plotName)
    local plot = workspace.Plots:FindFirstChild(plotName)
    return plot
end

-- Round CFrame to x studs
function Utility.RoundToNearestStud(raycastCFrame, studSize)
    local position = raycastCFrame.Position
    local x = math.floor(position.X / studSize + 0.5) * studSize
    local y = raycastCFrame.Y
    local z = math.floor(position.Z / studSize + 0.5) * studSize

    local newPosition = Vector3.new(x, y, z)
    local newCFrame = CFrame.new(newPosition, newPosition + raycastCFrame.LookVector)
    return newCFrame
end

return Utility

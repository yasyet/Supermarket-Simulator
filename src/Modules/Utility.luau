local Utility = {}

-- Function to return raycast result of item from screen position
function Utility.ShootRaycast(camera, direction, player, MAX_DISTANCE)
    -- Filter out the camera and the player's character
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {camera, player.Character}

    local raycastResult = workspace:Raycast(camera.CFrame.Position, direction * MAX_DISTANCE, rayParams)

    if raycastResult then
        return raycastResult
    else
        return nil
    end
end

-- Function to check if object is in part
function Utility.IsObstructed(part, blacklist)
    -- Create a region around the part
    local region = Region3.new(part.Position - (part.Size / 2), part.Position + (part.Size / 2))

    -- Calculate the parts in the region
    local partsInRegion = workspace:FindPartsInRegion3WithIgnoreList(region, blacklist, math.huge)

    -- If there is more than one part in the region, return true (since it includes the floor)
    return #partsInRegion > 1
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

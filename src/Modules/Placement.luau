local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- ReplicatedStorage Content
local Data = ReplicatedStorage.Data
local Modules = ReplicatedStorage.Modules
local Assets = ReplicatedStorage.Assets
local Remote = ReplicatedStorage.Remote

local Placement = {}

-- Data
local ItemData = require(Data.Items)

-- Modules
local Utility = require(Modules.Utility)

-- Assets
local PlacementErrorHighlight = Assets.Highlights.PlacementError
local PlacementSuccessHighlight = Assets.Highlights.PlacementSuccess

-- Remote
local PlaceFurnitureRemote = Remote.PlaceFurnitureRemote

-- Utility: Disable/Enable Collission of Model
local function SetModelCollission(model, value)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then

            if part.Name == "Collission" then
                part.CanCollide = false
                part.CanQuery = false
                continue
            end

            part.CanCollide = value
            part.CanQuery = value
        end
    end
end

local currentRotation = 0 -- Track current rotation
local function RotateModel(model, rotation)
    local position = model.PrimaryPart.Position
    local newCFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
    model:PivotTo(newCFrame)
end

local newCFrame = nil
-- Place Model
local function PlaceModel(model, raycastPosition, raycastSurface)
    if model:GetAttribute("HitSurface") == "Wall" then
        newCFrame = CFrame.new(raycastPosition, raycastPosition + raycastSurface)
    else
        newCFrame = CFrame.new(raycastPosition) * CFrame.Angles(0, math.rad(currentRotation), 0)
    end

    newCFrame = Utility.RoundToNearestStud(newCFrame, 0.5)
    model:SetPrimaryPartCFrame(newCFrame)
    model.Parent = workspace
end

-- Update color of model's highlight
local function UpdateModelHighlight(model, raycastInstance, player, canPlace)

    -- Check if player is in placement mode
    if not player:GetAttribute("Placement") then
        return
    end

    local modelDescendants = model:GetDescendants()

    -- Utility: Find Highlight
    local function findHighlight(highlightType)
        for _, descendant in ipairs(modelDescendants) do
            if descendant.Name == highlightType.Name then
                return descendant
            end
        end
        return nil
    end
    
    -- Fix: Change condition to show error when obstructed OR not own plot
    if not canPlace then
        -- Remove Success Highlight if present
        local successHighlight = findHighlight(PlacementSuccessHighlight)
        if successHighlight then
            successHighlight:Destroy()
        end

        -- Add Error Highlight if not already present
        local errorHighlight = findHighlight(PlacementErrorHighlight)
        if not errorHighlight then
            local newErrorHighlight = PlacementErrorHighlight:Clone()
            newErrorHighlight.Parent = model
        end
    else
        -- Remove Error Highlight
        local errorHighlight = findHighlight(PlacementErrorHighlight)
        if errorHighlight then
            errorHighlight:Destroy()
        end

        -- Add Success Highlight
        local successHighlight = findHighlight(PlacementSuccessHighlight)
        if not successHighlight then
            local newSuccessHighlight = PlacementSuccessHighlight:Clone()
            newSuccessHighlight.Parent = model
        end
    end
end

local function CheckPlacingSurface(itemModel, raycastInstance)
    local HitTags = raycastInstance:GetTags()
    local modelHitSurface = itemModel:GetAttribute("HitSurface")
    local hitSurface = nil

    if not modelHitSurface then
        warn("HitSurface attribute not found in model")
        return false
    end

    if table.find(HitTags, "Floor") then
        hitSurface = "Floor"
    elseif table.find(HitTags, "Wall") then
        hitSurface = "Wall"
    elseif table.find(HitTags, "Ceiling") then
        hitSurface = "Ceiling"
    end

    return hitSurface == modelHitSurface
end

local function PlaceModelMobile(player, itemModel)
    -- Set collision state
    SetModelCollission(itemModel, false)

    -- Track if placement is valid
    local canPlace = false
    local currentPlot = nil

    -- Store connection to clean up later
    local keybindConnection = nil
    keybindConnection = {UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if not itemModel.PrimaryPart then
            return
        end

        if input.UserInputType == Enum.UserInputType.Touch then
            if not input.UserInputState == Enum.UserInputState.Begin then
                return
            end

            local touchPosition = input.Position
            local camera = workspace.CurrentCamera
            local unitRay = camera:ViewportPointToRay(touchPosition.X, touchPosition.Y)
            local direction = unitRay.Direction

            local raycastResult = Utility.ShootRaycast(camera, direction, player, 100)
            if not raycastResult then
                return
            end

            local raycastPosition = raycastResult.Position
            local raycastInstance = raycastResult.Instance

            currentPlot = raycastInstance:FindFirstAncestor("Plot")
            
            local ownPlot = false
            if currentPlot then
                ownPlot = currentPlot:GetAttribute("Owner") == player.UserId
            else
                ownPlot = false
            end

            local modelObstructed = Utility.IsObstructed(itemModel.Collission, itemModel:GetDescendants())

            local HitTags = raycastInstance:GetTags()

            -- Update placement validity
            canPlace = not modelObstructed and ownPlot and currentPlot ~= nil

            -- Update model's highlight
            UpdateModelHighlight(itemModel, raycastInstance, player, canPlace)

            if not CheckPlacingSurface(itemModel, raycastInstance) then
                canPlace = false
                return
            end

            PlaceModel(itemModel, raycastPosition, raycastResult.Normal)
        end
    end),

    UserInputService.TouchTap:Connect(function(touchPosition, gameProcessed)
        if gameProcessed then
            return
        end

        if not canPlace then
            return
        end

        print("TouchTap")

        local touchPosition = touchPosition[1]

        local camera = workspace.CurrentCamera
        local unitRay = camera:ViewportPointToRay(touchPosition.X, touchPosition.Y)

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {camera, player.Character}

        local raycastResult = workspace:Raycast(camera.CFrame.Position, unitRay.Direction * 100, raycastParams)
        if not raycastResult then
            return
        end

        -- Remove all highlights
        for _, desc in pairs(itemModel:GetDescendants()) do
            if desc:IsA("Highlight") then
                desc:Destroy()
            end
        end

        -- Parent to plot
        itemModel.Parent = currentPlot

        -- First disconnect connection
        for _, connection in pairs(keybindConnection) do
            connection:Disconnect()
        end


        -- Then disable placement mode
        player:SetAttribute("Placement", false)

        -- Hide placement GUI
        player.PlayerGui:WaitForChild("PlacementGui").Enabled = false

        -- End interacting mode
        player:SetAttribute("Interacting", false)

        -- Emit event to server
        PlaceFurnitureRemote:FireServer(currentPlot.Name, itemModel.Name, newCFrame)

        task.wait(0.1)

        -- Delete itemModel
        itemModel:Destroy()
        itemModel = nil
    end)
    }
end

local function PlaceModelNonMobile(player, itemModel)
    local Camera = workspace.CurrentCamera
    
    -- Set collision state
    SetModelCollission(itemModel, false)
    
    -- Track if placement is valid
    local canPlace = false
    local currentPlot = nil
    
    -- Store connection to clean up later
    local keybindConnection = nil
    keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if not itemModel.PrimaryPart then return end
        
        if itemModel:GetAttribute("HitSurface") ~= "Wall" then
            -- Handle rotation
            if input.KeyCode == Enum.KeyCode.E then
    
                currentRotation = currentRotation + 90
                RotateModel(itemModel, currentRotation)
    
            elseif input.KeyCode == Enum.KeyCode.Q then
    
                currentRotation = currentRotation - 90
                RotateModel(itemModel, currentRotation)
            end
        end
        
        -- Handle placement
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.KeyCode == Enum.KeyCode.ButtonR2 then
            if canPlace and currentPlot then                
                -- Remove all highlights
                for _, desc in pairs(itemModel:GetDescendants()) do
                    if desc:IsA("Highlight") then
                        desc:Destroy()
                    end
                end
                
                -- Parent to plot
                itemModel.Parent = currentPlot
                
                -- First disconnect connection
                keybindConnection:Disconnect()
                
                -- Then disable placement mode
                player:SetAttribute("Placement", false)
                
                -- Hide placement GUI
                player.PlayerGui:WaitForChild("PlacementGui").Enabled = false
                
                -- End interacting mode
                player:SetAttribute("Interacting", false)

                -- Emit event to server
                PlaceFurnitureRemote:FireServer(currentPlot.Name, itemModel.Name, newCFrame)

                task.wait(0.1)

                -- Delete itemModel
                itemModel:Destroy()
                itemModel = nil

            end
        end
    end)
    
    -- Main placement loop
    while player:GetAttribute("Placement") do
        task.wait()

        if not player:GetAttribute("Placement") then
            break
        end
        
        -- Shoot a raycast in the direction of the player's head
        local raycastResult = Utility.ShootRaycast(Camera, Camera.CFrame.LookVector, player, 100)
        if not raycastResult then
            canPlace = false
            continue
        end
        
        local raycastPosition = raycastResult.Position
        local raycastInstance = raycastResult.Instance
        
        -- Find the plot
        currentPlot = raycastInstance:FindFirstAncestor("Plot")
        
        -- Check if player owns the plot
        local ownPlot = false
        if currentPlot then
            ownPlot = currentPlot:GetAttribute("Owner") == player.UserId
        end
        
        -- Check if model is obstructed
        local modelObstructed = Utility.IsObstructed(itemModel.Collission, itemModel:GetDescendants())
        
        -- Update placement validity
        canPlace = not modelObstructed and ownPlot and currentPlot ~= nil
        
        -- Update model's highlight
        UpdateModelHighlight(itemModel, raycastInstance, player, canPlace)
        
        if not CheckPlacingSurface(itemModel, raycastInstance) then
            canPlace = false
            continue
        end
        
        PlaceModel(itemModel, raycastPosition, raycastResult.Normal)
    end
    
    -- Clean up connection when done
    if keybindConnection then
        keybindConnection:Disconnect()
    end
end

function Placement.Enable(player, boxInstance)
    -- Enables placement attribute for player, and shows gui
    player:SetAttribute("Placement", true)
    player.PlayerGui:WaitForChild("PlacementGui").Enabled = true

    -- Attribute of cardboard box - refered here as "instance"
    local itemAttribute = boxInstance:GetAttribute("Item")

    -- If the item attribute is not found, return
    if not itemAttribute then
        return
    end

    -- Data of the item
    local itemData = ItemData[itemAttribute]
    local itemModel = itemData.Model:Clone()

    -- Connect buttons to rotate
    local PlacementGui = player.PlayerGui:WaitForChild("PlacementGui")
    local RotateLeft = PlacementGui:WaitForChild("ItemConfiguration"):WaitForChild("RotateLeftButton")
    local RotateRight = PlacementGui:WaitForChild("ItemConfiguration"):WaitForChild("RotateRightButton")

    RotateLeft.MouseButton1Click:Connect(function()
        currentRotation = currentRotation - 90
        RotateModel(itemModel, currentRotation)
    end)

    RotateRight.MouseButton1Click:Connect(function()
        currentRotation = currentRotation + 90
        RotateModel(itemModel, currentRotation)
    end)

    local isWallHitSurface = itemModel:GetAttribute("HitSurface") == "Wall"
    RotateLeft.Visible = not isWallHitSurface
    RotateRight.Visible = not isWallHitSurface

    -- If the player is a mobile player
    local isMobile = player:GetAttribute("Mobile")

    -- Start placement of the item
    if isMobile then
        PlaceModelMobile(player, itemModel)
    else
        PlaceModelNonMobile(player, itemModel)
    end
end

return Placement

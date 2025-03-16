local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris  = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

-- ReplicatedStorage Content
local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

-- Modules
local Utility = require(Modules.Utility)
local Placement = require(Modules.Placement)

-- Constants
local MAX_DISTANCE = 400 --11
local FILL_TRANSPARENCY = 0.9
local OUTLINE_TRANSPARENCY = 0.3
local TWEEN_TIME = 0.06
local INTERACT_TAG = "Interact"

-- Variables
local raycastResult = nil
local previousRaycastResult = nil
local raycastInstance = nil
local lastTouchPosition = nil

local Interaction = {}

-- Utility: Find the first instance of a tag
local function FindFirstAncestorWithTag(instance, tag)
    if not instance then return nil end
    
    local current = instance
    local maxDepth = 15 -- Max depth to search for the tag
    local depth = 0

    while current and depth < maxDepth do
        local success, hasTag = pcall(function()
            return current:HasTag(tag)
        end)
        
        if success and hasTag then
            return current
        end
        
        current = current.Parent
        depth += 1
    end
    
    return nil
end

-- Utility: Check if object is interactable
local function IsInteractable(instance)
    local modelWithTag = FindFirstAncestorWithTag(instance, INTERACT_TAG)
    -- Tweens the highlight of the object
    return modelWithTag
end

-- Utility: Tween the highlight of the object
local function TweenHighlight(highlight, goal)
    local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(highlight, tweenInfo, goal)
    tween:Play()
end

-- When a player looks at an object
local function ObjectHit(instance)    
    if not IsInteractable(instance) then
        return
    end

    if Players.LocalPlayer:GetAttribute("Interacting") then
        return
    end

    -- Runs if the instance has the tag INTERACT_TAG
    local highlightClone = Assets.Highlights.Interact:Clone()
    highlightClone.Parent = FindFirstAncestorWithTag(instance, INTERACT_TAG)

    -- Resets the transparency of the highlight, then tweens it
    highlightClone.FillTransparency = 1
    highlightClone.OutlineTransparency = 1
    TweenHighlight(highlightClone, {FillTransparency = FILL_TRANSPARENCY, OutlineTransparency = OUTLINE_TRANSPARENCY})
    game:GetService("CollectionService"):AddTag(highlightClone, "Interactable")
end

-- When a player stops looking at an object
local function ObjectHitRemove(instance)
    if not IsInteractable(instance) then
        return
    end

    -- Finds highlight of module and destroys it
    local modelDescendants = FindFirstAncestorWithTag(instance, INTERACT_TAG):GetDescendants()

    for _, descendant in ipairs(modelDescendants) do
        if descendant.Name == "Interact" then
            TweenHighlight(descendant, {FillTransparency = 1, OutlineTransparency = 1})
            Debris:AddItem(descendant, TWEEN_TIME)
        end
    end
end

-- Loop to detect which item to interact with
local function MainInteractionLoop()

    task.spawn(function()
        while true do
            task.wait()

            local camera = workspace.CurrentCamera
            
            -- For non-mobile devices, cast ray from mouse position
            if not Players.LocalPlayer:GetAttribute("MobilePlayer") then
                local mousePos = UserInputService:GetMouseLocation()
                local unitRay = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
                local direction = unitRay.Direction
                
                -- Shoot a raycast in the direction of the mouse
                raycastResult = Utility.ShootRaycast(camera, direction, Players.LocalPlayer, MAX_DISTANCE)
            else
                -- Mobile implementation left for later
                if lastTouchPosition then
                    local unitRay = camera:ScreenPointToRay(lastTouchPosition.X, lastTouchPosition.Y)
                    local direction = unitRay.Direction
                    raycastResult = Utility.ShootRaycast(camera, direction, Players.LocalPlayer, MAX_DISTANCE)
                end
            end

            -- If the raycast result is nil, continue
            if not raycastResult then
                if previousRaycastResult then
                    ObjectHitRemove(previousRaycastResult.Instance)
                    previousRaycastResult = nil
                end
                continue
            end

            -- If no previous Object is hit, call ObjectHit function
            if not previousRaycastResult then
                previousRaycastResult = raycastResult
                ObjectHit(raycastResult.Instance)
            end

            -- If new Object is hit, call ObjectHit function
            if previousRaycastResult.Instance ~= raycastResult.Instance then
                ObjectHitRemove(previousRaycastResult.Instance)
                previousRaycastResult = raycastResult
                ObjectHit(raycastResult.Instance)
            end
        end
    end)
end

local function InteractionStartLogic()
    if not raycastResult then
        return
    end

    if not raycastResult.Instance then
        return
    end

    -- Get the instance of the object
    raycastInstance = FindFirstAncestorWithTag(raycastResult.Instance, INTERACT_TAG)
    
    if not IsInteractable(raycastInstance) then
        return
    end

    -- Get the interact highlight of the object
    local interactHighlight = raycastInstance:FindFirstChild("Interact")

    -- Flash effect when clicking interactable object
    if interactHighlight then
        local goal = {FillTransparency = 0.85}
        TweenHighlight(interactHighlight, goal)
    end
end

local function InteractionEndLogic()
    if not raycastResult then
        return
    end

    if not IsInteractable(raycastInstance) then
        return
    end

    local interactHighlight = raycastInstance:FindFirstChild("Interact")

    if interactHighlight then
        local goal = {FillTransparency = FILL_TRANSPARENCY}
        TweenHighlight(interactHighlight, goal)
    end

    -- Enter placement mode
    if raycastInstance:HasTag("Placement") then
        task.spawn(function()
            Placement.Enable(Players.LocalPlayer, raycastInstance)
        end)
    end

    ObjectHitRemove(raycastInstance)
    -- Enter interaction mode
    Players.LocalPlayer:SetAttribute("Interacting", true)
end

 -- This function is called when the game is running on a mobile device
function Interaction.Mobile()
    MainInteractionLoop()

    local touchStartTime = nil
    local touchStartPosition = nil
    local isTouching = false
    local MAX_TAP_TIME = 0.3
    local MAX_TAP_MOVEMENT = 10

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if Players.LocalPlayer:GetAttribute("Interacting") then
            return
        end

        -- Start the tap
        if input.UserInputType == Enum.UserInputType.Touch then
            isTouching = true
            touchStartTime = os.clock()
            touchStartPosition = input.Position

            InteractionStartLogic()
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Touch and isTouching then
            
            -- Too much movement: End the tap
            local delta = (input.Position - touchStartPosition).Magnitude
            if delta < MAX_TAP_MOVEMENT then
                isTouching = false
                return
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Touch and isTouching then
            
            local touchDuration = os.clock() - touchStartTime
            if touchDuration < MAX_TAP_TIME then
                InteractionEndLogic()
                lastTouchPosition = input.Position
            end
        end
    end)
end

 -- This function is called when the game is running on a non-mobile device
function Interaction.NonMobile()
    MainInteractionLoop()

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if Players.LocalPlayer:GetAttribute("Interacting") then
            return
        end

        -- If the player clicks on the object
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.KeyCode == Enum.KeyCode.ButtonR2 then

            InteractionStartLogic()
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.KeyCode == Enum.KeyCode.ButtonR2 then

            InteractionEndLogic()
        end
    end)
end

return Interaction

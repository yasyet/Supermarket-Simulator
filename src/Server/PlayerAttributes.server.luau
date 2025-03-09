local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

Players.PlayerAdded:Connect(function(player)

    -- If the player is currently placing
    player:SetAttribute("Placement", false)

    -- If the player is currently interacting
    player:SetAttribute("Interacting", false)

    -- If the player is a mobile player
    player:SetAttribute("Mobile", UserInputService.TouchEnabled)
end)

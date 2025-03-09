local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Handles the interaction of the player with the game with interactalbe objects
local Interaction = require(ReplicatedStorage.Modules.Interaction)

-- If the local player is a mobile player: true
-- else: false
local mobilePlayer = UserInputService.TouchEnabled

if mobilePlayer then
    -- If the game is running on a mobile device
    Interaction.Mobile()
else
    -- If the game is running on a non-mobile device
    Interaction.NonMobile()
end

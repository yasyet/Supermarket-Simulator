local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Furniture = ReplicatedStorage.Assets.Furniture

return {
    ["Chair"] = {
        ["Name"] = "Chair",
        ["Model"] = Furniture.Chair
    },

    ["SleekChair"] = {
        ["Name"] = "Sleek Chair",
        ["Model"] = Furniture.SleekChair
    },

    ["ArmChair"] = {
        ["Name"] = "Arm Chair",
        ["Model"] = Furniture.ArmChair
    },

    ["Shelf"] = {
        ["Name"] = "Shelf",
        ["Model"] = Furniture.Shelf
    },

    ["Register"] = {
        ["Name"] = "Register",
        ["Model"] = Furniture.Register
    },

    ["Painting"] = {
        ["Name"] = "Painting",
        ["Model"] = Furniture.Painting
    }
}

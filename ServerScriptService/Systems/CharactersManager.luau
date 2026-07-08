--// Module
local CharactersManager = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")

--// Assets
local weaponsAssets = assets:WaitForChild("Weapons")

--// Functions
function CharactersManager.initialize()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character.Parent = workspace.Players
			
			for _, child in character:GetChildren() do
				if child:IsA("BasePart") then
					CollectionService:AddTag(child, "Player")
				end
			end

			local weaponName

			repeat
				weaponName = player:GetAttribute("Weapon")
				task.wait()
			until weaponName

			local weaponModel = weaponsAssets:FindFirstChild(weaponName):Clone()
			weaponModel.Handle.Main.Part0 = character:WaitForChild("RightHand")
			weaponModel:PivotTo(character:WaitForChild("RightHand").CFrame)
			weaponModel.Parent = character
		end)
	end)
end

--// Return
return CharactersManager

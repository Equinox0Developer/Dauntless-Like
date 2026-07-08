--// Module
local AnimationsManager = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")
local data = ReplicatedStorage:WaitForChild("Data")

--// Assets
local animationsAssets = assets:WaitForChild("Animations")

--// Data
local animationsData = require(data:WaitForChild("Animations"))

--// Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--// Tables
local tracks = {}

--// Functions
function AnimationsManager.getTrack(animationName: string): AnimationTrack
	local track = tracks[animationName]
	return track
end

function AnimationsManager.playAnimation(animationName: string)
	local track = tracks[animationName]
	track:Play()
end

function AnimationsManager.stopAnimation(animationName: string)
	local track = tracks[animationName]
	track:Stop()
end

function AnimationsManager.stopAllAnimations()
	for _, track in tracks do
		track:Stop()
	end
end

function AnimationsManager.changeIdle(weaponName: string)
	local animate = character:WaitForChild("Animate")
	animate.idle.Animation1.AnimationId = animationsAssets[weaponName]["Idle_1"].AnimationId
	animate.idle.Animation2.AnimationId = animationsAssets[weaponName]["Idle_1"].AnimationId

	AnimationsManager.stopAllAnimations()
end

function AnimationsManager.characterAdded(model: Model)
	character = model

	table.clear(tracks)

	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", humanoid)

	for i, animationFolder in animationsAssets:GetChildren() do
		for i, animation in animationFolder:GetChildren() do
			tracks[`{animationFolder.Name}_{animation.Name}`] = animator:LoadAnimation(animation)
		end
	end

	AnimationsManager.changeIdle(player:GetAttribute("Weapon"))

	character:SetAttribute("Loaded", true)
end

function AnimationsManager.initialize()
	for weaponName, animationsTables in animationsData.Weapons do
		local weaponFolder = Instance.new("Folder")
		weaponFolder.Name = weaponName
		weaponFolder.Parent = animationsAssets

		for animationType, animationTable in animationsTables do
			for animationName, animationId in animationTable do
				local animationInstance = Instance.new("Animation")
				animationInstance.Name = `{animationType}_{animationName}`
				animationInstance.AnimationId = `rbxassetid://{animationId}`
				animationInstance.Parent = weaponFolder
			end
		end
	end
end

--// Return
return AnimationsManager

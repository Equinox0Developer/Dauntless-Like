--// Module
local CombatManagerClient = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")
local systems = ReplicatedStorage:WaitForChild("Systems")
local data = ReplicatedStorage:WaitForChild("Data")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Systems
local statesManager = require(systems:WaitForChild("StatesManagerClient"))
local animationsManager = require(systems:WaitForChild("AnimationsManager"))
local hitboxManager = require(systems:WaitForChild("HitboxManager"))

--// Data
local animationsData = require(data:WaitForChild("Animations"))
local weaponsData = require(data:WaitForChild("Weapons"))

--// Events
local attackEvent = packet("Attack", packet.NumberU8)
local hitEvent = packet("Hit", packet.Instance, packet.String, packet.NumberU8)

--// Variables
local player = Players.LocalPlayer

local ready = true

local actualAttack = nil
local attacksCombo = nil
local attackId = 0
local attackTime = os.clock()

local hitbox = nil

local raycastParameters = RaycastParams.new()
raycastParameters.FilterType = Enum.RaycastFilterType.Include
raycastParameters.FilterDescendantsInstances = { workspace:WaitForChild("Bots") }

--// Tables
local tracks = {}
local connections = {}
local cooldowns = {}

local hittedParts = {}

--// Functions
local function handleAttack()
	tracks[actualAttack]:Stop()

	if (os.clock() - attackTime) > 1.5 then
		actualAttack = 1
	elseif actualAttack >= attacksCombo then
		actualAttack = 1
	else
		actualAttack += 1
	end

	tracks[actualAttack]:Play()

	task.delay(cooldowns[actualAttack], function()
		ready = true
	end)
end

local function handleHitbox(weaponModel: Model)
	if hitbox then
		hitbox:Destroy()
		hitbox = nil
	end

	hitbox = hitboxManager.new(weaponModel, raycastParameters)

	hitbox:OnHit(function(raycastResult)
		local hitPart = raycastResult.Instance

		if not hitPart then
			return
		end

		local hitModel = hitPart:FindFirstAncestorWhichIsA("Model")

		if not hitModel then
			return
		end

		if hittedParts[hitPart] then
			return
		end

		hittedParts[hitPart] = raycastResult
	end)
end

local function handleTracks(weaponName: string)
	for _, track in tracks do
		track:Stop()
	end

	table.clear(tracks)

	for _, connection in connections do
		connection:Disconnect()
	end

	table.clear(connections)

	for i = 1, attacksCombo do
		local track = animationsManager.getTrack(`{weaponName}_Attack_{i}`)

		tracks[i] = track

		connections[`{i}_Begin`] = track:GetMarkerReachedSignal("Begin"):Connect(function()
			hitbox:HitStart()
		end)

		connections[`{i}_End`] = track:GetMarkerReachedSignal("Finish"):Connect(function()
			hitbox:HitStop()

			task.defer(function()
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

				if not root then
					return
				end

				local closestPart = nil
				local closestDistance = math.huge

				for part, raycastResult in hittedParts do
					local hitPart = raycastResult.Instance

					if not hitPart then
						continue
					end

					local model = hitPart:FindFirstAncestorWhichIsA("Model")

					if not model then
						continue
					end

					local distance = (hitPart.Position - root.Position).Magnitude

					if distance < closestDistance then
						closestDistance = distance
						closestPart = hitPart
					end
				end

				if closestPart then
					local model = closestPart:FindFirstAncestorWhichIsA("Model")
					hitEvent:Fire(model, closestPart.Name, actualAttack)
				end
			end)
		end)
	end
end

local function handleCombo(weaponName: string)
	attacksCombo = #animationsData.Weapons[weaponName].Attack
	actualAttack = attacksCombo

	if cooldowns then
		table.clear(cooldowns)
	end

	for i = 1, attacksCombo do
		cooldowns[i] = weaponsData[weaponName].Cooldown[i]
	end
end

local function weaponChanged()
	ready = false

	local character

	repeat
		task.wait()
		character = player.Character
	until character

	local weaponName = player:GetAttribute("Weapon")
	local weaponModel = player.Character:FindFirstChild(weaponName)

	handleCombo(weaponName)
	handleHitbox(weaponModel)
	handleTracks(weaponName)

	ready = true
end

function CombatManagerClient.attack()
	if statesManager.canPerformAction("Attack") and ready then
		local character = player.Character

		if not character then
			return
		end

		ready = false
		attackId += 1

		table.clear(hittedParts)

		handleAttack()
		attackTime = os.clock()

		attackEvent:Fire(actualAttack)
	end
end

function CombatManagerClient.initialize()
	hitboxManager.Settings.Debug_Visible = true

	weaponChanged()
	player:GetAttributeChangedSignal("Weapon"):Connect(weaponChanged)
end

--// Return
return CombatManagerClient

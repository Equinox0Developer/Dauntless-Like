--// Module
local NotificationsMenu = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Events
local popUpEvent = packet("Notification", packet.String, packet.String, packet.NumberF64, packet.String, packet.String)
local setDefaultTransEvent = packet("NotificationSetTransition", packet.String, packet.String)

--// Variables
local player = Players.LocalPlayer

local mainTransIn = "Drop"
local mainTransOut = "Shrink"
local setTransCon 	

local gui
local popupsFrame
local waitlistFolder
local cloneTemplate
local typwriterSound
local frameCounter = 0

local taskWait = task.wait
local taskSpawn = task.spawn
local clamp = math.clamp

--// Constants
local DEFAULT_MAX_POPUPS = 5
local DEFAULT_FONT = Font.fromName("FredokaOne")
local DEFAULT_SOUND_ID = 3779045779
local DEFAULT_SOUND_VOLUME = 0.5
local DEFAULT_STROKE_ENABLED = true
local DEFAULT_STROKE_THICK = 2
local DEFAULT_USE_GRADIENT = true
local DEFAULT_GRADIENT_COLOR = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),})
local DEFAULT_GRADIENT_ROT = 90
local DEFAULT_REVERSE_DIR = true
local DEFAULT_PLAY_SOUND = true
local DEFAULT_TIME = 3

--// Types
export type NotifType = "Error" | "Warning" | "Notification" | "Completed" | "Reward"
export type Transitions = {string}
export type Properties = {
	Font: Font?,
	StrokeColor: Color3?,
	Gradient: UIGradient | {Color: ColorSequence, Rotation: number}?,
	Sound: string?,
}

local TYPE_MAP: {[string]: {gradient: string, sound: string}} = {
	Error = { gradient = "Red", sound = "Error" },
	Warning = { gradient = "Orange", sound = "Warning" },
	Notification = { gradient = "Yellow", sound = "Notification" },
	Completed = { gradient = "Blue", sound = "Collect" },
	Reward = { gradient = "Green", sound = "Reward" },
}

NotificationsMenu.TransitionIn = {
	Fade = "Fade",
	Drop = "Drop",
	Typewriter = "Typewriter",
}

NotificationsMenu.TransitionOut = {
	Fade = "Fade",
	Shrink = "Shrink",
	Erase = "Erase",
}

--// Functions
local function format(str)
	for match in str:gmatch("{(.-)}") do

		local symbols = {}
		local startfrom = 1

		while match:find("[.]", startfrom) do
			local spos = match:find("[.]", startfrom)
			local epos = match:find("[.]", spos + 1)

			if not epos then
				epos = match:find("[:]", spos + 1)

				if not epos then
					epos = match:find("}", spos + 1)
				end
			end

			if not epos then
				break
			else
				epos -= 1
			end

			table.insert(symbols, {
				symbol = ".",
				spos = spos,
				epos = epos,
				key = string.sub(match, spos + 1, epos)
			})

			startfrom = epos + 1
		end

		if #symbols > 0 then
			table.sort(symbols, function(a, b)
				return a.spos < b.spos
			end)

			local first = symbols[1]

			table.insert(symbols, {
				symbol = "start",
				spos = 1,
				epos = first.spos - 1,
				key = string.sub(match, 1, first.spos - 1)
			})

			table.sort(symbols, function(a, b)
				return a.spos < b.spos
			end)
		else
			table.insert(symbols, {
				symbol = "start",
				spos = 1,
				epos = #match,
				key = match
			})
		end

		local val

		for _, v in symbols do
			if v.symbol == "start" then
				local function c(s, t)
					if v.key == s then
						val = t
					end
				end

				c("game", game)
				c("workspace", workspace)

			elseif v.symbol == "." then
				if val then
					val = val[v.key]
				else
					break
				end
			end
		end

		if val == nil then
			val = "nil"
		end

		local sp = string.split(str, "{" .. match .. "}")

		if type(val) ~= "string" then
			val = tostring(val)
		end

		str = sp[1] .. val .. sp[2]
	end

	return str
end

local function psound(sound, stoptime)
	if not sound then
		return
	end

	taskSpawn(function()
		local s = sound:Clone()

		s.Parent = SoundService
		s:Play()

		if tonumber(stoptime) then
			Debris:AddItem(s, stoptime)
		else
			s.Ended:Wait()

			if s then
				s:Destroy()
			end
		end
	end)
end

local function RGBToHex(s)
	local function c(a)
		return clamp(a, 0, 255)
	end

	return string.format("#%02X%02X%02X", c(s[1]), c(s[2]), c(s[3]))
end

function NotificationsMenu:SetDefaultTransition(TransitionIn: string, TransitionOut: string)
	if RunService:IsServer() then
		for _, plr in Players:GetPlayers() do
			setDefaultTransEvent:FireClient(plr, TransitionIn, TransitionOut)
		end

		if setTransCon then setTransCon:Disconnect() end

		setTransCon = Players.PlayerAdded:Connect(function(plr)
			setDefaultTransEvent:FireClient(plr, TransitionIn, TransitionOut)
		end)
	end

	if NotificationsMenu.TransitionIn[TransitionIn] then
		mainTransIn = TransitionIn
	else
		warn("Couldn't set default transition in:", TransitionIn)
	end

	if NotificationsMenu.TransitionOut[TransitionOut] then
		mainTransOut = TransitionOut
	else
		warn("Couldn't set default transition out:", TransitionOut)
	end
end

local function getFramePos(frame)
	local ticks = {}

	for _, v in popupsFrame:GetChildren() do
		if string.find(v.Name, "Sort_") then
			table.insert(ticks, { s = tonumber(string.split(v.Name, "_")[2]), y = v.Size.Y.Scale })
		end
	end

	if DEFAULT_REVERSE_DIR then
		table.sort(ticks, function(a, b) return a.s < b.s end)
	else
		table.sort(ticks, function(a, b) return a.s > b.s end)
	end

	local loc = 1
	local myNum = tonumber(string.split(frame.Name, "_")[2])

	for i, v in ticks do
		if v.s == myNum then
			loc = i
			break
		end
	end

	local newpos = UDim2.new(0.5, 0, 0, 0)

	for i = 1, loc - 1 do
		newpos = newpos + UDim2.new(0, 0, -(0.15 + ticks[i].y), -5)
	end

	if DEFAULT_REVERSE_DIR then
		newpos = UDim2.new(0.5, 0, -newpos.Y.Scale, -newpos.Y.Offset)
	end

	return newpos
end

local function repositionAll(except, transin)
	for _, v in popupsFrame:GetChildren() do
		if v:IsA("Frame") and v.Name ~= "cloneframe" and v ~= except then
			local info
			if transin == "Fade" then
				info = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
			elseif transin == "Typewriter" then
				info = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
			elseif transin == "Drop" then
				info = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
			else
				info = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
			end
			TweenService:Create(v, info, { Position = getFramePos(v) }):Play()
		end
	end
end

local function handleWaitlist()
	if not waitlistFolder then return end

	local waiting = waitlistFolder:GetChildren()
	if #waiting == 0 then return end

	table.sort(waiting, function(a, b)
		local na = tonumber(string.split(a.Name, "_")[2]) or 0
		local nb = tonumber(string.split(b.Name, "_")[2]) or 0
		return na < nb
	end)

	local next = waiting[1]
	next.Parent = popupsFrame
	next.Position = getFramePos(next)
	next.Visible = true
	repositionAll(next, nil)
end

local function resolveType(notifType: string, properties: Properties?)
	local map = TYPE_MAP[notifType]

	if not map then
		warn("NotificationsMenu: unknown type '" .. tostring(notifType) .. "', defaulting to Notification")
		map = TYPE_MAP["Notification"]
	end

	local gradientName = (properties and properties.Gradient == nil and map.gradient) or map.gradient
	local soundName = (properties and properties.Sound) or map.sound

	return map.gradient, soundName
end

local function fireClient(plr, message: string, notifType: string, time: number, transin: string, transout: string)
	popUpEvent:FireClient(plr, message, notifType, time, transin, transout)
end

--// Public API
function NotificationsMenu.PopSelectedPlayers(players: {Player}, message: string, notifType: NotifType, time: number?, transitions: Transitions?, properties: Properties?)
	local t = time or DEFAULT_TIME
	local transin = (transitions and transitions[1]) or mainTransIn
	local transout = (transitions and transitions[2]) or mainTransOut

	for _, plr in players do
		if plr then
			fireClient(plr, message, notifType, t, transin, transout)
		end
	end
end

function NotificationsMenu.PopExceptPlayers(players: {Player}, message: string, notifType: NotifType, time: number?, transitions: Transitions?, properties: Properties?)
	local t = time or DEFAULT_TIME
	local transin = (transitions and transitions[1]) or mainTransIn
	local transout = (transitions and transitions[2]) or mainTransOut

	for _, plr in Players:GetPlayers() do
		if not table.find(players, plr) then
			fireClient(plr, message, notifType, t, transin, transout)
		end
	end
end

function NotificationsMenu.PopSelectedTeam(team: Team, message: string, notifType: NotifType, time: number?, transitions: Transitions?, properties: Properties?)
	if not team then warn("Team not found!") return end

	local t = time or DEFAULT_TIME
	local transin = (transitions and transitions[1]) or mainTransIn
	local transout = (transitions and transitions[2]) or mainTransOut

	for _, plr in Players:GetPlayers() do
		if plr.Team == team then
			fireClient(plr, message, notifType, t, transin, transout)
		end
	end
end

function NotificationsMenu.PopExceptTeam(team: Team, message: string, notifType: NotifType, time: number?, transitions: Transitions?, properties: Properties?)
	if not team then warn("Team not found!") return end

	local t = time or DEFAULT_TIME
	local transin = (transitions and transitions[1]) or mainTransIn
	local transout = (transitions and transitions[2]) or mainTransOut

	for _, plr in Players:GetPlayers() do
		if plr.Team ~= team then
			fireClient(plr, message, notifType, t, transin, transout)
		end
	end
end

function NotificationsMenu.PopEveryone(message: string, notifType: NotifType, time: number?, transitions: Transitions?, properties: Properties?)
	local t = time or DEFAULT_TIME
	local transin = (transitions and transitions[1]) or mainTransIn
	local transout = (transitions and transitions[2]) or mainTransOut

	for _, plr in Players:GetPlayers() do
		fireClient(plr, message, notifType, t, transin, transout)
	end
end

function NotificationsMenu.PopLocal(message: string, notifType: NotifType, time: number?, transitions: Transitions?, properties: Properties?)

	taskSpawn(function()
		if type(message) ~= "string" then
			return warn("NotificationsMenu: 'message' must be a string.")
		end

		if type(notifType) ~= "string" then
			return warn("NotificationsMenu: 'type' must be a string.")
		end

		if time ~= nil and type(time) ~= "number" then
			return warn("NotificationsMenu: 'time' must be a number or nil.")
		end

		if transitions ~= nil and type(transitions) ~= "table" then
			return warn("NotificationsMenu: 'transitions' must be a table or nil.")
		end

		if properties ~= nil and type(properties) ~= "table" then
			return warn("NotificationsMenu: 'properties' must be a table or nil.")
		end

		local duration = time or DEFAULT_TIME
		local transin = (transitions and transitions[1]) or mainTransIn
		local transout = (transitions and transitions[2]) or mainTransOut

		if not player then return warn("This function is client-side only.") end
		if not gui then return warn("Notifications GUI not found.") end
		if not popupsFrame then return warn("PopUps container missing.") end
		if not cloneTemplate then return warn("cloneframe not found.") end

		local map = TYPE_MAP[notifType]

		if not map then
			warn("NotificationsMenu: unknown type '" .. tostring(notifType) .. "', defaulting to Notification")
			map = TYPE_MAP["Notification"]
		end

		local gradientName = map.gradient
		local soundName = (properties and properties.Sound) or map.sound

		local count = 0

		for _, v in popupsFrame:GetChildren() do
			if v:IsA("Frame") and v.Name ~= "cloneframe" then count += 1 end
		end

		message = format(message)

		local brs = {}
		local findbr = 0

		local function br()
			local spos, epos = string.find(message, "<br/>", findbr + 1)

			if epos then
				findbr = epos

				table.insert(brs, {
					startp = spos,
					endp = epos
				})

				br()
			end
		end

		br()

		frameCounter += 1
		local frame = cloneTemplate:Clone()
		frame.Name = "Sort_" .. frameCounter

		if DEFAULT_MAX_POPUPS == 0 or count < DEFAULT_MAX_POPUPS then
			frame.Parent = popupsFrame
		elseif waitlistFolder then
			frame.Parent = waitlistFolder
		else
			frame.Parent = popupsFrame
		end

		local label = frame:FindFirstChild("TextLabel")

		if not label then
			frame:Destroy()
			return
		end

		local stcolor = {0, 0, 0}
		local grad

		if properties then
			for i, prop in pairs(properties) do

				if i == "Font" then
					if typeof(prop) == "EnumItem" then
						label.FontFace = Font.fromEnum(prop)
					elseif typeof(prop) == "Font" then
						label.FontFace = prop
					end

				elseif i == "StrokeColor" then
					if typeof(prop) == "Color3" then
						stcolor = {
							prop.R * 255,
							prop.G * 255,
							prop.B * 255
						}
					end

				elseif i == "Gradient" then

					if typeof(prop) == "Instance" and prop:IsA("UIGradient") then

						grad = prop:Clone()

					elseif type(prop) == "table" then

						if prop.Color and prop.Rotation then

							grad = Instance.new("UIGradient")

							grad.Color = prop.Color
							grad.Rotation = prop.Rotation
						end
					end
				end
			end
		end

		local oldGradient = label:FindFirstChildWhichIsA("UIGradient")
		if oldGradient then oldGradient:Destroy() end

		if grad then
			grad.Parent = label
		else
			local gradientChild = script:FindFirstChild(gradientName)
			if gradientChild and gradientChild:IsA("UIGradient") then
				gradientChild:Clone().Parent = label
			elseif DEFAULT_USE_GRADIENT then
				local defaultGrad = Instance.new("UIGradient")
				defaultGrad.Color = DEFAULT_GRADIENT_COLOR
				defaultGrad.Rotation = DEFAULT_GRADIENT_ROT
				defaultGrad.Parent = label
			end
		end

		local existingStroke = label:FindFirstChildWhichIsA("UIStroke")
		if existingStroke then existingStroke:Destroy() end

		if DEFAULT_STROKE_ENABLED then
			local uiStroke = Instance.new("UIStroke")
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
			uiStroke.Color = Color3.fromRGB(
				clamp(stcolor[1], 0, 255),
				clamp(stcolor[2], 0, 255),
				clamp(stcolor[3], 0, 255)
			)
			uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
			uiStroke.Thickness = DEFAULT_STROKE_THICK
			uiStroke.Parent = label
		end

		stcolor = RGBToHex(stcolor)

		label.TextColor3 = Color3.new(1, 1, 1)

		local function setText(txt)
			label.Text = txt
		end

		setText(message)

		local inPopups = frame.Parent == popupsFrame

		if inPopups then
			frame.Position = getFramePos(frame)
			frame.Visible = true
			repositionAll(frame, transin)
		end

		if DEFAULT_PLAY_SOUND then
			local soundObj = SoundService:FindFirstChild(soundName)
			if soundObj then
				psound(soundObj)
			elseif DEFAULT_SOUND_ID and DEFAULT_SOUND_ID ~= 0 then
				taskSpawn(function()
					local playsound = Instance.new("Sound")
					playsound.Parent = SoundService
					playsound.Volume = DEFAULT_SOUND_VOLUME
					playsound.SoundId = "rbxassetid://" .. DEFAULT_SOUND_ID
					playsound:Play()
					playsound.Ended:Wait()
					if playsound then playsound:Destroy() end
				end)
			end
		end

		if inPopups then
			if transin == "Fade" then

				label.TextTransparency = 1
				label.Position = UDim2.new(0.5, 0, 0.3, 0)

				TweenService:Create(label,
					TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
					{ TextTransparency = 0, Position = UDim2.new(0.5, 0, 0, 0) }
				):Play()

			elseif transin == "Drop" then

				label.Size = UDim2.new(1.5, 0, 1.5, 0)
				label.Position = UDim2.new(0.5, 0, -0.25, 0)

				TweenService:Create(label,
					TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
					{ Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0) }
				):Play()

			elseif transin == "Typewriter" then

				label.Text = ""

				local pureLength = math.max(1, (#message - (#brs * 5)))
				local lenmp = 0.75 + (5 / pureLength)

				local write = ""

				for i = 1, #message do

					local newadded = string.sub(message, i, i)

					write ..= newadded

					setText(write)

					if typwriterSound and not typwriterSound.IsPlaying then
						typwriterSound:Play()
					end

					local waitt

					if newadded == " " then
						waitt = 0.05 * lenmp
					elseif newadded == "," then
						waitt = 0.28 * lenmp
					elseif newadded == ";" or newadded == ":" then
						waitt = 0.32 * lenmp
					elseif newadded == "." or newadded == "!" then
						waitt = 0.5 * lenmp
					elseif newadded == "?" then
						waitt = 0.6 * lenmp
					else
						waitt = 0.07 * lenmp
					end

					taskWait(waitt)
				end
			end
		end

		if transout == "Fade" then

			local info = TweenInfo.new(
				0.15,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.In
			)

			local fadeout = TweenService:Create(label, info, {
				TextTransparency = 1
			})

			taskWait(math.max(0, duration - info.Time))

			fadeout:Play()

			taskWait(info.Time)

		elseif transout == "Shrink" then

			local info = TweenInfo.new(
				0.25,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.In
			)

			local shrink = TweenService:Create(label, info, {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = math.random(-10, 10)
			})

			taskWait(math.max(0, duration - 0.23))

			shrink:Play()

			taskWait(0.23)

		elseif transout == "Erase" then

			taskWait(
				math.max(
					0,
					duration - (#message - (#brs * 5)) * 0.02
				)
			)

			local eraseMsg = message
			local tagLen = #"<br/>"

			while #eraseMsg > 0 do
				local len = #eraseMsg

				if string.sub(eraseMsg, len - tagLen + 1, len) == "<br/>" then
					eraseMsg = string.sub(eraseMsg, 1, len - tagLen)
				else
					eraseMsg = string.sub(eraseMsg, 1, len - 1)
				end

				setText(eraseMsg)
				taskWait(0.02)
			end
		end

		if frame and frame.Parent then
			frame:Destroy()
			repositionAll(nil, nil)
			handleWaitlist()
		end
	end)
end

--// Initialize
function NotificationsMenu.initialize()
	if not RunService:IsClient() then return end

	local screenGui = script:FindFirstChild("Notifications")
	if screenGui and not player.PlayerGui:FindFirstChild("Notifications") then
		screenGui.Parent = player.PlayerGui
	end

	gui = player.PlayerGui:WaitForChild("Notifications")
	popupsFrame = gui:WaitForChild("PopUps")
	waitlistFolder = popupsFrame:FindFirstChild("waitlist")
	if not waitlistFolder then
		waitlistFolder = Instance.new("Folder")
		waitlistFolder.Name = "waitlist"
		waitlistFolder.Parent = popupsFrame
	end
	cloneTemplate = popupsFrame:WaitForChild("cloneframe")
	typwriterSound = gui:FindFirstChild("TypewriterSound")

	local cloneLabel = cloneTemplate:FindFirstChild("TextLabel")
	if cloneLabel then
		cloneLabel.FontFace = DEFAULT_FONT
	end
	if DEFAULT_REVERSE_DIR then
		cloneTemplate.AnchorPoint = Vector2.new(0.5, 0)
	end

	popUpEvent.OnClientEvent:Connect(function(message: string, notifType: string, time: number, transin: string, transout: string)
		NotificationsMenu.PopLocal(message, notifType, time, {transin, transout})
	end)

	setDefaultTransEvent.OnClientEvent:Connect(function(tIn, tOut)
		NotificationsMenu:SetDefaultTransition(tIn, tOut)
	end)
end

--// Return
return NotificationsMenu
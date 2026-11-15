--[[
	DriveClient (LocalScript)  ->  StarterPlayer.StarterPlayerScripts.DriveClient

	Drives your robot when you're seated in it. The server gives you
	network ownership of the robot, so setting the constraints here is
	smooth and lag-free.

	Controls:  W/S or thumbstick = drive, A/D = turn,
	           Q/E = strafe (Mecanum / X-Drive only), F = score
	           Jump = leave robot
	Mobile & gamepad get on-screen / button bindings automatically.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ScoreRemote = Remotes:WaitForChild("Score")

local player = Players.LocalPlayer

local current = nil -- { Seat, Model, LV, AV }
local strafeLeft, strafeRight = false, false

local function onStrafe(actionName, inputState)
	local down = inputState == Enum.UserInputState.Begin
	if inputState == Enum.UserInputState.Begin or inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		if actionName == "VexStrafeLeft" then
			strafeLeft = down
		else
			strafeRight = down
		end
	end
	return Enum.ContextActionResult.Sink
end

local function onScore(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ScoreRemote:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

local function bindControls(model)
	ContextActionService:BindAction("VexScore", onScore, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle("VexScore", "SCORE")
	ContextActionService:SetPosition("VexScore", UDim2.new(1, -200, 1, -140))
	if model:GetAttribute("Strafe") then
		ContextActionService:BindAction("VexStrafeLeft", onStrafe, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
		ContextActionService:BindAction("VexStrafeRight", onStrafe, true, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
		ContextActionService:SetTitle("VexStrafeLeft", "◀")
		ContextActionService:SetTitle("VexStrafeRight", "▶")
		ContextActionService:SetPosition("VexStrafeLeft", UDim2.new(1, -270, 1, -80))
		ContextActionService:SetPosition("VexStrafeRight", UDim2.new(1, -200, 1, -60))
	end
end

local function unbindControls()
	ContextActionService:UnbindAction("VexScore")
	ContextActionService:UnbindAction("VexStrafeLeft")
	ContextActionService:UnbindAction("VexStrafeRight")
	strafeLeft, strafeRight = false, false
end

local function onSeated(active, seatPart)
	if active and seatPart and seatPart:GetAttribute("VexRobot") then
		local model = seatPart.Parent
		local root = model and model.PrimaryPart
		if not root then
			return
		end
		current = {
			Seat = seatPart,
			Model = model,
			LV = root:WaitForChild("DriveLV", 5),
			AV = root:WaitForChild("DriveAV", 5),
		}
		bindControls(model)
	elseif current then
		unbindControls()
		current = nil
	end
end

local function hookCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Seated:Connect(onSeated)
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	task.spawn(hookCharacter, player.Character)
end

local function key(code)
	return UserInputService:IsKeyDown(code)
end

RunService.Heartbeat:Connect(function()
	if not current then
		return
	end
	if not current.Model.Parent or not current.LV or not current.AV then
		unbindControls()
		current = nil
		return
	end

	local throttle = current.Seat.ThrottleFloat
	local steer = current.Seat.SteerFloat

	-- keyboard fallback (works even if the default vehicle controller is off)
	if throttle == 0 and steer == 0 and not UserInputService:GetFocusedTextBox() then
		if key(Enum.KeyCode.W) or key(Enum.KeyCode.Up) then
			throttle += 1
		end
		if key(Enum.KeyCode.S) or key(Enum.KeyCode.Down) then
			throttle -= 1
		end
		if key(Enum.KeyCode.D) or key(Enum.KeyCode.Right) then
			steer += 1
		end
		if key(Enum.KeyCode.A) or key(Enum.KeyCode.Left) then
			steer -= 1
		end
	end

	local maxSpeed = current.Model:GetAttribute("MaxSpeed") or 16
	local turnSpeed = current.Model:GetAttribute("TurnSpeed") or 3
	local strafe = 0
	if current.Model:GetAttribute("Strafe") then
		strafe = (strafeRight and 1 or 0) - (strafeLeft and 1 or 0)
	end

	current.LV.PlaneVelocity = Vector2.new(strafe * maxSpeed * 0.85, -throttle * maxSpeed)
	current.AV.AngularVelocity = Vector3.new(0, -steer * turnSpeed, 0)
end)

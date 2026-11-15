--[[
	RobotBuilder (ModuleScript)  ->  ReplicatedStorage.RobotBuilder
	Shared so the UI can show live 3D robot previews.

	Builds a 3D VEX-style robot Model out of the chosen modules.
	  RobotBuilder.Build(loadout, options) -> model, stats
	options:
	  Drive      = true  -> unanchored, has a VehicleSeat + drive constraints
	  TeamColor  = Color3 accent color
	  Label      = text shown above the robot
	  SubLabel   = second line of text
	  NoNameplate = true -> skip the floating name tag (UI previews)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local RobotBuilder = {}

local METAL = Color3.fromRGB(196, 198, 204)
local DARK = Color3.fromRGB(35, 35, 40)
local MOTOR = Color3.fromRGB(55, 30, 30)

local function makeBillboard(root, label, subLabel, accent)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.new(9, 0, 2.2, 0)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.MaxDistance = 110
	gui.LightInfluence = 0
	gui.Parent = root

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
	card.BackgroundTransparency = 0.2
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = accent
	stroke.Thickness = 2
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0.05, 0, 0.06, 0)
	title.Size = UDim2.new(0.9, 0, 0.52, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = label or "Robot"
	title.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.new(0.05, 0, 0.56, 0)
	sub.Size = UDim2.new(0.9, 0, 0.36, 0)
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(255, 205, 80)
	sub.Text = subLabel or ""
	sub.Parent = card
end

function RobotBuilder.Build(loadout, options)
	options = options or {}
	local stats, defs = Config.GetRobotStats(loadout)
	local drivetrain, intake, lift, brain = defs.Drivetrain, defs.Intake, defs.Lift, defs.Brain
	local accent = options.TeamColor or drivetrain.Accent

	local model = Instance.new("Model")
	model.Name = options.Name or "VexRobot"

	-- Invisible collision box. Everything else is decoration welded to it.
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(7.4, 2, 8.4)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true
	root.CFrame = CFrame.new()
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.25, 0, 1, 1)
	root.Parent = model
	model.PrimaryPart = root

	local function add(name, size, cf, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	-------------------------------------------------------------- drivetrain
	local wheelD = drivetrain.WheelSize or 2.5
	local wy = -1 + wheelD / 2 -- axle height (root bottom is the floor)

	add("Chassis", Vector3.new(6, 0.3, 8), CFrame.new(0, wy, 0), METAL, Enum.Material.Metal)
	add("RailL", Vector3.new(0.5, 1, 8.2), CFrame.new(-3, wy + 0.35, 0), METAL, Enum.Material.Metal)
	add("RailR", Vector3.new(0.5, 1, 8.2), CFrame.new(3, wy + 0.35, 0), METAL, Enum.Material.Metal)
	add("CrossF", Vector3.new(6, 0.6, 0.5), CFrame.new(0, wy + 0.35, -3.8), accent, Enum.Material.Metal)
	add("CrossB", Vector3.new(6, 0.6, 0.5), CFrame.new(0, wy + 0.35, 3.8), accent, Enum.Material.Metal)

	local wheelZ = drivetrain.Wheels == 6 and { -3, 0, 3 } or { -3, 3 }
	for _, z in ipairs(wheelZ) do
		for _, side in ipairs({ -1, 1 }) do
			local cf = CFrame.new(side * 3.65, wy, z)
			if drivetrain.Diagonal then
				local angle = (z < 0) == (side < 0) and 45 or -45
				cf = cf * CFrame.Angles(0, math.rad(angle), 0)
			end
			add("Wheel", Vector3.new(0.8, wheelD, wheelD), cf, drivetrain.WheelColor, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			add("Hub", Vector3.new(0.85, wheelD * 0.4, wheelD * 0.4), cf, accent, Enum.Material.Neon, Enum.PartType.Cylinder)
			add("Motor", Vector3.new(0.9, 0.9, 1.2), CFrame.new(side * 2.2, wy + 0.35, z), MOTOR, Enum.Material.SmoothPlastic)
		end
	end

	-------------------------------------------------------------- intake (front = -Z)
	if intake.Style == "Claw" then
		add("ClawBase", Vector3.new(3, 0.4, 0.6), CFrame.new(0, wy + 1.2, -4.3), intake.Color, Enum.Material.Metal)
		add("ClawL", Vector3.new(0.3, 0.6, 1.8), CFrame.new(-1.2, wy + 1.2, -5.2), intake.Color, Enum.Material.Metal)
		add("ClawR", Vector3.new(0.3, 0.6, 1.8), CFrame.new(1.2, wy + 1.2, -5.2), intake.Color, Enum.Material.Metal)
		add("ClawPost", Vector3.new(0.4, 1.6, 0.4), CFrame.new(0, wy + 0.6, -4), METAL, Enum.Material.Metal)
	else
		local count = intake.Rollers or 1
		add("IntakePlateL", Vector3.new(0.25, 0.8 + count * 0.9, 2.2), CFrame.new(-2.9, wy + 0.4 + count * 0.45, -4.6), METAL, Enum.Material.Metal)
		add("IntakePlateR", Vector3.new(0.25, 0.8 + count * 0.9, 2.2), CFrame.new(2.9, wy + 0.4 + count * 0.45, -4.6), METAL, Enum.Material.Metal)
		for i = 1, count do
			local y = wy - 0.1 + i * 0.9
			local z = -4.9 + (i % 2) * 0.5
			add("Roller", Vector3.new(5.5, 0.85, 0.85), CFrame.new(0, y, z), intake.Color, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
	end

	-------------------------------------------------------------- lift (back = +Z)
	local liftColor = lift.Color
	if lift.Style == "FourBar" or lift.Style == "DR4B" then
		local towerH = lift.Style == "DR4B" and 4.5 or 3.5
		for _, side in ipairs({ -1, 1 }) do
			add("Tower", Vector3.new(0.4, towerH, 0.4), CFrame.new(side * 2.6, wy + towerH / 2, 3), METAL, Enum.Material.Metal)
			add("Arm", Vector3.new(0.3, 0.3, 5.5), CFrame.new(side * 2.6, wy + towerH - 0.4, 0.6) * CFrame.Angles(math.rad(-18), 0, 0), liftColor, Enum.Material.Metal)
			add("Arm2", Vector3.new(0.3, 0.3, 5.5), CFrame.new(side * 2.6, wy + towerH - 1.4, 0.6) * CFrame.Angles(math.rad(-18), 0, 0), liftColor, Enum.Material.Metal)
			if lift.Style == "DR4B" then
				add("UpperArm", Vector3.new(0.3, 0.3, 4.5), CFrame.new(side * 2.6, wy + towerH + 1, 1.2) * CFrame.Angles(math.rad(20), 0, 0), liftColor, Enum.Material.Metal)
			end
		end
	elseif lift.Style == "Cascade" then
		for _, side in ipairs({ -1, 1 }) do
			add("Stage1", Vector3.new(0.5, 5, 0.5), CFrame.new(side * 2.4, wy + 2.5, 3), METAL, Enum.Material.Metal)
			add("Stage2", Vector3.new(0.35, 4.5, 0.35), CFrame.new(side * 2.0, wy + 4.2, 3), liftColor, Enum.Material.Metal)
		end
		add("Carriage", Vector3.new(4.8, 0.4, 1.2), CFrame.new(0, wy + 6.3, 2.6), liftColor, Enum.Material.Metal)
	elseif lift.Style == "Catapult" then
		add("CataBase", Vector3.new(4, 0.8, 1), CFrame.new(0, wy + 0.8, 2.6), METAL, Enum.Material.Metal)
		add("CataArm", Vector3.new(0.5, 0.5, 5.5), CFrame.new(0, wy + 2.6, 1.5) * CFrame.Angles(math.rad(35), 0, 0), liftColor, Enum.Material.Metal)
		add("CataCup", Vector3.new(1.8, 0.4, 1.8), CFrame.new(0, wy + 4.2, -0.6), liftColor, Enum.Material.SmoothPlastic)
		add("Piston", Vector3.new(0.3, 2, 0.3), CFrame.new(1.3, wy + 1.6, 2.4), Color3.fromRGB(230, 230, 230), Enum.Material.Glass)
	elseif lift.Style == "Flywheel" then
		add("FlyFrame", Vector3.new(0.3, 3.5, 3.5), CFrame.new(-1.8, wy + 2.5, 2.3), METAL, Enum.Material.Metal)
		add("FlyFrame2", Vector3.new(0.3, 3.5, 3.5), CFrame.new(1.8, wy + 2.5, 2.3), METAL, Enum.Material.Metal)
		add("Flywheel", Vector3.new(0.7, 3.2, 3.2), CFrame.new(0, wy + 2.8, 2.3), liftColor, Enum.Material.Neon, Enum.PartType.Cylinder)
		add("Hood", Vector3.new(3.4, 0.25, 3), CFrame.new(0, wy + 4.5, 1.8) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(240, 240, 240), Enum.Material.Glass)
	end

	-------------------------------------------------------------- brain + battery
	add("Brain", Vector3.new(2, 0.5, 1.6), CFrame.new(0, wy + 0.75, -1.6), DARK, Enum.Material.SmoothPlastic)
	add("Screen", Vector3.new(1.6, 0.05, 1.1), CFrame.new(0, wy + 1.03, -1.6), brain.ScreenColor, Enum.Material.Neon)
	add("Battery", Vector3.new(1.4, 0.6, 2), CFrame.new(-1.4, wy + 0.8, 1.4), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic)
	if (brain.Auton or 0) >= 5 then
		add("Antenna", Vector3.new(1.8, 0.15, 0.15), CFrame.new(1.4, wy + 1.8, -1.6) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("AntennaTip", Vector3.new(0.35, 0.35, 0.35), CFrame.new(1.4, wy + 2.7, -1.6), brain.ScreenColor, Enum.Material.Neon, Enum.PartType.Ball)
	end
	if brain.Id ~= "br_basic" then
		add("Sensor", Vector3.new(0.8, 0.5, 0.4), CFrame.new(0, wy + 0.5, -4.15), Color3.fromRGB(40, 40, 45), Enum.Material.SmoothPlastic)
	end

	-------------------------------------------------------------- seat
	if options.Drive then
		local seat = Instance.new("VehicleSeat")
		seat.Name = "DriverSeat"
		seat.Size = Vector3.new(2.4, 0.4, 2.4)
		seat.CFrame = CFrame.new(0, wy + 1.1, 1.2)
		seat.Color = accent
		seat.Material = Enum.Material.SmoothPlastic
		seat.MaxSpeed = 0
		seat.Torque = 0
		seat.TurnSpeed = 0
		seat.HeadsUpDisplay = false
		seat.CanCollide = false
		seat.CanTouch = false -- only the server can seat someone
		seat.Massless = true
		seat.Anchored = true
		seat:SetAttribute("VexRobot", true)
		seat.Parent = model
	end

	if not options.NoNameplate then
		makeBillboard(root, options.Label, options.SubLabel, accent)
	end

	-------------------------------------------------------------- weld everything to root
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = d
			weld.Parent = d
		end
	end

	if options.Drive then
		local attachment = Instance.new("Attachment")
		attachment.Name = "DriveAttachment"
		attachment.Parent = root

		local lv = Instance.new("LinearVelocity")
		lv.Name = "DriveLV"
		lv.Attachment0 = attachment
		lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
		lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
		lv.PlaneVelocity = Vector2.new(0, 0)
		lv.MaxForce = stats.Force
		lv.Parent = root

		local av = Instance.new("AngularVelocity")
		av.Name = "DriveAV"
		av.Attachment0 = attachment
		av.RelativeTo = Enum.ActuatorRelativeTo.World
		av.AngularVelocity = Vector3.zero
		av.MaxTorque = stats.Force * 5
		av.Parent = root

		model:SetAttribute("MaxSpeed", stats.MaxSpeed)
		model:SetAttribute("TurnSpeed", stats.TurnSpeed)
		model:SetAttribute("Strafe", stats.Strafe)
	end

	model:SetAttribute("Rating", stats.Rating)
	return model, stats
end

function RobotBuilder.SetAnchored(model, anchored)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = anchored
		end
	end
end

return RobotBuilder

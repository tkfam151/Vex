--[[
	WorldBuilder (ModuleScript)  ->  ServerScriptService.WorldBuilder

	Generates the whole map from code so you don't need to model anything:
	  * Hub plaza with leaderboard + competition kiosk
	  * Practice field and Ranked field (VEX-style 1v1 arena)
	  * 6 team workshops (tycoon plots) with conveyor + collector
	Also builds every purchasable workshop item.

	WorldBuilder.GetWorld() builds once and returns the same table to
	every script that asks.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local WorldBuilder = {}
local world = nil

local SMOOTH = Enum.SurfaceType.Smooth
local FONT_BOLD = Font.fromEnum(Enum.Font.FredokaOne)
local FONT_SEMI = Font.fromEnum(Enum.Font.FredokaOne)
local SIGN_BLACK = Color3.fromRGB(16, 16, 18)
local VEX_RED = Color3.fromRGB(226, 35, 42)
local METAL = Color3.fromRGB(196, 198, 204)
local WHITE = Color3.fromRGB(240, 240, 240)

---------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------
local function newPart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = SMOOTH
	p.BottomSurface = SMOOTH
	p.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = parent
	return p
end

-- a part placed in plot-local coordinates
local function plotPart(plot, parent, size, pos, color, material, extra)
	local props = {
		Size = size,
		CFrame = plot.CFrame * CFrame.new(pos),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return newPart(parent, props)
end

local function surfaceText(part, face, text, textColor, bgColor, font)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = bgColor and 0 or 1
	label.BackgroundColor3 = bgColor or Color3.new(0, 0, 0)
	label.TextScaled = true
	label.FontFace = font or FONT_BOLD
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 3
	textStroke.Color = Color3.fromRGB(20, 20, 30)
	textStroke.Parent = label
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
	return label
end

local function strokedLabel(parent, text, color, thickness)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = FONT_BOLD
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 2
	stroke.Color = Color3.fromRGB(20, 20, 30)
	stroke.Parent = label
	return label
end

local function billboard(adornee, text, studsWidth, studsHeight, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(studsWidth, 0, studsHeight, 0)
	gui.StudsOffset = offset or Vector3.new(0, 3, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Parent = adornee
	local label = strokedLabel(gui, text, color)
	label.Size = UDim2.fromScale(1, 1)
	return label
end

-- name + price floating above tycoon buttons
local function priceTag(adornee, name, price)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(8, 0, 2.4, 0)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Parent = adornee
	local nameLabel = strokedLabel(gui, name, Color3.new(1, 1, 1))
	nameLabel.Size = UDim2.fromScale(1, 0.55)
	local priceLabel = strokedLabel(gui, price, Color3.fromRGB(120, 255, 100))
	priceLabel.Name = "Price"
	priceLabel.Position = UDim2.fromScale(0, 0.55)
	priceLabel.Size = UDim2.fromScale(1, 0.45)
	return gui
end

-- black VEX-style sign with a red accent bar along the bottom
local function vexSign(parent, size, cf, text, color)
	local sign = newPart(parent, { Size = size, CFrame = cf, Color = color or VEX_RED })
	newPart(parent, { Size = Vector3.new(size.X + 0.6, 0.6, size.Z + 0.2), CFrame = cf * CFrame.new(0, -size.Y / 2, 0), Color = Color3.fromRGB(255, 255, 255) })
	newPart(parent, { Size = Vector3.new(size.X + 0.6, 0.6, size.Z + 0.2), CFrame = cf * CFrame.new(0, size.Y / 2, 0), Color = Color3.fromRGB(255, 255, 255) })
	surfaceText(sign, Enum.NormalId.Front, text, Color3.new(1, 1, 1))
	return sign
end

local function setupLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.6
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.Ambient = Color3.fromRGB(60, 60, 75)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	local function ensure(className, props)
		local effect = Lighting:FindFirstChildOfClass(className)
		if not effect then
			effect = Instance.new(className)
			for k, v in pairs(props) do
				effect[k] = v
			end
			effect.Parent = Lighting
		end
	end
	ensure("Atmosphere", { Density = 0.22, Offset = 0.15, Color = Color3.fromRGB(190, 225, 255), Decay = Color3.fromRGB(120, 160, 210), Glare = 0.2, Haze = 0.8 })
	ensure("BloomEffect", { Intensity = 0.45, Size = 24, Threshold = 1.6 })
	ensure("ColorCorrectionEffect", { Saturation = 0.25, Contrast = 0.08, Brightness = 0.03 })
	ensure("SunRaysEffect", { Intensity = 0.03, Spread = 0.5 })
end

local function prompt(parent, actionText, objectText, holdTime)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText or ""
	p.HoldDuration = holdTime or 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

---------------------------------------------------------------------
-- Hub
---------------------------------------------------------------------
local function buildHub(root)
	local hub = { }
	local hubFolder = folder("Hub", root)

	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(95, 190, 70)
		baseplate.Material = Enum.Material.Grass
		for _, child in ipairs(baseplate:GetChildren()) do
			if child:IsA("Texture") then
				child:Destroy()
			end
		end
	else
		newPart(hubFolder, {
			Name = "Ground",
			Size = Vector3.new(1200, 2, 1200),
			CFrame = CFrame.new(0, -1, 0),
			Color = Color3.fromRGB(95, 190, 70),
			Material = Enum.Material.Grass,
		})
	end

	newPart(hubFolder, {
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, Config.HubRadius * 2, Config.HubRadius * 2),
		CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(235, 220, 185),
		Material = Enum.Material.SmoothPlastic,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, 72)
	spawn.Color = Color3.fromRGB(40, 40, 44)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.TopSurface = SMOOTH
	spawn.Parent = hubFolder

	-- floating title
	local title = newPart(hubFolder, {
		Name = "Title",
		Size = Vector3.new(60, 10, 1),
		CFrame = CFrame.new(0, 30, 0),
		Color = SIGN_BLACK,
	})
	newPart(hubFolder, { Size = Vector3.new(60, 0.6, 1.1), CFrame = CFrame.new(0, 25.3, 0), Color = VEX_RED })
	surfaceText(title, Enum.NormalId.Front, string.upper(Config.GameName), Color3.new(1, 1, 1))
	surfaceText(title, Enum.NormalId.Back, string.upper(Config.GameName), Color3.new(1, 1, 1))

	-- leaderboard (faces the center)
	local board = newPart(hubFolder, {
		Name = "Leaderboard",
		Size = Vector3.new(18, 22, 1),
		CFrame = CFrame.new(0, 12, -100),
		Color = SIGN_BLACK,
	})
	newPart(hubFolder, { Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(-7, 0.5, -100), Color = METAL, Material = Enum.Material.Metal })
	newPart(hubFolder, { Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(7, 0.5, -100), Color = METAL, Material = Enum.Material.Metal })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = board
	local list = Instance.new("Frame")
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = VEX_RED
	header.FontFace = FONT_BOLD
	header.TextScaled = true
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Text = "TOP TEAMS  ·  TROPHIES"
	header.Parent = list
	hub.LeaderboardRows = {}
	for i = 1, 10 do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundTransparency = 1
		row.FontFace = FONT_SEMI
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = i <= 3 and Color3.new(1, 1, 1) or Color3.fromRGB(170, 170, 178)
		row.Text = string.format("  %d    —", i)
		row.Parent = list
		hub.LeaderboardRows[i] = row
	end

	-- competition kiosk
	local kiosk = newPart(hubFolder, {
		Name = "CompetitionKiosk",
		Size = Vector3.new(14, 6, 4),
		CFrame = CFrame.new(0, 3.3, 100),
		Color = SIGN_BLACK,
	})
	hub.CompetitionPrompt = prompt(kiosk, "Enter Competitions", "Tournament Desk")
	vexSign(hubFolder, Vector3.new(18, 5, 1), CFrame.new(0, 10, 100), "COMPETITIONS", Color3.fromRGB(255, 190, 30))

	-- lamp posts
	for i = 0, 11 do
		local angle = math.rad(i * 30 + 15)
		local pos = Vector3.new(math.sin(angle), 0, math.cos(angle)) * (Config.HubRadius - 6)
		newPart(hubFolder, { Size = Vector3.new(0.8, 12, 0.8), CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(50, 50, 55), Material = Enum.Material.Metal })
		local bulb = newPart(hubFolder, { Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(pos + Vector3.new(0, 12.5, 0)), Color = Color3.fromRGB(255, 240, 200), Material = Enum.Material.Neon })
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1.5
		light.Parent = bulb
	end

	-- seed shop + sell stand (simple market stalls)
	local function stall(pos, roofA, roofB, title, signColor)
		local counter = newPart(hubFolder, { Name = "Counter", Size = Vector3.new(16, 4, 5), CFrame = CFrame.new(pos + Vector3.new(0, 2.3, 0)), Color = Color3.fromRGB(165, 110, 65), Material = Enum.Material.WoodPlanks })
		for _, x in ipairs({ -7.6, 7.6 }) do
			for _, z in ipairs({ -2.2, 2.2 }) do
				newPart(hubFolder, { Size = Vector3.new(0.8, 10, 0.8), CFrame = CFrame.new(pos + Vector3.new(x, 5.3, z)), Color = Color3.fromRGB(130, 85, 50), Material = Enum.Material.Wood })
			end
		end
		for i = 0, 5 do
			newPart(hubFolder, { Size = Vector3.new(3, 0.8, 8), CFrame = CFrame.new(pos + Vector3.new(-7.5 + i * 3, 10.6, 0)), Color = (i % 2 == 0) and roofA or roofB })
		end
		vexSign(hubFolder, Vector3.new(16, 3.4, 0.6), CFrame.new(pos + Vector3.new(0, 13.2, -1.5)), title, signColor)
		return counter
	end
	local seedCounter = stall(Vector3.new(-48, 0.3, 115), Color3.fromRGB(80, 200, 80), Color3.fromRGB(255, 255, 255), "SEED SHOP", Color3.fromRGB(60, 170, 60))
	for i = 0, 3 do
		newPart(hubFolder, { Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(-53 + i * 3.4, 5.2, 113.5), Color = Config.Seeds[(i % #Config.Seeds) + 1].Color })
	end
	local sellCounter = stall(Vector3.new(48, 0.3, 115), Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 90, 60), "SELL", Color3.fromRGB(240, 150, 30))
	hub.SeedPrompt = prompt(seedCounter, "Open Seed Shop", "Seed Shop")
	hub.SellPrompt = prompt(sellCounter, "Sell Backpack", "Sell Stand")
	hub.SellPosition = sellCounter.Position

	-- robot market conveyor
	local market = Config.Market
	local mid = (market.Start + market.End) / 2
	local length = (market.End - market.Start).Magnitude
	newPart(hubFolder, { Name = "MarketBelt", Size = Vector3.new(length + 10, 0.8, 10), CFrame = CFrame.new(mid.X, 0.4, mid.Z), Color = Color3.fromRGB(50, 50, 60), Material = Enum.Material.DiamondPlate })
	for _, side in ipairs({ -1, 1 }) do
		newPart(hubFolder, { Size = Vector3.new(length + 10, 1, 0.8), CFrame = CFrame.new(mid.X, 0.5, mid.Z + side * 5.4), Color = Color3.fromRGB(255, 200, 40) })
	end
	for _, x in ipairs({ market.Start.X, market.End.X }) do
		for _, side in ipairs({ -1, 1 }) do
			newPart(hubFolder, { Size = Vector3.new(1.2, 12, 1.2), CFrame = CFrame.new(x, 6.3, mid.Z + side * 6), Color = VEX_RED })
		end
		newPart(hubFolder, { Size = Vector3.new(1.6, 1.6, 13.2), CFrame = CFrame.new(x, 12.6, mid.Z), Color = VEX_RED })
	end
	for _, x in ipairs({ -12, 12 }) do
		newPart(hubFolder, { Size = Vector3.new(1, 16, 1), CFrame = CFrame.new(mid.X + x, 8.3, mid.Z - 7), Color = Color3.fromRGB(255, 255, 255) })
	end
	vexSign(hubFolder, Vector3.new(30, 5, 1), CFrame.new(mid.X, 17, mid.Z - 7) * CFrame.Angles(0, math.pi, 0), "ROBOT MARKET", Color3.fromRGB(60, 140, 255))
	hub.MarketFolder = folder("Market", hubFolder)

	return hub
end

---------------------------------------------------------------------
-- Driving fields
---------------------------------------------------------------------
local function buildField(root, name, center, accentText)
	local size = Config.Field.Size
	local half = size / 2
	local field = {
		Name = name,
		CFrame = CFrame.new(center),
		Size = size,
		Goals = {},
		Spawns = {},
	}
	local f = folder(name .. "Field", root)
	field.Folder = f
	field.Balls = folder("Balls", f)
	field.Robots = folder("Robots", f)

	local function at(x, y, z)
		return field.CFrame * CFrame.new(x, y, z)
	end

	-- foam tiles (6x6 grid like a real field)
	local tile = size / 6
	for ix = 0, 5 do
		for iz = 0, 5 do
			newPart(f, {
				Name = "Tile",
				Size = Vector3.new(tile, 0.5, tile),
				CFrame = at(-half + tile * (ix + 0.5), 0.35, -half + tile * (iz + 0.5)),
				Color = ((ix + iz) % 2 == 0) and Color3.fromRGB(105, 105, 112) or Color3.fromRGB(92, 92, 100),
				Material = Enum.Material.Fabric,
			})
		end
	end
	newPart(f, { Name = "CenterLine", Size = Vector3.new(0.4, 0.05, size), CFrame = at(0, 0.62, 0), Color = WHITE })

	-- perimeter walls (clear polycarbonate + aluminum rail)
	local wallH = 7
	local walls = {
		{ Vector3.new(size + 2, wallH, 1), Vector3.new(0, wallH / 2 + 0.6, -half - 0.5) },
		{ Vector3.new(size + 2, wallH, 1), Vector3.new(0, wallH / 2 + 0.6, half + 0.5) },
		{ Vector3.new(1, wallH, size), Vector3.new(-half - 0.5, wallH / 2 + 0.6, 0) },
		{ Vector3.new(1, wallH, size), Vector3.new(half + 0.5, wallH / 2 + 0.6, 0) },
	}
	for _, w in ipairs(walls) do
		newPart(f, { Name = "Wall", Size = w[1], CFrame = at(w[2].X, w[2].Y, w[2].Z), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass, Transparency = 0.6 })
		newPart(f, { Name = "Rail", Size = Vector3.new(w[1].X, 0.4, w[1].Z), CFrame = at(w[2].X, wallH + 0.8, w[2].Z), Color = METAL, Material = Enum.Material.Metal })
	end

	-- goals
	for _, info in ipairs({ { "Red", -1, Color3.fromRGB(220, 45, 50) }, { "Blue", 1, Color3.fromRGB(40, 110, 230) } }) do
		local side, sign, color = info[1], info[2], info[3]
		local gx = sign * (half - 4)
		local pad = newPart(f, { Name = side .. "GoalPad", Size = Vector3.new(8, 0.1, 12), CFrame = at(gx, 0.65, 0), Color = color, Material = Enum.Material.SmoothPlastic })
		newPart(f, { Size = Vector3.new(0.6, 8, 0.6), CFrame = at(gx + sign * 3.5, 4.6, -5.5), Color = color, Material = Enum.Material.Metal })
		newPart(f, { Size = Vector3.new(0.6, 8, 0.6), CFrame = at(gx + sign * 3.5, 4.6, 5.5), Color = color, Material = Enum.Material.Metal })
		newPart(f, { Size = Vector3.new(0.6, 0.6, 11.6), CFrame = at(gx + sign * 3.5, 8.6, 0), Color = color, Material = Enum.Material.Metal })
		newPart(f, { Name = "Net", Size = Vector3.new(0.2, 7.5, 11), CFrame = at(gx + sign * 3.7, 4.6, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.ForceField, Transparency = 0.3, CanCollide = false })
		local ring = newPart(f, {
			Name = side .. "ScoreZone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.05, Config.Field.GoalRadius * 2, Config.Field.GoalRadius * 2),
			CFrame = at(gx, 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.75,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		})
		field.Goals[side] = { Position = at(gx, 0.6, 0).Position, Pad = pad, Zone = ring, Color = color }
	end

	-- spawns
	field.Spawns.Red = CFrame.lookAt(at(-30, 0.6, -30).Position, at(0, 0.6, -30).Position)
	field.Spawns.Blue = CFrame.lookAt(at(30, 0.6, 30).Position, at(0, 0.6, 30).Position)
	field.Spawns.List = {}
	for _, p in ipairs({ { -20, -34 }, { 20, -34 }, { -20, 34 }, { 20, 34 }, { 0, -20 }, { 0, 20 }, { -28, 0 }, { 28, 0 } }) do
		local pos = at(p[1], 0.6, p[2]).Position
		table.insert(field.Spawns.List, CFrame.lookAt(pos, at(0, 0.6, 0).Position))
	end

	-- entrance kiosk
	local kiosk = newPart(f, { Name = "Kiosk", Size = Vector3.new(10, 4, 3), CFrame = at(0, 2.3, -half - 10), Color = SIGN_BLACK })
	vexSign(f, Vector3.new(28, 5, 1), at(0, 13, -half - 1.5), accentText)
	field.Kiosk = kiosk
	field.ExitCFrame = at(0, 3.5, -half - 16)

	return field
end

local function buildScoreboard(field)
	local half = field.Size / 2
	local board = newPart(field.Folder, {
		Name = "Scoreboard",
		Size = Vector3.new(40, 12, 1),
		CFrame = field.CFrame * CFrame.new(0, 17, half + 3),
		Color = SIGN_BLACK,
	})
	local labels = {}
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		gui.LightInfluence = 0
		gui.Parent = board
		local function make(text, x, w, color)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(x, 0)
			l.Size = UDim2.fromScale(w, 1)
			l.FontFace = FONT_BOLD
			l.TextScaled = true
			l.TextColor3 = color
			l.Text = text
			l.Parent = gui
			return l
		end
		table.insert(labels, {
			Red = make("0", 0, 0.3, Color3.fromRGB(255, 80, 80)),
			Status = make("WAITING FOR PLAYERS", 0.3, 0.4, Color3.new(1, 1, 1)),
			Blue = make("0", 0.7, 0.3, Color3.fromRGB(90, 160, 255)),
		})
	end
	field.Scoreboard = labels
end

---------------------------------------------------------------------
-- Workshop plots
---------------------------------------------------------------------
local function buildPlot(root, index)
	local angle = math.rad((index - 1) * (360 / Config.MaxPlots))
	local center = Vector3.new(math.sin(angle), 0, math.cos(angle)) * Config.PlotRadius
	local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))
	local color = Config.PlotColors[((index - 1) % #Config.PlotColors) + 1]
	local half = Config.PlotSize / 2

	local plot = {
		Id = index,
		CFrame = cf,
		Color = color,
		Owner = nil,
		Storage = 0,
		Built = {},
		ButtonModels = {},
		Token = 0,
	}
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = root
	plot.Folder = model
	plot.Base = folder("Base", model)
	plot.Items = folder("Items", model)
	plot.Buttons = folder("Buttons", model)
	plot.Drops = folder("Drops", model)
	plot.Bays = folder("Bays", model)

	local base = plot.Base
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1, Config.PlotSize), Vector3.new(0, 0.5, 0), Color3.fromRGB(175, 175, 180), Enum.Material.Concrete, { Name = "Floor" })
	-- colored border
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1.2, 1), Vector3.new(0, 0.6, -half + 0.5), color, Enum.Material.SmoothPlastic)
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1.2, 1), Vector3.new(0, 0.6, half - 0.5), color, Enum.Material.SmoothPlastic)
	plotPart(plot, base, Vector3.new(1, 1.2, Config.PlotSize), Vector3.new(-half + 0.5, 0.6, 0), color, Enum.Material.SmoothPlastic)
	plotPart(plot, base, Vector3.new(1, 1.2, Config.PlotSize), Vector3.new(half - 0.5, 0.6, 0), color, Enum.Material.SmoothPlastic)

	-- path to hub
	local pathLength = Config.PlotRadius - half - Config.HubRadius + 6
	plotPart(plot, base, Vector3.new(16, 0.4, pathLength), Vector3.new(0, 0.1, -half - pathLength / 2 + 2), Color3.fromRGB(150, 150, 155), Enum.Material.Concrete)

	-- owner sign
	local sign = plotPart(plot, base, Vector3.new(26, 6, 1), Vector3.new(-30, 6, -half + 1), color)
	plotPart(plot, base, Vector3.new(1, 3, 1), Vector3.new(-40, 2, -half + 1), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(1, 3, 1), Vector3.new(-20, 2, -half + 1), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(26, 0.4, 1.1), Vector3.new(-30, 3.2, -half + 1), color, Enum.Material.SmoothPlastic)
	plot.OwnerLabel = surfaceText(sign, Enum.NormalId.Front, "Empty Workshop", Color3.new(1, 1, 1))

	-- spawn pad
	plotPart(plot, base, Vector3.new(8, 0.2, 8), Vector3.new(30, 1.1, -42), color, Enum.Material.SmoothPlastic, { CanCollide = false })
	plot.SpawnCFrame = cf * CFrame.new(30, 4, -42) * CFrame.Angles(0, math.pi, 0)

	-- conveyor
	local z = Config.Layout.ConveyorZ
	local conveyor = plotPart(plot, base, Vector3.new(79, 1, 6), Vector3.new(-5.5, 3, z), Color3.fromRGB(40, 40, 45), Enum.Material.DiamondPlate, { Name = "Conveyor" })
	conveyor.AssemblyLinearVelocity = cf.RightVector * Config.ConveyorSpeed
	plotPart(plot, base, Vector3.new(79, 1.2, 0.5), Vector3.new(-5.5, 4.1, z - 3.25), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(79, 1.2, 0.5), Vector3.new(-5.5, 4.1, z + 3.25), METAL, Enum.Material.Metal)
	for x = -40, 30, 14 do
		plotPart(plot, base, Vector3.new(1, 2, 5), Vector3.new(x, 1.5, z), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
	end
	plotPart(plot, base, Vector3.new(1, 3, 6), Vector3.new(-45.5, 4, z), METAL, Enum.Material.Metal) -- end stop

	-- collector
	local collector = plotPart(plot, base, Vector3.new(11, 1, 10), Vector3.new(39.5, 1.5, z), Color3.fromRGB(40, 40, 44), Enum.Material.DiamondPlate, { Name = "Collector" })
	plotPart(plot, base, Vector3.new(11, 3, 0.5), Vector3.new(39.5, 3, z - 5), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(11, 3, 0.5), Vector3.new(39.5, 3, z + 5), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(0.5, 3, 10), Vector3.new(45.25, 3, z), METAL, Enum.Material.Metal)
	plot.Collector = collector
	billboard(collector, "PART COLLECTOR", 10, 1.5, Vector3.new(0, 4, 0), Color3.fromRGB(255, 255, 255))

	-- collect pad
	local collectPad = plotPart(plot, base, Vector3.new(7, 0.4, 7), Vector3.new(40, 1.2, -4), Color3.fromRGB(52, 199, 89), Enum.Material.SmoothPlastic, { Name = "CollectPad" })
	plot.CollectPad = collectPad
	plot.StorageLabel = billboard(collectPad, "Collect\n$0", 9, 3, Vector3.new(0, 4, 0), Color3.fromRGB(120, 255, 140))

	-- garden beds
	plot.GardenTiles = {}
	local garden = Config.Garden
	local tileIndex = 0
	for _, tz in ipairs(garden.TileRows) do
		for _, tx in ipairs(garden.TileColumns) do
			tileIndex += 1
			plotPart(plot, base, Vector3.new(garden.TileSize + 0.8, 0.6, garden.TileSize + 0.8), Vector3.new(tx, 1.15, tz), Color3.fromRGB(150, 100, 55), Enum.Material.WoodPlanks)
			local bed = plotPart(plot, base, Vector3.new(garden.TileSize, 0.6, garden.TileSize), Vector3.new(tx, 1.3, tz), Color3.fromRGB(105, 70, 40), Enum.Material.Ground, { Name = "Bed" .. tileIndex })
			local bedPrompt = prompt(bed, "Plant", "Garden Bed")
			bedPrompt.MaxActivationDistance = 8
			bedPrompt.Enabled = false
			plot.GardenTiles[tileIndex] = { Part = bed, Prompt = bedPrompt, Key = "t" .. tileIndex }
		end
	end

	-- showcase pads for market robots
	plot.ShowcasePads = {}
	local market = Config.Market
	local padIndex = 0
	for _, pz in ipairs(market.PadRows) do
		for _, px in ipairs(market.PadColumns) do
			padIndex += 1
			plotPart(plot, base, Vector3.new(market.PadSize + 0.8, 0.4, market.PadSize + 0.8), Vector3.new(px, 1.1, pz), color)
			local showPad = plotPart(plot, base, Vector3.new(market.PadSize, 0.5, market.PadSize), Vector3.new(px, 1.3, pz), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic, { Name = "Showcase" .. padIndex })
			local cashLabel = billboard(showPad, "", 8, 1.6, Vector3.new(0, 12, 0), Color3.fromRGB(120, 255, 100))
			plot.ShowcasePads[padIndex] = { Part = showPad, Key = "p" .. padIndex, Label = cashLabel }
		end
	end

	-- base lock pad + laser walls
	local lockPad = plotPart(plot, base, Vector3.new(6, 0.4, 6), market.LockPad + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 70, 70), Enum.Material.Neon, { Name = "LockPad" })
	plot.LockPad = lockPad
	plot.LockLabel = billboard(lockPad, "LOCK BASE", 8, 2, Vector3.new(0, 3, 0), Color3.fromRGB(255, 140, 140))
	plot.Lasers = {}
	local laserH = 14
	local laserSpecs = {
		{ Vector3.new(Config.PlotSize, laserH, 0.6), Vector3.new(0, laserH / 2 + 1, -half - 0.4) },
		{ Vector3.new(Config.PlotSize, laserH, 0.6), Vector3.new(0, laserH / 2 + 1, half + 0.4) },
		{ Vector3.new(0.6, laserH, Config.PlotSize), Vector3.new(-half - 0.4, laserH / 2 + 1, 0) },
		{ Vector3.new(0.6, laserH, Config.PlotSize), Vector3.new(half + 0.4, laserH / 2 + 1, 0) },
	}
	for _, spec in ipairs(laserSpecs) do
		local laser = plotPart(plot, base, spec[1], spec[2], Color3.fromRGB(255, 40, 60), Enum.Material.Neon, { Name = "Laser", Transparency = 1, CanCollide = false, CanQuery = false })
		table.insert(plot.Lasers, laser)
	end
	plot.LockedUntil = 0
	plot.LockReadyAt = 0

	return plot
end

---------------------------------------------------------------------
-- Tycoon buttons
---------------------------------------------------------------------
function WorldBuilder.BuildButton(plot, item)
	local cols = Config.Layout.ButtonColumns
	local rows = Config.Layout.ButtonRows
	local i = item.Index - 1
	local x = cols[(i % #cols) + 1]
	local z = rows[(math.floor(i / #cols) % #rows) + 1]

	local model = Instance.new("Model")
	model.Name = "Button_" .. item.Id
	local pad = plotPart(plot, model, Vector3.new(0.6, 5, 5), Vector3.new(x, 1.3, z), Color3.fromRGB(60, 220, 90), Enum.Material.Neon, {
		Name = "Pad",
		Shape = Enum.PartType.Cylinder,
		CanCollide = false,
	})
	pad.CFrame = pad.CFrame * CFrame.Angles(0, 0, math.rad(90))
	plotPart(plot, model, Vector3.new(0.4, 6, 6), Vector3.new(x, 1.1, z), Color3.fromRGB(40, 40, 45), Enum.Material.Metal, {
		Shape = Enum.PartType.Cylinder,
		CFrame = plot.CFrame * CFrame.new(x, 1.1, z) * CFrame.Angles(0, 0, math.rad(90)),
	})
	local priceText = item.Cost == 0 and "FREE" or Config.Money(item.Cost)
	priceTag(pad, item.Name, priceText)
	model.PrimaryPart = pad
	model.Parent = plot.Buttons
	return model
end

---------------------------------------------------------------------
-- Robot bays
---------------------------------------------------------------------
function WorldBuilder.BuildBayPad(plot, index)
	local pos = Config.Layout.BayPositions[index]
	local pad = plotPart(plot, plot.Bays, Vector3.new(10, 0.3, 11), pos + Vector3.new(0, 1.15, 0), Color3.fromRGB(45, 48, 60), Enum.Material.Metal, { Name = "BayPad" .. index })
	plotPart(plot, plot.Bays, Vector3.new(10, 0.32, 0.4), pos + Vector3.new(0, 1.16, -5.3), VEX_RED, Enum.Material.SmoothPlastic)
	return pad
end

---------------------------------------------------------------------
-- Items
---------------------------------------------------------------------
local itemBuilders = {}

function itemBuilders.Dropper(plot, item, model)
	local x = Config.Layout.DropperX[item.Slot]
	local z = Config.Layout.ConveyorZ
	plotPart(plot, model, Vector3.new(1.2, 12, 1.2), Vector3.new(x, 7, z + 5.5), METAL, Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(1, 1, 5), Vector3.new(x, 12.5, z + 3), METAL, Enum.Material.Metal)
	local body = plotPart(plot, model, Vector3.new(4.5, 4, 4.5), Vector3.new(x, 11, z), item.DropColor, Enum.Material.Metal, { Name = "Body" })
	plotPart(plot, model, Vector3.new(4.7, 0.6, 4.7), Vector3.new(x, 13.2, z), SIGN_BLACK, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(2, 1.5, 2), Vector3.new(x, 8.3, z), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	local dropPoint = Instance.new("Attachment")
	dropPoint.Name = "DropPoint"
	dropPoint.Parent = body
	dropPoint.WorldPosition = (plot.CFrame * CFrame.new(x, 6.6, z)).Position
	billboard(body, item.Name, 8, 1.4, Vector3.new(0, 4.5, 0), Color3.new(1, 1, 1))
	model.PrimaryPart = body
end

function itemBuilders.Upgrader(plot, item, model)
	local x = Config.Layout.UpgraderX[item.Slot]
	local z = Config.Layout.ConveyorZ
	plotPart(plot, model, Vector3.new(1, 8, 1), Vector3.new(x, 5, z - 4), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(1, 8, 1), Vector3.new(x, 5, z + 4), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	local top = plotPart(plot, model, Vector3.new(1.4, 1.4, 9), Vector3.new(x, 9.5, z), SIGN_BLACK, Enum.Material.Metal)
	local laser = plotPart(plot, model, Vector3.new(0.4, 3.5, 6), Vector3.new(x, 5.25, z), item.Color, Enum.Material.Neon, {
		Name = "Laser",
		Transparency = 0.45,
		CanCollide = false,
	})
	billboard(top, item.Name .. "  ·  " .. item.Multiplier .. "×", 8, 1.4, Vector3.new(0, 2, 0), item.Color)
	model.PrimaryPart = laser
end

function itemBuilders.Walls(plot, _, model)
	local half = Config.PlotSize / 2
	local wallColor = Color3.fromRGB(230, 230, 235)
	plotPart(plot, model, Vector3.new(Config.PlotSize, 14, 1), Vector3.new(0, 8, half - 0.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1, 14, 75), Vector3.new(-half + 0.5, 8, 17.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1, 14, 75), Vector3.new(half - 0.5, 8, 17.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(Config.PlotSize, 1.5, 1.2), Vector3.new(0, 6, half - 0.6), VEX_RED, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1.2, 1.5, 75), Vector3.new(-half + 0.6, 6, 17.5), VEX_RED, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1.2, 1.5, 75), Vector3.new(half - 0.6, 6, 17.5), VEX_RED, Enum.Material.SmoothPlastic)
end

function itemBuilders.Assembly(plot, _, model)
	local tableTop = plotPart(plot, model, Vector3.new(12, 0.6, 6), Vector3.new(-38, 4, 36), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks, { Name = "Workbench" })
	for _, p in ipairs({ { -43, 33.5 }, { -33, 33.5 }, { -43, 38.5 }, { -33, 38.5 } }) do
		plotPart(plot, model, Vector3.new(0.6, 3, 0.6), Vector3.new(p[1], 2.5, p[2]), METAL, Enum.Material.Metal)
	end
	local monitor = plotPart(plot, model, Vector3.new(5, 3.2, 0.3), Vector3.new(-38, 6.3, 38.5), Color3.fromRGB(20, 20, 25))
	surfaceText(monitor, Enum.NormalId.Front, "ROBOT LAB", Color3.new(1, 1, 1), SIGN_BLACK)
	-- tool rack
	plotPart(plot, model, Vector3.new(0.6, 6, 0.6), Vector3.new(-47, 4, 36), METAL, Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(0.4, 0.4, 4), Vector3.new(-46, 6.5, 35) , Color3.fromRGB(240, 120, 30), Enum.Material.Metal)
	local p = prompt(tableTop, "Open Robot Lab", "Assembly Station")
	p.Name = "LabPrompt"
	-- display pad for the current design
	local display = plotPart(plot, model, Vector3.new(0.4, 12, 12), Vector3.new(-20, 1.2, 36), Color3.fromRGB(45, 48, 60), Enum.Material.Metal, {
		Name = "DisplayPad",
		Shape = Enum.PartType.Cylinder,
		CFrame = plot.CFrame * CFrame.new(-20, 1.2, 36) * CFrame.Angles(0, 0, math.rad(90)),
	})
	billboard(display, "CURRENT DESIGN", 10, 1.5, Vector3.new(0, 1.5, -7), plot.Color)
	model.PrimaryPart = tableTop
end

function itemBuilders.Bay()
	-- bays are drawn by TycoonServer.refreshBays
end

function itemBuilders.Tiles(plot, _, model)
	for ix = 0, 9 do
		for iz = 0, 2 do
			plotPart(plot, model, Vector3.new(10, 0.1, 10), Vector3.new(-50 + ix * 10 + 5, 1.04, 21 + iz * 10 + 5), ((ix + iz) % 2 == 0) and Color3.fromRGB(105, 105, 112) or Color3.fromRGB(92, 92, 100), Enum.Material.Fabric, { CanCollide = false })
		end
	end
end

function itemBuilders.Banner(plot, _, model)
	local half = Config.PlotSize / 2
	local banner = plotPart(plot, model, Vector3.new(34, 10, 0.3), Vector3.new(0, 17, half - 1.4), plot.Color, Enum.Material.Fabric)
	surfaceText(banner, Enum.NormalId.Front, "TEAM " .. string.upper(plot.OwnerName or "ROBOTICS"), Color3.new(1, 1, 1))
	for _, x in ipairs({ -45, -15, 15, 45 }) do
		plotPart(plot, model, Vector3.new(0.6, 22, 0.6), Vector3.new(x, 11, half - 3), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
		local lamp = plotPart(plot, model, Vector3.new(2.5, 1, 2.5), Vector3.new(x, 22, half - 4.5), Color3.fromRGB(255, 245, 220), Enum.Material.Neon)
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 40
		light.Angle = 80
		light.Brightness = 2
		light.Parent = lamp
	end
end

function itemBuilders.Shelf(plot, _, model)
	local half = Config.PlotSize / 2
	for i, y in ipairs({ 4, 8 }) do
		plotPart(plot, model, Vector3.new(2, 0.4, 20), Vector3.new(-half + 2, y, 14 - i * 2), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks)
		for k = 0, 3 do
			local tz = 14 - i * 2 - 8 + k * 5
			plotPart(plot, model, Vector3.new(1.2, 0.4, 1.2), Vector3.new(-half + 2, y + 0.4, tz), Color3.fromRGB(80, 60, 30), Enum.Material.Wood)
			plotPart(plot, model, Vector3.new(0.4, 1.2, 0.4), Vector3.new(-half + 2, y + 1.1, tz), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
			plotPart(plot, model, Vector3.new(1.2, 1.2, 1.2), Vector3.new(-half + 2, y + 2.1, tz), Color3.fromRGB(255, 200, 60), Enum.Material.Metal, { Shape = Enum.PartType.Ball })
		end
	end
	local sign = plotPart(plot, model, Vector3.new(0.4, 3, 14), Vector3.new(-half + 1.5, 12.5, 11), Color3.fromRGB(25, 28, 40))
	local label = surfaceText(sign, Enum.NormalId.Right, "0 TROPHIES", Color3.new(1, 1, 1))
	label.Name = "TrophyLabel"
end

function itemBuilders.Overclock(plot, _, model)
	local z = Config.Layout.ConveyorZ
	local core = plotPart(plot, model, Vector3.new(5, 7, 5), Vector3.new(-50, 4.5, z - 9), Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
	for i = 0, 2 do
		plotPart(plot, model, Vector3.new(5.2, 0.5, 5.2), Vector3.new(-50, 2.5 + i * 2, z - 9), Color3.fromRGB(80, 200, 255), Enum.Material.Neon)
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(80, 200, 255)
	light.Range = 20
	light.Brightness = 3
	light.Parent = core
	billboard(core, "Factory Overclock", 8, 1.5, Vector3.new(0, 5, 0), Color3.fromRGB(80, 200, 255))
end

function itemBuilders.Hall(plot, _, model)
	local half = Config.PlotSize / 2
	local gold = Color3.fromRGB(255, 200, 60)
	plotPart(plot, model, Vector3.new(2, 18, 2), Vector3.new(-10, 10, -half + 2), gold, Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(2, 18, 2), Vector3.new(10, 10, -half + 2), gold, Enum.Material.Metal)
	local top = plotPart(plot, model, Vector3.new(24, 4, 2), Vector3.new(0, 20, -half + 2), gold, Enum.Material.Metal)
	surfaceText(top, Enum.NormalId.Front, "CHAMPIONS", Color3.fromRGB(40, 30, 0))
	plotPart(plot, model, Vector3.new(16, 0.2, 30), Vector3.new(0, 1.02, -half + 16), SIGN_BLACK, Enum.Material.SmoothPlastic, { CanCollide = false })
end

function WorldBuilder.BuildItem(plot, item)
	local model = Instance.new("Model")
	model.Name = item.Id
	model.Parent = plot.Items
	local builder = itemBuilders[item.Type]
	if builder then
		builder(plot, item, model)
	end
	return model
end

---------------------------------------------------------------------
-- Entry point
---------------------------------------------------------------------
function WorldBuilder.GetWorld()
	if world then
		return world
	end
	local existing = workspace:FindFirstChild("VexWorld")
	if existing then
		existing:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "VexWorld"
	root.Parent = workspace

	setupLighting()
	world = {}
	world.Root = root
	world.Hub = buildHub(root)
	world.Fields = {
		Practice = buildField(root, "Practice", Vector3.new(-62, 0, 0), "PRACTICE FIELD"),
		Ranked = buildField(root, "Ranked", Vector3.new(62, 0, 0), "RANKED  ·  1 V 1"),
	}
	buildScoreboard(world.Fields.Ranked)
	world.Fields.Practice.Prompt = prompt(world.Fields.Practice.Kiosk, "Drive Your Robot", "Practice Field")
	world.Fields.Ranked.Prompt = prompt(world.Fields.Ranked.Kiosk, "Join / Leave Queue", "Ranked 1v1")

	world.Plots = {}
	local plotsFolder = folder("Plots", root)
	for i = 1, Config.MaxPlots do
		world.Plots[i] = buildPlot(plotsFolder, i)
	end
	return world
end

return WorldBuilder

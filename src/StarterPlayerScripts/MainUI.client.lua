--[[
	MainUI (LocalScript)  ->  StarterPlayer.StarterPlayerScripts.MainUI

	The complete interface, built in code:
	  * HUD: rolling cash counter with +$ popups, trophies, season, next-goal bar
	  * Side menu with alert badges
	  * Robot Lab with a live spinning 3D robot preview + stat bars
	  * Garage cards with 3D previews, Competitions, Drive, Season, Shop
	  * Animated tournament results, match HUD, countdown, match results
	  * Slide-in notifications
	Everything auto-scales for phone, tablet and desktop.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRemote = Remotes:WaitForChild("Request")
local ArenaRemote = Remotes:WaitForChild("ArenaRequest")
local DataUpdate = Remotes:WaitForChild("DataUpdate")
local NotifyRemote = Remotes:WaitForChild("Notify")
local OpenUIRemote = Remotes:WaitForChild("OpenUI")
local ArenaState = Remotes:WaitForChild("ArenaState")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local State = nil -- latest snapshot from the server
local Arena = { Mode = "None" }
local cooldownEnds = {} -- [compId] = os.clock() when ready again

---------------------------------------------------------------------
-- Theme
---------------------------------------------------------------------
local C = {
	Bg = Color3.fromRGB(14, 16, 26),
	Panel = Color3.fromRGB(22, 25, 38),
	Panel2 = Color3.fromRGB(30, 34, 52),
	Card = Color3.fromRGB(36, 41, 62),
	Line = Color3.fromRGB(66, 72, 100),
	Text = Color3.fromRGB(245, 247, 255),
	Muted = Color3.fromRGB(150, 158, 186),
	Dark = Color3.fromRGB(20, 22, 30),
	Red = Color3.fromRGB(232, 56, 66),
	Blue = Color3.fromRGB(56, 132, 244),
	Green = Color3.fromRGB(46, 196, 110),
	Gold = Color3.fromRGB(255, 196, 60),
	Purple = Color3.fromRGB(150, 90, 230),
	Orange = Color3.fromRGB(245, 130, 40),
	Cyan = Color3.fromRGB(40, 200, 220),
	Disabled = Color3.fromRGB(58, 63, 84),
}
local TIER = { Color3.fromRGB(150, 158, 175), C.Green, C.Blue, C.Purple, C.Orange, C.Gold, C.Red }
local SLOT_COLOR = { Drivetrain = C.Red, Intake = C.Green, Lift = C.Blue, Brain = C.Purple }
local STAT_STYLE = {
	{ Key = "Speed", Icon = "⚡", Color = C.Cyan },
	{ Key = "Power", Icon = "💪", Color = C.Red },
	{ Key = "Control", Icon = "🎯", Color = C.Purple },
	{ Key = "Scoring", Icon = "🏀", Color = C.Gold },
}
local FONT = Enum.Font.GothamBold
local FONT_BLACK = Enum.Font.GothamBlack
local FONT_MED = Enum.Font.GothamMedium
local CENTER = Enum.TextXAlignment.Center
local RIGHT = Enum.TextXAlignment.Right

-- highest possible value of each stat (for stat bars)
local STAT_MAX = {}
for _, style in ipairs(STAT_STYLE) do
	local total = 0
	for _, slot in ipairs(Config.ModuleSlots) do
		local best = 0
		for _, def in ipairs(Config.Modules[slot]) do
			best = math.max(best, def[style.Key] or 0)
		end
		total += best
	end
	STAT_MAX[style.Key] = math.max(total, 1)
end

---------------------------------------------------------------------
-- UI toolkit
---------------------------------------------------------------------
local function tween(obj, time, props, style, direction)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function shade(color, factor)
	return Color3.new(math.clamp(color.R * factor, 0, 1), math.clamp(color.G * factor, 0, 1), math.clamp(color.B * factor, 0, 1))
end

local function new(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", { Color = color or C.Line, Thickness = thickness or 1.5, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function gradient(c1, c2, rotation)
	return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rotation or 90 })
end

local SHADE_TOP, SHADE_BOTTOM = Color3.new(1, 1, 1), Color3.fromRGB(200, 202, 212)

local function vlist(gap, hAlign)
	return new("UIListLayout", { Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left })
end

local function hlist(gap, hAlign)
	return new("UIListLayout", {
		Padding = UDim.new(0, gap or 8),
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
	})
end

local function Text(p)
	local label = new("TextLabel", {
		Name = p.Name or "Text",
		BackgroundTransparency = 1,
		Font = p.Font or FONT,
		TextColor3 = p.Color or C.Text,
		TextScaled = true,
		TextWrapped = true,
		RichText = true,
		Text = p.Text or "",
		TextXAlignment = p.AlignX or Enum.TextXAlignment.Left,
		TextYAlignment = p.AlignY or Enum.TextYAlignment.Center,
		Size = p.Size or UDim2.new(1, 0, 0, 20),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
	}, {
		new("UITextSizeConstraint", { MaxTextSize = p.Max or 18, MinTextSize = p.Min or 7 }),
	})
	label.Parent = p.Parent
	return label
end

local function Box(p, children)
	local f = new("Frame", {
		Name = p.Name or "Box",
		BorderSizePixel = 0,
		BackgroundColor3 = p.Color or C.Card,
		BackgroundTransparency = p.Transparency or 0,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
		ZIndex = p.Z or 1,
	}, children)
	if p.Radius ~= false then
		corner(p.Radius or 12).Parent = f
	end
	if p.Stroke then
		stroke(p.Stroke, p.StrokeThickness or 1.5, p.StrokeTransparency or 0).Parent = f
	end
	if p.Gradient then
		gradient(p.Gradient[1], p.Gradient[2], p.Gradient[3]).Parent = f
	end
	f.Parent = p.Parent
	return f
end

local function Button(p, onClick)
	local color = p.Color or C.Blue
	local b = new("TextButton", {
		Name = p.Name or "Button",
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		BackgroundColor3 = color,
		Size = p.Size or UDim2.new(0, 120, 0, 40),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
	})
	corner(p.Radius or 10).Parent = b
	gradient(SHADE_TOP, SHADE_BOTTOM, 90).Parent = b
	local outline = stroke(shade(color, 1.3), 1.5, 0.4)
	outline.Name = "Outline"
	outline.Parent = b
	local scale = new("UIScale", { Parent = b })
	local label = Text({ Parent = b, Name = "Label", Text = p.Text or "", Font = FONT_BLACK, Max = p.Max or 16, AlignX = CENTER, Color = p.TextColor or C.Text, Size = UDim2.new(1, -12, 1, -8), Position = UDim2.new(0, 6, 0, 4) })
	local enabled = p.Enabled ~= false
	b:SetAttribute("Enabled", enabled)
	b:SetAttribute("BaseColor", color)
	if not enabled then
		label.TextTransparency = 0.45
	end
	b.MouseEnter:Connect(function()
		if b:GetAttribute("Enabled") then
			tween(b, 0.12, { BackgroundColor3 = shade(b:GetAttribute("BaseColor"), 1.15) })
		end
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.12, { BackgroundColor3 = b:GetAttribute("BaseColor") })
		tween(scale, 0.1, { Scale = 1 })
	end)
	b.MouseButton1Down:Connect(function()
		if b:GetAttribute("Enabled") then
			tween(scale, 0.06, { Scale = 0.94 })
		end
	end)
	b.MouseButton1Up:Connect(function()
		tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	b.Activated:Connect(function()
		if b:GetAttribute("Enabled") and onClick then
			onClick(b)
		end
	end)
	b.Parent = p.Parent
	return b
end

local function setButton(b, text, color, enabled)
	if text then
		b.Label.Text = text
	end
	if color then
		b:SetAttribute("BaseColor", color)
		b.BackgroundColor3 = color
		b.Outline.Color = shade(color, 1.3)
	end
	if enabled ~= nil then
		b:SetAttribute("Enabled", enabled)
		b.Label.TextTransparency = enabled and 0 or 0.45
	end
end

local function Pill(parent, text, color, width, order, textColor)
	local pill = Box({ Parent = parent, Order = order, Size = UDim2.new(0, width, 0, 22), Color = color, Radius = 11 })
	Text({ Parent = pill, Text = text, Max = 12, AlignX = CENTER, Font = FONT_BLACK, Color = textColor or C.Text, Size = UDim2.new(1, -10, 1, -6), Position = UDim2.new(0, 5, 0, 3) })
	return pill
end

local function Scroll(p)
	local s = new("ScrollingFrame", {
		Name = p.Name or "List",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.Line,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
	})
	if p.Grid then
		new("UIGridLayout", { Parent = s, CellSize = p.Grid, CellPadding = UDim2.new(0, 12, 0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
	else
		vlist(p.Gap or 8).Parent = s
	end
	new("UIPadding", { Parent = s, PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6) })
	s.Parent = p.Parent
	return s
end

local function Keycap(parent, key, position)
	local cap = Box({ Parent = parent, Size = UDim2.new(0, 34, 0, 30), Position = position, Color = C.Panel2, Radius = 8, Stroke = C.Line })
	Box({ Parent = cap, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), Color = C.Line, Radius = 2 })
	Text({ Parent = cap, Text = key, Font = FONT_BLACK, Max = 14, AlignX = CENTER, Size = UDim2.new(1, -4, 1, -6), Position = UDim2.new(0, 2, 0, 1) })
	return cap
end

---------------------------------------------------------------------
-- Screens + auto scaling
---------------------------------------------------------------------
local mainGui = new("ScreenGui", { Name = "VexUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1, Parent = playerGui })
local modalGui = new("ScreenGui", { Name = "VexModal", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10, Parent = playerGui })

local scalers = {}
local currentScale = 1
local function autoScale(guiObject)
	local s = new("UIScale", { Parent = guiObject, Scale = currentScale })
	table.insert(scalers, s)
	return s
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local vp = camera.ViewportSize
	currentScale = math.clamp(math.min(vp.X / 1366, vp.Y / 800), 0.5, 1.2)
	for _, s in ipairs(scalers) do
		s.Scale = currentScale
	end
end

---------------------------------------------------------------------
-- Live robot previews (ViewportFrames)
---------------------------------------------------------------------
local previews = {}
local previewAngle = 0

local function RobotPreview(parent, loadout, size, position, background)
	local vp = new("ViewportFrame", {
		BackgroundColor3 = background or C.Bg,
		BorderSizePixel = 0,
		Size = size,
		Position = position or UDim2.new(),
		Ambient = Color3.fromRGB(150, 150, 165),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-0.6, -1, -0.4),
	})
	corner(14).Parent = vp
	local camera = new("Camera", { FieldOfView = 34 })
	camera.CFrame = CFrame.lookAt(Vector3.new(10, 8, -14), Vector3.new(0, 1.2, 0))
	camera.Parent = vp
	vp.CurrentCamera = camera
	new("Part", {
		Anchored = true,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 13, 13),
		CFrame = CFrame.new(0, -1.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(58, 62, 84),
		Material = Enum.Material.SmoothPlastic,
		Parent = vp,
	})
	local ok, model = pcall(RobotBuilder.Build, loadout, { NoNameplate = true })
	if ok and model then
		model:PivotTo(CFrame.Angles(0, previewAngle, 0))
		model.Parent = vp
		table.insert(previews, model)
	end
	vp.Parent = parent
	return vp
end

RunService.RenderStepped:Connect(function(dt)
	previewAngle = (previewAngle + dt * 0.7) % (math.pi * 2)
	for i = #previews, 1, -1 do
		local model = previews[i]
		if model.Parent == nil then
			table.remove(previews, i)
		else
			model:PivotTo(CFrame.Angles(0, previewAngle, 0))
		end
	end
end)

---------------------------------------------------------------------
-- Cash / state helpers
---------------------------------------------------------------------
local function cash()
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Cash")
	return value and value.Value or (State and State.Cash or 0)
end

-- things inside the open panel that update without a full re-render
local live = { Cash = {}, Tick = {} }
local function onCash(fn)
	table.insert(live.Cash, fn)
	fn(cash())
end
local function onTick(fn)
	table.insert(live.Tick, fn)
	fn()
end

---------------------------------------------------------------------
-- Notifications (slide in from the right)
---------------------------------------------------------------------
local toastHost = Box({ Parent = mainGui, Transparency = 1, Radius = false, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 120), Size = UDim2.new(0, 340, 0, 420) }, { vlist(8, Enum.HorizontalAlignment.Right) })
autoScale(toastHost)

local TOAST_STYLE = {
	success = { C.Green, "✓" },
	error = { C.Red, "✕" },
	cash = { C.Gold, "$" },
	info = { C.Blue, "i" },
}
local toastCount = 0

local function toast(text, kind)
	if type(text) ~= "string" or text == "" then
		return
	end
	local style = TOAST_STYLE[kind] or TOAST_STYLE.info
	toastCount += 1
	local holder = Box({ Parent = toastHost, Transparency = 1, Radius = false, Size = UDim2.new(1, 0, 0, 56), Order = toastCount })
	local card = Box({ Parent = holder, Color = C.Panel, Transparency = 0.04, Radius = 12, Stroke = style[1], StrokeTransparency = 0.5, Position = UDim2.new(0, 360, 0, 0), Size = UDim2.fromScale(1, 1) })
	Box({ Parent = card, Color = style[1], Radius = 3, Size = UDim2.new(0, 5, 1, -16), Position = UDim2.new(0, 7, 0, 8) })
	local icon = Box({ Parent = card, Color = style[1], Radius = 15, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 20, 0.5, 0), Anchor = Vector2.new(0, 0.5), Gradient = { SHADE_TOP, SHADE_BOTTOM, 90 } })
	Text({ Parent = icon, Text = style[2], Font = FONT_BLACK, Max = 16, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })
	Text({ Parent = card, Text = text, Max = 15, Font = FONT, Size = UDim2.new(1, -70, 1, -12), Position = UDim2.new(0, 60, 0, 6) })
	tween(card, 0.35, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)

	local frames = {}
	for _, child in ipairs(toastHost:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(frames, child)
		end
	end
	if #frames > 5 then
		table.sort(frames, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		frames[1]:Destroy()
	end

	task.delay(3.8, function()
		if card.Parent then
			tween(card, 0.3, { Position = UDim2.new(0, 360, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.wait(0.32)
			holder:Destroy()
		end
	end)
end

NotifyRemote.OnClientEvent:Connect(toast)

---------------------------------------------------------------------
-- Server calls
---------------------------------------------------------------------
local busy = false
local function request(remote, ...)
	if busy then
		return false, nil
	end
	busy = true
	local ok, a, b = pcall(remote.InvokeServer, remote, ...)
	busy = false
	if not ok then
		return false, "Connection problem, try again"
	end
	return a, b
end

local function act(action, ...)
	local ok, msg = request(RequestRemote, action, ...)
	if type(msg) == "string" then
		toast(msg, ok and "success" or "error")
	end
	return ok, msg
end

---------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------
local hudHost = Box({ Parent = mainGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0, 580, 0, 100) })
autoScale(hudHost)
local chipRow = Box({ Parent = hudHost, Transparency = 1, Radius = false, Size = UDim2.new(1, 0, 0, 58) }, { hlist(10, Enum.HorizontalAlignment.Center) })

local function Chip(order, width, accent, icon)
	local chip = Box({ Parent = chipRow, Order = order, Size = UDim2.new(0, width, 0, 58), Color = C.Panel, Transparency = 0.06, Radius = 16, Stroke = accent, StrokeTransparency = 0.5 })
	local iconBox = Box({ Parent = chip, Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, 8, 0.5, 0), Anchor = Vector2.new(0, 0.5), Color = accent, Radius = 12, Gradient = { SHADE_TOP, Color3.fromRGB(165, 165, 175), 90 } })
	Text({ Parent = iconBox, Text = icon, AlignX = CENTER, Max = 22, Size = UDim2.fromScale(1, 1) })
	local main = Text({ Parent = chip, Font = FONT_BLACK, Max = 24, Position = UDim2.new(0, 58, 0, 7), Size = UDim2.new(1, -66, 0, 26) })
	local sub = Text({ Parent = chip, Font = FONT_MED, Color = C.Muted, Max = 13, Position = UDim2.new(0, 58, 0, 33), Size = UDim2.new(1, -66, 0, 16) })
	return chip, main, sub
end

local cashChip, cashMain, cashSub = Chip(1, 250, C.Green, "💵")
local _, trophyMain, trophySub = Chip(2, 150, C.Gold, "🏆")
local _, seasonMain, seasonSub = Chip(3, 150, C.Purple, "🔄")
trophySub.Text = "trophies"

-- next goal bar
local goalBar = Box({ Parent = hudHost, Color = C.Panel, Transparency = 0.1, Radius = 13, Stroke = C.Line, StrokeTransparency = 0.5, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.new(0, 400, 0, 26) })
local goalFill = Box({ Parent = goalBar, Color = Color3.new(1, 1, 1), Radius = 13, Size = UDim2.new(0, 0, 1, 0), Gradient = { C.Green, shade(C.Green, 0.6), 0 } })
local goalName = Text({ Parent = goalBar, Font = FONT_BLACK, Max = 13, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.62, -12, 1, 0) })
local goalValue = Text({ Parent = goalBar, Font = FONT_BLACK, Max = 13, AlignX = RIGHT, Position = UDim2.new(0.62, 0, 0, 0), Size = UDim2.new(0.38, -12, 1, 0) })

local function nextGoal()
	if not State then
		return nil, 0
	end
	local best = nil
	for _, item in ipairs(Config.Items) do
		if not State.Purchased[item.Id] and (item.Requires == nil or State.Purchased[item.Requires]) then
			if not best or item.Cost < best.Cost then
				best = item
			end
		end
	end
	if best then
		return best.Name, best.Cost
	end
	return "New Season", Config.GetSeasonCost(State.Season)
end

local function updateGoal(money)
	local name, cost = nextGoal()
	if not name then
		goalBar.Visible = false
		return
	end
	goalBar.Visible = Arena.Mode ~= "Practice" and Arena.Mode ~= "Ranked"
	goalName.Text = "🎯 NEXT: " .. string.upper(name)
	local progress = cost > 0 and math.clamp(money / cost, 0, 1) or 1
	goalValue.Text = progress >= 1 and "READY! ✓" or (Config.Money(money) .. " / " .. Config.Money(cost))
	goalValue.TextColor3 = progress >= 1 and C.Gold or C.Text
	tween(goalFill, 0.3, { Size = UDim2.new(math.max(progress, 0.04), 0, 1, 0) })
end

-- rolling cash number + "+$" popups
local cashDisplay = new("NumberValue", { Value = 0 })
cashDisplay.Changed:Connect(function(v)
	cashMain.Text = Config.Money(v)
end)
local lastCash = nil
local pendingGain = 0
local popupQueued = false

local function popup(amount)
	pendingGain += amount
	if popupQueued then
		return
	end
	popupQueued = true
	task.delay(0.35, function()
		popupQueued = false
		local gained = pendingGain
		pendingGain = 0
		local pop = Text({ Parent = cashChip, Text = "+" .. Config.Money(gained), Font = FONT_BLACK, Color = C.Green, Max = 20, AlignX = CENTER, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.6, 0, 1, -6), Size = UDim2.new(0.8, 0, 0, 24) })
		pop.TextStrokeTransparency = 0.4
		tween(pop, 1.1, { Position = UDim2.new(0.6, 0, 1, 22), TextTransparency = 1, TextStrokeTransparency = 1 })
		task.delay(1.15, function()
			pop:Destroy()
		end)
	end)
end

local function setCash(value)
	if lastCash == nil then
		cashDisplay.Value = value
		cashMain.Text = Config.Money(value)
	else
		local delta = value - lastCash
		if delta > 0 then
			popup(delta)
		end
		tween(cashDisplay, 0.4, { Value = value })
	end
	lastCash = value
end

local function updateHud()
	if not State then
		return
	end
	cashSub.Text = "robots +" .. Config.Money(State.RobotIncome) .. "/s"
	trophyMain.Text = Config.Format(State.Trophies)
	seasonMain.Text = "Season " .. State.Season
	seasonSub.Text = string.format("x%.1f cash", State.Multiplier)
	updateGoal(cash())
end

---------------------------------------------------------------------
-- Window
---------------------------------------------------------------------
local panels = {}
local openName = nil

local windowHost = Box({ Parent = mainGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 40, 0.5, 34), Size = UDim2.new(0, 840, 0, 560), Visible = false })
autoScale(windowHost)
local windowWrap = Box({ Parent = windowHost, Transparency = 1, Radius = false })
local windowScale = new("UIScale", { Parent = windowWrap })
Box({ Parent = windowWrap, Color = Color3.new(0, 0, 0), Transparency = 0.55, Radius = 22, Position = UDim2.new(0, 0, 0, 10), Z = 0 })
local windowBody = Box({ Parent = windowWrap, Color = C.Panel, Radius = 20, Stroke = C.Line, StrokeTransparency = 0.3, Z = 1 })

local header = Box({ Parent = windowBody, Color = Color3.new(1, 1, 1), Radius = 20, Size = UDim2.new(1, 0, 0, 76) })
local headerFill = Box({ Parent = windowBody, Color = Color3.new(1, 1, 1), Radius = false, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 46) })
local headerGradient = gradient(C.Red, C.Panel, 0)
headerGradient.Parent = header
local headerFillGradient = gradient(C.Red, C.Panel, 0)
headerFillGradient.Parent = headerFill
local headerIcon = Box({ Parent = windowBody, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 16, 0, 13), Color = C.Red, Radius = 14, Gradient = { SHADE_TOP, Color3.fromRGB(160, 160, 170), 90 }, Stroke = Color3.new(1, 1, 1), StrokeTransparency = 0.6 })
local headerIconText = Text({ Parent = headerIcon, AlignX = CENTER, Max = 26, Size = UDim2.fromScale(1, 1) })
local headerTitle = Text({ Parent = windowBody, Font = FONT_BLACK, Max = 28, Position = UDim2.new(0, 80, 0, 12), Size = UDim2.new(1, -160, 0, 30) })
local headerSub = Text({ Parent = windowBody, Font = FONT_MED, Color = Color3.fromRGB(215, 220, 240), Max = 14, Position = UDim2.new(0, 80, 0, 44), Size = UDim2.new(1, -160, 0, 18) })
local accentLine = Box({ Parent = windowBody, Color = C.Red, Radius = false, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 0, 76) })
new("UIGradient", { Parent = accentLine, Transparency = NumberSequence.new(0, 1) })
local content = Box({ Parent = windowBody, Transparency = 1, Radius = false, Position = UDim2.new(0, 20, 0, 92), Size = UDim2.new(1, -40, 1, -108) })

local closeWindow -- forward

Button({ Parent = windowBody, Text = "✕", Color = C.Red, Radius = 20, Max = 18, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 18), Size = UDim2.new(0, 40, 0, 40) }, function()
	closeWindow()
end)

local menuTiles = {}

local function updateMenuIndicators()
	for key, tile in pairs(menuTiles) do
		tile.Indicator.Visible = key == openName
	end
end

local function renderOpen()
	if not openName or not windowHost.Visible then
		return
	end
	local panel = panels[openName]
	local savedScroll = {}
	for _, d in ipairs(content:GetDescendants()) do
		if d:IsA("ScrollingFrame") then
			savedScroll[d.Name] = d.CanvasPosition
		end
	end
	content:ClearAllChildren()
	live.Cash = {}
	live.Tick = {}

	headerTitle.Text = panel.Title
	headerSub.Text = panel.Subtitle
	headerIconText.Text = panel.Icon
	headerIcon.BackgroundColor3 = panel.Color
	headerGradient.Color = ColorSequence.new(shade(panel.Color, 0.55), C.Panel)
	headerFillGradient.Color = ColorSequence.new(shade(panel.Color, 0.55), C.Panel)
	accentLine.BackgroundColor3 = panel.Color

	panel.Render(content)

	task.defer(function()
		for _, d in ipairs(content:GetDescendants()) do
			if d:IsA("ScrollingFrame") and savedScroll[d.Name] then
				d.CanvasPosition = savedScroll[d.Name]
			end
		end
	end)
end

local function openWindow(name)
	if openName == name and windowHost.Visible then
		closeWindow()
		return
	end
	local wasOpen = windowHost.Visible
	openName = name
	windowHost.Visible = true
	renderOpen()
	updateMenuIndicators()
	if not wasOpen then
		windowScale.Scale = 0.88
		tween(windowScale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

function closeWindow()
	if not windowHost.Visible then
		return
	end
	openName = nil
	live.Cash = {}
	live.Tick = {}
	updateMenuIndicators()
	local t = tween(windowScale, 0.12, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	t.Completed:Connect(function()
		if openName == nil then
			windowHost.Visible = false
			content:ClearAllChildren()
		end
	end)
end

local function emptyState(parent, icon, title, body, buttonText, onClick)
	local holder = Box({ Parent = parent, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.new(0, 460, 0, 240) })
	local circle = Box({ Parent = holder, Color = C.Panel2, Radius = 45, Size = UDim2.new(0, 90, 0, 90), Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Stroke = C.Line })
	Text({ Parent = circle, Text = icon, AlignX = CENTER, Max = 44, Size = UDim2.fromScale(1, 1) })
	Text({ Parent = holder, Text = title, Font = FONT_BLACK, Max = 22, AlignX = CENTER, Position = UDim2.new(0, 0, 0, 102), Size = UDim2.new(1, 0, 0, 28) })
	Text({ Parent = holder, Text = body, Color = C.Muted, Max = 15, AlignX = CENTER, Position = UDim2.new(0, 0, 0, 132), Size = UDim2.new(1, 0, 0, 40) })
	if buttonText then
		Button({ Parent = holder, Text = buttonText, Color = C.Blue, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 184), Size = UDim2.new(0, 200, 0, 44) }, onClick)
	end
end

---------------------------------------------------------------------
-- Robot Lab
---------------------------------------------------------------------
local labSlot = "Drivetrain"

local function StatBar(parent, style, value, y)
	local rowFrame = Box({ Parent = parent, Transparency = 1, Radius = false, Position = UDim2.new(0, 12, 0, y), Size = UDim2.new(1, -24, 0, 22) })
	Text({ Parent = rowFrame, Text = style.Icon .. " " .. style.Key, Font = FONT, Max = 13, Size = UDim2.new(0, 92, 1, 0) })
	local track = Box({ Parent = rowFrame, Color = C.Panel2, Radius = 6, Position = UDim2.new(0, 96, 0.5, 0), Anchor = Vector2.new(0, 0.5), Size = UDim2.new(1, -136, 0, 10) })
	local fill = Box({ Parent = track, Color = Color3.new(1, 1, 1), Radius = 6, Size = UDim2.new(0, 0, 1, 0), Gradient = { style.Color, shade(style.Color, 0.65), 0 } })
	tween(fill, 0.5, { Size = UDim2.new(math.clamp(value / STAT_MAX[style.Key], 0.03, 1), 0, 1, 0) })
	Text({ Parent = rowFrame, Text = tostring(value), Font = FONT_BLACK, Max = 14, AlignX = RIGHT, Position = UDim2.new(1, -36, 0, 0), Size = UDim2.new(0, 36, 1, 0), Color = style.Color })
end

panels.Lab = {
	Title = "Robot Lab",
	Subtitle = "Unlock parts, design your robot, then build it",
	Icon = "🤖",
	Color = C.Red,
	Render = function(root)
		if not State then
			return
		end
		if not State.Purchased.assembly then
			emptyState(root, "🔧", "Robot Lab is locked", "Buy the Robot Assembly Station button in your workshop to start building robots.")
			return
		end

		local left = Box({ Parent = root, Transparency = 1, Radius = false, Size = UDim2.new(1, -316, 1, 0) })
		local right = Box({ Parent = root, Color = C.Bg, Radius = 16, Stroke = C.Line, StrokeTransparency = 0.6, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 300, 1, 0) })

		-- slot tabs
		local tabs = Box({ Parent = left, Color = C.Bg, Radius = 14, Size = UDim2.new(1, 0, 0, 46) })
		for i, slot in ipairs(Config.ModuleSlots) do
			local active = slot == labSlot
			Button({
				Parent = tabs,
				Text = Config.SlotInfo[slot].Icon .. " " .. slot,
				Color = active and SLOT_COLOR[slot] or C.Panel2,
				TextColor = active and C.Text or C.Muted,
				Max = 14,
				Radius = 10,
				Position = UDim2.new((i - 1) / 4, 4, 0, 5),
				Size = UDim2.new(0.25, -8, 1, -10),
			}, function()
				labSlot = slot
				renderOpen()
			end)
		end
		Text({ Parent = left, Text = Config.SlotInfo[labSlot].Desc, Font = FONT_MED, Color = C.Muted, Max = 13, Position = UDim2.new(0, 4, 0, 52), Size = UDim2.new(1, -8, 0, 18) })

		local scroll = Scroll({ Parent = left, Name = "Modules", Position = UDim2.new(0, 0, 0, 76), Size = UDim2.new(1, 0, 1, -76) })
		local slotColor = SLOT_COLOR[labSlot]
		for index, def in ipairs(Config.Modules[labSlot]) do
			local owned = State.Modules[def.Id] == true
			local equipped = State.Loadout[labSlot] == def.Id
			local locked = (def.Season or 0) > State.Season
			local tierColor = TIER[math.min(index, #TIER)]

			local card = Box({
				Parent = scroll,
				Order = index,
				Size = UDim2.new(1, -10, 0, 80),
				Color = equipped and C.Panel2 or C.Card,
				Radius = 14,
				Stroke = equipped and slotColor or C.Line,
				StrokeTransparency = equipped and 0 or 0.65,
				StrokeThickness = equipped and 2 or 1,
			})
			Box({ Parent = card, Color = tierColor, Radius = 3, Size = UDim2.new(0, 6, 1, -20), Position = UDim2.new(0, 10, 0, 10) })
			Text({ Parent = card, Text = def.Name, Font = FONT_BLACK, Max = 17, Position = UDim2.new(0, 26, 0, 8), Size = UDim2.new(1, -190, 0, 22) })

			local pills = Box({ Parent = card, Transparency = 1, Radius = false, Position = UDim2.new(0, 26, 0, 33), Size = UDim2.new(1, -190, 0, 22) }, { hlist(5) })
			local order = 0
			for _, style in ipairs(STAT_STYLE) do
				local v = def[style.Key] or 0
				if v > 0 then
					order += 1
					Pill(pills, style.Icon .. " +" .. v, shade(style.Color, 0.35), 54, order)
				end
			end
			local extra = nil
			if def.Slot == "Intake" then
				extra = "holds " .. def.Capacity
			elseif def.Slot == "Lift" then
				extra = def.Points .. " pts / ball"
			elseif def.Slot == "Brain" then
				extra = "auton +" .. def.Auton
			elseif def.Strafe then
				extra = "🔀 STRAFE"
			end
			if extra then
				Pill(pills, extra, shade(C.Gold, 0.4), 86, 10, C.Gold)
			end
			Text({ Parent = card, Text = def.Desc or "", Font = FONT_MED, Color = C.Muted, Max = 12, Position = UDim2.new(0, 26, 0, 58), Size = UDim2.new(1, -190, 0, 15) })

			local btnProps = { Parent = card, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 146, 0, 44), Max = 14 }
			if equipped then
				btnProps.Text, btnProps.Color, btnProps.Enabled = "✓ EQUIPPED", shade(slotColor, 0.5), false
				Button(btnProps)
			elseif owned then
				btnProps.Text, btnProps.Color = "EQUIP", C.Blue
				Button(btnProps, function()
					act("EquipModule", def.Id)
				end)
			elseif locked then
				btnProps.Text, btnProps.Color, btnProps.Enabled = "🔒 SEASON " .. def.Season, C.Disabled, false
				Button(btnProps)
			else
				btnProps.Text, btnProps.Color = "UNLOCK", C.Green
				local b = Button(btnProps, function()
					act("UnlockModule", def.Id)
				end)
				onCash(function(money)
					local afford = money >= def.Cost
					setButton(b, (afford and "UNLOCK " or "💰 ") .. Config.Money(def.Cost), afford and C.Green or C.Disabled, afford)
				end)
			end
		end

		-- design summary
		local stats = Config.GetRobotStats(State.Loadout)
		local preview = RobotPreview(right, State.Loadout, UDim2.new(1, -24, 0, 176), UDim2.new(0, 12, 0, 12), C.Panel2)
		Pill(preview, "RATING " .. stats.Rating, C.Gold, 104, 0, C.Dark).Position = UDim2.new(0, 10, 0, 10)
		Text({ Parent = preview, Text = "CURRENT DESIGN", Font = FONT_BLACK, Color = C.Muted, Max = 11, AlignX = RIGHT, Position = UDim2.new(1, -130, 0, 12), Size = UDim2.new(0, 120, 0, 16) })
		for i, style in ipairs(STAT_STYLE) do
			StatBar(right, style, stats[style.Key], 198 + (i - 1) * 27)
		end
		local info = {
			string.format("🏀 Holds <b>%d</b> • <b>%d</b> pts each", stats.Capacity, stats.PointsPerBall),
			string.format("🧠 Auton <b>+%d</b> • 🔀 Strafe %s", stats.Auton, stats.Strafe and "<font color='#2EC46E'>✓</font>" or "—"),
			string.format("💵 <font color='#2EC46E'>+%s/s</font> • 🏠 Bays %d/%d", Config.Money(stats.Income * State.Multiplier), #State.Garage, State.GarageSlots),
		}
		for i, line in ipairs(info) do
			Text({ Parent = right, Text = line, Font = FONT_MED, Max = 13, Position = UDim2.new(0, 14, 0, 312 + (i - 1) * 21), Size = UDim2.new(1, -28, 0, 19) })
		end
		local full = #State.Garage >= State.GarageSlots
		local buildButton = Button({ Parent = right, Text = "BUILD", Color = C.Green, Max = 17, Radius = 12, Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(1, -24, 0, 50) }, function()
			act("BuildRobot")
		end)
		onCash(function(money)
			if full then
				setButton(buildButton, "🏠 ALL BAYS FULL", C.Disabled, false)
			else
				local afford = money >= stats.BuildCost
				setButton(buildButton, "🔧 BUILD ROBOT • " .. Config.Money(stats.BuildCost), afford and C.Green or C.Disabled, afford)
			end
		end)
	end,
}

---------------------------------------------------------------------
-- Garage
---------------------------------------------------------------------
panels.Garage = {
	Title = "Robot Garage",
	Subtitle = "Robots in bays earn cash every second • ⭐ = competition & driving robot",
	Icon = "🏠",
	Color = C.Blue,
	Render = function(root)
		if not State then
			return
		end
		if State.GarageSlots == 0 then
			emptyState(root, "🏠", "No robot bays yet", "Buy the Robot Assembly Station to get your first bay.")
			return
		end
		local scroll = Scroll({ Parent = root, Name = "Robots", Grid = UDim2.new(0, 384, 0, 160) })
		for i = 1, State.GarageSlots do
			local robot = State.Garage[i]
			if robot then
				local stats, defs = Config.GetRobotStats(robot)
				local active = State.Active == i
				local card = Box({ Parent = scroll, Order = i, Color = C.Card, Radius = 16, Stroke = active and C.Gold or C.Line, StrokeTransparency = active and 0 or 0.6, StrokeThickness = active and 2 or 1 })
				RobotPreview(card, robot, UDim2.new(0, 140, 0, 140), UDim2.new(0, 10, 0, 10), C.Panel2)
				Text({ Parent = card, Text = "Robot #" .. i, Font = FONT_BLACK, Max = 19, Position = UDim2.new(0, 162, 0, 10), Size = UDim2.new(1, -250, 0, 24) })
				if active then
					Pill(card, "⭐ ACTIVE", C.Gold, 78, 0, C.Dark).Position = UDim2.new(1, -90, 0, 12)
				end
				Text({ Parent = card, Text = string.format("Rating <b>%d</b>  •  <font color='#2EC46E'>+%s/s</font>", stats.Rating, Config.Money(stats.Income * State.Multiplier)), Font = FONT, Color = C.Gold, Max = 14, Position = UDim2.new(0, 162, 0, 36), Size = UDim2.new(1, -172, 0, 18) })
				Text({ Parent = card, Text = defs.Drivetrain.Name .. "\n" .. defs.Intake.Name .. " • " .. defs.Lift.Name .. "\n" .. defs.Brain.Name, Font = FONT_MED, Color = C.Muted, Max = 11, AlignY = Enum.TextYAlignment.Top, Position = UDim2.new(0, 162, 0, 58), Size = UDim2.new(1, -172, 0, 46) })
				Button({ Parent = card, Text = active and "ACTIVE" or "SET ACTIVE", Color = active and shade(C.Gold, 0.55) or C.Blue, Enabled = not active, Max = 13, Position = UDim2.new(0, 162, 1, -46), Size = UDim2.new(0, 104, 0, 36) }, function()
					act("SetActive", i)
				end)
				local refund = math.floor(stats.BuildCost * Config.ScrapRefund)
				Button({ Parent = card, Text = "SCRAP +" .. Config.Money(refund), Color = C.Red, Max = 12, Position = UDim2.new(0, 274, 1, -46), Size = UDim2.new(0, 100, 0, 36) }, function(b)
					if b:GetAttribute("Confirm") then
						act("ScrapRobot", i)
					else
						b:SetAttribute("Confirm", true)
						setButton(b, "SURE?", shade(C.Red, 1.2))
						task.delay(3, function()
							if b.Parent then
								b:SetAttribute("Confirm", false)
								setButton(b, "SCRAP +" .. Config.Money(refund), C.Red)
							end
						end)
					end
				end)
			else
				local card = Box({ Parent = scroll, Order = i, Color = C.Panel2, Transparency = 0.3, Radius = 16, Stroke = C.Line, StrokeTransparency = 0.4 })
				Text({ Parent = card, Text = "＋", Font = FONT_BLACK, Color = C.Line, Max = 46, AlignX = CENTER, Position = UDim2.new(0, 0, 0, 14), Size = UDim2.new(1, 0, 0, 50) })
				Text({ Parent = card, Text = "Empty Bay #" .. i, Font = FONT_BLACK, Max = 17, AlignX = CENTER, Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, 0, 0, 22) })
				Button({ Parent = card, Text = "🤖 OPEN ROBOT LAB", Color = C.Red, Max = 13, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(0, 190, 0, 38) }, function()
					openWindow("Lab")
				end)
			end
		end
	end,
}

---------------------------------------------------------------------
-- Competition results modal
---------------------------------------------------------------------
local overlay = Box({ Parent = modalGui, Color = Color3.new(0, 0, 0), Transparency = 0.45, Radius = false, Visible = false })
overlay.Active = true
local compHost = Box({ Parent = modalGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 560, 0, 440), Visible = false })
autoScale(compHost)
local compScale = new("UIScale", { Parent = Box({ Parent = compHost, Transparency = 1, Radius = false, Name = "Wrap" }) })
local compCard = Box({ Parent = compHost.Wrap, Color = C.Panel, Radius = 20, Stroke = C.Gold, StrokeThickness = 2 })
local compTitle = Text({ Parent = compCard, Font = FONT_BLACK, Max = 28, AlignX = CENTER, Position = UDim2.new(0, 20, 0, 18), Size = UDim2.new(1, -40, 0, 34) })
Text({ Parent = compCard, Text = "TOURNAMENT RESULTS", Font = FONT_BLACK, Color = C.Muted, Max = 13, AlignX = CENTER, Position = UDim2.new(0, 20, 0, 54), Size = UDim2.new(1, -40, 0, 16) })
local roundsHolder = Box({ Parent = compCard, Transparency = 1, Radius = false, Position = UDim2.new(0, 24, 0, 84), Size = UDim2.new(1, -48, 0, 236) }, { vlist(10) })
local finalBanner = Box({ Parent = compCard, Color = Color3.new(1, 1, 1), Radius = 14, Position = UDim2.new(0, 24, 0, 312), Size = UDim2.new(1, -48, 0, 50), Visible = false })
local finalGradient = gradient(C.Gold, C.Orange, 0)
finalGradient.Parent = finalBanner
local finalText = Text({ Parent = finalBanner, Font = FONT_BLACK, Max = 18, AlignX = CENTER, Color = C.Dark, Position = UDim2.new(0, 12, 0, 4), Size = UDim2.new(1, -24, 1, -8) })
local compToken = 0

local compContinue = Button({ Parent = compCard, Text = "CONTINUE", Color = C.Green, Max = 16, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(0, 200, 0, 44) }, function()
	compToken += 1
	overlay.Visible = false
	compHost.Visible = false
end)

local function showCompResult(result)
	compToken += 1
	local token = compToken
	overlay.Visible = true
	compHost.Visible = true
	compContinue.Visible = false
	finalBanner.Visible = false
	for _, child in ipairs(roundsHolder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	compTitle.Text = "🏆 " .. result.Competition
	compScale.Scale = 0.85
	tween(compScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

	task.spawn(function()
		for i, r in ipairs(result.Rounds) do
			task.wait(0.75)
			if token ~= compToken then
				return
			end
			local color = r.Won and C.Green or C.Red
			local roundCard = Box({ Parent = roundsHolder, Order = i, Color = C.Card, Radius = 14, Stroke = color, StrokeTransparency = 0.3, Size = UDim2.new(1, 0, 0, 64) })
			local s = new("UIScale", { Parent = roundCard, Scale = 0.6 })
			Text({ Parent = roundCard, Text = string.upper(r.Round), Font = FONT_BLACK, Max = 16, Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(0.4, 0, 0, 22) })
			Text({ Parent = roundCard, Text = "vs Team " .. r.OppTeam, Font = FONT_MED, Color = C.Muted, Max = 13, Position = UDim2.new(0, 16, 0, 34), Size = UDim2.new(0.4, 0, 0, 18) })
			Text({ Parent = roundCard, Text = r.You .. "  –  " .. r.Opp, Font = FONT_BLACK, Max = 28, AlignX = CENTER, Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.3, 0, 1, 0) })
			Pill(roundCard, r.Won and "WIN" or "LOSS", color, 80, 0).Position = UDim2.new(1, -96, 0.5, -11)
			tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		task.wait(0.7)
		if token ~= compToken then
			return
		end
		if result.Champion then
			finalGradient.Color = ColorSequence.new(C.Gold, C.Orange)
			finalText.Text = "🏆 CHAMPIONS!  +" .. Config.Money(result.Prize) .. "  •  +" .. result.Trophies .. " trophies"
		elseif result.Reached == 2 then
			finalGradient.Color = ColorSequence.new(Color3.fromRGB(215, 220, 235), Color3.fromRGB(150, 158, 180))
			finalText.Text = "🥈 FINALIST  +" .. Config.Money(result.Prize) .. "  •  +" .. result.Trophies .. " trophies"
		elseif result.Reached == 1 then
			finalGradient.Color = ColorSequence.new(Color3.fromRGB(230, 160, 100), Color3.fromRGB(170, 100, 60))
			finalText.Text = "🥉 SEMIFINALIST  +" .. Config.Money(result.Prize)
		else
			finalGradient.Color = ColorSequence.new(Color3.fromRGB(120, 126, 150), Color3.fromRGB(80, 86, 108))
			finalText.Text = "Knocked out early - upgrade your robot!"
		end
		finalBanner.Visible = true
		compContinue.Visible = true
		-- shimmer for champions
		if result.Champion then
			while token == compToken and finalBanner.Visible do
				finalGradient.Rotation = (finalGradient.Rotation + 4) % 360
				task.wait(0.03)
			end
		end
	end)
end

---------------------------------------------------------------------
-- Competitions
---------------------------------------------------------------------
panels.Compete = {
	Title = "Competitions",
	Subtitle = "Tournaments are decided by your active robot's rating",
	Icon = "🏆",
	Color = C.Gold,
	Render = function(root)
		if not State then
			return
		end
		local robot = State.Garage[State.Active]
		local rating = robot and Config.GetRobotStats(robot).Rating or 0

		local banner = Box({ Parent = root, Color = C.Card, Radius = 14, Stroke = C.Gold, StrokeTransparency = 0.5, Size = UDim2.new(1, 0, 0, 66) })
		if robot then
			RobotPreview(banner, robot, UDim2.new(0, 54, 0, 54), UDim2.new(0, 6, 0, 6), C.Panel2)
			Text({ Parent = banner, Text = "Competing with ⭐ Robot #" .. State.Active, Font = FONT_BLACK, Max = 17, Position = UDim2.new(0, 72, 0, 10), Size = UDim2.new(1, -220, 0, 22) })
			Text({ Parent = banner, Text = "Win all 3 rounds for the full prize + trophies", Font = FONT_MED, Color = C.Muted, Max = 13, Position = UDim2.new(0, 72, 0, 34), Size = UDim2.new(1, -220, 0, 18) })
			Pill(banner, "RATING " .. rating, C.Gold, 120, 0, C.Dark).Position = UDim2.new(1, -134, 0.5, -11)
		else
			Text({ Parent = banner, Text = "You need a robot to compete!", Font = FONT_BLACK, Color = C.Red, Max = 17, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -220, 1, 0) })
			Button({ Parent = banner, Text = "🤖 ROBOT LAB", Color = C.Red, Max = 14, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 160, 0, 42) }, function()
				openWindow("Lab")
			end)
		end

		local scroll = Scroll({ Parent = root, Name = "Comps", Position = UDim2.new(0, 0, 0, 78), Size = UDim2.new(1, 0, 1, -78) })
		for index, comp in ipairs(Config.Competitions) do
			local tierColor = TIER[math.min(index, #TIER)]
			local meets = robot ~= nil and rating >= comp.MinRating
			local card = Box({ Parent = scroll, Order = index, Size = UDim2.new(1, -10, 0, 80), Color = C.Card, Radius = 14, Stroke = C.Line, StrokeTransparency = 0.65 })
			local icon = Box({ Parent = card, Color = tierColor, Radius = 26, Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0, 14, 0.5, 0), Anchor = Vector2.new(0, 0.5), Gradient = { SHADE_TOP, Color3.fromRGB(150, 150, 160), 90 } })
			Text({ Parent = icon, Text = "🏆", AlignX = CENTER, Max = 26, Size = UDim2.fromScale(1, 1) })
			Text({ Parent = card, Text = comp.Name, Font = FONT_BLACK, Max = 18, Position = UDim2.new(0, 80, 0, 8), Size = UDim2.new(1, -250, 0, 22) })
			local pills = Box({ Parent = card, Transparency = 1, Radius = false, Position = UDim2.new(0, 80, 0, 33), Size = UDim2.new(1, -250, 0, 22) }, { hlist(6) })
			Pill(pills, (meets and "✓ " or "✕ ") .. "Rating " .. comp.MinRating .. "+", meets and shade(C.Green, 0.45) or shade(C.Red, 0.45), 104, 1)
			Pill(pills, "🎟 " .. (comp.Fee > 0 and Config.Money(comp.Fee) or "FREE"), C.Panel2, 84, 2)
			Text({ Parent = card, Text = "Champion: <b>" .. Config.Money(comp.Prize * State.Multiplier) .. "</b> + " .. comp.Trophies .. " 🏆", Font = FONT_MED, Color = C.Gold, Max = 13, Position = UDim2.new(0, 80, 0, 58), Size = UDim2.new(1, -250, 0, 16) })

			local b = Button({ Parent = card, Text = "ENTER", Color = C.Green, Max = 15, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 150, 0, 46) }, function()
				local ok, result = request(RequestRemote, "EnterCompetition", comp.Id)
				if ok and type(result) == "table" then
					cooldownEnds[comp.Id] = os.clock() + comp.Cooldown
					showCompResult(result)
				elseif type(result) == "string" then
					toast(result, "error")
				end
			end)
			local function update()
				local remaining = math.ceil((cooldownEnds[comp.Id] or 0) - os.clock())
				if not meets then
					setButton(b, "🔒 LOCKED", C.Disabled, false)
				elseif remaining > 0 then
					setButton(b, "⏳ " .. remaining .. "s", C.Disabled, false)
				elseif cash() < comp.Fee then
					setButton(b, "💰 NEED " .. Config.Money(comp.Fee), C.Disabled, false)
				else
					setButton(b, "ENTER", C.Green, true)
				end
			end
			onTick(update)
			onCash(update)
		end
	end,
}

---------------------------------------------------------------------
-- Drive
---------------------------------------------------------------------
local function arena(action)
	local ok, msg = request(ArenaRemote, action)
	if type(msg) == "string" then
		toast(msg, ok and "info" or "error")
	end
	if ok and action == "Practice" then
		closeWindow()
	end
	task.defer(renderOpen)
end

local function ModeCard(parent, x, color, icon, title, lines)
	local card = Box({ Parent = parent, Color = Color3.new(1, 1, 1), Radius = 18, Gradient = { color, shade(color, 0.4), 120 }, Position = UDim2.new(x, x > 0 and 8 or 0, 0, 0), Size = UDim2.new(0.5, -8, 0, 214) })
	Text({ Parent = card, Text = icon, Max = 44, AlignX = RIGHT, Position = UDim2.new(1, -86, 0, 12), Size = UDim2.new(0, 70, 0, 56) })
	Text({ Parent = card, Text = title, Font = FONT_BLACK, Max = 24, Position = UDim2.new(0, 18, 0, 16), Size = UDim2.new(1, -110, 0, 30) })
	for i, line in ipairs(lines) do
		Text({ Parent = card, Text = line, Font = FONT, Color = Color3.fromRGB(230, 235, 250), Max = 14, Position = UDim2.new(0, 18, 0, 52 + (i - 1) * 22), Size = UDim2.new(1, -36, 0, 20) })
	end
	return card
end

panels.Drive = {
	Title = "Drive Your Robot",
	Subtitle = "Practice for cash or battle other players in ranked 1v1",
	Icon = "🎮",
	Color = C.Green,
	Render = function(root)
		if not State then
			return
		end
		local robot = State.Garage[State.Active]
		local driving = player:GetAttribute("Driving") == true
		local inQueue = player:GetAttribute("InQueue") == true
		local queueSize = Remotes:GetAttribute("QueueSize") or 0
		local matchLive = Remotes:GetAttribute("MatchLive") == true

		if driving then
			local card = Box({ Parent = root, Color = C.Card, Radius = 18, Stroke = C.Green, Size = UDim2.new(1, 0, 0, 120) })
			Text({ Parent = card, Text = "🎮 You're driving!", Font = FONT_BLACK, Max = 24, Position = UDim2.new(0, 20, 0, 18), Size = UDim2.new(1, -240, 0, 30) })
			Text({ Parent = card, Text = "Leaving a ranked match forfeits it.", Font = FONT_MED, Color = C.Muted, Max = 14, Position = UDim2.new(0, 20, 0, 54), Size = UDim2.new(1, -240, 0, 20) })
			Button({ Parent = card, Text = "🛑 STOP DRIVING", Color = C.Red, Max = 16, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.new(0, 200, 0, 52) }, function()
				arena("Stop")
			end)
		else
			local practice = ModeCard(root, 0, C.Blue, "🎮", "PRACTICE FIELD", {
				"Free drive, no opponents",
				"Earn " .. Config.Money(Config.Practice.CashPerPoint * State.Multiplier) .. " per point scored",
				"Great for learning the controls",
			})
			Button({ Parent = practice, Text = robot and "DRIVE NOW" or "BUILD A ROBOT FIRST", Color = Color3.fromRGB(240, 244, 255), TextColor = C.Dark, Enabled = robot ~= nil, Max = 16, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(1, -36, 0, 48) }, function()
				arena("Practice")
			end)

			local ranked = ModeCard(root, 0.5, C.Red, "⚔️", "RANKED 1v1", {
				Config.Match.Duration .. "s matches • Brain gives auton points",
				"Win: +" .. Config.Match.WinTrophies .. " 🏆 and big cash",
				matchLive and "🔴 Match in progress - go watch!" or ("👥 " .. queueSize .. " player" .. (queueSize == 1 and "" or "s") .. " in queue"),
			})
			Button({
				Parent = ranked,
				Text = not robot and "BUILD A ROBOT FIRST" or (inQueue and "LEAVE QUEUE" or "JOIN QUEUE"),
				Color = inQueue and C.Dark or Color3.fromRGB(240, 244, 255),
				TextColor = inQueue and C.Text or C.Dark,
				Enabled = robot ~= nil,
				Max = 16,
				Anchor = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -16),
				Size = UDim2.new(1, -36, 0, 48),
			}, function()
				arena("Queue")
			end)
		end

		local controlsY = driving and 136 or 230
		local controls = Box({ Parent = root, Color = C.Card, Radius = 16, Stroke = C.Line, StrokeTransparency = 0.6, Position = UDim2.new(0, 0, 0, controlsY), Size = UDim2.new(1, 0, 1, -controlsY) })
		Text({ Parent = controls, Text = "CONTROLS", Font = FONT_BLACK, Color = C.Muted, Max = 13, Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -32, 0, 16) })
		local entries = {
			{ { "W", "S" }, "Drive forward / back" },
			{ { "A", "D" }, "Turn left / right" },
			{ { "Q", "E" }, "Strafe (Mecanum & X-Drive)" },
			{ { "F" }, "Score held balls in a goal zone" },
			{ { "SPC" }, "Jump - exit the robot" },
			{ { "🧲" }, "Intake grabs balls automatically" },
		}
		for i, entry in ipairs(entries) do
			local column = (i - 1) % 2
			local rowIndex = math.floor((i - 1) / 2)
			local x = column == 0 and 16 or 0
			local holder = Box({ Parent = controls, Transparency = 1, Radius = false, Position = UDim2.new(column * 0.5, x, 0, 36 + rowIndex * 40), Size = UDim2.new(0.5, -24, 0, 34) })
			for k, key in ipairs(entry[1]) do
				Keycap(holder, key, UDim2.new(0, (k - 1) * 40, 0, 2))
			end
			Text({ Parent = holder, Text = entry[2], Font = FONT, Max = 14, Position = UDim2.new(0, 88, 0, 0), Size = UDim2.new(1, -88, 1, 0) })
		end
	end,
}

---------------------------------------------------------------------
-- Season
---------------------------------------------------------------------
panels.Season = {
	Title = "New Season",
	Subtitle = "Rebirth for a permanent cash multiplier and new parts",
	Icon = "🔄",
	Color = C.Purple,
	Render = function(root)
		if not State then
			return
		end
		local cost = Config.GetSeasonCost(State.Season)
		local nowMult = Config.GetMultiplier(State.Season, false)
		local nextMult = Config.GetMultiplier(State.Season + 1, false)

		local hero = Box({ Parent = root, Color = Color3.new(1, 1, 1), Radius = 18, Gradient = { C.Purple, shade(C.Purple, 0.35), 120 }, Size = UDim2.new(1, 0, 0, 112) })
		Text({ Parent = hero, Text = "SEASON " .. State.Season .. "  ➜  " .. (State.Season + 1), Font = FONT_BLACK, Max = 34, Position = UDim2.new(0, 24, 0, 14), Size = UDim2.new(0.6, 0, 0, 44) })
		Text({ Parent = hero, Text = "Permanent cash multiplier", Font = FONT_MED, Color = Color3.fromRGB(225, 215, 250), Max = 14, Position = UDim2.new(0, 24, 0, 66), Size = UDim2.new(0.5, 0, 0, 20) })
		local multRow = Box({ Parent = hero, Transparency = 1, Radius = false, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0), Size = UDim2.new(0, 260, 0, 50) }, { hlist(10, Enum.HorizontalAlignment.Right) })
		local nowPill = Box({ Parent = multRow, Order = 1, Color = C.Dark, Transparency = 0.3, Radius = 14, Size = UDim2.new(0, 100, 0, 50) })
		Text({ Parent = nowPill, Text = string.format("x%.1f", nowMult), Font = FONT_BLACK, Max = 24, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })
		local arrow = Text({ Parent = multRow, Order = 2, Text = "➜", Font = FONT_BLACK, Max = 24, AlignX = CENTER, Size = UDim2.new(0, 30, 0, 50) })
		arrow.LayoutOrder = 2
		local nextPill = Box({ Parent = multRow, Order = 3, Color = C.Gold, Radius = 14, Size = UDim2.new(0, 100, 0, 50) })
		Text({ Parent = nextPill, Text = string.format("x%.1f", nextMult), Font = FONT_BLACK, Max = 24, AlignX = CENTER, Color = C.Dark, Size = UDim2.fromScale(1, 1) })

		local bar = Box({ Parent = root, Color = C.Bg, Radius = 14, Stroke = C.Line, StrokeTransparency = 0.5, Position = UDim2.new(0, 0, 0, 124), Size = UDim2.new(1, 0, 0, 32) })
		local fill = Box({ Parent = bar, Color = Color3.new(1, 1, 1), Radius = 14, Size = UDim2.new(0, 0, 1, 0), Gradient = { C.Green, shade(C.Green, 0.6), 0 } })
		local barText = Text({ Parent = bar, Font = FONT_BLACK, Max = 15, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })

		local nextParts = {}
		for _, slot in ipairs(Config.ModuleSlots) do
			for _, def in ipairs(Config.Modules[slot]) do
				if def.Season == State.Season + 1 then
					table.insert(nextParts, "★ " .. def.Name)
				end
			end
		end
		if #nextParts == 0 then
			table.insert(nextParts, "Bigger multiplier!")
		end
		local columns = {
			{ "RESETS", C.Red, { "✕ Cash", "✕ Workshop", "✕ Robot parts", "✕ Robots" } },
			{ "KEEPS", C.Green, { "✓ Trophies", "✓ Stats", "✓ Season bonus" } },
			{ "UNLOCKS", C.Gold, nextParts },
		}
		for i, col in ipairs(columns) do
			local box = Box({ Parent = root, Color = C.Card, Radius = 14, Stroke = col[2], StrokeTransparency = 0.6, Position = UDim2.new((i - 1) / 3, i > 1 and 6 or 0, 0, 166), Size = UDim2.new(1 / 3, -8, 0, 130) })
			Text({ Parent = box, Text = col[1], Font = FONT_BLACK, Color = col[2], Max = 13, Position = UDim2.new(0, 14, 0, 10), Size = UDim2.new(1, -28, 0, 16) })
			for k, line in ipairs(col[3]) do
				if k <= 4 then
					Text({ Parent = box, Text = line, Font = FONT, Max = 13, Position = UDim2.new(0, 14, 0, 30 + (k - 1) * 23), Size = UDim2.new(1, -28, 0, 20) })
				end
			end
		end

		local startButton = Button({ Parent = root, Text = "START", Color = C.Purple, Max = 17, Radius = 12, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 306), Size = UDim2.new(0, 380, 0, 50) }, function(b)
			if b:GetAttribute("Confirm") then
				act("Rebirth")
			else
				b:SetAttribute("Confirm", true)
				setButton(b, "⚠️ CLICK AGAIN TO CONFIRM", C.Red)
				task.delay(3, function()
					if b.Parent then
						b:SetAttribute("Confirm", false)
						setButton(b, "🔄 START SEASON " .. (State.Season + 1), C.Purple)
					end
				end)
			end
		end)
		onCash(function(money)
			local progress = math.clamp(money / cost, 0, 1)
			tween(fill, 0.3, { Size = UDim2.new(math.max(progress, 0.03), 0, 1, 0) })
			barText.Text = Config.Money(money) .. " / " .. Config.Money(cost)
			if not startButton:GetAttribute("Confirm") then
				local afford = money >= cost
				setButton(startButton, afford and ("🔄 START SEASON " .. (State.Season + 1)) or ("🔒 NEED " .. Config.Money(cost - money) .. " MORE"), afford and C.Purple or C.Disabled, afford)
			end
		end)

		local s = State.Stats
		local tiles = {
			{ s.CompWins .. "/" .. s.CompsEntered, "Tournaments won" },
			{ s.MatchesWon .. "/" .. s.MatchesPlayed, "Ranked wins" },
			{ Config.Format(s.BallsScored), "Balls scored" },
			{ tostring(s.RobotsBuilt), "Robots built" },
			{ Config.Money(s.TotalEarned), "Lifetime cash" },
		}
		local statsRow = Box({ Parent = root, Transparency = 1, Radius = false, Position = UDim2.new(0, 0, 1, -60), Size = UDim2.new(1, 0, 0, 60) }, { hlist(8, Enum.HorizontalAlignment.Center) })
		for i, tile in ipairs(tiles) do
			local t = Box({ Parent = statsRow, Order = i, Color = C.Card, Radius = 12, Size = UDim2.new(0.2, -7, 1, 0) })
			Text({ Parent = t, Text = tile[1], Font = FONT_BLACK, Max = 18, AlignX = CENTER, Position = UDim2.new(0, 6, 0, 8), Size = UDim2.new(1, -12, 0, 24) })
			Text({ Parent = t, Text = tile[2], Font = FONT_MED, Color = C.Muted, Max = 11, AlignX = CENTER, Position = UDim2.new(0, 6, 0, 34), Size = UDim2.new(1, -12, 0, 16) })
		end
	end,
}

---------------------------------------------------------------------
-- Shop
---------------------------------------------------------------------
panels.Shop = {
	Title = "Shop",
	Subtitle = "Game passes that supercharge your team",
	Icon = "🛒",
	Color = C.Orange,
	Render = function(root)
		if not State then
			return
		end
		local scroll = Scroll({ Parent = root, Name = "Passes", Grid = UDim2.new(0, 384, 0, 204) })
		for index, pass in ipairs(Config.GamePasses) do
			local owned = State.Passes[pass.Key] == true
			local card = Box({ Parent = scroll, Order = index, Color = C.Card, Radius = 18, Stroke = owned and C.Green or C.Gold, StrokeTransparency = owned and 0.2 or 0.5 })
			local icon = Box({ Parent = card, Color = owned and C.Green or C.Gold, Radius = 34, Size = UDim2.new(0, 68, 0, 68), Position = UDim2.new(0, 18, 0, 18), Gradient = { SHADE_TOP, Color3.fromRGB(150, 150, 160), 90 } })
			Text({ Parent = icon, Text = pass.Icon, AlignX = CENTER, Max = 34, Size = UDim2.fromScale(1, 1) })
			Text({ Parent = card, Text = pass.Name, Font = FONT_BLACK, Max = 21, Position = UDim2.new(0, 100, 0, 22), Size = UDim2.new(1, -116, 0, 28) })
			Text({ Parent = card, Text = pass.Desc, Font = FONT_MED, Color = C.Muted, Max = 14, AlignY = Enum.TextYAlignment.Top, Position = UDim2.new(0, 100, 0, 54), Size = UDim2.new(1, -116, 0, 50) })
			Button({ Parent = card, Text = owned and "✓ OWNED" or "BUY", Color = owned and shade(C.Green, 0.6) or C.Gold, TextColor = owned and C.Text or C.Dark, Enabled = not owned, Max = 17, Radius = 12, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(1, -36, 0, 48) }, function()
				act("PromptPass", pass.Key)
			end)
		end
	end,
}

---------------------------------------------------------------------
-- Side menu
---------------------------------------------------------------------
local MENU = {
	{ "Lab", "🤖", "Lab", C.Red },
	{ "Garage", "🏠", "Garage", C.Blue },
	{ "Compete", "🏆", "Compete", C.Gold },
	{ "Drive", "🎮", "Drive", C.Green },
	{ "Season", "🔄", "Season", C.Purple },
	{ "Shop", "🛒", "Shop", C.Orange },
}

local menuHost = Box({ Parent = mainGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 20), Size = UDim2.new(0, 90, 0, #MENU * 82) }, { vlist(10) })
autoScale(menuHost)

for i, entry in ipairs(MENU) do
	local key, icon, name, color = entry[1], entry[2], entry[3], entry[4]
	local holder = Box({ Parent = menuHost, Transparency = 1, Radius = false, Order = i, Size = UDim2.new(0, 78, 0, 72) })
	local tile = new("TextButton", { Parent = holder, AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = C.Panel, BackgroundTransparency = 0.05, Size = UDim2.fromScale(1, 1) })
	corner(18).Parent = tile
	local tileStroke = stroke(color, 2, 0.55)
	tileStroke.Parent = tile
	local iconBox = Box({ Parent = tile, Transparency = 1, Radius = false, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 0, 6) })
	local iconScale = new("UIScale", { Parent = iconBox })
	Text({ Parent = iconBox, Text = icon, AlignX = CENTER, Max = 30, Size = UDim2.fromScale(1, 1) })
	Text({ Parent = tile, Text = name, Font = FONT_BLACK, Color = color, Max = 12, AlignX = CENTER, Position = UDim2.new(0, 2, 1, -22), Size = UDim2.new(1, -4, 0, 16) })
	local indicator = Box({ Parent = holder, Color = color, Radius = 3, Size = UDim2.new(0, 5, 0, 36), Position = UDim2.new(0, -10, 0.5, 0), Anchor = Vector2.new(0, 0.5), Visible = false })
	local badge = Box({ Parent = holder, Color = C.Red, Radius = 11, Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -14, 0, -6), Stroke = C.Panel, StrokeThickness = 2, Visible = false })
	Text({ Parent = badge, Text = "!", Font = FONT_BLACK, Max = 14, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })

	tile.MouseEnter:Connect(function()
		tween(tileStroke, 0.15, { Transparency = 0 })
		tween(iconScale, 0.18, { Scale = 1.15 }, Enum.EasingStyle.Back)
		tween(tile, 0.15, { BackgroundColor3 = C.Panel2 })
	end)
	tile.MouseLeave:Connect(function()
		tween(tileStroke, 0.15, { Transparency = 0.55 })
		tween(iconScale, 0.15, { Scale = 1 })
		tween(tile, 0.15, { BackgroundColor3 = C.Panel })
	end)
	tile.Activated:Connect(function()
		iconScale.Scale = 0.85
		tween(iconScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		openWindow(key)
	end)
	menuTiles[key] = { Indicator = indicator, Badge = badge }
end

local function refreshBadges()
	if not State then
		return
	end
	local money = cash()
	local robot = State.Garage[State.Active]

	local lab = false
	if State.Purchased.assembly then
		for _, slot in ipairs(Config.ModuleSlots) do
			for _, def in ipairs(Config.Modules[slot]) do
				if not State.Modules[def.Id] and (def.Season or 0) <= State.Season and money >= def.Cost then
					lab = true
				end
			end
		end
		if #State.Garage < State.GarageSlots and money >= Config.GetRobotStats(State.Loadout).BuildCost then
			lab = true
		end
	end

	local compete = false
	if robot then
		local rating = Config.GetRobotStats(robot).Rating
		for _, comp in ipairs(Config.Competitions) do
			if rating >= comp.MinRating and money >= comp.Fee and (cooldownEnds[comp.Id] or 0) <= os.clock() then
				compete = true
			end
		end
	end

	local queueSize = Remotes:GetAttribute("QueueSize") or 0
	menuTiles.Lab.Badge.Visible = lab
	menuTiles.Compete.Badge.Visible = compete
	menuTiles.Season.Badge.Visible = money >= Config.GetSeasonCost(State.Season)
	menuTiles.Drive.Badge.Visible = robot ~= nil and queueSize > 0 and not player:GetAttribute("InQueue")
end

---------------------------------------------------------------------
-- Arena HUD
---------------------------------------------------------------------
local scoreHost = Box({ Parent = mainGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 82), Size = UDim2.new(0, 540, 0, 84), Visible = false })
autoScale(scoreHost)

local function TeamBox(x, anchorX, color)
	local box = Box({ Parent = scoreHost, Color = Color3.new(1, 1, 1), Radius = 16, Gradient = { color, shade(color, 0.45), 90 }, Stroke = Color3.new(1, 1, 1), StrokeTransparency = 0.7, Anchor = Vector2.new(anchorX, 0), Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(0, 196, 0, 78) })
	local s = new("UIScale", { Parent = box })
	local nameLabel = Text({ Parent = box, Font = FONT_BLACK, Max = 14, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(1, -16, 0, 18) })
	local scoreLabel = Text({ Parent = box, Font = FONT_BLACK, Max = 40, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 24), Size = UDim2.new(1, -16, 0, 48) })
	return box, nameLabel, scoreLabel, s
end

local redBox, redName, redScore, redScale = TeamBox(0, 0, C.Red)
local blueBox, blueName, blueScore, blueScale = TeamBox(1, 1, C.Blue)
local timerBox = Box({ Parent = scoreHost, Color = C.Panel, Radius = 16, Stroke = C.Line, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0, 124, 0, 66) })
local timerText = Text({ Parent = timerBox, Font = FONT_BLACK, Max = 30, AlignX = CENTER, Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 0, 34) })
local timerSub = Text({ Parent = timerBox, Font = FONT_BLACK, Color = C.Muted, Max = 11, AlignX = CENTER, Position = UDim2.new(0, 6, 0, 42), Size = UDim2.new(1, -12, 0, 16) })

local practiceBox = Box({ Parent = scoreHost, Color = Color3.new(1, 1, 1), Radius = 16, Gradient = { C.Blue, shade(C.Blue, 0.45), 90 }, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 280, 0, 78), Visible = false })
local practiceScale = new("UIScale", { Parent = practiceBox })
Text({ Parent = practiceBox, Text = "PRACTICE • POINTS", Font = FONT_BLACK, Max = 14, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(1, -16, 0, 18) })
local practiceScore = Text({ Parent = practiceBox, Font = FONT_BLACK, Max = 40, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 24), Size = UDim2.new(1, -16, 0, 48) })

local intakeHost = Box({ Parent = mainGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.new(0, 480, 0, 100), Visible = false })
autoScale(intakeHost)
local intakeCard = Box({ Parent = intakeHost, Color = C.Panel, Transparency = 0.05, Radius = 18, Stroke = C.Green, StrokeTransparency = 0.5 })
Text({ Parent = intakeCard, Text = "INTAKE", Font = FONT_BLACK, Color = C.Muted, Max = 12, Position = UDim2.new(0, 18, 0, 12), Size = UDim2.new(0, 70, 0, 16) })
local pipRow = Box({ Parent = intakeCard, Transparency = 1, Radius = false, Position = UDim2.new(0, 18, 0, 30), Size = UDim2.new(1, -150, 0, 30) }, { hlist(6) })
local pointsPill = Box({ Parent = intakeCard, Color = shade(C.Gold, 0.4), Radius = 12, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 26), Size = UDim2.new(0, 110, 0, 34) })
local pointsText = Text({ Parent = pointsPill, Font = FONT_BLACK, Color = C.Gold, Max = 15, AlignX = CENTER, Size = UDim2.new(1, -8, 1, -6), Position = UDim2.new(0, 4, 0, 3) })
local hintText = Text({ Parent = intakeCard, Font = FONT, Color = C.Muted, Max = 13, AlignX = CENTER, Position = UDim2.new(0, 12, 1, -30), Size = UDim2.new(1, -24, 0, 20) })

local exitHost = Box({ Parent = mainGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -22), Size = UDim2.new(0, 160, 0, 50), Visible = false })
autoScale(exitHost)
Button({ Parent = exitHost, Text = "⏏ EXIT ROBOT", Color = C.Red, Max = 15, Radius = 14, Size = UDim2.fromScale(1, 1) }, function()
	arena("Stop")
end)

local countdownHost = Box({ Parent = modalGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.new(0, 420, 0, 200), Visible = false })
autoScale(countdownHost)
local countdownText = Text({ Parent = countdownHost, Font = FONT_BLACK, Max = 140, AlignX = CENTER, Color = C.Gold, Size = UDim2.fromScale(1, 1) })
local countdownStroke = stroke(C.Dark, 4, 0)
countdownStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
countdownStroke.Parent = countdownText
local countdownScale = new("UIScale", { Parent = countdownText })

local matchHost = Box({ Parent = modalGui, Transparency = 1, Radius = false, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.new(0, 500, 0, 300), Visible = false })
autoScale(matchHost)
local matchWrap = Box({ Parent = matchHost, Transparency = 1, Radius = false })
local matchScale = new("UIScale", { Parent = matchWrap })
local matchCard = Box({ Parent = matchWrap, Color = C.Panel, Radius = 22, Stroke = C.Gold, StrokeThickness = 3 })
local matchStroke = matchCard:FindFirstChildOfClass("UIStroke")
local matchTitle = Text({ Parent = matchCard, Font = FONT_BLACK, Max = 52, AlignX = CENTER, Position = UDim2.new(0, 20, 0, 20), Size = UDim2.new(1, -40, 0, 64) })
local matchScoreRow = Box({ Parent = matchCard, Transparency = 1, Radius = false, Position = UDim2.new(0, 24, 0, 100), Size = UDim2.new(1, -48, 0, 90) })
local function ResultSide(x, color)
	local side = Box({ Parent = matchScoreRow, Color = Color3.new(1, 1, 1), Radius = 14, Gradient = { color, shade(color, 0.45), 90 }, Position = UDim2.new(x, x > 0 and 8 or 0, 0, 0), Size = UDim2.new(0.5, -8, 1, 0) })
	local n = Text({ Parent = side, Font = FONT_BLACK, Max = 14, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 0, 18) })
	local sc = Text({ Parent = side, Font = FONT_BLACK, Max = 40, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 28), Size = UDim2.new(1, -16, 0, 54) })
	return n, sc
end
local resultRedName, resultRedScore = ResultSide(0, C.Red)
local resultBlueName, resultBlueScore = ResultSide(0.5, C.Blue)
Text({ Parent = matchCard, Text = "Rewards were added to your wallet", Font = FONT_MED, Color = C.Muted, Max = 13, AlignX = CENTER, Position = UDim2.new(0, 20, 0, 198), Size = UDim2.new(1, -40, 0, 18) })
Button({ Parent = matchCard, Text = "CONTINUE", Color = C.Green, Max = 16, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(0, 200, 0, 46) }, function()
	matchHost.Visible = false
	overlay.Visible = false
end)

local lastCountdown = nil
local lastMatchState = nil
local lastScores = { Red = 0, Blue = 0, Practice = 0 }
local lastHeld = 0

local function pulse(scaleObj)
	scaleObj.Scale = 1.18
	tween(scaleObj, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

local function showCountdown(text, color)
	countdownHost.Visible = true
	countdownText.Text = text
	countdownText.TextColor3 = color
	countdownText.TextTransparency = 0
	countdownScale.Scale = 1.8
	tween(countdownScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
end

local function buildPips(held, capacity)
	for _, child in ipairs(pipRow:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i = 1, capacity do
		local filled = i <= held
		local pip = Box({ Parent = pipRow, Order = i, Color = filled and C.Green or C.Bg, Radius = 14, Size = UDim2.new(0, 28, 0, 28), Stroke = filled and Color3.fromRGB(160, 255, 190) or C.Line, StrokeTransparency = filled and 0.3 or 0 })
		if filled then
			gradient(SHADE_TOP, Color3.fromRGB(150, 160, 150), 90).Parent = pip
			if i == held and held > lastHeld then
				local s = new("UIScale", { Parent = pip, Scale = 1.5 })
				tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
	end
end

local function renderArena()
	local mode = Arena.Mode
	local driving = mode == "Practice" or mode == "Ranked"
	intakeHost.Visible = driving
	exitHost.Visible = driving
	scoreHost.Visible = driving
	menuHost.Visible = not driving
	goalBar.Visible = not driving
	if driving then
		closeWindow()
		local held, capacity = Arena.Held or 0, Arena.Capacity or 1
		buildPips(held, capacity)
		lastHeld = held
		pointsText.Text = "×" .. (Arena.PointsPerBall or 1) .. " PTS"
		intakeCard.UIStroke.Color = held >= capacity and C.Gold or C.Green
	end

	if mode == "Practice" then
		practiceBox.Visible = true
		redBox.Visible, blueBox.Visible, timerBox.Visible = false, false, false
		local points = Arena.Points or 0
		practiceScore.Text = tostring(points)
		if points > lastScores.Practice then
			pulse(practiceScale)
		end
		lastScores.Practice = points
		hintText.Text = "WASD drive" .. (Arena.Strafe and " • Q/E strafe" or "") .. " • F score in any goal • Space exit"
		countdownHost.Visible = false
	elseif mode == "Ranked" and Arena.Match then
		local m = Arena.Match
		practiceBox.Visible = false
		redBox.Visible, blueBox.Visible, timerBox.Visible = true, true, true
		redName.Text = (m.Side == "Red" and "⭐ " or "") .. string.upper(m.RedName)
		blueName.Text = (m.Side == "Blue" and "⭐ " or "") .. string.upper(m.BlueName)
		redScore.Text = tostring(m.Red)
		blueScore.Text = tostring(m.Blue)
		if m.Red > lastScores.Red then
			pulse(redScale)
		end
		if m.Blue > lastScores.Blue then
			pulse(blueScale)
		end
		lastScores.Red, lastScores.Blue = m.Red, m.Blue
		hintText.Text = "Score in the " .. string.upper(m.Side or "?") .. " goal • F to score • Jumping out forfeits!"
		if m.State == "Countdown" then
			timerText.Text = "0:" .. string.format("%02d", m.Countdown or 0)
			timerSub.Text = "GET READY"
			if m.Countdown ~= lastCountdown then
				showCountdown(tostring(m.Countdown or ""), C.Gold)
			end
			lastCountdown = m.Countdown
		else
			timerText.Text = string.format("%d:%02d", math.floor((m.Time or 0) / 60), (m.Time or 0) % 60)
			timerSub.Text = "LIVE"
			timerText.TextColor3 = (m.Time or 0) <= 10 and C.Red or C.Text
			if lastMatchState == "Countdown" then
				showCountdown("GO!", C.Green)
				task.delay(0.7, function()
					tween(countdownText, 0.3, { TextTransparency = 1 })
					task.wait(0.3)
					if Arena.Match and Arena.Match.State == "Live" then
						countdownHost.Visible = false
					end
				end)
			end
		end
		lastMatchState = m.State
	else
		countdownHost.Visible = false
		lastMatchState, lastCountdown = nil, nil
		lastScores = { Red = 0, Blue = 0, Practice = 0 }
	end

	if mode == "Result" then
		local titles = { Win = "🏆 VICTORY!", Loss = "DEFEAT", Tie = "TIE GAME", Forfeit = "FORFEIT" }
		local colors = { Win = C.Gold, Loss = C.Red, Tie = C.Blue, Forfeit = C.Red }
		local color = colors[Arena.Result] or C.Gold
		matchTitle.Text = titles[Arena.Result] or "MATCH OVER"
		matchTitle.TextColor3 = color
		matchStroke.Color = color
		resultRedName.Text = string.upper(Arena.RedName or "RED")
		resultBlueName.Text = string.upper(Arena.BlueName or "BLUE")
		resultRedScore.Text = tostring(Arena.Red or 0)
		resultBlueScore.Text = tostring(Arena.Blue or 0)
		overlay.Visible = true
		matchHost.Visible = true
		matchScale.Scale = 0.8
		tween(matchScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		Arena = { Mode = "None" }
	end
end

ArenaState.OnClientEvent:Connect(function(info)
	Arena = info or { Mode = "None" }
	renderArena()
end)

---------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------
DataUpdate.OnClientEvent:Connect(function(snapshot)
	State = snapshot
	for compId, remaining in pairs(snapshot.Cooldowns or {}) do
		cooldownEnds[compId] = os.clock() + remaining
	end
	updateHud()
	refreshBadges()
	renderOpen()
end)

OpenUIRemote.OnClientEvent:Connect(function(name)
	if panels[name] and Arena.Mode ~= "Practice" and Arena.Mode ~= "Ranked" and openName ~= name then
		openWindow(name)
	end
end)

task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	local cashValue = stats:WaitForChild("Cash")
	setCash(cashValue.Value)
	cashValue.Changed:Connect(function(value)
		setCash(value)
		for _, fn in ipairs(live.Cash) do
			fn(value)
		end
		if State then
			updateGoal(value)
		end
	end)
end)

player:GetAttributeChangedSignal("InQueue"):Connect(function()
	refreshBadges()
	if openName == "Drive" then
		renderOpen()
	end
end)
player:GetAttributeChangedSignal("Driving"):Connect(function()
	if openName == "Drive" then
		renderOpen()
	end
end)
Remotes:GetAttributeChangedSignal("QueueSize"):Connect(function()
	refreshBadges()
	if openName == "Drive" then
		renderOpen()
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		for _, fn in ipairs(live.Tick) do
			fn()
		end
		refreshBadges()
	end
end)

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		updateScale()
	end
end)
updateScale()

-- initial data
task.spawn(function()
	for _ = 1, 20 do
		local ok, snapshot = pcall(RequestRemote.InvokeServer, RequestRemote, "GetData")
		if ok and type(snapshot) == "table" then
			if not State then
				State = snapshot
				updateHud()
				refreshBadges()
			end
			return
		end
		task.wait(1)
	end
end)

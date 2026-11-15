--[[
	MainUI (LocalScript)  ->  StarterPlayer.StarterPlayerScripts.MainUI

	Bright simulator-style interface, built in code:
	  * Big cash counter, trophies, season, next-goal bar
	  * Chunky colored menu buttons with alert badges
	  * Seeds (shop + restock timer), Backpack (crops), Base (market robots + lock),
	    Robot Lab, Garage, Competitions, Drive, Season, Shop
	  * Pop-in notifications, match HUD, countdown, results
	Everything scales to fit phones, tablets and desktops.
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
local SimRemote = Remotes:WaitForChild("SimRequest")
local DataUpdate = Remotes:WaitForChild("DataUpdate")
local NotifyRemote = Remotes:WaitForChild("Notify")
local OpenUIRemote = Remotes:WaitForChild("OpenUI")
local ArenaState = Remotes:WaitForChild("ArenaState")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local State = nil
local Arena = { Mode = "None" }
local cooldownEnds = {}

---------------------------------------------------------------------
-- Style
---------------------------------------------------------------------
local C = {
	Panel = Color3.fromRGB(52, 122, 222),
	PanelDark = Color3.fromRGB(34, 86, 176),
	Row = Color3.fromRGB(84, 152, 242),
	RowEdge = Color3.fromRGB(36, 92, 182),
	Outline = Color3.fromRGB(18, 28, 64),
	Text = Color3.fromRGB(255, 255, 255),
	Sub = Color3.fromRGB(215, 232, 255),
	Cash = Color3.fromRGB(130, 255, 90),
	Green = Color3.fromRGB(80, 205, 60),
	Yellow = Color3.fromRGB(255, 196, 36),
	Red = Color3.fromRGB(240, 70, 70),
	Blue = Color3.fromRGB(60, 150, 255),
	Purple = Color3.fromRGB(160, 92, 240),
	Orange = Color3.fromRGB(255, 140, 40),
	Disabled = Color3.fromRGB(125, 135, 155),
	TeamRed = Color3.fromRGB(235, 60, 60),
	TeamBlue = Color3.fromRGB(50, 130, 255),
}

local FREDOKA = Font.fromEnum(Enum.Font.FredokaOne)
local GOTHAM = Font.fromEnum(Enum.Font.GothamBold)

local TYPE = {
	Huge = { FREDOKA, 44 },
	Title = { FREDOKA, 32 },
	Heading = { FREDOKA, 22 },
	Name = { FREDOKA, 18 },
	Button = { FREDOKA, 17 },
	Body = { GOTHAM, 15 },
	Small = { GOTHAM, 13 },
}

local LEFT, CENTER, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local BOUNCE = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local STATS = { "Speed", "Power", "Control", "Scoring" }
local STAT_COLOR = { Speed = Color3.fromRGB(80, 230, 255), Power = Color3.fromRGB(255, 100, 90), Control = Color3.fromRGB(190, 130, 255), Scoring = Color3.fromRGB(255, 210, 60) }
local STAT_MAX = {}
for _, key in ipairs(STATS) do
	local total = 0
	for _, slot in ipairs(Config.ModuleSlots) do
		local best = 0
		for _, def in ipairs(Config.Modules[slot]) do
			best = math.max(best, def[key] or 0)
		end
		total += best
	end
	STAT_MAX[key] = math.max(total, 1)
end

local function rarityColor(rarity)
	local r = Config.Rarities[rarity]
	return r and r.Color or C.Text
end

local function hex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

---------------------------------------------------------------------
-- Toolkit
---------------------------------------------------------------------
local function tween(obj, props, info)
	local t = TweenService:Create(obj, info or QUICK, props)
	t:Play()
	return t
end

local function shade(color, f)
	return Color3.new(math.clamp(color.R * f, 0, 1), math.clamp(color.G * f, 0, 1), math.clamp(color.B * f, 0, 1))
end

local function new(className, props)
	local inst = Instance.new(className)
	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(inst, radius)
	new("UICorner", { Parent = inst, CornerRadius = radius == "round" and UDim.new(1, 0) or UDim.new(0, radius or 12) })
end

local function outline(inst, thickness, color)
	return new("UIStroke", { Parent = inst, Color = color or C.Outline, Thickness = thickness or 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function Frame(p)
	local f = new("Frame", {
		Name = p.Name or "Frame",
		BorderSizePixel = 0,
		BackgroundColor3 = p.Color or C.Row,
		BackgroundTransparency = p.Transparency or (p.Color and 0 or 1),
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
		AutomaticSize = p.AutoSize or Enum.AutomaticSize.None,
		Parent = p.Parent,
	})
	if p.Radius then
		corner(f, p.Radius)
	end
	if p.Outline then
		outline(f, p.Outline ~= true and p.Outline or 3, p.OutlineColor)
	end
	if p.Shine then
		new("UIGradient", { Parent = f, Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 210)) })
	end
	return f
end

local function Text(p)
	local style = TYPE[p.Style or "Body"]
	local size = p.TextSize or style[2]
	local label = new("TextLabel", {
		Name = p.Name or "Text",
		BackgroundTransparency = 1,
		FontFace = p.Font or style[1],
		TextSize = size,
		TextColor3 = p.Color or C.Text,
		Text = p.Text or "",
		RichText = true,
		TextWrapped = p.Wrap ~= false,
		TextTruncate = p.Wrap == false and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		TextXAlignment = p.AlignX or LEFT,
		TextYAlignment = p.AlignY or Enum.TextYAlignment.Center,
		Size = p.Size or UDim2.new(1, 0, 0, size + 8),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
		Parent = p.Parent,
	})
	if p.Stroke ~= false then
		new("UIStroke", {
			Parent = label,
			Color = C.Outline,
			Thickness = p.StrokeThickness or (size >= 30 and 3 or (size >= 17 and 2 or 1.4)),
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		})
	end
	return label
end

local KIND = {
	green = C.Green,
	yellow = C.Yellow,
	red = C.Red,
	blue = C.Blue,
	purple = C.Purple,
	orange = C.Orange,
	disabled = C.Disabled,
}

local function applyKind(b, kind)
	b.BackgroundColor3 = KIND[kind] or C.Blue
	b:SetAttribute("Kind", kind)
	b:SetAttribute("Enabled", kind ~= "disabled")
end

local function Button(p, onClick)
	local b = new("TextButton", {
		Name = p.Name or "Button",
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Size = p.Size or UDim2.new(0, 120, 0, 40),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
		Parent = p.Parent,
	})
	corner(b, p.Radius or 12)
	outline(b, 3)
	new("UIGradient", { Parent = b, Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(185, 185, 195)) })
	local scale = new("UIScale", { Parent = b })
	Text({ Parent = b, Name = "Label", Text = p.Text or "", Style = "Button", TextSize = p.TextSize, AlignX = CENTER, Wrap = false, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0) })
	applyKind(b, p.Kind or "blue")
	b.MouseEnter:Connect(function()
		if b:GetAttribute("Enabled") then
			tween(scale, { Scale = 1.05 })
		end
	end)
	b.MouseLeave:Connect(function()
		tween(scale, { Scale = 1 })
	end)
	b.MouseButton1Down:Connect(function()
		if b:GetAttribute("Enabled") then
			tween(scale, { Scale = 0.92 }, TweenInfo.new(0.05))
		end
	end)
	b.MouseButton1Up:Connect(function()
		tween(scale, { Scale = 1 }, BOUNCE)
	end)
	b.Activated:Connect(function()
		if b:GetAttribute("Enabled") and onClick then
			onClick(b)
		end
	end)
	return b
end

local function setButton(b, text, kind)
	if text then
		b.Label.Text = text
	end
	if kind then
		applyKind(b, kind)
	end
end

local function Scroll(p)
	local s = new("ScrollingFrame", {
		Name = p.Name or "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Outline,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		Parent = p.Parent,
	})
	if p.Grid then
		new("UIGridLayout", { Parent = s, CellSize = p.Grid, CellPadding = UDim2.new(0, 12, 0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
	else
		new("UIListLayout", { Parent = s, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	end
	new("UIPadding", { Parent = s, PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 8) })
	return s
end

-- a vertical stack of cards
local function Group(parent, props)
	props = props or {}
	local g = Frame({ Parent = parent, Name = "Group", Size = props.Size or UDim2.new(1, 0, 0, 0), Position = props.Position, AutoSize = Enum.AutomaticSize.Y, Order = props.Order })
	new("UIListLayout", { Parent = g, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	g:SetAttribute("Rows", 0)
	return g
end

local function Row(group, height)
	local index = group:GetAttribute("Rows") + 1
	group:SetAttribute("Rows", index)
	return Frame({ Parent = group, Name = "Row" .. index, Color = C.Row, Radius = 12, Outline = 2, OutlineColor = C.RowEdge, Size = UDim2.new(1, 0, 0, height), Order = index })
end

local function Bar(parent, position, size, fraction, color)
	local track = Frame({ Parent = parent, Color = C.Outline, Transparency = 0.35, Radius = "round", Position = position, Size = size })
	local fill = Frame({ Parent = track, Color = color or C.Green, Radius = "round", Shine = true, Size = UDim2.new(0, 0, 1, 0) })
	tween(fill, { Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0) }, TweenInfo.new(0.4))
	return track, fill
end

local function Swatch(parent, color, position, size)
	local s = Frame({ Parent = parent, Color = color, Radius = "round", Outline = 2.5, Shine = true, Position = position, Size = size or UDim2.new(0, 40, 0, 40) })
	return s
end

local function Keycap(parent, key, position, width)
	local cap = Frame({ Parent = parent, Color = C.Text, Radius = 8, Outline = 2, Shine = true, Position = position, Size = UDim2.new(0, width or 30, 0, 28) })
	Text({ Parent = cap, Text = key, Style = "Button", TextSize = 14, Color = C.Outline, Stroke = false, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })
	return cap
end

local function serverNow()
	return workspace:GetServerTimeNow()
end

local function clockText(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

---------------------------------------------------------------------
-- Screens + scaling
---------------------------------------------------------------------
local mainGui = new("ScreenGui", { Name = "VexUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1, Parent = playerGui })
local modalGui = new("ScreenGui", { Name = "VexModal", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10, Parent = playerGui })

local scalers = {}
local uiScale = 1
local function autoScale(guiObject)
	table.insert(scalers, new("UIScale", { Parent = guiObject, Scale = uiScale }))
end
local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local vp = camera.ViewportSize
	uiScale = math.clamp(math.min(vp.X / 1400, vp.Y / 820), 0.5, 1.15)
	for _, s in ipairs(scalers) do
		s.Scale = uiScale
	end
end

---------------------------------------------------------------------
-- 3D robot previews
---------------------------------------------------------------------
local previews = {}
local previewAngle = 0.6

local function RobotPreview(parent, loadout, size, position, tint)
	local vp = new("ViewportFrame", {
		BackgroundColor3 = C.PanelDark,
		BorderSizePixel = 0,
		Size = size,
		Position = position or UDim2.new(),
		Ambient = Color3.fromRGB(170, 170, 180),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.5, -1, -0.6),
		Parent = parent,
	})
	corner(vp, 12)
	local camera = new("Camera", { FieldOfView = 32, CFrame = CFrame.lookAt(Vector3.new(11, 7, -15), Vector3.new(0, 1, 0)), Parent = vp })
	vp.CurrentCamera = camera
	local ok, model = pcall(RobotBuilder.Build, loadout, { NoNameplate = true, Tint = tint })
	if ok and model then
		model:PivotTo(CFrame.Angles(0, previewAngle, 0))
		model.Parent = vp
		table.insert(previews, model)
	end
	return vp
end

RunService.RenderStepped:Connect(function(dt)
	previewAngle = (previewAngle + dt * 0.8) % (math.pi * 2)
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
-- Helpers
---------------------------------------------------------------------
local function cash()
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Cash")
	return value and value.Value or (State and State.Cash or 0)
end

local live = { Cash = {}, Tick = {} }
local function onCash(fn)
	table.insert(live.Cash, fn)
	fn(cash())
end
local function onTick(fn)
	table.insert(live.Tick, fn)
	fn()
end

local function isDriving()
	return Arena.Mode == "Practice" or Arena.Mode == "Ranked"
end

---------------------------------------------------------------------
-- Notifications
---------------------------------------------------------------------
local toastHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.new(0, 520, 0, 220) })
new("UIListLayout", { Parent = toastHost, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
autoScale(toastHost)

local TOAST_KIND = { success = C.Green, error = C.Red, cash = C.Yellow, info = C.Blue }
local toastCount = 0

local function toast(text, kind)
	if type(text) ~= "string" or text == "" then
		return
	end
	toastCount += 1
	local holder = Frame({ Parent = toastHost, Order = toastCount, Size = UDim2.new(1, 0, 0, 46) })
	local card = Frame({ Parent = holder, Color = TOAST_KIND[kind] or C.Blue, Radius = 14, Outline = 3, Shine = true, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 0, 1, 0), AutoSize = Enum.AutomaticSize.X })
	new("UIPadding", { Parent = card, PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) })
	local label = Text({ Parent = card, Text = text, Style = "Name", Wrap = false, AlignX = CENTER, Size = UDim2.new(0, 0, 1, 0) })
	label.AutomaticSize = Enum.AutomaticSize.X
	local scale = new("UIScale", { Parent = card, Scale = 0.6 })
	tween(scale, { Scale = 1 }, BOUNCE)

	local holders = {}
	for _, child in ipairs(toastHost:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(holders, child)
		end
	end
	if #holders > 3 then
		table.sort(holders, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		holders[1]:Destroy()
	end
	task.delay(3, function()
		if holder.Parent then
			tween(scale, { Scale = 0 }, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In))
			task.wait(0.22)
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
		return false, "Connection problem, try again!"
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

local function sim(action, ...)
	local ok, msg = request(SimRemote, action, ...)
	if type(msg) == "string" then
		toast(msg, ok and "success" or "error")
	end
	return ok, msg
end

---------------------------------------------------------------------
-- HUD (top center)
---------------------------------------------------------------------
local hudHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0, 460, 0, 140) })
autoScale(hudHost)
local cashText = Text({ Parent = hudHost, Style = "Huge", Color = C.Cash, AlignX = CENTER, Wrap = false, Size = UDim2.new(1, 0, 0, 48) })
local incomeText = Text({ Parent = hudHost, Style = "Name", AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 22) })

local chipRow = Frame({ Parent = hudHost, Position = UDim2.new(0, 0, 0, 70), Size = UDim2.new(1, 0, 0, 30) })
new("UIListLayout", { Parent = chipRow, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
local function Chip(order, color)
	local chip = Frame({ Parent = chipRow, Order = order, Color = color, Radius = "round", Outline = 2.5, Shine = true, Size = UDim2.new(0, 150, 1, 0) })
	return Text({ Parent = chip, Style = "Button", TextSize = 16, AlignX = CENTER, Wrap = false, Size = UDim2.fromScale(1, 1) })
end
local trophyText = Chip(1, C.Yellow)
local seasonText = Chip(2, C.Purple)

local goalBar = Frame({ Parent = hudHost, Color = C.Outline, Transparency = 0.25, Radius = "round", Outline = 2.5, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 108), Size = UDim2.new(0, 380, 0, 26) })
local goalFill = Frame({ Parent = goalBar, Color = C.Green, Radius = "round", Shine = true, Size = UDim2.new(0, 0, 1, 0) })
local goalText = Text({ Parent = goalBar, Style = "Button", TextSize = 14, AlignX = CENTER, Wrap = false, Size = UDim2.fromScale(1, 1) })

local cashDisplay = new("NumberValue", { Value = 0 })
cashDisplay.Changed:Connect(function(v)
	cashText.Text = Config.Money(v)
end)
local cashScale = new("UIScale", { Parent = cashText })

local lastCash = nil
local function setCash(value)
	if lastCash == nil then
		cashDisplay.Value = value
		cashText.Text = Config.Money(value)
	else
		if value > lastCash then
			cashScale.Scale = 1.12
			tween(cashScale, { Scale = 1 }, BOUNCE)
		end
		tween(cashDisplay, { Value = value }, TweenInfo.new(0.35))
	end
	lastCash = value
end

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
	return "Season " .. (State.Season + 1), Config.GetSeasonCost(State.Season)
end

local function updateGoal(money)
	local name, cost = nextGoal()
	goalBar.Visible = name ~= nil and not isDriving()
	if not name then
		return
	end
	local fraction = cost > 0 and math.clamp(money / cost, 0, 1) or 1
	goalText.Text = fraction >= 1 and ("NEXT: " .. name .. "  -  READY!") or ("NEXT: " .. name .. "  " .. Config.Money(money) .. " / " .. Config.Money(cost))
	tween(goalFill, { Size = UDim2.new(math.max(fraction, 0.05), 0, 1, 0) })
end

local function updateHud()
	if not State then
		return
	end
	incomeText.Text = "+" .. Config.Money(State.RobotIncome) .. "/s from robots"
	trophyText.Text = Config.Format(State.Trophies) .. " TROPHIES"
	seasonText.Text = "SEASON " .. State.Season .. "  x" .. string.format("%.1f", State.Multiplier)
	updateGoal(cash())
end

---------------------------------------------------------------------
-- Window
---------------------------------------------------------------------
local panels = {}
local openName = nil

local windowHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 50, 0.5, 40), Size = UDim2.new(0, 860, 0, 580), Visible = false })
autoScale(windowHost)
local windowWrap = Frame({ Parent = windowHost })
local windowScale = new("UIScale", { Parent = windowWrap })
local window = Frame({ Parent = windowWrap, Color = C.Panel, Radius = 22, Outline = 4 })
Frame({ Parent = window, Color = C.PanelDark, Radius = 22, Size = UDim2.new(1, 0, 0, 72) })
Frame({ Parent = window, Color = C.PanelDark, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 32) })
Frame({ Parent = window, Color = C.Outline, Position = UDim2.new(0, 0, 0, 72), Size = UDim2.new(1, 0, 0, 3) })
local windowTitle = Text({ Parent = window, Style = "Title", Wrap = false, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -120, 0, 72) })
local windowHint = Text({ Parent = window, Style = "Small", Color = C.Sub, Wrap = false, AlignX = RIGHT, Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, -84, 0, 72) })
local body = Frame({ Parent = window, Position = UDim2.new(0, 22, 0, 88), Size = UDim2.new(1, -44, 1, -104) })

local closeWindow -- forward
Button({ Parent = window, Text = "X", Kind = "red", TextSize = 22, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.new(0, 46, 0, 44) }, function()
	closeWindow()
end)

local menuItems = {}

local function updateMenu()
	for key, item in pairs(menuItems) do
		item.Stroke.Color = key == openName and C.Text or C.Outline
	end
end

local function renderOpen()
	if not openName or not windowHost.Visible then
		return
	end
	local panel = panels[openName]
	local saved = {}
	for _, d in ipairs(body:GetDescendants()) do
		if d:IsA("ScrollingFrame") then
			saved[d.Name] = d.CanvasPosition
		end
	end
	body:ClearAllChildren()
	live.Cash, live.Tick = {}, {}
	windowTitle.Text = panel.Title
	windowHint.Text = panel.Hint or ""
	panel.Render(body)
	task.defer(function()
		for _, d in ipairs(body:GetDescendants()) do
			if d:IsA("ScrollingFrame") and saved[d.Name] then
				d.CanvasPosition = saved[d.Name]
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
	updateMenu()
	if not wasOpen then
		windowScale.Scale = 0.7
		tween(windowScale, { Scale = 1 }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
	end
end

function closeWindow()
	if not windowHost.Visible then
		return
	end
	openName = nil
	live.Cash, live.Tick = {}, {}
	updateMenu()
	windowHost.Visible = false
	body:ClearAllChildren()
end

local function emptyState(parent, title, message, buttonText, onClick)
	local holder = Frame({ Parent = parent, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.new(0, 460, 0, 160) })
	Text({ Parent = holder, Text = title, Style = "Heading", TextSize = 28, AlignX = CENTER, Size = UDim2.new(1, 0, 0, 36) })
	Text({ Parent = holder, Text = message, Style = "Body", Color = C.Sub, AlignX = CENTER, AlignY = Enum.TextYAlignment.Top, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 48) })
	if buttonText then
		Button({ Parent = holder, Text = buttonText, Kind = "green", Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.new(0, 200, 0, 46) }, onClick)
	end
end

---------------------------------------------------------------------
-- Seeds
---------------------------------------------------------------------
local function ownedSeeds()
	local n = 0
	for _, count in pairs(State.Seeds or {}) do
		n += count
	end
	return n
end

panels.Seeds = {
	Title = "SEED SHOP",
	Hint = "Plant seeds in the beds at your workshop",
	Render = function(root)
		if not State then
			return
		end
		local top = Frame({ Parent = root, Color = C.PanelDark, Radius = 12, Outline = 2, OutlineColor = C.RowEdge, Size = UDim2.new(1, 0, 0, 48) })
		local restock = Text({ Parent = top, Style = "Name", Wrap = false, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0.5, 0, 1, 0) })
		onTick(function()
			local at = Remotes:GetAttribute("RestockAt") or 0
			restock.Text = "RESTOCK IN " .. clockText(at - serverNow())
		end)
		local selected = State.SelectedSeed and Config.SeedById[State.SelectedSeed]
		Text({ Parent = top, Text = selected and ("PLANTING: " .. selected.Name) or ("YOU HAVE " .. ownedSeeds() .. " SEEDS"), Style = "Name", Color = C.Yellow, Wrap = false, AlignX = RIGHT, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -16, 1, 0) })

		local scroll = Scroll({ Parent = root, Name = "SeedList", Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 1, -58) })
		local group = Group(scroll)
		for _, seed in ipairs(Config.Seeds) do
			local stock = State.Stock[seed.Id] or 0
			local owned = State.Seeds[seed.Id] or 0
			local r = Row(group, 74)
			Swatch(r, seed.Color, UDim2.new(0, 14, 0.5, -22), UDim2.new(0, 44, 0, 44))
			Text({ Parent = r, Text = seed.Name, Style = "Name", TextSize = 20, Color = rarityColor(seed.Rarity), Wrap = false, Position = UDim2.new(0, 70, 0, 8), Size = UDim2.new(0.42, 0, 0, 26) })
			Text({ Parent = r, Text = string.upper(seed.Rarity) .. "  -  Grows in " .. clockText(seed.GrowTime) .. "  -  Sells " .. Config.Money(seed.Value), Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 70, 0, 36), Size = UDim2.new(0.5, 0, 0, 16) })
			Text({ Parent = r, Text = (stock > 0 and ("x" .. stock .. " in stock") or '<font color="#FF7070">SOLD OUT</font>') .. (owned > 0 and ("   -   You have " .. owned) or ""), Style = "Small", Wrap = false, Position = UDim2.new(0, 70, 0, 52), Size = UDim2.new(0.5, 0, 0, 16) })

			local buy = Button({ Parent = r, Text = "BUY", Kind = "green", Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -122, 0.5, 0), Size = UDim2.new(0, 124, 0, 44) }, function()
				sim("BuySeed", seed.Id)
			end)
			onCash(function(money)
				if stock <= 0 then
					setButton(buy, "SOLD OUT", "disabled")
				else
					setButton(buy, Config.Money(seed.Price), money >= seed.Price and "green" or "disabled")
				end
			end)
			if owned > 0 then
				local isSelected = State.SelectedSeed == seed.Id
				Button({ Parent = r, Text = isSelected and "PICKED" or "PICK", Kind = isSelected and "disabled" or "yellow", Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 100, 0, 44) }, function()
					sim("SelectSeed", seed.Id)
				end)
			end
		end
	end,
}

---------------------------------------------------------------------
-- Backpack
---------------------------------------------------------------------
panels.Bag = {
	Title = "BACKPACK",
	Hint = "Sell your crops at the Sell Stand in the hub",
	Render = function(root)
		if not State then
			return
		end
		local items = State.Backpack or {}
		local total = 0
		local groups, order = {}, {}
		for _, item in ipairs(items) do
			total += item.V or 0
			local key = item.S .. "|" .. (item.M or "")
			if not groups[key] then
				groups[key] = { S = item.S, M = item.M, Count = 0, Value = 0 }
				table.insert(order, key)
			end
			groups[key].Count += 1
			groups[key].Value += item.V or 0
		end

		local top = Frame({ Parent = root, Color = C.PanelDark, Radius = 12, Outline = 2, OutlineColor = C.RowEdge, Size = UDim2.new(1, 0, 0, 70) })
		Text({ Parent = top, Text = #items .. " / " .. Config.Garden.MaxBackpack .. " CROPS", Style = "Heading", Wrap = false, Position = UDim2.new(0, 18, 0, 6), Size = UDim2.new(0.5, 0, 0, 32) })
		Text({ Parent = top, Text = "Worth " .. Config.Money(total * State.Multiplier), Style = "Name", Color = C.Cash, Wrap = false, Position = UDim2.new(0, 18, 0, 38), Size = UDim2.new(0.5, 0, 0, 24) })
		Button({ Parent = top, Text = "SELL ALL", Kind = #items > 0 and "yellow" or "disabled", TextSize = 20, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 170, 0, 48) }, function()
			sim("SellAll")
		end)

		if #items == 0 then
			local holder = Frame({ Parent = root, Position = UDim2.new(0, 0, 0, 80), Size = UDim2.new(1, 0, 1, -80) })
			emptyState(holder, "Your backpack is empty", "Plant seeds in your garden beds, wait for them to grow, then harvest them.", "OPEN SEED SHOP", function()
				openWindow("Seeds")
			end)
			return
		end

		table.sort(order, function(a, b)
			return groups[a].Value > groups[b].Value
		end)
		local scroll = Scroll({ Parent = root, Name = "BagList", Position = UDim2.new(0, 0, 0, 80), Size = UDim2.new(1, 0, 1, -80) })
		local group = Group(scroll)
		for _, key in ipairs(order) do
			local g = groups[key]
			local seed = Config.SeedById[g.S]
			if seed then
				local mutation = g.M and Config.GetMutation(g.M)
				local r = Row(group, 56)
				Swatch(r, mutation and mutation.Color or seed.Color, UDim2.new(0, 12, 0.5, -17), UDim2.new(0, 34, 0, 34))
				local name = (mutation and ('<font color="' .. hex(mutation.Color) .. '">' .. mutation.Name .. "</font> ") or "") .. seed.Name
				Text({ Parent = r, Text = name, Style = "Name", Wrap = false, Position = UDim2.new(0, 58, 0, 0), Size = UDim2.new(0.6, 0, 1, 0) })
				Text({ Parent = r, Text = "x" .. g.Count, Style = "Name", Color = C.Yellow, Wrap = false, AlignX = RIGHT, Position = UDim2.new(0.6, 0, 0, 0), Size = UDim2.new(0.15, 0, 1, 0) })
				Text({ Parent = r, Text = Config.Money(g.Value * State.Multiplier), Style = "Name", Color = C.Cash, Wrap = false, AlignX = RIGHT, Position = UDim2.new(0.75, 0, 0, 0), Size = UDim2.new(0.25, -16, 1, 0) })
			end
		end
	end,
}

---------------------------------------------------------------------
-- Base (market robots + lock)
---------------------------------------------------------------------
panels.Base = {
	Title = "MY BASE",
	Hint = "Buy robots on the Robot Market conveyor",
	Render = function(root)
		if not State then
			return
		end
		local top = Frame({ Parent = root, Color = C.PanelDark, Radius = 12, Outline = 2, OutlineColor = C.RowEdge, Size = UDim2.new(1, 0, 0, 64) })
		local lockText = Text({ Parent = top, Style = "Heading", Wrap = false, Position = UDim2.new(0, 18, 0, 4), Size = UDim2.new(0.7, 0, 0, 32) })
		Text({ Parent = top, Text = "Step on the red LOCK pad at your base. Thieves can't steal while it's locked.", Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 18, 0, 36), Size = UDim2.new(1, -36, 0, 18) })
		onTick(function()
			local now = serverNow()
			if now < (State.LockedUntil or 0) then
				lockText.Text = '<font color="#82FF5A">LOCKED</font>  ' .. clockText(State.LockedUntil - now)
			elseif now < (State.LockReadyAt or 0) then
				lockText.Text = "LOCK RECHARGING  " .. clockText(State.LockReadyAt - now)
			else
				lockText.Text = '<font color="#FF7070">UNLOCKED</font>  -  lock is ready'
			end
		end)

		local scroll = Scroll({ Parent = root, Name = "Pads", Grid = UDim2.new(0, 188, 0, 176), Position = UDim2.new(0, 0, 0, 74), Size = UDim2.new(1, 0, 1, -74) })
		local pads = #Config.Market.PadRows * #Config.Market.PadColumns
		for i = 1, pads do
			local entry = State.Showcase["p" .. i]
			local species = entry and Config.SpeciesById[entry.S]
			if species then
				local mutation = entry.M and Config.GetMarketMutation(entry.M)
				local card = Frame({ Parent = scroll, Order = i, Color = C.Row, Radius = 14, Outline = 3, OutlineColor = rarityColor(species.Rarity) })
				RobotPreview(card, species.Loadout, UDim2.new(1, -12, 0, 100), UDim2.new(0, 6, 0, 6), mutation and mutation.Tint or nil)
				Text({ Parent = card, Text = (entry.M and (entry.M .. " ") or "") .. species.Name, Style = "Name", Color = rarityColor(species.Rarity), Wrap = false, AlignX = CENTER, Position = UDim2.new(0, 6, 0, 110), Size = UDim2.new(1, -12, 0, 24) })
				Text({ Parent = card, Text = string.upper(species.Rarity), Style = "Small", Color = C.Sub, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 6, 0, 134), Size = UDim2.new(1, -12, 0, 14) })
				Text({ Parent = card, Text = "+" .. Config.Money(Config.ShowcaseIncome(entry) * State.Multiplier) .. "/s", Style = "Name", Color = C.Cash, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 6, 0, 148), Size = UDim2.new(1, -12, 0, 22) })
			else
				local card = Frame({ Parent = scroll, Order = i, Color = C.PanelDark, Transparency = 0.3, Radius = 14, Outline = 2, OutlineColor = C.RowEdge })
				Text({ Parent = card, Text = "EMPTY PAD", Style = "Name", Color = C.Sub, AlignX = CENTER, Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 0, 24) })
				Text({ Parent = card, Text = "Buy a robot on the market conveyor", Style = "Small", Color = C.Sub, AlignX = CENTER, Position = UDim2.new(0, 10, 0, 84), Size = UDim2.new(1, -20, 0, 34) })
			end
		end
	end,
}

---------------------------------------------------------------------
-- Robot Lab
---------------------------------------------------------------------
local labSlot = "Drivetrain"

local function moduleDetail(def)
	local parts = {}
	for _, key in ipairs(STATS) do
		local v = def[key] or 0
		if v > 0 then
			table.insert(parts, key .. " +" .. v)
		end
	end
	if def.Slot == "Intake" then
		table.insert(parts, "Holds " .. def.Capacity)
	elseif def.Slot == "Lift" then
		table.insert(parts, def.Points .. " pts/ball")
	elseif def.Slot == "Brain" then
		table.insert(parts, "Auton +" .. def.Auton)
	elseif def.Strafe then
		table.insert(parts, "Strafes")
	end
	return table.concat(parts, "  -  ")
end

panels.Lab = {
	Title = "ROBOT LAB",
	Hint = "Unlock parts, then build your design",
	Render = function(root)
		if not State then
			return
		end
		if not State.Purchased.assembly then
			emptyState(root, "Robot Lab is locked", "Buy the Robot Assembly Station button in your workshop to start building robots.")
			return
		end
		local left = Frame({ Parent = root, Size = UDim2.new(1, -330, 1, 0) })
		local right = Frame({ Parent = root, Color = C.PanelDark, Radius = 14, Outline = 3, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 314, 1, 0) })

		for i, slot in ipairs(Config.ModuleSlots) do
			Button({ Parent = left, Text = string.upper(slot), Kind = slot == labSlot and "yellow" or "blue", TextSize = 15, Position = UDim2.new((i - 1) / 4, 3, 0, 0), Size = UDim2.new(0.25, -6, 0, 40) }, function()
				labSlot = slot
				renderOpen()
			end)
		end
		Text({ Parent = left, Text = Config.SlotInfo[labSlot].Desc, Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 4, 0, 46), Size = UDim2.new(1, -8, 0, 18) })

		local scroll = Scroll({ Parent = left, Name = "Modules", Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68) })
		local group = Group(scroll)
		for index, def in ipairs(Config.Modules[labSlot]) do
			local owned = State.Modules[def.Id] == true
			local equipped = State.Loadout[labSlot] == def.Id
			local locked = (def.Season or 0) > State.Season
			local r = Row(group, 66)
			Text({ Parent = r, Text = def.Name, Style = "Name", Color = rarityColor(Config.RarityOrder[math.min(index, #Config.RarityOrder)]), Wrap = false, Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(1, -170, 0, 26) })
			Text({ Parent = r, Text = moduleDetail(def), Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -170, 0, 18) })
			local props = { Parent = r, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 140, 0, 42) }
			if equipped then
				props.Text, props.Kind = "EQUIPPED", "disabled"
				Button(props)
			elseif owned then
				props.Text, props.Kind = "EQUIP", "blue"
				Button(props, function()
					act("EquipModule", def.Id)
				end)
			elseif locked then
				props.Text, props.Kind = "SEASON " .. def.Season, "disabled"
				Button(props)
			else
				props.Kind = "green"
				local b = Button(props, function()
					act("UnlockModule", def.Id)
				end)
				onCash(function(money)
					setButton(b, Config.Money(def.Cost), money >= def.Cost and "green" or "disabled")
				end)
			end
		end

		local stats = Config.GetRobotStats(State.Loadout)
		RobotPreview(right, State.Loadout, UDim2.new(1, -16, 0, 180), UDim2.new(0, 8, 0, 8))
		Text({ Parent = right, Text = "RATING " .. stats.Rating, Style = "Heading", TextSize = 26, Color = C.Yellow, Position = UDim2.new(0, 18, 0, 14), Size = UDim2.new(1, -36, 0, 30) })
		for i, key in ipairs(STATS) do
			local y = 198 + (i - 1) * 28
			Text({ Parent = right, Text = string.upper(key), Style = "Button", TextSize = 14, Position = UDim2.new(0, 14, 0, y), Size = UDim2.new(0, 84, 0, 22) })
			Bar(right, UDim2.new(0, 100, 0, y + 5), UDim2.new(1, -150, 0, 14), stats[key] / STAT_MAX[key], STAT_COLOR[key])
			Text({ Parent = right, Text = tostring(stats[key]), Style = "Button", TextSize = 15, AlignX = RIGHT, Position = UDim2.new(1, -46, 0, y), Size = UDim2.new(0, 32, 0, 22) })
		end
		local details = {
			"Holds " .. stats.Capacity .. "  -  " .. stats.PointsPerBall .. " pts per ball",
			"Auton +" .. stats.Auton .. "  -  " .. (stats.Strafe and "Strafes" or "No strafe"),
			"Earns " .. Config.Money(stats.Income * State.Multiplier) .. "/s  -  Bays " .. #State.Garage .. "/" .. State.GarageSlots,
		}
		for i, line in ipairs(details) do
			Text({ Parent = right, Text = line, Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 14, 0, 314 + (i - 1) * 20), Size = UDim2.new(1, -28, 0, 18) })
		end
		local full = #State.Garage >= State.GarageSlots
		local build = Button({ Parent = right, Text = "BUILD", Kind = "green", TextSize = 20, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 52) }, function()
			act("BuildRobot")
		end)
		onCash(function(money)
			if full then
				setButton(build, "BAYS FULL", "disabled")
			else
				setButton(build, "BUILD  " .. Config.Money(stats.BuildCost), money >= stats.BuildCost and "green" or "disabled")
			end
		end)
	end,
}

---------------------------------------------------------------------
-- Garage
---------------------------------------------------------------------
panels.Garage = {
	Title = "GARAGE",
	Hint = "Robots in bays earn cash every second",
	Render = function(root)
		if not State then
			return
		end
		if State.GarageSlots == 0 then
			emptyState(root, "No robot bays yet", "Buy the Robot Assembly Station to get your first bay.")
			return
		end
		local scroll = Scroll({ Parent = root, Name = "Robots", Grid = UDim2.new(0, 252, 0, 250) })
		for i = 1, State.GarageSlots do
			local robot = State.Garage[i]
			if robot then
				local stats, defs = Config.GetRobotStats(robot)
				local active = State.Active == i
				local card = Frame({ Parent = scroll, Order = i, Color = C.Row, Radius = 14, Outline = 3, OutlineColor = active and C.Yellow or C.Outline })
				RobotPreview(card, robot, UDim2.new(1, -12, 0, 130), UDim2.new(0, 6, 0, 6))
				Text({ Parent = card, Text = "ROBOT " .. i .. (active and '  <font color="#FFC424">ACTIVE</font>' or ""), Style = "Name", Wrap = false, Position = UDim2.new(0, 12, 0, 140), Size = UDim2.new(1, -24, 0, 24) })
				Text({ Parent = card, Text = "Rating " .. stats.Rating .. "  -  " .. Config.Money(stats.Income * State.Multiplier) .. "/s", Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 12, 0, 166), Size = UDim2.new(1, -24, 0, 16) })
				Text({ Parent = card, Text = defs.Drivetrain.Name, Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 12, 0, 182), Size = UDim2.new(1, -24, 0, 16) })
				Button({ Parent = card, Text = active and "ACTIVE" or "USE", Kind = active and "disabled" or "blue", TextSize = 15, Position = UDim2.new(0, 10, 1, -46), Size = UDim2.new(0.5, -15, 0, 36) }, function()
					act("SetActive", i)
				end)
				local refund = math.floor(stats.BuildCost * Config.ScrapRefund)
				Button({ Parent = card, Text = "SCRAP", Kind = "red", TextSize = 15, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -10, 1, -46), Size = UDim2.new(0.5, -15, 0, 36) }, function(b)
					if b:GetAttribute("Confirm") then
						act("ScrapRobot", i)
					else
						b:SetAttribute("Confirm", true)
						setButton(b, "+" .. Config.Money(refund) .. "?")
						task.delay(3, function()
							if b.Parent then
								b:SetAttribute("Confirm", false)
								setButton(b, "SCRAP")
							end
						end)
					end
				end)
			else
				local card = Frame({ Parent = scroll, Order = i, Color = C.PanelDark, Transparency = 0.3, Radius = 14, Outline = 2, OutlineColor = C.RowEdge })
				Text({ Parent = card, Text = "BAY " .. i, Style = "Heading", AlignX = CENTER, Position = UDim2.new(0, 0, 0, 70), Size = UDim2.new(1, 0, 0, 30) })
				Text({ Parent = card, Text = "Empty", Style = "Small", Color = C.Sub, AlignX = CENTER, Position = UDim2.new(0, 0, 0, 102), Size = UDim2.new(1, 0, 0, 18) })
				Button({ Parent = card, Text = "ROBOT LAB", Kind = "green", TextSize = 15, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140), Size = UDim2.new(0, 150, 0, 40) }, function()
					openWindow("Lab")
				end)
			end
		end
	end,
}

---------------------------------------------------------------------
-- Competition results
---------------------------------------------------------------------
local dim = Frame({ Parent = modalGui, Color = Color3.new(0, 0, 0), Transparency = 0.45, Visible = false })
dim.Active = true

local resultHost = Frame({ Parent = modalGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 540, 0, 450), Visible = false })
autoScale(resultHost)
local resultWrap = Frame({ Parent = resultHost })
local resultScale = new("UIScale", { Parent = resultWrap })
local resultCard = Frame({ Parent = resultWrap, Color = C.Panel, Radius = 22, Outline = 4 })
local resultTitle = Text({ Parent = resultCard, Style = "Title", TextSize = 30, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 20, 0, 14), Size = UDim2.new(1, -40, 0, 40) })
local roundsGroup = nil
local resultSummary = Text({ Parent = resultCard, Style = "Huge", TextSize = 38, AlignX = CENTER, Color = C.Yellow, Position = UDim2.new(0, 20, 0, 290), Size = UDim2.new(1, -40, 0, 44) })
local resultDetail = Text({ Parent = resultCard, Style = "Name", Color = C.Cash, AlignX = CENTER, Position = UDim2.new(0, 20, 0, 336), Size = UDim2.new(1, -40, 0, 24) })
local resultToken = 0
local resultDone = Button({ Parent = resultCard, Text = "AWESOME!", Kind = "green", TextSize = 20, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(0, 220, 0, 50) }, function()
	resultToken += 1
	dim.Visible = false
	resultHost.Visible = false
end)

local function showCompResult(result)
	resultToken += 1
	local token = resultToken
	dim.Visible = true
	resultHost.Visible = true
	resultDone.Visible = false
	resultTitle.Text = string.upper(result.Competition)
	resultSummary.Text = ""
	resultDetail.Text = ""
	resultScale.Scale = 0.6
	tween(resultScale, { Scale = 1 }, BOUNCE)
	if roundsGroup then
		roundsGroup:Destroy()
	end
	roundsGroup = Group(resultCard, { Position = UDim2.new(0, 24, 0, 66), Size = UDim2.new(1, -48, 0, 0) })

	task.spawn(function()
		for _, r in ipairs(result.Rounds) do
			task.wait(0.6)
			if token ~= resultToken then
				return
			end
			local row = Row(roundsGroup, 62)
			row.BackgroundColor3 = r.Won and Color3.fromRGB(70, 170, 70) or Color3.fromRGB(190, 70, 70)
			Text({ Parent = row, Text = string.upper(r.Round), Style = "Name", Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(0.45, 0, 0, 26) })
			Text({ Parent = row, Text = "vs Team " .. r.OppTeam, Style = "Small", Color = C.Sub, Position = UDim2.new(0, 14, 0, 34), Size = UDim2.new(0.45, 0, 0, 18) })
			Text({ Parent = row, Text = r.You .. " - " .. r.Opp, Style = "Heading", TextSize = 26, AlignX = CENTER, Position = UDim2.new(0.45, 0, 0, 0), Size = UDim2.new(0.3, 0, 1, 0) })
			Text({ Parent = row, Text = r.Won and "WIN!" or "LOSS", Style = "Heading", Color = r.Won and C.Cash or C.Text, AlignX = RIGHT, Position = UDim2.new(0.75, 0, 0, 0), Size = UDim2.new(0.25, -14, 1, 0) })
			local s = new("UIScale", { Parent = row, Scale = 0.5 })
			tween(s, { Scale = 1 }, BOUNCE)
		end
		task.wait(0.6)
		if token ~= resultToken then
			return
		end
		if result.Champion then
			resultSummary.Text = "CHAMPIONS!"
			resultDetail.Text = "+" .. Config.Money(result.Prize) .. "   +" .. result.Trophies .. " trophies"
		elseif result.Reached == 2 then
			resultSummary.Text = "FINALIST!"
			resultDetail.Text = "+" .. Config.Money(result.Prize) .. "   +" .. result.Trophies .. " trophies"
		elseif result.Reached == 1 then
			resultSummary.Text = "SEMIFINALIST"
			resultDetail.Text = "+" .. Config.Money(result.Prize)
		else
			resultSummary.Text = "KNOCKED OUT"
			resultDetail.Text = "Upgrade your robot and try again!"
		end
		local s = new("UIScale", { Parent = resultSummary, Scale = 0.3 })
		tween(s, { Scale = 1 }, BOUNCE)
		resultDone.Visible = true
	end)
end

---------------------------------------------------------------------
-- Compete
---------------------------------------------------------------------
panels.Compete = {
	Title = "COMPETITIONS",
	Hint = "Your active robot's rating decides the result",
	Render = function(root)
		if not State then
			return
		end
		local robot = State.Garage[State.Active]
		local rating = robot and Config.GetRobotStats(robot).Rating or 0
		local top = Frame({ Parent = root, Color = C.PanelDark, Radius = 12, Outline = 2, OutlineColor = C.RowEdge, Size = UDim2.new(1, 0, 0, 72) })
		if robot then
			RobotPreview(top, robot, UDim2.new(0, 62, 0, 62), UDim2.new(0, 5, 0, 5))
			Text({ Parent = top, Text = "ROBOT " .. State.Active, Style = "Heading", Position = UDim2.new(0, 80, 0, 8), Size = UDim2.new(0.5, 0, 0, 28) })
			Text({ Parent = top, Text = "Win all 3 rounds for the full prize!", Style = "Small", Color = C.Sub, Position = UDim2.new(0, 80, 0, 40), Size = UDim2.new(0.6, 0, 0, 18) })
			Text({ Parent = top, Text = "RATING " .. rating, Style = "Heading", TextSize = 26, Color = C.Yellow, AlignX = RIGHT, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0, 200, 1, 0) })
		else
			Text({ Parent = top, Text = "Build a robot to compete!", Style = "Heading", Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -220, 1, 0) })
			Button({ Parent = top, Text = "ROBOT LAB", Kind = "green", Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 160, 0, 46) }, function()
				openWindow("Lab")
			end)
		end

		local scroll = Scroll({ Parent = root, Name = "Comps", Position = UDim2.new(0, 0, 0, 82), Size = UDim2.new(1, 0, 1, -82) })
		local group = Group(scroll)
		for index, comp in ipairs(Config.Competitions) do
			local meets = robot ~= nil and rating >= comp.MinRating
			local r = Row(group, 70)
			Text({ Parent = r, Text = comp.Name, Style = "Name", TextSize = 20, Color = rarityColor(Config.RarityOrder[math.min(index, #Config.RarityOrder)]), Wrap = false, Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(0.5, 0, 0, 28) })
			local need = meets and ("Rating " .. comp.MinRating .. "+") or ('<font color="#FF7070">Needs rating ' .. comp.MinRating .. "</font>")
			Text({ Parent = r, Text = need .. "  -  Entry " .. (comp.Fee > 0 and Config.Money(comp.Fee) or "FREE"), Style = "Small", Color = C.Sub, Wrap = false, Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(0.5, 0, 0, 18) })
			Text({ Parent = r, Text = Config.Money(comp.Prize * State.Multiplier) .. "  +" .. comp.Trophies .. " TROPHIES", Style = "Name", Color = C.Cash, Wrap = false, AlignX = RIGHT, Position = UDim2.new(0.45, 0, 0, 0), Size = UDim2.new(0.55, -170, 1, 0) })
			local b = Button({ Parent = r, Text = "ENTER", Kind = "green", Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 140, 0, 46) }, function()
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
					setButton(b, "LOCKED", "disabled")
				elseif remaining > 0 then
					setButton(b, clockText(remaining), "disabled")
				elseif cash() < comp.Fee then
					setButton(b, "NEED CASH", "disabled")
				else
					setButton(b, "ENTER", "green")
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

local function ModeTile(parent, x, color, title, lines)
	local tile = Frame({ Parent = parent, Color = color, Radius = 16, Outline = 3, Shine = true, Position = UDim2.new(x, x > 0 and 7 or 0, 0, 0), Size = UDim2.new(0.5, -7, 0, 210) })
	Text({ Parent = tile, Text = title, Style = "Title", TextSize = 30, Wrap = false, Position = UDim2.new(0, 18, 0, 12), Size = UDim2.new(1, -36, 0, 40) })
	for i, line in ipairs(lines) do
		Text({ Parent = tile, Text = line, Style = "Body", Wrap = false, Position = UDim2.new(0, 18, 0, 58 + (i - 1) * 24), Size = UDim2.new(1, -36, 0, 22) })
	end
	return tile
end

panels.Drive = {
	Title = "DRIVE",
	Hint = "Practice for cash or battle other players",
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
			local tile = Frame({ Parent = root, Color = C.Green, Radius = 16, Outline = 3, Shine = true, Size = UDim2.new(1, 0, 0, 100) })
			Text({ Parent = tile, Text = "YOU'RE DRIVING!", Style = "Title", Position = UDim2.new(0, 20, 0, 10), Size = UDim2.new(1, -240, 0, 44) })
			Text({ Parent = tile, Text = "Leaving a ranked match counts as a forfeit.", Style = "Body", Position = UDim2.new(0, 20, 0, 58), Size = UDim2.new(1, -240, 0, 22) })
			Button({ Parent = tile, Text = "STOP", Kind = "red", TextSize = 22, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.new(0, 170, 0, 54) }, function()
				arena("Stop")
			end)
		else
			local practice = ModeTile(root, 0, C.Blue, "PRACTICE", {
				"Drive freely, no opponents",
				Config.Money(Config.Practice.CashPerPoint * State.Multiplier) .. " for every point scored",
			})
			Button({ Parent = practice, Text = robot and "DRIVE!" or "BUILD A ROBOT", Kind = robot and "green" or "disabled", TextSize = 22, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -36, 0, 54) }, function()
				arena("Practice")
			end)
			local status = matchLive and "A match is live right now!" or (queueSize .. " waiting in queue")
			local ranked = ModeTile(root, 0.5, C.Red, "RANKED 1v1", {
				Config.Match.Duration .. "s matches  -  Win +" .. Config.Match.WinTrophies .. " trophies",
				status,
			})
			Button({ Parent = ranked, Text = not robot and "BUILD A ROBOT" or (inQueue and "LEAVE QUEUE" or "JOIN QUEUE"), Kind = not robot and "disabled" or (inQueue and "orange" or "green"), TextSize = 22, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -36, 0, 54) }, function()
				arena("Queue")
			end)
		end

		local top = driving and 112 or 222
		local controls = Frame({ Parent = root, Color = C.PanelDark, Radius = 14, Outline = 2, OutlineColor = C.RowEdge, Position = UDim2.new(0, 0, 0, top), Size = UDim2.new(1, 0, 0, 150) })
		Text({ Parent = controls, Text = "CONTROLS", Style = "Name", Position = UDim2.new(0, 16, 0, 6), Size = UDim2.new(1, -32, 0, 24) })
		local entries = {
			{ { "W", "S" }, "Drive forward and back" },
			{ { "A", "D" }, "Turn" },
			{ { "Q", "E" }, "Strafe (Mecanum, X-Drive)" },
			{ { "F" }, "Score held balls in a goal" },
			{ { "SPACE" }, "Leave the robot" },
			{ { "AUTO" }, "Intake grabs balls" },
		}
		for i, entry in ipairs(entries) do
			local col = (i - 1) % 2
			local rowIndex = math.floor((i - 1) / 2)
			local holder = Frame({ Parent = controls, Position = UDim2.new(col * 0.5, 16, 0, 36 + rowIndex * 36), Size = UDim2.new(0.5, -32, 0, 30) })
			local x = 0
			for _, key in ipairs(entry[1]) do
				local w = #key > 1 and 60 or 30
				Keycap(holder, key, UDim2.new(0, x, 0, 1), w)
				x += w + 6
			end
			Text({ Parent = holder, Text = entry[2], Style = "Body", Wrap = false, Position = UDim2.new(0, 76, 0, 0), Size = UDim2.new(1, -76, 1, 0) })
		end
	end,
}

---------------------------------------------------------------------
-- Season
---------------------------------------------------------------------
panels.Season = {
	Title = "NEW SEASON",
	Hint = "Rebirth for a permanent cash boost",
	Render = function(root)
		if not State then
			return
		end
		local cost = Config.GetSeasonCost(State.Season)
		local nowMult = Config.GetMultiplier(State.Season, false)
		local nextMult = Config.GetMultiplier(State.Season + 1, false)
		local hero = Frame({ Parent = root, Color = C.Purple, Radius = 16, Outline = 3, Shine = true, Size = UDim2.new(1, 0, 0, 120) })
		Text({ Parent = hero, Text = "SEASON " .. State.Season .. "  >  " .. (State.Season + 1), Style = "Huge", TextSize = 40, Position = UDim2.new(0, 20, 0, 10), Size = UDim2.new(0.6, 0, 0, 50) })
		Text({ Parent = hero, Text = string.format("Cash x%.1f  >  x%.1f forever", nowMult, nextMult), Style = "Heading", Color = C.Yellow, Position = UDim2.new(0, 20, 0, 64), Size = UDim2.new(0.6, 0, 0, 30) })
		local start = Button({ Parent = hero, Text = "START", Kind = "green", TextSize = 22, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.new(0, 250, 0, 60) }, function(b)
			if b:GetAttribute("Confirm") then
				act("Rebirth")
			else
				b:SetAttribute("Confirm", true)
				setButton(b, "TAP AGAIN!", "red")
				task.delay(3, function()
					if b.Parent then
						b:SetAttribute("Confirm", false)
						setButton(b, "START SEASON " .. (State.Season + 1), "green")
					end
				end)
			end
		end)
		local _, fill = Bar(root, UDim2.new(0, 0, 0, 132), UDim2.new(1, 0, 0, 30), 0, C.Green)
		local barText = Text({ Parent = root, Style = "Button", AlignX = CENTER, Position = UDim2.new(0, 0, 0, 132), Size = UDim2.new(1, 0, 0, 30) })
		onCash(function(money)
			tween(fill, { Size = UDim2.new(math.clamp(money / cost, 0, 1), 0, 1, 0) })
			barText.Text = Config.Money(money) .. " / " .. Config.Money(cost)
			if not start:GetAttribute("Confirm") then
				setButton(start, money >= cost and ("START SEASON " .. (State.Season + 1)) or "NOT ENOUGH CASH", money >= cost and "green" or "disabled")
			end
		end)

		local unlocks = {}
		for _, slot in ipairs(Config.ModuleSlots) do
			for _, def in ipairs(Config.Modules[slot]) do
				if def.Season == State.Season + 1 then
					table.insert(unlocks, def.Name)
				end
			end
		end
		if #unlocks == 0 then
			unlocks = { "Bigger multiplier" }
		end
		local columns = {
			{ "RESETS", C.Red, { "Cash", "Workshop", "Garden + seeds", "Robots" } },
			{ "KEEPS", C.Green, { "Trophies", "Stats", "Season boost" } },
			{ "UNLOCKS", C.Yellow, unlocks },
		}
		for i, col in ipairs(columns) do
			local box = Frame({ Parent = root, Color = C.PanelDark, Radius = 14, Outline = 3, OutlineColor = col[2], Position = UDim2.new((i - 1) / 3, i > 1 and 6 or 0, 0, 174), Size = UDim2.new(1 / 3, -8, 0, 150) })
			Text({ Parent = box, Text = col[1], Style = "Heading", Color = col[2], Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(1, -28, 0, 28) })
			for k, line in ipairs(col[3]) do
				if k <= 4 then
					Text({ Parent = box, Text = line, Style = "Body", Wrap = false, Position = UDim2.new(0, 14, 0, 36 + (k - 1) * 26), Size = UDim2.new(1, -28, 0, 22) })
				end
			end
		end

		local s = State.Stats
		local tiles = {
			{ tostring(s.Harvests or 0), "HARVESTS" },
			{ tostring(s.Steals or 0), "STEALS" },
			{ s.CompWins .. "/" .. s.CompsEntered, "TOURNEYS" },
			{ s.MatchesWon .. "/" .. s.MatchesPlayed, "RANKED" },
			{ Config.Money(s.TotalEarned), "EARNED" },
		}
		local row = Frame({ Parent = root, Position = UDim2.new(0, 0, 1, -76), Size = UDim2.new(1, 0, 0, 76) })
		for i, tile in ipairs(tiles) do
			local t = Frame({ Parent = row, Color = C.Row, Radius = 12, Outline = 2, OutlineColor = C.RowEdge, Position = UDim2.new((i - 1) / 5, 4, 0, 0), Size = UDim2.new(0.2, -8, 1, 0) })
			Text({ Parent = t, Text = tile[1], Style = "Heading", AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 4, 0, 8), Size = UDim2.new(1, -8, 0, 30) })
			Text({ Parent = t, Text = tile[2], Style = "Small", Color = C.Sub, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 4, 0, 44), Size = UDim2.new(1, -8, 0, 18) })
		end
	end,
}

---------------------------------------------------------------------
-- Shop
---------------------------------------------------------------------
panels.Shop = {
	Title = "SHOP",
	Hint = "Game passes",
	Render = function(root)
		if not State then
			return
		end
		local scroll = Scroll({ Parent = root, Name = "Passes", Grid = UDim2.new(0, 384, 0, 200) })
		local colors = { C.Green, C.Yellow, C.Purple, C.Orange }
		for index, pass in ipairs(Config.GamePasses) do
			local owned = State.Passes[pass.Key] == true
			local card = Frame({ Parent = scroll, Order = index, Color = colors[(index - 1) % #colors + 1], Radius = 16, Outline = 3, Shine = true })
			Text({ Parent = card, Text = string.upper(pass.Name), Style = "Title", TextSize = 28, Wrap = false, Position = UDim2.new(0, 18, 0, 12), Size = UDim2.new(1, -36, 0, 38) })
			Text({ Parent = card, Text = pass.Desc, Style = "Body", AlignY = Enum.TextYAlignment.Top, Position = UDim2.new(0, 18, 0, 56), Size = UDim2.new(1, -36, 0, 48) })
			Button({ Parent = card, Text = owned and "OWNED" or "BUY", Kind = owned and "disabled" or "green", TextSize = 22, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -36, 0, 52) }, function()
				act("PromptPass", pass.Key)
			end)
		end
	end,
}

---------------------------------------------------------------------
-- Menu (left side)
---------------------------------------------------------------------
local MENU = {
	{ "Seeds", "SEEDS", "green" },
	{ "Bag", "BAG", "orange" },
	{ "Base", "BASE", "red" },
	{ "Lab", "ROBOTS", "blue" },
	{ "Garage", "GARAGE", "purple" },
	{ "Compete", "COMPETE", "yellow" },
	{ "Drive", "DRIVE", "green" },
	{ "Season", "SEASON", "purple" },
	{ "Shop", "SHOP", "yellow" },
}

local menuHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 30), Size = UDim2.new(0, 196, 0, 5 * 76) })
new("UIGridLayout", { Parent = menuHost, CellSize = UDim2.new(0, 92, 0, 66), CellPadding = UDim2.new(0, 10, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
autoScale(menuHost)

for i, entry in ipairs(MENU) do
	local key, label, kind = entry[1], entry[2], entry[3]
	local holder = Frame({ Parent = menuHost, Order = i })
	local b = Button({ Parent = holder, Text = label, Kind = kind, TextSize = 17, Radius = 14, Size = UDim2.fromScale(1, 1) }, function()
		openWindow(key)
	end)
	local badge = Frame({ Parent = holder, Color = C.Red, Radius = "round", Outline = 2.5, OutlineColor = C.Text, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.new(0, 24, 0, 24), Visible = false })
	Text({ Parent = badge, Text = "!", Style = "Button", TextSize = 16, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })
	menuItems[key] = { Badge = badge, Stroke = b:FindFirstChildOfClass("UIStroke") }
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
	local seeds = false
	for id, count in pairs(State.Stock or {}) do
		local seed = Config.SeedById[id]
		if seed and count > 0 and money >= seed.Price and seed.Rarity ~= "Common" then
			seeds = true
		end
	end
	menuItems.Lab.Badge.Visible = lab
	menuItems.Compete.Badge.Visible = compete
	menuItems.Seeds.Badge.Visible = seeds
	menuItems.Bag.Badge.Visible = #(State.Backpack or {}) >= Config.Garden.MaxBackpack
	menuItems.Season.Badge.Visible = money >= Config.GetSeasonCost(State.Season)
	menuItems.Drive.Badge.Visible = robot ~= nil and (Remotes:GetAttribute("QueueSize") or 0) > 0 and not player:GetAttribute("InQueue")
end

---------------------------------------------------------------------
-- Carrying a stolen robot
---------------------------------------------------------------------
local carryBanner = Frame({ Parent = mainGui, Color = C.Red, Radius = 16, Outline = 3, Shine = true, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.new(0, 460, 0, 64), Visible = false })
autoScale(carryBanner)
Text({ Parent = carryBanner, Text = "RUN TO YOUR BASE!", Style = "Title", TextSize = 30, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })
player:GetAttributeChangedSignal("Carrying"):Connect(function()
	carryBanner.Visible = player:GetAttribute("Carrying") == true
end)

---------------------------------------------------------------------
-- Match HUD
---------------------------------------------------------------------
local scoreHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 106), Size = UDim2.new(0, 500, 0, 80), Visible = false })
autoScale(scoreHost)

local function TeamBox(x, anchor, color)
	local box = Frame({ Parent = scoreHost, Color = color, Radius = 16, Outline = 3, Shine = true, Anchor = Vector2.new(anchor, 0), Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(0, 180, 0, 76) })
	local s = new("UIScale", { Parent = box })
	local name = Text({ Parent = box, Style = "Button", TextSize = 14, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 20) })
	local score = Text({ Parent = box, Style = "Huge", TextSize = 40, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 8, 0, 22), Size = UDim2.new(1, -16, 0, 48) })
	return box, name, score, s
end

local redBox, redName, redScore, redScale = TeamBox(0, 0, C.TeamRed)
local blueBox, blueName, blueScore, blueScale = TeamBox(1, 1, C.TeamBlue)
local timerBox = Frame({ Parent = scoreHost, Color = C.Yellow, Radius = 16, Outline = 3, Shine = true, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0, 120, 0, 64) })
local timerText = Text({ Parent = timerBox, Style = "Heading", TextSize = 30, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(1, -8, 0, 36) })
local timerSub = Text({ Parent = timerBox, Style = "Button", TextSize = 12, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 4, 0, 40), Size = UDim2.new(1, -8, 0, 18) })
local practiceBox = Frame({ Parent = scoreHost, Color = C.Blue, Radius = 16, Outline = 3, Shine = true, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 260, 0, 76), Visible = false })
local practiceScale = new("UIScale", { Parent = practiceBox })
Text({ Parent = practiceBox, Text = "PRACTICE POINTS", Style = "Button", TextSize = 14, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 20) })
local practiceScore = Text({ Parent = practiceBox, Style = "Huge", TextSize = 40, AlignX = CENTER, Position = UDim2.new(0, 8, 0, 22), Size = UDim2.new(1, -16, 0, 48) })

local intakeHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.new(0, 520, 0, 100), Visible = false })
autoScale(intakeHost)
local hint = Text({ Parent = intakeHost, Style = "Name", TextSize = 16, AlignX = CENTER, Wrap = false, Size = UDim2.new(1, 0, 0, 22) })
local intakeCard = Frame({ Parent = intakeHost, Color = C.Panel, Radius = 16, Outline = 3, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 400, 0, 66) })
Text({ Parent = intakeCard, Text = "INTAKE", Style = "Button", TextSize = 14, Position = UDim2.new(0, 16, 0, 4), Size = UDim2.new(0, 80, 0, 20) })
local dots = Frame({ Parent = intakeCard, Position = UDim2.new(0, 16, 0, 26), Size = UDim2.new(1, -150, 0, 30) })
new("UIListLayout", { Parent = dots, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
local pointsText = Text({ Parent = intakeCard, Style = "Heading", Color = C.Yellow, AlignX = RIGHT, Wrap = false, Position = UDim2.new(1, -140, 0, 0), Size = UDim2.new(0, 124, 1, 0) })

local exitHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -24), Size = UDim2.new(0, 170, 0, 54), Visible = false })
autoScale(exitHost)
Button({ Parent = exitHost, Text = "EXIT ROBOT", Kind = "red", TextSize = 19, Size = UDim2.fromScale(1, 1) }, function()
	arena("Stop")
end)

local countdownHost = Frame({ Parent = modalGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.new(0, 420, 0, 200), Visible = false })
autoScale(countdownHost)
local countdownText = Text({ Parent = countdownHost, Style = "Huge", TextSize = 140, StrokeThickness = 6, Color = C.Yellow, AlignX = CENTER, Wrap = false, Size = UDim2.fromScale(1, 1) })
local countdownScale = new("UIScale", { Parent = countdownText })

local matchHost = Frame({ Parent = modalGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.new(0, 480, 0, 300), Visible = false })
autoScale(matchHost)
local matchWrap = Frame({ Parent = matchHost })
local matchScale = new("UIScale", { Parent = matchWrap })
local matchCard = Frame({ Parent = matchWrap, Color = C.Panel, Radius = 22, Outline = 4 })
local matchTitle = Text({ Parent = matchCard, Style = "Huge", TextSize = 54, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 20, 0, 18), Size = UDim2.new(1, -40, 0, 64) })
local matchScore = Text({ Parent = matchCard, Style = "Huge", TextSize = 40, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 20, 0, 96), Size = UDim2.new(1, -40, 0, 48) })
local matchNames = Text({ Parent = matchCard, Style = "Name", Color = C.Sub, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 20, 0, 148), Size = UDim2.new(1, -40, 0, 24) })
Text({ Parent = matchCard, Text = "Rewards added to your wallet!", Style = "Body", Color = C.Cash, AlignX = CENTER, Position = UDim2.new(0, 20, 0, 180), Size = UDim2.new(1, -40, 0, 22) })
Button({ Parent = matchCard, Text = "OK!", Kind = "green", TextSize = 22, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(0, 200, 0, 52) }, function()
	matchHost.Visible = false
	dim.Visible = false
end)

local lastCountdown, lastMatchState = nil, nil
local lastScores = { Red = 0, Blue = 0, Practice = 0 }

local function pulse(scale)
	scale.Scale = 1.25
	tween(scale, { Scale = 1 }, BOUNCE)
end

local function showCountdown(text, color)
	countdownHost.Visible = true
	countdownText.Text = text
	countdownText.TextColor3 = color
	countdownText.TextTransparency = 0
	countdownScale.Scale = 2
	tween(countdownScale, { Scale = 1 }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end

local function buildDots(held, capacity)
	for _, child in ipairs(dots:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i = 1, capacity do
		Frame({ Parent = dots, Order = i, Color = i <= held and Config.Field.BallColor or C.PanelDark, Radius = "round", Outline = 2, Shine = i <= held, Size = UDim2.new(0, 26, 0, 26) })
	end
end

local function renderArena()
	local mode = Arena.Mode
	local driving = isDriving()
	intakeHost.Visible = driving
	exitHost.Visible = driving
	scoreHost.Visible = driving
	menuHost.Visible = not driving
	if State then
		updateGoal(cash())
	end
	if driving then
		closeWindow()
		local held, capacity = Arena.Held or 0, Arena.Capacity or 1
		buildDots(held, capacity)
		pointsText.Text = "x" .. (Arena.PointsPerBall or 1) .. " PTS"
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
		hint.Text = "WASD drive" .. (Arena.Strafe and "  -  Q/E strafe" or "") .. "  -  F score in any goal  -  SPACE exit"
		countdownHost.Visible = false
	elseif mode == "Ranked" and Arena.Match then
		local m = Arena.Match
		practiceBox.Visible = false
		redBox.Visible, blueBox.Visible, timerBox.Visible = true, true, true
		redName.Text = string.upper(m.RedName) .. (m.Side == "Red" and " (YOU)" or "")
		blueName.Text = string.upper(m.BlueName) .. (m.Side == "Blue" and " (YOU)" or "")
		redScore.Text = tostring(m.Red)
		blueScore.Text = tostring(m.Blue)
		if m.Red > lastScores.Red then
			pulse(redScale)
		end
		if m.Blue > lastScores.Blue then
			pulse(blueScale)
		end
		lastScores.Red, lastScores.Blue = m.Red, m.Blue
		hint.Text = "Score in the " .. string.upper(m.Side or "?") .. " goal  -  F to score  -  Leaving forfeits!"
		if m.State == "Countdown" then
			timerText.Text = tostring(m.Countdown or "")
			timerSub.Text = "GET READY"
			if m.Countdown ~= lastCountdown then
				showCountdown(tostring(m.Countdown or ""), C.Yellow)
			end
			lastCountdown = m.Countdown
		else
			local t = m.Time or 0
			timerText.Text = clockText(t)
			timerSub.Text = "LIVE"
			timerText.TextColor3 = t <= 10 and C.Red or C.Text
			if lastMatchState == "Countdown" then
				showCountdown("GO!", C.Cash)
				task.delay(0.7, function()
					tween(countdownText, { TextTransparency = 1 }, TweenInfo.new(0.3))
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
		local titles = { Win = "VICTORY!", Loss = "DEFEAT", Tie = "TIE GAME", Forfeit = "FORFEIT" }
		local colors = { Win = C.Yellow, Loss = C.Red, Tie = C.Blue, Forfeit = C.Red }
		matchTitle.Text = titles[Arena.Result] or "MATCH OVER"
		matchTitle.TextColor3 = colors[Arena.Result] or C.Text
		matchScore.Text = '<font color="#FF6464">' .. (Arena.Red or 0) .. "</font>  -  " .. '<font color="#64A0FF">' .. (Arena.Blue or 0) .. "</font>"
		matchNames.Text = (Arena.RedName or "Red") .. "  vs  " .. (Arena.BlueName or "Blue")
		dim.Visible = true
		matchHost.Visible = true
		matchScale.Scale = 0.5
		tween(matchScale, { Scale = 1 }, BOUNCE)
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
	if panels[name] and not isDriving() and openName ~= name then
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

local function rerenderDrive()
	refreshBadges()
	if openName == "Drive" then
		renderOpen()
	end
end
player:GetAttributeChangedSignal("InQueue"):Connect(rerenderDrive)
player:GetAttributeChangedSignal("Driving"):Connect(rerenderDrive)
Remotes:GetAttributeChangedSignal("QueueSize"):Connect(rerenderDrive)

task.spawn(function()
	while true do
		task.wait(1)
		for _, fn in ipairs(live.Tick) do
			fn()
		end
		refreshBadges()
	end
end)

local function hookCamera(cam)
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()
end
hookCamera(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	hookCamera(workspace.CurrentCamera)
end)

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

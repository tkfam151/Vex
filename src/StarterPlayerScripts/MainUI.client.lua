--[[
	MainUI (LocalScript)  ->  StarterPlayer.StarterPlayerScripts.MainUI

	Builds the entire interface in code:
	  HUD (cash / trophies / season), side menu, Robot Lab, Garage,
	  Competitions, Drive (practice + ranked), Season (rebirth), Shop,
	  notifications, match HUD and result popups.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRemote = Remotes:WaitForChild("Request")
local ArenaRemote = Remotes:WaitForChild("ArenaRequest")
local DataUpdate = Remotes:WaitForChild("DataUpdate")
local NotifyRemote = Remotes:WaitForChild("Notify")
local OpenUIRemote = Remotes:WaitForChild("OpenUI")
local ArenaState = Remotes:WaitForChild("ArenaState")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local State = nil -- latest data snapshot from the server
local Arena = { Mode = "None" }
local cooldownEnds = {} -- [compId] = os.clock() time when ready

---------------------------------------------------------------------
-- Theme + helpers
---------------------------------------------------------------------
local T = {
	Bg = Color3.fromRGB(22, 25, 36),
	Panel = Color3.fromRGB(30, 34, 50),
	Row = Color3.fromRGB(42, 47, 66),
	Red = Color3.fromRGB(220, 50, 55),
	Blue = Color3.fromRGB(50, 120, 230),
	Green = Color3.fromRGB(50, 180, 85),
	Gold = Color3.fromRGB(245, 190, 50),
	Gray = Color3.fromRGB(85, 90, 108),
	Text = Color3.fromRGB(255, 255, 255),
	Sub = Color3.fromRGB(175, 180, 200),
}

local function corner(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px or 8)
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(0, 0, 0)
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function padding(inst, px)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = inst
	return p
end

local function apply(inst, props)
	for key, value in pairs(props or {}) do
		if key == "MaxText" then
			local c = Instance.new("UITextSizeConstraint")
			c.MaxTextSize = value
			c.Parent = inst
		elseif key ~= "Parent" then
			inst[key] = value
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function frame(props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = T.Panel
	return apply(f, props)
end

local function label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = T.Text
	l.TextScaled = true
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	if props.MaxText == nil then
		props.MaxText = 18
	end
	return apply(l, props)
end

local function button(props, onClick)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = T.Blue
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBlack
	b.TextColor3 = T.Text
	b.TextScaled = true
	corner(b, 8)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = b
	if props.MaxText == nil then
		props.MaxText = 16
	end
	apply(b, props)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

local function list(props)
	local s = Instance.new("ScrollingFrame")
	s.Name = "List"
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = T.Sub
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = s
	return apply(s, props)
end

local function row(parent, height, order)
	local r = frame({ Parent = parent, BackgroundColor3 = T.Row, Size = UDim2.new(1, -10, 0, height), LayoutOrder = order or 0 })
	corner(r, 8)
	return r
end

local function cash()
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Cash")
	return value and value.Value or (State and State.Cash or 0)
end

---------------------------------------------------------------------
-- Screen
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "VexUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

---------------------------------------------------------------------
-- Notifications
---------------------------------------------------------------------
local toastHolder = frame({
	Parent = gui,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.new(0, 420, 0, 260),
})
do
	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = toastHolder
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(420, 260)
	constraint.Parent = toastHolder
end

local TOAST_COLORS = { success = T.Green, error = T.Red, cash = T.Gold, info = T.Blue }

local function toast(text, kind)
	if type(text) ~= "string" or text == "" then
		return
	end
	local t = frame({ Parent = toastHolder, BackgroundColor3 = T.Bg, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 0.1 })
	corner(t, 10)
	stroke(t, TOAST_COLORS[kind] or T.Blue, 2)
	local l = label({ Parent = t, Text = text, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.new(0, 8, 0, 4), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 17 })
	local children = toastHolder:GetChildren()
	local count = 0
	for _, c in ipairs(children) do
		if c:IsA("Frame") then
			count += 1
		end
	end
	if count > 5 then
		for _, c in ipairs(children) do
			if c:IsA("Frame") and c ~= t then
				c:Destroy()
				break
			end
		end
	end
	task.delay(3.5, function()
		if t.Parent then
			TweenService:Create(t, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			task.wait(0.45)
			t:Destroy()
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
local hud = frame({
	Parent = gui,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.new(0, 470, 0, 74),
})
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = hud
end

local function chip(width, color, order)
	local c = frame({ Parent = hud, BackgroundColor3 = T.Bg, BackgroundTransparency = 0.1, Size = UDim2.new(0, width, 0, 46), LayoutOrder = order })
	corner(c, 12)
	stroke(c, color, 2)
	local main = label({ Parent = c, Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 0, 2), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextColor3 = color, MaxText = 24 })
	local sub = label({ Parent = c, Size = UDim2.new(1, -12, 0, 14), Position = UDim2.new(0, 6, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.Sub, MaxText = 12 })
	return main, sub
end

local cashLabel, incomeLabel = chip(200, T.Green, 1)
local trophyLabel, trophySub = chip(110, T.Gold, 2)
local seasonLabel, seasonSub = chip(130, T.Blue, 3)
trophySub.Text = "trophies"

local function updateHud()
	cashLabel.Text = Config.Money(cash())
	if State then
		incomeLabel.Text = "robots +" .. Config.Money(State.RobotIncome) .. "/s"
		trophyLabel.Text = "🏆 " .. Config.Format(State.Trophies)
		seasonLabel.Text = "Season " .. State.Season
		seasonSub.Text = "x" .. string.format("%.1f", State.Multiplier) .. " cash"
	end
end

---------------------------------------------------------------------
-- Panels
---------------------------------------------------------------------
local panels = {}
local openName = nil

local panelFrame = frame({
	Parent = gui,
	BackgroundColor3 = T.Panel,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 30, 0.53, 0),
	Size = UDim2.new(0.7, 0, 0.72, 0),
	Visible = false,
})
corner(panelFrame, 14)
stroke(panelFrame, T.Red, 3)
do
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(780, 540)
	c.MinSize = Vector2.new(300, 240)
	c.Parent = panelFrame
end
local panelTitle = label({ Parent = panelFrame, Size = UDim2.new(1, -70, 0, 40), Position = UDim2.new(0, 14, 0, 6), Font = Enum.Font.GothamBlack, MaxText = 26 })
local panelContent = frame({ Parent = panelFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 1, -60) })

local function closePanel()
	panelFrame.Visible = false
	openName = nil
end

button({ Parent = panelFrame, Text = "X", BackgroundColor3 = T.Red, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.new(0, 36, 0, 36) }, closePanel)

local function renderOpen()
	if not openName or not panelFrame.Visible then
		return
	end
	local panel = panels[openName]
	-- remember scroll position of the list so re-renders don't jump
	local savedScroll = {}
	for _, d in ipairs(panelContent:GetDescendants()) do
		if d:IsA("ScrollingFrame") then
			savedScroll[d.Name] = d.CanvasPosition
		end
	end
	panelContent:ClearAllChildren()
	panelTitle.Text = panel.Title
	panel.Render(panelContent)
	task.defer(function()
		for _, d in ipairs(panelContent:GetDescendants()) do
			if d:IsA("ScrollingFrame") and savedScroll[d.Name] then
				d.CanvasPosition = savedScroll[d.Name]
			end
		end
	end)
end

local function openPanel(name)
	if openName == name and panelFrame.Visible then
		closePanel()
		return
	end
	openName = name
	panelFrame.Visible = true
	renderOpen()
end

local function message(parent, text)
	label({ Parent = parent, Text = text, Size = UDim2.new(1, -20, 0, 120), Position = UDim2.new(0, 10, 0.3, 0), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.Sub, MaxText = 22 })
end

---------------------------------------------------------------------
-- Robot Lab
---------------------------------------------------------------------
local labSlot = "Drivetrain"

local function moduleStatLine(def)
	local parts = {}
	if (def.Speed or 0) > 0 then
		table.insert(parts, "SPD +" .. def.Speed)
	end
	if (def.Power or 0) > 0 then
		table.insert(parts, "PWR +" .. def.Power)
	end
	if (def.Control or 0) > 0 then
		table.insert(parts, "CTL +" .. def.Control)
	end
	if (def.Scoring or 0) > 0 then
		table.insert(parts, "SCR +" .. def.Scoring)
	end
	if def.Slot == "Intake" then
		table.insert(parts, "holds " .. def.Capacity)
	elseif def.Slot == "Lift" then
		table.insert(parts, def.Points .. " pts/ball")
	elseif def.Slot == "Brain" then
		table.insert(parts, "auton +" .. def.Auton)
	elseif def.Strafe then
		table.insert(parts, "STRAFE")
	end
	return table.concat(parts, "  •  ")
end

panels.Lab = {
	Title = "🤖 Robot Lab",
	Render = function(content)
		if not State then
			return
		end
		if not State.Purchased.assembly then
			message(content, "Buy the Robot Assembly Station in your workshop to unlock the Robot Lab!")
			return
		end
		local left = frame({ Parent = content, BackgroundTransparency = 1, Size = UDim2.new(0.62, -6, 1, 0) })
		local right = frame({ Parent = content, BackgroundColor3 = T.Bg, Position = UDim2.new(0.62, 6, 0, 0), Size = UDim2.new(0.38, -6, 1, 0) })
		corner(right, 10)
		padding(right, 10)

		-- slot tabs
		for i, slot in ipairs(Config.ModuleSlots) do
			local info = Config.SlotInfo[slot]
			button({
				Parent = left,
				Text = info.Icon .. " " .. slot,
				BackgroundColor3 = slot == labSlot and T.Red or T.Gray,
				Position = UDim2.new((i - 1) / 4, 2, 0, 0),
				Size = UDim2.new(0.25, -4, 0, 34),
				MaxText = 14,
			}, function()
				labSlot = slot
				renderOpen()
			end)
		end
		label({ Parent = left, Text = Config.SlotInfo[labSlot].Desc, Position = UDim2.new(0, 4, 0, 38), Size = UDim2.new(1, -8, 0, 18), TextColor3 = T.Sub, MaxText = 13 })

		local scroll = list({ Parent = left, Name = "Modules", Position = UDim2.new(0, 0, 0, 60), Size = UDim2.new(1, 0, 1, -60) })
		local money = cash()
		for index, def in ipairs(Config.Modules[labSlot]) do
			local r = row(scroll, 62, index)
			label({ Parent = r, Text = def.Name, Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(0.65, -10, 0, 22), Font = Enum.Font.GothamBlack, MaxText = 17 })
			label({ Parent = r, Text = moduleStatLine(def), Position = UDim2.new(0, 10, 0, 26), Size = UDim2.new(0.65, -10, 0, 16), TextColor3 = T.Gold, MaxText = 13 })
			label({ Parent = r, Text = def.Desc or "", Position = UDim2.new(0, 10, 0, 42), Size = UDim2.new(0.65, -10, 0, 15), TextColor3 = T.Sub, MaxText = 12 })

			local owned = State.Modules[def.Id] == true
			local equipped = State.Loadout[labSlot] == def.Id
			local locked = (def.Season or 0) > State.Season
			local text, color, onClick
			if equipped then
				text, color = "EQUIPPED", T.Gray
			elseif owned then
				text, color = "EQUIP", T.Blue
				onClick = function()
					act("EquipModule", def.Id)
				end
			elseif locked then
				text, color = "SEASON " .. def.Season, T.Gray
			else
				text = "UNLOCK " .. Config.Money(def.Cost)
				color = money >= def.Cost and T.Green or Color3.fromRGB(140, 60, 60)
				onClick = function()
					act("UnlockModule", def.Id)
				end
			end
			button({ Parent = r, Text = text, BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.33, -8, 0, 40), MaxText = 14 }, onClick)
		end

		-- design summary
		local stats = Config.GetRobotStats(State.Loadout)
		label({ Parent = right, Text = "CURRENT DESIGN", Size = UDim2.new(1, 0, 0, 20), TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Center, MaxText = 14 })
		label({ Parent = right, Text = "Rating " .. stats.Rating, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 34), Font = Enum.Font.GothamBlack, TextColor3 = T.Gold, TextXAlignment = Enum.TextXAlignment.Center, MaxText = 30 })
		local lines = {
			"⚡ Speed " .. stats.Speed .. "    💪 Power " .. stats.Power,
			"🎯 Control " .. stats.Control .. "    🏀 Scoring " .. stats.Scoring,
			"Holds " .. stats.Capacity .. " balls • " .. stats.PointsPerBall .. " pts each",
			"Auton bonus +" .. stats.Auton .. (stats.Strafe and " • Strafe ✔" or ""),
			"Income in a bay: +" .. Config.Money(stats.Income * State.Multiplier) .. "/s",
			"Bays used: " .. #State.Garage .. " / " .. State.GarageSlots,
		}
		for i, text in ipairs(lines) do
			label({ Parent = right, Text = text, Position = UDim2.new(0, 0, 0, 60 + (i - 1) * 22), Size = UDim2.new(1, 0, 0, 20), MaxText = 14 })
		end
		local full = #State.Garage >= State.GarageSlots
		button({
			Parent = right,
			Text = full and "BAYS FULL" or ("🔧 BUILD ROBOT  " .. Config.Money(stats.BuildCost)),
			BackgroundColor3 = full and T.Gray or (money >= stats.BuildCost and T.Green or Color3.fromRGB(140, 60, 60)),
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 48),
			MaxText = 18,
		}, function()
			act("BuildRobot")
		end)
	end,
}

---------------------------------------------------------------------
-- Garage
---------------------------------------------------------------------
local scrapConfirm = nil

panels.Garage = {
	Title = "🏠 Robot Garage",
	Render = function(content)
		if not State then
			return
		end
		if State.GarageSlots == 0 then
			message(content, "Buy the Robot Assembly Station to get your first robot bay!")
			return
		end
		label({ Parent = content, Text = "Robots in bays earn cash every second. ⭐ = your competition & driving robot.", Size = UDim2.new(1, 0, 0, 20), TextColor3 = T.Sub, MaxText = 14 })
		local scroll = list({ Parent = content, Name = "Robots", Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 1, -26) })
		for i = 1, State.GarageSlots do
			local robot = State.Garage[i]
			local r = row(scroll, 66, i)
			if robot then
				local stats, defs = Config.GetRobotStats(robot)
				local active = State.Active == i
				label({ Parent = r, Text = (active and "⭐ " or "") .. "Robot #" .. i .. "  •  Rating " .. stats.Rating, Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(0.55, 0, 0, 24), Font = Enum.Font.GothamBlack, MaxText = 18 })
				label({ Parent = r, Text = "+" .. Config.Money(stats.Income * State.Multiplier) .. "/s", Position = UDim2.new(0, 10, 0, 28), Size = UDim2.new(0.55, 0, 0, 16), TextColor3 = T.Green, MaxText = 14 })
				label({ Parent = r, Text = defs.Drivetrain.Name .. " / " .. defs.Intake.Name .. " / " .. defs.Lift.Name .. " / " .. defs.Brain.Name, Position = UDim2.new(0, 10, 0, 45), Size = UDim2.new(0.6, 0, 0, 16), TextColor3 = T.Sub, MaxText = 11 })
				button({ Parent = r, Text = active and "ACTIVE" or "SET ACTIVE", BackgroundColor3 = active and T.Gold or T.Blue, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -150, 0.5, 0), Size = UDim2.new(0, 120, 0, 40) }, function()
					if not active then
						act("SetActive", i)
					end
				end)
				local refund = math.floor(stats.BuildCost * Config.ScrapRefund)
				local confirming = scrapConfirm == i
				button({ Parent = r, Text = confirming and "CONFIRM?" or ("SCRAP +" .. Config.Money(refund)), BackgroundColor3 = T.Red, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 134, 0, 40), MaxText = 14 }, function()
					if scrapConfirm == i then
						scrapConfirm = nil
						act("ScrapRobot", i)
					else
						scrapConfirm = i
						renderOpen()
						task.delay(3, function()
							if scrapConfirm == i then
								scrapConfirm = nil
								renderOpen()
							end
						end)
					end
				end)
			else
				label({ Parent = r, Text = "Bay #" .. i .. " is empty - build a robot in the Robot Lab", Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), TextColor3 = T.Sub, MaxText = 16 })
			end
		end
	end,
}

---------------------------------------------------------------------
-- Competitions
---------------------------------------------------------------------
local resultFrame = frame({ Parent = gui, BackgroundColor3 = T.Bg, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 460, 0, 330), Visible = false, ZIndex = 5 })
corner(resultFrame, 14)
stroke(resultFrame, T.Gold, 3)
local resultTitle = label({ Parent = resultFrame, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 10), Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.Gold, MaxText = 26, ZIndex = 5 })
local resultLines = {}
for i = 1, 4 do
	resultLines[i] = label({ Parent = resultFrame, Size = UDim2.new(1, -30, 0, 32), Position = UDim2.new(0, 15, 0, 58 + (i - 1) * 40), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 18, ZIndex = 5 })
end
local resultClose = button({ Parent = resultFrame, Text = "OK", BackgroundColor3 = T.Green, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(0, 160, 0, 42), ZIndex = 5 }, function()
	resultFrame.Visible = false
end)
local resultToken = 0

local function showCompResult(result)
	resultToken += 1
	local token = resultToken
	resultFrame.Visible = true
	resultClose.Visible = false
	resultTitle.Text = "🏆 " .. result.Competition
	for _, l in ipairs(resultLines) do
		l.Text = ""
		l.TextColor3 = T.Text
	end
	task.spawn(function()
		for i, r in ipairs(result.Rounds) do
			task.wait(0.8)
			if token ~= resultToken then
				return
			end
			resultLines[i].Text = string.format("%s vs %s:  %d - %d  %s", r.Round, r.OppTeam, r.You, r.Opp, r.Won and "✅" or "❌")
			resultLines[i].TextColor3 = r.Won and T.Green or T.Red
		end
		task.wait(0.8)
		if token ~= resultToken then
			return
		end
		local final
		if result.Champion then
			final = "🏆 CHAMPIONS! +" .. Config.Money(result.Prize) .. "  +" .. result.Trophies .. " trophies"
		elseif result.Reached == 2 then
			final = "🥈 Finalist! +" .. Config.Money(result.Prize) .. "  +" .. result.Trophies .. " trophies"
		elseif result.Reached == 1 then
			final = "🥉 Semifinalist! +" .. Config.Money(result.Prize)
		else
			final = "Knocked out early. Upgrade your robot and try again!"
		end
		resultLines[4].Text = final
		resultLines[4].TextColor3 = T.Gold
		resultClose.Visible = true
	end)
end

panels.Compete = {
	Title = "🏆 Competitions",
	Render = function(content)
		if not State then
			return
		end
		local robot = State.Garage[State.Active]
		local rating = robot and Config.GetRobotStats(robot).Rating or 0
		label({
			Parent = content,
			Text = robot and ("Competing with ⭐ Robot #" .. State.Active .. "  •  Rating " .. rating) or "Build a robot in the Robot Lab to compete!",
			Size = UDim2.new(1, 0, 0, 22),
			TextColor3 = robot and T.Gold or T.Red,
			MaxText = 16,
		})
		local scroll = list({ Parent = content, Name = "Comps", Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 1, -28) })
		local money = cash()
		for index, comp in ipairs(Config.Competitions) do
			local r = row(scroll, 62, index)
			label({ Parent = r, Text = comp.Name, Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(0.62, 0, 0, 24), Font = Enum.Font.GothamBlack, MaxText = 18 })
			label({ Parent = r, Text = "Needs rating " .. comp.MinRating .. "  •  Entry " .. (comp.Fee > 0 and Config.Money(comp.Fee) or "FREE"), Position = UDim2.new(0, 10, 0, 28), Size = UDim2.new(0.62, 0, 0, 14), TextColor3 = T.Sub, MaxText = 12 })
			label({ Parent = r, Text = "Win: " .. Config.Money(comp.Prize * State.Multiplier) .. " + " .. comp.Trophies .. " 🏆", Position = UDim2.new(0, 10, 0, 43), Size = UDim2.new(0.62, 0, 0, 15), TextColor3 = T.Gold, MaxText = 13 })

			local remaining = math.ceil((cooldownEnds[comp.Id] or 0) - os.clock())
			local text, color, onClick
			if not robot or rating < comp.MinRating then
				text, color = "🔒 LOCKED", T.Gray
			elseif remaining > 0 then
				text, color = "⏳ " .. remaining .. "s", T.Gray
			elseif money < comp.Fee then
				text, color = "NEED CASH", Color3.fromRGB(140, 60, 60)
			else
				text, color = "ENTER", T.Green
				onClick = function()
					local ok, result = request(RequestRemote, "EnterCompetition", comp.Id)
					if ok and type(result) == "table" then
						cooldownEnds[comp.Id] = os.clock() + comp.Cooldown
						showCompResult(result)
					elseif type(result) == "string" then
						toast(result, "error")
					end
				end
			end
			button({ Parent = r, Text = text, BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.3, -8, 0, 40) }, onClick)
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
		closePanel()
	end
	task.defer(renderOpen)
end

panels.Drive = {
	Title = "🎮 Drive Your Robot",
	Render = function(content)
		if not State then
			return
		end
		local robot = State.Garage[State.Active]
		local driving = player:GetAttribute("Driving") == true
		local inQueue = player:GetAttribute("InQueue") == true
		local queueSize = Remotes:GetAttribute("QueueSize") or 0
		local matchLive = Remotes:GetAttribute("MatchLive") == true

		local info = robot and ("Driving ⭐ Robot #" .. State.Active .. " (Rating " .. Config.GetRobotStats(robot).Rating .. ")") or "Build a robot in the Robot Lab first!"
		label({ Parent = content, Text = info, Size = UDim2.new(1, 0, 0, 24), TextColor3 = robot and T.Gold or T.Red, MaxText = 17 })

		local help = {
			"W / S - drive      A / D - turn",
			"Q / E - strafe (Mecanum & X-Drive only)",
			"Your intake grabs balls automatically",
			"F (or SCORE) inside a goal zone - score all held balls",
			"Jump - leave the robot (forfeits a ranked match!)",
		}
		for i, text in ipairs(help) do
			label({ Parent = content, Text = "• " .. text, Position = UDim2.new(0, 0, 0, 30 + (i - 1) * 22), Size = UDim2.new(1, 0, 0, 20), TextColor3 = T.Sub, MaxText = 14 })
		end

		local y = 150
		if driving then
			button({ Parent = content, Text = "🛑 STOP DRIVING", BackgroundColor3 = T.Red, Position = UDim2.new(0, 0, 0, y), Size = UDim2.new(1, 0, 0, 50), MaxText = 20 }, function()
				arena("Stop")
			end)
			return
		end
		button({ Parent = content, Text = "🎮 PRACTICE DRIVE  (earn cash per point)", BackgroundColor3 = robot and T.Blue or T.Gray, Position = UDim2.new(0, 0, 0, y), Size = UDim2.new(1, 0, 0, 50), MaxText = 18 }, function()
			arena("Practice")
		end)
		button({
			Parent = content,
			Text = inQueue and ("❌ LEAVE RANKED QUEUE  (" .. queueSize .. " waiting)") or ("⚔️ JOIN RANKED 1v1  (" .. queueSize .. " waiting)"),
			BackgroundColor3 = robot and (inQueue and T.Red or T.Green) or T.Gray,
			Position = UDim2.new(0, 0, 0, y + 60),
			Size = UDim2.new(1, 0, 0, 50),
			MaxText = 18,
		}, function()
			arena("Queue")
		end)
		label({
			Parent = content,
			Text = (matchLive and "A ranked match is in progress - watch at the Ranked Arena! " or "")
				.. "Win: +" .. Config.Match.WinTrophies .. " trophies + cash. Your Brain gives free auton points at the start.",
			Position = UDim2.new(0, 0, 0, y + 118),
			Size = UDim2.new(1, 0, 0, 40),
			TextColor3 = T.Sub,
			MaxText = 14,
		})
	end,
}

---------------------------------------------------------------------
-- Season (rebirth) + stats
---------------------------------------------------------------------
local seasonConfirm = false

panels.Season = {
	Title = "🔄 New Season",
	Render = function(content)
		if not State then
			return
		end
		local cost = Config.GetSeasonCost(State.Season)
		local money = cash()
		local nowMult = Config.GetMultiplier(State.Season, false)
		local nextMult = Config.GetMultiplier(State.Season + 1, false)
		label({ Parent = content, Text = "Season " .. State.Season .. "  →  Season " .. (State.Season + 1), Size = UDim2.new(1, 0, 0, 32), Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.Gold, MaxText = 26 })
		label({ Parent = content, Text = string.format("Permanent cash multiplier: x%.1f  →  x%.1f", nowMult, nextMult), Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 17 })
		label({ Parent = content, Text = "Resets: cash, workshop, robot parts & garage.  Keeps: trophies & stats.  Unlocks season-only parts!", Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, 0, 0, 36), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.Sub, MaxText = 14 })

		local bar = frame({ Parent = content, BackgroundColor3 = T.Bg, Position = UDim2.new(0, 0, 0, 104), Size = UDim2.new(1, 0, 0, 26) })
		corner(bar, 8)
		local fill = frame({ Parent = bar, BackgroundColor3 = T.Green, Size = UDim2.new(math.clamp(money / cost, 0, 1), 0, 1, 0) })
		corner(fill, 8)
		label({ Parent = bar, Text = Config.Money(money) .. " / " .. Config.Money(cost), Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 15 })

		local canAfford = money >= cost
		button({
			Parent = content,
			Text = seasonConfirm and "⚠️ CLICK AGAIN TO CONFIRM" or ("START SEASON " .. (State.Season + 1)),
			BackgroundColor3 = canAfford and (seasonConfirm and T.Red or T.Green) or T.Gray,
			Position = UDim2.new(0.15, 0, 0, 138),
			Size = UDim2.new(0.7, 0, 0, 46),
			MaxText = 18,
		}, function()
			if not canAfford then
				toast("You need " .. Config.Money(cost - money) .. " more", "error")
				return
			end
			if seasonConfirm then
				seasonConfirm = false
				act("Rebirth")
			else
				seasonConfirm = true
				renderOpen()
				task.delay(3, function()
					seasonConfirm = false
					renderOpen()
				end)
			end
		end)

		local s = State.Stats
		local statsText = string.format(
			"📊 Competitions won: %d / %d    Ranked: %d wins / %d matches\nBalls scored: %d    Robots built: %d    Lifetime cash: %s",
			s.CompWins, s.CompsEntered, s.MatchesWon, s.MatchesPlayed, s.BallsScored, s.RobotsBuilt, Config.Money(s.TotalEarned)
		)
		label({ Parent = content, Text = statsText, Position = UDim2.new(0, 0, 0, 196), Size = UDim2.new(1, 0, 0, 44), TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Center, MaxText = 14 })
	end,
}

---------------------------------------------------------------------
-- Shop
---------------------------------------------------------------------
panels.Shop = {
	Title = "🛒 Shop",
	Render = function(content)
		if not State then
			return
		end
		local scroll = list({ Parent = content, Name = "Passes", Size = UDim2.new(1, 0, 1, 0) })
		for index, pass in ipairs(Config.GamePasses) do
			local r = row(scroll, 62, index)
			label({ Parent = r, Text = pass.Icon .. "  " .. pass.Name, Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(0.65, 0, 0, 26), Font = Enum.Font.GothamBlack, MaxText = 19 })
			label({ Parent = r, Text = pass.Desc, Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(0.65, 0, 0, 20), TextColor3 = T.Sub, MaxText = 14 })
			local owned = State.Passes[pass.Key] == true
			button({ Parent = r, Text = owned and "OWNED ✔" or "BUY", BackgroundColor3 = owned and T.Gray or T.Gold, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.28, 0, 0, 40) }, function()
				if not owned then
					act("PromptPass", pass.Key)
				end
			end)
		end
	end,
}

---------------------------------------------------------------------
-- Side menu
---------------------------------------------------------------------
local menu = frame({ Parent = gui, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.new(0, 72, 0, 6 * 70) })
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = menu
end

local MENU = {
	{ "Lab", "🤖", "Lab", T.Red },
	{ "Garage", "🏠", "Garage", T.Blue },
	{ "Compete", "🏆", "Compete", T.Gold },
	{ "Drive", "🎮", "Drive", T.Green },
	{ "Season", "🔄", "Season", Color3.fromRGB(150, 80, 220) },
	{ "Shop", "🛒", "Shop", Color3.fromRGB(240, 120, 30) },
}
for i, entry in ipairs(MENU) do
	local b = button({ Parent = menu, Text = "", BackgroundColor3 = T.Bg, Size = UDim2.new(0, 64, 0, 64), LayoutOrder = i }, function()
		openPanel(entry[1])
	end)
	stroke(b, entry[4], 2)
	label({ Parent = b, Text = entry[2], Size = UDim2.new(1, 0, 0.62, 0), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 30 })
	label({ Parent = b, Text = entry[3], Position = UDim2.new(0, 0, 0.62, 0), Size = UDim2.new(1, 0, 0.38, 0), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = entry[4], MaxText = 12 })
end

---------------------------------------------------------------------
-- Arena HUD
---------------------------------------------------------------------
local arenaTop = frame({ Parent = gui, BackgroundColor3 = T.Bg, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 86), Size = UDim2.new(0, 440, 0, 60), Visible = false })
corner(arenaTop, 12)
local redBox = frame({ Parent = arenaTop, BackgroundColor3 = T.Red, Size = UDim2.new(0.33, 0, 1, 0) })
corner(redBox, 12)
local redName = label({ Parent = redBox, Size = UDim2.new(1, -8, 0.35, 0), Position = UDim2.new(0, 4, 0, 2), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 13 })
local redScore = label({ Parent = redBox, Size = UDim2.new(1, -8, 0.6, 0), Position = UDim2.new(0, 4, 0.38, 0), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, MaxText = 30 })
local blueBox = frame({ Parent = arenaTop, BackgroundColor3 = T.Blue, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.33, 0, 1, 0) })
corner(blueBox, 12)
local blueName = label({ Parent = blueBox, Size = UDim2.new(1, -8, 0.35, 0), Position = UDim2.new(0, 4, 0, 2), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 13 })
local blueScore = label({ Parent = blueBox, Size = UDim2.new(1, -8, 0.6, 0), Position = UDim2.new(0, 4, 0.38, 0), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, MaxText = 30 })
local centerText = label({ Parent = arenaTop, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.new(0.32, 0, 1, -8), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, MaxText = 24 })

local heldFrame = frame({ Parent = gui, BackgroundColor3 = T.Bg, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.new(0, 420, 0, 60), Visible = false })
corner(heldFrame, 12)
stroke(heldFrame, T.Green, 2)
local heldLabel = label({ Parent = heldFrame, Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 2), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, MaxText = 22 })
local hintLabel = label({ Parent = heldFrame, Size = UDim2.new(1, -16, 0, 22), Position = UDim2.new(0, 8, 0, 34), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.Sub, MaxText = 13 })

local exitButton = button({ Parent = gui, Text = "EXIT ROBOT", BackgroundColor3 = T.Red, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 90, 1, -40), Size = UDim2.new(0, 120, 0, 40), Visible = false }, function()
	arena("Stop")
end)

local countdown = label({ Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.4, 0), Size = UDim2.new(0, 400, 0, 120), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextColor3 = T.Gold, TextStrokeTransparency = 0, MaxText = 90, Visible = false })

local matchResult = frame({ Parent = gui, BackgroundColor3 = T.Bg, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0), Size = UDim2.new(0, 420, 0, 220), Visible = false, ZIndex = 6 })
corner(matchResult, 14)
local matchResultStroke = stroke(matchResult, T.Gold, 3)
local matchResultTitle = label({ Parent = matchResult, Size = UDim2.new(1, -20, 0, 60), Position = UDim2.new(0, 10, 0, 10), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, MaxText = 44, ZIndex = 6 })
local matchResultScore = label({ Parent = matchResult, Size = UDim2.new(1, -20, 0, 50), Position = UDim2.new(0, 10, 0, 76), TextXAlignment = Enum.TextXAlignment.Center, MaxText = 22, ZIndex = 6 })
button({ Parent = matchResult, Text = "OK", BackgroundColor3 = T.Green, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(0, 150, 0, 42), ZIndex = 6 }, function()
	matchResult.Visible = false
end)

local function renderArena()
	local mode = Arena.Mode
	local driving = mode == "Practice" or mode == "Ranked"
	heldFrame.Visible = driving
	exitButton.Visible = driving
	arenaTop.Visible = false
	countdown.Visible = false

	if driving then
		menu.Visible = false
		closePanel()
		heldLabel.Text = string.format("🟢 Holding %d / %d balls  •  %d pts each", Arena.Held or 0, Arena.Capacity or 1, Arena.PointsPerBall or 1)
		local strafeHint = Arena.Strafe and "  •  Q/E strafe" or ""
		hintLabel.Text = "WASD drive" .. strafeHint .. "  •  F score in goal  •  Jump to exit"
	else
		menu.Visible = true
	end

	if mode == "Practice" then
		arenaTop.Visible = true
		redName.Text, redScore.Text = "PRACTICE", ""
		blueName.Text, blueScore.Text = "POINTS", tostring(Arena.Points or 0)
		centerText.Text = "Score in any goal"
	elseif mode == "Ranked" and Arena.Match then
		local m = Arena.Match
		arenaTop.Visible = true
		redName.Text = m.RedName .. (m.Side == "Red" and " (YOU)" or "")
		blueName.Text = m.BlueName .. (m.Side == "Blue" and " (YOU)" or "")
		redScore.Text = tostring(m.Red)
		blueScore.Text = tostring(m.Blue)
		if m.State == "Countdown" then
			centerText.Text = "GET READY"
			countdown.Visible = true
			countdown.Text = tostring(m.Countdown or "")
		else
			centerText.Text = string.format("%d:%02d", math.floor((m.Time or 0) / 60), (m.Time or 0) % 60)
		end
		hintLabel.Text = "Score in the " .. string.upper(m.Side or "?") .. " goal  •  F to score  •  Jumping out forfeits!"
	elseif mode == "Result" then
		matchResult.Visible = true
		local titles = { Win = "🏆 VICTORY!", Loss = "DEFEAT", Tie = "TIE GAME", Forfeit = "FORFEIT" }
		local colors = { Win = T.Gold, Loss = T.Red, Tie = T.Blue, Forfeit = T.Red }
		matchResultTitle.Text = titles[Arena.Result] or "MATCH OVER"
		matchResultTitle.TextColor3 = colors[Arena.Result] or T.Text
		matchResultStroke.Color = colors[Arena.Result] or T.Gold
		matchResultScore.Text = string.format("%s  %d  -  %d  %s", Arena.RedName or "Red", Arena.Red or 0, Arena.Blue or 0, Arena.BlueName or "Blue")
		Arena = { Mode = "None" }
	end
end

ArenaState.OnClientEvent:Connect(function(info)
	Arena = info or { Mode = "None" }
	renderArena()
end)

---------------------------------------------------------------------
-- Data + refresh wiring
---------------------------------------------------------------------
local dirty = false

DataUpdate.OnClientEvent:Connect(function(snapshot)
	State = snapshot
	for compId, remaining in pairs(snapshot.Cooldowns or {}) do
		cooldownEnds[compId] = os.clock() + remaining
	end
	updateHud()
	renderOpen()
end)

OpenUIRemote.OnClientEvent:Connect(function(name)
	if panels[name] and Arena.Mode ~= "Practice" and Arena.Mode ~= "Ranked" then
		if openName ~= name then
			openPanel(name)
		end
	end
end)

task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	local cashValue = stats:WaitForChild("Cash")
	cashValue.Changed:Connect(function()
		updateHud()
		dirty = true
	end)
	updateHud()
end)

player:GetAttributeChangedSignal("InQueue"):Connect(renderOpen)
player:GetAttributeChangedSignal("Driving"):Connect(renderOpen)
Remotes:GetAttributeChangedSignal("QueueSize"):Connect(renderOpen)

-- re-render the open panel once per second when cash changed (affordability)
-- and always for the competition cooldown timers
task.spawn(function()
	while true do
		task.wait(1)
		if openName == "Compete" or (dirty and (openName == "Lab" or openName == "Season")) then
			renderOpen()
		end
		dirty = false
	end
end)

-- initial data
task.spawn(function()
	for _ = 1, 20 do
		local ok, snapshot = pcall(RequestRemote.InvokeServer, RequestRemote, "GetData")
		if ok and type(snapshot) == "table" then
			State = snapshot
			updateHud()
			return
		end
		task.wait(1)
	end
end)

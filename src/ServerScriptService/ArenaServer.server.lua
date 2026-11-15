--[[
	ArenaServer (Script)  ->  ServerScriptService.ArenaServer

	Driving your ACTIVE robot:
	  * Practice field: free drive, score balls for cash
	  * Ranked 1v1: queue up, auton bonus, 90s match, trophies + cash
	Balls are collected automatically by your intake; press F (or the
	SCORE button) near a goal to score everything you're holding.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local RobotBuilder = require(ServerScriptService:WaitForChild("RobotBuilder"))
local WorldBuilder = require(ServerScriptService:WaitForChild("WorldBuilder"))

local Remotes = DataManager.Remotes
local World = WorldBuilder.GetWorld()
local Practice = World.Fields.Practice
local Ranked = World.Fields.Ranked

local TEAM_COLORS = {
	Red = Color3.fromRGB(220, 45, 50),
	Blue = Color3.fromRGB(40, 110, 230),
}

local sessions = {} -- [player] = session
local queue = {} -- array of players waiting for ranked
local match = nil -- current ranked match

local finishMatch, tryStartMatch -- forward declarations

local function notify(player, text, kind)
	DataManager.Notify(player, text, kind)
end

---------------------------------------------------------------------
-- Balls
---------------------------------------------------------------------
local function spawnBall(field)
	local half = field.Size / 2 - 6
	local pos = Vector3.new(0, 0, 0)
	for _ = 1, 15 do
		local x = (math.random() * 2 - 1) * half
		local z = (math.random() * 2 - 1) * half
		-- keep balls out of the goal zones
		if math.abs(x) < field.Size / 2 - 18 or math.abs(z) > 16 then
			pos = Vector3.new(x, 0, z)
			break
		end
	end
	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * Config.Field.BallSize
	ball.Color = Config.Field.BallColor
	ball.Material = Enum.Material.SmoothPlastic
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.5, 0.3, 1, 1)
	ball.CFrame = field.CFrame * CFrame.new(pos + Vector3.new(0, 3, 0))
	ball.Parent = field.Balls
end

local function fillBalls(field, count)
	local current = #field.Balls:GetChildren()
	for _ = current + 1, count do
		spawnBall(field)
	end
end

local function clearBalls(field)
	field.Balls:ClearAllChildren()
end

local function ballTarget(field)
	return field == Ranked and Config.Match.Balls or Config.Practice.Balls
end

---------------------------------------------------------------------
-- State pushed to the driving player's HUD
---------------------------------------------------------------------
local function matchInfo(forPlayer)
	if not match then
		return nil
	end
	return {
		State = match.State,
		Countdown = match.Countdown,
		Time = match.TimeLeft,
		Red = match.Scores.Red,
		Blue = match.Scores.Blue,
		RedName = match.Red and match.Red.DisplayName or "?",
		BlueName = match.Blue and match.Blue.DisplayName or "?",
		Side = (forPlayer == match.Red and "Red") or (forPlayer == match.Blue and "Blue") or nil,
	}
end

local function sendState(player)
	local s = sessions[player]
	if not s then
		Remotes.ArenaState:FireClient(player, { Mode = "None" })
		return
	end
	Remotes.ArenaState:FireClient(player, {
		Mode = s.Mode,
		Held = s.Held,
		Capacity = s.Stats.Capacity,
		Points = s.Points,
		PointsPerBall = s.Stats.PointsPerBall,
		Strafe = s.Stats.Strafe,
		Side = s.Side,
		Match = s.Mode == "Ranked" and matchInfo(player) or nil,
	})
end

local function updateQueueAttributes()
	Remotes.Folder:SetAttribute("QueueSize", #queue)
	Remotes.Folder:SetAttribute("MatchLive", match ~= nil)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("InQueue", table.find(queue, player) ~= nil)
	end
end

local function updateScoreboard()
	for _, labels in ipairs(Ranked.Scoreboard) do
		if match then
			labels.Red.Text = tostring(match.Scores.Red)
			labels.Blue.Text = tostring(match.Scores.Blue)
			if match.State == "Countdown" then
				labels.Status.Text = string.format("%s vs %s\nStarting in %d", match.Red.DisplayName, match.Blue.DisplayName, match.Countdown or 0)
			else
				labels.Status.Text = string.format("%s vs %s\n%d:%02d", match.Red.DisplayName, match.Blue.DisplayName, math.floor(match.TimeLeft / 60), match.TimeLeft % 60)
			end
		else
			labels.Red.Text = "0"
			labels.Blue.Text = "0"
			labels.Status.Text = #queue > 0 and (#queue .. " in queue...") or "WAITING FOR PLAYERS"
		end
	end
end

---------------------------------------------------------------------
-- Sessions (a player driving a robot)
---------------------------------------------------------------------
local function getHumanoid(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and character.PrimaryPart then
		return humanoid, character
	end
	return nil, nil
end

local function playerPlot(player)
	for _, plot in ipairs(World.Plots) do
		if plot.Owner == player then
			return plot
		end
	end
	return nil
end

local function sendHome(player, field)
	local _, character = getHumanoid(player)
	if not character then
		return
	end
	local plot = playerPlot(player)
	if plot then
		character:PivotTo(plot.SpawnCFrame)
	else
		character:PivotTo(field.ExitCFrame)
	end
end

local function endSession(player, teleport)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	s.Ended = true
	player:SetAttribute("Driving", false)
	for _, conn in ipairs(s.Connections) do
		conn:Disconnect()
	end
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.Sit = false
	end
	if s.Model then
		s.Model:Destroy()
	end
	if teleport then
		task.delay(0.1, function()
			if player.Parent then
				sendHome(player, s.Field)
			end
		end)
	end
	sendState(player)
	task.delay(2, function()
		fillBalls(s.Field, ballTarget(s.Field))
	end)
end

local function releaseRobot(s)
	if s.Ended or not s.Model.Parent then
		return
	end
	s.Frozen = false
	RobotBuilder.SetAnchored(s.Model, false)
	pcall(function()
		s.Root:SetNetworkOwner(s.Player)
	end)
end

local function onLeftRobot(s)
	if s.Ended then
		return
	end
	local player = s.Player
	if s.Mode == "Ranked" and match and (match.Red == player or match.Blue == player) then
		notify(player, "You left your robot - match forfeited!", "error")
		finishMatch(match, s.Side)
	else
		notify(player, "Practice over! You scored " .. s.Points .. " points.", "info")
		endSession(player, true)
	end
end

-- Spawns the player's active robot on a field and seats them in it.
local function startSession(player, field, mode, spawnCF, side)
	if sessions[player] then
		return false, "You're already driving!"
	end
	local data = DataManager.Get(player)
	local loadout = DataManager.GetActiveRobot(player)
	if not data or not loadout then
		return false, "Build a robot in the Robot Lab first!"
	end
	local humanoid, character = getHumanoid(player)
	if not humanoid then
		return false, "Respawn first!"
	end
	if humanoid.SeatPart then
		humanoid.Sit = false
	end

	local model, stats = RobotBuilder.Build(loadout, {
		Drive = true,
		TeamColor = side and TEAM_COLORS[side] or nil,
		Label = player.DisplayName,
		SubLabel = "Rating " .. Config.GetRobotStats(loadout).Rating,
	})
	model.Name = "Robot_" .. player.Name
	if DataManager.HasPass(player, "Turbo") then
		model:SetAttribute("MaxSpeed", stats.MaxSpeed * 1.15)
	end
	model:PivotTo(spawnCF * CFrame.new(0, 1.2, 0))
	model.Parent = field.Robots

	local seat = model:FindFirstChild("DriverSeat")
	local s = {
		Player = player,
		Model = model,
		Root = model.PrimaryPart,
		Seat = seat,
		Stats = stats,
		Field = field,
		Mode = mode,
		Side = side,
		Held = 0,
		Points = 0,
		Frozen = true,
		Connections = {},
	}
	sessions[player] = s
	player:SetAttribute("Driving", true)

	character:PivotTo(seat.CFrame * CFrame.new(0, 3, 0))
	seat:Sit(humanoid)

	task.delay(0.6, function()
		if s.Ended then
			return
		end
		if seat.Occupant ~= humanoid then
			seat:Sit(humanoid) -- retry once
		end
		table.insert(s.Connections, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant == nil then
				onLeftRobot(s)
			end
		end))
	end)
	table.insert(s.Connections, humanoid.Died:Connect(function()
		onLeftRobot(s)
	end))

	sendState(player)
	return true
end

---------------------------------------------------------------------
-- Practice
---------------------------------------------------------------------
local function startPractice(player)
	if match and (match.Red == player or match.Blue == player) then
		return false, "You're in a ranked match!"
	end
	local spawns = Practice.Spawns.List
	local spawnCF = spawns[math.random(1, #spawns)]
	local ok, err = startSession(player, Practice, "Practice", spawnCF, nil)
	if not ok then
		return false, err
	end
	fillBalls(Practice, Config.Practice.Balls)
	task.delay(0.8, function()
		local s = sessions[player]
		if s then
			releaseRobot(s)
		end
	end)
	return true, "Drive with WASD, Q/E strafe (holonomic), F to score near a goal. Jump to exit."
end

---------------------------------------------------------------------
-- Ranked matches
---------------------------------------------------------------------
local function broadcastMatch()
	if not match then
		return
	end
	for _, player in ipairs({ match.Red, match.Blue }) do
		if player and player.Parent then
			sendState(player)
		end
	end
	updateScoreboard()
end

local function giveRewards(player, result, opponentRating)
	local data = DataManager.Get(player)
	if not data then
		return
	end
	data.Stats.MatchesPlayed += 1
	if result == "Win" then
		data.Stats.MatchesWon += 1
		local cash = DataManager.AddCash(player, Config.Match.WinCashBase + opponentRating * Config.Match.WinCashPerRating, true)
		DataManager.AddTrophies(player, Config.Match.WinTrophies)
		notify(player, "🏆 VICTORY! +" .. Config.Money(cash) .. " and +" .. Config.Match.WinTrophies .. " trophies", "success")
	elseif result == "Tie" then
		local cash = DataManager.AddCash(player, Config.Match.LoseCash * 2, true)
		DataManager.AddTrophies(player, Config.Match.TieTrophies)
		notify(player, "Tie game! +" .. Config.Money(cash) .. " and +" .. Config.Match.TieTrophies .. " trophies", "info")
	elseif result == "Loss" then
		local cash = DataManager.AddCash(player, Config.Match.LoseCash, true)
		DataManager.AddTrophies(player, Config.Match.LoseTrophies)
		notify(player, "Defeat - good effort! +" .. Config.Money(cash) .. " and +" .. Config.Match.LoseTrophies .. " trophy", "info")
	end
	DataManager.MarkChanged(player)
end

function finishMatch(m, forfeitSide)
	if match ~= m then
		return
	end
	match = nil
	m.State = "Ended"

	local winner
	if forfeitSide then
		winner = forfeitSide == "Red" and "Blue" or "Red"
	elseif m.Scores.Red > m.Scores.Blue then
		winner = "Red"
	elseif m.Scores.Blue > m.Scores.Red then
		winner = "Blue"
	else
		winner = "Tie"
	end

	local ratings = {
		Red = m.Ratings.Red or 0,
		Blue = m.Ratings.Blue or 0,
	}
	for _, side in ipairs({ "Red", "Blue" }) do
		local player = m[side]
		local other = side == "Red" and "Blue" or "Red"
		if player and player.Parent then
			local result
			if winner == "Tie" then
				result = "Tie"
			elseif winner == side then
				result = "Win"
			elseif forfeitSide == side then
				result = "Forfeit"
			else
				result = "Loss"
			end
			giveRewards(player, result, ratings[other])
			Remotes.ArenaState:FireClient(player, {
				Mode = "Result",
				Result = result,
				Red = m.Scores.Red,
				Blue = m.Scores.Blue,
				RedName = m.Red.DisplayName,
				BlueName = m.Blue.DisplayName,
			})
			endSession(player, true)
		end
	end

	for _, labels in ipairs(Ranked.Scoreboard) do
		labels.Status.Text = winner == "Tie" and "TIE GAME!" or (string.upper(winner) .. " WINS!")
	end
	clearBalls(Ranked)
	updateQueueAttributes()
	task.delay(4, function()
		updateScoreboard()
	end)
	task.delay(5, function()
		-- try to start the next match
		if not match then
			tryStartMatch()
		end
	end)
end

local function runMatch(m)
	for i = Config.Match.Countdown, 1, -1 do
		if match ~= m then
			return
		end
		m.Countdown = i
		broadcastMatch()
		task.wait(1)
	end
	if match ~= m then
		return
	end

	-- autonomous bonus from each robot's Brain
	for _, side in ipairs({ "Red", "Blue" }) do
		local s = sessions[m[side]]
		if s then
			m.Scores[side] += s.Stats.Auton
			if s.Stats.Auton > 0 then
				notify(m[side], "🧠 Autonomous bonus: +" .. s.Stats.Auton .. " points!", "success")
			end
			releaseRobot(s)
		end
	end
	m.State = "Live"
	broadcastMatch()

	while match == m and m.TimeLeft > 0 do
		task.wait(1)
		if match ~= m then
			return
		end
		m.TimeLeft -= 1
		broadcastMatch()
	end
	if match == m then
		finishMatch(m, nil)
	end
end

function tryStartMatch()
	if match then
		return
	end
	-- drop anyone who can't play
	for i = #queue, 1, -1 do
		local p = queue[i]
		if not p.Parent or not DataManager.GetActiveRobot(p) or not getHumanoid(p) then
			table.remove(queue, i)
		end
	end
	if #queue < 2 then
		updateQueueAttributes()
		updateScoreboard()
		return
	end
	local red = table.remove(queue, 1)
	local blue = table.remove(queue, 1)
	for _, p in ipairs({ red, blue }) do
		if sessions[p] then
			endSession(p, false)
		end
	end

	local m = {
		Red = red,
		Blue = blue,
		Scores = { Red = 0, Blue = 0 },
		Ratings = {
			Red = Config.GetRobotStats(DataManager.GetActiveRobot(red)).Rating,
			Blue = Config.GetRobotStats(DataManager.GetActiveRobot(blue)).Rating,
		},
		State = "Countdown",
		Countdown = Config.Match.Countdown,
		TimeLeft = Config.Match.Duration,
	}
	match = m
	clearBalls(Ranked)
	fillBalls(Ranked, Config.Match.Balls)

	local okRed, errRed = startSession(red, Ranked, "Ranked", Ranked.Spawns.Red, "Red")
	local okBlue, errBlue = startSession(blue, Ranked, "Ranked", Ranked.Spawns.Blue, "Blue")
	if not okRed or not okBlue then
		match = nil
		for _, p in ipairs({ red, blue }) do
			endSession(p, true)
			notify(p, "Match cancelled: " .. tostring(errRed or errBlue), "error")
		end
		updateQueueAttributes()
		updateScoreboard()
		return
	end

	for _, p in ipairs({ red, blue }) do
		notify(p, "⚔️ Ranked match! Score in your " .. (p == red and "RED" or "BLUE") .. " goal. Jumping out forfeits!", "info")
	end
	updateQueueAttributes()
	task.spawn(runMatch, m)
end

local function joinQueue(player)
	if table.find(queue, player) then
		table.remove(queue, table.find(queue, player))
		updateQueueAttributes()
		updateScoreboard()
		return true, "Left the ranked queue"
	end
	if match and (match.Red == player or match.Blue == player) then
		return false, "You're already in a match!"
	end
	if not DataManager.GetActiveRobot(player) then
		return false, "Build a robot in the Robot Lab first!"
	end
	table.insert(queue, player)
	updateQueueAttributes()
	updateScoreboard()
	task.defer(tryStartMatch)
	if #queue < 2 and not match then
		return true, "Joined the ranked queue! Waiting for an opponent..."
	end
	return true, "Joined the ranked queue!"
end

---------------------------------------------------------------------
-- Intake loop: robots automatically grab nearby balls
---------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.15)
		for player, s in pairs(sessions) do
			if not s.Frozen and s.Root and s.Root.Parent and s.Held < s.Stats.Capacity then
				local intakePos = (s.Root.CFrame * CFrame.new(0, 0, -4.5)).Position
				local grabbed = false
				for _, ball in ipairs(s.Field.Balls:GetChildren()) do
					if (ball.Position - intakePos).Magnitude <= s.Stats.IntakeRadius then
						ball:Destroy()
						s.Held += 1
						grabbed = true
						if s.Held >= s.Stats.Capacity then
							break
						end
					end
				end
				if grabbed then
					sendState(player)
					local field = s.Field
					task.delay(2.5, function()
						fillBalls(field, ballTarget(field))
					end)
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- Scoring (client presses F / SCORE)
---------------------------------------------------------------------
local function flashGoal(goal)
	local pad = goal.Pad
	local original = pad.Transparency
	pad.Transparency = 0
	pad.Size += Vector3.new(0, 0.5, 0)
	task.delay(0.3, function()
		pad.Transparency = original
		pad.Size -= Vector3.new(0, 0.5, 0)
	end)
end

Remotes.Score.OnServerEvent:Connect(function(player)
	local s = sessions[player]
	if not s or s.Frozen or s.Held <= 0 or not s.Root.Parent then
		return
	end
	if os.clock() - (s.LastScore or 0) < 0.3 then
		return
	end
	s.LastScore = os.clock()

	local goals
	if s.Mode == "Ranked" then
		goals = { s.Field.Goals[s.Side] }
	else
		goals = { s.Field.Goals.Red, s.Field.Goals.Blue }
	end
	local pos = s.Root.Position
	for _, goal in ipairs(goals) do
		local offset = Vector3.new(pos.X - goal.Position.X, 0, pos.Z - goal.Position.Z)
		if offset.Magnitude <= Config.Field.GoalRadius then
			local points = s.Held * s.Stats.PointsPerBall
			local data = DataManager.Get(player)
			if data then
				data.Stats.BallsScored += s.Held
			end
			s.Held = 0
			s.Points += points
			flashGoal(goal)
			if s.Mode == "Ranked" and match and s.Side then
				match.Scores[s.Side] += points
				broadcastMatch()
			else
				local cash = DataManager.AddCash(player, points * Config.Practice.CashPerPoint, true)
				notify(player, "+" .. points .. " points  (+" .. Config.Money(cash) .. ")", "cash")
				sendState(player)
			end
			return
		end
	end
	notify(player, s.Mode == "Ranked" and ("Drive into your " .. string.upper(s.Side) .. " goal zone to score!") or "Drive into a goal zone to score!", "error")
end)

---------------------------------------------------------------------
-- Requests from the UI
---------------------------------------------------------------------
Remotes.ArenaRequest.OnServerInvoke = function(player, action)
	if not DataManager.Get(player) then
		return false, "Your data is still loading..."
	end
	if action == "Practice" then
		return startPractice(player)
	elseif action == "Queue" then
		return joinQueue(player)
	elseif action == "Stop" then
		local s = sessions[player]
		if not s then
			return false, "You're not driving"
		end
		onLeftRobot(s)
		return true
	end
	return false, "Unknown action"
end

Practice.Prompt.Triggered:Connect(function(player)
	local ok, msg = startPractice(player)
	if msg then
		notify(player, msg, ok and "info" or "error")
	end
end)

Ranked.Prompt.Triggered:Connect(function(player)
	local ok, msg = joinQueue(player)
	if msg then
		notify(player, msg, ok and "info" or "error")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local index = table.find(queue, player)
	if index then
		table.remove(queue, index)
	end
	if match and (match.Red == player or match.Blue == player) then
		finishMatch(match, match.Red == player and "Red" or "Blue")
	end
	endSession(player, false)
	updateQueueAttributes()
	updateScoreboard()
end)

fillBalls(Practice, Config.Practice.Balls)
updateQueueAttributes()
updateScoreboard()

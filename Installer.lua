-- VEX Robotics Tycoon installer
-- Paste ALL of this into Roblox Studio > View > Command Bar and press Enter.
-- It creates (or replaces) every game script. Undo with Ctrl+Z.
local ChangeHistoryService = game:GetService("ChangeHistoryService")
ChangeHistoryService:SetWaypoint("Before VEX Tycoon install")
local files = {}
table.insert(files, { Class = "ModuleScript", Service = "ReplicatedStorage", Sub = nil, Name = "Config", Source = [=[
--[[
	Config (ModuleScript)  ->  ReplicatedStorage.Config

	Every number in the game lives here. Tweak prices, robot parts,
	competitions and rewards without touching any other script.
]]

local Config = {}

---------------------------------------------------------------------
-- General
---------------------------------------------------------------------
Config.GameName = "VEX Robotics Tycoon"
Config.DataStoreName = "VexRoboticsTycoon_v1"
Config.LeaderboardStoreName = "VexRoboticsTycoon_Trophies_v1"
Config.AutoSaveInterval = 120 -- seconds
Config.StartingCash = 0

---------------------------------------------------------------------
-- World layout
---------------------------------------------------------------------
Config.MaxPlots = 6
Config.PlotRadius = 220 -- distance from hub center to each workshop
Config.PlotSize = 110
Config.HubRadius = 130
Config.ConveyorSpeed = 10
Config.DropLifetime = 25
Config.MaxDropsPerPlot = 80

Config.PlotColors = {
	Color3.fromRGB(215, 45, 55), -- red
	Color3.fromRGB(40, 110, 220), -- blue
	Color3.fromRGB(50, 175, 80), -- green
	Color3.fromRGB(240, 190, 40), -- yellow
	Color3.fromRGB(150, 70, 210), -- purple
	Color3.fromRGB(240, 120, 30), -- orange
}

-- Local positions inside a workshop plot (plot faces the hub on -Z)
Config.Layout = {
	DropperX = { -40, -31, -22, -13, -4, 5 },
	UpgraderX = { 14, 21, 28 },
	ConveyorZ = 10,
	ButtonColumns = { -46, -36, -26, -16, -6 },
	ButtonRows = { -46, -37, -28, -19, -10 },
	BayPositions = {
		Vector3.new(5, 0, 27),
		Vector3.new(17, 0, 27),
		Vector3.new(29, 0, 27),
		Vector3.new(41, 0, 27),
		Vector3.new(5, 0, 44),
		Vector3.new(17, 0, 44),
		Vector3.new(29, 0, 44),
		Vector3.new(41, 0, 44),
	},
}

---------------------------------------------------------------------
-- Seasons (rebirth)
---------------------------------------------------------------------
Config.Season = {
	BaseCost = 250000,
	CostGrowth = 2.5, -- cost = BaseCost * CostGrowth ^ currentSeason
	MultiplierPerSeason = 0.5, -- +50% cash per season
}

function Config.GetSeasonCost(season)
	return math.floor(Config.Season.BaseCost * Config.Season.CostGrowth ^ season)
end

function Config.GetMultiplier(season, hasDoubleCash)
	local m = 1 + (season or 0) * Config.Season.MultiplierPerSeason
	if hasDoubleCash then
		m *= 2
	end
	return m
end

---------------------------------------------------------------------
-- Robot economy
---------------------------------------------------------------------
Config.RobotIncomePerRating = 0.5 -- cash / second per rating point for each robot in a bay
Config.BuildCostBase = 50
Config.BuildCostPerRating = 25
Config.ScrapRefund = 0.5

---------------------------------------------------------------------
-- Workshop items (tycoon buttons). Bought in order via "Requires".
-- Types: Dropper, Upgrader, Walls, Assembly, Bay, Tiles, Banner,
--        Shelf, Overclock, Hall
---------------------------------------------------------------------
Config.Items = {
	{ Id = "dropper1", Name = "Parts Bin", Cost = 0, Type = "Dropper", Slot = 1, DropValue = 1, Interval = 2, DropColor = Color3.fromRGB(170, 170, 180), Desc = "Drops screws and nuts." },
	{ Id = "dropper2", Name = "Screw Sorter", Cost = 40, Requires = "dropper1", Type = "Dropper", Slot = 2, DropValue = 2, Interval = 2, DropColor = Color3.fromRGB(120, 120, 130), Desc = "Sorts hardware faster." },
	{ Id = "walls", Name = "Workshop Walls", Cost = 100, Requires = "dropper2", Type = "Walls", Desc = "A real team workshop!" },
	{ Id = "upgrader1", Name = "Deburring Station", Cost = 200, Requires = "dropper2", Type = "Upgrader", Slot = 1, Multiplier = 1.5, Color = Color3.fromRGB(60, 200, 255), Desc = "x1.5 part value." },
	{ Id = "dropper3", Name = "Metal Cutter", Cost = 450, Requires = "upgrader1", Type = "Dropper", Slot = 3, DropValue = 5, Interval = 2.5, DropColor = Color3.fromRGB(200, 200, 210), Desc = "Cuts aluminum C-channel." },
	{ Id = "assembly", Name = "Robot Assembly Station", Cost = 700, Requires = "dropper3", Type = "Assembly", Desc = "Unlocks the Robot Lab + Robot Bay #1." },
	{ Id = "tiles", Name = "Practice Field Tiles", Cost = 900, Requires = "assembly", Type = "Tiles", Desc = "Foam tiles for your robot bays." },
	{ Id = "bay2", Name = "Robot Bay #2", Cost = 1500, Requires = "assembly", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "dropper4", Name = "3D Printer", Cost = 2500, Requires = "dropper3", Type = "Dropper", Slot = 4, DropValue = 12, Interval = 2.5, DropColor = Color3.fromRGB(240, 120, 30), Desc = "Prints custom parts." },
	{ Id = "banner", Name = "Team Banner & Lights", Cost = 4000, Requires = "walls", Type = "Banner", Desc = "Show off your team." },
	{ Id = "upgrader2", Name = "Quality Inspection", Cost = 6000, Requires = "dropper4", Type = "Upgrader", Slot = 2, Multiplier = 1.75, Color = Color3.fromRGB(80, 255, 120), Desc = "x1.75 part value." },
	{ Id = "bay3", Name = "Robot Bay #3", Cost = 9000, Requires = "bay2", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "dropper5", Name = "CNC Mill", Cost = 15000, Requires = "upgrader2", Type = "Dropper", Slot = 5, DropValue = 35, Interval = 3, DropColor = Color3.fromRGB(90, 160, 255), Desc = "Precision machined parts." },
	{ Id = "shelf", Name = "Trophy Shelf", Cost = 22000, Requires = "banner", Type = "Shelf", Desc = "Displays your trophies." },
	{ Id = "bay4", Name = "Robot Bay #4", Cost = 35000, Requires = "bay3", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "dropper6", Name = "Laser Cutter", Cost = 60000, Requires = "dropper5", Type = "Dropper", Slot = 6, DropValue = 90, Interval = 3, DropColor = Color3.fromRGB(255, 70, 70), Desc = "Laser-cut polycarbonate." },
	{ Id = "upgrader3", Name = "Precision Polisher", Cost = 100000, Requires = "dropper6", Type = "Upgrader", Slot = 3, Multiplier = 2, Color = Color3.fromRGB(255, 220, 60), Desc = "x2 part value." },
	{ Id = "bay5", Name = "Robot Bay #5", Cost = 150000, Requires = "bay4", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "overclock", Name = "Factory Overclock", Cost = 250000, Requires = "upgrader3", Type = "Overclock", Factor = 0.6, Desc = "All machines run 40% faster." },
	{ Id = "bay6", Name = "Robot Bay #6", Cost = 400000, Requires = "bay5", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "hall", Name = "Championship Hall", Cost = 750000, Requires = "overclock", Type = "Hall", Desc = "A golden entrance for champions." },
}

Config.ItemById = {}
for index, item in ipairs(Config.Items) do
	item.Index = index
	Config.ItemById[item.Id] = item
end

---------------------------------------------------------------------
-- Robot modules. First entry in each slot is the free starter part.
-- Stats: Speed, Power, Control, Scoring  -> Rating = sum of all
-- Season = minimum season (rebirths) needed to unlock
---------------------------------------------------------------------
Config.ModuleSlots = { "Drivetrain", "Intake", "Lift", "Brain" }

Config.SlotInfo = {
	Drivetrain = { Icon = "⚙️", Desc = "Speed & pushing power. Holonomic drives can strafe (Q/E)." },
	Intake = { Icon = "🧲", Desc = "How many balls you can hold and how easily you grab them." },
	Lift = { Icon = "🏗️", Desc = "Points per ball scored." },
	Brain = { Icon = "🧠", Desc = "Control + free Autonomous points at match start." },
}

Config.Modules = {
	Drivetrain = {
		{ Id = "dt_basic", Name = "2-Motor Tank Drive", Cost = 0, Speed = 2, Power = 2, Control = 1, Wheels = 4, WheelSize = 2.4, WheelColor = Color3.fromRGB(45, 45, 50), Accent = Color3.fromRGB(150, 150, 155), Desc = "The classic Clawbot base." },
		{ Id = "dt_4m", Name = "4-Motor Tank Drive", Cost = 300, Speed = 4, Power = 4, Control = 2, Wheels = 4, WheelSize = 2.6, WheelColor = Color3.fromRGB(45, 45, 50), Accent = Color3.fromRGB(220, 50, 50), Desc = "Twice the motors, twice the push." },
		{ Id = "dt_omni", Name = "6-Wheel Omni Drive", Cost = 2500, Speed = 7, Power = 6, Control = 4, Wheels = 6, WheelSize = 2.6, WheelColor = Color3.fromRGB(110, 110, 120), Accent = Color3.fromRGB(60, 200, 90), Desc = "Smooth turns, great traction." },
		{ Id = "dt_mecanum", Name = "Mecanum Drive", Cost = 15000, Speed = 8, Power = 5, Control = 8, Strafe = true, Wheels = 4, WheelSize = 2.8, WheelColor = Color3.fromRGB(230, 190, 60), Accent = Color3.fromRGB(60, 140, 230), Desc = "Strafe sideways with Q/E!" },
		{ Id = "dt_xdrive", Name = "X-Drive", Cost = 60000, Speed = 13, Power = 7, Control = 10, Strafe = true, Wheels = 4, WheelSize = 2.8, Diagonal = true, WheelColor = Color3.fromRGB(200, 200, 210), Accent = Color3.fromRGB(150, 70, 210), Desc = "Fast holonomic drive, strafes." },
		{ Id = "dt_blue", Name = "600 RPM Blue-Cartridge Drive", Cost = 250000, Speed = 18, Power = 12, Control = 12, Wheels = 6, WheelSize = 2.8, WheelColor = Color3.fromRGB(40, 40, 45), Accent = Color3.fromRGB(40, 120, 255), Season = 1, Desc = "Blazing fast. Season 1+." },
		{ Id = "dt_worlds", Name = "Worlds Holonomic Drive", Cost = 1200000, Speed = 25, Power = 18, Control = 18, Strafe = true, Wheels = 4, WheelSize = 3, Diagonal = true, WheelColor = Color3.fromRGB(255, 205, 60), Accent = Color3.fromRGB(255, 205, 60), Season = 2, Desc = "Championship-grade. Season 2+." },
	},
	Intake = {
		{ Id = "in_claw", Name = "Clawbot Claw", Cost = 0, Scoring = 1, Capacity = 1, Radius = 4, Style = "Claw", Color = Color3.fromRGB(160, 160, 165), Desc = "Holds 1 ball." },
		{ Id = "in_flex", Name = "Flex Wheel Intake", Cost = 400, Scoring = 3, Capacity = 2, Radius = 5, Style = "Rollers", Rollers = 1, Color = Color3.fromRGB(60, 200, 90), Desc = "Holds 2 balls." },
		{ Id = "in_roller", Name = "Roller Intake", Cost = 3000, Scoring = 6, Capacity = 3, Radius = 6, Style = "Rollers", Rollers = 2, Color = Color3.fromRGB(60, 140, 230), Desc = "Holds 3 balls." },
		{ Id = "in_chain", Name = "Hooked Chain Conveyor", Cost = 20000, Scoring = 10, Power = 1, Capacity = 4, Radius = 7, Style = "Rollers", Rollers = 3, Color = Color3.fromRGB(230, 120, 40), Desc = "Holds 4 balls." },
		{ Id = "in_dual", Name = "Dual Stage Intake", Cost = 90000, Scoring = 15, Power = 2, Capacity = 5, Radius = 7.5, Style = "Rollers", Rollers = 4, Color = Color3.fromRGB(220, 50, 50), Desc = "Holds 5 balls." },
		{ Id = "in_pro", Name = "Worlds Intake", Cost = 500000, Scoring = 24, Power = 3, Capacity = 7, Radius = 9, Style = "Rollers", Rollers = 4, Color = Color3.fromRGB(255, 205, 60), Season = 1, Desc = "Holds 7 balls. Season 1+." },
	},
	Lift = {
		{ Id = "lf_none", Name = "No Lift", Cost = 0, Points = 1, Style = "None", Color = Color3.fromRGB(150, 150, 155), Desc = "1 point per ball." },
		{ Id = "lf_4bar", Name = "4-Bar Lift", Cost = 800, Scoring = 2, Power = 1, Points = 2, Style = "FourBar", Color = Color3.fromRGB(200, 200, 210), Desc = "2 points per ball." },
		{ Id = "lf_dr4b", Name = "Double Reverse 4-Bar", Cost = 6000, Scoring = 5, Power = 1, Points = 3, Style = "DR4B", Color = Color3.fromRGB(60, 140, 230), Desc = "3 points per ball." },
		{ Id = "lf_cascade", Name = "Cascade Lift", Cost = 35000, Scoring = 9, Power = 2, Points = 4, Style = "Cascade", Color = Color3.fromRGB(60, 200, 90), Desc = "4 points per ball." },
		{ Id = "lf_cata", Name = "Pneumatic Catapult", Cost = 150000, Scoring = 14, Power = 3, Points = 5, Style = "Catapult", Color = Color3.fromRGB(220, 50, 50), Desc = "5 points per ball." },
		{ Id = "lf_fly", Name = "Flywheel Launcher", Cost = 700000, Scoring = 20, Power = 5, Points = 7, Style = "Flywheel", Color = Color3.fromRGB(255, 205, 60), Season = 1, Desc = "7 points per ball. Season 1+." },
	},
	Brain = {
		{ Id = "br_basic", Name = "Basic Controller", Cost = 0, Control = 1, Auton = 0, ScreenColor = Color3.fromRGB(120, 120, 120), Desc = "Driver control only." },
		{ Id = "br_v5", Name = "V5 Brain + Driver Code", Cost = 1000, Control = 3, Auton = 1, ScreenColor = Color3.fromRGB(80, 160, 255), Desc = "+1 auton point." },
		{ Id = "br_pid", Name = "PID Autonomous", Cost = 8000, Control = 6, Auton = 3, ScreenColor = Color3.fromRGB(80, 255, 140), Desc = "+3 auton points." },
		{ Id = "br_odom", Name = "Odometry + Pure Pursuit", Cost = 45000, Control = 10, Auton = 5, ScreenColor = Color3.fromRGB(255, 200, 60), Desc = "+5 auton points." },
		{ Id = "br_vision", Name = "Vision Sensor AI", Cost = 200000, Control = 15, Auton = 8, ScreenColor = Color3.fromRGB(255, 90, 200), Desc = "+8 auton points." },
		{ Id = "br_worlds", Name = "Worlds Skills Code", Cost = 900000, Control = 22, Auton = 12, ScreenColor = Color3.fromRGB(255, 60, 60), Season = 2, Desc = "+12 auton points. Season 2+." },
	},
}

Config.ModuleById = {}
for _, slot in ipairs(Config.ModuleSlots) do
	for index, def in ipairs(Config.Modules[slot]) do
		def.Slot = slot
		def.Index = index
		Config.ModuleById[def.Id] = def
	end
end

-- Returns computed stats for a loadout {Drivetrain=id, Intake=id, Lift=id, Brain=id}
function Config.GetRobotStats(loadout)
	local stats = { Speed = 0, Power = 0, Control = 0, Scoring = 0 }
	local defs = {}
	for _, slot in ipairs(Config.ModuleSlots) do
		local id = loadout and loadout[slot]
		local def = id and Config.ModuleById[id]
		if not def or def.Slot ~= slot then
			def = Config.Modules[slot][1]
		end
		defs[slot] = def
		stats.Speed += def.Speed or 0
		stats.Power += def.Power or 0
		stats.Control += def.Control or 0
		stats.Scoring += def.Scoring or 0
	end
	stats.Rating = stats.Speed + stats.Power + stats.Control + stats.Scoring
	stats.Capacity = defs.Intake.Capacity or 1
	stats.IntakeRadius = defs.Intake.Radius or 4
	stats.PointsPerBall = defs.Lift.Points or 1
	stats.Auton = defs.Brain.Auton or 0
	stats.Strafe = defs.Drivetrain.Strafe == true
	stats.MaxSpeed = 14 + stats.Speed * 0.7
	stats.TurnSpeed = 2.4 + stats.Control * 0.05
	stats.Force = 5000 + stats.Power * 900
	stats.Income = stats.Rating * Config.RobotIncomePerRating
	stats.BuildCost = math.floor(Config.BuildCostBase + stats.Rating * Config.BuildCostPerRating)
	return stats, defs
end

---------------------------------------------------------------------
-- Competitions (auto-simulated tournaments, uses your ACTIVE robot)
---------------------------------------------------------------------
Config.Competitions = {
	{ Id = "scrim", Name = "Club Scrimmage", MinRating = 0, Fee = 0, Difficulty = 6, Prize = 120, Trophies = 1, Cooldown = 45 },
	{ Id = "league", Name = "League Night", MinRating = 12, Fee = 60, Difficulty = 14, Prize = 700, Trophies = 2, Cooldown = 60 },
	{ Id = "qualifier", Name = "Local Qualifier", MinRating = 22, Fee = 300, Difficulty = 24, Prize = 3500, Trophies = 4, Cooldown = 90 },
	{ Id = "regional", Name = "Regional Championship", MinRating = 35, Fee = 2000, Difficulty = 38, Prize = 22000, Trophies = 8, Cooldown = 120 },
	{ Id = "state", Name = "State Championship", MinRating = 55, Fee = 12000, Difficulty = 58, Prize = 130000, Trophies = 15, Cooldown = 150 },
	{ Id = "nationals", Name = "Nationals", MinRating = 80, Fee = 60000, Difficulty = 84, Prize = 650000, Trophies = 30, Cooldown = 180 },
	{ Id = "worlds", Name = "World Championship", MinRating = 110, Fee = 300000, Difficulty = 112, Prize = 3500000, Trophies = 75, Cooldown = 240 },
}

Config.CompetitionById = {}
for _, comp in ipairs(Config.Competitions) do
	Config.CompetitionById[comp.Id] = comp
end

-- Payout fraction of the prize based on how far you got (0 = lost QF, 3 = champion)
Config.CompetitionPayout = { [0] = 0, [1] = 0.25, [2] = 0.5, [3] = 1 }

---------------------------------------------------------------------
-- Driving: practice field + ranked 1v1 matches
---------------------------------------------------------------------
Config.Field = {
	Size = 96,
	GoalRadius = 13,
	BallSize = 2.5,
	BallColor = Color3.fromRGB(80, 220, 90),
}

Config.Practice = {
	Balls = 14,
	CashPerPoint = 15, -- multiplied by season multiplier
}

Config.Match = {
	Duration = 90,
	Countdown = 5,
	Balls = 18,
	WinTrophies = 5,
	TieTrophies = 2,
	LoseTrophies = 1,
	WinCashBase = 500,
	WinCashPerRating = 40,
	LoseCash = 100,
}

---------------------------------------------------------------------
-- Game passes: put your real Game Pass IDs here (0 = disabled)
---------------------------------------------------------------------
Config.GamePasses = {
	{ Key = "DoubleCash", Name = "2x Cash", Id = 0, Icon = "💰", Desc = "Double all cash you earn, forever." },
	{ Key = "AutoCollect", Name = "Auto Collect", Id = 0, Icon = "🧺", Desc = "Workshop cash goes straight to your wallet." },
	{ Key = "ExtraBays", Name = "+2 Robot Bays", Id = 0, Icon = "🏠", Desc = "Two extra robot bays (needs Assembly Station)." },
	{ Key = "Turbo", Name = "Turbo Motors", Id = 0, Icon = "⚡", Desc = "+15% drive speed in practice & ranked." },
}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Config.Format(n)
	n = math.floor(tonumber(n) or 0)
	local negative = n < 0
	n = math.abs(n)
	local text
	if n < 1000 then
		text = tostring(n)
	else
		local index = 1
		local value = n
		while value >= 1000 and index < #SUFFIXES do
			value /= 1000
			index += 1
		end
		local fmt = value >= 100 and "%.0f%s" or (value >= 10 and "%.1f%s" or "%.2f%s")
		text = string.format(fmt, value, SUFFIXES[index])
	end
	return (negative and "-" or "") .. text
end

function Config.Money(n)
	return "$" .. Config.Format(n)
end

return Config
]=] })
table.insert(files, { Class = "ModuleScript", Service = "ServerScriptService", Sub = nil, Name = "DataManager", Source = [=[
--[[
	DataManager (ModuleScript)  ->  ServerScriptService.DataManager

	Loads/saves player data, owns leaderstats, cash helpers, game pass
	checks, and creates all RemoteEvents/RemoteFunctions.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local DataManager = {}
DataManager.Profiles = {} -- [player] = saved data table
DataManager.Passes = {} -- [player] = { [passKey] = true }
DataManager.Runtime = {} -- [player] = non-saved state (cooldowns, debounces)

local changedEvent = Instance.new("BindableEvent")
DataManager.Changed = changedEvent.Event

---------------------------------------------------------------------
-- Remotes (created once, shared by every server script)
---------------------------------------------------------------------
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function getRemote(className, name)
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remoteFolder
	end
	return remote
end

DataManager.Remotes = {
	Folder = remoteFolder,
	Request = getRemote("RemoteFunction", "Request"), -- workshop / lab / competitions
	ArenaRequest = getRemote("RemoteFunction", "ArenaRequest"), -- driving / ranked
	DataUpdate = getRemote("RemoteEvent", "DataUpdate"),
	Notify = getRemote("RemoteEvent", "Notify"),
	OpenUI = getRemote("RemoteEvent", "OpenUI"),
	ArenaState = getRemote("RemoteEvent", "ArenaState"),
	Score = getRemote("RemoteEvent", "Score"),
}

---------------------------------------------------------------------
-- DataStore
---------------------------------------------------------------------
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataManager] DataStore unavailable (publish the place & enable Studio API access to save):", result)
	end
end

local warnedSaveFailure = false

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end
DataManager.DeepCopy = deepCopy

local function reconcile(data, template)
	for key, value in pairs(template) do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" and key ~= "Garage" then
			reconcile(data[key], value)
		end
	end
end

function DataManager.DefaultModules()
	local modules, loadout = {}, {}
	for _, slot in ipairs(Config.ModuleSlots) do
		local starter = Config.Modules[slot][1]
		modules[starter.Id] = true
		loadout[slot] = starter.Id
	end
	return modules, loadout
end

local function defaultData()
	local modules, loadout = DataManager.DefaultModules()
	return {
		Cash = Config.StartingCash,
		Trophies = 0,
		Season = 0,
		Purchased = {},
		Modules = modules,
		Loadout = loadout,
		Garage = {},
		Active = 0,
		Stats = {
			CompWins = 0,
			CompsEntered = 0,
			MatchesPlayed = 0,
			MatchesWon = 0,
			BallsScored = 0,
			RobotsBuilt = 0,
			TotalEarned = 0,
		},
	}
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function sanitize(data)
	-- make sure the loadout only references real, owned modules
	for _, slot in ipairs(Config.ModuleSlots) do
		local def = Config.ModuleById[data.Loadout[slot]]
		if not def or def.Slot ~= slot or not data.Modules[def.Id] then
			data.Loadout[slot] = Config.Modules[slot][1].Id
		end
	end
	-- remove garage robots that reference unknown parts
	local cleanGarage = {}
	for _, robot in ipairs(data.Garage) do
		if type(robot) == "table" then
			table.insert(cleanGarage, robot)
		end
	end
	data.Garage = cleanGarage
	if data.Active > #data.Garage then
		data.Active = #data.Garage
	end
	if data.Active < 1 and #data.Garage > 0 then
		data.Active = 1
	end
	data.Cash = math.max(0, math.floor(tonumber(data.Cash) or 0))
end

---------------------------------------------------------------------
-- Leaderstats
---------------------------------------------------------------------
local function updateLeaderstats(player)
	local data = DataManager.Profiles[player]
	local stats = player:FindFirstChild("leaderstats")
	if not data or not stats then
		return
	end
	stats.Cash.Value = data.Cash
	stats.Trophies.Value = data.Trophies
	stats.Season.Value = data.Season
end
DataManager.UpdateLeaderstats = updateLeaderstats

local function createLeaderstats(player, data)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.Cash
	cash.Parent = folder
	local trophies = Instance.new("IntValue")
	trophies.Name = "Trophies"
	trophies.Value = data.Trophies
	trophies.Parent = folder
	local season = Instance.new("IntValue")
	season.Name = "Season"
	season.Value = data.Season
	season.Parent = folder
	folder.Parent = player
end

---------------------------------------------------------------------
-- Load / Save
---------------------------------------------------------------------
function DataManager.Load(player)
	local data = nil
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if ok then
				data = result
				break
			end
			warn("[DataManager] Load attempt", attempt, "failed for", player.Name, result)
			task.wait(1.5)
		end
	end

	if type(data) ~= "table" then
		data = defaultData()
	else
		reconcile(data, defaultData())
	end
	sanitize(data)

	if not player.Parent then
		return nil -- left while loading
	end

	DataManager.Profiles[player] = data
	DataManager.Runtime[player] = { Cooldowns = {} }
	DataManager.Passes[player] = {}
	createLeaderstats(player, data)

	for _, pass in ipairs(Config.GamePasses) do
		if pass.Id and pass.Id > 0 then
			task.spawn(function()
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
				end)
				if ok and owns and DataManager.Passes[player] then
					DataManager.Passes[player][pass.Key] = true
					DataManager.MarkChanged(player)
				end
			end)
		end
	end

	return data
end

function DataManager.Save(player)
	local data = DataManager.Profiles[player]
	if not data or not store then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(player), data)
	end)
	if not ok and not warnedSaveFailure then
		warnedSaveFailure = true
		warn("[DataManager] Save failed (further save warnings hidden):", err)
	end
end

function DataManager.Release(player)
	DataManager.Save(player)
	DataManager.Profiles[player] = nil
	DataManager.Runtime[player] = nil
	DataManager.Passes[player] = nil
end

task.spawn(function()
	while true do
		task.wait(Config.AutoSaveInterval)
		for player in pairs(DataManager.Profiles) do
			task.spawn(DataManager.Save, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in pairs(DataManager.Profiles) do
		pending += 1
		task.spawn(function()
			DataManager.Save(player)
			pending -= 1
		end)
	end
	local start = os.clock()
	while pending > 0 and os.clock() - start < 25 do
		task.wait(0.1)
	end
end)

---------------------------------------------------------------------
-- Helpers used by every server script
---------------------------------------------------------------------
function DataManager.Get(player)
	return DataManager.Profiles[player]
end

function DataManager.HasPass(player, key)
	local passes = DataManager.Passes[player]
	return passes ~= nil and passes[key] == true
end

function DataManager.GrantPass(player, key)
	local passes = DataManager.Passes[player]
	if passes then
		passes[key] = true
		DataManager.MarkChanged(player)
	end
end

function DataManager.GetMultiplier(player)
	local data = DataManager.Profiles[player]
	if not data then
		return 1
	end
	return Config.GetMultiplier(data.Season, DataManager.HasPass(player, "DoubleCash"))
end

-- Adds cash. If applyMultiplier is true the season/pass multiplier is used.
function DataManager.AddCash(player, amount, applyMultiplier)
	local data = DataManager.Profiles[player]
	if not data then
		return 0
	end
	if applyMultiplier then
		amount *= DataManager.GetMultiplier(player)
	end
	amount = math.floor(amount)
	data.Cash += amount
	if amount > 0 then
		data.Stats.TotalEarned += amount
	end
	updateLeaderstats(player)
	return amount
end

function DataManager.SpendCash(player, amount)
	local data = DataManager.Profiles[player]
	if not data or amount < 0 or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	updateLeaderstats(player)
	return true
end

function DataManager.AddTrophies(player, amount)
	local data = DataManager.Profiles[player]
	if not data then
		return
	end
	data.Trophies += amount
	updateLeaderstats(player)
	DataManager.MarkChanged(player)
end

function DataManager.GetGarageSlots(player)
	local data = DataManager.Profiles[player]
	if not data then
		return 0
	end
	local slots = 0
	for _, item in ipairs(Config.Items) do
		if (item.Type == "Assembly" or item.Type == "Bay") and data.Purchased[item.Id] then
			slots += 1
		end
	end
	if slots > 0 and DataManager.HasPass(player, "ExtraBays") then
		slots += 2
	end
	return math.min(slots, #Config.Layout.BayPositions)
end

function DataManager.GetActiveRobot(player)
	local data = DataManager.Profiles[player]
	if not data then
		return nil
	end
	return data.Garage[data.Active]
end

function DataManager.GetRobotIncome(player)
	local data = DataManager.Profiles[player]
	if not data then
		return 0
	end
	local total = 0
	for _, robot in ipairs(data.Garage) do
		local stats = Config.GetRobotStats(robot)
		total += stats.Income
	end
	return total
end

function DataManager.Notify(player, text, kind)
	DataManager.Remotes.Notify:FireClient(player, text, kind or "info")
end

function DataManager.MarkChanged(player)
	changedEvent:Fire(player)
end

function DataManager.GetSnapshot(player)
	local data = DataManager.Profiles[player]
	if not data then
		return nil
	end
	local runtime = DataManager.Runtime[player]
	local cooldowns = {}
	if runtime then
		for compId, readyAt in pairs(runtime.Cooldowns) do
			local remaining = readyAt - os.time()
			if remaining > 0 then
				cooldowns[compId] = remaining
			end
		end
	end
	return {
		Cash = data.Cash,
		Trophies = data.Trophies,
		Season = data.Season,
		Purchased = data.Purchased,
		Modules = data.Modules,
		Loadout = data.Loadout,
		Garage = data.Garage,
		Active = data.Active,
		Stats = data.Stats,
		Passes = DataManager.Passes[player] or {},
		Multiplier = DataManager.GetMultiplier(player),
		GarageSlots = DataManager.GetGarageSlots(player),
		RobotIncome = DataManager.GetRobotIncome(player) * DataManager.GetMultiplier(player),
		Cooldowns = cooldowns,
		HasPlot = runtime ~= nil and runtime.Plot ~= nil,
	}
end

Players.PlayerRemoving:Connect(function(player)
	-- deferred so other scripts' PlayerRemoving handlers can still read the data first
	task.defer(function()
		if DataManager.Profiles[player] then
			DataManager.Release(player)
		end
	end)
end)

return DataManager
]=] })
table.insert(files, { Class = "ModuleScript", Service = "ServerScriptService", Sub = nil, Name = "RobotBuilder", Source = [=[
--[[
	RobotBuilder (ModuleScript)  ->  ServerScriptService.RobotBuilder

	Builds a 3D VEX-style robot Model out of the chosen modules.
	  RobotBuilder.Build(loadout, options) -> model, stats
	options:
	  Drive      = true  -> unanchored, has a VehicleSeat + drive constraints
	  TeamColor  = Color3 accent color
	  Label      = text shown above the robot
	  SubLabel   = second line of text
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local RobotBuilder = {}

local METAL = Color3.fromRGB(196, 198, 204)
local DARK = Color3.fromRGB(35, 35, 40)
local MOTOR = Color3.fromRGB(55, 30, 30)

local function makeBillboard(root, label, subLabel)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.new(10, 0, 2.4, 0)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.4
	title.Text = label or "Robot"
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(255, 220, 90)
	sub.TextStrokeTransparency = 0.4
	sub.Text = subLabel or ""
	sub.Parent = gui
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

	makeBillboard(root, options.Label, options.SubLabel)

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
]=] })
table.insert(files, { Class = "ModuleScript", Service = "ServerScriptService", Sub = nil, Name = "WorldBuilder", Source = [=[
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
	label.Font = font or Enum.Font.GothamBlack
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
	return label
end

local function billboard(adornee, text, studsWidth, studsHeight, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(studsWidth, 0, studsHeight, 0)
	gui.StudsOffset = offset or Vector3.new(0, 3, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	return label
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
		baseplate.Color = Color3.fromRGB(80, 140, 70)
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
			Color = Color3.fromRGB(80, 140, 70),
			Material = Enum.Material.Grass,
		})
	end

	newPart(hubFolder, {
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, Config.HubRadius * 2, Config.HubRadius * 2),
		CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(205, 205, 210),
		Material = Enum.Material.Concrete,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, 72)
	spawn.Color = Color3.fromRGB(220, 50, 50)
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0
	spawn.TopSurface = SMOOTH
	spawn.Parent = hubFolder

	-- floating title
	local title = newPart(hubFolder, {
		Name = "Title",
		Size = Vector3.new(60, 10, 1),
		CFrame = CFrame.new(0, 30, 0),
		Color = Color3.fromRGB(25, 28, 40),
	})
	surfaceText(title, Enum.NormalId.Front, Config.GameName, Color3.fromRGB(255, 80, 80))
	surfaceText(title, Enum.NormalId.Back, Config.GameName, Color3.fromRGB(80, 160, 255))

	-- leaderboard (faces the center)
	local board = newPart(hubFolder, {
		Name = "Leaderboard",
		Size = Vector3.new(18, 22, 1),
		CFrame = CFrame.new(0, 12, -100),
		Color = Color3.fromRGB(25, 28, 40),
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
	header.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	header.Font = Enum.Font.GothamBlack
	header.TextScaled = true
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Text = "🏆 TOP TEAMS (Trophies)"
	header.Parent = list
	hub.LeaderboardRows = {}
	for i = 1, 10 do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = i <= 3 and Color3.fromRGB(255, 215, 80) or Color3.new(1, 1, 1)
		row.Text = string.format("  #%d  ---", i)
		row.Parent = list
		hub.LeaderboardRows[i] = row
	end

	-- competition kiosk
	local kiosk = newPart(hubFolder, {
		Name = "CompetitionKiosk",
		Size = Vector3.new(14, 6, 4),
		CFrame = CFrame.new(0, 3.3, 100),
		Color = Color3.fromRGB(25, 28, 40),
	})
	local kioskSign = newPart(hubFolder, {
		Size = Vector3.new(16, 5, 1),
		CFrame = CFrame.new(0, 10, 100),
		Color = Color3.fromRGB(240, 190, 40),
		Material = Enum.Material.Neon,
	})
	surfaceText(kioskSign, Enum.NormalId.Front, "🏆 COMPETITIONS", Color3.fromRGB(30, 30, 30))
	hub.CompetitionPrompt = prompt(kiosk, "Enter Competitions", "Tournament Desk")

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
		local pad = newPart(f, { Name = side .. "GoalPad", Size = Vector3.new(8, 0.1, 12), CFrame = at(gx, 0.65, 0), Color = color, Material = Enum.Material.Neon, Transparency = 0.2 })
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
	local kiosk = newPart(f, { Name = "Kiosk", Size = Vector3.new(10, 4, 3), CFrame = at(0, 2.3, -half - 10), Color = Color3.fromRGB(25, 28, 40) })
	local sign = newPart(f, { Size = Vector3.new(26, 5, 1), CFrame = at(0, 13, -half - 1.5), Color = Color3.fromRGB(25, 28, 40) })
	surfaceText(sign, Enum.NormalId.Front, accentText, Color3.fromRGB(255, 255, 255))
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
		Color = Color3.fromRGB(20, 22, 30),
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
			l.Font = Enum.Font.GothamBlack
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
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1.2, 1), Vector3.new(0, 0.6, -half + 0.5), color, Enum.Material.Neon)
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1.2, 1), Vector3.new(0, 0.6, half - 0.5), color, Enum.Material.Neon)
	plotPart(plot, base, Vector3.new(1, 1.2, Config.PlotSize), Vector3.new(-half + 0.5, 0.6, 0), color, Enum.Material.Neon)
	plotPart(plot, base, Vector3.new(1, 1.2, Config.PlotSize), Vector3.new(half - 0.5, 0.6, 0), color, Enum.Material.Neon)

	-- path to hub
	local pathLength = Config.PlotRadius - half - Config.HubRadius + 6
	plotPart(plot, base, Vector3.new(16, 0.4, pathLength), Vector3.new(0, 0.1, -half - pathLength / 2 + 2), Color3.fromRGB(150, 150, 155), Enum.Material.Concrete)

	-- owner sign
	local sign = plotPart(plot, base, Vector3.new(26, 6, 1), Vector3.new(-30, 6, -half + 1), Color3.fromRGB(25, 28, 40))
	plotPart(plot, base, Vector3.new(1, 3, 1), Vector3.new(-40, 2, -half + 1), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(1, 3, 1), Vector3.new(-20, 2, -half + 1), METAL, Enum.Material.Metal)
	plot.OwnerLabel = surfaceText(sign, Enum.NormalId.Front, "Empty Workshop", color)

	-- spawn pad
	plotPart(plot, base, Vector3.new(8, 0.2, 8), Vector3.new(30, 1.1, -42), color, Enum.Material.Neon, { CanCollide = false })
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
	local collector = plotPart(plot, base, Vector3.new(11, 1, 10), Vector3.new(39.5, 1.5, z), color, Enum.Material.Neon, { Name = "Collector" })
	plotPart(plot, base, Vector3.new(11, 3, 0.5), Vector3.new(39.5, 3, z - 5), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(11, 3, 0.5), Vector3.new(39.5, 3, z + 5), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(0.5, 3, 10), Vector3.new(45.25, 3, z), METAL, Enum.Material.Metal)
	plot.Collector = collector
	billboard(collector, "PART COLLECTOR", 10, 1.5, Vector3.new(0, 4, 0), Color3.fromRGB(255, 255, 255))

	-- collect pad
	local collectPad = plotPart(plot, base, Vector3.new(7, 0.4, 7), Vector3.new(40, 1.2, -4), Color3.fromRGB(60, 220, 90), Enum.Material.Neon, { Name = "CollectPad" })
	plot.CollectPad = collectPad
	plot.StorageLabel = billboard(collectPad, "Step here to collect\n$0", 10, 3, Vector3.new(0, 4, 0), Color3.fromRGB(120, 255, 140))

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
	billboard(pad, item.Name .. "\n" .. priceText, 9, 3, Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
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
	plotPart(plot, plot.Bays, Vector3.new(10, 0.32, 0.4), pos + Vector3.new(0, 1.16, -5.3), plot.Color, Enum.Material.Neon)
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
	plotPart(plot, model, Vector3.new(4.7, 0.6, 4.7), Vector3.new(x, 13.2, z), plot.Color, Enum.Material.Neon)
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
	local top = plotPart(plot, model, Vector3.new(1.4, 1.4, 9), Vector3.new(x, 9.5, z), item.Color, Enum.Material.Neon)
	local laser = plotPart(plot, model, Vector3.new(0.4, 3.5, 6), Vector3.new(x, 5.25, z), item.Color, Enum.Material.Neon, {
		Name = "Laser",
		Transparency = 0.45,
		CanCollide = false,
	})
	billboard(top, item.Name .. " x" .. item.Multiplier, 8, 1.4, Vector3.new(0, 2, 0), item.Color)
	model.PrimaryPart = laser
end

function itemBuilders.Walls(plot, _, model)
	local half = Config.PlotSize / 2
	local wallColor = Color3.fromRGB(230, 230, 235)
	plotPart(plot, model, Vector3.new(Config.PlotSize, 14, 1), Vector3.new(0, 8, half - 0.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1, 14, 75), Vector3.new(-half + 0.5, 8, 17.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1, 14, 75), Vector3.new(half - 0.5, 8, 17.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(Config.PlotSize, 1.5, 1.2), Vector3.new(0, 6, half - 0.6), plot.Color, Enum.Material.Neon)
	plotPart(plot, model, Vector3.new(1.2, 1.5, 75), Vector3.new(-half + 0.6, 6, 17.5), plot.Color, Enum.Material.Neon)
	plotPart(plot, model, Vector3.new(1.2, 1.5, 75), Vector3.new(half - 0.6, 6, 17.5), plot.Color, Enum.Material.Neon)
end

function itemBuilders.Assembly(plot, _, model)
	local tableTop = plotPart(plot, model, Vector3.new(12, 0.6, 6), Vector3.new(-38, 4, 36), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks, { Name = "Workbench" })
	for _, p in ipairs({ { -43, 33.5 }, { -33, 33.5 }, { -43, 38.5 }, { -33, 38.5 } }) do
		plotPart(plot, model, Vector3.new(0.6, 3, 0.6), Vector3.new(p[1], 2.5, p[2]), METAL, Enum.Material.Metal)
	end
	local monitor = plotPart(plot, model, Vector3.new(5, 3.2, 0.3), Vector3.new(-38, 6.3, 38.5), Color3.fromRGB(20, 20, 25))
	surfaceText(monitor, Enum.NormalId.Front, "🤖 ROBOT LAB", Color3.fromRGB(90, 200, 255), Color3.fromRGB(10, 20, 35))
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
		plotPart(plot, model, Vector3.new(2, 0.4, 20), Vector3.new(-half + 2, y, 0 - i * 2), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks)
		for k = 0, 3 do
			local tz = -i * 2 - 8 + k * 5
			plotPart(plot, model, Vector3.new(1.2, 0.4, 1.2), Vector3.new(-half + 2, y + 0.4, tz), Color3.fromRGB(80, 60, 30), Enum.Material.Wood)
			plotPart(plot, model, Vector3.new(0.4, 1.2, 0.4), Vector3.new(-half + 2, y + 1.1, tz), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
			plotPart(plot, model, Vector3.new(1.2, 1.2, 1.2), Vector3.new(-half + 2, y + 2.1, tz), Color3.fromRGB(255, 200, 60), Enum.Material.Metal, { Shape = Enum.PartType.Ball })
		end
	end
	local sign = plotPart(plot, model, Vector3.new(0.4, 3, 14), Vector3.new(-half + 1.5, 12.5, -3), Color3.fromRGB(25, 28, 40))
	local label = surfaceText(sign, Enum.NormalId.Right, "🏆 0 Trophies", Color3.fromRGB(255, 210, 70))
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
	billboard(core, "⚡ OVERCLOCK", 8, 1.5, Vector3.new(0, 5, 0), Color3.fromRGB(80, 200, 255))
end

function itemBuilders.Hall(plot, _, model)
	local half = Config.PlotSize / 2
	local gold = Color3.fromRGB(255, 200, 60)
	plotPart(plot, model, Vector3.new(2, 18, 2), Vector3.new(-10, 10, -half + 2), gold, Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(2, 18, 2), Vector3.new(10, 10, -half + 2), gold, Enum.Material.Metal)
	local top = plotPart(plot, model, Vector3.new(24, 4, 2), Vector3.new(0, 20, -half + 2), gold, Enum.Material.Metal)
	surfaceText(top, Enum.NormalId.Front, "🏆 CHAMPIONS 🏆", Color3.fromRGB(60, 40, 0))
	plotPart(plot, model, Vector3.new(16, 0.2, 30), Vector3.new(0, 1.02, -half + 16), gold, Enum.Material.Neon, { CanCollide = false, Transparency = 0.3 })
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

	world = {}
	world.Root = root
	world.Hub = buildHub(root)
	world.Fields = {
		Practice = buildField(root, "Practice", Vector3.new(-62, 0, 0), "🎮 PRACTICE FIELD"),
		Ranked = buildField(root, "Ranked", Vector3.new(62, 0, 0), "⚔️ RANKED 1v1 ARENA"),
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
]=] })
table.insert(files, { Class = "Script", Service = "ServerScriptService", Sub = nil, Name = "TycoonServer", Source = [=[
--[[
	TycoonServer (Script)  ->  ServerScriptService.TycoonServer

	Workshops, tycoon buttons, droppers, Robot Lab, robot bays (income),
	competitions, seasons (rebirth), game pass shop and leaderboard.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local RobotBuilder = require(ServerScriptService:WaitForChild("RobotBuilder"))
local WorldBuilder = require(ServerScriptService:WaitForChild("WorldBuilder"))

local Remotes = DataManager.Remotes
local World = WorldBuilder.GetWorld()

local playerPlot = {} -- [player] = plot

local function notify(player, text, kind)
	DataManager.Notify(player, text, kind)
end

---------------------------------------------------------------------
-- Data push (batched so many changes in one frame send one update)
---------------------------------------------------------------------
local pendingPush = {}
local function pushData(player)
	if pendingPush[player] then
		return
	end
	pendingPush[player] = true
	task.defer(function()
		pendingPush[player] = nil
		if player.Parent and DataManager.Get(player) then
			Remotes.DataUpdate:FireClient(player, DataManager.GetSnapshot(player))
		end
	end)
end

---------------------------------------------------------------------
-- Plot visuals
---------------------------------------------------------------------
local function updateStorageLabel(plot)
	plot.StorageLabel.Text = "Step here to collect\n" .. Config.Money(plot.Storage)
end

local function updateTrophyShelf(plot)
	local model = plot.Built.shelf
	local data = plot.Owner and DataManager.Get(plot.Owner)
	if model and data then
		local label = model:FindFirstChild("TrophyLabel", true)
		if label then
			label.Text = "🏆 " .. Config.Format(data.Trophies) .. " Trophies"
		end
	end
end

local function refreshDisplay(plot)
	local assembly = plot.Built.assembly
	if not assembly then
		return
	end
	local old = assembly:FindFirstChild("DesignRobot")
	if old then
		old:Destroy()
	end
	local data = plot.Owner and DataManager.Get(plot.Owner)
	local pad = assembly:FindFirstChild("DisplayPad")
	if not data or not pad then
		return
	end
	local robot, stats = RobotBuilder.Build(data.Loadout, {
		Name = "DesignRobot",
		TeamColor = plot.Color,
		Label = "Current Design",
	})
	robot:PivotTo(plot.CFrame * CFrame.new(-20, 1.4 + 1, 36) * CFrame.Angles(0, math.pi, 0))
	robot.Parent = assembly
	local sub = robot.Root.Nameplate:FindFirstChild("Sub")
	if sub then
		sub.Text = "Rating " .. stats.Rating
	end
end

local function refreshBays(plot)
	plot.Bays:ClearAllChildren()
	local player = plot.Owner
	local data = player and DataManager.Get(player)
	if not data then
		return
	end
	local mult = DataManager.GetMultiplier(player)
	local slots = DataManager.GetGarageSlots(player)
	for i = 1, slots do
		local pad = WorldBuilder.BuildBayPad(plot, i)
		local loadout = data.Garage[i]
		if loadout then
			local stats = Config.GetRobotStats(loadout)
			local label = (i == data.Active and "⭐ " or "") .. "Robot #" .. i .. " (" .. stats.Rating .. ")"
			local robot = RobotBuilder.Build(loadout, {
				Name = "BayRobot" .. i,
				TeamColor = plot.Color,
				Label = label,
				SubLabel = "+" .. Config.Money(stats.Income * mult) .. "/s",
			})
			robot:PivotTo(pad.CFrame * CFrame.new(0, 0.15 + 1, 0) * CFrame.Angles(0, math.pi, 0))
			robot.Parent = plot.Bays
		end
	end
end

local function updateButtonColors(plot)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	if not data then
		return
	end
	for itemId, model in pairs(plot.ButtonModels) do
		local item = Config.ItemById[itemId]
		local pad = model.PrimaryPart
		if pad and item then
			pad.Color = data.Cash >= item.Cost and Color3.fromRGB(60, 220, 90) or Color3.fromRGB(220, 60, 60)
		end
	end
end

---------------------------------------------------------------------
-- Drops
---------------------------------------------------------------------
local function spawnDrop(plot, item, position)
	local drop = Instance.new("Part")
	drop.Name = "Drop"
	drop.Size = Vector3.new(1, 1, 1) * (0.8 + math.min(item.Slot, 6) * 0.08)
	drop.Color = item.DropColor
	drop.Material = Enum.Material.Metal
	drop.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
	drop.TopSurface = Enum.SurfaceType.Smooth
	drop.BottomSurface = Enum.SurfaceType.Smooth
	drop.CanQuery = false
	drop:SetAttribute("Value", item.DropValue)
	drop.Parent = plot.Drops
	pcall(function()
		drop:SetNetworkOwner(nil)
	end)
	Debris:AddItem(drop, Config.DropLifetime)
end

local function startDropper(plot, item, model)
	local token = plot.Token
	task.spawn(function()
		local body = model.PrimaryPart
		local dropPoint = body and body:FindFirstChild("DropPoint")
		if not dropPoint then
			return
		end
		while plot.Token == token and model.Parent do
			local interval = item.Interval
			if plot.Built.overclock then
				interval *= Config.ItemById.overclock.Factor
			end
			task.wait(interval)
			if plot.Token ~= token or not model.Parent then
				break
			end
			if #plot.Drops:GetChildren() < Config.MaxDropsPerPlot then
				spawnDrop(plot, item, dropPoint.WorldPosition)
			end
		end
	end)
end

local function hookUpgrader(plot, item, model)
	local laser = model:FindFirstChild("Laser")
	if not laser then
		return
	end
	local flag = "Up_" .. item.Id
	laser.Touched:Connect(function(hit)
		if hit.Parent ~= plot.Drops or hit:GetAttribute(flag) then
			return
		end
		hit:SetAttribute(flag, true)
		hit:SetAttribute("Value", (hit:GetAttribute("Value") or 0) * item.Multiplier)
		hit.Color = item.Color
		hit.Material = Enum.Material.Neon
	end)
end

---------------------------------------------------------------------
-- Building items / buttons
---------------------------------------------------------------------
local tryPurchase -- forward declaration

local function buildItem(plot, item)
	if plot.Built[item.Id] then
		return
	end
	local model = WorldBuilder.BuildItem(plot, item)
	plot.Built[item.Id] = model
	if item.Type == "Dropper" then
		startDropper(plot, item, model)
	elseif item.Type == "Upgrader" then
		hookUpgrader(plot, item, model)
	elseif item.Type == "Assembly" then
		local labPrompt = model:FindFirstChild("LabPrompt", true)
		if labPrompt then
			labPrompt.Triggered:Connect(function(who)
				if who == plot.Owner then
					Remotes.OpenUI:FireClient(who, "Lab")
				else
					notify(who, "This is " .. (plot.OwnerName or "someone") .. "'s workshop.", "error")
				end
			end)
		end
		refreshDisplay(plot)
	elseif item.Type == "Shelf" then
		updateTrophyShelf(plot)
	end
end

local function refreshButtons(plot)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	for _, item in ipairs(Config.Items) do
		local existing = plot.ButtonModels[item.Id]
		local show = data ~= nil
			and not data.Purchased[item.Id]
			and (item.Requires == nil or data.Purchased[item.Requires] == true)
		if show and not existing then
			local model = WorldBuilder.BuildButton(plot, item)
			plot.ButtonModels[item.Id] = model
			model.PrimaryPart.Touched:Connect(function(hit)
				local who = Players:GetPlayerFromCharacter(hit.Parent)
				if who and who == plot.Owner then
					tryPurchase(who, item)
				end
			end)
		elseif not show and existing then
			existing:Destroy()
			plot.ButtonModels[item.Id] = nil
		end
	end
	updateButtonColors(plot)
end

function tryPurchase(player, item)
	local data = DataManager.Get(player)
	local runtime = DataManager.Runtime[player]
	local plot = playerPlot[player]
	if not data or not runtime or not plot then
		return
	end
	if data.Purchased[item.Id] then
		return
	end
	if item.Requires and not data.Purchased[item.Requires] then
		return
	end
	if not DataManager.SpendCash(player, item.Cost) then
		if os.clock() - (runtime.LastBuyFail or 0) > 2 then
			runtime.LastBuyFail = os.clock()
			notify(player, "You need " .. Config.Money(item.Cost - data.Cash) .. " more for " .. item.Name, "error")
		end
		return
	end
	data.Purchased[item.Id] = true
	buildItem(plot, item)
	refreshButtons(plot)
	if item.Type == "Assembly" or item.Type == "Bay" then
		refreshBays(plot)
	end
	if item.Type == "Assembly" then
		notify(player, "Robot Lab unlocked! Use the 🤖 button or the workbench to design robots.", "success")
	else
		notify(player, "Built " .. item.Name .. "!", "success")
	end
	DataManager.MarkChanged(player)
end

---------------------------------------------------------------------
-- Claim / release plots
---------------------------------------------------------------------
local function teleportHome(player)
	local plot = playerPlot[player]
	local character = player.Character
	if not character then
		return
	end
	if plot then
		character:PivotTo(plot.SpawnCFrame)
	end
end

local function clearPlot(plot)
	plot.Token += 1
	plot.Items:ClearAllChildren()
	plot.Buttons:ClearAllChildren()
	plot.Drops:ClearAllChildren()
	plot.Bays:ClearAllChildren()
	plot.Built = {}
	plot.ButtonModels = {}
	plot.Storage = 0
	updateStorageLabel(plot)
end

local function loadPlot(plot)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	if not data then
		return
	end
	for _, item in ipairs(Config.Items) do
		if data.Purchased[item.Id] then
			buildItem(plot, item)
		end
	end
	refreshButtons(plot)
	refreshBays(plot)
	refreshDisplay(plot)
end

local function claimPlot(player, plot)
	plot.Owner = player
	plot.OwnerName = player.DisplayName
	playerPlot[player] = plot
	DataManager.Runtime[player].Plot = plot
	plot.OwnerLabel.Text = player.DisplayName .. "'s Workshop"
	clearPlot(plot)
	loadPlot(plot)
end

local function releasePlot(plot)
	clearPlot(plot)
	plot.Owner = nil
	plot.OwnerName = nil
	plot.OwnerLabel.Text = "Empty Workshop"
end

-- collectors & collect pads are permanent, hook them once
for _, plot in ipairs(World.Plots) do
	plot.Collector.Touched:Connect(function(hit)
		if hit.Parent ~= plot.Drops or hit:GetAttribute("Collected") then
			return
		end
		hit:SetAttribute("Collected", true)
		local value = hit:GetAttribute("Value") or 0
		hit:Destroy()
		local owner = plot.Owner
		if not owner or not DataManager.Get(owner) then
			return
		end
		local amount = value * DataManager.GetMultiplier(owner)
		if DataManager.HasPass(owner, "AutoCollect") then
			DataManager.AddCash(owner, amount, false)
		else
			plot.Storage += amount
			updateStorageLabel(plot)
		end
	end)

	local lastCollect = 0
	plot.CollectPad.Touched:Connect(function(hit)
		local who = Players:GetPlayerFromCharacter(hit.Parent)
		if not who or who ~= plot.Owner or plot.Storage < 1 then
			return
		end
		if os.clock() - lastCollect < 0.5 then
			return
		end
		lastCollect = os.clock()
		local amount = DataManager.AddCash(who, plot.Storage, false)
		plot.Storage = 0
		updateStorageLabel(plot)
		notify(who, "+" .. Config.Money(amount) .. " collected", "cash")
	end)
end

---------------------------------------------------------------------
-- Competitions
---------------------------------------------------------------------
local TEAM_LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H", "K", "R", "X", "Y", "Z" }
local function randomTeam()
	return tostring(math.random(100, 99999)) .. TEAM_LETTERS[math.random(1, #TEAM_LETTERS)]
end

local ROUNDS = {
	{ Name = "Quarterfinals", Difficulty = 0.85 },
	{ Name = "Semifinals", Difficulty = 1.0 },
	{ Name = "Finals", Difficulty = 1.15 },
}

local function simulateTournament(rating, comp)
	local results = {}
	local reached = 0
	for i, round in ipairs(ROUNDS) do
		local you = rating * (0.8 + math.random() * 0.45)
		local opp = comp.Difficulty * round.Difficulty * (0.8 + math.random() * 0.4)
		local yourScore = math.floor(you * 1.5 + math.random(0, 8))
		local oppScore = math.floor(opp * 1.5 + math.random(0, 8))
		if yourScore == oppScore then
			yourScore += math.random(0, 1) == 0 and 1 or -1
		end
		local won = yourScore > oppScore
		table.insert(results, { Round = round.Name, You = yourScore, Opp = oppScore, OppTeam = randomTeam(), Won = won })
		if not won then
			break
		end
		reached = i
	end
	return results, reached
end

---------------------------------------------------------------------
-- Request handlers
---------------------------------------------------------------------
local Actions = {}

function Actions.GetData(player)
	return DataManager.GetSnapshot(player)
end

local function hasLab(data)
	return data.Purchased.assembly == true
end

function Actions.UnlockModule(player, data, moduleId)
	local def = Config.ModuleById[moduleId]
	if not def then
		return false, "Unknown part"
	end
	if not hasLab(data) then
		return false, "Buy the Robot Assembly Station first!"
	end
	if data.Modules[def.Id] then
		return false, "Already unlocked"
	end
	if (def.Season or 0) > data.Season then
		return false, "Requires Season " .. def.Season
	end
	if not DataManager.SpendCash(player, def.Cost) then
		return false, "Not enough cash"
	end
	data.Modules[def.Id] = true
	data.Loadout[def.Slot] = def.Id
	local plot = playerPlot[player]
	if plot then
		refreshDisplay(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Unlocked & equipped " .. def.Name .. "!"
end

function Actions.EquipModule(player, data, moduleId)
	local def = Config.ModuleById[moduleId]
	if not def or not data.Modules[def.Id] then
		return false, "You don't own that part"
	end
	data.Loadout[def.Slot] = def.Id
	local plot = playerPlot[player]
	if plot then
		refreshDisplay(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Equipped " .. def.Name
end

function Actions.BuildRobot(player, data)
	if not hasLab(data) then
		return false, "Buy the Robot Assembly Station first!"
	end
	local slots = DataManager.GetGarageSlots(player)
	if #data.Garage >= slots then
		return false, "All robot bays are full! Buy more bays or scrap a robot."
	end
	local stats = Config.GetRobotStats(data.Loadout)
	if not DataManager.SpendCash(player, stats.BuildCost) then
		return false, "Building costs " .. Config.Money(stats.BuildCost)
	end
	table.insert(data.Garage, DataManager.DeepCopy(data.Loadout))
	data.Stats.RobotsBuilt += 1
	if data.Active < 1 then
		data.Active = #data.Garage
	end
	local plot = playerPlot[player]
	if plot then
		refreshBays(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Robot #" .. #data.Garage .. " built! (Rating " .. stats.Rating .. ")"
end

function Actions.ScrapRobot(player, data, index)
	index = tonumber(index)
	local robot = index and data.Garage[index]
	if not robot then
		return false, "No robot there"
	end
	if player:GetAttribute("Driving") then
		return false, "Stop driving first"
	end
	local stats = Config.GetRobotStats(robot)
	local refund = math.floor(stats.BuildCost * Config.ScrapRefund)
	table.remove(data.Garage, index)
	if data.Active == index then
		data.Active = #data.Garage > 0 and 1 or 0
	elseif data.Active > index then
		data.Active -= 1
	end
	DataManager.AddCash(player, refund, false)
	local plot = playerPlot[player]
	if plot then
		refreshBays(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Scrapped robot for " .. Config.Money(refund)
end

function Actions.SetActive(player, data, index)
	index = tonumber(index)
	if not index or not data.Garage[index] then
		return false, "No robot there"
	end
	if player:GetAttribute("Driving") then
		return false, "Stop driving first"
	end
	data.Active = index
	local plot = playerPlot[player]
	if plot then
		refreshBays(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Robot #" .. index .. " is now your competition robot"
end

function Actions.EnterCompetition(player, data, compId)
	local comp = Config.CompetitionById[compId]
	if not comp then
		return false, "Unknown competition"
	end
	local robot = data.Garage[data.Active]
	if not robot then
		return false, "Build a robot in the Robot Lab first!"
	end
	local stats = Config.GetRobotStats(robot)
	if stats.Rating < comp.MinRating then
		return false, "Your robot needs a rating of " .. comp.MinRating
	end
	local runtime = DataManager.Runtime[player]
	local readyAt = runtime.Cooldowns[comp.Id] or 0
	if os.time() < readyAt then
		return false, "Next event in " .. (readyAt - os.time()) .. "s"
	end
	if not DataManager.SpendCash(player, comp.Fee) then
		return false, "Entry fee is " .. Config.Money(comp.Fee)
	end
	runtime.Cooldowns[comp.Id] = os.time() + comp.Cooldown
	data.Stats.CompsEntered += 1

	local rounds, reached = simulateTournament(stats.Rating, comp)
	local prize = 0
	local trophies = 0
	local payout = Config.CompetitionPayout[reached] or 0
	if payout > 0 then
		prize = DataManager.AddCash(player, comp.Prize * payout, true)
	end
	if reached == 3 then
		trophies = comp.Trophies
		data.Stats.CompWins += 1
	elseif reached == 2 then
		trophies = math.max(1, math.floor(comp.Trophies / 3))
	end
	if trophies > 0 then
		DataManager.AddTrophies(player, trophies)
	end
	local plot = playerPlot[player]
	if plot then
		updateTrophyShelf(plot)
	end
	DataManager.MarkChanged(player)
	return true, {
		Competition = comp.Name,
		Rounds = rounds,
		Reached = reached,
		Prize = prize,
		Trophies = trophies,
		Champion = reached == 3,
	}
end

function Actions.Rebirth(player, data)
	local cost = Config.GetSeasonCost(data.Season)
	if data.Cash < cost then
		return false, "You need " .. Config.Money(cost) .. " to start a new season"
	end
	if player:GetAttribute("Driving") then
		return false, "Stop driving first"
	end
	local modules, loadout = DataManager.DefaultModules()
	data.Season += 1
	data.Cash = Config.StartingCash
	data.Purchased = {}
	data.Modules = modules
	data.Loadout = loadout
	data.Garage = {}
	data.Active = 0
	DataManager.UpdateLeaderstats(player)
	local plot = playerPlot[player]
	if plot then
		clearPlot(plot)
		loadPlot(plot)
	end
	DataManager.MarkChanged(player)
	task.spawn(DataManager.Save, player)
	local mult = Config.GetMultiplier(data.Season, false)
	return true, "Season " .. data.Season .. " begins! Permanent x" .. mult .. " cash."
end

function Actions.PromptPass(player, _, key)
	for _, pass in ipairs(Config.GamePasses) do
		if pass.Key == key then
			if not pass.Id or pass.Id <= 0 then
				return false, "This pass isn't set up yet (add its ID in Config)."
			end
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			return true
		end
	end
	return false, "Unknown pass"
end

Remotes.Request.OnServerInvoke = function(player, action, ...)
	local handler = Actions[action]
	local data = DataManager.Get(player)
	if not handler then
		return false, "Unknown action"
	end
	if not data then
		return false, "Your data is still loading..."
	end
	local runtime = DataManager.Runtime[player]
	if runtime.Busy then
		return false, "Slow down!"
	end
	runtime.Busy = true
	local ok, a, b = pcall(handler, player, data, ...)
	runtime.Busy = false
	if not ok then
		warn("[TycoonServer] Action", action, "failed:", a)
		return false, "Something went wrong"
	end
	return a, b
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	for _, pass in ipairs(Config.GamePasses) do
		if pass.Id == passId then
			DataManager.GrantPass(player, pass.Key)
			notify(player, "Thanks for buying " .. pass.Name .. "!", "success")
			local plot = playerPlot[player]
			if plot and pass.Key == "ExtraBays" then
				refreshBays(plot)
			end
		end
	end
end)

World.Hub.CompetitionPrompt.Triggered:Connect(function(player)
	Remotes.OpenUI:FireClient(player, "Compete")
end)

---------------------------------------------------------------------
-- Players
---------------------------------------------------------------------
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		teleportHome(player)
	end)

	local data = DataManager.Load(player)
	if not data then
		return
	end

	local plot = nil
	for _, candidate in ipairs(World.Plots) do
		if not candidate.Owner then
			plot = candidate
			break
		end
	end
	if plot then
		claimPlot(player, plot)
		teleportHome(player)
	else
		notify(player, "All workshops are full - you can still compete and drive!", "error")
	end
	pushData(player)
	task.delay(2, function()
		if player.Parent then
			notify(player, "Welcome to " .. Config.GameName .. "! Step on the green buttons to build your workshop.", "info")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local plot = playerPlot[player]
	if plot then
		releasePlot(plot)
	end
	playerPlot[player] = nil
	pendingPush[player] = nil
end)

DataManager.Changed:Connect(function(player)
	pushData(player)
	local plot = playerPlot[player]
	if plot then
		updateTrophyShelf(plot)
	end
end)

---------------------------------------------------------------------
-- Loops: robot income + button colors, leaderboard
---------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		for player, plot in pairs(playerPlot) do
			if DataManager.Get(player) then
				local income = DataManager.GetRobotIncome(player)
				if income > 0 then
					DataManager.AddCash(player, income, true)
				end
				updateButtonColors(plot)
			end
		end
	end
end)

local leaderboardStore = nil
pcall(function()
	leaderboardStore = DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)
end)
local nameCache = {}

local function showOnlineLeaderboard(rows)
	-- no datastore (e.g. unpublished place in Studio): rank online players instead
	local list = {}
	for player, data in pairs(DataManager.Profiles) do
		table.insert(list, { Name = player.DisplayName, Value = data.Trophies })
	end
	table.sort(list, function(a, b)
		return a.Value > b.Value
	end)
	for i, row in ipairs(rows) do
		local entry = list[i]
		row.Text = entry and string.format("  #%d  %s - %s 🏆", i, entry.Name, Config.Format(entry.Value)) or string.format("  #%d  ---", i)
	end
end

local function refreshLeaderboard()
	local rows = World.Hub.LeaderboardRows
	if not leaderboardStore then
		showOnlineLeaderboard(rows)
		return
	end
	for player, data in pairs(DataManager.Profiles) do
		pcall(function()
			leaderboardStore:SetAsync(tostring(player.UserId), data.Trophies)
		end)
	end
	local ok, pages = pcall(function()
		return leaderboardStore:GetSortedAsync(false, 10)
	end)
	if not ok then
		showOnlineLeaderboard(rows)
		return
	end
	local entries = pages:GetCurrentPage()
	for i, row in ipairs(rows) do
		local entry = entries[i]
		if entry then
			local userId = tonumber(entry.key)
			local name = nameCache[userId]
			if not name then
				local success, result = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				name = success and result or ("User " .. tostring(userId))
				nameCache[userId] = name
			end
			row.Text = string.format("  #%d  %s - %s 🏆", i, name, Config.Format(entry.value))
		else
			row.Text = string.format("  #%d  ---", i)
		end
	end
end

task.spawn(function()
	task.wait(10)
	while true do
		refreshLeaderboard()
		task.wait(60)
	end
end)
]=] })
table.insert(files, { Class = "Script", Service = "ServerScriptService", Sub = nil, Name = "ArenaServer", Source = [=[
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
]=] })
table.insert(files, { Class = "LocalScript", Service = "StarterPlayer", Sub = "StarterPlayerScripts", Name = "MainUI", Source = [=[
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
]=] })
table.insert(files, { Class = "LocalScript", Service = "StarterPlayer", Sub = "StarterPlayerScripts", Name = "DriveClient", Source = [=[
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
]=] })
for _, f in ipairs(files) do
	local parent = game:GetService(f.Service)
	if f.Sub then
		parent = parent:WaitForChild(f.Sub)
	end
	local old = parent:FindFirstChild(f.Name)
	if old then
		old:Destroy()
	end
	local s = Instance.new(f.Class)
	s.Name = f.Name
	s.Source = f.Source
	s.Parent = parent
end
ChangeHistoryService:SetWaypoint("Installed VEX Tycoon")
print("VEX Robotics Tycoon installed! " .. #files .. " scripts created. Press Play to test.")

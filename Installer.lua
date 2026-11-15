-- VEX Robotics Tycoon installer
-- Paste ALL of this into Roblox Studio > View > Command Bar and press Enter.
-- It creates (or replaces) every game script. Undo with Ctrl+Z.
local ChangeHistoryService = game:GetService("ChangeHistoryService")
ChangeHistoryService:SetWaypoint("Before VEX Tycoon install")
-- remove scripts from older versions that moved
local oldBuilder = game:GetService("ServerScriptService"):FindFirstChild("RobotBuilder")
if oldBuilder then
	oldBuilder:Destroy()
end
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
table.insert(files, { Class = "ModuleScript", Service = "ReplicatedStorage", Sub = nil, Name = "RobotBuilder", Source = [=[
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
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
	card.BackgroundTransparency = 0.25
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = card
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0.05, 0.1)
	label.Size = UDim2.fromScale(0.9, 0.8)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = card
	return label
end

-- two-line "shop tag" used above tycoon buttons
local function priceTag(adornee, name, price, isFree)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(9, 0, 3, 0)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Parent = adornee
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 0.62)
	card.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
	card.BackgroundTransparency = 0.15
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = card
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromScale(0.05, 0.12)
	nameLabel.Size = UDim2.fromScale(0.9, 0.76)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = name
	nameLabel.Parent = card
	local pill = Instance.new("Frame")
	pill.AnchorPoint = Vector2.new(0.5, 0)
	pill.Position = UDim2.fromScale(0.5, 0.64)
	pill.Size = UDim2.fromScale(0.5, 0.36)
	pill.BackgroundColor3 = isFree and Color3.fromRGB(245, 190, 50) or Color3.fromRGB(46, 190, 100)
	pill.Parent = gui
	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(0.5, 0)
	pillCorner.Parent = pill
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Position = UDim2.fromScale(0.08, 0.1)
	priceLabel.Size = UDim2.fromScale(0.84, 0.8)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.TextColor3 = Color3.fromRGB(15, 20, 25)
	priceLabel.Text = price
	priceLabel.Parent = pill
	return pill
end

local function setupLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(135, 135, 150)
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
	ensure("Atmosphere", { Density = 0.28, Offset = 0.2, Color = Color3.fromRGB(200, 215, 235), Decay = Color3.fromRGB(110, 120, 150), Glare = 0.1, Haze = 1 })
	ensure("BloomEffect", { Intensity = 0.5, Size = 28, Threshold = 1.4 })
	ensure("ColorCorrectionEffect", { Saturation = 0.12, Contrast = 0.06, Brightness = 0.01 })
	ensure("SunRaysEffect", { Intensity = 0.06, Spread = 0.6 })
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
	plot.StorageLabel = billboard(collectPad, "Step here to collect\n$0", 9, 3, Vector3.new(0, 4, 0), Color3.fromRGB(120, 255, 140))

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
	priceTag(pad, item.Name, priceText, item.Cost == 0)
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

	setupLighting()
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
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
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
	local sub = robot.Root:FindFirstChild("Sub", true)
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
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
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

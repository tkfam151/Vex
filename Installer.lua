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
Config.PlotRadius = 275 -- distance from hub center to each workshop
Config.PlotSize = 150
Config.HubRadius = 175
Config.ConveyorSpeed = 10
Config.DropLifetime = 25
Config.MaxDropsPerPlot = 80

Config.PlotColors = {
	Color3.fromRGB(196, 38, 46), -- VEX red
	Color3.fromRGB(28, 92, 178), -- alliance blue
	Color3.fromRGB(46, 130, 84), -- green
	Color3.fromRGB(204, 150, 40), -- amber
	Color3.fromRGB(104, 72, 160), -- violet
	Color3.fromRGB(196, 96, 40), -- orange
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
	Drivetrain = { Desc = "Speed and pushing power. Holonomic drives can strafe with Q and E." },
	Intake = { Desc = "How many balls you can hold, and how easily you pick them up." },
	Lift = { Desc = "How many points each scored ball is worth." },
	Brain = { Desc = "Driver control, plus autonomous points at the start of every match." },
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
-- Rarities (shared by seeds and market robots)
---------------------------------------------------------------------
Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }
Config.Rarities = {
	Common = { Color = Color3.fromRGB(210, 210, 210), Weight = 50 },
	Uncommon = { Color = Color3.fromRGB(90, 225, 90), Weight = 28 },
	Rare = { Color = Color3.fromRGB(70, 160, 255), Weight = 14 },
	Epic = { Color = Color3.fromRGB(190, 100, 255), Weight = 6 },
	Legendary = { Color = Color3.fromRGB(255, 195, 40), Weight = 1.8 },
	Mythic = { Color = Color3.fromRGB(255, 70, 130), Weight = 0.2 },
}

---------------------------------------------------------------------
-- Garden: plant seeds, wait, harvest, sell
---------------------------------------------------------------------
Config.Garden = {
	RestockInterval = 300, -- seconds between seed shop restocks
	MaxBackpack = 200,
	StartingSeeds = { gear = 3 },
	SellDistance = 25, -- how close to the Sell Stand you must be to sell from the menu
	-- 12 beds on the right side of every workshop (plot-local positions)
	TileSize = 9,
	TileColumns = { 59, 69 },
	TileRows = { -52, -42, -32, -22, -12, -2 },
	-- chance the stock includes a seed, and how many, by rarity
	Stock = {
		Common = { Chance = 1, Min = 6, Max = 15 },
		Uncommon = { Chance = 0.8, Min = 2, Max = 8 },
		Rare = { Chance = 0.5, Min = 1, Max = 4 },
		Epic = { Chance = 0.25, Min = 1, Max = 2 },
		Legendary = { Chance = 0.08, Min = 1, Max = 1 },
		Mythic = { Chance = 0.02, Min = 1, Max = 1 },
	},
	-- rolled when a seed is planted
	Mutations = {
		{ Name = "Titanium", Chance = 0.005, Multiplier = 15, Color = Color3.fromRGB(200, 210, 230) },
		{ Name = "Golden", Chance = 0.025, Multiplier = 5, Color = Color3.fromRGB(255, 200, 40) },
		{ Name = "Shiny", Chance = 0.08, Multiplier = 2, Color = Color3.fromRGB(120, 235, 255) },
	},
}

Config.Seeds = {
	{ Id = "gear", Name = "Gear Sprout", Rarity = "Common", Price = 10, GrowTime = 30, Value = 18, Color = Color3.fromRGB(170, 170, 180) },
	{ Id = "bolt", Name = "Bolt Bush", Rarity = "Common", Price = 25, GrowTime = 45, Value = 45, Color = Color3.fromRGB(120, 130, 145) },
	{ Id = "spring", Name = "Spring Vine", Rarity = "Uncommon", Price = 80, GrowTime = 90, Value = 150, Color = Color3.fromRGB(90, 220, 120) },
	{ Id = "motor", Name = "Motor Melon", Rarity = "Uncommon", Price = 200, GrowTime = 150, Value = 400, Color = Color3.fromRGB(220, 60, 60) },
	{ Id = "battery", Name = "Battery Berry", Rarity = "Rare", Price = 750, GrowTime = 240, Value = 1500, Color = Color3.fromRGB(60, 140, 255) },
	{ Id = "sensor", Name = "Sensor Sunflower", Rarity = "Rare", Price = 2000, GrowTime = 360, Value = 4200, Color = Color3.fromRGB(255, 210, 40) },
	{ Id = "chip", Name = "Microchip Mango", Rarity = "Epic", Price = 8000, GrowTime = 600, Value = 18000, Color = Color3.fromRGB(255, 140, 40) },
	{ Id = "brain", Name = "Brain Blossom", Rarity = "Legendary", Price = 40000, GrowTime = 900, Value = 100000, Color = Color3.fromRGB(255, 120, 200) },
	{ Id = "quantum", Name = "Quantum Cactus", Rarity = "Mythic", Price = 250000, GrowTime = 1800, Value = 700000, Color = Color3.fromRGB(170, 80, 255) },
}
Config.SeedById = {}
for i, seed in ipairs(Config.Seeds) do
	seed.Index = i
	Config.SeedById[seed.Id] = seed
end

function Config.GetMutation(name)
	for _, m in ipairs(Config.Garden.Mutations) do
		if m.Name == name then
			return m
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Robot Market: buy robots off the conveyor, they earn at your base,
-- other players can steal them. Lock your base to stop thieves.
---------------------------------------------------------------------
Config.Market = {
	SpawnInterval = 4,
	Speed = 5, -- studs per second along the conveyor
	Start = Vector3.new(-95, 0.8, -140),
	End = Vector3.new(95, 0.8, -140),
	-- 8 showcase pads on the left side of every workshop
	PadSize = 9,
	PadColumns = { -69, -58 },
	PadRows = { -52, -40, -28, -16 },
	StealHold = 1.2, -- seconds to hold the steal prompt
	StealTimeout = 90, -- thief must reach their base within this time
	CarrySpeed = 12, -- thief walk speed while carrying
	RecoverDistance = 7, -- owner gets the robot back by touching the thief
	LockDuration = 60,
	LockCooldown = 20,
	LockPad = Vector3.new(-58, 0, -66),
	Mutations = {
		{ Name = "Diamond", Chance = 0.01, Multiplier = 8, Tint = Color3.fromRGB(140, 230, 255) },
		{ Name = "Gold", Chance = 0.05, Multiplier = 3, Tint = Color3.fromRGB(255, 200, 40) },
	},
}

Config.Species = {
	{ Id = "clawbot", Name = "Clawbot", Rarity = "Common", Price = 100, Income = 2, Scale = 0.8, Loadout = { Drivetrain = "dt_basic", Intake = "in_claw", Lift = "lf_none", Brain = "br_basic" } },
	{ Id = "pushbot", Name = "Pushbot", Rarity = "Common", Price = 250, Income = 5, Scale = 0.85, Loadout = { Drivetrain = "dt_4m", Intake = "in_claw", Lift = "lf_none", Brain = "br_basic" } },
	{ Id = "stackbot", Name = "Stackbot", Rarity = "Uncommon", Price = 900, Income = 15, Scale = 0.9, Loadout = { Drivetrain = "dt_4m", Intake = "in_flex", Lift = "lf_4bar", Brain = "br_v5" } },
	{ Id = "scoopbot", Name = "Scoopbot", Rarity = "Uncommon", Price = 1800, Income = 28, Scale = 0.95, Loadout = { Drivetrain = "dt_omni", Intake = "in_roller", Lift = "lf_none", Brain = "br_v5" } },
	{ Id = "flingbot", Name = "Flingbot", Rarity = "Rare", Price = 6000, Income = 80, Scale = 1, Loadout = { Drivetrain = "dt_omni", Intake = "in_roller", Lift = "lf_cata", Brain = "br_pid" } },
	{ Id = "spinbot", Name = "Spinbot", Rarity = "Rare", Price = 12000, Income = 150, Scale = 1, Loadout = { Drivetrain = "dt_mecanum", Intake = "in_chain", Lift = "lf_dr4b", Brain = "br_pid" } },
	{ Id = "shooterbot", Name = "Shooterbot", Rarity = "Epic", Price = 45000, Income = 450, Scale = 1.1, Loadout = { Drivetrain = "dt_mecanum", Intake = "in_chain", Lift = "lf_fly", Brain = "br_odom" } },
	{ Id = "climbbot", Name = "Climbbot", Rarity = "Epic", Price = 90000, Income = 850, Scale = 1.15, Loadout = { Drivetrain = "dt_xdrive", Intake = "in_dual", Lift = "lf_cascade", Brain = "br_odom" } },
	{ Id = "skillsbot", Name = "Skills Champion", Rarity = "Legendary", Price = 350000, Income = 2800, Scale = 1.25, Loadout = { Drivetrain = "dt_blue", Intake = "in_dual", Lift = "lf_cata", Brain = "br_vision" } },
	{ Id = "worldsbot", Name = "Worlds Finalist", Rarity = "Legendary", Price = 800000, Income = 6500, Scale = 1.3, Loadout = { Drivetrain = "dt_worlds", Intake = "in_pro", Lift = "lf_fly", Brain = "br_vision" } },
	{ Id = "prototype", Name = "Golden Prototype", Rarity = "Mythic", Price = 3000000, Income = 25000, Scale = 1.45, Loadout = { Drivetrain = "dt_worlds", Intake = "in_pro", Lift = "lf_fly", Brain = "br_worlds" } },
}
Config.SpeciesById = {}
for _, sp in ipairs(Config.Species) do
	Config.SpeciesById[sp.Id] = sp
end

function Config.GetMarketMutation(name)
	for _, m in ipairs(Config.Market.Mutations) do
		if m.Name == name then
			return m
		end
	end
	return nil
end

-- income per second of a showcase entry { S = speciesId, M = mutation }
function Config.ShowcaseIncome(entry)
	local sp = entry and Config.SpeciesById[entry.S]
	if not sp then
		return 0
	end
	local m = entry.M and Config.GetMarketMutation(entry.M)
	return sp.Income * (m and m.Multiplier or 1)
end

---------------------------------------------------------------------
-- Game passes: put your real Game Pass IDs here (0 = disabled)
---------------------------------------------------------------------
Config.GamePasses = {
	{ Key = "DoubleCash", Name = "2x Cash", Id = 0, Desc = "Double all cash you earn, forever." },
	{ Key = "AutoCollect", Name = "Auto Collect", Id = 0, Desc = "Workshop cash goes straight to your wallet." },
	{ Key = "ExtraBays", Name = "+2 Robot Bays", Id = 0, Desc = "Two extra robot bays (needs Assembly Station)." },
	{ Key = "Turbo", Name = "Turbo Motors", Id = 0, Desc = "+15% drive speed in practice & ranked." },
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

-- fired by TycoonServer so other systems (garden, market) can react
local plotClaimed = Instance.new("BindableEvent")
local plotReleased = Instance.new("BindableEvent")
local progressReset = Instance.new("BindableEvent")
DataManager.PlotClaimed = plotClaimed.Event -- (player, plot)
DataManager.PlotReleased = plotReleased.Event -- (player, plot)
DataManager.ProgressReset = progressReset.Event -- (player) after a new season
function DataManager.FirePlotClaimed(player, plot)
	plotClaimed:Fire(player, plot)
end
function DataManager.FirePlotReleased(player, plot)
	plotReleased:Fire(player, plot)
end
function DataManager.FireProgressReset(player)
	progressReset:Fire(player)
end

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
	SimRequest = getRemote("RemoteFunction", "SimRequest"), -- garden / market
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
		elseif type(value) == "table" and type(data[key]) == "table" and key ~= "Garage" and key ~= "Seeds" then
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
		Seeds = deepCopy(Config.Garden.StartingSeeds),
		Garden = {}, -- ["t1"] = { S = seedId, T = plantedAt, M = mutation }
		Backpack = {}, -- { { S = seedId, M = mutation, V = value } }
		Showcase = {}, -- ["p1"] = { S = speciesId, M = mutation }
		Stats = {
			CompWins = 0,
			CompsEntered = 0,
			MatchesPlayed = 0,
			MatchesWon = 0,
			BallsScored = 0,
			RobotsBuilt = 0,
			TotalEarned = 0,
			Harvests = 0,
			Steals = 0,
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
		Seeds = data.Seeds,
		Garden = data.Garden,
		Backpack = data.Backpack,
		Showcase = data.Showcase,
		Stock = runtime and runtime.Stock or {},
		SelectedSeed = runtime and runtime.SelectedSeed or nil,
		LockedUntil = runtime and runtime.Plot and runtime.Plot.LockedUntil or 0,
		LockReadyAt = runtime and runtime.Plot and runtime.Plot.LockReadyAt or 0,
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
	  TitleColor = Color3 for the name tag title
	  Tint       = Color3 to recolor the whole robot (mutations)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local RobotBuilder = {}

local FONT_BOLD = Font.fromEnum(Enum.Font.FredokaOne)

local METAL = Color3.fromRGB(196, 198, 204)
local DARK = Color3.fromRGB(35, 35, 40)
local MOTOR = Color3.fromRGB(55, 30, 30)

local function makeBillboard(root, label, subLabel, titleColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.new(10, 0, 2.6, 0)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.MaxDistance = 110
	gui.LightInfluence = 0
	gui.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.FontFace = FONT_BOLD
	title.TextScaled = true
	title.TextColor3 = titleColor or Color3.new(1, 1, 1)
	title.Text = label or "Robot"
	title.Parent = gui
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 2
	titleStroke.Parent = title

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.FontFace = FONT_BOLD
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(120, 255, 100)
	sub.Text = subLabel or ""
	sub.Parent = gui
	local subStroke = Instance.new("UIStroke")
	subStroke.Thickness = 1.5
	subStroke.Parent = sub
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
			add("Hub", Vector3.new(0.85, wheelD * 0.4, wheelD * 0.4), cf, accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
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
		add("Flywheel", Vector3.new(0.7, 3.2, 3.2), CFrame.new(0, wy + 2.8, 2.3), liftColor, Enum.Material.Metal, Enum.PartType.Cylinder)
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
		makeBillboard(root, options.Label, options.SubLabel, options.TitleColor)
	end

	-------------------------------------------------------------- optional full-body tint (mutations)
	if options.Tint then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d ~= root and d.Name ~= "Screen" then
				d.Color = options.Tint
				d.Material = Enum.Material.Metal
				d.Reflectance = 0.15
			end
		end
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
			label.Text = Config.Format(data.Trophies) .. " TROPHIES"
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
			local label = "Robot " .. i .. (i == data.Active and "  ·  Active" or "")
			local robot = RobotBuilder.Build(loadout, {
				Name = "BayRobot" .. i,
				TeamColor = plot.Color,
				Label = label,
				SubLabel = "Rating " .. stats.Rating .. "  ·  +" .. Config.Money(stats.Income * mult) .. "/s",
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
		notify(player, "Robot Lab unlocked! Open ROBOTS from the menu or use the workbench.", "success")
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
	DataManager.FirePlotClaimed(player, plot)
end

local function releasePlot(plot)
	if plot.Owner then
		DataManager.FirePlotReleased(plot.Owner, plot)
	end
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
	data.Seeds = DataManager.DeepCopy(Config.Garden.StartingSeeds)
	data.Garden = {}
	data.Backpack = {}
	data.Showcase = {}
	DataManager.UpdateLeaderstats(player)
	local plot = playerPlot[player]
	if plot then
		clearPlot(plot)
		loadPlot(plot)
	end
	DataManager.FireProgressReset(player)
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
		row.Text = entry and string.format("  %d    %s    %s", i, entry.Name, Config.Format(entry.Value)) or string.format("  %d    —", i)
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
			row.Text = string.format("  %d    %s    %s", i, name, Config.Format(entry.value))
		else
			row.Text = string.format("  %d    —", i)
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
		notify(player, "Victory. +" .. Config.Money(cash) .. " and +" .. Config.Match.WinTrophies .. " trophies", "success")
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
				notify(m[side], "Autonomous bonus: +" .. s.Stats.Auton .. " points", "success")
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
		notify(p, "Ranked match. Score in your " .. (p == red and "RED" or "BLUE") .. " goal. Leaving your robot forfeits.", "info")
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
table.insert(files, { Class = "Script", Service = "ServerScriptService", Sub = nil, Name = "SimServer", Source = [=[
--[[
	SimServer (Script)  ->  ServerScriptService.SimServer

	Garden:  buy seeds at the Seed Shop (restocks every few minutes), plant
	         them in the beds at your workshop, harvest when ripe, sell your
	         backpack at the Sell Stand. Crops keep growing while you're away.
	Market:  robots ride the Robot Market conveyor in the hub. Buy one and it
	         stands on a showcase pad at your base, filling it with cash.
	Steal:   hold the prompt on someone else's robot, then carry it back to
	         your own base. The owner gets it back by catching you. Step on
	         your lock pad to raise laser walls for a minute.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local WorldBuilder = require(ServerScriptService:WaitForChild("WorldBuilder"))

local Remotes = DataManager.Remotes
local World = WorldBuilder.GetWorld()
local Hub = World.Hub
local Garden = Config.Garden
local Market = Config.Market

local function notify(player, text, kind)
	DataManager.Notify(player, text, kind)
end

local function plotOf(player)
	for _, plot in ipairs(World.Plots) do
		if plot.Owner == player then
			return plot
		end
	end
	return nil
end

local function rarityColor(rarity)
	local r = Config.Rarities[rarity]
	return r and r.Color or Color3.new(1, 1, 1)
end

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root then
		return root, humanoid, character
	end
	return nil, nil, nil
end

-- true if a world position is inside a plot's square
local function insidePlot(plot, position)
	local localPos = plot.CFrame:PointToObjectSpace(position)
	local half = Config.PlotSize / 2
	return math.abs(localPos.X) <= half and math.abs(localPos.Z) <= half
end

---------------------------------------------------------------------
-- Seed shop stock
---------------------------------------------------------------------
local globalStock = {}

local function rollStock()
	local stock = {}
	for _, seed in ipairs(Config.Seeds) do
		local rule = Garden.Stock[seed.Rarity]
		if rule and math.random() <= rule.Chance then
			stock[seed.Id] = math.random(rule.Min, rule.Max)
		end
	end
	return stock
end

local function restock()
	globalStock = rollStock()
	Remotes.Folder:SetAttribute("RestockAt", os.time() + Garden.RestockInterval)
	for player, runtime in pairs(DataManager.Runtime) do
		runtime.Stock = DataManager.DeepCopy(globalStock)
		if player.Parent then
			DataManager.MarkChanged(player)
		end
	end
end

task.spawn(function()
	restock()
	while true do
		task.wait(Garden.RestockInterval)
		restock()
		for _, player in ipairs(Players:GetPlayers()) do
			notify(player, "The Seed Shop has restocked!", "info")
		end
	end
end)

---------------------------------------------------------------------
-- Garden beds
---------------------------------------------------------------------
local function rollGardenMutation()
	for _, m in ipairs(Garden.Mutations) do
		if math.random() < m.Chance then
			return m.Name
		end
	end
	return nil
end

local function growthOf(entry)
	local seed = Config.SeedById[entry.S]
	if not seed then
		return 1, 0
	end
	local elapsed = os.time() - entry.T
	return math.clamp(elapsed / seed.GrowTime, 0, 1), math.max(0, seed.GrowTime - elapsed)
end

local function renderTile(plot, tile)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	local entry = data and data.Garden[tile.Key]
	local model = tile.Model
	if not entry then
		if model then
			model:Destroy()
			tile.Model = nil
		end
		tile.Prompt.ActionText = "Plant"
		tile.Prompt.ObjectText = "Empty Bed"
		return
	end
	local seed = Config.SeedById[entry.S]
	if not seed then
		data.Garden[tile.Key] = nil
		return
	end
	local mutation = entry.M and Config.GetMutation(entry.M)
	local progress, remaining = growthOf(entry)
	local top = tile.Part.CFrame * CFrame.new(0, tile.Part.Size.Y / 2, 0)

	if not model then
		model = Instance.new("Model")
		model.Name = "Plant"
		local stem = Instance.new("Part")
		stem.Name = "Stem"
		stem.Anchored = true
		stem.CanCollide = false
		stem.CanQuery = false
		stem.Color = Color3.fromRGB(70, 170, 60)
		stem.Material = Enum.Material.SmoothPlastic
		stem.Parent = model
		local fruit = Instance.new("Part")
		fruit.Name = "Fruit"
		fruit.Shape = Enum.PartType.Ball
		fruit.Anchored = true
		fruit.CanCollide = false
		fruit.CanQuery = false
		fruit.Material = Enum.Material.SmoothPlastic
		fruit.Parent = model
		for _, side in ipairs({ -1, 1 }) do
			local leaf = Instance.new("Part")
			leaf.Name = "Leaf"
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.CanQuery = false
			leaf.Color = Color3.fromRGB(90, 200, 70)
			leaf.Material = Enum.Material.SmoothPlastic
			leaf:SetAttribute("Side", side)
			leaf.Parent = model
		end
		local gui = Instance.new("BillboardGui")
		gui.Name = "Tag"
		gui.Size = UDim2.new(7, 0, 2, 0)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
		gui.MaxDistance = 60
		gui.LightInfluence = 0
		gui.Adornee = tile.Part
		gui.Parent = model
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = label
		model.Parent = plot.Items.Parent
		tile.Model = model
	end

	local stemHeight = 0.8 + 3.2 * progress
	local fruitSize = 0.6 + 2.6 * progress
	model.Stem.Size = Vector3.new(0.5, stemHeight, 0.5)
	model.Stem.CFrame = top * CFrame.new(0, stemHeight / 2, 0)
	for _, leaf in ipairs(model:GetChildren()) do
		if leaf.Name == "Leaf" then
			local side = leaf:GetAttribute("Side")
			leaf.Size = Vector3.new(0.6 + 1.6 * progress, 0.2, 0.8 + 0.8 * progress)
			leaf.CFrame = top * CFrame.new(side * (0.4 + 0.8 * progress), stemHeight * 0.45, 0) * CFrame.Angles(0, 0, math.rad(side * 20))
		end
	end
	model.Fruit.Size = Vector3.one * fruitSize
	model.Fruit.CFrame = top * CFrame.new(0, stemHeight + fruitSize * 0.35, 0)
	model.Fruit.Color = mutation and mutation.Color or seed.Color
	model.Fruit.Material = mutation and Enum.Material.Neon or Enum.Material.SmoothPlastic

	local label = model.Tag.Label
	local name = (mutation and (mutation.Name .. " ") or "") .. seed.Name
	if progress >= 1 then
		label.Text = name .. "\nREADY!"
		label.TextColor3 = Color3.fromRGB(120, 255, 100)
		tile.Prompt.ActionText = "Harvest"
	else
		label.Text = name .. "\n" .. (remaining >= 60 and string.format("%dm %ds", remaining // 60, remaining % 60) or (remaining .. "s"))
		label.TextColor3 = Color3.new(1, 1, 1)
		tile.Prompt.ActionText = "Growing..."
	end
	tile.Prompt.ObjectText = name
end

local function renderGarden(plot)
	for _, tile in ipairs(plot.GardenTiles) do
		renderTile(plot, tile)
	end
end

local function clearGarden(plot)
	for _, tile in ipairs(plot.GardenTiles) do
		if tile.Model then
			tile.Model:Destroy()
			tile.Model = nil
		end
		tile.Prompt.Enabled = false
	end
end

local function onBedTriggered(plot, tile, player)
	if player ~= plot.Owner then
		notify(player, "That's someone else's garden!", "error")
		return
	end
	local data = DataManager.Get(player)
	local runtime = DataManager.Runtime[player]
	if not data or not runtime then
		return
	end
	local entry = data.Garden[tile.Key]
	if entry then
		local progress, remaining = growthOf(entry)
		if progress < 1 then
			notify(player, "Still growing. Ready in " .. remaining .. "s", "info")
			return
		end
		if #data.Backpack >= Garden.MaxBackpack then
			notify(player, "Your backpack is full! Sell at the Sell Stand.", "error")
			return
		end
		local seed = Config.SeedById[entry.S]
		local mutation = entry.M and Config.GetMutation(entry.M)
		local value = math.floor(seed.Value * (mutation and mutation.Multiplier or 1))
		table.insert(data.Backpack, { S = entry.S, M = entry.M, V = value })
		data.Garden[tile.Key] = nil
		data.Stats.Harvests += 1
		notify(player, "Harvested " .. (entry.M and (entry.M .. " ") or "") .. seed.Name .. " (" .. Config.Money(value) .. ")", "success")
		renderTile(plot, tile)
		DataManager.MarkChanged(player)
		return
	end

	-- plant: use the selected seed, otherwise the first one you own
	local seedId = runtime.SelectedSeed
	if not seedId or (data.Seeds[seedId] or 0) <= 0 then
		seedId = nil
		for _, seed in ipairs(Config.Seeds) do
			if (data.Seeds[seed.Id] or 0) > 0 then
				seedId = seed.Id
				break
			end
		end
	end
	if not seedId then
		notify(player, "You have no seeds. Buy some at the Seed Shop!", "error")
		return
	end
	data.Seeds[seedId] -= 1
	if data.Seeds[seedId] <= 0 then
		data.Seeds[seedId] = nil
	end
	local mutation = rollGardenMutation()
	data.Garden[tile.Key] = { S = seedId, T = os.time(), M = mutation }
	if mutation then
		notify(player, "Lucky! Your " .. Config.SeedById[seedId].Name .. " is growing " .. mutation .. "!", "success")
	end
	renderTile(plot, tile)
	DataManager.MarkChanged(player)
end

for _, plot in ipairs(World.Plots) do
	for _, tile in ipairs(plot.GardenTiles) do
		tile.Prompt.Triggered:Connect(function(player)
			onBedTriggered(plot, tile, player)
		end)
	end
end

local function sellBackpack(player)
	local data = DataManager.Get(player)
	if not data then
		return false, "Data still loading"
	end
	if #data.Backpack == 0 then
		return false, "Your backpack is empty. Harvest some crops first!"
	end
	local total = 0
	for _, item in ipairs(data.Backpack) do
		total += item.V or 0
	end
	local count = #data.Backpack
	data.Backpack = {}
	local earned = DataManager.AddCash(player, total, true)
	DataManager.MarkChanged(player)
	return true, "Sold " .. count .. " crops for " .. Config.Money(earned) .. "!"
end

Hub.SellPrompt.Triggered:Connect(function(player)
	local ok, msg = sellBackpack(player)
	notify(player, msg, ok and "cash" or "error")
end)

Hub.SeedPrompt.Triggered:Connect(function(player)
	Remotes.OpenUI:FireClient(player, "Seeds")
end)

---------------------------------------------------------------------
-- Showcase pads (market robots at your base)
---------------------------------------------------------------------
local carries = {} -- [thief] = carry
local stealingPads = {} -- [plot][key] = true while a pad's robot is being carried

local startSteal -- forward

local function buildShowcaseRobot(entry, label, sub)
	local species = Config.SpeciesById[entry.S]
	local mutation = entry.M and Config.GetMarketMutation(entry.M)
	local model = RobotBuilder.Build(species.Loadout, {
		Label = (entry.M and (entry.M .. " ") or "") .. (label or species.Name),
		SubLabel = sub,
		TitleColor = rarityColor(species.Rarity),
		Tint = mutation and mutation.Tint or nil,
	})
	model:ScaleTo(species.Scale)
	return model, species
end

local function renderPad(plot, pad)
	if pad.Model then
		pad.Model:Destroy()
		pad.Model = nil
	end
	local data = plot.Owner and DataManager.Get(plot.Owner)
	local entry = data and data.Showcase[pad.Key]
	pad.Stored = pad.Stored or 0
	if not entry or not Config.SpeciesById[entry.S] then
		pad.Label.Text = ""
		pad.Part.Color = Color3.fromRGB(240, 240, 245)
		return
	end
	if stealingPads[plot] and stealingPads[plot][pad.Key] then
		pad.Label.Text = "BEING STOLEN!"
		pad.Label.TextColor3 = Color3.fromRGB(255, 90, 90)
		return
	end
	local species = Config.SpeciesById[entry.S]
	local mult = DataManager.GetMultiplier(plot.Owner)
	local model = buildShowcaseRobot(entry, nil, species.Rarity .. "  +" .. Config.Money(Config.ShowcaseIncome(entry) * mult) .. "/s")
	local scale = species.Scale
	model:PivotTo(pad.Part.CFrame * CFrame.new(0, pad.Part.Size.Y / 2 + scale, 0) * CFrame.Angles(0, math.pi, 0))
	model.Parent = plot.Bays.Parent
	pad.Model = model
	pad.Part.Color = rarityColor(species.Rarity)

	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.ActionText = "Steal"
	stealPrompt.ObjectText = species.Name
	stealPrompt.HoldDuration = Market.StealHold
	stealPrompt.MaxActivationDistance = 10
	stealPrompt.RequiresLineOfSight = false
	stealPrompt.Parent = model.PrimaryPart
	stealPrompt.Triggered:Connect(function(thief)
		startSteal(thief, plot, pad)
	end)
	pad.Label.TextColor3 = Color3.fromRGB(120, 255, 100)
	pad.Label.Text = pad.Stored >= 1 and Config.Money(pad.Stored) or ""
end

local function renderShowcase(plot)
	for _, pad in ipairs(plot.ShowcasePads) do
		renderPad(plot, pad)
	end
end

local function clearShowcase(plot)
	for _, pad in ipairs(plot.ShowcasePads) do
		if pad.Model then
			pad.Model:Destroy()
			pad.Model = nil
		end
		pad.Stored = 0
		pad.Label.Text = ""
		pad.Part.Color = Color3.fromRGB(240, 240, 245)
	end
end

local function freePadKey(data)
	for i = 1, #Market.PadRows * #Market.PadColumns do
		local key = "p" .. i
		if not data.Showcase[key] then
			return key
		end
	end
	return nil
end

local function padByKey(plot, key)
	for _, pad in ipairs(plot.ShowcasePads) do
		if pad.Key == key then
			return pad
		end
	end
	return nil
end

-- collect stored cash by stepping on a pad
for _, plot in ipairs(World.Plots) do
	for _, pad in ipairs(plot.ShowcasePads) do
		pad.Stored = 0
		local last = 0
		pad.Part.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or player ~= plot.Owner or (pad.Stored or 0) < 1 or os.clock() - last < 0.4 then
				return
			end
			last = os.clock()
			local amount = DataManager.AddCash(player, pad.Stored, false)
			pad.Stored = 0
			pad.Label.Text = ""
			notify(player, "+" .. Config.Money(amount) .. " collected", "cash")
		end)
	end
end

-- income tick
task.spawn(function()
	while true do
		task.wait(1)
		for _, plot in ipairs(World.Plots) do
			local owner = plot.Owner
			local data = owner and DataManager.Get(owner)
			if data then
				local mult = DataManager.GetMultiplier(owner)
				local auto = DataManager.HasPass(owner, "AutoCollect")
				for _, pad in ipairs(plot.ShowcasePads) do
					local entry = data.Showcase[pad.Key]
					if entry and not (stealingPads[plot] and stealingPads[plot][pad.Key]) then
						local income = Config.ShowcaseIncome(entry) * mult
						if auto then
							DataManager.AddCash(owner, income, false)
						else
							pad.Stored = (pad.Stored or 0) + income
							pad.Label.Text = Config.Money(pad.Stored)
						end
					end
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- Robot Market conveyor
---------------------------------------------------------------------
local runway = {} -- list of { Model, Species, Mutation, Distance }
local direction = (Market.End - Market.Start).Unit
local runwayLength = (Market.End - Market.Start).Magnitude

local function pickSpecies()
	local total = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		total += Config.Rarities[rarity].Weight
	end
	local roll = math.random() * total
	local chosen = "Common"
	for _, rarity in ipairs(Config.RarityOrder) do
		roll -= Config.Rarities[rarity].Weight
		if roll <= 0 then
			chosen = rarity
			break
		end
	end
	local pool = {}
	for _, sp in ipairs(Config.Species) do
		if sp.Rarity == chosen then
			table.insert(pool, sp)
		end
	end
	if #pool == 0 then
		return Config.Species[1]
	end
	return pool[math.random(1, #pool)]
end

local function rollMarketMutation()
	for _, m in ipairs(Market.Mutations) do
		if math.random() < m.Chance then
			return m.Name
		end
	end
	return nil
end

local function runwayCFrame(item)
	local pos = Market.Start + direction * item.Distance
	return CFrame.lookAt(pos, pos + direction) * CFrame.new(0, item.Species.Scale, 0)
end

local function buyFromRunway(player, item)
	if not item.Model.Parent then
		return
	end
	local data = DataManager.Get(player)
	local plot = plotOf(player)
	if not data or not plot then
		notify(player, "You need a workshop to buy robots.", "error")
		return
	end
	local key = freePadKey(data)
	if not key then
		notify(player, "All your showcase pads are full!", "error")
		return
	end
	local price = item.Species.Price
	if not DataManager.SpendCash(player, price) then
		notify(player, "You need " .. Config.Money(price - data.Cash) .. " more!", "error")
		return
	end
	for i, other in ipairs(runway) do
		if other == item then
			table.remove(runway, i)
			break
		end
	end
	item.Model:Destroy()
	data.Showcase[key] = { S = item.Species.Id, M = item.Mutation }
	local pad = padByKey(plot, key)
	if pad then
		renderPad(plot, pad)
	end
	notify(player, "You bought " .. (item.Mutation and (item.Mutation .. " ") or "") .. item.Species.Name .. "! It's at your base.", "success")
	DataManager.MarkChanged(player)
end

local function spawnRunwayRobot()
	local species = pickSpecies()
	local mutation = rollMarketMutation()
	local entry = { S = species.Id, M = mutation }
	local model = buildShowcaseRobot(entry, nil, Config.Money(species.Price) .. "  ·  +" .. Config.Money(Config.ShowcaseIncome(entry)) .. "/s")
	local item = { Model = model, Species = species, Mutation = mutation, Distance = 0 }
	model:PivotTo(runwayCFrame(item))
	model.Parent = Hub.MarketFolder
	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.ActionText = "Buy " .. Config.Money(species.Price)
	buyPrompt.ObjectText = (mutation and (mutation .. " ") or "") .. species.Name .. " (" .. species.Rarity .. ")"
	buyPrompt.HoldDuration = 0.25
	buyPrompt.MaxActivationDistance = 12
	buyPrompt.RequiresLineOfSight = false
	buyPrompt.Parent = model.PrimaryPart
	buyPrompt.Triggered:Connect(function(player)
		buyFromRunway(player, item)
	end)
	table.insert(runway, item)
	if Config.RarityOrder[5] == species.Rarity or Config.RarityOrder[6] == species.Rarity then
		for _, player in ipairs(Players:GetPlayers()) do
			notify(player, "A " .. species.Rarity .. " " .. species.Name .. " is on the Robot Market!", "info")
		end
	end
end

task.spawn(function()
	while true do
		spawnRunwayRobot()
		task.wait(Market.SpawnInterval)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for i = #runway, 1, -1 do
		local item = runway[i]
		item.Distance += Market.Speed * dt
		if item.Distance >= runwayLength or not item.Model.Parent then
			item.Model:Destroy()
			table.remove(runway, i)
		else
			item.Model:PivotTo(runwayCFrame(item))
		end
	end
end)

---------------------------------------------------------------------
-- Stealing
---------------------------------------------------------------------
local function isLocked(plot)
	return os.time() < (plot.LockedUntil or 0)
end

local function endCarry(carry, success, reason)
	carries[carry.Thief] = nil
	if stealingPads[carry.Plot] then
		stealingPads[carry.Plot][carry.Key] = nil
	end
	if carry.Visual then
		carry.Visual:Destroy()
	end
	local _, humanoid = rootOf(carry.Thief)
	if humanoid then
		humanoid.WalkSpeed = carry.OldSpeed or 16
	end
	carry.Thief:SetAttribute("Carrying", nil)

	local ownerData = carry.Owner.Parent and DataManager.Get(carry.Owner)
	if success and ownerData and ownerData.Showcase[carry.Key] then
		local thiefData = DataManager.Get(carry.Thief)
		local thiefPlot = plotOf(carry.Thief)
		local key = thiefData and freePadKey(thiefData)
		if thiefData and thiefPlot and key then
			local entry = ownerData.Showcase[carry.Key]
			ownerData.Showcase[carry.Key] = nil
			thiefData.Showcase[key] = entry
			thiefData.Stats.Steals += 1
			local name = Config.SpeciesById[entry.S].Name
			notify(carry.Thief, "You stole " .. name .. "!", "success")
			notify(carry.Owner, carry.Thief.DisplayName .. " stole your " .. name .. "!", "error")
			local pad = padByKey(thiefPlot, key)
			if pad then
				renderPad(thiefPlot, pad)
			end
			DataManager.MarkChanged(carry.Thief)
			DataManager.MarkChanged(carry.Owner)
		else
			success = false
			reason = "You have no free pads!"
		end
	end
	if not success then
		if reason then
			notify(carry.Thief, reason, "error")
		end
		if carry.Owner.Parent and reason == "Caught!" then
			notify(carry.Owner, "You got your robot back!", "success")
		end
	end
	if carry.Plot.Owner == carry.Owner then
		local pad = padByKey(carry.Plot, carry.Key)
		if pad then
			renderPad(carry.Plot, pad)
		end
	end
end

function startSteal(thief, plot, pad)
	local owner = plot.Owner
	if not owner or thief == owner then
		if thief == owner then
			notify(thief, "That's your robot! Step on its pad to collect cash.", "info")
		end
		return
	end
	if carries[thief] then
		notify(thief, "You're already carrying a robot!", "error")
		return
	end
	if isLocked(plot) then
		notify(thief, "This base is locked!", "error")
		return
	end
	local ownerData = DataManager.Get(owner)
	local thiefData = DataManager.Get(thief)
	local entry = ownerData and ownerData.Showcase[pad.Key]
	if not entry or not thiefData then
		return
	end
	if not plotOf(thief) then
		notify(thief, "You need a workshop to steal robots.", "error")
		return
	end
	if not freePadKey(thiefData) then
		notify(thief, "Your showcase pads are full!", "error")
		return
	end
	local root, humanoid, character = rootOf(thief)
	if not root then
		return
	end
	if stealingPads[plot] and stealingPads[plot][pad.Key] then
		return
	end

	stealingPads[plot] = stealingPads[plot] or {}
	stealingPads[plot][pad.Key] = true

	-- carried copy above the thief's head
	local visual = buildShowcaseRobot(entry, nil, "STOLEN")
	visual:ScaleTo(0.4 * Config.SpeciesById[entry.S].Scale)
	for _, d in ipairs(visual:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	visual:PivotTo(root.CFrame * CFrame.new(0, 4.5, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = visual.PrimaryPart
	weld.Parent = visual.PrimaryPart
	visual.Parent = character

	local carry = {
		Thief = thief,
		Owner = owner,
		Plot = plot,
		Key = pad.Key,
		Visual = visual,
		Started = os.clock(),
		OldSpeed = humanoid.WalkSpeed,
	}
	carries[thief] = carry
	humanoid.WalkSpeed = Market.CarrySpeed
	thief:SetAttribute("Carrying", true)
	renderPad(plot, pad)
	notify(thief, "Run back to your base!", "info")
	notify(owner, thief.DisplayName .. " is stealing your " .. Config.SpeciesById[entry.S].Name .. "! Catch them!", "error")
end

task.spawn(function()
	while true do
		task.wait(0.15)
		for thief, carry in pairs(carries) do
			local root = rootOf(thief)
			if not thief.Parent or not root then
				endCarry(carry, false, nil)
			elseif not carry.Owner.Parent or carry.Plot.Owner ~= carry.Owner then
				endCarry(carry, false, "The owner left.")
			elseif os.clock() - carry.Started > Market.StealTimeout then
				endCarry(carry, false, "You took too long!")
			else
				local ownerRoot = rootOf(carry.Owner)
				local thiefPlot = plotOf(thief)
				if ownerRoot and (ownerRoot.Position - root.Position).Magnitude <= Market.RecoverDistance then
					endCarry(carry, false, "Caught!")
				elseif thiefPlot and insidePlot(thiefPlot, root.Position) then
					endCarry(carry, true, nil)
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- Base lock
---------------------------------------------------------------------
local function setLasers(plot, on)
	for _, laser in ipairs(plot.Lasers) do
		laser.Transparency = on and 0.55 or 1
	end
end

for _, plot in ipairs(World.Plots) do
	local last = 0
	plot.LockPad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or player ~= plot.Owner or os.clock() - last < 1 then
			return
		end
		last = os.clock()
		local now = os.time()
		if isLocked(plot) then
			return
		end
		if now < (plot.LockReadyAt or 0) then
			notify(player, "Lock recharging: " .. (plot.LockReadyAt - now) .. "s", "error")
			return
		end
		plot.LockedUntil = now + Market.LockDuration
		plot.LockReadyAt = plot.LockedUntil + Market.LockCooldown
		setLasers(plot, true)
		notify(player, "Base locked for " .. Market.LockDuration .. " seconds!", "success")
		DataManager.MarkChanged(player)
	end)
	for _, laser in ipairs(plot.Lasers) do
		laser.Touched:Connect(function(hit)
			if not isLocked(plot) then
				return
			end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or player == plot.Owner then
				return
			end
			local root = hit.Parent:FindFirstChild("HumanoidRootPart")
			if root then
				local localPos = plot.CFrame:PointToObjectSpace(root.Position)
				local outward = plot.CFrame:VectorToWorldSpace(Vector3.new(localPos.X, 0, localPos.Z).Unit)
				root.CFrame = root.CFrame + outward * 8
				root.AssemblyLinearVelocity = outward * 60 + Vector3.new(0, 30, 0)
			end
		end)
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.time()
		for _, plot in ipairs(World.Plots) do
			if plot.Owner then
				if isLocked(plot) then
					plot.LockLabel.Text = "LOCKED  " .. (plot.LockedUntil - now) .. "s"
				else
					if plot.Lasers[1].Transparency < 1 then
						setLasers(plot, false)
					end
					local wait = (plot.LockReadyAt or 0) - now
					plot.LockLabel.Text = wait > 0 and ("RECHARGING  " .. wait .. "s") or "LOCK BASE"
				end
				renderGarden(plot)
			end
		end
	end
end)

---------------------------------------------------------------------
-- Plot lifecycle
---------------------------------------------------------------------
local function setupPlot(player, plot)
	plot.LockedUntil = 0
	plot.LockReadyAt = 0
	setLasers(plot, false)
	for _, tile in ipairs(plot.GardenTiles) do
		tile.Prompt.Enabled = true
	end
	renderGarden(plot)
	renderShowcase(plot)
	local runtime = DataManager.Runtime[player]
	if runtime then
		runtime.Stock = runtime.Stock or DataManager.DeepCopy(globalStock)
	end
end

local function teardownPlot(player, plot)
	-- bank any uncollected pad cash
	local total = 0
	for _, pad in ipairs(plot.ShowcasePads) do
		total += pad.Stored or 0
	end
	if total > 0 and DataManager.Get(player) then
		DataManager.AddCash(player, total, false)
	end
	for thief, carry in pairs(carries) do
		if carry.Plot == plot or thief == player then
			endCarry(carry, false, "The steal was cancelled.")
		end
	end
	stealingPads[plot] = nil
	clearGarden(plot)
	clearShowcase(plot)
	setLasers(plot, false)
	plot.LockedUntil = 0
	plot.LockReadyAt = 0
end

DataManager.PlotClaimed:Connect(setupPlot)
DataManager.PlotReleased:Connect(teardownPlot)
DataManager.ProgressReset:Connect(function(player)
	local plot = plotOf(player)
	if plot then
		teardownPlot(player, plot)
		setupPlot(player, plot)
	end
end)

for _, plot in ipairs(World.Plots) do
	if plot.Owner then
		setupPlot(plot.Owner, plot)
	end
end

Players.PlayerAdded:Connect(function(player)
	-- stock for players who join between restocks
	task.spawn(function()
		for _ = 1, 30 do
			local runtime = DataManager.Runtime[player]
			if runtime then
				runtime.Stock = runtime.Stock or DataManager.DeepCopy(globalStock)
				DataManager.MarkChanged(player)
				return
			end
			task.wait(1)
		end
	end)
end)

---------------------------------------------------------------------
-- Requests from the UI
---------------------------------------------------------------------
local Actions = {}

function Actions.BuySeed(player, data, runtime, seedId)
	local seed = Config.SeedById[seedId]
	if not seed then
		return false, "Unknown seed"
	end
	runtime.Stock = runtime.Stock or {}
	if (runtime.Stock[seedId] or 0) <= 0 then
		return false, seed.Name .. " is sold out. Wait for the restock!"
	end
	if not DataManager.SpendCash(player, seed.Price) then
		return false, "You need " .. Config.Money(seed.Price - data.Cash) .. " more"
	end
	runtime.Stock[seedId] -= 1
	data.Seeds[seedId] = (data.Seeds[seedId] or 0) + 1
	runtime.SelectedSeed = runtime.SelectedSeed or seedId
	DataManager.MarkChanged(player)
	return true, "Bought " .. seed.Name .. " seed"
end

function Actions.SelectSeed(player, data, runtime, seedId)
	if not Config.SeedById[seedId] or (data.Seeds[seedId] or 0) <= 0 then
		return false, "You don't have that seed"
	end
	runtime.SelectedSeed = seedId
	DataManager.MarkChanged(player)
	return true, Config.SeedById[seedId].Name .. " selected. Plant it in a garden bed!"
end

function Actions.SellAll(player)
	local root = rootOf(player)
	if not root or (root.Position - Hub.SellPosition).Magnitude > Garden.SellDistance then
		return false, "Go to the Sell Stand in the hub to sell!"
	end
	return sellBackpack(player)
end

Remotes.SimRequest.OnServerInvoke = function(player, action, ...)
	local handler = Actions[action]
	local data = DataManager.Get(player)
	local runtime = DataManager.Runtime[player]
	if not handler then
		return false, "Unknown action"
	end
	if not data or not runtime then
		return false, "Your data is still loading..."
	end
	local ok, a, b = pcall(handler, player, data, runtime, ...)
	if not ok then
		warn("[SimServer] " .. tostring(action) .. " failed: " .. tostring(a))
		return false, "Something went wrong"
	end
	return a, b
end
]=] })
table.insert(files, { Class = "LocalScript", Service = "StarterPlayer", Sub = "StarterPlayerScripts", Name = "MainUI", Source = [=[
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
	ContextActionService:SetTitle("VexScore", "Score")
	ContextActionService:SetPosition("VexScore", UDim2.new(1, -200, 1, -140))
	if model:GetAttribute("Strafe") then
		ContextActionService:BindAction("VexStrafeLeft", onStrafe, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
		ContextActionService:BindAction("VexStrafeRight", onStrafe, true, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
		ContextActionService:SetTitle("VexStrafeLeft", "Left")
		ContextActionService:SetTitle("VexStrafeRight", "Right")
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

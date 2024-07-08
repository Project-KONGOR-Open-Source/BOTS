--ArachnaBot v1.0


local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic 		= true
object.bRunBehaviors	= true
object.bUpdates 		= true
object.bUseShop 		= true

object.bRunCommands 	= true
object.bMoveCommands 	= true
object.bAttackCommands 	= true
object.bAbilityCommands = true
object.bOtherCommands 	= true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false


object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core 		= {}
object.eventsLib 	= {}
object.metadata 	= {}
object.behaviorLib 	= {}
object.skills 		= {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading adrenaline_main...')

object.heroName = 'Hero_Adrenaline'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 4, ShortSolo = 4, LongSolo = 5, ShortSupport = 1, LongSupport = 1, ShortCarry = 3, LongCarry = 4}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.shardBlast = unitSelf:GetAbility(0)
		skills.rush = unitSelf:GetAbility(1)
		skills.emberShard = unitSelf:GetAbility(2)
		skills.deathsHalo = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.shardBlast and skills.rush and skills.emberShard and skills.deathsHalo and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level ordering first {precision, web, web, harden}
	if not (skills.shardBlast:GetLevel() >= 1) then
		skills.shardBlast:LevelUp()
	elseif not (skills.rush:GetLevel() >= 2) then
		skills.rush:LevelUp()
	elseif not (skills.emberShard:GetLevel() >= 1) then
		skills.emberShard:LevelUp()
	--max in this order {ult, web, precision, carapace, stats}
	elseif skills.deathsHalo:CanLevelUp() then
		skills.deathsHalo:LevelUp()
	elseif skills.shardBlast:CanLevelUp() then
		skills.shardBlast:LevelUp()
	elseif skills.rush:CanLevelUp() then
		skills.rush:LevelUp()
	elseif skills.emberShard:CanLevelUp() then
		skills.emberShard:LevelUp()
	else
		skills.attributeBoost:LevelUp()
	end	
end

---------------------------------------------------
--                   Overrides                   --
---------------------------------------------------

----------------------------------
--	Arachna specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

object.shardBlastUpBonus = 3
object.shardBlastUseBonus = 19
object.shardBlastUseThreshold = 25

object.rushUpBonus = 10
object.rushUseBonus = 18
object.rushUseThreshold = 16

object.emberShardUpBonus = 15
object.emberShardUseBonus = 48
object.emberShardUseThreshold = 22

object.deathsHaloUpBonus = 80
object.deathsHaloUseBonus = 222
object.deathsHaloUseThreshold = 45

object.mageBaneUpBonus = 30
object.mageBaneUseBonus = 0
object.mageBaneUseThreshold = 46

local function AbilitiesUpUtilityFn()
	local unitSelf = core.unitSelf
	local val = 0
	
	if skills.shardBlast:CanActivate() then
		val = val + object.shardBlastUpBonus
	end
	
	if skills.rush:CanActivate() then
		val = val + object.rushUpBonus
	end
	
	if skills.emberShard:CanActivate() then
		val = val + object.emberShardUpBonus
	end
	
	if skills.deathsHalo:CanActivate() then
		val = val + object.deathsHaloUpBonus
	end
	
	return val
end

--Arachna ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Adrenaline1" then
			addBonus = addBonus + object.shardBlastUseBonus
		elseif EventData.InflictorName == "Ability_Adrenaline2" then
			addBonus = addBonus + object.rushUseBonus
		elseif EventData.InflictorName == "Ability_Adrenaline3" then --We want Adrenaline to eventually run away and pull the enemies with himself, that's why there's minus instead of plus
			addBonus = addBonus - object.emberShardUseBonus
		elseif EventData.InflictorName == "Ability_Adrenaline4" then
			addBonus = addBonus + object.deathsHaloUseBonus
		end
	end
	
	if addBonus > 0 then
		--decay before we add
		core.DecayBonus(self)
	
		core.nHarassBonus = core.nHarassBonus + addBonus
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent 	= object.oncombateventOverride

--Util override
local function CustomHarassUtilityOverride(hero)
	local unitSelf = core.unitSelf
	local nUtility = AbilitiesUpUtilityFn()
	
	if unitSelf:GetHealthPercent() > .93 then
		nUtility = nUtility + 4
	end
	
	if unitSelf:GetManaPercent() > .93 then
		nUtility = nUtility + 8
	end
	
	if unitSelf:HasState("State_Adrenaline_Ability1_Stack") then
		nUtility = nUtility + 22
	end
	
	if unitSelf:HasState("State_Adrenaline_Ability3_Self") then
		nUtility = nUtility + 69
	end
	
	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride   

----------------------------------
--	Arachna specific push strength
----------------------------------
local function PushingStrengthUtilOverride(myHero)
	local myDamage = core.GetFinalAttackDamageAverage(myHero)
	local myAttackDuration = myHero:GetAdjustedAttackDuration()
	local myDPS = myDamage * 1000 / (myAttackDuration) --ms to s
	
	local vTop = Vector3.Create(300, 100)
	local vBot = Vector3.Create(100, 0)
	local m = ((vTop.y - vBot.y)/(vTop.x - vBot.x))
	local b = vBot.y - m * vBot.x 
	
	local util = m * myDPS + b
	util = Clamp(util, 0, 100)
	
	--BotEcho(format("MyDPS: %g  util: %g  myMin: %g  myMax: %g  myAttackAverageL %g", 
	--	myDPS, util, myHero:GetFinalAttackDamageMin(), myHero:GetFinalAttackDamageMax(), myDamage))

	return util
end
behaviorLib.PushingStrengthUtilFn = PushingStrengthUtilOverride


----------------------------------
--	Arachna harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behavior
	end
	
	local unitSelf = core.unitSelf
	
	local bActionTaken = false
	
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	
	--since we are using an old pointer, ensure we can still see the target for entity targeting
	if core.CanSeeUnit(botBrain, unitTarget) then
		local vecMyPosition = unitSelf:GetPosition()
		local vecTargetPosition = unitTarget:GetPosition()
		
		local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
		
		local dist = Vector3.Distance2D(vecMyPosition, vecTargetPosition)
		
		local abilShardBlast = skills.shardBlast
		local abilRush = skills.rush
		local abilEmberShard = skills.emberShard
		local abilDeathsHalo = skills.deathsHalo
		local abilShardBlastRange = abilShardBlast and abilShardBlast:GetRange() or 0
		local abilRushRange = abilRush and abilRush:GetRange() or 0
		
		if abilDeathsHalo and abilDeathsHalo:CanActivate() and not bActionTaken then
			if dist < 600 and object.deathsHaloUseThreshold then
				bActionTaken = core.OrderAbility(botBrain, abilDeathsHalo)
			end
		end
		
		if abilEmberShard and abilEmberShard:CanActivate() and not bActionTaken then
			if nLastHarassUtility > object.emberShardUseThreshold then
				bActionTaken = core.OrderAbility(botBrain, abilEmberShard)
			end
		end
		
		if abilRush and abilRush:CanActivate() and not bActionTaken then
			if nLastHarassUtility > object.rushUseThreshold and unitSelf:GetHealthPercent() > unitTarget:GetHealthPercent() and dist+75 < abilRushRange then
				local vecToward = Vector3.Normalize(vecTargetPosition - vecMyPosition)
				local vecAbilityTarget = vecMyPosition + vecToward * abilRushRange
				bActionTaken = core.OrderAbilityPosition(botBrain, abilRush, vecAbilityTarget)
			end
		end
		
		if abilShardBlast and abilShardBlast:CanActivate() and not bActionTaken then
			if nLastHarassUtility > object.shardBlastUseThreshold and dist+110 < abilShardBlastRange then
				local vecToward = Vector3.Normalize(vecTargetPosition - vecMyPosition)
				local vecAbilityTarget = vecMyPosition + vecToward * 250
				bActionTaken = core.OrderAbilityPosition(botBrain, abilShardBlast, vecAbilityTarget)
			end
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

behaviorLib.StartingItems =
	{"2 Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems =
	{"Item_Lifetube", "Item_Marchers", "Item_Shield2", "Item_MysticVestments"} -- Shield2 is HotBL
behaviorLib.MidItems =
	{"Item_EnhancedMarchers", "Item_PortalKey"} 
behaviorLib.LateItems =
	{"Item_Excruciator", "Item_SolsBulwark", "Item_DaemonicBreastplate", "Item_Intelligence7", "Item_HealthMana2", "Item_BehemothsHeart"} --Excruciator is Barbed Armor, Item_Intelligence7 is staff, Item_HealthMana2 is icon

--[[ colors:
	red
	aqua == cyan
	gray
	navy
	teal
	blue
	lime
	black
	brown
	green
	olive
	white
	silver
	purple
	maroon
	yellow
	orange
	fuchsia == magenta
	invisible
--]]

BotEcho('finished loading adrenaline_main')

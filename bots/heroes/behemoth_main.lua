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

BotEcho('loading behemoth_main...')

object.heroName = 'Hero_Behemoth'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 3, ShortSolo = 2, LongSolo = 2, ShortSupport = 4, LongSupport = 5, ShortCarry = 2, LongCarry = 2}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.fissure = unitSelf:GetAbility(0)
		skills.enrage = unitSelf:GetAbility(1)
		skills.heavyweight = unitSelf:GetAbility(2)
		skills.shockwave = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.fissure and skills.enrage and skills.heavyweight and skills.shockwave and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level ordering first {precision, web, web, harden}
	if not (skills.fissure:GetLevel() >= 1) then
		skills.fissure:LevelUp()
	elseif not (skills.heavyweight:GetLevel() >= 2) then
		skills.heavyweight:LevelUp()
	elseif not (skills.enrage:GetLevel() >= 1) then
		skills.enrage:LevelUp()
	--max in this order {ult, web, precision, carapace, stats}
	elseif skills.shockwave:CanLevelUp() then
		skills.shockwave:LevelUp()
	elseif skills.fissure:CanLevelUp() then
		skills.fissure:LevelUp()
	elseif skills.heavyweight:CanLevelUp() then
		skills.heavyweight:LevelUp()
	elseif skills.enrage:CanLevelUp() then
		skills.enrage:LevelUp()
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

object.fissusreUpBonus = 15
object.fissusreUseBonus = 20
object.fissusreUseThreshold = 29

object.enrageUpBonus = 5
object.enrageUseBonus = 4
object.enrageUseThreshold = 11

object.shockwaveUpBonus = 110
object.shockwaveUseBonus = 23
object.shockwaveUseThreshold = 119 --Has bonuses to threshold per enemies around

local function AbilitiesUpUtilityFn()
	local unitSelf = core.unitSelf
	local val = 0
	
	if skills.fissure:CanActivate() then
		val = val + object.fissusreUpBonus
	end
	
	if skills.enrage:CanActivate() then
		val = val + object.enrageUpBonus
	end
	
	if skills.shockwave:CanActivate() then
		val = val + object.shockwaveUpBonus
	end
	
	return val
end

--Arachna ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Behemoth1" then
			addBonus = addBonus + object.fissusreUseBonus
		elseif EventData.InflictorName == "Ability_Behemoth2" then
			addBonus = addBonus + object.enrageUseBonus
		elseif EventData.InflictorName == "Ability_Behemoth4" then
			addBonus = addBonus + object.shockwaveUseBonus
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
	
	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride   
--This function returns the position of the enemy hero.
--If he is not shown on map it returns the last visible spot
--as long as it is not older than 10s
object.tEnemyPosition = {}
object.tEnemyPositionTimestamp = {}
local function funcGetEnemyPosition(unitEnemy)

	if not unitEnemy then 
		--TODO: change this to nil and fix the rest of the code to recognize it as the failure case
		return Vector3.Create(20000, 20000) 
	end
	
	local tEnemyPosition = object.tEnemyPosition
	local tEnemyPositionTimestamp = object.tEnemyPositionTimestamp

	if core.IsTableEmpty(tEnemyPosition) then	
		local tEnemyTeam = HoN.GetHeroes(core.enemyTeam)
		
		--vector beyond map
		for x, hero in pairs(tEnemyTeam) do
			--TODO: Also here
			tEnemyPosition[hero:GetUniqueID()] = Vector3.Create(20000, 20000)
			tEnemyPositionTimestamp[hero:GetUniqueID()] = HoN.GetGameTime()
		end
	end

	local nUniqueID = unitEnemy:GetUniqueID()
	
	--enemy visible?
	if core.CanSeeUnit(object, unitEnemy) then
		--update table
		tEnemyPosition[nUniqueID] = unitEnemy:GetPosition()
		tEnemyPositionTimestamp[nUniqueID] = HoN.GetGameTime()
	end

	--return position, 10s memory
	if tEnemyPositionTimestamp[nUniqueID] <= HoN.GetGameTime() + 10000 then
		return tEnemyPosition[nUniqueID]
	else	
		--TODO: Also here
		return Vector3.Create(20000, 20000)
	end
end
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
		
		local dist = Vector3.Distance2D(vecMyPosition, vecTargetPosition)
		
		local abilFissure = skills.fissure
		local abilEnrage = skills.enrage
		local abilShockwave = skills.shockwave
		local abilFissureRange = abilFissure and abilFissure:GetRange() or 0
		
		local numEnemies = 0
		local tEnemyTeam = HoN.GetHeroes(core.enemyTeam)
		--units close to unitTarget
		for id, enemy in pairs(tEnemyTeam) do
			if id ~= unitTarget:GetUniqueID() then
				if Vector3.Distance2DSq(unitSelf:GetPosition(), funcGetEnemyPosition(enemy)) < 600*600 then
					numEnemies = numEnemies + 1
				end
			end
		end
		
		if abilEnrage and abilEnrage:CanActivate() and not bActionTaken then
			if nLastHarassUtility > botBrain.enrageUseThreshold then
				bActionTaken = core.OrderAbility(botBrain, abilEnrage)
			end
		end
		
		if abilShockwave and abilShockwave:CanActivate() and not bActionTaken then
			if (nLastHarassUtility + (numEnemies * 11.9)) > object.shockwaveUseThreshold and core.NumberElements(tLocalEnemyHeroes) > 0 then
				bActionTaken = core.OrderAbility(botBrain, abilShockwave)
			end
		end
		
		if abilFissure and abilFissure:CanActivate() and not bActionTaken then
			if nLastHarassUtility > botBrain.fissusreUseThreshold then
				bActionTaken = core.OrderAbilityPosition(botBrain, abilFissure, vecTargetPosition)
			end
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
behaviorLib.StartingItems = {"Item_CrushingClaws", "Item_MarkOfTheNovice", "2 Item_RunesOfTheBlight", "2 Item_ManaPotion"}
behaviorLib.LaneItems = {"Item_BloodChalice", "Item_Marchers", "Item_Striders", "Item_Strength5"} --Item_Strength5 is Fortified Bracelet
behaviorLib.MidItems = {"Item_PortalKey", "Item_Immunity", "Item_FrostfieldPlate"} --Immunity is Shrunken Head
behaviorLib.LateItems = {"Item_SpellShards 3", "Item_SolsBulwark", "Item_DaemonicBreastplate", "Item_BehemothsHeart", "Item_Damage9"} --Item_Damage9 is doombringer


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

BotEcho('finished loading behemoth_main')

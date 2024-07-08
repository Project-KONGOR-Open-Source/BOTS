--ArmadonBot v1.0
--Coded by Sparks1992
--   additions by malloc
 
local _G = getfenv(0)
local object = _G.object
 
object.myName = object:GetName()
 
object.bRunLogic		= true
object.bRunBehaviors    = true
object.bUpdates		    = true
object.bUseShop		    = true
 
object.bRunCommands     = true
object.bMoveCommands    = true
object.bAttackCommands  = true
object.bAbilityCommands = true
object.bOtherCommands   = true
 
object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false
 

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false
 
object.core	    		= {}
object.eventsLib		= {}
object.metadata	 		= {}
object.behaviorLib      = {}
object.skills			= {}
 
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
local sqrtTwo = math.sqrt(2)
BotEcho('loading gladiator_main...')

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 1, LongSolo = 1, ShortSupport = 3, LongSupport = 4, ShortCarry = 4, LongCarry = 5}

object.heroName = 'Hero_Gladiator'
   
--------------------------------
-- Leveling Order | Skills
--------------------------------
object.tSkills = {
	2, 0, 2, 1, 2,
	3, 2, 1, 1, 1,
	3, 0, 0, 0, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4,
}

---------------------------------
-- Skill Declare
---------------------------------
local bSkillsValid = false
function object:SkillBuild()
-- takes care at load/reload, <name_#> to be replaced by some convinient name.
    local unitSelf = self.core.unitSelf
       
    if not bSkillsValid then
		skills.pitfall				= unitSelf:GetAbility(0)
		skills.showdown				= unitSelf:GetAbility(1)
		skills.flagellation			= unitSelf:GetAbility(2)
		skills.callToArms			= unitSelf:GetAbility(3)
 
		if skills.pitfall and skills.showdown and skills.flagellation and skills.callToArms then
			bSkillsValid = true    
		else
			return
		end
	end
   
    if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
    end
   
    local nlev = unitSelf:GetLevel()
    local nlevpts = unitSelf:GetAbilityPointsAvailable()
    for i = nlev, nlev+nlevpts do
		unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
    end
end
 
----------------------------------
--      Armadon items
----------------------------------
behaviorLib.StartingItems = {"Item_Scarab", "2 Item_RunesOfTheBlight", "Item_ManaPotion"}  -- Items: Scarab, 2x Runes Of The Blight, Mana Potion
behaviorLib.LaneItems = {"Item_Marchers", "Item_Insanitarius", "Item_EnhancedMarchers"}    -- Items: Marchers, Insanitarius, Upg. Ghost Marchers
behaviorLib.MidItems = {"Item_PortalKey", "Item_Pierce 3"} 								   -- Items: Portal Key, Shield Breaker Lvl 3
behaviorLib.LateItems = {"Item_Protect", "Item_DaemonicBreastplate"} 					   -- Items: Null Stone, Daemonic Breastplate
----------------------------------
--      Armadon specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

-- Should include extra aggression when ult stacks -malloc

object.nPitfallUp    = 10
object.nShowdownUp   = 14
object.nFlagellationUp   = 4
object.nCallToArmsUp   = 60
 
object.nPitfallUse   = 10
object.nShowdownUse  = 5
object.nCallToArmsUse   = 22

object.nPitfallThreshold   = 35
object.nShowdownThreshold  = 15
object.nCallToArmsThreshold   = 70

local function AbilitiesUpUtilityFn()
	local nUtility = 0
       
	if skills.pitfall:CanActivate() then
		nUtility = nUtility + object.nPitfallUp
	end
       
	if skills.showdown:CanActivate() then
		nUtility = nUtility + object.nShowdownUp
	end
	
	if skills.flagellation:CanActivate() then
		nUtility = nUtility + object.nFlagellationUp
	end
	
	if skills.callToArms:CanActivate() then
		nUtility = nUtility + object.nCallToArmsUp
	end

	return nUtility
end
 object.nPitfallUseTime = 0
--ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
       
	local nAddBonus = 0
	if EventData.Type == "Ability" then
		       
		if EventData.InflictorName == "Ability_Gladiator1" then
			nAddBonus = nAddBonus + object.nPitfallUse
			object.nPitfallUseTime = EventData.TimeStamp
		end
		
		if EventData.InflictorName == "Ability_Gladiator2" then
			nAddBonus = nAddBonus + object.nShowdownUse
		end
 
		if EventData.InflictorName == "Ability_Gladiator4" then
			nAddBonus = nAddBonus + object.nCallToArmsUse
		end
	end
       
	if nAddBonus > 0 then
		--decay before we add
		core.DecayBonus(self)
		core.nHarassBonus = core.nHarassBonus + nAddBonus
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent    = object.oncombateventOverride
 
 object.useShowdownAlready = false
 
----------------------------------
--      Armadon harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local bDebugEchos = false
       
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behavior
	end
       
	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition()
       
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
       
	local nLastHarassUtil = behaviorLib.lastHarassUtil
	local bCanSee = core.CanSeeUnit(botBrain, unitTarget)

	local bTargetRooted = unitTarget:IsStunned() or unitTarget:IsImmobilized() or unitTarget:GetMoveSpeed() < 300	
       
	local bActionTaken = false
       
	local abilPitfall = skills.pitfall
	local abilShowdown = skills.showdown
	local abilCallToArms = skills.callToArms
 
	-- Call to Arms
	if not bActionTaken and abilCallToArms:CanActivate() and bCanSee then
		if (nLastHarassUtil > object.nCallToArmsThreshold) or (nLastHarassUtil > object.nCallToArmsThreshold + 15 and bTargetRooted) then
			local nRange = abilCallToArms:GetRange()
			if abilCallToArms:CanActivate() and nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityPosition(botBrain, abilCallToArms, vecTargetPosition)
			end
		end
	end
       
	-- Showdown
	if not bActionTaken and abilShowdown:CanActivate() and bCanSee then
		local nRange = abilShowdown:GetRange()
		if nTargetDistanceSq < (nRange * nRange) and not unitSelf:HasState("State_Gladiator_Ability2_Return") and nLastHarassUtil > object.nShowdownThreshold then
			bActionTaken = core.OrderAbilityEntity(botBrain, abilShowdown, unitTarget)
		elseif unitSelf:HasState("State_Gladiator_Ability2_Return") and unitSelf:HasState("State_Gladiator_Ability4") then
			bActionTaken = core.OrderAbility(botBrain, abilShowdown)
		elseif unitSelf:HasState("State_Gladiator_Ability2_Return") and object.useShowdownAlready and HoN.GetGameTime() > object.nPitfallUseTime + 1167 then
			bActionTaken = core.OrderAbility(botBrain, abilShowdown)
			object.useShowdownAlready = false
		end
	end

	-- Pitfall
	if not bActionTaken and abilPitfall:CanActivate() and bCanSee then
		if (nLastHarassUtil > object.nPitfallThreshold) or (nLastHarassUtil > object.nPitfallThreshold + 15 and bTargetRooted) then
			local nRange = abilPitfall:GetRange()
			if abilPitfall:CanActivate() and nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityPosition(botBrain, abilPitfall, vecTargetPosition)
			end
		elseif unitSelf:HasState("State_Gladiator_Ability2_Return") then
			local nRange = abilPitfall:GetRange()
			if abilPitfall:CanActivate() and nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityPosition(botBrain, abilPitfall, vecTargetPosition)
				object.useShowdownAlready = true
			end
		end
	end
 
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

 
BotEcho('finished loading armadon_main')
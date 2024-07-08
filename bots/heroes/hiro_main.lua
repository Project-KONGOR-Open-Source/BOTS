--Shadowblade v0.5
--Coded by Sparks1992

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
object.bDebugUtility = true
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = true
object.logger.bVerboseLog = true

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

BotEcho('loading swiftblade_main...')

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 1, ShortSolo = 1, LongSolo = 1, ShortSupport = 1, LongSupport = 1, ShortCarry = 1, LongCarry = 5}

object.heroName = 'Hero_Hiro'

--------------------------------
-- Leveling Order | Skills
--------------------------------
object.tSkills = {
    0, 1, 0, 2, 0,
    3, 0, 1, 1, 1, 
    3, 2, 2, 2, 4,
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
        skills.bladeFrenzy			= unitSelf:GetAbility(0)
        skills.counterAttack		= unitSelf:GetAbility(1)
        skills.wayOfTheSword		= unitSelf:GetAbility(2)
        skills.swiftSlashes			= unitSelf:GetAbility(3)
		skills.abilAttributeBoost 	= unitSelf:GetAbility(4)

		if skills.bladeFrenzy and skills.counterAttack and skills.wayOfTheSword and skills.swiftSlashes and skills.abilAttributeBoost then
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
--	Shadowblade items
----------------------------------

behaviorLib.StartingItems =
  {"Item_RunesOfTheBlight", "Item_MinorTotem", "Item_LoggersHatchet", "Item_IronBuckler"}
behaviorLib.LaneItems =
  {"Item_Marchers", "Item_Steamboots", "Item_ElderParasite"}
behaviorLib.MidItems =
  { "Item_ManaBurn1", "Item_Brutalizer", "Item_ManaBurn2"}
behaviorLib.LateItems =
  { "Item_Freeze", "Item_Evasion", "Item_Damage9"}

---------------------------------------------------
--                   Overrides                   --
---------------------------------------------------

--[[for testing
function object:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)
	
	core.unitSelf:TeamShare()
	
	-- Insert code here
end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride
--]]

----------------------------------
--	Shadowblade specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

object.nBladeFrenzyUp = 18
object.nCounterAttackUp = 14	
object.nSwiftSlashesUp = 110

object.nBladeFrenzyUse = 10
object.nCounterAttackUse = 4	
object.nSwiftSlashesUse = 30

object.nBladeFrenzyThreshold = 193 --Multiplied by healthSelf, and then divided by enemies nearby
object.nCounterAttackThreshold = 88 --Multiplied by healthSelf, and then divided by enemies nearby
object.nSwiftSlashesThreshold = 88

--ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local nAddBonus = 0
	if EventData.Type == "Ability" then
			
		if EventData.InflictorName == "Ability_Hiro1" then
			nAddBonus = nAddBonus + object.nBladeFrenzyUse
		end
		if EventData.InflictorName == "Ability_Hiro2" then
			nAddBonus = nAddBonus + object.nCounterAttackUse
		end
		if EventData.InflictorName == "Ability_Hiro4" then
			nAddBonus = nAddBonus + object.nSwiftSlashesUse
		end
	end
	
	if nAddBonus > 0 then
		--decay before we add
		core.DecayBonus(self)
		core.nHarassBonus = core.nHarassBonus + nAddBonus
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent 	= object.oncombateventOverride
------------------------------------------------------
--            CustomHarassUtility Override          --
-- Change Utility according to usable spells here   --
------------------------------------------------------
-- @param: IunitEntity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
    local nUtil = 0
	local unitSelf = core.unitSelf
	 
    if skills.bladeFrenzy:CanActivate() then
        nUtil = nUtil + object.nBladeFrenzyUp
    end
 
    if skills.counterAttack:CanActivate() then
        nUtil = nUtil + object.nCounterAttackUp
    end
 
    if skills.swiftSlashes:CanActivate() then
        nUtil = nUtil + object.nSwiftSlashesUp
    end
	
	if unitSelf:GetHealthPercent() > .93 then
		nUtility = nUtil + 4
	end
	
	if unitSelf:GetManaPercent() > .93 then
		nUtility = nUtil + 8
	end
	
	if unitSelf:HasState("State_Hiro_Ability1") then
		nUtil = nUtil + object.nBladeFrenzyUse
	end
	
	if unitSelf:HasState("State_Hiro_Ability2") then
		nUtil = nUtil + object.nCounterAttackUse
	end
	
    return nUtil
end
-- assign custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride
----------------------------------
--	Shadowblade harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local bDebugEchos = false
	
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behavior
	end
	
	local unitSelf = core.unitSelf
	local healthSelf = unitSelf:GetHealthPercent()
	local healthTarget = unitTarget:GetHealthPercent()
	
	local vecMyPosition = unitSelf:GetPosition()
	
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
	
	local nLastHarassUtil = behaviorLib.lastHarassUtil
	local bCanSee = core.CanSeeUnit(botBrain, unitTarget)	
	
	local bActionTaken = false
	
	local abilBladeFrenzy = skills.bladeFrenzy
	local abilCounterAttack = skills.counterAttack
	local abilSwiftSlashes = skills.swiftSlashes
	
	-- Swift Slashes
	if abilSwiftSlashes:CanActivate() and bCanSee then
		local nRange = abilSwiftSlashes:GetRange()
		if abilSwiftSlashes:CanActivate() and nTargetDistanceSq < (nRange * nRange) and (healthTarget < 0.30 or nLastHarassUtil > object.nSwiftSlashesThreshold) then
			bActionTaken = core.OrderAbilityEntity(botBrain, abilSwiftSlashes, unitTarget)
		end
	end

	-- Counter Attack
	if not bActionTaken and abilCounterAttack:CanActivate() then
		if nLastHarassUtil > object.nCounterAttackThreshold * healthSelf / (core.NumberElements(tLocalEnemyHeroes) + 1) then
			bActionTaken = core.OrderAbility(botBrain, abilCounterAttack)
		end	
	end
	
	-- Blade Frenzy
	if not bActionTaken and abilBladeFrenzy:CanActivate() then
		if nLastHarassUtil > object.nBladeFrenzyThreshold * healthSelf / (core.NumberElements(tLocalEnemyHeroes) + 1) then
			bActionTaken = core.OrderAbility(botBrain, abilBladeFrenzy)
		end	
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
	
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

-----------------------------
--	 Retreat execute	 --
-----------------------------

--Modelled after Pure`Light's Magebane custom retreat code.
--  this is a great function to override with using retreating skills, such as blinks, travels, stuns or slows.

function behaviorLib.CustomRetreatExecute(botBrain)
	bActionTaken = false
	local abilBladeFrenzy = skills.bladeFrenzy
	local abilCounterAttack = skills.counterAttack
	if not bAcionTaken and abilCounterAttack:CanActivate() then
		bActionTaken = core.OrderAbility(botBrain, abilCounterAttack)
	end
	if not bAcionTaken and abilBladeFrenzy:CanActivate() then
		bActionTaken = core.OrderAbility(botBrain, abilBladeFrenzy)
	end
	return bActionTaken
end

BotEcho('finished loading swiftblade_main')

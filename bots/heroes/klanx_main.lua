--KlanxBot v1.0


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

local sqrtTwo = math.sqrt(2)

BotEcho('loading calamity_main...')

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 4, ShortSolo = 4, LongSolo = 2, ShortSupport = 2, LongSupport = 1, ShortCarry = 5, LongCarry = 5}

object.heroName = 'Hero_Klanx'

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()	
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.first		= unitSelf:GetAbility(0)
		skills.second		= unitSelf:GetAbility(1)
		skills.third		= unitSelf:GetAbility(2)
		skills.fourth		= unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.first and skills.second and skills.third and skills.fourth and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end	
	
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level 1 skill
	if skills.first:GetLevel() < 1 then
		skills.first:LevelUp()
	--max in this order {ult, flare, deadeye, hollowpoint, stats}
	elseif skills.fourth:CanLevelUp() then
		skills.fourth:LevelUp()
	elseif skills.first:CanLevelUp() then
		skills.first:LevelUp()
	elseif skills.third:CanLevelUp() then
		skills.third:LevelUp()
	elseif skills.second:CanLevelUp() then
		skills.second:LevelUp()
	else
		skills.attributeBoost:LevelUp()
	end	
end


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
--	Flint specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

object.firstUpBonus = 6
object.ultUpBonus = 80

object.firstUseBonus = 6
object.ultUseBonus = 80

local function AbilitiesUpUtilityFn()
	local val = 0
	
	if skills.first:CanActivate() then
		val = val + object.firstUpBonus
	end
	
	if skills.fourth:CanActivate() then
		val = val + object.ultUpBonus
	end
	
	return val
end

--Flint ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Klanx1" then
			addBonus = addBonus + object.firstUseBonus
		end
		if EventData.InflictorName == "Ability_Klanx4" then
			addBonus = addBonus + object.ultUseBonus
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

--Util calc override
local function CustomHarassUtilityOverride(hero)
	local nUtility = AbilitiesUpUtilityFn()
	
	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride  

--HarassHeroUtility override
local function HarassHeroUtilityOverride(botBrain)
	--Flint's ult has a larger range than the default "local units" target gathering range of 1250 (or 
	--	whatever core.localCreepRange is). This means we have to temporarally override that table so 
	--	we consider all units that are in his (extended) range
	
	local oldHeroes = core.localUnits["EnemyHeroes"]
		
	local abilUlt = skills.fourth
	local nRange = abilUlt:GetRange()
	
	if nRange > core.localCreepRange and abilUlt:CanActivate() then
		local vecMyPosition = core.unitSelf:GetPosition()		
		local tAllHeroes = HoN.GetUnitsInRadius(vecMyPosition, nRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_HERO)
		local tEnemyHeroes = {}
		local nEnemyTeam = core.enemyTeam
		for key, hero in pairs(tAllHeroes) do
			if hero:GetTeam() == nEnemyTeam then
				tinsert(tEnemyHeroes, hero)
			end
		end
		
		core.teamBotBrain:AddMemoryUnitsToTable(tEnemyHeroes, nEnemyTeam, vecMyPosition, nRange)
		core.localUnits["EnemyHeroes"] = tEnemyHeroes
	end
	
	local nUtility = object.HarassHeroUtilityOld(botBrain)	
	
	core.localUnits["EnemyHeroes"] = oldHeroes
	return nUtility
end
object.HarassHeroUtilityOld = behaviorLib.HarassHeroBehavior["Utility"] 
behaviorLib.HarassHeroBehavior["Utility"]  = HarassHeroUtilityOverride 

----------------------------------
--	Flint specific building attack
----------------------------------

----------------------------------
--	Flint harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false -- we can't procede, reassess behaviors
	end
	
	local vecTargetPos = unitTarget:GetPosition() or Vector3.Create()
	
	local unitSelf = core.unitSelf
	local bCanSee = core.CanSeeUnit(botBrain, unitTarget)
	
	local bActionTaken = false
	
	local nDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
	
	--money shot
	if not bActionTaken and bCanSee then
		--ult only if it will kill our enemy
		local abilFourth = skills.fourth
		local nRange = 750

		if abilFourth:CanActivate() and nDistanceSq < (nRange * nRange) then
			local nLevel = abilFourth:GetLevel()
			local nDamage = 600
			if nLevel == 2 then
				nDamage = 1000
			elseif nLevel == 3 then
				nDamage = 1400
			end
			
			local nHealth = unitTarget:GetHealth()
			local nDamageMultiplier = 1 - unitTarget:GetMagicResistance()
			local nTrueDamage = nDamage * nDamageMultiplier
			local bUseFourth = ((core.nDifficulty ~= core.nEASY_DIFFCULTY) 
								or (unitTarget:IsBotControlled() and nTrueDamage > nHealth) 
								or (not unitTarget:IsBotControlled() and nHealth - nTrueDamage >= nMaxHealth * 0.23))
			
			--BotEcho(format("ultDamage: %d  damageMul: %g  trueDmg: %g  health: %d", nDamage, nDamageMultiplier, nTrueDamage, nHealth))
			if bUseFourth then
				bActionTaken = core.OrderAbility(botBrain, abilFourth)
			end
		end
	end
	
	--flare
	if not bActionTaken then
		--TODO: consider updating with thresholds on flare
		local abilFirst = skills.first
		local nRange = abilFirst:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(unitTarget)		
		local nFlareCost = abilFirst:GetManaCost()
		
		local bShouldFlare = false 
		local bFlareUsable = abilFirst:CanActivate() and nDistanceSq < (nRange * nRange)
				
		if bFlareUsable then
			local abilMoneyShot = skills.fourth
			if abilMoneyShot:CanActivate() then
				--don't flare if it means we can't ult
				local nMoneyShotCost = abilMoneyShot:GetManaCost()
				if unitSelf:GetMana() - nMoneyShotCost > nFlareCost then
					bShouldFlare = true
				end
			else
				bShouldFlare = true
			end				
		end
		
		if bShouldFlare then
			bActionTaken = core.OrderAbilityPosition(botBrain, abilFirst, vecTargetPos)
		end
	end
	
	if not bActionTaken then
		--TODO: consider updating with thresholds on flare
		local abilSecond = skills.second
		
		local bShouldSpd = false 
		local bSpedUsable = abilSecond:CanActivate()
				
		if bSpedUsable and (unitSelf:GetManaPercent() > .85 or unitSelf:GetManaPercent() < .45) then
			bShouldSpd = true		
		end
		
		if bShouldSpd then
			bActionTaken = core.OrderAbility(botBrain, abilSecond)
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


----------------------------------
--	Flint items
----------------------------------
--[[ list code:
	"# Item" is "get # of these"
	"Item #" is "get this level of the item" --]]
behaviorLib.StartingItems = {"2 Item_DuckBoots", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = {"Item_Marchers", "2 Item_Soulscream", "Item_EnhancedMarchers"}
behaviorLib.MidItems = {"Item_StrengthAgility"} --StrengthAgility is frostburn
--TODO: break into frostwolf skull and geometer's bane
behaviorLib.LateItems = {"Item_Weapon3", "Item_BehemothsHeart", "Item_Damage9" } --Weapon3 is Savage Mace. Item_Sicarius is Firebrand. ManaBurn2 is Geomenter's Bane. Item_Damage9 is Doombringer


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

BotEcho('finished loading klanx_main')

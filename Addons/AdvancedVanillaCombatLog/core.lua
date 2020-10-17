local RPLL = RPLL
RPLL.VERSION = 1
RPLL.PlayerInformation = {}
RPLL.PlayerRotation = {}
RPLL.RotationIndex = 1
RPLL.RotationLength = 0
RPLL.ExtraMessageQueue = {}
RPLL.ExtraMessageQueueIndex = 1
RPLL.ExtraMessageQueueLength = 0

RPLL:RegisterEvent("PLAYER_TARGET_CHANGED")
RPLL:RegisterEvent("RAID_ROSTER_UPDATE")
RPLL:RegisterEvent("PARTY_MEMBERS_CHANGED")

RPLL:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RPLL:RegisterEvent("UPDATE_INSTANCE_INFO")

RPLL:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
RPLL:RegisterEvent("PLAYER_ENTERING_WORLD")
RPLL:RegisterEvent("VARIABLES_LOADED")

RPLL:RegisterEvent("UNIT_PET")
RPLL:RegisterEvent("PLAYER_PET_CHANGED")
RPLL:RegisterEvent("PET_STABLE_CLOSED")

RPLL:RegisterEvent("UI_ERROR_MESSAGE")

RPLL:RegisterEvent("CHAT_MSG_LOOT")

local tinsert = table.insert
local strformat = string.format
local GetTime = GetTime
local UnitName = UnitName
local strgfind = string.gfind
local strsub = string.sub
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local IsInInstance = IsInInstance
local pairs = pairs
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitHealth = UnitHealth
local UnitIsPlayer = UnitIsPlayer
local UnitLevel = UnitLevel
local UnitSex = UnitSex
local strlower = strlower
local GetGuildInfo = GetGuildInfo
local GetInspectPVPRankProgress = GetInspectPVPRankProgress
local GetInventoryItemLink = GetInventoryItemLink
local GetPVPRankInfo = GetPVPRankInfo
local UnitPVPRank = UnitPVPRank
local strfind = string.find
local Unknown = UNKNOWN
local LoggingCombat = LoggingCombat
local pairs = pairs

RPLL.ZONE_CHANGED_NEW_AREA = function()
    LoggingCombat(IsInInstance("player"))
    this:grab_unit_information("player")
    this:RAID_ROSTER_UPDATE()
    this:PARTY_MEMBERS_CHANGED()
    this:QueueRaidIds()
end

RPLL.UPDATE_INSTANCE_INFO = function()
    LoggingCombat(IsInInstance("player"))
    this:grab_unit_information("player")
    this:RAID_ROSTER_UPDATE()
    this:PARTY_MEMBERS_CHANGED()
    this:QueueRaidIds()
end

RPLL.PLAYER_ENTERING_WORLD = function()
    this:grab_unit_information("player")
    this:fix_combat_log_strings()
end

RPLL.VARIABLES_LOADED = function()
    this:grab_unit_information("player")
    this:RAID_ROSTER_UPDATE()
    this:PARTY_MEMBERS_CHANGED()
    this:fix_combat_log_strings()
end

RPLL.PLAYER_TARGET_CHANGED = function()
    this:grab_unit_information("target")
end

RPLL.UPDATE_MOUSEOVER_UNIT = function()
    this:grab_unit_information("mouseover")
end

RPLL.RAID_ROSTER_UPDATE = function()
    for i=1, GetNumRaidMembers() do
        if UnitName("raid"..i) then
            this:grab_unit_information("raid"..i)
        end
    end
end


RPLL.PARTY_MEMBERS_CHANGED = function()
    for i=1, GetNumPartyMembers() do
        if UnitName("party"..i) then
            this:grab_unit_information("party"..i)
        end
    end
end

RPLL.UNIT_PET = function(unit)
    if unit then
        this:grab_unit_information(unit)
    end
end

RPLL.PLAYER_PET_CHANGED = function()
    this:grab_unit_information("player")
end

RPLL.PET_STABLE_CLOSED = function()
    this:grab_unit_information("player")
end

RPLL.UI_ERROR_MESSAGE = function(msg)
    if this:DeepSubString(msg, "spell") then
        this:rotate_combat_log_global_string()
    end
end

RPLL.CHAT_MSG_LOOT = function(msg)
    tinsert(this.ExtraMessageQueue, "LOOT: "..msg)
    this.ExtraMessageQueueLength = this.ExtraMessageQueueLength + 1
end

local function strsplit(pString, pPattern)
	local Table = {}
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = strfind(pString, fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table,cap)
		end
		last_end = e+1
		s, e, cap = strfind(pString, fpat, last_end)
	end
	if last_end <= strlen(pString) then
		cap = strfind(pString, last_end)
		table.insert(Table, cap)
	end
	return Table
end

function RPLL:DeepSubString(str1, str2)
    if str1 == nil or str2 == nil then
        return false
    end

    str1 = strlower(str1)
    str2 = strlower(str2)
    if (strfind(str1, str2) or strfind(str2, str1)) then
        return true;
    end
    for cat, val in pairs(strsplit(str1, " ")) do
        if val ~= "the" then
            if (strfind(val, str2) or strfind(str2, val)) then
                return true;
            end
        end
    end
    return false;
end

function RPLL:QueueRaidIds()
    local zone, zone2 = GetRealZoneText(), GetZoneText()
    for i=1, GetNumSavedInstances() do
        local instance_name, instance_id = GetSavedInstanceInfo(i)
        if zone == instance_name or zone2 == instance_name or self:DeepSubString(zone, instance_name) or self:DeepSubString(instance_name, zone) or self:DeepSubString(zone2, instance_name) or self:DeepSubString(instance_name, zone2) then
            tinsert(this.ExtraMessageQueue, "ZONE_INFO: "..instance_name.."&"..instance_id)
            this.ExtraMessageQueueLength = this.ExtraMessageQueueLength + 1
            break
        end
    end
end

function RPLL:fix_combat_log_strings()
    local player_name = UnitName("player")
    AURAADDEDSELFHARMFUL = player_name.." is afflicted by %s."
    AURAADDEDSELFHELPFUL = player_name.." gains %s."
    AURAAPPLICATIONADDEDSELFHARMFUL = player_name.." is afflicted by %s (%d)."
    AURAAPPLICATIONADDEDSELFHELPFUL = player_name.." gains %s (%d)."
    AURACHANGEDSELF = player_name.." replaces %s with %s."
    AURADISPELSELF = player_name.."'s %s is removed."
    AURAREMOVEDSELF = "%s fades from "..player_name.."."
    AURASTOLENOTHERSELF = "%s steals "..player_name.."'s %s."
    AURASTOLENSELFOTHER = player_name.." steals %s's %s."
    AURASTOLENSELFSELF = player_name.." steals "..player_name.."'s %s."
    COMBATHITCRITOTHERSELF = "%s crits "..player_name.." for %d."
    COMBATHITCRITSCHOOLOTHERSELF = "%s crits "..player_name.." for %d %s damage."
    COMBATHITCRITSCHOOLSELFOTHER = player_name.." crits %s for %d %s damage."
    COMBATHITCRITSELFOTHER = player_name.." crits %s for %d."
    COMBATHITOTHERSELF = "%s hits "..player_name.." for %d."
    COMBATHITSCHOOLOTHERSELF = "%s hits "..player_name.." for %d %s damage."
    COMBATHITSCHOOLSELFOTHER = player_name.." hits %s for %d %s damage."
    COMBATHITSELFOTHER = player_name.." hits %s for %d."
    DAMAGESHIELDOTHERSELF = "%s reflects %d %s damage to "..player_name.."."
    DAMAGESHIELDSELFOTHER = player_name.." reflects %d %s damage to %s."
    HEALEDCRITOTHERSELF = "%s's %s critically heals "..player_name.." for %d."
    HEALEDCRITSELFOTHER = player_name.."'s %s critically heals %s for %d."
    HEALEDCRITSELFSELF = player_name.."'s %s critically heals "..player_name.." for %d."
    HEALEDOTHERSELF = "%s's %s heals "..player_name.." for %d."
    HEALEDSELFOTHER = player_name.."'s %s heals %s for %d."
    HEALEDSELFSELF = player_name.."'s %s heals "..player_name.." for %d."
    IMMUNEDAMAGECLASSOTHERSELF = player_name.." is immune to %s's %s damage."
    IMMUNEDAMAGECLASSSELFOTHER = "%s is immune to "..player_name.."'s %s damage."
    IMMUNEOTHEROTHER = "%s hits %s, who is immune."
    IMMUNEOTHERSELF = "%s hits "..player_name..", who is immune."
    IMMUNESELFOTHER = player_name.." hits %s, who is immune."
    IMMUNESELFSELF = player_name.." hits "..player_name..", who is immune."
    IMMUNESPELLOTHERSELF = player_name.." is immune to %s's %s."
    IMMUNESPELLSELFOTHER = "%s is immune to "..player_name.."'s %s."
    IMMUNESPELLSELFSELF = player_name.." is immune to "..player_name.."'s %s."
    INSTAKILLSELF = player_name.." is killed by %s."
    ITEMENCHANTMENTADDOTHERSELF = "%s casts %s on "..player_name.."'s %s."
    ITEMENCHANTMENTADDSELFOTHER = player_name.." casts %s on %s's %s."
    ITEMENCHANTMENTADDSELFSELF = player_name.." casts %s on "..player_name.."'s %s."
    ITEMENCHANTMENTREMOVESELF = "%s has faded from "..player_name.."'s %s."
    LOOT_ITEM_CREATED_SELF = player_name.." creates: %s."
    LOOT_ITEM_CREATED_SELF_MULTIPLE = player_name.." creates: %sx%d."
    LOOT_ITEM_PUSHED_SELF = player_name.." receives item: %s."
    LOOT_ITEM_PUSHED_SELF_MULTIPLE = player_name.." receives item: %sx%d."
    LOOT_ITEM_SELF = player_name.." receives loot: %s."
    LOOT_ITEM_SELF_MULTIPLE = player_name.." receives loot: %sx%d."
    MISSEDOTHERSELF = "%s misses "..player_name.."."
    MISSEDSELFOTHER = player_name.." misses %s."
    OPEN_LOCK_SELF = player_name.." performs %s on %s."
    PERIODICAURADAMAGEOTHERSELF = player_name.." suffers %d %s damage from %s's %s."
    PERIODICAURADAMAGESELFOTHER = "%s suffers %d %s damage from "..player_name.."'s %s."
    PERIODICAURADAMAGESELFSELF = player_name.." suffers %d %s damage from "..player_name.."'s %s."
    PERIODICAURAHEALOTHERSELF = player_name.." gains %d health from %s's %s."
    PERIODICAURAHEALSELFOTHER = "%s gains %d health from "..player_name.."'s %s."
    PERIODICAURAHEALSELFSELF = player_name.." gains %d health from "..player_name.."'s %s."
    POWERGAINOTHERSELF = player_name.." gains %d %s from %s's %s."
    POWERGAINSELFOTHER = "%s gains %d %s from "..player_name.."'s %s."
    POWERGAINSELFSELF = player_name.." gains %d %s from "..player_name.."'s %s."
    PROCRESISTOTHERSELF = player_name.." resists %s's %s."
    PROCRESISTSELFOTHER = "%s resists "..player_name.."'s %s."
    PROCRESISTSELFSELF = player_name.." resists "..player_name.."'s %s."
    SELFKILLOTHER = player_name.." slays %s!"
    SIMPLECASTOTHERSELF = "%s casts %s on "..player_name.."."
    SIMPLECASTSELFOTHER = player_name.." casts %s on %s."
    SIMPLECASTSELFSELF = player_name.." casts %s on "..player_name.."."
    SIMPLEPERFORMOTHERSELF = player_name.." performs %s on "..player_name.."."
    SIMPLEPERFORMSELFOTHER = player_name.." performs %s on %s."
    SIMPLEPERFORMSELFSELF = player_name.." performs %s on "..player_name.."."
    SPELLBLOCKEDOTHERSELF = "%s's %s was blocked by "..player_name.."."
    SPELLBLOCKEDSELFOTHER = player_name.."'s %s was blocked by "..player_name.."."
    SPELLCASTGOSELF = player_name.." casts %s."
    SPELLCASTGOSELFTARGETTED = player_name.." casts %s on %s."
    SPELLCASTSELFSTART = player_name.." begins to casts %s."
    SPELLDEFLECTEDOTHERSELF = "%s's %s was deflected by "..player_name.."."
    SPELLDEFLECTEDSELFOTHER = player_name.."'s %s was deflected by %s."
    SPELLDEFLECTEDSELFSELF = player_name.."'s %s was deflected by "..player_name.."."
    SPELLDISMISSPETSELF = player_name.."'s %s is dismissed."
    SPELLDODGEDOTHERSELF = "%s's %s was dodged by "..player_name.."."
    SPELLDODGEDSELFOTHER = player_name.."'s %s was dodged by %s."
    SPELLDODGEDSELFSELF = player_name.."'s %s was dodged by "..player_name.."."
    SPELLDURABILITYDAMAGEALLOTHERSELF = "%s casts %s on "..player_name..": all items damaged."
    SPELLDURABILITYDAMAGEALLSELFOTHER = player_name.." casts %s on %s: all items damaged."
    SPELLDURABILITYDAMAGEOTHERSELF = "%s casts %s on "..player_name..": %s damaged."
    SPELLDURABILITYDAMAGESELFOTHER = player_name.." casts %s on %s: %s damaged."
    SPELLEVADEDOTHERSELF = "%s's %s was evaded by "..player_name.."."
    SPELLEVADEDSELFOTHER = player_name.."'s %s was evaded by %s."
    SPELLEVADEDSELFSELF = player_name.."'s %s was evaded by "..player_name.."."
    SPELLEXTRAATTACKSOTHER_SINGULAR = "%s gains %d extra attacks through %s."
    SPELLEXTRAATTACKSSELF = player_name.." gains %d extra attacks through %s."
    SPELLEXTRAATTACKSSELF_SINGULAR = player_name.." gains %d extra attacks through %s."
    SPELLFAILCASTSELF = player_name.." fails to cast %s: %s."
    SPELLFAILPERFORMSELF = player_name.." fails to perform %s: %s."
    SPELLHAPPINESSDRAINSELF = player_name.."'s %s loses %d happiness."
    SPELLIMMUNEOTHERSELF = "%s's %s fails. "..player_name.." is immune."
    SPELLIMMUNESELFOTHER = player_name.."'s %s fails. %s is immune."
    SPELLIMMUNESELFSELF = player_name.."'s fails. "..player_name.." is immune."
    SPELLINTERRUPTOTHERSELF = "%s interrupts "..player_name.."'s %s."
    SPELLINTERRUPTSELFOTHER = player_name.." interrupts %s's %s."
    SPELLLOGABSORBOTHERSELF = player_name.." absorbs %s's %s."
    SPELLLOGABSORBSELFOTHER = player_name.."'s %s is absorbed by %s."
    SPELLLOGABSORBSELFSELF = player_name.."'s %s is absorbed by "..player_name.."."
    SPELLLOGCRITOTHERSELF = "%s's %s crits "..player_name.." for %d."
    SPELLLOGCRITSCHOOLOTHERSELF = "%s's %s crits "..player_name.." for %d %s damage."
    SPELLLOGCRITSCHOOLSELFOTHER = player_name.."'s %s crits %s for %d %s damage."
    SPELLLOGCRITSCHOOLSELFSELF = player_name.."'s %s crits "..player_name.." for %d %s damage."
    SPELLLOGCRITSELFOTHER = player_name.."'s %s crits %s for %d."
    SPELLLOGCRITSELFSELF = player_name.."'s %s crits "..player_name.." for %d."
    SPELLLOGOTHERSELF = "%s's %s hits "..player_name.." for %d."
    SPELLLOGSCHOOLOTHERSELF = "%s's %s hits "..player_name.." for %d %s damage."
    SPELLLOGSCHOOLSELFOTHER = player_name.."'s %s hits %s for %d %s damage."
    SPELLLOGSCHOOLSELFSELF = player_name.."'s %s hits "..player_name.." for %d %s damage."
    SPELLLOGSELFOTHER = player_name.."'s %s hits %s for %d."
    SPELLLOGSELFSELF = player_name.."'s hits "..player_name.." for %d."
    SPELLMISSOTHERSELF = "%s's %s misses "..player_name.."."
    SPELLMISSSELFOTHER = player_name.."'s %s misses %s."
    SPELLMISSSELFSELF = player_name.."'s %s misses "..player_name.."."
    SPELLPARRIEDOTHERSELF = "%s's %s was parried by "..player_name.."."
    SPELLPARRIEDSELFOTHER = player_name.."'s %s was parried by %s."
    SPELLPARRIEDSELFSELF = player_name.."'s %s was parried by "..player_name.."."
    SPELLPERFORMGOSELF = player_name.." performs %s."
    SPELLPERFORMGOSELFTARGETTED = player_name.." performs %s on %s."
    SPELLPERFORMSELFSTART = player_name.." begins to perform %s."
    SPELLPOWERDRAINOTHERSELF = "%s's %s drains %d %s from "..player_name.."."
    SPELLPOWERDRAINSELFOTHER = player_name.."'s %s drains %d %s from %s."
    SPELLPOWERDRAINSELFSELF = player_name.."'s %s drains %d %s from "..player_name.."."
    SPELLPOWERLEECHOTHERSELF = "%s's %s drains %d %s from "..player_name..". %s gains %d %s."
    SPELLPOWERLEECHSELFOTHER = player_name.."'s %s drains %d %s from %s. "..player_name.." gains %d %s."
    SPELLREFLECTOTHERSELF = "%s's %s is reflected back by "..player_name.."."
    SPELLREFLECTSELFOTHER = player_name.."'s %s is reflected back by %s."
    SPELLREFLECTSELFSELF = player_name.."'s %s is reflected back by "..player_name.."."
    SPELLRESISTOTHERSELF = "%s's %s was resisted by "..player_name.."."
    SPELLRESISTSELFOTHER = player_name.."'s %s was resisted by "..player_name.."."
    SPELLRESISTSELFSELF = player_name.."'s %s was resisted by "..player_name.."."
    SPELLSPLITDAMAGEOTHERSELF = "%s's %s causes "..player_name.." %d damage."
    SPELLSPLITDAMAGESELFOTHER = player_name.."'s %s causes %s %d damage."
    SPELLTEACHOTHERSELF = "%s teaches "..player_name.." %s."
    SPELLTEACHSELFOTHER = player_name.." teaches %s %s."
    SPELLTEACHSELFSELF = player_name.." teaches "..player_name.." %s."
    SPELLTERSEPERFORM_SELF = player_name.." performs %s."
    SPELLTERSE_SELF = player_name.." casts %s."
    UNITDIESSELF = player_name.." dies."
    VSABSORBOTHERSELF = "%s attacks. "..player_name.." absorbs all the damage."
    VSABSORBSELFOTHER = player_name.." attacks. "..player_name.." absorbs all the damage."
    VSBLOCKOTHERSELF = "%s attacks. "..player_name.." blocks."
    VSBLOCKSELFOTHER = player_name.." attacks. %s blocks."
    VSDEFLECTOTHERSELF = "%s attacks. "..player_name.." deflects."
    VSDEFLECTSELFOTHER = player_name.." attacks. %s deflects."
    VSDODGEOTHERSELF = "%s attacks. "..player_name.." dodges."
    VSDODGESELFOTHER = player_name.." attacks. %s dodges."
    VSENVIRONMENTALDAMAGE_DROWNING_SELF = player_name.." is drowning and loses %d health."
    VSENVIRONMENTALDAMAGE_FALLING_SELF = player_name.." falls and loses %d health."
    VSENVIRONMENTALDAMAGE_FATIGUE_SELF = player_name.." is exhausted and loses %d health."
    VSENVIRONMENTALDAMAGE_FIRE_SELF = player_name.." suffers %d points of fire damage."
    VSENVIRONMENTALDAMAGE_LAVA_SELF = player_name.." loses %d health for swimming in lava."
    VSENVIRONMENTALDAMAGE_SLIME_SELF = player_name.." loses %d health for swimming in slime."
    VSEVADEOTHERSELF = "%s attacks. "..player_name.." evades."
    VSEVADESELFOTHER = player_name.." attacks. %s evades."
    VSIMMUNEOTHERSELF = "%s attacks but "..player_name.." is immune."
    VSIMMUNESELFOTHER = player_name.." attacks but %s is immune."
    VSPARRYOTHERSELF = player_name.." attacks. %s parries."
    VSPARRYSELFOTHER = player_name.." attacks. %s parries."
    VSRESISTOTHERSELF = "%s attacks. "..player_name.." resists all the damage."
    VSRESISTSELFOTHER = player_name.." attacks. %s resists all the damage."
end

function RPLL:grab_unit_information(unit)
    local unit_name = UnitName(unit)
    if UnitIsPlayer(unit) and unit_name ~= nil and unit_name ~= Unknown then
        if this.PlayerInformation[unit_name] == nil then
            this.PlayerInformation[unit_name] = {}
            tinsert(this.PlayerRotation, unit_name)
            this.RotationLength = this.RotationLength + 1
        end
        local info = this.PlayerInformation[unit_name]
        info["name"] = unit_name

        -- Guild info
        local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit)
        info["guild_name"] = guildName
        info["guild_rank_name"] = guildRankName
        info["guild_rank_index"] = guildRankIndex

        -- Pet name
        if strfind(unit, "pet") == nil then
            local pet_name = nil
            if unit == "player" then
                pet_name = UnitName("pet")
            elseif strfind(unit, "raid") then
                pet_name = UnitName("raidpet"..strsub(unit, 5))
            elseif strfind(unit, "party") then
                pet_name = UnitName("partypet"..strsub(unit, 6))
            end

            if pet_name ~= nil and pet_name ~= Unknown then
                info["pet"] = pet_name
            end
        end

        -- Hero Class, race, sex
        info["hero_class"] = UnitClass(unit)
        info["race"] = UnitRace(unit)
        info["sex"] = UnitSex(unit)

        -- Gear
        info["gear"] = {}
        for i=1, 19 do
            local inv_link = GetInventoryItemLink(unit, i)
            if inv_link == nil then
                info["gear"][i] = nil
            else
                local found, _, itemString = strfind(inv_link, "Hitem:(.+)\124h%[")
                if found == nil then
                    info["gear"][i] = nil
                else
                    info["gear"][i] = itemString
                end
            end
        end
    end
end

function RPLL:rotate_combat_log_global_string()
    if this.ExtraMessageQueueLength >= this.ExtraMessageQueueIndex then
        SPELLFAILCASTSELF = this.ExtraMessageQueue[this.ExtraMessageQueueIndex]
        SPELLFAILPERFORMSELF = this.ExtraMessageQueue[this.ExtraMessageQueueIndex]
        this.ExtraMessageQueueIndex = this.ExtraMessageQueueIndex + 1
    elseif this.RotationLength ~= 0 then
        local character = this.PlayerInformation[this.PlayerRotation[this.RotationIndex]]
        local result = "COMBATANT_INFO: "
        local gear_str = prep_value(character["gear"][1])
        for i=2, 19 do
            gear_str = gear_str.."&"..prep_value(character["gear"][i])
        end
        result = result..prep_value(character["name"]).."&"..prep_value(character["hero_class"]).."&"..prep_value(character["race"]).."&"..prep_value(character["sex"]).."&"..prep_value(character["pet"]).."&"..prep_value(character["guild_name"]).."&"..prep_value(character["guild_rank_name"]).."&"..prep_value(character["guild_rank_index"]).."&"..gear_str
        SPELLFAILCASTSELF = result
        SPELLFAILPERFORMSELF = result
        if this.RotationIndex + 1 > this.RotationLength then
            this.RotationIndex = 1
        else
            this.RotationIndex = this.RotationIndex + 1
        end
    end
end

function prep_value(val)
    if val == nil then
        return "nil"
    end
    return val
end
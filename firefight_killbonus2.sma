#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <firefight>
#include <hamsandwich>
#include <fakemeta>
#include <colorchat>
#include <cstrike>

#define MAXPLAYERS 32

new g_iMaxPlayers

#define ADMIN_HEALTH	10
#define ADMIN_ARMOR	50
#define ADMIN_SPEED	15.0
#define ADMIN_EXP	25

#define BONUS_RENDERAMT	40
#define BONUS_HEALTH	5
#define BONUS_ARMOR	25
#define BONUS_SPEED	7
#define BONUS_AMMO	30
#define BONUS_GRENADE	0.15
#define BONUS_FLAGS	0.04
#define BONUS_KNIFE	0.15
#define BONUS_PISTOL	5

#define MAX_NADEDMG 	1.75
#define MAX_KNIFEHEAL 	0.60
#define MAX_MOVESPEED 	45

#define STUNNED_SPEED	100.0
#define STUNNED_TIME	1.25

#define EXP_MULTIPLIER 1

#define MIN_FOR_FLAGS 4
#define FLAGS_ROUNDXP 250
#define FLAGS_MATCHXP 500

#define SOUND_BONUS "firefight/bonus.wav"
#define SOUND_CHALLENGE "firefight/levelup-beta.wav"
#define SOUND_PAYBACK "firefight/payback.wav"
#define SOUND_HEADSHOT "player/bhit_helmet-1.wav"

static g_iKillbonuses[] =
{
	50,
	100,
	50,
	50,
	200,
	75,
	300,
	100,
	50,
	50
}

enum
{
	MEDALBOX_NONE = -1,
	BONUS_NONE,
	BONUS_FIRSTBLOOD,
	BONUS_HEADSHOT,
	BONUS_PAYBACK,
	BONUS_ASSASSINATION,
	BONUS_COMEBACK,
	BONUS_FINALKILL,
	BONUS_POSITIONSECURE,
	BONUS_POSITIONSECURE2,
	BONUS_ONEHITONEKILL
}

static const g_szKillbonuses[sizeof g_iKillbonuses][] =
{
	"Kill!",
	"First Blood!",
	"Headshot",
	"Payback!",
	"Assassination!",
	"Comeback!",
	"Final Kill!",
	"Area Secure!",
	"Area Secure!",
	"One shot... one kill"
}

new bool:g_isFirstKill;
new g_iKiller;
new g_iLastKiller[MAXPLAYERS+1]
new g_iDeathCounter[MAXPLAYERS+1]
new g_iLastHitter[MAXPLAYERS+1]


new g_iExperienceToAdd[MAXPLAYERS+1];

#define HUD_LEVEL_RANK 4
#define MEDALBOX_MAX 10
new g_iMedalBox[MAXPLAYERS+1][MEDALBOX_MAX]

#define MEDALBOX_DELAY 1.5
new Float:g_fMedalBoxDelay[MAXPLAYERS+1]

enum
{
	BADGE_PISTOL = 0,
	BADGE_SHOTGUN,
	BADGE_SNIPER,
	BADGE_MACHINEGUN,
	BADGE_ASSAULT,
	BADGE_SMG,
	BADGE_KNIFE,
	BADGE_GRENADE,
	BADGE_FLAG
}
#define BADGE_MAX 9
new g_iBadgeCounter[MAXPLAYERS+1][BADGE_MAX];
new g_iBadgeLevel[MAXPLAYERS+1][BADGE_MAX];

//{9,24,74,149,299,499,749,999, 999}
#define BADGE_LEVELS 8
/*static g_iBadgeRequirements[BADGE_MAX][BADGE_LEVELS] = 
{
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//Pistol
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//Shotgun
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//Sniper
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//Machine Gun
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//Assault Rifles
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//SMGs
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//Knife
	{ 10, 	25, 	100, 	250, 	500, 	1000, 	2500, 	5000	 }, 	//Grenade
	{ 5, 	25, 	50, 	100, 	250, 	500, 	1000, 	2500	 }	//Flag Captures
}*/
static g_iBadgeRequirements[BADGE_MAX][BADGE_LEVELS] = 
{
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//Pistol
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//Shotgun
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//Sniper
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//Machine Gun
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//Assault Rifles
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//SMGs
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//Knife
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }, 	//Grenade
	{ 2, 	5, 	8, 	11, 	14, 	17, 	20, 	25	 }	//Flag Captures
}

static g_iBadgeReward[BADGE_LEVELS] = 
{
	1000,
	2500,
	5000,
	7500,
	10000,
	15000,
	20000,
	25000,
}

static const g_szBadgeNames[BADGE_MAX][3][] =
{
	{ "Pistol Killer", 	"pistol kills",		"% chance to stun enemy"	 },
	{ "Shotgun Pointman", 	"shotgun kills",	"armor"				 },
	{ "Sniper Expert", 	"sniper kills",		"invisibility"			 },
	{ "LMG Terminator", 	"machine gun kills",	"ammo"				 },
	{ "Rifle Surgeon", 	"assault rifle kills",	"health"			 },
	{ "SMG Gunner", 		"SMG kills",		"movement speed"		 },
	{ "Knife Commando", 	"knife kills",		"% damage returned as health"	 },
	{ "HE Pyromaniac", 	"grenade kills",	"explosive damage"		 },
	{ "Flag Capturer", 	"flag captures",	"explosive resistance"		 }
}

static const g_szRomanNumerals[][] =
{
	"I", "II", "III", "IV", "V", "VI", "VII", "VIII"
}

new Float: g_fPlayerHealth[MAXPLAYERS+1];
new Float: g_fPlayerSpeed[MAXPLAYERS+1];
new g_iPlayerRender[MAXPLAYERS+1];
new g_iLastWeapon[MAXPLAYERS+1];
new g_iLastZoom[MAXPLAYERS+1];

new Float: g_fStunnedTime[MAXPLAYERS+1];

#define SPEED_RIFLE	230.0
#define SPEED_SMG	245.0
#define SPEED_KNIFE	260.0
#define SPEED_OTHER	235.0
#define SPEED_SCOPED	150.0
#define SPEED_ZOOMED	210.0

new bool:g_isConnected[MAXPLAYERS+1]
new bool:g_isAlive[MAXPLAYERS+1]
new bool:g_isBot[MAXPLAYERS+1]

public plugin_precache()
{
	precache_sound(SOUND_CHALLENGE);
	precache_sound(SOUND_BONUS);
	precache_sound(SOUND_PAYBACK);
	precache_sound(SOUND_HEADSHOT);
}

public plugin_init()
{
	register_plugin("Killbonuses", VERSION, "Tirant");
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_logevent("logevent_round_end", 2, 	"1=Round_End")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	register_forward(FM_CmdStart, "fw_CmdStart");
	
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage");
	
	register_message(SVC_INTERMISSION, "Message_Intermission");
	g_iMaxPlayers = get_maxplayers()
	
	for (new i = 0; i < g_iMaxPlayers; i++)
		arrayset(g_iMedalBox[i], MEDALBOX_NONE, MEDALBOX_MAX)
}

public plugin_natives()
{
	register_native("ff_get_user_ammo",	"native_get_user_ammo", 1);
	
	register_native("ff_get_user_maxspeed",	"native_get_user_maxspeed", 1);
	register_native("ff_set_user_maxspeed",	"native_set_user_maxspeed", 1);
	
	register_native("ff_get_user_maxhealth","native_get_user_maxhealth", 1);
	register_native("ff_set_user_maxhealth","native_set_user_maxhealth", 1);
	
	register_native("ff_get_user_renderamt","native_get_user_renderamt", 1);
	register_native("ff_set_user_renderamt","native_set_user_renderamt", 1);
}

public event_round_start()
{
	g_isFirstKill = false;
	g_iKiller = 0;
	
	arrayset(g_iLastKiller, 0, g_iMaxPlayers+1);
	arrayset(g_iDeathCounter, 0, g_iMaxPlayers+1);
	arrayset(g_iLastHitter, 0, g_iMaxPlayers+1);
}

public logevent_round_end()
{
	if (g_iKiller)
		task_SetMedalSlot(g_iKiller, BONUS_FINALKILL);
}

public client_putinserver(id)
{
	g_isConnected[id] = true;
	g_isAlive[id] = false;
	if (is_user_bot(id))
		g_isBot[id] = true;
	
	g_fPlayerHealth[id] = 100.0;
	g_fPlayerSpeed[id] = 0.0;
	g_iPlayerRender[id] = 0;
	g_iLastWeapon[id] = 0;
	g_iLastZoom[id] = 0;
	
	g_iExperienceToAdd[id] = 0;
	g_iLastKiller[id] = 0;
	g_iLastHitter[id] = 0;
	g_iDeathCounter[id] = 0;
	
	arrayset(g_iBadgeCounter[id], 0, BADGE_MAX);
	arrayset(g_iMedalBox[id], MEDALBOX_NONE, MEDALBOX_MAX);
	
	//for (new i = 0; i < MEDALBOX_MAX; i++)
	//	g_iMedalBox[id][i] = MEDALBOX_NONE
}

public client_disconnect(id)
{
	g_isConnected[id] = false;
	g_isAlive[id] = false;
	g_isBot[id] = false
	
	g_fPlayerHealth[id] = 100.0;
	g_fPlayerSpeed[id] = 0.0;
	g_iPlayerRender[id] = 0;
	g_iLastWeapon[id] = 0;
	g_iLastZoom[id] = 0;
	
	g_iExperienceToAdd[id] = 0;
	g_iLastKiller[id] = 0;
	g_iLastHitter[id] = 0;
	g_iDeathCounter[id] = 0;
	
	arrayset(g_iBadgeCounter[id], 0, BADGE_MAX);
	arrayset(g_iMedalBox[id], MEDALBOX_NONE, MEDALBOX_MAX);
	
	//for (new i = 0; i < MEDALBOX_MAX; i++)
	//	g_iMedalBox[id][i] = MEDALBOX_NONE
}

public client_damage(attacker, victim, damage, wpnindex, hitplace, TA)
{
	if (!is_user_connected(attacker) || TA)
		return PLUGIN_HANDLED;
		
	if (hitplace == HIT_HEAD)
		client_cmd(attacker, "spk %s", SOUND_HEADSHOT);
	
	if (g_iLastHitter[victim] != attacker)
	{
		g_iLastHitter[victim] = attacker;
		
		new iHealth = pev(victim, pev_health)+damage
		if (damage  >= iHealth && (wpnindex == CSW_SCOUT || wpnindex == CSW_AWP))
			task_SetMedalSlot(attacker, BONUS_ONEHITONEKILL);
	}
	
	if (g_isAlive[attacker] && wpnindex == CSW_KNIFE)
	{
		#define LEECH (g_iBadgeLevel[attacker][BADGE_KNIFE] * BONUS_KNIFE)
		new Float:fHealth = LEECH;
		if (fHealth > MAX_KNIFEHEAL)
			fHealth = MAX_KNIFEHEAL;
		fHealth *= damage;
		fHealth += pev(attacker, pev_health);
		if (fHealth > g_fPlayerHealth[attacker])
			fHealth = g_fPlayerHealth[attacker];
		set_pev(attacker, pev_health, fHealth)
	}
	
	if (get_user_weapon(victim) != CSW_KNIFE && (wpnindex == CSW_USP || wpnindex == CSW_GLOCK18 || wpnindex == CSW_P228 || wpnindex == CSW_DEAGLE || wpnindex == CSW_FIVESEVEN || wpnindex == CSW_ELITE))
	{
		#define CHANCE (g_iBadgeLevel[attacker][BADGE_PISTOL] * BONUS_PISTOL)
		if (random_num(0,100) < CHANCE)
			g_fStunnedTime[victim] = get_gametime() + STUNNED_TIME;
	}
	
	return PLUGIN_CONTINUE;
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (is_user_alive(victim))
		return PLUGIN_HANDLED;
		
	g_isAlive[victim] = false;
		
	if (killer == victim || TK)
		return PLUGIN_HANDLED;
		
	task_SetMedalSlot(killer, BONUS_NONE);
	g_iKiller = killer;
	
	if (!is_user_connected(victim))
		return PLUGIN_HANDLED;
		
	g_iLastHitter[victim] = 0;
	
	if (!g_isFirstKill)
	{
		g_isFirstKill = true;
		task_SetMedalSlot(killer, BONUS_FIRSTBLOOD);
	}
	
	if (hitplace == HIT_HEAD)
	{
		task_SetMedalSlot(killer, BONUS_HEADSHOT);
	}
		
	if (victim == g_iLastKiller[killer])
	{
		client_cmd(victim, "spk %s", SOUND_PAYBACK);
		g_iLastKiller[killer] = 0;
		task_SetMedalSlot(killer, BONUS_PAYBACK);
	}
	g_iLastKiller[victim] = killer;
	
	new iBadgeMode = -1;
	if (wpnindex == CSW_KNIFE)
	{
		iBadgeMode = BADGE_KNIFE;
		task_SetMedalSlot(killer, BONUS_ASSASSINATION);
	}
		
	if (g_iDeathCounter[killer] > 2)
	{
		g_iDeathCounter[killer] = 0;
		task_SetMedalSlot(killer, BONUS_COMEBACK);
	}
	g_iDeathCounter[victim]++
	
	if (wpnindex == CSW_USP || wpnindex == CSW_GLOCK18 || wpnindex == CSW_P228 || wpnindex == CSW_FIVESEVEN || wpnindex == CSW_DEAGLE || wpnindex == CSW_ELITE)
		iBadgeMode = BADGE_PISTOL;
	else if (wpnindex == CSW_XM1014 || wpnindex == CSW_M3)
		iBadgeMode = BADGE_SHOTGUN;
	else if (wpnindex == CSW_SCOUT || wpnindex == CSW_AWP || wpnindex == CSW_SG550 || wpnindex == CSW_G3SG1)
		iBadgeMode = BADGE_SNIPER;
	else if (wpnindex == CSW_M249)
		iBadgeMode = BADGE_MACHINEGUN;
	else if (wpnindex == CSW_FAMAS || wpnindex == CSW_GALIL || wpnindex == CSW_M4A1 || wpnindex == CSW_AK47 || wpnindex == CSW_AUG || wpnindex == CSW_SG552)
		iBadgeMode = BADGE_ASSAULT;
	else if (wpnindex == CSW_MAC10 || wpnindex == CSW_TMP || wpnindex == CSW_MP5NAVY || wpnindex == CSW_UMP45 || wpnindex == CSW_P90)
		iBadgeMode = BADGE_SMG;
	else if (wpnindex == CSW_HEGRENADE)
		iBadgeMode = BADGE_GRENADE;
		
	task_AddBadgeStats(killer, iBadgeMode);
	
	return PLUGIN_CONTINUE;
}

task_SetMedalSlot(id, iMedal)
{
	if (g_isBot[id])
		return false;
		
	if (iMedal <= MEDALBOX_NONE)
		return false;

	for ( new i = 0; i < MEDALBOX_MAX; i++)
	{
		if (g_iMedalBox[id][i] <= MEDALBOX_NONE)
		{
			g_iMedalBox[id][i] = iMedal
			break;
		}
	}
	
	return true;
}

task_AddBadgeStats(id, iBadge)
{
	g_iBadgeCounter[id][iBadge]++;
	
	#define iBadgeLevel g_iBadgeLevel[id][iBadge]
	if (iBadgeLevel < BADGE_LEVELS)
	{
		if (g_iBadgeCounter[id][iBadge] >= g_iBadgeRequirements[iBadge][iBadgeLevel])
		{
			iBadgeLevel++;
			task_SetMedalSlot(id, iBadge+100);
		}
	}
}

public task_SetBadgeSlot(id, iMedal)
{
	if (g_isBot[id])
		return false;
		
	if (iMedal <= MEDALBOX_NONE)
		return false;

	for ( new i = 0; i < MEDALBOX_MAX; i++)
	{
		if (g_iMedalBox[id][i] <= MEDALBOX_NONE)
		{
			g_iMedalBox[id][i] = iMedal
			break;
		}
	}
	
	return true;
}

public csf_flag_taken(id)
{
	if ( get_playersnum() < MIN_FOR_FLAGS )
		return;
	
	task_SetMedalSlot(id, BONUS_POSITIONSECURE);
	task_AddBadgeStats(id, BADGE_FLAG);
}

public csf_flag_taken_assist(id)
{
	if ( get_playersnum() < MIN_FOR_FLAGS )
		return;
	
	task_SetMedalSlot(id, BONUS_POSITIONSECURE2);
	task_AddBadgeStats(id, BADGE_FLAG);
}

public csf_round_won(CsTeams:team)
{
	if ( get_playersnum() < MIN_FOR_FLAGS )
		return;

	#if defined FLAGS_ROUNDXP
	for ( new id = 1; id <= g_iMaxPlayers; id++ )
	{
		if ( !is_user_connected(id) ) continue;
		if ( cs_get_user_team(id) != team ) continue;

		ff_add_user_xp(id, FLAGS_ROUNDXP);
		client_print_color(id, DontChange, "%s You've received ^4%dXP ^1for winning the flag round", MODNAME, FLAGS_ROUNDXP);
	}
	#endif
}

public csf_match_won(CsTeams:team)
{
	if ( get_playersnum() < MIN_FOR_FLAGS )
		return;

	#if defined FLAGS_MATCHXP
	for ( new id = 1; id <= g_iMaxPlayers; id++ )
	{
		if ( !is_user_connected(id) || is_user_bot(id) ) continue;
		if ( cs_get_user_team(id) != team ) continue;

		ff_add_user_xp(id, FLAGS_MATCHXP);
		client_print_color(id, DontChange, "%s You've received ^4%dXP ^1for winning the flag match", MODNAME, FLAGS_MATCHXP);
	}
	#endif
}


public fw_PlayerPreThink(id)
{
	if (!g_isConnected[id] || g_isBot[id])
		return FMRES_IGNORED;
		
	static Float:fGameTime
	fGameTime = get_gametime()
	
	if (g_fStunnedTime[id] > fGameTime)
		set_pev(id, pev_maxspeed, STUNNED_SPEED);
	else
		task_SetUserSpeed(id);
	
	new bool:isMedal
	
	if (g_fMedalBoxDelay[id] < fGameTime)
	{	
		for (new i = 0; i < MEDALBOX_MAX; i++)
		{
			if (g_iMedalBox[id][i] > MEDALBOX_NONE)
			{	
				g_fMedalBoxDelay[id] = fGameTime + MEDALBOX_DELAY
				
				new iMedal = g_iMedalBox[id][i]
				g_iMedalBox[id][i] = MEDALBOX_NONE
				
				//set_hudmessage(240, 240, 0, -1.0, 0.45, 0, 0.0, 2.5, 0.02, 0.02, HUD_LEVEL_RANK)
				set_hudmessage(0, 240, 240, -1.0, 0.40, 0, 0.0, 2.5, 0.02, 0.02, HUD_LEVEL_RANK)
				
				if (iMedal < 1)
				{
					show_hudmessage(id, "+%dXP", (access(id, ADMIN_LEVEL_A) ? (g_iKillbonuses[iMedal] + ADMIN_EXP) : (g_iKillbonuses[iMedal])) );
					new iExp = g_iKillbonuses[iMedal];
					if (access(id, ADMIN_LEVEL_A)) iExp += ADMIN_EXP;
					g_iExperienceToAdd[id] += iExp;
				}
				else if (iMedal >= 100)
				{
					iMedal -= 100;
					#define iLevel g_iBadgeLevel[id][iMedal]-1
					
					show_hudmessage(id, "%s %s^nGet %d %s^n[+%dXP]", g_szBadgeNames[iMedal][0], g_szRomanNumerals[iLevel], g_iBadgeRequirements[iMedal][iLevel], g_szBadgeNames[iMedal][1], g_iBadgeReward[iLevel]);
					client_print_color(id, DontChange, "%s ^3You have completed the ^1[^4%s %s^1] ^3badge ^1[^4%d %s^1] ^3for ^4%d^3XP", MODNAME, g_szBadgeNames[iMedal][0], g_szRomanNumerals[iLevel], g_iBadgeRequirements[iMedal][iLevel], g_szBadgeNames[iMedal][1], g_iBadgeReward[iLevel]);
					client_print_color(id, DontChange, "%s ^3Your ^1[^4%s^1] ^3as been increased", MODNAME, g_szBadgeNames[iMedal][2]);
					//g_iExperienceToAdd[id] += g_iBadgeReward[iLevel];
					
					client_cmd(id, "spk %s", SOUND_CHALLENGE);
				}
				else
				{
					show_hudmessage(id, "%s [+%dXP]", g_szKillbonuses[iMedal], g_iKillbonuses[iMedal]);
					g_iExperienceToAdd[id] += g_iKillbonuses[iMedal];
					
					if (iMedal != BONUS_POSITIONSECURE)
						client_cmd(id, "spk %s", SOUND_BONUS);
				}

				isMedal = true;
				
				break;
			}
		}
	}
	
	if (!isMedal)
	{
		g_iExperienceToAdd[id] *= EXP_MULTIPLIER;
		if (g_iExperienceToAdd[id] > 0)
			ff_add_user_xp(id, g_iExperienceToAdd[id]);
		g_iExperienceToAdd[id] = 0;
	}
	
	return FMRES_IGNORED;
}

public ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return HAM_IGNORED;
		
	g_isAlive[id] = true;

	#define HEALTH (100 + (g_iBadgeLevel[id][BADGE_ASSAULT]*BONUS_HEALTH))
	new iHealth = HEALTH;
	if (access(id, ADMIN_LEVEL_A)) iHealth += ADMIN_HEALTH;
	g_fPlayerHealth[id] = float(iHealth);
	set_pev(id, pev_health, g_fPlayerHealth[id]);
	
	#define ARMOR (g_iBadgeLevel[id][BADGE_SHOTGUN]*BONUS_ARMOR)
	new iArmor = ARMOR;
	if (access(id, ADMIN_LEVEL_A)) iArmor += ADMIN_ARMOR;
	cs_set_user_armor ( id, iArmor,CS_ARMOR_VESTHELM);
	
	return HAM_IGNORED;
}

public ham_TakeDamage(victim, useless, attacker, Float:damage, damagebits)
{
	if (!is_user_connected(attacker) || !g_isAlive[victim])
		return HAM_HANDLED;
	
	if (damagebits & (1<<24))
	{
		#define MODIFIER 1.0 + (g_iBadgeLevel[attacker][BADGE_GRENADE] * BONUS_GRENADE)
		new Float:fDamage = MODIFIER;
		if (fDamage > MAX_NADEDMG)
			fDamage = MAX_NADEDMG;
		damage *= fDamage;
		
		#define REDUCER 1.0 - (g_iBadgeLevel[attacker][BADGE_FLAG] * BONUS_FLAGS)
		damage *= fDamage;
	}
		
	SetHamParamFloat(4, damage)
	return HAM_HANDLED
}

task_SetUserSpeed(id)
{
	if (!g_isAlive[id])
		return;
		
	new dummy;
	new weapon = get_user_weapon( id,dummy,dummy);
	new zoom = cs_get_user_zoom(id);
	
	if (weapon == g_iLastWeapon[id] && zoom == g_iLastZoom[id])
		return;
		
	g_iLastWeapon[id] = weapon
	g_iLastZoom[id] = zoom
	new Float: fPlayerSpeed = SPEED_OTHER;

	//Sniper Rifles (minus scout)
	if (weapon != CSW_SCOUT && ((zoom == 2) || ( zoom == 3 )))
	{
		fPlayerSpeed = SPEED_SCOPED
	}
	//Partial Zoomed Rifles and Scout
	else if (weapon == CSW_SCOUT && ((zoom == 2) || ( zoom==3 )) || (zoom == 4))
	{
		fPlayerSpeed = SPEED_ZOOMED;
	}
	//Knife
	else if (weapon == CSW_KNIFE || weapon == CSW_HEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_SMOKEGRENADE)
	{
		fPlayerSpeed = SPEED_KNIFE;
	}
	//Rifles
	else if (weapon == CSW_FAMAS || weapon == CSW_GALIL || weapon == CSW_M4A1 || weapon == CSW_AK47 || weapon == CSW_AUG || weapon == CSW_SG552)
	{
		fPlayerSpeed = SPEED_RIFLE;
	}
	//SMGs
	else if (weapon == CSW_MAC10 || weapon == CSW_TMP || weapon == CSW_MP5NAVY || weapon == CSW_UMP45 || weapon == CSW_P90)
	{
		fPlayerSpeed = SPEED_SMG;
	}
	
	fPlayerSpeed += float(clamp((g_iBadgeLevel[id][BADGE_SMG] * BONUS_SPEED), 0, MAX_MOVESPEED));
	if (access(id, ADMIN_LEVEL_A)) fPlayerSpeed += ADMIN_SPEED;
	g_fPlayerSpeed[id] = fPlayerSpeed;
	
	set_pev(id, pev_maxspeed, g_fPlayerSpeed[id])
}

public fw_CmdStart( id, uc_handle, randseed )
{
	if (!g_isAlive[id])
		return FMRES_IGNORED;
	
	new dummy;
	new weapon = get_user_weapon( id,dummy,dummy);
	g_iLastWeapon[id] = weapon;

	if (!g_iBadgeLevel[id][BADGE_SNIPER] || (weapon != CSW_KNIFE && weapon != CSW_SCOUT && weapon != CSW_AWP))
	{
		fm_set_rendering(id);
		return FMRES_IGNORED;
	}
	
	new Float:fmove, Float:smove;
	get_uc(uc_handle, UC_ForwardMove, fmove);
	get_uc(uc_handle, UC_SideMove, smove );

	new Float:maxspeed;
	pev(id, pev_maxspeed, maxspeed);
	new Float:walkspeed = (maxspeed * 0.52); 
	fmove = floatabs( fmove );
	smove = floatabs( smove );

	static VISIBILITY;
	VISIBILITY = (g_iBadgeLevel[id][BADGE_SNIPER] * BONUS_RENDERAMT);
		
	if (g_iLastWeapon[id] == CSW_KNIFE)
	{
		if (fmove <= walkspeed && smove <= walkspeed)
		{
			fm_set_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, clamp(255-VISIBILITY, 50, 255));
		}
		else
		{
			fm_set_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, clamp(255-floatround(VISIBILITY*0.5), 100, 255));
		}
	}
	else if (g_iLastWeapon[id] == CSW_AWP || g_iLastWeapon[id] == CSW_SCOUT)
	{
		if (fmove <= walkspeed && smove <= walkspeed)
		{
			fm_set_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, clamp(255-floatround(VISIBILITY*0.66), 125, 255));
			
		}
		else
		{
			fm_set_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, clamp(255-floatround(VISIBILITY*0.33), 150, 255));
		}
	}
	
	return FMRES_IGNORED;
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)

	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, RenderColor)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))

	if (entity < MAXPLAYERS+1)
	{
		//if (g_iPlayerRender[entity] != amount)
		//	client_print(entity, print_chat, "Invis changed to %d/255", amount);
		g_iPlayerRender[entity] = amount
	}
	return amount;
}

/*public vault_server_save() 
{
    	new vaultkey[64],vaultdata[256]

    	formatex(vaultkey,63,"BF2-ServerData")
    	formatex(vaultdata,255,"%i#^"%s^"#%i#^"%s^"#%i#^"%s^"",highestrankserver,highestrankservername,mostkills,mostkillsname,mostwins,mostwinsname)

	nvault_set(g_Vault,vaultkey,vaultdata)

    	return PLUGIN_CONTINUE;	
}

public vault_server_load()
{	
	new vaultkey[64], vaultdata[256]; 
	new TimeStamp;

	formatex(vaultkey,63,"BF2-ServerData");

    	if(nvault_lookup(g_Vault, vaultkey, vaultdata, sizeof(vaultdata) - 1, TimeStamp ))
    	{	
		new str_rank[8],str_kills[8],str_wins[8]
        	
		replace_all(vaultdata,253,"#"," ")

		parse(vaultdata,str_rank,7,highestrankservername,29,str_kills,7,mostkillsname,29,str_wins,7,mostwinsname,29)      
		        	
		highestrankserver = str_to_num(str_rank)
		mostkills = str_to_num(str_kills)
		mostwins = str_to_num(str_wins)
    	}
}*/

public Message_Intermission(msg_id,msg_dest,msg_entity)
{
	set_task(0.1,"task_CheckAwards");
}

public task_CheckAwards()
{
	//Run on SVC_INTERMISSION (Map change)
	//Find the top three Fragging players and award them with a star

	new players[32],num
	get_players(players,num,"h")

	new iTempFrags,id

	new iSwapFrags,iSwapID

	new iStarFrags[3] //0 - Bronze / 1 - Silver / 2 - Gold
	new iStarID[3]

	for (new i=0; i<num; i++)
	{
		id = players[i]
		iTempFrags = get_user_frags(id)
		if (iTempFrags>iStarFrags[0])
		{
			iStarFrags[0] = iTempFrags
			iStarID[0] = id
			if (iTempFrags > iStarFrags[1])
			{
				iSwapFrags = iStarFrags[1]
				iSwapID = iStarID[1]
				iStarFrags[1] = iTempFrags
				iStarID[1] = id
				iStarFrags[0] = iSwapFrags
				iStarID[0] = iSwapID

				if (iTempFrags > iStarFrags[2])
				{
					iSwapFrags = iStarFrags[2]
					iSwapID = iStarID[2]
					iStarFrags[2] = iTempFrags
					iStarID[2] = id
					iStarFrags[1] = iSwapFrags
					iStarID[1] = iSwapID
				}
			}	
		}
		//save_badges(id)
	}
	
	if (!iStarID[2])
		return;
	
	new szName[30];
	/*new winner = iStarID[2]
	new bool:newleader=false;

	if (!winner)
		return;

	//We now should have our three awards

	bronze[iStarID[0]]++
	silver[iStarID[1]]++
	gold[winner]++

	save_badges(iStarID[0])
	save_badges(iStarID[1])
	save_badges(winner)

	get_user_name(iStarID[2],szName,29)

	if (gold[winner]>mostwins)
	{
		mostwins=gold[winner]
		newleader=true
		format(mostwinsname,29,szName)
	}

	server_save()*/

	client_print_color(0, DontChange, "%s ^4Congratulations to the kill leaders!", MODNAME);

	get_user_name(iStarID[0],szName,29)
	client_print_color(0, DontChange, "%s ^3%s ^4- ^3Bronze Medal ^4- ^1%d ^4Kills", MODNAME, szName, iStarFrags[0]);

	get_user_name(iStarID[1],szName,29)
	client_print_color(0, DontChange, "%s ^3%s ^4- ^3Silver Medal ^4- ^1%d ^4Kills", MODNAME, szName, iStarFrags[1]);

	get_user_name(iStarID[2],szName,29)
	client_print_color(0, DontChange, "%s ^3%s ^4- ^3Gold Medal ^4- ^1%d ^4Kills", MODNAME, szName, iStarFrags[2]);
}

public native_get_user_ammo(id) return g_iBadgeLevel[id][BADGE_MACHINEGUN]*BONUS_AMMO;

public native_get_user_maxspeed(id)return floatround(g_fPlayerSpeed[id]);
public native_set_user_maxspeed(id, iSpeed)
{
	if (!g_isConnected[id])
		return 0;
		
	g_fPlayerSpeed[id] = float(iSpeed);
	return floatround(g_fPlayerSpeed[id]);
}

public native_get_user_maxhealth(id) return floatround(g_fPlayerHealth[id]);
public native_set_user_maxhealth(id, iHealth)
{
	if (!g_isConnected[id])
		return 0;
		
	g_fPlayerHealth[id] = float(iHealth);
	return floatround(g_fPlayerHealth[id]);
}

public native_get_user_renderamt(id) return g_iPlayerRender[id];
public native_set_user_renderamt(id, iRenderAmt)
{
	if (!g_isConnected[id])
		return 0;
		
	g_iPlayerRender[id] = iRenderAmt;
	return g_iPlayerRender[id];
}

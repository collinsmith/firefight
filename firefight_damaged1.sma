//#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <hamsandwich>
#include <fakemeta>
#include <fb_controller>
#include <screenfade_util>

#define VERSION "1.0"

#define SOUND_BREATH "firefight/damaged.wav"

#define SOUND_HITMARKER "firefight/hit_marker.wav"

#define HUD_LEVEL_DAMAGE 1

#define MAXPLAYERS 32
new bool:g_isConnected[MAXPLAYERS+1];
new bool:g_isAlive[MAXPLAYERS+1];
new bool:g_isBot[MAXPLAYERS+1];

#define DELAY_HEAL 8.0
new Float:g_fHealDelay[MAXPLAYERS+1];
new bool:g_isHealDelay[MAXPLAYERS+1];

#define DELAY_SOUND 1.500//1.509
new Float:g_fDamagedDelay[MAXPLAYERS+1];

new Float:g_fFlashDelay[MAXPLAYERS+1];
new bool:g_isFlashed[MAXPLAYERS+1];

public plugin_init()
{
	register_plugin("Damage", VERSION, "Tirant");
	
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage");
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
}

public plugin_precache()
{
	precache_sound(SOUND_BREATH);
	precache_sound(SOUND_HITMARKER);
}

public client_putinserver(id)
{
	task_ResetVars(id)
	g_isConnected[id] = true;
	if (is_user_bot(id))
		g_isBot[id] = true;
}

public client_disconnect(id)
{
	task_ResetVars(id)
}

task_ResetVars(id)
{
	g_isConnected[id] = false;
	g_isAlive[id] = false;
	g_isBot[id] = false;
	g_isFlashed[id] = false;
	g_isHealDelay[id] = false;	
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (is_user_alive(victim))
		return;
		
	g_isAlive[victim] = false;
	g_isFlashed[victim] = false;
	g_isHealDelay[victim] = false;
}

public ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;
		
	server_cmd("echo Player has spawned! firefight_damaged1");
		
	g_isAlive[id] = true;
}

public ham_TakeDamage(victim, useless, attacker, Float:damage, damagebits)
{
	new bool:isConnected = true;
	if (!is_user_connected(attacker))
		isConnected = false;
	
	if (isConnected && g_isBot[attacker])
		isConnected = false;
	
	if (!is_user_alive(victim))
		return HAM_HANDLED;
	
	new iHealth = pev(victim, pev_health);
	if (iHealth == 100)
		return HAM_HANDLED;
	
	new bool:TeamKill;
	if (isConnected)
	{
		if (get_user_team(attacker) == get_user_team(victim) && victim != attacker)
			TeamKill = true;
	}
	
	if ( !TeamKill )
	{
		if (isConnected && victim != attacker)
			task_ShowDamageHUD(attacker);
			
		if (!g_isFlashed[victim])
		{
			#define Algorithm (((150-iHealth)-0)+0)
			UTIL_ScreenFade(victim, {225, 25, 25}, DELAY_HEAL*0.15, DELAY_HEAL*0.85, Algorithm, FFADE_IN, false, false);
		}
		
		if (!g_isHealDelay[victim])
			g_isHealDelay[victim] = true;
	
		g_fHealDelay[victim] = get_gametime() + DELAY_HEAL;
	}
	
	return HAM_HANDLED;
}

task_ShowDamageHUD(id)
{
	client_cmd(id, "spk %s", SOUND_HITMARKER);
	set_hudmessage(240, 240, 0, -1.0, -1.0, 0, 0.0, 0.5, 0.02, 0.02, HUD_LEVEL_DAMAGE);
	show_hudmessage(id, "x");	
}

public fw_PlayerPreThink(id)
{
	if (!g_isConnected[id] || g_isBot[id])
		return FMRES_IGNORED;
		
	static Float:fGameTime;
	fGameTime = get_gametime();
	
	if (is_user_alive(id))
	{
		if (pev(id, pev_health) < 100 && !g_isHealDelay[id])
		{
			g_isHealDelay[id] = true;
			g_fHealDelay[id] = get_gametime() + DELAY_HEAL;
		}
		
		if (g_fHealDelay[id] < fGameTime && g_isHealDelay[id])
		{	
			set_pev(id, pev_health, 100.0);
			g_isHealDelay[id] = false;
		}
		
		if (g_isHealDelay[id] && g_fDamagedDelay[id] < fGameTime)
		{
			client_cmd(id, "spk %s", SOUND_BREATH);
			g_fDamagedDelay[id] = get_gametime() + DELAY_SOUND;
		}
	}
	
	if (g_fFlashDelay[id] < fGameTime && g_isFlashed[id])
	{
		g_isFlashed[id] = false;
	}
	
	return FMRES_IGNORED;
}


public fw_FRC_preflash(flasher, flashed, flashbang, amount)
{
	if (!g_isConnected[flasher] || !g_isConnected[flashed])
		return PLUGIN_HANDLED;
		
	g_isFlashed[flashed] = true;
	
	static iFlashed;
	iFlashed = get_FRC_duration(flashed) + get_FRC_holdtime(flashed);
	
	g_fFlashDelay[flashed] = get_gametime() + float(iFlashed / 10);
	
	if (flasher != flashed)
		task_ShowDamageHUD(flasher);
		
	return PLUGIN_CONTINUE;
}

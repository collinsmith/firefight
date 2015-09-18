#include <amxmodx>
#include <amxmisc>
#include <csdm>
#include <csx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <colorchat>
#include <firefight>

static const Plugin [] = "Experience";
static const Version[] = "0.0.5";
static const Author [] = "Tirant";

enum (+= 5000)
{
	XPLOAD_TASK = 100000
}

new g_iMaxPlayers
new gmsgStatusText
new gHudSyncInfo
//new bool:g_isFreezeTime = true;

static const g_szLevelGained	[] = "firefight/levelup-beta.wav"
static const g_szRankingOfficer	[] = "buttons/bell1.wav"

new g_iExperience[MAXPLAYERS+1]

#define LEVEL_NONE -1
new g_iRank[MAXPLAYERS+1]
new g_iHighestRankID

#define HUD_RANK_R 000
#define HUD_RANK_G 240
#define HUD_RANK_B 120

#define HUD_COLOR_FRIEND 255
#define HUD_COLOR_ENEMY	 255
#define HUD_HEIGHT	 0.35	
new g_iFriend[MAXPLAYERS+1]
new CsTeams:g_iCurTeam[MAXPLAYERS+1]

new bool:g_isConnected[MAXPLAYERS+1]
new bool:g_isAlive[MAXPLAYERS+1]
new bool:g_isBot[MAXPLAYERS+1]

new g_szModName[32]

new const g_szRankName[][] = 
{ 
	"Rank 1",
	"Rank 2",
	"Rank 3",
	"Rank 4",
	"Rank 5"
};

new const g_iRankXP[sizeof g_szRankName-1] =
{
	100,
	200,
	300,
	400
};

#define MAX_RANK (sizeof g_iRankXP)

//Forwards
new g_fwDummyResult

new g_fwRankUp, g_fwRewardXP

//nVault
new g_szAuth[MAXPLAYERS+1][35];
new g_Vault

//Save Vars for XP top 10
new g_szStatXP[10][32], g_iStatXP[10],g_iStatLVL[10];

#define ICON_SECONDS 2
new g_szSprites[50];

public plugin_precache()
{
	precache_sound(g_szLevelGained);
	precache_sound(g_szRankingOfficer);
	
	new szSprite[32]
	for (new i = 0; i < 50; i++)
	{
		format(szSprite, 31, "sprites/firefight/%d.spr", i);
		g_szSprites[i] = precache_model(szSprite);
	}
}

public plugin_cfg()
{
	g_Vault = nvault_open( "ff-experience" );

	if ( g_Vault == INVALID_HANDLE )
		set_fail_state( "Error opening Battlefield nVault, file does not exist!" );
		
	vault_server_load()
}

public plugin_init()
{
	register_plugin(Plugin, Version, Author);
	
	csdm_set_intromsg(0);
	formatex(g_szModName, charsmax(g_szModName), "%s %s", MODNAME2, VERSION)

	register_clcmd("say", 	   	"cmdSay");
	register_clcmd("say_team",	"cmdSay");
	
	register_concmd("ff_setlevel",	"cmdSetLevel",ADMIN_CVAR,"<name> <rank>")
	register_concmd("ff_addxp",	"cmdAddExperience",ADMIN_CVAR,"<name> <experience>")
	
	register_event("StatusValue", "setTeam", "be", "1=1");
	register_event("StatusValue", "on_ShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "on_HideStatus", "be", "1=1", "2=0");
	
	register_message(get_user_msgid("TeamInfo"), "msgTeamInfo");
	
	//register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	register_forward(FM_GetGameDescription, "fw_GetGameDescription")
	
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1);
	
	g_iMaxPlayers = get_maxplayers();
	gmsgStatusText = get_user_msgid("StatusText");
	gHudSyncInfo = CreateHudSyncObj();
	
	arrayset(g_iRank, LEVEL_NONE, g_iMaxPlayers+1);
	
	//Custom forwards
	g_fwRankUp = CreateMultiForward("ff_player_rankup", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwRewardXP = CreateMultiForward("ff_player_gainxp", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_natives()
{
	register_native("ff_reset_user_rank",	"task_ResetXP", 1);
	
	register_native("ff_get_rankofficer",	"native_get_highest_rank", 1);
	
	register_native("ff_get_user_rank",	"native_get_user_rank", 1);
	register_native("ff_set_user_rank",	"task_SetLevel", 1);
	
	register_native("ff_get_user_xp",	"native_get_user_experience", 1);
	register_native("ff_add_user_xp",	"task_AddXP", 1);
}

#define PRUNE_DAYS 90
#define NEGATIVE_SECONDSINDAY -86400 //number of seconds in a day.. (60*60*24)

public plugin_end()
{
	DestroyForward(g_fwRankUp);
	DestroyForward(g_fwRewardXP);	
	
	new pruneDelay = (NEGATIVE_SECONDSINDAY * PRUNE_DAYS);
	nvault_prune(g_Vault, 0, get_systime(pruneDelay));
	
	vault_server_save();
	nvault_close(g_Vault);
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, g_szModName)
	return FMRES_SUPERCEDE;
}

public client_putinserver(id)
{
	task_ResetVars(id);
	
	g_isConnected[id] = true;
	if (is_user_bot(id))
	{
		g_isBot[id] = true;
		g_iRank[id] = 0;
	}
		
	get_load_key(id);
}

public client_disconnect(id)
{
	if (id == g_iHighestRankID)
	{
		client_print_color(0, DontChange, "%s ^1The highest ranking officer has left the game...", MODNAME);
		
		g_iHighestRankID = 0;
		new i;
		for (i = 0; i < MAXPLAYERS+1; i++)
		{
			if (!g_isConnected[i] || i == id || g_isBot[i])
				continue;
				
			if (!g_iHighestRankID)
				g_iHighestRankID = i;
			else if (g_iExperience[i] > g_iExperience[g_iHighestRankID])
				g_iHighestRankID = i;
		}
		
		if (g_iHighestRankID)
		{
			client_cmd(0, "spk %s", g_szRankingOfficer);
			new szPlayerName[32]
			get_user_name(g_iHighestRankID, szPlayerName, 31);
			client_print_color(0, DontChange, "%s ^4%s ^3is now the highest ranking officer in the server at ^1%s", MODNAME, szPlayerName, g_szRankName[g_iRank[g_iHighestRankID]]);
		}
	}
	
	SaveLevel(id);
	
	task_ResetVars(id);
	
	remove_task(id+XPLOAD_TASK);
}

task_ResetVars(id)
{
	g_isConnected[id] = false;
	g_isAlive[id] = false;
	g_isBot[id] = false;
	
	g_iExperience[id] = 0;
	g_iRank[id] = LEVEL_NONE;
	
	format(g_szAuth[id], 34, "^0");
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (is_user_alive(victim) || killer == victim || TK)
		return;
		
	g_isAlive[victim] = false;
}

/**
 * This loop will go through and check if thier current experience is
 * higher then the next rank. When their XP is not, then it will set
 * their rank to this rank. This is only used upon initial connect.
 **/
task_GetLevel(id)
{
	if (!g_isConnected[id] || g_isBot[id])
		return 0;
	
	/*new i = 0;
	if (g_iExperience[id] > g_iRankXP[sizeof (g_iRankXP) * 3 / 4])
		i = sizeof (g_iRankXP) * 3 / 4
	else if (g_iExperience[id] > g_iRankXP[sizeof (g_iRankXP) / 2])
		i = sizeof (g_iRankXP) / 2
	else if (g_iExperience[id] > g_iRankXP[sizeof (g_iRankXP) / 4])
		i = sizeof (g_iRankXP) / 4*/
	
	new i = 0;
	new imin = 0;
	new imax = sizeof g_iRankXP-1;
	while (g_iRankXP[i] >= g_iExperience[id] && imin <= imax) {
		i = (imin+imax) / 2;
		if (g_iExperience[id] > g_iRankXP[i])
			imin = inum + 1;
		else
			imax = inum - 1;
	}
	
	/*while (g_iExperience[id] >= g_iRankXP[i] && i < MAX_RANK)
	{
		i++;
		
		if (i == MAX_RANK)
			break;
	}
	i--;*/
	
	//i = clamp (i, 0, MAX_RANK-1);
	g_iRank[id] = i;
	
	if (g_iExperience[id] > g_iExperience[g_iHighestRankID])
	{
		g_iHighestRankID = id;
		client_cmd(0, "spk %s", g_szRankingOfficer);
		new szPlayerName[32]
		get_user_name(id, szPlayerName, 31);
		client_print_color(0, DontChange, "%s ^4%s ^3is now the new highest ranking officer in the server at ^1%s", MODNAME, szPlayerName, g_szRankName[i]);
	}
	
	return g_iRank[id];
}

/**
 * This is the proper and correct way to add experience. This checks their XP and blocks
 * max level bugs.
 **/
public task_AddXP(id, iExperience)
{
	if (!g_isConnected[id] || g_isBot[id] )
		return 0;
		
	if (iExperience < 0 || g_iExperience[id] >= g_iRankXP[MAX_RANK-1])
		return 0;
	
	ExecuteForward(g_fwRewardXP, g_fwDummyResult, id, iExperience, g_iExperience[id], g_iExperience[id]+iExperience);
	
	iExperience += g_iExperience[id];
	
	if (iExperience > g_iRankXP[MAX_RANK-1])
		g_iExperience[id] = g_iRankXP[MAX_RANK-1]
	else
		g_iExperience[id] = iExperience
	
	/**
	 * This will check if they should level up
	 **/
	if (-1 < g_iRank[id] < MAX_RANK-1)
	{	
		static iRank;
		iRank = g_iRank[id];
		
		static iNextRank;
		iNextRank = iRank+1;

		/**
		 * This is the actual rank up code
		 **/
		if (g_iExperience[id] >= g_iRankXP[iNextRank])
		{
			g_iRank[id]++;
			task_ShowRankHUD(id, iNextRank);	
			//task_DisplayHUD(id);
			
			SaveLevel(id);
		}
	}
	
	new i = 0;
	while (g_iExperience[id] >= g_iStatXP[i] && i < 10)
	{
		if (i == 0)
		{
			get_user_name(id, g_szStatXP[i], 31);
			g_iStatXP[i] = g_iExperience[id];
			g_iStatLVL[i] = g_iRank[id]+1;
		}
		else
		{
			formatex(g_szStatXP[i-1], 31, g_szStatXP[i])
			get_user_name(id, g_szStatXP[i], 31);
			
			g_iStatXP[i-1] = g_iStatXP[i];
			g_iStatXP[i] = g_iExperience[id];
			
			g_iStatLVL[i-1] = g_iStatLVL[i];
			g_iStatLVL[i] = g_iRank[id]+1;
		}
		vault_server_save();
		i++;
	}
	
	task_DisplayHUD(id);
	
	return g_iExperience[id];
}

public cmdSetLevel(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
		
	new szTarget[32];
    	read_argv(1,szTarget,31);
	static player;
	player = cmd_target(id, szTarget, 8);
   	if(!player)
		return PLUGIN_HANDLED ;
	
	new szPlayerName[32];
     	get_user_name(player, szPlayerName, 31);
	
	new szRank[3];
	read_argv(2, szRank, 2);
	
	new iRank;
	iRank = str_to_num(szRank)-1;
	iRank = clamp (iRank, 0, MAX_RANK+1);
	task_SetLevel(player, iRank);
	
	client_print(id,print_console,"[%s] You have set %s's to rank %d", MODNAME2, szPlayerName, iRank+1);
	client_print_color(player, DontChange, "%s An admin has set your rank to ^4%d^1", MODNAME, iRank+1);
	
	new szAdminID[32];
	get_user_authid(id, szAdminID, 31);
	Log("[RANK] Admin: %s changed player: %s rank to %d (%s)", szAdminID, szPlayerName, iRank+1, g_szRankName[iRank]);
	
	return PLUGIN_CONTINUE;
}

public cmdAddExperience(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
		
	new szTarget[32];
    	read_argv(1,szTarget,31);
	static player;
	player = cmd_target(id, szTarget, 8);
   	if(!player)
		return PLUGIN_HANDLED ;
	
	new szPlayerName[32];
     	get_user_name(player, szPlayerName, 31);
	
	new szExperience[32];
	read_argv(2, szExperience, 31);
	
	new iExperience = str_to_num(szExperience);
	task_AddXP(player, iExperience);
	
	client_print(id,print_console,"[%s] You have awarded %s with %d XP", MODNAME2, szPlayerName, iExperience);
	client_print_color(player, DontChange, "%s An admin has awarded you with ^4%d^1XP", MODNAME, iExperience);
	
	new szAdminID[32];
	get_user_authid(id, szAdminID, 31);
	Log("[EXP] Admin: %s awarded player: %s with %d XP", szAdminID, szPlayerName, iExperience);
	
	return PLUGIN_CONTINUE;
}

/**
 * This is mainly just the "proper" way to set a level.  Once the level is set, then
 * the experience is set to that level
 **/
public task_SetLevel(id, iRank)
{
	if (!g_isConnected[id] || g_isBot[id])
		return 0;
		
	if (iRank < 0 || iRank > sizeof g_iRankXP)
		return 0;
	
	g_iRank[id] = iRank;
	g_iExperience[id] = g_iRankXP[iRank];
	
	task_ShowRankHUD(id, iRank);
	task_DisplayHUD(id);
	
	return g_iRank[id];
}

/**
 * Since resetting is equal to level 0, just set them to level 0
 **/
public task_ResetXP(id)
{
	return task_SetLevel(id, 0);
}

public native_get_user_rank(id)
{
	return g_iRank[id]+1;
}

public native_get_user_experience(id)
{
	return g_iExperience[id];
}

public native_get_highest_rank()
{
	return g_iHighestRankID;
}

public ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return HAM_IGNORED;
		
	g_isAlive[id] = true;
	
	/*if (g_iRank[id] == LEVEL_NONE)
	{
		task_GetLevel(id);
	}*/
	
	task_DisplayHUD(id);
	
	return HAM_IGNORED;
}

/*public fw_PlayerPreThink(id)
{
	if (!g_isConnected[id] || g_isBot[id])
		return FMRES_IGNORED;
	
	if (-1 < g_iRank[id] < MAX_RANK-1)
	{	
		static iRank;
		iRank = g_iRank[id];
		
		static iNextRank;
		iNextRank = iRank+1;

		if (g_iExperience[id] >= g_iRankXP[iNextRank])
		{
			g_iRank[id]++;
			task_ShowRankHUD(id, iNextRank);	
			task_DisplayHUD(id);
			
			SaveLevel(id);
		}
	}
	
	return FMRES_IGNORED;
}*/

task_ShowRankHUD(id, iRank)
{
	static szPlayerName[32];
	get_user_name(id,szPlayerName,31);
			
	new szMessage[64]
	formatex(szMessage, 63, "You've been promoted!^n%s", g_szRankName[iRank]);
	
	ff_set_message(id, szMessage, g_szLevelGained, HUD_RANK_R, HUD_RANK_G, HUD_RANK_B);
	
	client_print_color(0, DontChange, "^3%s^1 has ranked up and is now a ^4%s^1", szPlayerName, g_szRankName[iRank]);
	
	ExecuteForward(g_fwRankUp, g_fwDummyResult, id, iRank+1);
}

public hook_StatusValue()
{
	set_msg_block(gmsgStatusText, BLOCK_SET);
}

public setTeam(id)
{
	g_iFriend[id] = read_data(2)
}

public msgTeamInfo(msgid, dest)
{
	if (dest != MSG_ALL && dest != MSG_BROADCAST)
		return;
	
	static id, team[2]
	id = get_msg_arg_int(1)

	get_msg_arg_string(2, team, charsmax(team))
	switch (team[0])
	{
		case 'T' : // TERRORIST
		{
			g_iCurTeam[id] = CS_TEAM_T;
		}
		case 'C' : // CT
		{
			g_iCurTeam[id] = CS_TEAM_CT;
		}
		case 'S' : // SPECTATOR
		{
			g_iCurTeam[id] = CS_TEAM_SPECTATOR;
		}
		default : // UNASSIGNED
		{
			g_iCurTeam[id] = CS_TEAM_UNASSIGNED;
		}
	}
}

public on_ShowStatus(id)
{
	if (g_isBot[id])
		return;
		
	static iTarget;
	iTarget = read_data(2);
	
	static szName[32];
	get_user_name(iTarget, szName, 31);
	
	static iTargetRank;
	iTargetRank = g_iRank[iTarget]+1;
		
	if (g_iFriend[id] == 1)
	{
		set_hudmessage(0, HUD_COLOR_FRIEND, 0, -1.0, HUD_HEIGHT, 1, 0.0, 0.5, 0.01, 0.01);
		ShowSyncHudMsg(id, gHudSyncInfo, "[%d] %s", iTargetRank, szName);
		
		new iTime = ICON_SECONDS*10;
		if (iTime > 0)
			Create_TE_PLAYERATTACHMENT(id, iTarget, 40, g_szSprites[iTargetRank-1], iTime);
	}
	else if (g_iFriend[id] != 1) 
	{
		set_hudmessage(HUD_COLOR_ENEMY, 0, 0, -1.0, HUD_HEIGHT, 1, 0.0, 0.5, 0.01, 0.01);
		ShowSyncHudMsg(id, gHudSyncInfo, "[%d] %s", iTargetRank, szName);
	}
	
	task_DisplayHUD(id);
}

public on_HideStatus(id)
{
	if (g_isBot[id])
		return;
		
	ClearSyncHud(id, gHudSyncInfo);
	
	task_DisplayHUD(id);
}

public cmdSay(id)
{
	if (!is_user_connected(id) || g_isBot[id])
		return PLUGIN_HANDLED;

	new szMessage[32]
	read_args(szMessage, charsmax(szMessage));
	remove_quotes(szMessage);
		
	if(szMessage[0] == '/')
	{
		if (equali(szMessage, "/ranklist") == 1)
		{
			new tempstring[100];
			new motd[2048];
			format(motd,2047,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b></strong></b>")
		
			format(tempstring,99,"Battlefield Mod v%s by Tirant<br><br>", VERSION)
			add(motd,2047,tempstring);
		
			format(tempstring,99,"Rank List:<br>")
			add(motd,2047,tempstring);
		
			for ( new i = 0; i < MAX_RANK; i++)
			{
				format(tempstring,99,"[%d] %s<br>", i+1, g_szRankName[i])
				add(motd,2047,tempstring);
			}
			
			add(motd,2047,"</font></body></html>")

			show_motd(id,motd,"Battlefield: Rank List");
		}
		else if (equali(szMessage, "/ranks") == 1 || equali(szMessage, "/playerlist") == 1)
		{
			new tempstring[100];
			new motd[2048];
			format(motd,2047,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b></strong></b>")
		
			format(tempstring,99,"Battlefield Mod v%s by Tirant<br><br>", VERSION)
			add(motd,2047,tempstring);
		
			format(tempstring,99,"Player List:<br>")
			add(motd,2047,tempstring);
		
			new szPlayerName[32]
			for ( new i = 0; i < g_iMaxPlayers; i++)
			{
				if (!is_user_connected(i) || is_user_bot(i))
					continue;
				
				get_user_name(i, szPlayerName, 31);
				format(tempstring,99,"[%d] %s (%s)<br>", g_iRank[i]+1, szPlayerName, g_szRankName[g_iRank[i]])
				add(motd,2047,tempstring);
			}
			
			add(motd,2047,"</font></body></html>")

			show_motd(id,motd,"Battlefield: Player List");
		}
		else if (equali(szMessage, "/topranks") == 1 || equali(szMessage, "/leaderboard") == 1 || equali(szMessage, "/top10") == 1)
		{
			new tempstring[100];
			new motd[2048];
			format(motd,2047,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b></strong></b>")
		
			format(tempstring,99,"Battlefield Mod v%s by Tirant<br><br>", VERSION)
			add(motd,2047,tempstring);
		
			format(tempstring,99,"Top 10 XP Leaders:<br>")
			add(motd,2047,tempstring);
		
			for ( new i = 9; i > -1; i--)
			{
				format(tempstring,99,"%d. [%d] %s - %d<br>", 10-i, g_iStatLVL[i], g_szStatXP[i], g_iStatXP[i])
				add(motd,2047,tempstring);
			}
			
			add(motd,2047,"</font></body></html>")

			show_motd(id,motd,"Battlefield: Experience Leaderboards");
		}
	}
	return PLUGIN_CONTINUE;
}

public get_load_key(id)
{
	if (id > g_iMaxPlayers)
		id -= XPLOAD_TASK;
		
	if (!g_isConnected[id] || g_isBot[id])
		return;
		
	new szAuthID[35]
	get_user_authid(id, szAuthID, 34);
	if ( equal(szAuthID[9], "PENDING") || szAuthID[0] == '^0' ) 
	{
		set_task(0.5, "get_load_key", id+XPLOAD_TASK);
	}
	else
	{
		format(g_szAuth[id], 34, szAuthID)
		LoadLevel(id)
	}
}

LoadLevel(id)
{
	if (!g_isConnected[id] || g_isBot[id])
		return false;
		
	if ( equal(g_szAuth[id][9], "PENDING") || g_szAuth[id][0] == '^0')
		return false;
	
	new szKey[64];
	new szData[32];

	formatex( szKey , 63 , "%s", g_szAuth[id]);
	formatex( szData , 31, "%i", g_iExperience[id]);
	
	nvault_get(g_Vault, szKey, szData, 31) 
	
	new iExp[32]
	parse(szData, iExp, 31) 
	
	g_iExperience[id] = str_to_num(iExp)
	task_GetLevel(id);
	
	return true;
}

SaveLevel(id)
{ 
	if (equal(g_szAuth[id][9], "PENDING") || g_szAuth[id][0] == '^0' )
		return false;
		
	new szKey[64];
	new szData[32];

	//Base Mod Saves
	formatex( szKey , 63 , "%s", g_szAuth[id]);
	formatex( szData , 31, "%i",  g_iExperience[id]);

	nvault_set( g_Vault , szKey , szData );
	
	return true;
}

public vault_server_save() 
{
    	new vaultkey[64],vaultdata[512]

	new i = -1;
    	formatex(vaultkey,63,"BF-ServerData")
    	formatex(vaultdata,511,"%i %i ^"%s^" %i %i ^"%s^" %i %i ^"%s^" %i %i ^"%s^" %i %i ^"%s^"",g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i]);

	nvault_set(g_Vault,vaultkey,vaultdata)
	
    	formatex(vaultkey,63,"BF-ServerData2")
    	formatex(vaultdata,511,"%i %i ^"%s^" %i %i ^"%s^" %i %i ^"%s^" %i %i ^"%s^" %i %i ^"%s^"",
		g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],
		g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i],
		g_iStatXP[++i], g_iStatLVL[i], g_szStatXP[i]);

	nvault_set(g_Vault,vaultkey,vaultdata)

    	return PLUGIN_CONTINUE;	
}

public vault_server_load()
{	
	new vaultkey[64], vaultdata[512]; 
	new TimeStamp;

	new i = -1;
	new szStatXP[10][8], szStatLVL[10][3];
	
	formatex(vaultkey,63,"BF-ServerData")

    	if(nvault_lookup(g_Vault, vaultkey, vaultdata, sizeof(vaultdata) - 1, TimeStamp ))
    	{	
		parse(vaultdata,
			szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,
			szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,
			szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31);      
	}
	
	formatex(vaultkey,63,"BF-ServerData2")

    	if(nvault_lookup(g_Vault, vaultkey, vaultdata, sizeof(vaultdata) - 1, TimeStamp ))
    	{	
		parse(vaultdata,
			szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,
			szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31,
			szStatXP[++i], 7, szStatLVL[i], 2, g_szStatXP[i],31);      
	}
	
	for (i = 0; i < 10; i++)
	{
		g_iStatXP[i] = str_to_num(szStatXP[i]);
		g_iStatLVL[i] = str_to_num(szStatLVL[i]);
	}
}

/**
 * This is just to check if their current XP is higher then the next
 * level requirement. Also manages the hud as well.
 **/
task_DisplayHUD(id)
{
	if (!g_isAlive[id] || !g_isConnected[id] || g_isBot[id])
		return;
	
	static szHUD[128];
	
	static iRank;
	iRank = g_iRank[id];
	
	static iXPNeeded;
	if (iRank == MAX_RANK-1)
		iXPNeeded = g_iRankXP[iRank];
	else
		iXPNeeded = g_iRankXP[iRank+1];
		
	if (iXPNeeded < 0)
		iXPNeeded = 0;

	formatex(szHUD, charsmax(szHUD), "[%s] %d/%d (%d) %s (%d)", MODNAME2, g_iExperience[id], iXPNeeded, (iXPNeeded-g_iExperience[id]), g_szRankName[iRank], iRank+1);
	
	message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, _, id);
	write_byte(0);
	write_string(szHUD);
	message_end();
}

stock Create_TE_PLAYERATTACHMENT(id, entity, vOffset, iSprite, life)
{

	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id )
	write_byte( TE_PLAYERATTACHMENT )
	write_byte( entity )			// entity
	write_coord( vOffset )			// vertical offset ( attachment origin.z = player origin.z + vertical offset )
	write_short( iSprite )			// model index
	write_short( life )			// (life * 10 )
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

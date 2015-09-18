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

enum (+= 5000)
{
	XPLOAD_TASK = 100000
}

new g_iMaxPlayers
new gmsgStatusText
new gHudSyncInfo
//new bool:g_isFreezeTime = true;

#define SOUND_LEVELUP "firefight/levelup-beta.wav"
#define SOUND_HIGHESTLEVEL "buttons/bell1.wav"

#define MAXPLAYERS 32

new g_iExperience[MAXPLAYERS+1]

#define HUD_LEVEL_RANK 4
#define LEVEL_NONE -1
new g_iRank[MAXPLAYERS+1]
new g_iHighestRankID

new Float:g_fLevelDelay[MAXPLAYERS+1];
#define LEVEL_DELAY 3.5

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
	"Private I","Private II","Private III",
	"Pvt First Class I","Pvt First Class II","Pvt First Class III",
	"Specialist I","Specialist II","Specialist III",
	"Corporal I","Corporal II","Corporal III",
	"Sergeant I","Sergeant II","Sergeant III",
	"Staff Sergeant I","Staff Sergeant II","Staff Sergeant III",
	"Sgt First Class I","Sgt First Class II","Sgt First Class III",
	"Master Sergeant I","Master Sergeant II","Master Sergeant III",
	"First Sergeant I","First Sergeant II","First Sergeant III",
	"Sergeant Major I","Sergeant Major II","Sergeant Major III",
	"Comm. Sgt Major I","Comm. Sgt Major II","Comm. Sgt Major III",
	"2nd Lieutenant I","2nd Lieutenant II","2nd Lieutenant III",
	"1st Lieutenant I","1st Lieutenant II","1st Lieutenant III",
	"Captain I","Captain II","Captain III",
	"Major I","Major II","Major III",
	"Lieutenant Colonel I","Lieutenant Colonel II","Lieutenant Colonel III","Lieutenant Colonel IV",
	"Colonel I","Colonel II","Colonel III","Colonel IV",
	"Brigadier General I","Brigadier General II","Brigadier General III","Brigadier General IV",
	"Major General I","Major General II","Major General III","Major General IV",
	"Lieutenant General I","Lieutenant General II","Lieutenant General III","Lieutenant General IV",
	"General I","General II","General III","General IV",
	"Commander"
};

new const g_iRankXP[sizeof g_szRankName] =
{
	0,500,1700,
	3600,6200,9500,
	13500,18200,23600,
	29700,36500,44300,
	53100,62900,73700,
	85500,96300,112100,
	126900,142700,159500,
	177300,196100,215900,
	236700,258500,281300,
	305100,329900,355700,
	382700,410900,440300,
	470900,502700,535700,
	569900,605300,641900,
	679700,718700,758900,
	800300,842900,886700,
	931700,977900,1025300,1073900,
	1123700,1175000,1227800,1282100,
	1337900,1395200,1454000,1514300,
	1576100,1639400,1704200,1770500,
	1838300,1906700,1978400,2050700,
	2124500,2199800,2276800,2354900,
	2434700
};

#define MAX_RANK (sizeof g_iRankXP)

//Forwards
new g_fwDummyResult

new g_fwRankUp, g_fwRewardXP

//nVault
new g_szAuth[MAXPLAYERS+1][35];
new g_Vault

public plugin_precache()
{
	precache_sound(SOUND_LEVELUP);
	precache_sound(SOUND_HIGHESTLEVEL);
}

public plugin_cfg()
{
	g_Vault = nvault_open( "ff-experience" );

	if ( g_Vault == INVALID_HANDLE )
		set_fail_state( "Error opening Battlefield nVault, file does not exist!" );	
}

public plugin_init()
{
	register_plugin("Experience", VERSION, "Tirant");
	
	csdm_set_intromsg(0);
	formatex(g_szModName, charsmax(g_szModName), "%s %s", MODNAME2, VERSION)
	
	register_concmd("ff_setlevel",	"cmdSetLevel",ADMIN_CVAR,"<name> <rank>")
	register_concmd("ff_addxp",	"cmdAddExperience",ADMIN_CVAR,"<name> <rank>")
	
	register_event("StatusValue", "setTeam", "be", "1=1");
	register_event("StatusValue", "on_ShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "on_HideStatus", "be", "1=1", "2=0");
	
	//register_event("HLTV", "ev_RoundStart", "a", "1=0", "2=0")
	//register_logevent("logevent_round_start",2, 	"1=Round_Start")
	//register_logevent("logevent_round_end", 2, 	"1=Round_End")
	
	register_message(get_user_msgid("TeamInfo"), "msgTeamInfo");
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
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
	
	nvault_close(g_Vault);
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, g_szModName)
	return FMRES_SUPERCEDE;
}

/*public ev_RoundStart()
{
	g_isFreezeTime = true;
}

public logevent_round_start()
{
	g_isFreezeTime = false;
}

public logevent_round_end()
{
	g_isFreezeTime = true;
}*/

public client_putinserver(id)
{
	task_ResetVars(id);
	
	g_isConnected[id] = true;
	if (is_user_bot(id))
		g_isBot[id] = true;
		
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
			client_cmd(0, "spk %s", SOUND_HIGHESTLEVEL);
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
	
	new i = 0;

	if (g_iExperience[id] > g_iRankXP[sizeof (g_iRankXP) / 2])
		i = sizeof (g_iRankXP) / 2
	
	while (g_iExperience[id] > g_iRankXP[i] && i < MAX_RANK)
	{
		i++;
	}
	i--;
	
	i = clamp (i, 0, MAX_RANK-1);
	g_iRank[id] = i;
	
	if (g_iExperience[id] > g_iExperience[g_iHighestRankID])
	{
		g_iHighestRankID = id;
		
		client_cmd(0, "spk %s", SOUND_HIGHESTLEVEL);
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
	
	client_print(id,print_console,"[%s] You have set %s's to rank %d", MODNAME, szPlayerName, iRank+1);
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
	
	client_print(id,print_console,"[%s] You have awarded %s with %d XP", MODNAME, szPlayerName, iExperience);
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

/**
 * I could have it run the same loop as above, but it's easier to just
 * return a value that is already cached
 **/
public native_get_user_rank(id)
{
	return g_iRank[id]+1;
}

public native_get_user_experience(id)
{
	return g_iExperience[id];
}

public ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return HAM_IGNORED;
		
	//server_cmd("echo Player has spawned! firefight_exp1");
		
	g_isAlive[id] = true;
	
	/*if (g_iRank[id] == LEVEL_NONE)
	{
		task_GetLevel(id);
	}*/
		
	task_DisplayHUD(id);
	
	return HAM_IGNORED;
}

public fw_PlayerPreThink(id)
{
	if (!g_isConnected[id] || g_isBot[id])
		return FMRES_IGNORED;
	
	static Float:fGameTime;
	fGameTime = get_gametime();
	
	if (-1 < g_iRank[id] < MAX_RANK-1 && g_fLevelDelay[id] < fGameTime)
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
			g_fLevelDelay[id] = fGameTime + LEVEL_DELAY;
			
			g_iRank[id]++;
			task_ShowRankHUD(id, iNextRank);	
			task_DisplayHUD(id);
			
			SaveLevel(id);
		}
	}
	
	return FMRES_IGNORED;
}

task_ShowRankHUD(id, iRank)
{
	static szPlayerName[32];
	get_user_name(id,szPlayerName,31);
			
	set_hudmessage(0, 240, 120, -1.0, 0.30, 2, 5.0, 4.0, 0.02, 0.02, HUD_LEVEL_RANK);
	show_hudmessage(id, "You've been promoted!^n%s", g_szRankName[iRank]);
	client_cmd(id, "spk %s", SOUND_LEVELUP);
			
	client_print_color(0, DontChange, "^3%s^1 has ranked up and is now a ^4%s^1", szPlayerName, g_szRankName[iRank]);
	
	ExecuteForward(g_fwRankUp, g_fwDummyResult, id, iRank);
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

/**
 * This is just to check if their current XP is higher then the next
 * level requirement. Also manages the hud as well.
 **/
task_DisplayHUD(id)
{
	if (!g_isAlive[id] || !g_isConnected[id] || g_isBot[id])
		return;
	
	static szHUD[64];
	
	static iRank;
	iRank = g_iRank[id];
	
	static iXPNeeded;
	if (iRank == MAX_RANK-1)
		iXPNeeded = g_iRankXP[iRank];
	else
		iXPNeeded = g_iRankXP[iRank+1];
		
	iXPNeeded = clamp(iXPNeeded, 0, 1000000)

	formatex(szHUD, charsmax(szHUD), "[%s] %d/%d (%d) %s (%d)", MODNAME2, g_iExperience[id], iXPNeeded, (iXPNeeded-g_iExperience[id]), g_szRankName[iRank], iRank+1);
	
	message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, _, id);
	write_byte(0);
	write_string(szHUD);
	message_end();
}

/**
 * This is the log that keeps track of any admin rank/xp adjustments
 **/
Log(const message_fmt[], any:...)
{
	static message[256];
	vformat(message, sizeof(message) - 1, message_fmt, 2);
	
	static filename[96];
	static dir[64];
	if( !dir[0] )
	{
		get_basedir(dir, sizeof(dir) - 1);
		add(dir, sizeof(dir) - 1, "/logs/");
	}
	
	format_time(filename, sizeof(filename) - 1, "%m-%d-%Y");
	format(filename, sizeof(filename) - 1, "%s/%s_%s.log", dir, MODNAME2, filename);
	
	log_to_file(filename, "%s", message);
}

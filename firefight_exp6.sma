//#pragma semicolon 1

#define DEBUG_MODE

#include <amxmodx>
#include <amxmisc>
#include <firefight>
#include <colorchat>
#include <nvault>
#include <csdm>
#include <hamsandwich>

#define null -1
#define RANK_MAX (sizeof g_szRankName)

#define flag_get(%1,%2)		(g_PlayerInfo[%1] &   (1 << (%2 & 31)))
#define flag_set(%1,%2)		(g_PlayerInfo[%1] |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)	(g_PlayerInfo[%1] &= ~(1 << (%2 & 31)))

static const Plugin [] = "Experience";
static const Version[] = "0.0.6";
static const Author [] = "Tirant";

static const g_szLevelGained	[] = "firefight/levelup-beta.wav";
static const g_szRankingOfficer	[] = "buttons/bell1.wav";

enum (+= 5000) {
	TASK_LOADXP = 100000
};

static const g_szRankName[][] = { 
	"Rank 1",
	"Rank 2",
	"Rank 3",
	"Rank 4",
	"Rank 5",
	"Rank 6",
	"Rank 7",
	"Rank 8",
	"Rank 9",
	"Rank 10"
};

static const g_iRankMax = RANK_MAX;

static const g_iRankXP[RANK_MAX-1] = {
	100,
	200,
	300,
	400,
	500,
	600,
	700,
	800,
	900
};

enum _:eRankInfo {
	Exp,
	Rank
};
static g_iRankInfo[eRankInfo][MAX_PLAYERS+1];

enum _:ePlayerInfo {
	g_bIsConnected,
	g_bIsAlive,
	g_bIsBot
};
static g_PlayerInfo[ePlayerInfo];

static g_iHighestRankID;
static g_szAuth[MAX_PLAYERS+1][32];

enum eForwards {
	fwDummy,
	fwRankUp,
	fwRewardXP
};
static g_Forwards[eForwards];

static g_iMaxPlayers;
static g_msgStatusText;
static g_HudSyncInfo;
static g_Vault;

static const g_iHUDRank[3] = { 000, 240, 120 };

#define HUD_COLOR_FRIEND 255
#define HUD_COLOR_ENEMY	 255
#define HUD_HEIGHT	 0.35	
static g_iFriend[MAX_PLAYERS+1];

public plugin_precache() {
	precache_sound(g_szLevelGained);
	precache_sound(g_szRankingOfficer);
}

public plugin_cfg() {
	g_Vault = nvault_open("ff-experience");
	if (g_Vault == INVALID_HANDLE) {
		set_fail_state( "Error opening experience nVault, file does not exist!" );
	}
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	csdm_set_intromsg(0);

	register_concmd("ff_setlevel",	"cmdSetLevel", FLAG_EXP, "<name> <rank>");
	register_concmd("ff_setrank",	"cmdSetLevel", FLAG_EXP, "<name> <rank>");
	register_concmd("ff_addxp",	"cmdAddExperience", FLAG_EXP, "<name> <experience>");
	
	g_iMaxPlayers = get_maxplayers();
	g_msgStatusText = get_user_msgid("StatusText");
	g_HudSyncInfo = CreateHudSyncObj();

	static StatusValue[] = "StatusValue";
	register_event(StatusValue, "ev_setTeam", 	"be", "1=1");
	register_event(StatusValue, "ev_showStatus", 	"be", "1=2", "2!0");
	register_event(StatusValue, "ev_hideStatus", 	"be", "1=1", "2=0");
		
	register_message(get_user_msgid(StatusValue), "msgStatusValue");
	
	g_Forwards[fwRankUp]	 = CreateMultiForward("ff_player_rankup", ET_IGNORE, FP_CELL, FP_CELL);
	g_Forwards[fwRewardXP]	 = CreateMultiForward("ff_player_gainxp", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_natives() {
	register_native("ff_reset_user_rank",	"resetLevel", 1);
	
	register_native("ff_get_rankofficer",	"_get_highest_rank", 1);
	
	register_native("ff_get_user_rank",	"_get_user_rank", 1);
	register_native("ff_set_user_rank",	"setLevel", 1);
	
	register_native("ff_get_user_xp",	"_get_user_experience", 1);
	register_native("ff_add_user_xp",	"addExperience", 1);
}

public client_connect(id) {
	resetPlayerInfo(id);
	flag_set(g_bIsConnected,id);
	if (is_user_bot(id)) {
		flag_set(g_bIsBot,id);
		getLevelFromExperience(id);
	} else {
		getLoadKey(id);
	}
}

public client_disconnect(id) {
	saveLevel(id);
	resetPlayerInfo(id);
}

resetPlayerInfo(id) {
	for (new i; i < ePlayerInfo; i++) {
		flag_unset(i,id);
	}
	
	for (new i; i < eRankInfo; i++) {
		g_iRankInfo[i][id] = null;
	}
	
	g_szAuth[id][0] = '^0';
}

public csdm_PostSpawn(id) {
	if (!is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}
	
	flag_set(g_bIsAlive,id);
	displayHUD(id);
	return PLUGIN_CONTINUE;
}

public csdm_PostDeath(killer, victim, headshot, const weapon[]) {
	flag_unset(g_bIsAlive,victim);
}

getLevelFromExperience(id) {
	if (!flag_get(g_bIsConnected,id)) {
		return;
	} else if (flag_get(g_bIsBot,id)) {
		g_iRankInfo[Rank][id] = 0;
		g_iRankInfo[Exp][id] = 0;
		return;
	}
	
	new lowBounds, upBounds = g_iRankMax-1, curRank;
	while (lowBounds <= upBounds && curRank < g_iRankMax && !(g_iRankXP[curRank] <= g_iRankInfo[Exp][id] < g_iRankXP[curRank+1])) {
		#if defined DEBUG_MODE
		server_print("XP: %d, iCached: %d, iMin: %d, iMax = %d, g_iRankXP: %d, g_iRankXP+1: %d", g_iRankInfo[Exp][id], curRank, lowBounds, upBounds, g_iRankXP[curRank], g_iRankXP[curRank+1]);
		#endif
		curRank = (lowBounds + upBounds) / 2;
		if (g_iRankInfo[Exp][id] > g_iRankXP[curRank]) {
			lowBounds = curRank + 1;
		} else {
			upBounds = curRank - 1;
		}
	}
	
	if (g_iRankXP[0] <= g_iRankInfo[Exp][id] && curRank < (g_iRankMax-1)) {
		curRank++;
	}
	
	#if defined DEBUG_MODE
	server_print("Level set to: %d (%d); %d/%d", curRank, curRank+1, g_iRankInfo[Exp][id], g_iRankXP[clamp(curRank, 0, g_iRankMax-2)]);
	#endif

	g_iRankInfo[Rank][id] = curRank;
	if (g_iRankInfo[Exp][id] > g_iRankInfo[Exp][g_iHighestRankID]) {
		static szPlayerName[32];
		g_iHighestRankID = id;
		client_cmd(0, "spk %s", g_szRankingOfficer);
		get_user_name(id, szPlayerName, 31);
		client_print_color(0, DontChange, "%s ^4%s ^3is now the new highest ranking officer in the server at ^1%s", MODNAME, szPlayerName, g_szRankName[curRank]);
	}
	
	return;
}

public addExperience(id, iExperience) {
	if (!flag_get(g_bIsConnected,id)) {
		return -1;
	} else if (flag_get(g_bIsBot,id)) {
		return 0;
	} else if (g_iRankInfo[Exp][id] == null || g_iRankInfo[Rank][id] == null) {
		return -1;
	} else if (iExperience < 0) {
		return 0;
	}
	
	ExecuteForward(g_Forwards[fwRewardXP], g_Forwards[fwDummy], id, iExperience, g_iRankInfo[Exp][id], g_iRankInfo[Exp][id]+iExperience);
	
	g_iRankInfo[Exp][id] = clamp(iExperience+g_iRankInfo[Exp][id], 0, g_iRankXP[g_iRankMax-2]);
	
	if (g_iRankInfo[Rank][id] < g_iRankMax-1) {
		new iRank = g_iRankInfo[Rank][id];
		if (g_iRankInfo[Exp][id] >= g_iRankXP[iRank]) {
			g_iRankInfo[Exp][id]++;
			showRankupHUD(id, iRank+1);
			saveLevel(id);
		}
	}
	
	displayHUD(id);
	return iExperience;
}

public setLevel(id, iRank) {
	if (!flag_get(g_bIsConnected,id) || flag_get(g_bIsBot,id)) {
		return 0;
	} else if (iRank < 0 || iRank > g_iRankMax) {
		return 0;
	}
	
	g_iRankInfo[Rank][id] = iRank
	if (iRank-1 < 0) {
		g_iRankInfo[Exp][id] = 0;
	} else {
		g_iRankInfo[Exp][id] = g_iRankXP[iRank-1];
	}
	
	showRankupHUD(id, iRank);
	displayHUD(id);
	return iRank;
}

public resetLevel(id) {
	return setLevel(id, 0);
}

showRankupHUD(id, iRank) {
	static szPlayerName[32], szMessage[64];
	formatex(szMessage, 63, "You've been promoted!^n%s", g_szRankName[iRank]);
	ff_set_message(id, szMessage, g_szLevelGained, g_iHUDRank[0], g_iHUDRank[1], g_iHUDRank[2]);

	get_user_name(id, szPlayerName, 31);
	client_print_color(0, DontChange, "^3%s^1 has ranked up and is now a ^4%s^1", szPlayerName, g_szRankName[iRank]);

	ExecuteForward(g_Forwards[fwRankUp], g_Forwards[fwDummy], id, iRank+1);
}

displayHUD(id) {
	if (!flag_get(g_bIsAlive,id) || flag_get(g_bIsBot,id)) {
		return;
	}

	static szHUD[128], iNextRankExp, iRank;
	iRank = g_iRankInfo[Rank][id];
	iNextRankExp = g_iRankXP[clamp(iRank, 0, g_iRankMax-2)];
	formatex(szHUD, 127, "[%s] %d/%d (%d) %s (%d)", MODNAME2, g_iRankInfo[Exp][id], iNextRankExp, clamp(iNextRankExp-g_iRankInfo[Exp][id], 0), g_szRankName[iRank], iRank+1);
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgStatusText, _, id); {
	write_byte(0);
	write_string(szHUD);
	} message_end();
}

public msgStatusValue() {
	set_msg_block(g_msgStatusText, BLOCK_SET);
}

public ev_setTeam(id) {
	g_iFriend[id] = read_data(2);
}

public ev_showStatus(id) {
	if (!flag_get(g_bIsAlive,id) || flag_get(g_bIsBot, id)) {
		return;
	}
		
	static iTarget, szName[32], iTargetRank;
	iTarget = read_data(2);
	iTargetRank = g_iRankInfo[Rank][iTarget]+1;
	get_user_name(iTarget, szName, 31);
	if (g_iFriend[id] == 1) {
		set_hudmessage(0, HUD_COLOR_FRIEND, 0, -1.0, HUD_HEIGHT, 1, 0.0, 0.5, 0.0, 0.0);
		ShowSyncHudMsg(id, g_HudSyncInfo, "[%d] %s", iTargetRank, szName);
		
		/*static iTime;
		iTime = ICON_SECONDS*10;
		if (iTime > 0) {
			createPlayerAttachment(id, iTarget, 40, g_szSprites[iTargetRank-1], iTime);
		}*/
	} else {
		set_hudmessage(HUD_COLOR_ENEMY, 0, 0, -1.0, HUD_HEIGHT, 1, 0.0, 0.5, 0.0, 0.0);
		ShowSyncHudMsg(id, g_HudSyncInfo, "[%d] %s", iTargetRank, szName);
	}
	
	displayHUD(id);
}

public ev_hideStatus(id) {
	if (!flag_get(g_bIsAlive,id) || flag_get(g_bIsBot, id)) {
		return;
	}
		
	ClearSyncHud(id, g_HudSyncInfo);
	displayHUD(id);
}

public cmdSetLevel(id, level, cid) {
	if(!cmd_access(id, level, cid, 3)) {
		return PLUGIN_HANDLED;
	}
		
	static szTarget[32], player;
    	read_argv(1, szTarget, 31);
	player = cmd_target(id, szTarget, 8);
   	if(!player) {
		client_print(id, print_console, "[%s] Invalid player", MODNAME2);
		return PLUGIN_CONTINUE;
	}
	
	static szPlayerName[32], szRank[32], iRank;
	get_user_name(player, szPlayerName, 31);
	read_argv(2, szRank, 31);
	if (!is_str_num(szRank)) {
		client_print(id, print_console, "[%s] Invalid rank entered", MODNAME2);
		return PLUGIN_CONTINUE;
	}
	
	iRank = clamp(str_to_num(szRank)-1, 0, g_iRankMax-1);
	setLevel(player, iRank);
	client_print(id, print_console, "[%s] You have set %s's to rank %d", MODNAME2, szPlayerName, iRank+1);
	client_print_color(player, DontChange, "%s An admin has set your rank to ^4%d^1", MODNAME, iRank+1);
	get_user_authid(id, szRank, 31);
	Log("[RANK] Admin: %s changed player: %s rank to %d (%s)", szRank, szPlayerName, iRank+1, g_szRankName[iRank]);
	return PLUGIN_CONTINUE;
}

public cmdAddExperience(id, level, cid) {
	if(!cmd_access(id, level, cid, 3)) {
		return PLUGIN_HANDLED;
	}
		
	static szTarget[32], player;
    	read_argv(1,szTarget,31);
	player = cmd_target(id, szTarget, 8);
   	if(!player) {
		client_print(id, print_console, "[%s] Invalid player", MODNAME2);
		return PLUGIN_CONTINUE;
	}
	
	static szPlayerName[32], szExperience[32], iExperience;
     	get_user_name(player, szPlayerName, 31);
	read_argv(2, szExperience, 31);
	if (!is_str_num(szExperience)) {
		client_print(id, print_console, "[%s] Invalid experience amount entered", MODNAME2);
		return PLUGIN_CONTINUE;
	}
	
	iExperience = str_to_num(szExperience);
	addExperience(player, iExperience);
	client_print(id,print_console,"[%s] You have awarded %s with %d XP", MODNAME2, szPlayerName, iExperience);
	client_print_color(player, DontChange, "%s An admin has awarded you with ^4%d^1XP", MODNAME, iExperience);
	get_user_authid(id, szExperience, 31);
	Log("[EXP] Admin: %s awarded player: %s with %d XP", szExperience, szPlayerName, iExperience);
	return PLUGIN_CONTINUE;
}

public getLoadKey(id) {
	if (id > g_iMaxPlayers) {
		id -= TASK_LOADXP;
	}
	
	if (!flag_get(g_bIsConnected,id) || flag_get(g_bIsBot,id)) {
		return;
	}
	
	static szAuth[35];
	get_user_authid(id, szAuth, 34);
	if (equal(szAuth[9], "PENDING") || szAuth[0] == '^0') {
		set_task(0.5, "getLoadKey", id+TASK_LOADXP);
	} else {
		copy(g_szAuth[id], 34, szAuth);
		loadLevel(id);
	}
}

bool:loadLevel(id) {
	if (!flag_get(g_bIsConnected,id) || flag_get(g_bIsBot,id)) {
		return false;
	} else if (equal(g_szAuth[id][9], "PENDING") || g_szAuth[id][0] == '^0') {
		return false;
	}
	
	static szKey[64], szData[32];
	formatex(szKey, 63, "%s", g_szAuth[id]);
	formatex(szData, 31, "%d", g_iRankInfo[Exp][id]);
	nvault_get(g_Vault, szKey, szData, 31) 
	
	static szExp[32];
	parse(szData, szExp, 31);
	
	g_iRankInfo[Exp][id] = str_to_num(szExp);
	getLevelFromExperience(id);
	
	return true;
}

bool:saveLevel(id) {
	if (!flag_get(g_bIsConnected,id) || flag_get(g_bIsBot,id)) {
		return false;
	} else if (equal(g_szAuth[id][9], "PENDING") || g_szAuth[id][0] == '^0') {
		return false;
	}
		
	static szKey[64], szData[32];
	formatex(szKey, 63, "%s", g_szAuth[id]);
	formatex(szData, 31, "%d",  g_iRankInfo[Exp][id]);
	nvault_set(g_Vault, szKey, szData);
	
	return true;
}

stock createPlayerAttachment(id, entity, vOffset, iSprite, life) {
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id); {
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(entity);
	write_coord(vOffset);
	write_short(iSprite);
	write_short(life);
	} message_end();
}

public _get_user_rank(id) {
	return g_iRankInfo[Rank][id]+1;
}

public _get_user_experience(id) {
	return g_iRankInfo[Exp][id];
}

public _get_highest_rank() {
	return g_iHighestRankID;
}

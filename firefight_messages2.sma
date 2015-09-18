#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <firefight>

#define flag_get(%1,%2)		(%1 &   (1 << (%2 & 31)))
#define flag_set(%1,%2)		(%1 |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)	(%1 &= ~(1 << (%2 & 31)))

static const Plugin [] = "Messages";
static const Version[] = "0.0.2";
static const Author [] = "Tirant";

#define MESSAGE_MAX 10
#define MESSAGE_NONE -1
#define MESSAGE_DELAY 2.0

enum _:eMessageInfo {
	MB_isMedal = 0,
	MB_iRed,
	MB_iGreen,
	MB_iBlue,
	MB_szMessage[64],
	MB_szSound[64]
};
static g_Messages[MAX_PLAYERS+1][MESSAGE_MAX][eMessageInfo];
static Float:g_fMessageDelay[MAX_PLAYERS+1];
static g_bIsConnected;
static g_bIsBot;

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
}

public plugin_natives() {
	register_native("ff_set_message", "native_set_message", 1);
}

public client_connect(id) {
	resetPlayerInfo(id);
	flag_set(g_bIsConnected,id);
	if (is_user_bot(id)) {
		flag_set(g_bIsBot,id);
	}
}

public client_disconnect(id) {
	resetPlayerInfo(id);
}

resetPlayerInfo(id) {
	flag_unset(g_bIsConnected,id);
	flag_unset(g_bIsBot,id);
	for (new i = 0; i < MESSAGE_MAX; i++) {
		g_Messages[id][i][MB_isMedal] = -1;
	}
}

public fw_PlayerPreThink(id) {
	if (!flag_get(g_bIsConnected,id) || flag_get(g_bIsBot,id)) {
		return FMRES_IGNORED;
	}
		
	static Float:fGameTime;
	fGameTime = get_gametime();
	
	if (g_fMessageDelay[id] < fGameTime) {
		for (new i = 0; i < MESSAGE_MAX; i++) {
			if (g_Messages[id][i][MB_isMedal] > MESSAGE_NONE) {
				g_fMessageDelay[id] = fGameTime + MESSAGE_DELAY;
				g_Messages[id][i][MB_isMedal] = MESSAGE_NONE;
				set_hudmessage(g_Messages[id][i][MB_iRed], g_Messages[id][i][MB_iGreen], g_Messages[id][i][MB_iBlue], -1.0, 0.40, 0, 0.0, 2.5, 0.0, 0.0, HUD_LEVEL_RANK);
				show_hudmessage(id, g_Messages[id][i][MB_szMessage]);
				if (!equal(g_Messages[id][i][MB_szSound], "") && g_Messages[id][i][MB_szSound][0] != '^0') {
					client_cmd(id, "spk %s", g_Messages[id][i][MB_szSound]);
				}
				
				break;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public native_set_message(id, const szMessage[], const szSound[], iRed, iGreen, iBlue) {
	if (!flag_get(g_bIsConnected,id) || flag_get(g_bIsBot,id)) {
		return -1;
	}
	
	param_convert(2);
	param_convert(3);
	for (new i; i <= MESSAGE_MAX; i++) {
		if (i == MESSAGE_MAX) {
			return -1;
		} else if (g_Messages[id][i][MB_isMedal] <= MESSAGE_NONE) {
			g_Messages[id][i][MB_isMedal] = 1;
			g_Messages[id][i][MB_iRed] = iRed;
			g_Messages[id][i][MB_iGreen] = iGreen;
			g_Messages[id][i][MB_iBlue] = iBlue;
			formatex(g_Messages[id][i][MB_szMessage], 63, szMessage);
			formatex(g_Messages[id][i][MB_szSound], 63, szSound);
			return i;
		}
	}
	
	return -1;
}

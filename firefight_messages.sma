#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <firefight>

#define MEDALBOX_MAX 10
#define MEDALBOX_NONE -1

#define MEDALBOX_DELAY 2.0
new Float:g_fMedalBoxDelay[MAXPLAYERS+1];

enum
{
	MB_isMedal = 0,
	MB_iRed,
	MB_iGreen,
	MB_iBlue
}

#define TOTAL_INT_TYPES 4
new g_iMedalInt[MAXPLAYERS+1][MEDALBOX_MAX][TOTAL_INT_TYPES];

#define MAX_LENGTHFILE 64
new g_szMedalMsg[MAXPLAYERS+1][MEDALBOX_MAX][MAX_LENGTHFILE];
new g_szMedalSnd[MAXPLAYERS+1][MEDALBOX_MAX][MAX_LENGTHFILE];

new bool:g_isConnected[MAXPLAYERS+1]

public plugin_init()
{
	register_plugin("Messenger", VERSION, "Tirant")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
}

public plugin_natives()
{
	register_native("ff_set_message", "native_set_message", 1);
}

public client_putinserver(id)
{
	g_isConnected[id] = true
	
	for (new i = 0; i < MEDALBOX_MAX; i++)
		g_iMedalInt[id][i][MB_isMedal] = -1;
}

public client_disconnect(id)
{
	g_isConnected[id] = false

	for (new i = 0; i < MEDALBOX_MAX; i++)
		g_iMedalInt[id][i][MB_isMedal] = -1;
}

public fw_PlayerPreThink(id)
{
	if (!g_isConnected[id])
		return FMRES_IGNORED;
		
	static Float:fGameTime
	fGameTime = get_gametime()
	
	if (g_fMedalBoxDelay[id] < fGameTime)
	{	
		for (new i = 0; i < MEDALBOX_MAX; i++)
		{
			if (g_iMedalInt[id][i][MB_isMedal] > MEDALBOX_NONE)
			{	
				g_fMedalBoxDelay[id] = fGameTime + MEDALBOX_DELAY;

				g_iMedalInt[id][i][MB_isMedal] = MEDALBOX_NONE;
				
				//Reward medal...
				set_hudmessage(g_iMedalInt[id][i][MB_iRed], g_iMedalInt[id][i][MB_iGreen], g_iMedalInt[id][i][MB_iBlue], -1.0, 0.40, 0, 0.0, 2.5, 0.02, 0.02, HUD_LEVEL_RANK);
				show_hudmessage(id, g_szMedalMsg[id][i]);
				
				if (!equal(g_szMedalSnd[id][i], ""))
					client_cmd(id, "spk %s", g_szMedalSnd[id][i]);
				
				break;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public native_set_message(id, const szMessage[], const szSound[], iRed, iGreen, iBlue)
{
	if (!g_isConnected[id] || is_user_bot(id))
		return -1;
	
	param_convert(2);
	param_convert(3);
	
	/*
	 * It will loop through all slots, if it fails to find a slot upon reaching the ceiling
	 * of the loop, then the loop will terminate and return the failure of -1.
	 */
	for ( new i = 0; i <= MEDALBOX_MAX; i++)
	{
		if (i == MEDALBOX_MAX)
		{
			return -1;
			//break;
		}
		else if (g_iMedalInt[id][i][MB_isMedal] <= MEDALBOX_NONE)
		{
			g_iMedalInt[id][i][MB_isMedal] = 1;
			
			g_iMedalInt[id][i][MB_iRed] = iRed;
			g_iMedalInt[id][i][MB_iGreen] = iGreen;
			g_iMedalInt[id][i][MB_iBlue] = iBlue;
			
			format(g_szMedalMsg[id][i], MAX_LENGTHFILE - 1, szMessage);
			format(g_szMedalSnd[id][i], MAX_LENGTHFILE - 1, szSound);
			
			return i;
			//break;
		}
	}
	
	return -1;
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

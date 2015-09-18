#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <firefight>

/*
 * Okay, so, register the medal using the native, they register the reward sound and the xp reward
 * Should I add custom hud colors as well (ie, for registering badges/leveling and killbonuses?
 * 
 * ff_register_message(id, messagetask, szMessage[], iXPReward)
 * @param id		Player that the message is registering to
 * @param messagetask	Like the set_task, except medal-specific, might be useful in the forwarded event
 * @param szMessage[]	String formatted message header
 * @param iXPReward	Integer value to be rewarded (this isn't adding it actually, its jus the message delay)
 * 
 * @param iMode		Whether its a levelup hud, or whatever
 * @param iColor_R	Color if its custom
 * @param iColor_G	Color if its custom
 * @param iColor_B	Color if its custom
 * 
 * Should I 
 * 
 */

new g_iMaxPlayers

#define MAXPLAYERS 32

#define MEDALBOX_MAX 8
#define MEDALBOX_NONE -1
new g_iMedalBox[MAXPLAYERS+1][MEDALBOX_MAX];
new g_szMedalName[MAXPLAYERS+1][MEDALBOX_MAX][];
new g_iMedalReward[MAXPLAYERS+1][MEDALBOX_MAX];

#define MEDALBOX_DELAY 1.5
new Float:g_fMedalBoxDelay[MAXPLAYERS+1]

/*static const g_szRewardSound[][] = 
{
	"",
	"",
	""
}*/

new bool:g_isConnected[MAXPLAYERS+1]

public plugin_init()
{
	register_plugin("Message Notifier", VERSION, "Tirant")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	
	g_iMaxPlayers = get_maxplayers()
	
	for (new i = 0; i < g_iMaxPlayers; i++)
		arrayset(g_iMedalBox[i], MEDALBOX_NONE, MEDALBOX_MAX)
}

public client_putinserver(id)
{
	g_isConnected[id] = true
}

public client_disconnect(id)
{
	g_isConnected[id] = false
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
			if (g_iMedalBox[id][i] > MEDALBOX_NONE)
			{	
				g_fMedalBoxDelay[id] = fGameTime + MEDALBOX_DELAY
				
				new iMedal = g_iMedalBox[id][i]
				g_iMedalBox[id][i] = MEDALBOX_NONE
				
				//Reward medal...
				
				break;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public task_SetMedalSlot(id, iMedal)
{
	if (iMedal <= MEDALBOX_NONE)
		return 0;

	for ( new i = 0; i < MEDALBOX_MAX; i++)
	{
		if (g_iMedalBox[id][i] <= MEDALBOX_NONE)
		{
			g_iMedalBox[id][i] = iMedal
			break;
		}
	}
	
	return 1;
}

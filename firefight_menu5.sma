#include <amxmodx>
#include <amxmisc>
#include <firefight>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <csx>
#include <cstrike>
//#include <fun>
#include <colorchat>

enum (+= 5000)
{
	TASK_WEAPONS = 1000000
}

#define MAXPLAYERS 32

new g_iMaxPlayers;
//new bool:g_isFreezeTime = false;

new g_iCurWeapon[MAXPLAYERS+1];
new g_iWeaponEnt[MAXPLAYERS+1];

new bool:g_isConnected[MAXPLAYERS+1];
new bool:g_isAlive[MAXPLAYERS+1];
new bool:g_isBot[MAXPLAYERS+1];
new bool:g_isGunFiring[MAXPLAYERS+1];

new const g_szWeaponEvents[][] = 
{ 
	"events/awp.sc",
	"events/g3sg1.sc",
	"events/ak47.sc",
	"events/scout.sc",
	"events/m249.sc",
	"events/m4a1.sc",
	"events/sg552.sc",
	"events/aug.sc",
	"events/sg550.sc",
	"events/m3.sc",
	"events/xm1014.sc",
	"events/mac10.sc",
	"events/ump45.sc",
	"events/p90.sc",
	"events/mp5n.sc",
	"events/tmp.sc",
	"events/galil.sc",
	"events/famas.sc",
	"events/usp.sc",
	"events/fiveseven.sc",
	"events/deagle.sc",
	"events/p228.sc",
	"events/glock18.sc",
	"events/elite_left.sc",
	"events/elite_right.sc"
}

new g_iMenuTier[MAXPLAYERS+1];
new g_iPlayerTier[MAXPLAYERS+1];
new g_iPlayerClass[MAXPLAYERS+1];

enum
{
	CLASS_TIER_1 = 0,
	CLASS_TIER_2,
	CLASS_TIER_3,
	CLASS_TIER_4
}

static const g_szTierNames[][] =
{
	"Alpha Tier",
	"Bravo Tier",
	"Charlie Tier",
	"Delta Tier"
}

static g_iTierCost[] =
{
	0,
	1000,
	2000,
	3000
}

static const g_szCommands[][] =
{
	"/class",
	"/guns"
}

new g_iMenuOptions[MAXPLAYERS+1][8]
new g_iMenuOffset[MAXPLAYERS+1]
new bool:g_isMenuLooping[MAXPLAYERS+1]
new bool:g_isFirstMenu[MAXPLAYERS+1]

new bool:g_hasChosen[MAXPLAYERS+1];
new g_iMenuStore[MAXPLAYERS+1][2];

#define KEYS_GENERIC (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

new g_fwPrecache;
new g_evGunFired;

#define MAX_LENGTH 16
#define MAX_LENGTHFILE 32
#define MAX_CLASSES 32
#define MAX_TIERS 4

new g_iClasses;
new g_szClassName[MAX_CLASSES][MAX_LENGTH];
new g_szWeaponName[MAX_CLASSES][MAX_TIERS][MAX_LENGTH];
new g_szViewModel[MAX_CLASSES][MAX_TIERS][MAX_LENGTHFILE];
new g_szPlayerModel[MAX_CLASSES][MAX_TIERS][MAX_LENGTHFILE];
new g_szFireSound[MAX_CLASSES][MAX_TIERS][MAX_LENGTHFILE];
new Float:g_fWeaponDamage[MAX_CLASSES][MAX_TIERS];
new Float:g_fWeaponSpeed[MAX_CLASSES][MAX_TIERS];
new g_iWeaponCSW[MAX_CLASSES][MAX_TIERS];

new g_szWeaponName2[MAX_CLASSES][MAX_TIERS][MAX_LENGTH];
new g_szViewModel2[MAX_CLASSES][MAX_TIERS][MAX_LENGTHFILE];
new g_szPlayerModel2[MAX_CLASSES][MAX_TIERS][MAX_LENGTHFILE];
new g_szFireSound2[MAX_CLASSES][MAX_TIERS][MAX_LENGTHFILE];
new Float:g_fWeaponDamage2[MAX_CLASSES][MAX_TIERS];
new Float:g_fWeaponSpeed2[MAX_CLASSES][MAX_TIERS];
new g_iWeaponCSW2[MAX_CLASSES][MAX_TIERS];

//Forwards
new g_fwDummyResult

new g_fwClassChosen_Pre, g_fwClassChosen_Post

static const g_szWpnEntNames[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_precache()
{	
	g_fwPrecache = register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public plugin_init()
{
	register_plugin("Classes", VERSION, "Tirant");
	
	register_clcmd("say", 	   	"cmdSay");
	register_clcmd("say_team",	"cmdSay");
	
	register_event("CurWeapon","ev_CurWeapon","be","1=1")
	//register_event("HLTV", "ev_RoundStart", "a", "1=0", "2=0")
	//register_logevent("logevent_round_start",2, 	"1=Round_Start")
	//register_logevent("logevent_round_end", 2, 	"1=Round_End")
	
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage");
	new szWeapon[20];
	for (new i=CSW_P228;i<=CSW_P90;i++) 
	{
		if (get_weaponname(i, szWeapon, charsmax(szWeapon)))
		{
			RegisterHam(Ham_Item_Deploy, szWeapon, "ham_ItemDeploy_Post", 1)
			
			//if (i == CSW_AWP || i == CSW_SCOUT || i == CSW_SG550 || i == CSW_G3SG1 || i == CSW_KNIFE || i == CSW_SG552 || i == CSW_AUG)
			//	continue;

			//RegisterHam(Ham_Weapon_PrimaryAttack, szWeapon, "ham_BlockSecondaryAttack_Post", 1)
			//RegisterHam(Ham_Weapon_SecondaryAttack, szWeapon, "ham_BlockSecondaryAttack_Post", 1)
		}
	}
	
	unregister_forward(FM_PrecacheEvent, g_fwPrecache, 1)
	register_forward(FM_PlaybackEvent,    "fw_PlaybackEvent")
	//register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	
	register_menucmd(register_menuid("A1234"),KEYS_GENERIC,"weapons_pushed")
	register_menucmd(register_menuid("B0069"),KEYS_GENERIC,"method_pushed")
	
	g_iMaxPlayers = get_maxplayers();
	
	//Custom forwards
	g_fwClassChosen_Pre = CreateMultiForward("ff_player_class_chosen_pre", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_fwClassChosen_Post = CreateMultiForward("ff_player_class_chosen_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_end()
{
	DestroyForward(g_fwClassChosen_Pre)
	DestroyForward(g_fwClassChosen_Post)
}

public plugin_natives()
{
	register_native("ff_register_class",	"native_register_class", 1);
	register_native("ff_register_tier",	"native_register_tier", 1);
	
	register_native("ff_get_user_class",	"native_get_user_class", 1);
	register_native("ff_get_user_tier",	"native_get_user_tier", 1);
	
	register_native("ff_get_user_tier_csw",	"native_get_user_tier_csw", 1);
	register_native("ff_get_user_tier_csw2","native_get_user_tier_csw2", 1);
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

public ham_BlockSecondaryAttack_Post(const Entity)
{
	set_pdata_float(Entity , 47, 9999.0, 4);
}

public client_putinserver(id)
{
	g_isConnected[id] = true;
	g_isAlive[id] = false;
	if (is_user_bot(id))
		g_isBot[id] = true;
		
	g_iCurWeapon[id] = 0;
	g_iWeaponEnt[id] = 0;
	
	g_isMenuLooping[id] = true;
	g_isFirstMenu[id] = true;
	
	g_iMenuStore[id][0] = 0;
	g_iMenuStore[id][1] = 0;
	g_hasChosen[id] = false;
	
	g_iMenuTier[id] = CLASS_TIER_1;
	g_iPlayerTier[id] = CLASS_TIER_1;
	g_iPlayerClass[id] = 0;

	g_isGunFiring[id] = false;
}

public client_disconnect(id)
{
	g_isConnected[id] = false;
	g_isAlive[id] = false;
	g_isBot[id] = false;
	
	g_iMenuTier[id] = CLASS_TIER_1;
	g_iPlayerTier[id] = CLASS_TIER_1;
	g_iPlayerClass[id] = 0;

	g_isGunFiring[id] = false;
	
	remove_task(id+TASK_WEAPONS);
}

public ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return HAM_IGNORED;

	g_isAlive[id] = true;
	
	if (g_isBot[id])
		return HAM_IGNORED;
	
	g_isGunFiring[id] = false;
	g_iWeaponEnt[id] = 0;
	
	g_hasChosen[id] = false;
	g_iPlayerClass[id] = g_iMenuStore[id][0];
	g_iPlayerTier[id] = g_iMenuStore[id][1];
	
	//fm_strip_user_weapons(id);
	//fm_give_item(id, "weapon_knife");
	show_method_menu(id);
	
	if (!g_isMenuLooping[id])
		client_print_color(id, DontChange, "%s Your class menu is ^4disabled^1. To ^4re-enable^1 it at any time, type ^"^4/class^1^"", MODNAME);
	
	return HAM_IGNORED;
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (is_user_alive(victim))
		return;
		
	g_isAlive[victim] = false;
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
		if (equali(szMessage, "/commands") || equali(szMessage, "/cmd") || equali(szMessage, "/cmds"))
		{
			new szCmds[128]
			for (new i = 0; i < sizeof g_szCommands; i++)
			{
				if (i == 0)
					formatex(szCmds, charsmax(szCmds), "%s", g_szCommands[i]);
				else
					formatex(szCmds, charsmax(szCmds), "%s^1, ^4%s", szCmds, g_szCommands[i]);
			}
				
			client_print_color(id, DontChange, "%s ^4%s", MODNAME, szCmds);
		}
		else if (equali(szMessage, "/class") || equali(szMessage, "/changeclass") || equali(szMessage, "/gun") || equali(szMessage, "/guns"))
		{
			g_isMenuLooping[id] = true;
			show_method_menu(id);
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public show_method_menu(id)
{
	new iClass = g_iPlayerClass[id];
	new iTier = g_iPlayerTier[id];
	
	if (g_isFirstMenu[id])
	{
		show_weapons_menu(id, 0, g_iMenuTier[id]);
		return;
	}
	
	if (g_hasChosen[id])
	{
		client_print_color(id, DontChange, "%s You need to wait until you respawn to choose a new class", MODNAME);
		return;
	}
	else if (!g_isMenuLooping[id])
	{
		set_task(0.1, "task_GiveWeapons", id+TASK_WEAPONS);
		return;
	}

	new szMenuBody[2048], nLen, bitKeys;
		
	nLen = format( szMenuBody, 2047, "\rBattlefield Classes v%s:", VERSION);
	bitKeys += (1<<0)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r1. \wNew Class");
	bitKeys += (1<<1)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r2. \wLast Class: \r%s \y[%s + %s]", g_szClassName[iClass], g_szWeaponName[iClass][iTier], g_szWeaponName2[iClass][iTier]);
	bitKeys += (1<<2)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r3. \wLast Class + Save");
	
	new iMoney = cs_get_user_money(id);
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n");
	for(new i = 3; i < MAX_TIERS+2; i++)
	{
		iTier = i-2;
		
		if (iMoney >= g_iTierCost[iTier])
			bitKeys += (1<<i);
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r%d. %sPreview a random %s class ($%d)", i+1, (iMoney >= g_iTierCost[iTier] ? "\w" : "\d"), g_szTierNames[iTier], g_iTierCost[iTier]);
		
		g_iMenuOptions[id][i] = iTier
	}

	show_menu(id,bitKeys,szMenuBody,-1,"B0069")
}

public method_pushed(id, keys)
{
	if (!g_isAlive[id])
		return;
	
	switch (keys)
	{
		case 0:
		{
			show_weapons_menu(id, g_iMenuOffset[id], g_iPlayerTier[id]);
		}
		case 1:
		{
			g_hasChosen[id] = true;
			task_GiveWeapons(id);
		}
		case 2:
		{
			g_hasChosen[id] = true;
			g_isMenuLooping[id] = false;
			task_GiveWeapons(id);
			client_print_color(id, DontChange, "%s You have ^4disabled^1 your class menu. To ^4re-enable^1 it at any time, type ^"^4/class^1^"", MODNAME);
		}
		case 3..(MAX_TIERS+3):
		{
			new iTier = g_iMenuOptions[id][keys];
			
			new iMoney = cs_get_user_money(id);
			if (iMoney >= g_iTierCost[iTier])
			{
				cs_set_user_money(id, iMoney-g_iTierCost[iTier], 1);
				g_hasChosen[id] = true;
				
				g_iPlayerClass[id] = random_num(0, g_iClasses-1);
				g_iPlayerTier[id] = iTier;
				task_GiveWeapons(id);
				
				client_print_color(id, DontChange, "%s You have rolled the ^4%s^1 class (^4%s^1 + ^4%s^1)", MODNAME, g_szClassName[g_iPlayerClass[id]], g_szWeaponName[g_iPlayerClass[id]][g_iPlayerTier[id]], g_szWeaponName2[g_iPlayerClass[id]][g_iPlayerTier[id]]);
			}
			else
				show_method_menu(id);
		}
	}
	
	return;
}

public show_weapons_menu(id, iOffset, iTier)
{
	if (g_hasChosen[id])
		return;
	
	new szMenuBody[2048], nLen;
			
	nLen = format( szMenuBody, 2047, "\rSelect a Class \y(%s):", g_szTierNames[iTier]);
	
	if(iOffset < 0)
		iOffset = 0;

	new bitKeys, iCurNum;
	for(new i = iOffset; i < g_iClasses; i++)
	{
		g_iMenuOptions[id][iCurNum] = i
		bitKeys += (1<<iCurNum)
	
		iCurNum++
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r%d. \w%s \y[%s + %s]", iCurNum, g_szClassName[i], g_szWeaponName[i][iTier], g_szWeaponName2[i][iTier]);
	
		if(iCurNum == 7)
			break;
	}

	nLen += format( szMenuBody[nLen], 2047-nLen, "^n");
	if(iCurNum == 7 && iOffset<12 && g_iClasses > 7)
	{
		bitKeys += (1<<7)
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r8. \wNext");
	}
	if(iOffset)
	{
		bitKeys += (1<<8)
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r9. \wBack");
	}
	
	bitKeys += (1<<9)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r0. \yDisplay Next Tier");
		
	show_menu(id,bitKeys,szMenuBody,-1,"A1234")
}

public weapons_pushed(id,key)
{
	if (!g_isAlive[id])
		return;
	
	if(key < 7)
	{
		if (!g_hasChosen[id])
			g_hasChosen[id] = true;
			
		//set_user_footsteps(id, 0);
		
		g_iMenuOffset[id] = 0;
		
		g_iMenuStore[id][0] = g_iMenuOptions[id][key];
		new iClass = g_iMenuStore[id][0];
		g_iMenuStore[id][1] = g_iMenuTier[id];
		new iTier = g_iMenuStore[id][1];
		
		ExecuteForward(g_fwClassChosen_Pre, g_fwDummyResult, id, iClass, iTier);
		
		if (g_isFirstMenu[id] || !g_isMenuLooping[id] || g_hasChosen[id])
		{
			g_isFirstMenu[id] = false;
			
			g_iPlayerClass[id] = iClass;
			g_iPlayerTier[id] = iTier;
			task_GiveWeapons(id);
			
			client_print_color(id, DontChange, "%s You have selected the ^4%s^1 class (^4%s^1 + ^4%s^1)", MODNAME, g_szClassName[g_iPlayerClass[id]], g_szWeaponName[g_iPlayerClass[id]][g_iPlayerTier[id]], g_szWeaponName2[g_iPlayerClass[id]][g_iPlayerTier[id]]);
		}
		else
			client_print_color(id, DontChange, "%s Your new class will load when you respawn", MODNAME);
	}
	else
	{
		switch (key)
		{
			case 7: g_iMenuOffset[id] += 7
			case 8: g_iMenuOffset[id] -= 7
			case 9:
			{
				g_iMenuTier[id]++;
				
				if (ff_get_user_rank(id) / 12 < g_iMenuTier[id] || g_iMenuTier[id] > sizeof g_szTierNames-1)
					g_iMenuTier[id] = 0;
			}
		}
		show_weapons_menu(id, g_iMenuOffset[id], g_iMenuTier[id]);
	}
	return;
}

public task_GiveWeapons(id)
{
	if (id > MAXPLAYERS+1)
		id -= TASK_WEAPONS;
		
	fm_strip_user_weapons(id);
	fm_give_item(id,"weapon_knife");
	fm_give_item(id, "weapon_hegrenade");
	
	new iCSW
	
	iCSW = g_iWeaponCSW[g_iPlayerClass[id]][g_iPlayerTier[id]];
	fm_give_item(id,g_szWpnEntNames[iCSW])
	cs_set_user_bpammo(id,iCSW, clamp(90 + ff_get_user_ammo(id), 90, 240))
	
	iCSW = g_iWeaponCSW2[g_iPlayerClass[id]][g_iPlayerTier[id]];
	fm_give_item(id,g_szWpnEntNames[iCSW])
	cs_set_user_bpammo(id,iCSW,clamp(40 + (ff_get_user_ammo(id)/2), 40, 120))
	
	ExecuteForward(g_fwClassChosen_Post, g_fwDummyResult, id, g_iPlayerClass[id], g_iPlayerTier[id]);
}

public fw_PrecacheEvent_Post(type, const name[])
{
	for(new i = 0; i < sizeof g_szWeaponEvents; i++) if(equal(g_szWeaponEvents[i], name))
	{
		g_evGunFired |= (1<<get_orig_retval())
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public fw_PlaybackEvent(flags, id, eventid)
{
	if(g_evGunFired & (1<<eventid) && (1 <= id <= g_iMaxPlayers) && !g_isBot[id])
		g_isGunFiring[id] = true;
}

public ev_CurWeapon(id)
{
	if (!g_isAlive[id])
		return;
		
	g_iCurWeapon[id] = read_data(2);
	new iTier = g_iPlayerTier[id];
	new iClass = g_iPlayerClass[id];
	
	if (!task_CheckSpeed(id, g_iWeaponCSW[iClass][iTier], g_fWeaponSpeed[iClass][iTier], g_szViewModel[iClass][iTier], g_szPlayerModel[iClass][iTier], g_szFireSound[iClass][iTier]))
		task_CheckSpeed(id, g_iWeaponCSW2[iClass][iTier], g_fWeaponSpeed2[iClass][iTier], g_szViewModel2[iClass][iTier], g_szPlayerModel2[iClass][iTier], g_szFireSound2[iClass][iTier])
}

task_CheckSpeed(id, iCswCheck, Float:fWeaponSpeed, const szViewModel[], const szPlayerModel[], const szFireSound[])
{
	if (g_iCurWeapon[id] == iCswCheck)
	{
		if (equal(szViewModel, "") == 0)
			entity_set_string( id , EV_SZ_viewmodel , szViewModel )  
		
		if (equal(szPlayerModel, "") == 0)
			entity_set_string( id , EV_SZ_weaponmodel , szPlayerModel )  
			
	
		if (g_isGunFiring[id] && equal(szFireSound, "") == 0)
			emit_sound(id,CHAN_AUTO, szFireSound,1.0,ATTN_NORM,0,PITCH_NORM);
		
		if(fWeaponSpeed != 1.0)
		{
			if(!pev_valid(g_iWeaponEnt[id]) || (pev_valid(g_iWeaponEnt[id]) && cs_get_weapon_id(g_iWeaponEnt[id]) != g_iCurWeapon[id]))
			{
				static szWeaponName[32]; get_weaponname(g_iCurWeapon[id], szWeaponName, 31)
				g_iWeaponEnt[id] = fm_find_ent_by_owner(-1, szWeaponName, id)
			}
		
			if(cs_get_weapon_id(g_iWeaponEnt[id]) == g_iCurWeapon[id])
			{	
				static Float:Delay,Float:M_Delay
				Delay = get_pdata_float( g_iWeaponEnt[id], 46, 4) * fWeaponSpeed;
				M_Delay = get_pdata_float( g_iWeaponEnt[id], 47, 4) * fWeaponSpeed;
				if (Delay > 0.0)
				{
					set_pdata_float( g_iWeaponEnt[id], 46, Delay, 4);
					set_pdata_float( g_iWeaponEnt[id], 47, M_Delay, 4);
				}
			}
		}	
		g_isGunFiring[id] = false;
		return true;
	}
	return false;
}

stock fm_find_ent_by_owner(index, const classname[], owner) 
{
	static ent; ent = index
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) && pev(ent, pev_owner) != owner) {}
	
	return ent
}

public ham_ItemDeploy_Post(ent)
{
	static id;
	id = pev(ent, pev_owner);
	
	if(!is_user_alive(id))
		return;
		
	g_iCurWeapon[id] = cs_get_weapon_id(ent);
}

public ham_TakeDamage(victim, useless, attacker, Float:damage, damagebits)
{
	if (!is_user_connected(attacker) || !g_isAlive[victim])
		return HAM_HANDLED;
	
	new iTier = g_iPlayerTier[attacker];
	new iClass = g_iPlayerClass[attacker];
	
	if (g_iCurWeapon[attacker] == g_iWeaponCSW[iClass][iTier])
	{
		damage *= g_fWeaponDamage[iClass][iTier]
	}
	else if (g_iCurWeapon[attacker] == g_iWeaponCSW2[iClass][iTier])
	{
		damage *= g_fWeaponDamage2[iClass][iTier]
	}
		
	SetHamParamFloat(4, damage)
	return HAM_HANDLED
}

public native_register_class(const szClassName[])
{	
	param_convert(1);
	
	format(g_szClassName[g_iClasses], MAX_LENGTH - 1, szClassName);

	g_iClasses++
	
	return g_iClasses-1;
}

public native_register_tier(const szWeaponName[], const szViewModel[], const szPlayerModel[], const szFireSound[], Float:fWeaponDamage, Float:fWeaponSpeed, iCswReplacer, const szWeaponName2[], const szViewModel2[], const szPlayerModel2[], const szFireSound2[], Float:fWeaponDamage2, Float:fWeaponSpeed2, iCswReplacer2, iClass, iTier)
{
	if (iTier < 0 || iTier >= MAX_TIERS)
		return -1;
		
	if (iClass < 0 || iClass > g_iClasses+1)
		return -1;
		
	param_convert(1);
	param_convert(2);
	param_convert(3);
	param_convert(4);
	param_convert(8);
	param_convert(9);
	param_convert(10);
	param_convert(11);
	
	//Primary
	format(g_szWeaponName[iClass][iTier], 	MAX_LENGTH - 1, szWeaponName);
	format(g_szViewModel[iClass][iTier], 	MAX_LENGTHFILE - 1, szViewModel);
	format(g_szPlayerModel[iClass][iTier], 	MAX_LENGTHFILE - 1, szPlayerModel);
	format(g_szFireSound[iClass][iTier], 	MAX_LENGTHFILE - 1, szFireSound);
	g_fWeaponDamage[iClass][iTier] = fWeaponDamage
	g_fWeaponSpeed[iClass][iTier] = fWeaponSpeed
	g_iWeaponCSW[iClass][iTier] = iCswReplacer
	
	//Secondary
	format(g_szWeaponName2[iClass][iTier], 	MAX_LENGTH - 1, szWeaponName2);
	format(g_szViewModel2[iClass][iTier], 	MAX_LENGTHFILE - 1, szViewModel2);
	format(g_szPlayerModel2[iClass][iTier], 	MAX_LENGTHFILE - 1, szPlayerModel2);
	format(g_szFireSound2[iClass][iTier], 	MAX_LENGTHFILE - 1, szFireSound2);
	g_fWeaponDamage2[iClass][iTier] = fWeaponDamage2
	g_fWeaponSpeed2[iClass][iTier] = fWeaponSpeed2
	g_iWeaponCSW2[iClass][iTier] = iCswReplacer2
	
	//Process and precache all files
	task_AttemptPrecache(g_szViewModel[iClass][iTier]);
	task_AttemptPrecache(g_szPlayerModel[iClass][iTier]);
	task_AttemptPrecache(g_szFireSound[iClass][iTier], false);
	
	task_AttemptPrecache(g_szViewModel2[iClass][iTier]);
	task_AttemptPrecache(g_szPlayerModel2[iClass][iTier]);
	task_AttemptPrecache(g_szFireSound2[iClass][iTier], false);
	
	return iTier;
}

task_AttemptPrecache(const szFile[], bool:isModel = true)
{
	if (equal(szFile, ""))
		return;
		
	if (isModel)
		precache_model(szFile);
	else
		precache_sound(szFile);
}

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent))
		return 0;

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

public native_get_user_tier(id) return g_iPlayerTier[id];
public native_get_user_class(id) return g_iPlayerClass[id];

public native_get_user_tier_csw(id) return g_iWeaponCSW[g_iPlayerClass[id]][g_iPlayerTier[id]];
public native_get_user_tier_csw2(id) return g_iWeaponCSW2[g_iPlayerClass[id]][g_iPlayerTier[id]];

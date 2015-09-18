#include <amxmodx>
#include <amxmisc>
#include <firefight_weapons>

#define VERSION "1.0"

static const g_szClassName[] = "Pure Terrorist"

new g_iWeaponClass;

/*static const g_szMiscSounds[][] = 
{
	"weapons/m16/fire.wav",
	"weapons/m16/boltpull.wav",
	"weapons/m16/mag_in.wav",
	"weapons/m16/mag_out.wav",
	"weapons/m16/mag_push.wav",
	"weapons/m16/safety.wav"	
}*/

public plugin_init()
{
	register_plugin(g_szClassName, VERSION, "Tirant")
}

public plugin_precache()
{
	g_iWeaponClass = ff_register_class(g_szClassName);
	
	ff_register_tier("MAC10", 		"", 					"",					"",			CSW_MAC10,	"Glock", 		"", 					"",					"",			CSW_GLOCK18,	g_iWeaponClass, 0);
	ff_register_tier("Galil", 		"", 					"",					"",			CSW_GALIL,	"Glock", 		"", 					"",					"",			CSW_GLOCK18,	g_iWeaponClass, 1);
	ff_register_tier("SG552", 		"", 					"",					"",			CSW_SG552,	"Dual M9's",		"", 					"",					"",			CSW_ELITE,	g_iWeaponClass, 2);
	ff_register_tier("AK-47",		"",					"",					"",			CSW_AK47,	"Dual M9's", 		"", 					"",					"",			CSW_ELITE,	g_iWeaponClass, 3);
	
	//for (new i = 0; i < sizeof g_szMiscSounds; i++)
	//	precache_sound(g_szMiscSounds[i]);
}
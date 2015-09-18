#include <amxmodx>
#include <amxmisc>
#include <firefight_weapons>

#define VERSION "1.0"

static const g_szClassName[] = "Pure CT"

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
	
	ff_register_tier("TMP", 			"", 					"",					"",			CSW_TMP,	"USP", 		"", 					"",					"",			CSW_USP,	g_iWeaponClass, 0);
	ff_register_tier("Famas", 		"", 					"",					"",			CSW_FAMAS,	"USP", 		"", 					"",					"",			CSW_USP,	g_iWeaponClass, 1);
	ff_register_tier("AUG", 			"", 					"",					"",			CSW_AUG,	"Fiveseven",	"", 					"",					"",			CSW_FIVESEVEN,	g_iWeaponClass, 2);
	ff_register_tier("M4A1",		"",					"",					"",			CSW_M4A1,	"Fiveseven", 	"", 					"",					"",			CSW_FIVESEVEN,	g_iWeaponClass, 3);
	
	//for (new i = 0; i < sizeof g_szMiscSounds; i++)
	//	precache_sound(g_szMiscSounds[i]);
}

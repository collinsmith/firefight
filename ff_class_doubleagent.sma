#include <amxmodx>
#include <amxmisc>
#include <firefight_weapons>

#define VERSION "1.0"

static const g_szClassName[] = "Double Agent"

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
	
	ff_register_tier("Galil", 		"", 					"",					"",			CSW_GALIL,	"USP", 		"", 					"",					"",			CSW_USP,	g_iWeaponClass, 0);
	ff_register_tier("Famas", 		"", 					"",					"",			CSW_FAMAS,	"Glock", 	"", 					"",					"",			CSW_GLOCK18,	g_iWeaponClass, 1);
	ff_register_tier("SG552", 		"", 					"",					"",			CSW_SG552,	"USP",		"", 					"",					"",			CSW_USP,	g_iWeaponClass, 2);
	ff_register_tier("AUG",			"",					"",					"",			CSW_AUG,	"Glock", 	"", 					"",					"",			CSW_GLOCK18,	g_iWeaponClass, 3);
	
	//for (new i = 0; i < sizeof g_szMiscSounds; i++)
	//	precache_sound(g_szMiscSounds[i]);
}
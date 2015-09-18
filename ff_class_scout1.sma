#include <amxmodx>
#include <amxmisc>
#include <firefight_weapons>

#define VERSION "1.1"

#define szClassName "Scout Sniper"

/**
 * Tier 1
 */
#define iWeaponCSW1_1 		CSW_SCOUT
#define szWeaponName1_1		"Alpha Scout"
#define szViewModel1_1		""
#define szPlayerModel1_1	""
#define szFireSound1_1		""
#define fWeaponDamage1_1	0.95
#define fWeaponSpeed1_1		0.8
#define iWeaponCSW1_2		CSW_USP
#define szWeaponName1_2		"USP"
#define szViewModel1_2		""
#define szPlayerModel1_2	""
#define szFireSound1_2		""
#define fWeaponDamage1_2	1.0
#define fWeaponSpeed1_2		1.0

/**
 * Tier 2
 */
#define iWeaponCSW2_1 		CSW_SCOUT
#define szWeaponName2_1		"Beta Scout"
#define szViewModel2_1		""
#define szPlayerModel2_1	""
#define szFireSound2_1		""
#define fWeaponDamage2_1	1.00
#define fWeaponSpeed2_1		0.85
#define iWeaponCSW2_2		CSW_P228
#define szWeaponName2_2		"P228"
#define szViewModel2_2		""
#define szPlayerModel2_2	""
#define szFireSound2_2		""
#define fWeaponDamage2_2	1.0
#define fWeaponSpeed2_2		1.0

/**
 * Tier 3
 */
#define iWeaponCSW3_1 		CSW_SCOUT
#define szWeaponName3_1		"Charlie Scout"
#define szViewModel3_1		""
#define szPlayerModel3_1	""
#define szFireSound3_1		""
#define fWeaponDamage3_1	1.15
#define fWeaponSpeed3_1		0.9
#define iWeaponCSW3_2		CSW_FIVESEVEN
#define szWeaponName3_2		"Fiveseven"
#define szViewModel3_2		""
#define szPlayerModel3_2	""
#define szFireSound3_2		""
#define fWeaponDamage3_2	1.0
#define fWeaponSpeed3_2		1.0

/**
 * Tier 4
 */
#define iWeaponCSW4_1 		CSW_SCOUT
#define szWeaponName4_1		"Delta Scout"
#define szViewModel4_1		""
#define szPlayerModel4_1	""
#define szFireSound4_1		""
#define fWeaponDamage4_1	1.25
#define fWeaponSpeed4_1		0.95
#define iWeaponCSW4_2		CSW_FIVESEVEN
#define szWeaponName4_2		"Fiveseven"
#define szViewModel4_2		""
#define szPlayerModel4_2	""
#define szFireSound4_2		""
#define fWeaponDamage4_2	1.0
#define fWeaponSpeed4_2		1.0

/**
 * Tier 5
 */
#define iWeaponCSW5_1 		CSW_SCOUT
#define szWeaponName5_1		"Echo Scout"
#define szViewModel5_1		""
#define szPlayerModel5_1	""
#define szFireSound5_1		""
#define fWeaponDamage5_1	1.30
#define fWeaponSpeed5_1		0.9
#define iWeaponCSW5_2		CSW_FIVESEVEN
#define szWeaponName5_2		"Fiveseven"
#define szViewModel5_2		""
#define szPlayerModel5_2	""
#define szFireSound5_2		""
#define fWeaponDamage5_2	1.0
#define fWeaponSpeed5_2		1.0

new g_iWeaponClass;
new g_iTier[5];

/*static const g_szMiscSounds[][] = 
{
	"weapons/m24/bolt.wav",
	"weapons/m24/boltback.wav",
	"weapons/m24/boltforward.wav",
	"weapons/m24/clipin.wav",
	"weapons/m24/clipout.wav",
	"weapons/m200/boltdown.wav",
	"weapons/m200/boltpull.wav",
	"weapons/m200/clipin.wav",
	"weapons/m200/clipout.wav",
	"weapons/trg/boltpull1.wav",
	"weapons/trg/boltdown.wav",
	"weapons/trg/boltup.wav",
	"weapons/trg/clipin.wav",
	"weapons/trg/clipout.wav"
}*/

public plugin_init()
{
	register_plugin(szClassName, VERSION, "Tirant")
	
	/*register_event("CurWeapon","ev_CurWeapon","be","1=1")
	
	new szWeapon[20];
	if (get_weaponname(CSW_FAMAS, szWeapon, charsmax(szWeapon)))
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, szWeapon, "ham_BlockSecondaryAttack_Post", 1)
		RegisterHam(Ham_Weapon_SecondaryAttack, szWeapon, "ham_BlockSecondaryAttack_Post", 1)
	}*/
}

public plugin_precache()
{
	g_iWeaponClass = ff_register_class(szClassName);

	g_iTier[CLASS_TIER_1] = ff_register_tier(szWeaponName1_1, szViewModel1_1, szPlayerModel1_1, szFireSound1_1, fWeaponDamage1_1, fWeaponSpeed1_1, iWeaponCSW1_1, szWeaponName1_2, szViewModel1_2, szPlayerModel1_2, szFireSound1_2, fWeaponDamage1_2, fWeaponSpeed1_2, iWeaponCSW1_2, g_iWeaponClass, CLASS_TIER_1);
	g_iTier[CLASS_TIER_2] = ff_register_tier(szWeaponName2_1, szViewModel2_1, szPlayerModel2_1, szFireSound2_1, fWeaponDamage2_1, fWeaponSpeed2_1, iWeaponCSW2_1, szWeaponName2_2, szViewModel2_2, szPlayerModel2_2, szFireSound2_2, fWeaponDamage2_2, fWeaponSpeed2_2, iWeaponCSW2_2, g_iWeaponClass, CLASS_TIER_2);
	g_iTier[CLASS_TIER_3] = ff_register_tier(szWeaponName3_1, szViewModel3_1, szPlayerModel3_1, szFireSound3_1, fWeaponDamage3_1, fWeaponSpeed3_1, iWeaponCSW3_1, szWeaponName3_2, szViewModel3_2, szPlayerModel3_2, szFireSound3_2, fWeaponDamage3_2, fWeaponSpeed3_2, iWeaponCSW3_2, g_iWeaponClass, CLASS_TIER_3);
	g_iTier[CLASS_TIER_4] = ff_register_tier(szWeaponName4_1, szViewModel4_1, szPlayerModel4_1, szFireSound4_1, fWeaponDamage4_1, fWeaponSpeed4_1, iWeaponCSW4_1, szWeaponName4_2, szViewModel4_2, szPlayerModel4_2, szFireSound4_2, fWeaponDamage4_2, fWeaponSpeed4_2, iWeaponCSW4_2, g_iWeaponClass, CLASS_TIER_4);
	g_iTier[CLASS_TIER_5] = ff_register_tier(szWeaponName5_1, szViewModel5_1, szPlayerModel5_1, szFireSound5_1, fWeaponDamage5_1, fWeaponSpeed5_1, iWeaponCSW5_1, szWeaponName5_2, szViewModel5_2, szPlayerModel5_2, szFireSound5_2, fWeaponDamage5_2, fWeaponSpeed5_2, iWeaponCSW5_2, g_iWeaponClass, CLASS_TIER_5);
	
	//for (new i = 0; i < sizeof g_szMiscSounds; i++)
	//	precache_sound(g_szMiscSounds[i]);
}

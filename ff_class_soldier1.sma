#include <amxmodx>
#include <amxmisc>
#include <firefight_weapons>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

#define VERSION "1.1"

#define szClassName "Soldier"

/**
 * Tier 1
 */
#define iWeaponCSW1_1 		CSW_FAMAS
#define szWeaponName1_1		"Famas"
#define szViewModel1_1		""
#define szPlayerModel1_1	""
#define szFireSound1_1		""
#define fWeaponDamage1_1	0.95
#define fWeaponSpeed1_1		1.0
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
#define iWeaponCSW2_1 		CSW_FAMAS
#define szWeaponName2_1		"Galil (Burst)"
#define szViewModel2_1		"models/v_galil.mdl"
#define szPlayerModel2_1	"models/p_galil.mdl"
#define szFireSound2_1		"weapons/galil-1.wav"
#define fWeaponDamage2_1	1.00
#define fWeaponSpeed2_1		1.05
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
#define iWeaponCSW3_1 		CSW_FAMAS
#define szWeaponName3_1		"AUG (Burst)"
#define szViewModel3_1		"models/v_aug.mdl"
#define szPlayerModel3_1	"models/p_aug.mdl"
#define szFireSound3_1		"weapons/aug-1.wav"
#define fWeaponDamage3_1	1.05
#define fWeaponSpeed3_1		1.05
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
#define iWeaponCSW4_1 		CSW_FAMAS
#define szWeaponName4_1		"SCAR-L (Burst)"
#define szViewModel4_1		"models/ff/scar/v_scar-b.mdl"
#define szPlayerModel4_1	""
#define szFireSound4_1		"weapons/aug-1.wav"
#define fWeaponDamage4_1	1.05
#define fWeaponSpeed4_1		1.05
#define iWeaponCSW4_2		CSW_ELITE
#define szWeaponName4_2		"Dual M9's"
#define szViewModel4_2		""
#define szPlayerModel4_2	""
#define szFireSound4_2		""
#define fWeaponDamage4_2	1.0
#define fWeaponSpeed4_2		1.0

/**
 * Tier 5
 */
#define iWeaponCSW5_1 		CSW_FAMAS
#define szWeaponName5_1		"M16A1"
#define szViewModel5_1		"models/ff/m16/v_m16.mdl"
#define szPlayerModel5_1	"models/ff/m16/p_m16.mdl"
#define szFireSound5_1		"weapons/m16/fire.wav"
#define fWeaponDamage5_1	1.03
#define fWeaponSpeed5_1		1.1
#define iWeaponCSW5_2		CSW_DEAGLE
#define szWeaponName5_2		"Deagle"
#define szViewModel5_2		""
#define szPlayerModel5_2	""
#define szFireSound5_2		""
#define fWeaponDamage5_2	1.0
#define fWeaponSpeed5_2		1.0

new g_iWeaponClass;
new g_iTier[5];

static const g_szMiscSounds[][] = 
{
	"weapons/m16/fire.wav",
	"weapons/m16/boltpull.wav",
	"weapons/m16/mag_in.wav",
	"weapons/m16/mag_out.wav",
	"weapons/m16/mag_push.wav",
	"weapons/m16/safety.wav"	
}

public plugin_init()
{
	register_plugin(szClassName, VERSION, "Tirant")
	
	register_event("CurWeapon","ev_CurWeapon","be","1=1")
	
	new szWeapon[20];
	if (get_weaponname(CSW_FAMAS, szWeapon, charsmax(szWeapon)))
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, szWeapon, "ham_BlockSecondaryAttack_Post", 1)
		RegisterHam(Ham_Weapon_SecondaryAttack, szWeapon, "ham_BlockSecondaryAttack_Post", 1)
	}
}

public plugin_precache()
{
	g_iWeaponClass = ff_register_class(szClassName);

	g_iTier[CLASS_TIER_1] = ff_register_tier(szWeaponName1_1, szViewModel1_1, szPlayerModel1_1, szFireSound1_1, fWeaponDamage1_1, fWeaponSpeed1_1, iWeaponCSW1_1, szWeaponName1_2, szViewModel1_2, szPlayerModel1_2, szFireSound1_2, fWeaponDamage1_2, fWeaponSpeed1_2, iWeaponCSW1_2, g_iWeaponClass, CLASS_TIER_1);
	g_iTier[CLASS_TIER_2] = ff_register_tier(szWeaponName2_1, szViewModel2_1, szPlayerModel2_1, szFireSound2_1, fWeaponDamage2_1, fWeaponSpeed2_1, iWeaponCSW2_1, szWeaponName2_2, szViewModel2_2, szPlayerModel2_2, szFireSound2_2, fWeaponDamage2_2, fWeaponSpeed2_2, iWeaponCSW2_2, g_iWeaponClass, CLASS_TIER_2);
	g_iTier[CLASS_TIER_3] = ff_register_tier(szWeaponName3_1, szViewModel3_1, szPlayerModel3_1, szFireSound3_1, fWeaponDamage3_1, fWeaponSpeed3_1, iWeaponCSW3_1, szWeaponName3_2, szViewModel3_2, szPlayerModel3_2, szFireSound3_2, fWeaponDamage3_2, fWeaponSpeed3_2, iWeaponCSW3_2, g_iWeaponClass, CLASS_TIER_3);
	g_iTier[CLASS_TIER_4] = ff_register_tier(szWeaponName4_1, szViewModel4_1, szPlayerModel4_1, szFireSound4_1, fWeaponDamage4_1, fWeaponSpeed4_1, iWeaponCSW4_1, szWeaponName4_2, szViewModel4_2, szPlayerModel4_2, szFireSound4_2, fWeaponDamage4_2, fWeaponSpeed4_2, iWeaponCSW4_2, g_iWeaponClass, CLASS_TIER_4);
	g_iTier[CLASS_TIER_5] = ff_register_tier(szWeaponName5_1, szViewModel5_1, szPlayerModel5_1, szFireSound5_1, fWeaponDamage5_1, fWeaponSpeed5_1, iWeaponCSW5_1, szWeaponName5_2, szViewModel5_2, szPlayerModel5_2, szFireSound5_2, fWeaponDamage5_2, fWeaponSpeed5_2, iWeaponCSW5_2, g_iWeaponClass, CLASS_TIER_5);

	
	for (new i = 0; i < sizeof g_szMiscSounds; i++)
		precache_sound(g_szMiscSounds[i]);
}

public ev_CurWeapon(id)
{
	new iCurWeapon = read_data(2);
	new iClass = ff_get_user_class(id);
	
	new ent = get_pdata_cbase(id, 373, 5); 
	
	if (iClass == g_iWeaponClass)
	{
		for (new i = 0; i < 4; i++)
		{
			if (iCurWeapon == ff_get_user_tier_csw(id) && !cs_get_weapon_burst(ent))
			{
				cs_set_weapon_burst(ent,1);
			}
		}
	}
}

public ham_BlockSecondaryAttack_Post(const Entity)
{
	new owner = get_pdata_cbase(Entity, 41, 4);
	new ent = get_pdata_cbase(owner, 373, 5);  
	
	if (ff_get_user_class(owner) == g_iWeaponClass && !cs_get_weapon_burst(ent))
	{
		set_pdata_float(Entity , 47, 9999.0, 4);
		cs_set_weapon_burst(ent,1);
	}
}

public ff_player_class_chosen_post(id, iClass, iTier)
{
	if (!is_user_alive(id))
		return;
		
	if (iClass == g_iWeaponClass)
	{
		new ent = get_pdata_cbase(id, 373, 5);  
		cs_set_weapon_burst(ent,1);
	}
}

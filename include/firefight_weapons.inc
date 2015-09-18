#if defined _firefight_weapons_included
	#endinput
#endif
#define _firefight_weapons_included

#define MAX_LENGTH 16
#define MAX_LENGTHFILE 32

enum
{
	CLASS_TIER_1 = 0,
	CLASS_TIER_2,
	CLASS_TIER_3,
	CLASS_TIER_4
}

/**
 * Returns a players current class
 *
 * @param id		Player index.
 * @return		Returns their current class.
 */
native ff_get_user_class(id);

/**
 * Returns a players current tier (in their class)
 *
 * @param id		Player index.
 * @return		Returns their current tier.
 */
native ff_get_user_tier(id);

/**
 * Returns a players current tier primary csw
 *
 * @param id		Player index.
 * @return		Returns their current tier primary weapon.
 */
native ff_get_user_tier_csw(id);

/**
 * Returns a players current tier secondary csw
 *
 * @param id		Player index.
 * @return		Returns their current tier secondary csw.
 */
native ff_get_user_tier_csw2(id);

/**
 * Registers a class into the plugin
 *
 * @param szClassName	Name of the class.
 *
 * @return		Returns the class number as loaded in plugin.
 */
native ff_register_class(const szClassName[MAX_LENGTH]);

/**
 * Registers a class into the plugin
 *
 * @param szWeaponName		Name of the primary weapon.
 * @param szViewModel		View model of the primary weapon.
 * @param szPlayerModel		Player model of the primary weapon.
 * @param szFireSound		Firing sound of the primary weapon.
 * @param iCswReplacer		CSW base weapon for secondary weapon.
 *
 * @param szWeaponName2		Name of the secondary weapon.
 * @param szViewModel2		View model of the secondary weapon.
 * @param szPlayerModel2	Player model of the secondary weapon.
 * @param szFireSound2		Firing sound of the secondary weapon.
 * @param iCswReplacer2		CSW base weapon for secondary weapon.
 *
 * @param iClass		Class to register tier under
 * @param iTier			Tier to register as
 *
 * @return		Returns the tier number entered.
 */
native ff_register_tier(const szWeaponName[MAX_LENGTH], const szViewModel[MAX_LENGTHFILE], const szPlayerModel[MAX_LENGTHFILE], const szFireSound[MAX_LENGTHFILE], Float:fWeaponDamage, Float:fWeaponSpeed, iCswReplacer, const szWeaponName2[MAX_LENGTH], const szViewModel2[MAX_LENGTHFILE], const szPlayerModel2[MAX_LENGTHFILE], const szFireSound2[MAX_LENGTHFILE], Float:fWeaponDamage2, Float:fWeaponSpeed2, iCswReplacer2, iClass, iTier);

/**
 * Called when a player chooses a new class (before weapons given)
 *
 * @param id		Player index forwarding the event.
 * @param iClass	Player class selected.
 * @param iTier		Player tier selected.
 */
forward ff_player_class_chosen_pre(id, iClass, iTier);

/**
 * Called whenever a player receives new weapons from a class
 *
 * @param id		Player index forwarding the event.
 * @param iClass	Player class selected.
 * @param iTier		Player tier selected.
 */
forward ff_player_class_chosen_post(id, iClass, iTier);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

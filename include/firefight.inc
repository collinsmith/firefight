#if defined _firefight_included
	#endinput
#endif
#define _firefight_included

#define VERSION "1.4"
#define MODNAME "^1[^4Battlefield^1]"
#define MODNAME2 "Battlefield"

/**
 * Resets a players experience to level 1
 *
 * @param id		Player index.
 * @return		Returns their current level (after reset) should be 1
 */
native ff_reset_user_rank(id);

/**
 * Returns a players rank
 *
 * @param id		Player index.
 * @return		Returns their current rank.
 */
native ff_get_user_rank(id);

/**
 * Sets a players rank to a specified number
 *
 * @param id		Player index.
 * @param iRank		Rank to set them to.
 * @return		Returns their current rank (after reset) should be 1
 */
native ff_set_user_rank(id, iRank);

/**
 * Returns a players backpack ammo
 *
 * @param id		Player index.
 * @return		Returns their current backpack ammo.
 */
native ff_get_user_ammo(id)

/**
 * Returns a players max speed
 *
 * @param id		Player index.
 * @return		Returns their current rank.
 */
native ff_get_user_maxspeed(id);

/**
 * Sets a players max speed to a specified number
 *
 * @param id		Player index.
 * @param iSpeed	New max speed.
 * @return		Returns their current max speed.
 */
native ff_set_user_maxspeed(id, iSpeed);

/**
 * Returns a players max health
 *
 * @param id		Player index.
 * @return		Returns their current max health.
 */
native ff_get_user_maxhealth(id);

/**
 * Sets a players max health to a specified number
 *
 * @param id		Player index.
 * @param iHealth	New max health.
 * @return		Returns their new max health.
 */
native ff_set_user_maxhealth(id, iHealth);

/**
 * Returns a players rendering amount
 *
 * @param id		Player index.
 * @return		Returns their current rendering amount.
 */
native ff_get_user_renderamt(id);

/**
 * Sets a players rendering amount to a specified number
 *
 * @param id		Player index.
 * @param iRenderAmt	New render amount.
 * @return		Returns their new rendering amount.
 */
native ff_set_user_renderamt(id, iRenderAmt);

/**
 * Returns a current player's experience
 *
 * @param id		Player index.
 * @return		Returns their current experience
 */
native ff_get_user_xp(id);

/**
 * Adds a given amount of experience to a player
 *
 * @param id		Player index.
 * @param iExperience	Experience to add.
 * @return		Returns their total experience (after addition, with maxlevel clamp)
 */
native ff_add_user_xp(id, iExperience);

/**
 * Called when a player ranks up
 *
 * @param id		Player index forwarding the event.
 * @param iRank		New rank
 */
forward ff_player_rankup(id, iRank);

/**
 * Called when a player gains experience
 *
 * @param id		Player index forwarding the event.
 * @param iExperience	Experience added
 * @param iCurExp	Experience before add
 * @param iTotalXP	Total experience (with clamp) after add
 */
forward ff_player_gainxp(id, iExperience, iCurExp, iTotalXP);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

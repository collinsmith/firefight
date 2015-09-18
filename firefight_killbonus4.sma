#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <firefight>
#include <colorchat>
#include <csdm>

static const Plugin [] = "Killbonuses";
static const Version[] = "0.0.5";
static const Author [] = "Tirant";

static const SOUND_BONUS   [] = "firefight/bonus.wav";
static const SOUND_PAYBACK [] = "firefight/payback.wav";
static const SOUND_HEADSHOT[] = "player/bhit_helmet-1.wav";

#define flag_get(%1,%2)		(%1 &   (1 << %2))
#define flag_set(%1,%2) 	(%1 |=  (1 << %2))
#define flag_unset(%1,%2) 	(%1 &= ~(1 << %2))

#define ADMIN_EXP	15
#define EXP_MULTIPLIER 	1

#define MIN_FOR_FLAGS 4
#define FLAGS_ROUNDXP 250
#define FLAGS_MATCHXP 500

static const g_iHUDKillbonus[3] = { 000, 240, 240 };

enum eKillbonuses {
	BONUS_NONE,
	BONUS_ASSIST,
	BONUS_FIRSTBLOOD,
	BONUS_HEADSHOT,
	BONUS_PAYBACK,
	BONUS_ASSASSINATION,
	BONUS_COMEBACK,
	BONUS_COMEBACK2,
	BONUS_FINALKILL,
	BONUS_POSITIONSECURE,
	BONUS_POSITIONSECURE2,
	BONUS_ONEHITONEKILL
};

static const g_iKillbonuses[eKillbonuses] = {
	50,
	20,
	100,
	50,
	50,
	200,
	75,
	150,
	300,
	100,
	50,
	50,
};

static const g_szKillbonuses[eKillbonuses][] = {
	"Kill!",
	"Assist",
	"First Blood!",
	"Headshot",
	"Payback!",
	"Assassination!",
	"Comeback!",
	"Monster Comeback!",
	"Final Kill!",
	"Area Secure!",
	"Area Secure!",
	"One shot... one kill"
}

static bool:g_bIsFirstKill;
static g_iKiller;

enum _:ePlayerStats {
	LastKiller,
	DeathCounter,
	LastHitter,
	Assist
};
static g_iPlayerStats[ePlayerStats][MAX_PLAYERS+1];

static g_bIsBot;

#if defined FLAGS_ROUNDXP
static g_szFlagRound[64];
#endif

#if defined FLAGS_MATCHXP
static g_szFlagMatch[64];
#endif

public plugin_precache() {
	precache_sound(SOUND_BONUS);
	precache_sound(SOUND_PAYBACK);
	precache_sound(SOUND_HEADSHOT);
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_logevent("logevent_round_end", 2, "1=Round_End");
	
	formatex(g_szFlagRound, 63, "%s You've received ^4%dXP ^1for winning the flag round", MODNAME, FLAGS_ROUNDXP);
	formatex(g_szFlagMatch, 63, "%s You've received ^4%dXP ^1for winning the flag match", MODNAME, FLAGS_MATCHXP);
}

public event_round_start() {
	g_bIsFirstKill = false;
	g_iKiller = 0;
	
	for (new i; i < ePlayerStats; i++) {
		arrayset(g_iPlayerStats[i], 0, MAX_PLAYERS+1);
	}
}

public logevent_round_end() {
	if (g_iKiller) {
		triggerBonus(g_iKiller, BONUS_FINALKILL);
	}
}

public client_connect(id) {
	resetPlayerStats(id);
	if (is_user_bot(id)) {
		flag_set(g_bIsBot,id);
	}
}

public client_disconnect(id) {
	resetPlayerStats(id);
}

resetPlayerStats(id) {
	flag_unset(g_bIsBot,id);
	for (new i; i < ePlayerStats; i++) {
		g_iPlayerStats[i][id] = 0;
	}
}

public client_damage(attacker, victim, damage, wpnindex, hitplace, TA) {
	if (!is_user_connected(attacker) || TA) {
		return PLUGIN_HANDLED;
	}
		
	if (hitplace == HIT_HEAD) {
		client_cmd(attacker, "spk %s", SOUND_HEADSHOT);
	}
	
	if (g_iPlayerStats[LastHitter][victim] != attacker)  {
		g_iPlayerStats[Assist][victim] = g_iPlayerStats[LastHitter][victim];
		g_iPlayerStats[LastHitter][victim] = attacker;
		new iHealth = pev(victim, pev_health)+damage
		if (damage  >= iHealth && (wpnindex == CSW_SCOUT || wpnindex == CSW_AWP)) {
			triggerBonus(attacker, BONUS_ONEHITONEKILL);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public csdm_PostDeath(killer, victim, headshot, const weapon[]) {
	if (!is_user_connected(killer)) {
		return PLUGIN_CONTINUE;
	}
	
	if (killer == victim || get_user_team(killer) == get_user_team(victim)) {
		return PLUGIN_CONTINUE;
	}
	
	triggerBonus(killer, BONUS_NONE);
	g_iKiller = killer;
	
	if (!is_user_connected(victim)) {
		return PLUGIN_CONTINUE;
	}
		
	g_iPlayerStats[LastHitter][victim] = 0;
	
	if (!g_bIsFirstKill) {
		g_bIsFirstKill = true;
		triggerBonus(killer, BONUS_FIRSTBLOOD);
	}
	
	if (headshot) {
		triggerBonus(killer, BONUS_HEADSHOT);
	}
		
	if (victim == g_iPlayerStats[LastKiller][killer]) {
		client_cmd(victim, "spk %s", SOUND_PAYBACK);
		g_iPlayerStats[LastKiller][killer] = 0;
		triggerBonus(killer, BONUS_PAYBACK);
	}
	g_iPlayerStats[LastKiller][victim] = killer;

	if (equal(weapon, "knife")) {
		triggerBonus(killer, BONUS_ASSASSINATION);
	}
	
	if (g_iPlayerStats[DeathCounter][killer] > 4) {
		g_iPlayerStats[DeathCounter][killer] = 0;
		triggerBonus(killer, BONUS_COMEBACK2);
	} else if (g_iPlayerStats[DeathCounter][killer] > 2) {
		g_iPlayerStats[DeathCounter][killer] = 0;
		triggerBonus(killer, BONUS_COMEBACK);
	}
	
	if (g_iPlayerStats[Assist][victim]) {
		triggerBonus(g_iPlayerStats[Assist][victim], BONUS_ASSIST);
		g_iPlayerStats[Assist][victim] = 0;
	}

	return PLUGIN_CONTINUE;
}

triggerBonus(id, eKillbonuses:iBonus) {
	if (flag_get(g_bIsBot, id)) {
		return false;
	}

	static szMessage[64], szSound[64], iExp;
	iExp = (g_iKillbonuses[iBonus] * EXP_MULTIPLIER) + (access(id, ADMIN_LEVEL_A) ? ADMIN_EXP : 0);
	if (iBonus == BONUS_NONE) {
		formatex(szMessage, 63, "+%dXP", iExp);
	} else {
		formatex(szMessage, 63, "%s [+%dXP]", g_szKillbonuses[iBonus], iExp);
		if (iBonus != BONUS_POSITIONSECURE) {
			formatex(szSound, 63, SOUND_BONUS);
		}
	}
		
	ff_set_message(id, szMessage, szSound, g_iHUDKillbonus[0], g_iHUDKillbonus[1], g_iHUDKillbonus[2]);
	ff_add_user_xp(id, iExp)
	
	return true;
}

public csf_flag_taken(id) {
	if ( get_playersnum() < MIN_FOR_FLAGS ) {
		return;
	}
	
	triggerBonus(id, BONUS_POSITIONSECURE);
}

public csf_flag_taken_assist(id) {
	if (get_playersnum() < MIN_FOR_FLAGS) {
		return;
	}
	
	triggerBonus(id, BONUS_POSITIONSECURE2);
}

#if defined FLAGS_ROUNDXP
public csf_round_won(CsTeams:team) {
	if (get_playersnum() < MIN_FOR_FLAGS) {
		return;
	}

	static iPlayers[32], iCount;
	get_players(iPlayers, iCount, "c");
	for ( new id; id < iCount; id++ ) {
		if ( CsTeams:(get_user_team(id)-1) != team ) {
			continue;
		}

		ff_add_user_xp(id, FLAGS_ROUNDXP);
		client_print_color(id, DontChange, g_szFlagRound);
	}
}
#endif

#if defined FLAGS_MATCHXP
public csf_match_won(CsTeams:team) {
	if (get_playersnum() < MIN_FOR_FLAGS) {
		return;
	}
	
	static iPlayers[32], iCount;
	get_players(iPlayers, iCount, "c");
	for ( new id; id < iCount; id++ ) {
		if ( CsTeams:(get_user_team(id)-1) != team ) {
			continue;
		}

		ff_add_user_xp(id, FLAGS_MATCHXP);
		client_print_color(id, DontChange, g_szFlagMatch);
	}
}
#endif
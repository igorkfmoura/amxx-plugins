#include <amxmodx>
#include <reapi>

#define PLUGIN  "Advanced Observer Reapi"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PREFIX_CHAT "^4[Advanced Observer]^1"
#define PREFIX_MENU "\y[Advanced Observer]\w"

/* todo
- ~~observer switch to killer;~~
- fix spec bug on Observer_IsValidTarget
- fix freelook camera position
- fix fadetoblack for specs
- observer target C4 holder
- observer target C4 entity if no holder
- observer grenade camera
- observer doppelganger, copy inputs from another observer
*/

// Note: beware of non-standard bit position, %2 should be on 1-32 range and 
//       not in 0-31 to facilitate playerid manipulation
#define BIT_SET(%1,%2)    ((%1) |=  (1 << ((%2) - 1)))
#define BIT_CLR(%1,%2)    ((%1) &= ~(1 << ((%2) - 1)))
#define BIT_XOR(%1,%2)    ((%1) ^=  (1 << ((%2) - 1)))
#define BIT_IS_SET(%1,%2) ( (%1) & (1 << ((%2) - 1)))
#define BIT_IS_CLR(%1,%2) (~(%1) & (1 << ((%2) - 1)))

enum _:ObserverPreferences
{
    bool:ENABLED,
};
new preferences_default[ObserverPreferences] = 
{
    false
};
new preferences[MAX_PLAYERS+1][ObserverPreferences];

enum _:ObserverConfigs
{
    ENABLED_BITS,
}
new cfg[ObserverConfigs];


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR, URL);

    RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);

    register_clcmd("say /obs", "cmd_say_obs");
}


public client_disconnected(id)
{
    new size = sizeof(preferences_default)
    for (new i = 0; i < size; ++i)
    {
        preferences[id][i] = preferences_default[i];
    }

    BIT_XOR(cfg[ENABLED_BITS], id)
}
public cmd_say_obs(id)
{
    if (!is_user_connected(id))
    {
        return PLUGIN_HANDLED;
    }

    BIT_XOR(cfg[ENABLED_BITS], id);
    client_print_color(id, print_team_red, "%s Advanced Observer is now %s.", PREFIX_CHAT, BIT_IS_SET(cfg[ENABLED_BITS], id) ? "^4enabled^1" : "^3disabled^1");

    return PLUGIN_HANDLED;
}


public CBasePlayer_Killed_Post(victim, killer)
{
    if (!is_user_connected(victim) && !is_user_alive(killer))
    {
        return HC_CONTINUE;
    }

    for (new id = 1; id <= MAX_PLAYERS; ++id)
    {
        if (BIT_IS_SET(cfg[ENABLED_BITS], id) && is_user_connected(id) && !is_user_alive(id))
        {
            new iuser2 = get_entvar(id, var_iuser2);
            if (iuser2 == victim)
            {
                set_entvar(id, var_iuser2, killer);
                set_member(id, m_hObserverTarget, killer);
            }
        }
    }
    
    return HC_CONTINUE;
}
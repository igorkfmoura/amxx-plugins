#include <amxmodx>
#include <reapi>
#include <fakemeta>

#define PLUGIN  "Anti Duck Scroll" 
#define VERSION "0.2.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PM_VEC_VIEW 17.0

new Float:delay;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    bind_pcvar_float(create_cvar("amx_dd_delay", "20.0"), delay);
    
    RegisterHookChain(RG_PM_Move, "event_pm_move");
}

public event_pm_move(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
    {
        return HC_CONTINUE;
    }

    new button     = get_entvar(id, var_button);
    new oldbuttons = get_entvar(id, var_oldbuttons);

    new just_released = (oldbuttons ^ button) & oldbuttons;

    if ((~just_released & IN_DUCK) || (get_pmove(pm_onground) == -1))
    {
        return HC_CONTINUE;
    }

    new bool:in_duck    = bool:(get_entvar(id, var_bInDuck));
    new bool:is_ducking = bool:(get_entvar(id, var_flags) & FL_DUCKING);

    if (in_duck && !is_ducking)
    {
        new Float:duck_time = get_pmove(pm_flDuckTime);

        if (duck_time >= (1000 - delay))
        {
            set_pmove(pm_usehull, 0);
            set_pmove(pm_flDuckTime, 0);
            set_pmove(pm_bInDuck, false);

            new Float:tmp[3];
            get_pmove(pm_view_ofs, tmp);

            tmp[2] = PM_VEC_VIEW;
            set_pmove(pm_view_ofs, tmp);

            get_pmove(pm_velocity, tmp);
            tmp[0] = 0.0;
            tmp[1] = 0.0;
            
            set_pmove(pm_velocity, tmp);
        }
    }

    return HC_CONTINUE;
}
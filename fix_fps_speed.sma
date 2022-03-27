// https://github.com/igorkelvin/amxx-plugins

// References:
//  https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/pm_shared/pm_shared.cpp
//  https://kz-rush.ru/en/article/strafe-physics

#include <amxmodx>
#include <xs>
#include <reapi>

#define PLUGIN  "Fix FPS Speed"
#define VERSION "0.0.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

new enabled;
new cvar_enabled;

new HookChain:hook_PM_AirMove_pre;
new HookChain:hook_PM_AirMove_post;

enum PlayerState
{
    playerid,
    Float:fmove,
    Float:smove,
};
new oldstate[PlayerState];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    cvar_enabled = create_cvar("amx_fix_fps_speed", "1");

    bind_pcvar_num(cvar_enabled, enabled);
    hook_cvar_change(cvar_enabled, "on_cvar_changed");

    hook_PM_AirMove_pre  = RegisterHookChain(RG_PM_AirMove, "on_PM_AirMove_pre",  .post=false);
    hook_PM_AirMove_post = RegisterHookChain(RG_PM_AirMove, "on_PM_AirMove_post", .post=true);

    if (!enabled)
    {
        DisableHookChain(hook_PM_AirMove_pre);
        DisableHookChain(hook_PM_AirMove_post);
    }
}


public on_cvar_changed(pcvar, old_value[], new_value[])
{
    if ((pcvar != cvar_enabled) || equal(old_value, new_value))
    {
        return PLUGIN_CONTINUE;
    }

    new value = str_to_num(new_value);

    if (value)
    {
        EnableHookChain(hook_PM_AirMove_pre);
        EnableHookChain(hook_PM_AirMove_post);
    }
    else
    {
        DisableHookChain(hook_PM_AirMove_pre);
        DisableHookChain(hook_PM_AirMove_post);
    }

    return PLUGIN_CONTINUE;
}

public on_PM_AirMove_pre(id)
{
    oldstate[playerid] = id;

    new Float:_frametime = get_pmove(pm_frametime);

    if (_frametime == 0.01)
    {
        oldstate[playerid] = 0;
        return HC_CONTINUE;
    }

    new Float:scale = _frametime / 0.01;

    new cmd = get_pmove(pm_cmd);
    
    oldstate[fmove] = get_ucmd(cmd, ucmd_forwardmove);
    oldstate[fmove] = get_ucmd(cmd, ucmd_sidemove);
    
    set_ucmd(cmd, ucmd_forwardmove, oldstate[fmove] * scale);
    set_ucmd(cmd, ucmd_sidemove,    oldstate[fmove] * scale);

    return HC_CONTINUE;
}

public on_PM_AirMove_post(id)
{
    if (oldstate[playerid] && (id == oldstate[playerid]))
    {
        // set_pmove(pm_friction, oldstate[friction]);

        new cmd = get_pmove(pm_cmd);
        
        set_ucmd(cmd, ucmd_forwardmove, oldstate[fmove]);
        set_ucmd(cmd, ucmd_sidemove,    oldstate[smove]);
    }
}
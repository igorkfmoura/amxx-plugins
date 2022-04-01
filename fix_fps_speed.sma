// https://github.com/igorkelvin/amxx-plugins

// References:
//  https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/pm_shared/pm_shared.cpp
//  https://kz-rush.ru/en/article/strafe-physics

#include <amxmodx>
#include <xs>
#include <reapi>

#define PLUGIN  "Fix FPS Speed"
#define VERSION "0.0.2"
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
    Float:maxspeed
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

    new cmd = get_pmove(pm_cmd);
    new msec = get_ucmd(cmd, ucmd_msec);

    if (msec == 10)
    {
        oldstate[playerid] = 0;
        return HC_CONTINUE;
    }

    new Float:scale = xs_sqrt(float(msec) / 10.0);
    
    oldstate[fmove] = get_ucmd(cmd, ucmd_forwardmove);
    oldstate[smove] = get_ucmd(cmd, ucmd_sidemove);
    
    new Float:_fmove = oldstate[fmove] * scale;
    new Float:_smove = oldstate[smove] * scale;
    
    set_ucmd(cmd, ucmd_forwardmove, _fmove);
    set_ucmd(cmd, ucmd_sidemove,    _smove);

    oldstate[maxspeed] = get_pmove(pm_maxspeed);
    
    new Float:_maxspeed = oldstate[maxspeed] * scale;

    set_pmove(pm_maxspeed, _maxspeed);

    // client_print_color(id, id, "^4[AirMove 01]^1 fmove: %.1f, smove: %.1f, maxspeed: %.1f", _fmove, _smove, _maxspeed);

    // new Float:_forward[3];
    // new Float:_right[3];

    // get_pmove(pm_forward, _forward);
    // get_pmove(pm_right, _right);

    // _forward[2] = 0.0;
    // _right[2] = 0.0;

    // xs_vec_normalize(_forward, _forward);
    // xs_vec_normalize(_right, _right);

    // client_print_color(id, id, "^4[AirMove 02]^1 _forward: {%.1f, %.1f}, _right: {%.1f, %.1f}", _forward[0], _forward[1], _right[0], _right[1]);

    // new Float:wishvel[3];

    // wishvel[0] = _forward[0] * _fmove + _right[0] * _smove;
    // wishvel[1] = _forward[1] * _fmove + _right[1] * _smove;
    // wishvel[2] = 0.0;

    // new Float:wishspeed = xs_vec_len_2d(wishvel);

    // new Float:wishdir[3];
    // xs_vec_normalize(wishvel, wishdir);

    // if (wishspeed > _maxspeed)
    // {
    //     xs_vec_mul_scalar(wishvel, _maxspeed / wishspeed, wishvel);
    //     wishspeed = _maxspeed;
    // }
    // client_print_color(id, id, "^4[AirMove 03]^1 wishdir: {%.1f, %.1f}, wishspeed: %.1f", wishdir[0], wishdir[1], wishspeed);

    // new Float:wishspd = floatmin(wishspeed, 30.0);

    // new Float:velocity[3];
    // get_pmove(pm_velocity, velocity);

    // new Float:currentspeed = xs_vec_dot(velocity, wishdir);
    // new Float:addspeed = wishspd - currentspeed;

    // client_print_color(id, id, "^4[AirMove 04]^1 wishspd: %.1f, currentspeed: %.1f, addspeed: %.1f", wishspd, currentspeed, addspeed);

    // if (addspeed <= 0.0)
    // {
    //     client_print_color(id, id, "^4[AirMove 05]^1 no gain");
    // }
    // else
    // {
    //     new Float:accel = get_movevar(mv_airaccelerate);
    //     new Float:friction = get_movevar(mv_friction);
    //     new Float:accelspeed = accel * wishspeed * float(msec) * friction * 0.001;
        
    //     client_print_color(id, id, "^4[AirMove 05]^1 accel: %.1f, friction: %.1f, accelspeed: %.1f", accel, friction, accelspeed);

    //     new Float:speed1 = xs_vec_len_2d(velocity);
        
    //     accelspeed = floatmin(accelspeed, addspeed);

    //     velocity[0] += accelspeed * wishdir[0];
    //     velocity[1] += accelspeed * wishdir[1];
    //     velocity[2] += accelspeed * wishdir[2];

    //     new Float:speed2 = xs_vec_len_2d(velocity);
    //     new Float:gain = speed2 - speed1;

    //     client_print_color(id, id, "^4[AirMove 06]^1 speed1: %.1f, speed2: %.1f, gain: %.1f", speed1, speed2, gain);
    // }

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

        set_pmove(pm_maxspeed, oldstate[maxspeed]);
    }
}
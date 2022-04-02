#include <amxmodx>
#include <reapi>
#include <fakemeta>

#define PLUGIN  "ep1c_anti_duckscroll" 
#define VERSION "0.2"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PM_VEC_VIEW 17.0

#define ENTITY_MDL  "models/w_awp.mdl"
#define ENTITY_NAME "antidd"

new blockent;

new Float:delay;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR, URL);

    bind_pcvar_float(create_cvar("amx_dd_delay", "30.0"), delay);

    // blockent = rg_create_entity("info_target");
    // if (is_entity(blockent))
    // {
    //     set_entvar(blockent, var_classname,  ENTITY_NAME);
    //     set_entvar(blockent, var_solid,      SOLID_NOT);
    //     set_entvar(blockent, var_movetype,   MOVETYPE_NONE);
    //     set_entvar(blockent, var_rendermode, kRenderTransAlpha);
    //     set_entvar(blockent, var_renderamt,  0.0);

    //     engfunc(EngFunc_SetModel, blockent, ENTITY_MDL);
    //     engfunc(EngFunc_SetSize,  blockent, Float:{-16.0, -16.0, 53.0}, Float:{16.0, 16.0, 54.0});
		
    //     register_forward(FM_AddToFullPack, "FM_AddToFullPack_Pre");
    // }
    
    RegisterHookChain(RG_PM_Move, "event_pm_move");
}


public FM_AddToFullPack_Pre(eshandle, e, ent, host, hostflags, player, pSet)
{
    if ((ent != blockent))
    {
        return FMRES_IGNORED;
    }

    if (is_user_alive(host))
    {
        return FMRES_SUPERCEDE;
    }

    new Float:fallspeed = get_entvar(host, var_flFallVelocity);
    if (fallspeed >= 0.0)
    {
        new flags = get_entvar(host, var_flags);

        new Float:origin[3];
        get_entvar(host, var_origin);

        if (flags & FL_DUCKING)
        {
            origin[2] += fallspeed ? 2.0 : 18.0;
        }
        else
        {
            origin[2] -= fallspeed ? 16.0 : 0.0;
        }

        // origin[2] += 18.0;

        set_es(eshandle, ES_Origin, origin);

        // engfunc(EngFunc_SetOrigin, ent, origin);
        // forward_return(FMV_CELL, dllfunc(DLLFunc_AddToFullPack, eshandle, e, ent, host, hostflags, player, pSet));
        
        set_es(eshandle, ES_Solid, SOLID_BBOX);

        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}


public event_pm_move(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
    {
        return HC_CONTINUE;
    }

    // new Float:gametime = get_gametime();

    new button     = get_entvar(id, var_button);
    new oldbuttons = get_entvar(id, var_oldbuttons);

    new just_released = (oldbuttons ^ button) & oldbuttons;

    if ((~just_released & IN_DUCK) || (get_pmove(pm_onground) == -1))
    {
        // if (button & IN_DUCK)
        // {
        //     new Float:duck_time = get_pmove(pm_flDuckTime);
        //     client_print_color(id, print_team_red, "^3[%.2f]^1 duck_time: %s%.3f^1~", gametime, (duck_time >= (1000 - delay)) ? "^3" : "^4", duck_time);
        // }
        return HC_CONTINUE;
    }

    // new bool:duck_pressed = 0 != (get_entvar(id, var_button) & IN_DUCK);
    new bool:in_duck      = 0 != (get_entvar(id, var_bInDuck));
    new bool:is_ducking   = 0 != (get_entvar(id, var_flags) & FL_DUCKING);

    // client_print_color(id, id, "^4[PM_Duck]^1 duck_pressed: ^4%d^1, in_duck: ^4%d^1, is_ducking: ^4%d^1", duck_pressed, in_duck, is_ducking);

    if (in_duck && !is_ducking)
    {
        new Float:duck_time = get_pmove(pm_flDuckTime);
        // client_print_color(id, print_team_red, "^4[%.2f]^1 duck_time: %s%.3f^1", gametime, (duck_time >= (1000 - delay)) ? "^3" : "^4", duck_time);

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
            tmp[0] *= 0.2;
            tmp[1] *= 0.2;

            set_pmove(pm_velocity, tmp);
        }
    }


    return HC_CONTINUE;
}
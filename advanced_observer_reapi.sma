// Note 1: work in progress, I recommend https://github.com/igorkelvin/amxx-plugins#advanced-observer
// Note 2: this plugin only works in latest versions of amxmodx, reapi and regamedll.

#include <amxmodx>
#include <engine>
#include <reapi>
#include <xs>

#define PLUGIN  "Advanced Observer Reapi"
#define VERSION "0.2.2"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PREFIX_CHAT "^4[Advanced Observer]^1"
#define PREFIX_MENU "\y[Advanced Observer]\w"

/* todo
- ~~observer switch to killer;~~
- ~~fix spec bug on GetForceCamera~~
- ~~fix freelook camera position~~
- fix fadetoblack for specs
- ~~observer target C4 holder~~
- ~~observer target C4 entity if no holder~~
- observer grenade camera
- observer doppelganger, copy inputs from another observer
- ~~restrict observer modes~~
- fix observer crosshair
*/

// Note: beware of non-standard bit position, %2 should be on 1-32 range and 
//       not in 0-31 to facilitate playerid manipulation
#define BIT_PL_SET(%1,%2)    ( (%1) |=  (1 << ((%2) - 1)))
#define BIT_PL_CLR(%1,%2)    ( (%1) &= ~(1 << ((%2) - 1)))
#define BIT_PL_XOR(%1,%2)    ( (%1) ^=  (1 << ((%2) - 1)))
#define BIT_PL_IS_SET(%1,%2) ( (%1) &   (1 << ((%2) - 1)))
#define BIT_PL_IS_CLR(%1,%2) (~(%1) &   (1 << ((%2) - 1)))

#define BIT_SET(%1,%2)    ( (%1) |=  (1 << (%2)))
#define BIT_CLR(%1,%2)    ( (%1) &= ~(1 << (%2)))
#define BIT_XOR(%1,%2)    ( (%1) ^=  (1 << (%2)))
#define BIT_IS_SET(%1,%2) ( (%1) &   (1 << (%2)))
#define BIT_IS_CLR(%1,%2) (~(%1) &   (1 << (%2)))

enum _:CameraMode
{
    CAMERA_MODE_SPEC_ANYONE,
    CAMERA_MODE_SPEC_ONLY_TEAM,
    CAMERA_MODE_SPEC_ONLY_FIRST_PERSON
};

enum _:ObserverPreferences
{
    bool:ENABLED,
    OBS_MODES
};
new preferences_default[ObserverPreferences] = 
{
    false,
    (1 << OBS_IN_EYE) | (1 << OBS_ROAMING),
};
new preferences[MAX_PLAYERS + 1][ObserverPreferences];

enum _:ObserverConfigs
{
    ENABLED_BITS,
}
new cfg[ObserverConfigs];

enum _:HookChainIds
{
    HookChain:KILLED_POST,
    HookChain:OBS_SETMODE_POST,
    HookChain:OBS_SETMODE_PRE,
    HookChain:OBS_ISVALIDTARGET,
    HookChain:OBS_FORCECAMERA
    // HookChain:PLANT_BOMB
};
new hooks[HookChainIds];

enum _:Entities
{
    C4
};
new entities[Entities];

enum _:Cvars
{
    FADETOBLACK,
    FORCECHASECAM,
    FORCECAMERA
};
new cvars[Cvars];


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR, URL);

    hooks[KILLED_POST]       = RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
    hooks[OBS_SETMODE_PRE]   = RegisterHookChain(RG_CBasePlayer_Observer_SetMode, "CBasePlayer_Observer_SetMode_Pre");
    hooks[OBS_SETMODE_POST]  = RegisterHookChain(RG_CBasePlayer_Observer_SetMode, "CBasePlayer_Observer_SetMode_Post", true);
    // hooks[PLANT_BOMB]        = RegisterHookChain(RG_PlantBomb, "PlantBomb", true);
    // hooks[OBS_ISVALIDTARGET] = RegisterHookChain(RG_CBasePlayer_Observer_IsValidTarget, "CBasePlayer_Observer_IsValidTarget");
    hooks[OBS_FORCECAMERA] = RegisterHookChain(RG_GetForceCamera, "GetForceCamera");

    bind_pcvar_num(get_cvar_pointer("mp_fadetoblack"),   cvars[FADETOBLACK]);
    bind_pcvar_num(get_cvar_pointer("mp_forcechasecam"), cvars[FORCECHASECAM]);
    bind_pcvar_num(get_cvar_pointer("mp_forcecamera"),   cvars[FORCECAMERA]);

    register_event("ScoreAttrib", "event_pickedthebomb", "bc", "2=2");
    register_logevent("event_droppedthebomb", 3, "2=Dropped_The_Bomb");
    register_logevent("event_plantedthebomb", 3, "2=Planted_The_Bomb");

    register_clcmd("say /obs", "cmd_say_obs");
    register_clcmd("say /c4", "cmd_say_c4");

    for (new i = 1; i <= MAX_PLAYERS; ++i)
    {
        reset_preferences(i);
    }
}

public cmd_say_c4(id)
{
    if (!is_user_connected(id) || BIT_PL_IS_CLR(cfg[ENABLED_BITS], id) || is_user_alive(id) || get_entvar(id, var_iuser1) == OBS_NONE)
    {
        return PLUGIN_HANDLED;
    }

    // client_print(id, print_chat, "entities[C4]: %d", entities[C4]);

    if (!is_entity(entities[C4]))
    {
        return PLUGIN_HANDLED;
    }

    if (is_user_alive(entities[C4]))
    {
        Observer_SetTarget(id, entities[C4]);

        return PLUGIN_HANDLED;
    }
    
    camera_follow_entity(id, entities[C4], .fixangle=1);

    return PLUGIN_HANDLED;
}


public client_disconnected(id)
{
    reset_preferences(id);
    BIT_PL_CLR(cfg[ENABLED_BITS], id);
}


public reset_preferences(id)
{
    new size = sizeof(preferences_default);
    for (new i = 0; i < size; ++i)
    {
        preferences[id][i] = preferences_default[i];
    }
}


public cmd_say_obs(id)
{
    if (!is_user_connected(id))
    {
        return PLUGIN_HANDLED;
    }

    BIT_PL_XOR(cfg[ENABLED_BITS], id);
    client_print_color(id, print_team_red, "%s Advanced Observer is now %s.", PREFIX_CHAT, BIT_PL_IS_SET(cfg[ENABLED_BITS], id) ? "^4enabled^1" : "^3disabled^1");

    return PLUGIN_HANDLED;
}


public event_pickedthebomb()
{
    new id = read_data(1);
  
    if (is_user_alive(id))
    {
      entities[C4] = id;
    }
}


public event_droppedthebomb(id)
{
    set_task(0.1, "event_droppedthebomb_delayed", 25263);
}


public event_droppedthebomb_delayed()
{
    new weapon_c4 = rg_find_ent_by_class(0, "weapon_c4");
  
    if (!weapon_c4)
    {
      entities[C4] = 0;

      return;
    }
  
    new weaponbox = get_entvar(weapon_c4, var_owner);
    if (is_user_connected(weaponbox)) // owner is still a player, not the weaponbox
    {
        entities[C4] = 0;
        set_task(0.1, "event_droppedthebomb_delayed", 25263);

        return;
    }
    
    entities[C4] = weaponbox;
}


public event_plantedthebomb()
{  
    new grenade = -1;
    new bool:grenade_is_c4;
    while((grenade = rg_find_ent_by_class(grenade, "grenade")))
    {
        grenade_is_c4 = get_member(grenade, m_Grenade_bIsC4);
        if (grenade_is_c4)
        {
            break;
        }
    } 
    
    // client_print(0, print_chat, "event_plantedthebomb grenade: %d, grenade_is_c4: %d", grenade, grenade_is_c4)

    if ((grenade <= 0) || !grenade_is_c4)
    {
        return;
    }
    
    entities[C4] = grenade;
}


public CBasePlayer_Observer_SetMode_Pre(id, mode)
{
    if (!is_user_connected(id) || BIT_PL_IS_CLR(cfg[ENABLED_BITS], id))
    {
        return HC_CONTINUE;
    }

    new _mode = mode;
    do
    {
        if (BIT_IS_SET(preferences[id][OBS_MODES], mode))
        {
            break;
        }

        switch (mode)
        {
          case OBS_CHASE_LOCKED: mode = OBS_IN_EYE;
          case OBS_CHASE_FREE:   mode = OBS_IN_EYE;
          case OBS_IN_EYE:       mode = OBS_ROAMING;
          case OBS_ROAMING:      mode = OBS_MAP_FREE;
          case OBS_MAP_FREE:     mode = OBS_MAP_CHASE;
          default:               mode = get_member(id, m_bObserverAutoDirector) ? OBS_CHASE_LOCKED : OBS_CHASE_FREE;
        }
    } while (_mode != mode)

    if (_mode != mode)
    {
        SetHookChainArg(2, ATYPE_INTEGER, mode);
    }

    return HC_CONTINUE;
}


public CBasePlayer_Observer_SetMode_Post(id, mode)
{
    if (!is_user_connected(id) || BIT_PL_IS_CLR(cfg[ENABLED_BITS], id))
    {
        return HC_CONTINUE;
    }

    if (mode != OBS_ROAMING)
    {
        return HC_CONTINUE;
    }

    new target = get_member(id, m_hObserverTarget);
    if (!is_user_alive(target))
    {
        return HC_CONTINUE;
    }

    new Float:eyes[3];
    new Float:tmp[3];

    get_entvar(target, var_origin, eyes);
    get_entvar(target, var_view_ofs, tmp);
    xs_vec_add(eyes, tmp, eyes);
    
    get_entvar(target, var_v_angle, tmp);

    new Float:v_forward[3];
    angle_vector(tmp, ANGLEVECTOR_FORWARD, v_forward);

    eyes[0] += v_forward[0] * 10;
    eyes[1] += v_forward[1] * 10;
    
    entity_set_origin(id, eyes);

    set_entvar(id, var_angles, tmp);
    set_entvar(id, var_v_angle, tmp);
    set_entvar(id, var_fixangle, 1);

    return HC_CONTINUE;
}


public GetForceCamera(id)
{
    new ret;

    if (!cvars[FADETOBLACK])
    {
        ret = (cvars[FORCECHASECAM] == CAMERA_MODE_SPEC_ANYONE) ? cvars[FORCECAMERA] : cvars[FORCECHASECAM];
    }
    else
    {
        ret = CAMERA_MODE_SPEC_ONLY_FIRST_PERSON
    }

    if (ret != CAMERA_MODE_SPEC_ANYONE && (get_member(id, m_iTeam) == CS_TEAM_SPECTATOR))
    {
        ret = CAMERA_MODE_SPEC_ANYONE;
    }

    SetHookChainReturn(ATYPE_INTEGER, ret);
    return HC_SUPERCEDE;
}


public CBasePlayer_Observer_IsValidTarget(id, target, bool:sameteam)
{
    if (id == target || !is_user_connected(target) || !is_user_alive(target))
    {
        return HC_CONTINUE;
    }

    if (get_entvar(target, var_iuser1) != OBS_NONE)
    {
        return HC_CONTINUE;
    }

    if (get_entvar(target, var_effects) & EF_NODRAW)
    {
        return HC_CONTINUE;
    }

    new CsTeams:team_target = get_member(target, m_iTeam);
    if (team_target == CS_TEAM_UNASSIGNED)
    {
        return HC_CONTINUE;
    }

    new CsTeams:team = get_member(id, m_iTeam);
    if (sameteam && (team_target != team && team != CS_TEAM_SPECTATOR))
    {
        return HC_CONTINUE;
    }

    SetHookChainReturn(ATYPE_INTEGER, target);
    return HC_SUPERCEDE;
}


public CBasePlayer_Killed_Post(victim, killer)
{
    if (!is_user_connected(victim) && !is_user_alive(killer))
    {
        return HC_CONTINUE;
    }

    for (new id = 1; id <= MAX_PLAYERS; ++id)
    {
        if (BIT_PL_IS_SET(cfg[ENABLED_BITS], id) && is_user_connected(id) && !is_user_alive(id) && (get_entvar(id, var_iuser1) == OBS_NONE))
        {
            new iuser2 = get_entvar(id, var_iuser2);
            if (iuser2 == victim)
            {
                Observer_SetTarget(id, killer);
            }
        }
    }
    
    return HC_CONTINUE;
}


public Observer_SetTarget(id, target)
{
    if (is_user_connected(id) && is_user_alive(target))
    {
        set_entvar(id, var_iuser1, OBS_IN_EYE);
        set_entvar(id, var_iuser2, target);
        set_member(id, m_hObserverTarget, target);
    }
}

stock camera_follow_entity(id, ent, fixangle=0, Float:distance=200.0, Float:height=60.0)
{
    if (!is_user_connected(id))
    {
        return PLUGIN_CONTINUE;
    }

    set_entvar(id, var_iuser1, OBS_ROAMING);
    set_entvar(id, var_iuser2, 0);
    set_entvar(id, var_iuser3, 0);

    set_member(id, m_iObserverLastMode, OBS_ROAMING);
    set_member(id, m_bWasFollowing, false);

    new Float:ent_origin[3];
    new Float:id_origin[3];
    new Float:angles[3];
    new Float:v_forward[3];
    new Float:fraction;

    get_entvar(ent, var_origin, ent_origin);
    get_entvar(id, var_v_angle, angles);

    angle_vector(angles, ANGLEVECTOR_FORWARD, v_forward);
    xs_vec_copy(ent_origin, id_origin);

    id_origin[0] -= v_forward[0] * distance;
    id_origin[1] -= v_forward[1] * distance;
    id_origin[2] += height;

    trace_line(-1, ent_origin, id_origin, angles);   
    traceresult(TR_Fraction, fraction);

    if (fraction < 1.0)
    {
        id_origin[0] += v_forward[0] * distance * (1 - (fraction * 0.9));
        id_origin[1] += v_forward[1] * distance * (1 - (fraction * 0.9));
    }

    entity_set_origin(id, id_origin);

    if (fixangle)
    {
        xs_vec_sub(ent_origin, id_origin, v_forward);
        vector_to_angle(v_forward, angles);

        angles[0] *= -1.0;

        set_entvar(id, var_angles, angles);
        set_entvar(id, var_angles, angles);
        set_entvar(id, var_fixangle, 1);
    }

    return PLUGIN_HANDLED;
}
#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_stocks>
#include <xs>
#include <fun>

#define MOD_TITLE   "Advanced Observer"
#define MOD_VERSION "0.4.13"
#define MOD_AUTHOR  "lonewolf"

#define DEBUG_ENABLED true

#if DEBUG_ENABLED == true

#define DEBUG(%1) client_print(%1)

#else

#endif /* DEBUG_ENABLED == true */

#define USER_ENABLED(%1)           (camera_enabled_bits & (1 << (%1)-1))
#define IS_CAMERA_GRENADE_SET(%1)  (camera_grenade_bits & (1 << (%1)-1))
#define IS_THIS_GRENADE_C4(%1)     (get_pdata_int((%1), 96) & (1 << 8))
#define IS_THIS_A_POPPED_SMOKE(%1) (get_ent_data((%1), "CGrenade", "m_SGSmoke"))

// https://github.com/s1lentq/ReGameDLL_CS/blob/efb06a7a201829bdbe13218bc5f5342e1f2ed8f1/regamedll/pm_shared/pm_shared.h#L66
#define PM_VEC_DUCK_VIEW     12
#define PM_VEC_VIEW          17

#define TASK_ID_DEBUG 11515

static const FLAG_CLASSNAME[] = "ctf_flag"
static const Float:zeros[3] = {0.0, 0.0, 0.0};
    
static const colors[CsTeams][3] = 
{
  {  0,  0,   0},
  {255, 50,   0},
  {  0, 50, 255},
  {  0,  0,   0},
}

new MSG_ID_SCREENFADE;
new MSG_ID_CROSSHAIR;

new entities_flag[CsTeams];
new entity_c4 = 0;

new player_aimed[MAX_PLAYERS + 1];
new Float:next_action[MAX_PLAYERS + 1];

new bool:player_changed_specmode[MAX_PLAYERS + 1];

new camera_hooked[MAX_PLAYERS + 1];
new camera_grenade_to_follow[MAX_PLAYERS + 1];
new camera_ent_to_follow[MAX_PLAYERS + 1];

new camera_grenade_bits = 0x00000000;
new camera_enabled_bits = 0x00000000;
new camera_debug_bits   = 0x00000000;

public plugin_init()
{
  register_plugin(MOD_TITLE, MOD_VERSION, MOD_AUTHOR)
    
  register_clcmd("say /obs",      "handle_obs");
  register_clcmd("say /obsdebug", "handle_obsdebug");
  
  register_clcmd("+camera_c4",  "camera_ent_c4");
  register_clcmd("-camera_c4",  "camera_ent_unset");
  
  register_clcmd("+camera_flag_red",  "camera_ent_flag_red");
  register_clcmd("-camera_flag_red",  "camera_ent_unset");
  
  register_clcmd("+camera_flag_blue", "camera_ent_flag_blue");
  register_clcmd("-camera_flag_blue", "camera_ent_unset");
  
  register_clcmd("+camera_chase",    "camera_chase_set");
  register_clcmd("-camera_chase",    "camera_chase_unset");
  
  register_clcmd("+camera_hook",     "camera_hook_set");
  register_clcmd("-camera_hook",     "camera_hook_unset");
  
  register_clcmd("+camera_grenade",  "camera_grenade_set");
  register_clcmd("-camera_grenade",  "camera_grenade_unset");
  
  MSG_ID_SCREENFADE = get_user_msgid("ScreenFade");
  MSG_ID_CROSSHAIR  = get_user_msgid("Crosshair");
  
  register_event("ScreenFade", "event_flashed", "b", "7=255");
  
  RegisterHam(Ham_Killed, "player",  "event_player_killed", .Post = true);
  RegisterHam(Ham_Think,  "grenade", "think_grenade"); 
  
  // RegisterHam(Ham_Item_Deploy, "weapon_c4", "update_c4", 1);
  // RegisterHam(Ham_Spawn,       "weaponbox", "weaponbox_spawn", 1);
  
  register_event("ScoreAttrib", "event_pickedthebomb", "bc", "2=2");
  register_logevent("event_droppedthebomb",     3, "2=Dropped_The_Bomb");
  register_logevent("event_plantedthebomb",     3, "2=Planted_The_Bomb");
  // register_logevent("event_spawnedwiththebomb", 3, "2=Spawned_With_The_Bomb");
  
  register_forward(FM_AddToFullPack, "fwd_addtofullpack", 1);
  
  new task_id = 5032;
  set_task(5.0, "task_find_flag_holders", task_id); // delayed
  
  // set_task(1.0, "debug_print", TASK_ID_DEBUG, .flags = "b");
}

public event_pickedthebomb()
{
  new id = read_data(1);
  // DEBUG(0, print_chat, "event_pickedthebomb %d", id);
  
  if (is_user_alive(id))
  {
    entity_c4 = id;
  }
}


// public event_spawnedwiththebomb()
// {
  // DEBUG(0, print_chat, "event_spawnedwiththebomb");
// }

public event_droppedthebomb()
{
  set_task(0.1, "event_droppedthebomb_delayed", 252);
}

public event_droppedthebomb_delayed()
{
  // DEBUG(0, print_chat, "event_droppedthebomb");
  
  new c4_ent = find_ent_by_class(0, "weapon_c4");
  
  if (!c4_ent)
  {
    entity_c4 = 0;
    // DEBUG(0, print_chat, "dC4 not found, %d", c4_ent);
    return;
  }
  
  new weaponbox = entity_get_edict(c4_ent, EV_ENT_owner);
  if (is_user_connected(weaponbox))
  {
    entity_c4 = 0;
    // DEBUG(0, print_chat, "C4 dropped but owner isn't weaponbox", c4_ent);
    set_task(0.1, "event_droppedthebomb_delayed", 252);
    return;
  }
  
  entity_c4 = weaponbox;
  // DEBUG(0, print_chat, "dC4 ent: %d, owner: %d", c4_ent, weaponbox);
}

public event_plantedthebomb()
{
  // DEBUG(0, print_chat, "event_plantedthebomb");
  
  new c4_ent = -1;
  new is_c4 = 0;
  while((c4_ent = find_ent_by_class(c4_ent, "grenade")))
  {
    is_c4 = get_ent_data(c4_ent, "CGrenade", "m_bIsC4");
    // DEBUG(0, print_chat, "grenade, %d %d", c4_ent, is_c4);
    if (is_c4)
    {
      break;
    }
  } 
  
  if ((c4_ent <= 0) || !is_c4)
  {
    // DEBUG(0, print_chat, "C4 not found, %d %d", c4_ent, is_c4);
    return;
  }
  
  entity_c4 = c4_ent;
  // new c4_owner = entity_get_edict(c4_ent, EV_ENT_owner);
  // DEBUG(0, print_chat, "C4 ent: %d, owner: %d", c4_ent, c4_owner);
}


public update_c4(c4_ent)
{
  // new c4_owner = entity_get_edict(c4_ent, EV_ENT_owner);
  // DEBUG(0, print_chat, "C4 ent: %d, owner: %d", c4_ent, c4_owner);
}

public debug_print(id)
{
  if (!camera_debug_bits)
  {
    return;
  }
  
  // for (new id = 1; id < MAX_PLAYERS; ++id)
  // {
    // if (!(camera_debug_bits & (1 << id-1)))
    // {
      // continue;
    // }
    
    // new observer_target       = get_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget");
    // new observer_lastmode     = get_ent_data(id, "CBasePlayer", "m_iObserverLastMode");
    // new observer_wasfollowing = get_ent_data(id, "CBasePlayer", "m_bWasFollowing");
    // new observer_canswitch    = get_ent_data(id, "CBasePlayer", "m_canSwitchObserverModes");
    
    // DEBUG(id, print_chat, "[DEBUG 1/2] target: %d, lastmode: %d, wasfollowing: %s, canswitch: %s", observer_target, observer_lastmode, observer_wasfollowing ? "true" : "false", observer_canswitch ? "true" : "false");
    
    // new iuser1 = entity_get_int(id, EV_INT_iuser1);
    // new iuser2 = entity_get_int(id, EV_INT_iuser2);
    // new iuser3 = entity_get_int(id, EV_INT_iuser3);
    
    // DEBUG(id, print_chat, "[DEBUG 2/2] iuser{1,2,3}: {%d, %d, %d}", iuser1, iuser2, iuser3);
  // }
}

// When entering OBS_ROAMING make observar start pointing to last target's 'v_angle'
public client_cmdStart(id)
{
  if (!is_user_connected(id))
  {
    return;
  }
  
  new buttons    = get_usercmd(usercmd_buttons);
  new oldbuttons = get_user_oldbutton(id);
  
  new pressed = (buttons ^ oldbuttons) & buttons;
  
  if (!(pressed & IN_JUMP))
  {
    return;
  }
  
  new mode = entity_get_int(id, EV_INT_iuser1);
  
  // Next is OBS_ROAMING
  // https://github.com/s1lentq/ReGameDLL_CS/blob/efb06a7a201829bdbe13218bc5f5342e1f2ed8f1/regamedll/dlls/observer.cpp#L215
  if (mode != OBS_IN_EYE)
  {
    return;
  }
  
  new Float:now = get_gametime();
  
  if (now <= next_action[id])
  {
    return;
  }
  
  camera_update_angles(id);
  player_changed_specmode[id] = true;
  
  next_action[id] = now + 0.2;
}


public client_PostThink(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_CONTINUE;
  }
  
  if (player_changed_specmode[id])
  {
    new Float:origin[3];
    entity_get_vector(id, EV_VEC_origin, origin);
    
    new Float:angles[3];
    entity_get_vector(id, EV_VEC_v_angle, angles);
    
    EF_MakeVectors(angles);
    
    new Float:v_forward[3];
    get_global_vector(GL_v_forward, v_forward);
    
    origin[0] += v_forward[0] * 10;
    origin[1] += v_forward[1] * 10;
    
    new is_ducking = get_entity_flags(id) & FL_DUCKING;
    origin[2] += is_ducking ? PM_VEC_DUCK_VIEW : PM_VEC_VIEW;
    
    entity_set_origin(id, origin);
    
    set_observer_crosshair(id, OBS_ROAMING);
  
    player_changed_specmode[id] = false;
  }
  
  new grenade = camera_grenade_to_follow[id];
  new grenade_owner = entity_get_edict(grenade, EV_ENT_owner);
  
  if (!is_valid_ent(grenade) || !is_user_connected(grenade_owner))
  {
    camera_grenade_to_follow[id] = 0;
    
    new ent = camera_ent_to_follow[id];
    
    if (is_valid_ent(ent))
    {
      if (ent == entity_c4)
      {
        camera_follow_c4(id, ent);
      }
      else
      {
        camera_follow_flag(id, ent);
      }
    }
    
    return PLUGIN_CONTINUE;
  }

  // static target_name[32];
  // get_user_name(grenade_owner, target_name, charsmax(target_name));
  
  // DEBUG(1, print_chat, "#%d OWNER: %s[%d]", grenade, target_name, grenade_owner);
  camera_follow_grenade(id, grenade);
  
  return PLUGIN_CONTINUE;
}


public camera_follow_grenade(id, grenade)
{
  new Float:origin[3];
  new Float:spec_origin[3];
  new Float:velocity[3];
  new Float:angles[3];
  
  entity_get_vector(grenade, EV_VEC_origin, origin);
  entity_get_vector(grenade, EV_VEC_velocity, velocity);
  
  new Float:speed = xs_vec_len(velocity);
  
  if (speed < 5.0)
  {
    return PLUGIN_CONTINUE;
  }
  
  xs_vec_copy(origin, spec_origin);
  xs_vec_div_scalar(velocity, -speed, velocity);
  // xs_vec_add_scaled(spec_origin, velocity, 100.0, spec_origin);
  xs_vec_add_scaled(spec_origin, velocity, floatclamp(speed, 50.0, 150.0), spec_origin);
  
  spec_origin[2] += (velocity[2] >= 0.0) ? 32.0 : -32.0;
  
  new trace;
  new Float:fraction;
  
  engfunc(EngFunc_TraceLine, origin, spec_origin, IGNORE_MONSTERS, 0, trace);
  get_tr2(trace, TR_flFraction, fraction);
  
  if (fraction < 1.0)
  {
    get_tr2(trace, TR_vecEndPos, spec_origin);
  }
  
  
  new Float:dir[3];
  xs_vec_sub(origin, spec_origin, dir);
  vector_to_angle(dir, angles);
  angles[0] *= -1.0;
  
  camera_specmode(id, OBS_ROAMING);
  
  entity_set_origin(id, spec_origin);
  
  entity_set_vector(id, EV_VEC_angles, angles);
  entity_set_vector(id, EV_VEC_v_angle, angles);
  entity_set_vector(id, EV_VEC_punchangle, zeros);
  entity_set_int(id, EV_INT_fixangle, 1);
  
  return PLUGIN_HANDLED;
}

// https://github.com/s1lentq/ReGameDLL_CS/blob/6fc1c2ff84b917cc086e664ebd4ab7e18f30a043/regamedll/dlls/client.cpp#L3184
public camera_specmode(id, mode)
{
  new obs_mode = entity_get_int(id, EV_INT_iuser1);
  
  if (obs_mode == mode)
  {
    return;
  }
  
  static mode_string[32];
  num_to_str(mode, mode_string, charsmax(mode_string));
  
  engclient_cmd(id, "specmode", mode_string);
    
  set_observer_crosshair(id, mode);
}

// https://github.com/s1lentq/ReGameDLL_CS/blob/6fc1c2ff84b917cc086e664ebd4ab7e18f30a043/regamedll/dlls/client.cpp#L3213
public camera_follow(id, target)
{
  if (!is_user_alive(target))
  {
    return;
  }
  
  static target_name[32];
  get_user_name(target, target_name, charsmax(target_name));
  
  engclient_cmd(id, "follow", target_name);
}


public camera_update_angles(id)
{
  if (is_user_alive(id))
  {
    return;
  }
  
  new target = entity_get_int(id, EV_INT_iuser2);
  
  if (!is_user_alive(target))
  {
    return;
  }
  
  new Float:angles[3];
  
  entity_get_vector(target, EV_VEC_angles, angles);
  
  angles[0] *= -3.0;
  
  entity_set_vector(id, EV_VEC_angles,     angles);
  entity_set_vector(id, EV_VEC_v_angle,    angles);
  entity_set_vector(id, EV_VEC_punchangle, zeros);
  
  entity_set_int(id, EV_INT_fixangle, 1);
  
}

// Thanks to "Numb / ConnorMcLeod | Wilian M." for "CS Revo: No Flash Team" code
public think_grenade(grenade)
{
  if (!camera_grenade_bits || IS_THIS_GRENADE_C4(grenade) || IS_THIS_A_POPPED_SMOKE(grenade))
  {
    return HAM_IGNORED;
  }

  new grenade_owner = entity_get_edict(grenade, EV_ENT_owner);
  
  if (!is_user_connected(grenade_owner))
  {
    return HAM_IGNORED;
  }
  
  new spectators[32];
  new spectators_count;
  
  get_players(spectators, spectators_count, "bc"); // connected only, dead only, ignore bot
  
  if (spectators_count < 1)
  {
    return HAM_IGNORED;
  }
  
  for (new i = 0; i < spectators_count; ++i)
  {
    new spectator = spectators[i];
    
    if (!IS_CAMERA_GRENADE_SET(spectator))
    {
      continue;
    }
    
    //new target = entity_get_int(spectator, EV_INT_iuser2);
    new target = get_ent_data_entity(spectator, "CBasePlayer", "m_hObserverTarget");
    
    
    if (target == grenade_owner)
    {
      camera_grenade_to_follow[spectator] = grenade;
      // DEBUG(1, print_chat, "camera_grenade_to_follow[%d] (%d) = %d", spectator, IS_CAMERA_GRENADE_SET(spectator), grenade);
    }
  }
  
  //DEBUG 
  // if (!camera_grenade_to_follow[1])
  // {
    // camera_grenade_to_follow[1] = grenade;
  // }
  
  return HAM_HANDLED;
}


public fwd_addtofullpack(es_handle, e, ent, host, hostflags, player, set){
  
  if (is_user_alive(host) || !USER_ENABLED(host) || !player || e != player_aimed[host])
  {
    return FMRES_IGNORED;
  }
  
  new CsTeams:team = cs_get_user_team(e);
  
  set_es(es_handle, ES_RenderFx,    kRenderFxGlowShell);
  set_es(es_handle, ES_RenderColor, colors[team]);
  set_es(es_handle, ES_RenderMode,  kRenderNormal);  
  set_es(es_handle, ES_RenderAmt,   10);
  
  return FMRES_IGNORED;
}

public camera_grenade_set(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  camera_grenade_bits |= (1 << id-1);
  
  return PLUGIN_HANDLED;
}


public camera_grenade_unset(id)
{
  camera_grenade_bits &= ~(1 << id-1);
  camera_grenade_to_follow[id] = 0;
  
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  camera_specmode(id, OBS_IN_EYE);
  
  return PLUGIN_HANDLED;
}


public camera_hook_set(id)
{
  camera_hooked[id] = true;
  
  return PLUGIN_HANDLED;
}


public camera_hook_unset(id)
{
  camera_hooked[id] = false;
  
  return PLUGIN_HANDLED;
}

public client_connect(id)
{
  camera_enabled_bits          &= ~(1 << id-1);
  camera_grenade_bits          &= ~(1 << id-1);
  camera_debug_bits            &= ~(1 << id-1);
  camera_hooked[id]             = false;
  camera_grenade_to_follow[id]  = 0;
  camera_ent_to_follow[id]      = 0;
  player_aimed[id]              = 0;
  next_action[id]               = 0.0;
}


public client_disconnected(id)
{
  camera_enabled_bits          &= ~(1 << id-1);
  camera_grenade_bits          &= ~(1 << id-1);
  camera_debug_bits            &= ~(1 << id-1);
  camera_hooked[id]             = false;
  camera_grenade_to_follow[id]  = 0;
  camera_ent_to_follow[id]      = 0;
  player_aimed[id]              = 0;
  next_action[id]               = 0.0;
}


public task_find_flag_holders(task_id) // jctf_base.sma
{
  new ent = MAX_PLAYERS;
  new flags_found = 0;
  
  while ((ent = find_ent_by_class(ent, FLAG_CLASSNAME)) != 0)
  {
    // DEBUG(1, print_chat, "task_find_flag_holders -> ent = %d", ent);
    new CsTeams:team = CsTeams:entity_get_int(ent, EV_INT_body);
    
    if (team == CS_TEAM_T || team == CS_TEAM_CT)
    {
      entities_flag[team] = ent;
      flags_found++;
    }
  }
  
  // DEBUG(1, print_chat, "task_find_flag_holders -> flags_found == %d", flags_found);
    
  if (flags_found != 2)
  {
    set_task(2.0, "task_find_flag_holders", task_id);
  }
  set_task(0.1, "task_check_spec_aiming", task_id+1, .flags = "b");
}

public task_check_spec_aiming(task_id)
{
  if (!camera_enabled_bits)
  {
    return;
  }
  
  new spectators[32];
  new spectators_count;
  
  get_players(spectators, spectators_count, "bc"); // connected only, dead only, ignore bot
  
  if (spectators_count < 1)
  {
    return;
  }
  
  for (new i = 0; i < spectators_count; ++i)
  {
    new spectator = spectators[i];
    
    if (!(camera_enabled_bits & (1 << spectator-1)))
    {
      continue;
    }
    
    new obs_mode = entity_get_int(spectator, EV_INT_iuser1);
    
    if (obs_mode != OBS_ROAMING)
    {
      player_aimed[spectator] = 0;
      
      continue;
    }
    
    new ent;
    get_user_aiming(spectator, ent, _, 2000);
    
    if (!is_user_alive(ent))
    {
      player_aimed[spectator] = 0;
      continue;
    }
    
    static player_name[32];
    get_user_name(ent, player_name, charsmax(player_name));
    
    new CsTeams:team = cs_get_user_team(ent);
    
    player_aimed[spectator] = ent;
    
    set_hudmessage(colors[team][0], colors[team][1], colors[team][2], -1.0, 0.4, 0, 6.0, 0.1, 0.1, 0.1, -1);
    show_hudmessage(spectator, "[%s]", player_name);
    
    if (camera_hooked[spectator])
    {
      // TODO: Find a way to set "m_hObserverTarget" to player_name. 
      // If "Observer_SetMode" is called without target the function 
      // will make the spectator target a random player.
      //
      // https://github.com/ValveSoftware/halflife/blob/c7240b965743a53a29491dd49320c88eecf6257b/dlls/observer.cpp#L251
      
      
      // DEBUG(spectator, print_chat, "ent: %d", ent);
      // set_ent_data_entity(spectator, "CBasePlayer", "m_hObserverTarget", ent);
      
      set_ent_data_entity(spectator, "CBasePlayer", "m_hObserverTarget", ent);
      camera_specmode(spectator, OBS_IN_EYE);
      camera_follow(spectator, ent);
      // entity_set_int(spectator, EV_INT_iuser2, ent);
      
      
      camera_hooked[spectator] = false;
    }
  }
}

public camera_ent_c4(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  new c4 = entity_c4;
  
  if (!c4)
  {
    return PLUGIN_HANDLED;
  }
  
  camera_ent_to_follow[id] = c4;
  
  return PLUGIN_HANDLED;
}


public camera_ent_flag_red(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  new flag = entities_flag[CS_TEAM_T];
  
  if (!flag)
  {
    // DEBUG(1, print_chat, "camera_flag RED !flag");
    return PLUGIN_HANDLED;
  }
  
  camera_ent_to_follow[id] = flag;
  
  return PLUGIN_HANDLED;
}

public camera_ent_flag_blue(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  new flag = entities_flag[CS_TEAM_CT];
  
  if (!flag)
  {
    // DEBUG(1, print_chat, "camera_flag BLUE !flag");
    return PLUGIN_HANDLED;
  }
  
  camera_ent_to_follow[id] = flag;
  
  return PLUGIN_HANDLED;
}


public camera_ent_unset(id)
{
  camera_ent_to_follow[id] = 0;
}

public camera_follow_c4(id, c4_ent)
{
  if (is_user_alive(c4_ent))
  {
    new holder = c4_ent;
    new spectated = entity_get_int(id, EV_INT_iuser1);
    
    camera_specmode(id, OBS_IN_EYE);
    
    if (spectated != holder)
    {
      camera_follow(id, holder);
    }
    return PLUGIN_HANDLED;
  }
  
  camera_follow_ent(id, c4_ent);
  
  return PLUGIN_HANDLED;
}

public camera_follow_flag(id, flag)
{
  new holder = entity_get_edict(flag, EV_ENT_aiment);
  
  if (is_user_alive(holder)) // 0 is no holder, -1 is dropped
  {
    camera_specmode(id, OBS_IN_EYE);
    
    new spectated = entity_get_int(id, EV_INT_iuser1);
    
    if (spectated != holder)
    {
      camera_follow(id, holder);
    }
    return PLUGIN_HANDLED;
  }
  
  camera_follow_ent(id, flag);
  
  return PLUGIN_HANDLED;
}

public camera_follow_ent(id, ent)
{
  camera_specmode(id, OBS_ROAMING);
  
  new Float:ent_origin[3];
  new Float:player_origin[3];
  new Float:player_angles[3];
  new Float:player_angle_vector[3];
  entity_get_vector(ent, EV_VEC_origin, ent_origin);
  
  xs_vec_copy(ent_origin, player_origin);
  
  entity_get_vector(id, EV_VEC_angles, player_angles);
  
  angle_vector(player_angles, ANGLEVECTOR_FORWARD, player_angle_vector);
  
  player_origin[0] -= player_angle_vector[0] * 200;
  player_origin[1] -= player_angle_vector[1] * 200;
  player_origin[2] += 60;
  
  new trace;
  new Float:fraction;
  
  engfunc(EngFunc_TraceLine, ent_origin, player_origin, IGNORE_MONSTERS, 0, trace);
  get_tr2(trace, TR_flFraction, fraction);
  
  // DEBUG(1, print_chat, "camera_follow_ent -> fraction = %.3f", fraction);
  //DEBUG(1, print_center, "[%.3f, %.3f, %.3f] - [%.3f, %.3f, %.3f]", player_angle_vector[0], player_angle_vector[1], player_angle_vector[2], player_angles[0], player_angles[1], player_angles[2]);
  
  if (fraction < 1.0)
  {
    player_origin[0] += player_angle_vector[0] * 200 * (1 - fraction);
    player_origin[1] += player_angle_vector[1] * 200 * (1 - fraction);
  }
  
  entity_set_origin(id, player_origin);
  
  new Float:pitch = player_angles[0];
  if (pitch <= -10.0 || pitch >= 10.0)
  {
    player_angles[0] = -3.0 * floatclamp(pitch, -10.0, 10.0)
    
    //DEBUG(id, print_chat, "%.3f %.3f", player_angles[0], pitch);
    
    entity_set_vector(id, EV_VEC_angles, player_angles);
    entity_set_vector(id, EV_VEC_v_angle, player_angles);
    entity_set_vector(id, EV_VEC_punchangle, zeros);
    entity_set_int(id, EV_INT_fixangle, 1);
  }
  
  return PLUGIN_HANDLED;
}

public camera_chase_set(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  camera_specmode(id, OBS_CHASE_LOCKED);
  
  return PLUGIN_HANDLED;
}


public camera_chase_unset(id)
{
  
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  camera_specmode(id, OBS_IN_EYE);
  
  return PLUGIN_HANDLED;
}


public handle_obs(id)
{
  camera_enabled_bits ^= (1 << id-1);
  client_print(id, print_chat, "Advanced Observer %s.", camera_enabled_bits & (1 << id-1) ? "enabled" : "disabled");
  
  return PLUGIN_HANDLED;
}


public handle_obsdebug(id)
{
  camera_debug_bits ^= (1 << id-1);
  client_print(id, print_chat, "Advanced Observer DEBUG %s.", camera_debug_bits & (1 << id-1) ? "enabled" : "disabled");
  
  return PLUGIN_HANDLED;
}

// https://github.com/s1lentq/ReGameDLL_CS/blob/efb06a7a201829bdbe13218bc5f5342e1f2ed8f1/regamedll/dlls/observer.cpp#L492

public set_observer_crosshair(id, mode)
{
  message_begin(MSG_ONE, MSG_ID_CROSSHAIR, _, id);
  write_byte(mode == OBS_ROAMING);
  message_end();
}

// Spectator won't be fully blinded for quality of life reasons

public event_flashed(id)
{
  if (is_user_alive(id) || !(camera_enabled_bits & (1 << id-1)))
  {
    return PLUGIN_CONTINUE;
  }
  
  new duration  = read_data(1);
  new hold_time = read_data(2);
  
  message_begin(MSG_ONE_UNRELIABLE, MSG_ID_SCREENFADE, _, id);
  write_short(duration);
  write_short(hold_time);
  write_short(read_data(3));
  write_byte(read_data(4));
  write_byte(read_data(5));
  write_byte(read_data(6));
  write_byte(180);
  message_end();

  static const Float:a = 1.0;
  static const Float:b = 10.0;
  new Float:tmp = (a * duration + b * hold_time) / 4096.0 / (a + b);
  // new Float:tmp = hold_time / 4096.0;
  
  set_hudmessage(200, 50, 0, -1.0, -1.0, 1, tmp, tmp, 0.1, 0.1, -1);
  show_hudmessage(id, "[FLASHED]");
  
  return PLUGIN_CONTINUE;
}

// Thanks @Arkshine and @souvikdas95
// https://forums.alliedmods.net/showthread.php?t=238359&page=2

public event_player_killed(victim, killer)
{ 
  if (!is_user_connected(victim))
  {
    return HAM_IGNORED;
  }
  
  // When player is killed the engine sets "m_canSwitchObserverModes" to false, 
  // and this variable disables the "specmode" command until respawned.
  // https://github.com/s1lentq/ReGameDLL_CS/blob/8d6bf017f5c63efdb83b91b58f51f40c539ff10f/regamedll/dlls/player.cpp#L2017
  // https://github.com/s1lentq/ReGameDLL_CS/blob/6fc1c2ff84b917cc086e664ebd4ab7e18f30a043/regamedll/dlls/client.cpp#L3188
  
  set_ent_data(victim, "CBasePlayer", "m_canSwitchObserverModes", 1);
    
  if (!is_user_alive(killer) || !camera_enabled_bits)
  {
    return HAM_IGNORED;
  }
  
  
  new spectators[32];
  new spectators_count;
  
  get_players(spectators, spectators_count, "bc"); // connected only, dead only, ignore bot
  
  if (spectators_count < 1)
  {
    return HAM_IGNORED;
  }

  for (new i = 0; i < spectators_count; ++i)
  {
    new spectator = spectators[i];
    
    if (!(camera_enabled_bits & (1 << spectator-1)))
    {
      continue;
    }
    
    new spectated = entity_get_int(spectator, EV_INT_iuser2);
    
    if (spectator != victim && spectator != killer && spectated == victim)
    {
      camera_follow(spectator, killer);
    }
  }
  
  return HAM_HANDLED;
}

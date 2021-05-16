// AdvancedObserver by lonewolf <igorkelvin@gmail.com>
// https://github.com/igorkelvin/amxx-plugins

#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_stocks>
#include <xs>

#define MOD_TITLE   "AdvancedObserver"
#define MOD_VERSION "0.5.5"
#define MOD_AUTHOR  "lonewolf"

#define PREFIX "^4[AdvancedObserver]^1"

#define DEBUG_ENABLED true

#if DEBUG_ENABLED == true
#define DEBUG(%1) client_print(%1)
#else
#endif /* DEBUG_ENABLED == true */

#define USER_ENABLED(%1)           (camera_enabled_bits & (1 << (%1)-1))
#define IS_CAMERA_GRENADE_SET(%1)  (camera_grenade_bits & (1 << (%1)-1))
#define IS_THIS_GRENADE_C4(%1)     (get_ent_data((%1), "CGrenade", "m_bIsC4"))
#define IS_THIS_A_POPPED_SMOKE(%1) (get_ent_data((%1), "CGrenade", "m_SGSmoke"))

// https://github.com/s1lentq/ReGameDLL_CS/blob/efb06a7a201829bdbe13218bc5f5342e1f2ed8f1/regamedll/pm_shared/pm_shared.h#L66
#define PM_VEC_DUCK_VIEW     12
#define PM_VEC_VIEW          17

#define TASK_ID_DEBUG     11515
#define TASK_ID_FAKEINPUT 47653
enum
{
  CAMERA_MODE_SPEC_ANYONE = 0,
  CAMERA_MODE_SPEC_ONLY_TEAM,      
  CAMERA_MODE_SPEC_ONLY_FIRST_PERSON
};

static const FLAG_CLASSNAME[] = "ctf_flag";
static const Float:zeros[3] = {0.0, 0.0, 0.0};
    
static const colors[CsTeams][3] = 
{
  {  0,  0,   0},
  {255, 50,   0},
  {  0, 50, 255},
  {  0,  0,   0},
};

new MSG_ID_SCREENFADE;
new MSG_ID_CROSSHAIR;

new entities_flag[CsTeams];
new entity_c4 = 0;

new Float:next_action[MAX_PLAYERS+1];
new player_aimed[MAX_PLAYERS+1];

new bool:player_fixangle[MAX_PLAYERS+1];

enum Direction
{
  NO_DIRECTION = 0,
  RIGHT,
  LEFT,
  FORWARD,
  BACK
};

enum Entities
{
  NO_ENTITY = 0,
  C4,
  FLAG_RED,
  FLAG_BLUE
};

new Entities:player_follow[MAX_PLAYERS+1];
new bool:player_follow_once[MAX_PLAYERS+1];

new camera_hooked[MAX_PLAYERS + 1];
new camera_grenade_to_follow[MAX_PLAYERS+1];
new camera_ent_to_follow[MAX_PLAYERS+1];

new camera_grenade_bits = 0x00000000;
new camera_enabled_bits = 0x00000000;
new camera_debug_bits   = 0x00000000;

new hudsync1;

new menuid_fakeinput;

public plugin_init()
{
  register_plugin(MOD_TITLE, MOD_VERSION, MOD_AUTHOR)
  
  register_clcmd("say /obs",      "cmd_obs");
  register_clcmd("say /obsdebug", "cmd_obsdebug", ADMIN_CVAR);
  
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

  register_clcmd("say /debug",  "debug_print", ADMIN_CVAR);
  
  MSG_ID_SCREENFADE = get_user_msgid("ScreenFade");
  MSG_ID_CROSSHAIR  = get_user_msgid("Crosshair");
  
  register_event("ScreenFade", "event_flashed", "b", "7=255");
  
  RegisterHam(Ham_Spawn,  "player",  "event_player_spawned", .Post = true);
  RegisterHam(Ham_Killed, "player",  "event_player_killed",  .Post = true);
  RegisterHam(Ham_Think,  "grenade", "think_grenade"); 

  register_event("TeamInfo", "event_player_joined_team", "a");
  
  register_event("ScoreAttrib", "event_pickedthebomb", "bc", "2=2");
  register_logevent("event_droppedthebomb", 3, "2=Dropped_The_Bomb");
  register_logevent("event_plantedthebomb", 3, "2=Planted_The_Bomb");

  hudsync1 = CreateHudSyncObj();

  menuid_fakeinput = register_menuid("fakeinput");
  register_menucmd(menuid_fakeinput, 1023, "menu_fakeinput_handler");
  
  new task_id = 5032;
  set_task(5.0, "task_find_flag_holders", task_id);
  
}

public event_pickedthebomb()
{
  new id = read_data(1);
  
  if (is_user_alive(id))
  {
    entity_c4 = id;
  }
}

public event_droppedthebomb()
{
  set_task(0.1, "event_droppedthebomb_delayed", 252);
}


public event_droppedthebomb_delayed()
{
  new c4_ent = find_ent_by_class(0, "weapon_c4");
  
  if (!c4_ent)
  {
    entity_c4 = 0;
    return;
  }
  

  new weaponbox = entity_get_edict(c4_ent, EV_ENT_owner);
  if (is_user_connected(weaponbox))
  {
    entity_c4 = 0;
    set_task(0.1, "event_droppedthebomb_delayed", 252);
    return;
  }
  
  entity_c4 = weaponbox;
}

public event_plantedthebomb()
{  
  new c4_ent = -1;
  new is_c4 = 0;
  while((c4_ent = find_ent_by_class(c4_ent, "grenade")))
  {
    is_c4 = IS_THIS_GRENADE_C4(c4_ent);
    if (is_c4)
    {
      break;
    }
  } 
  
  if ((c4_ent <= 0) || !is_c4)
  {
    return;
  }
  
  entity_c4 = c4_ent;
}


public debug_print(id)
{
  if (!camera_debug_bits)
  {
    return;
  }
  
  for (new id = 1; id < MAX_PLAYERS; ++id)
  {
    if (!(camera_debug_bits & (1 << id-1)))
    {
      continue;
    }
    
    new observer_target       = get_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget");
    new observer_lastmode     = get_ent_data(id, "CBasePlayer", "m_iObserverLastMode");
    new observer_wasfollowing = get_ent_data(id, "CBasePlayer", "m_bWasFollowing");
    new observer_canswitch    = get_ent_data(id, "CBasePlayer", "m_canSwitchObserverModes");
    
    DEBUG(id, print_chat, "[DEBUG 1/2] target: %d, lastmode: %d, wasfollowing: %s, canswitch: %s", observer_target, observer_lastmode, observer_wasfollowing ? "true" : "false", observer_canswitch ? "true" : "false");
    
    new iuser1 = entity_get_int(id, EV_INT_iuser1);
    new iuser2 = entity_get_int(id, EV_INT_iuser2);
    new iuser3 = entity_get_int(id, EV_INT_iuser3);
    
    DEBUG(id, print_chat, "[DEBUG 2/2] iuser{1,2,3}: {%d, %d, %d}", iuser1, iuser2, iuser3);
  }
}


public client_cmdStart(id)
{
  if (is_user_alive(id) || !USER_ENABLED(id))
  {
    return PLUGIN_CONTINUE;
  }
  
  new buttons    = get_usercmd(usercmd_buttons);
  new oldbuttons = get_user_oldbutton(id);
  new pressed    = (buttons ^ oldbuttons) & buttons;
  new released   = (buttons ^ oldbuttons) & oldbuttons;
  
  if (released & IN_RELOAD)
  {
    camera_grenade_unset(id);
  }

  if (!(pressed & (IN_JUMP | IN_ATTACK | IN_ATTACK2 | IN_RELOAD | IN_MOVELEFT | IN_MOVERIGHT | IN_BACK | IN_FORWARD)))
  {
    return PLUGIN_CONTINUE;
  }
  
  new Float:now = get_gametime();
  
  if (now < next_action[id])
  {
    return PLUGIN_CONTINUE;
  }
  
  next_action[id] = now + 0.1;
  
  // Disable default observer inputs
  // TODO: find a good forward to set this just one time
  set_ent_data_float(id, "CBasePlayer", "m_flNextObserverInput", get_gametime() + 1337.0);

  if (pressed & IN_JUMP)
  {
    next_spec_mode(id);
  }
  else if (pressed & IN_ATTACK)
  {
    new obs_mode = entity_get_int(id, EV_INT_iuser1);
    if (obs_mode == OBS_ROAMING)
    {
      new closest = observer_find_next_player_direction(id, FORWARD, 2000.0, _, .target=id);
      if (closest)
      {
        observer_set_mode(id, OBS_IN_EYE);
      }
    }
    else
    {
      observer_find_next_player(id, .reverse=false);
    }
  }
  else if (pressed & IN_ATTACK2)
  {
    new obs_mode = entity_get_int(id, EV_INT_iuser1);
    if (obs_mode == OBS_ROAMING)
    {
      new closest = observer_find_next_player_direction(id, BACK, 2000.0, _, .target=id);
      if (closest)
      {
        observer_set_mode(id, OBS_IN_EYE);
      }
    }
    else
    {
      observer_find_next_player(id, .reverse=true);
    }
  }
  else if (pressed & IN_RELOAD)
  {
    camera_grenade_set(id);
  }
  else 
  {
    new obs_mode = entity_get_int(id, EV_INT_iuser1);
    if (obs_mode != OBS_ROAMING)
    {
      if (pressed & IN_MOVERIGHT)
      {
        observer_find_next_player_direction(id, RIGHT, .maxdistance=2000.0);
      }
      else if (pressed & IN_MOVELEFT)
      {
        observer_find_next_player_direction(id, LEFT, .maxdistance=2000.0);
      }
      else if (pressed & IN_FORWARD)
      {
        observer_find_next_player_direction(id, FORWARD, .maxdistance=2000.0);
      }
      else if (pressed & IN_BACK)
      {
        observer_find_next_player_direction(id, BACK, .maxdistance=2000.0);
      }
    }
  }

  return PLUGIN_CONTINUE;
}

public next_spec_mode(id)
{
  new mode = entity_get_int(id, EV_INT_iuser1);
  new nextmode;
  switch (mode)
  {
    case OBS_CHASE_LOCKED: nextmode = OBS_IN_EYE;
    case OBS_CHASE_FREE:   nextmode = OBS_IN_EYE;
    case OBS_IN_EYE:       nextmode = OBS_ROAMING;
    case OBS_ROAMING:      nextmode = OBS_IN_EYE;
    case OBS_MAP_FREE:     nextmode = OBS_IN_EYE;
    default:               nextmode = OBS_IN_EYE;
  }
  
  observer_set_mode(id, nextmode);
}

stock observer_find_next_player(id, reverse=false, target=0, CsTeams:force_team=CS_TEAM_UNASSIGNED)
{
  new CsTeams:team = cs_get_user_team(id);
  new bool:same_team = get_force_camera() != CAMERA_MODE_SPEC_ANYONE && team != CS_TEAM_SPECTATOR;
  
  new newtarget = 0;

  if (target)
  {
    newtarget = observer_is_valid_target(id, target, same_team, force_team);
  }
  else
  {
    new dir = reverse ? -1 : 1;
    new current = get_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget");
    new start = current;

    do
    {  
      current += dir;
      if (current >= MaxClients)
      {
        current = 1;
      }
      else if (current < 1)
      {
        current = MaxClients;
      }
      newtarget = observer_is_valid_target(id, current, same_team, force_team);
      if (newtarget)
      {
        break;
      }
    } 
    while (current != start)
  }

  if (newtarget)
  {
    camera_move_to_eyes(id);
    set_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget", newtarget);
    
    new mode = entity_get_int(id, EV_INT_iuser1);
    if (mode != OBS_ROAMING)
    {
      entity_set_int(id, EV_INT_iuser2, newtarget);
    }
  }

  ClearSyncHud(id, hudsync1);
  return newtarget;
}

stock observer_find_next_player_direction(id, Direction:dir, Float:maxdistance = 500.0, CsTeams:force_team=CS_TEAM_UNASSIGNED, target=0)
{
  new current = target;
  if (!is_user_connected(target))
  {
    current = get_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget");
  
    if (!is_valid_ent(current))
    {
      return 0;
    } 
  }

  new Float:id_origin[3];
  entity_get_vector(current, EV_VEC_origin, id_origin);

  new Float:angles[3];
  entity_get_vector(current, EV_VEC_v_angle, angles)
  
  angles[0] = 0.0;
  angles[2] = 0.0;

  EF_MakeVectors(angles);

  new Float:closest_distance = 9999.9;
  new closest = 0;

  new Float:direction[3];
  switch (dir)
  {
    case NO_DIRECTION:
    {
      return closest;
    }
    case RIGHT:
    {
      get_global_vector(GL_v_right, direction);
    }
    case LEFT:
    {
      get_global_vector(GL_v_right, direction);
      xs_vec_neg(direction, direction);
    }
    case FORWARD:
    {
      get_global_vector(GL_v_forward, direction);
    }
    case BACK:
    {
      get_global_vector(GL_v_forward, direction);
      xs_vec_neg(direction, direction);
    }
  }

  new CsTeams:team = cs_get_user_team(id);
  new bool:same_team = get_force_camera() != CAMERA_MODE_SPEC_ANYONE && team != CS_TEAM_SPECTATOR;

  for (new target = 1; target <= MaxClients; ++target)
  {
    if (id == target || target == current || !is_user_alive(target))
    {
      continue;
    }

    target = observer_is_valid_target(id, target, same_team, force_team);

    if (!target)
    {
      continue;
    }
    
    new Float:target_origin[3];
    entity_get_vector(target, EV_VEC_origin, target_origin);

    target_origin[2] *= 2.0; // Prioritize targets in the same height
    new Float:distance = xs_vec_distance(id_origin, target_origin);
    target_origin[2] *= 0.5;

    if (distance > maxdistance || distance > closest_distance)
    {
      continue;
    }

    xs_vec_sub(target_origin, id_origin, target_origin);
    xs_vec_normalize(target_origin, target_origin);
    
    new Float:cosine = xs_vec_dot(target_origin, direction);
    new Float:angle = floatacos(cosine, degrees);
    
    if (angle <= 45.0)
    {
      closest_distance = distance;
      closest = target;
    }
  }

  if (closest)
  {
    camera_move_to_eyes(id);
    set_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget", closest);
    
    new mode = entity_get_int(id, EV_INT_iuser1);
    if (mode != OBS_ROAMING)
    {
      entity_set_int(id, EV_INT_iuser2, closest);
    }
  }

  ClearSyncHud(id, hudsync1);
  return closest;
}

public get_force_camera()
{
  new ret;
  new fadetoblack = get_cvar_num("mp_fadetoblack");

  if (!fadetoblack)
  {
    ret = get_cvar_num("mp_forcechasecam");
    if (ret == CAMERA_MODE_SPEC_ANYONE)
    {
      ret = get_cvar_num("mp_forcecamera");
    }
  }
  else 
  {
    ret = CAMERA_MODE_SPEC_ONLY_FIRST_PERSON;
  }

  return ret;
}


stock observer_is_valid_target(id, target, bool:same_team=false, CsTeams:team=CS_TEAM_UNASSIGNED)
{
  if (id == target || !is_user_alive(target))
  {
    return 0;
  }

  new obs_mode = entity_get_int(target, EV_INT_iuser1);
  new effects  = entity_get_int(target, EV_INT_effects);

  new CsTeams:team_target = cs_get_user_team(target);
  new CsTeams:team_id     = cs_get_user_team(id);

  new bool:is_observer         = (obs_mode != OBS_NONE);
  new bool:cannot_see_entities = bool:(effects & EF_NODRAW);
  new bool:not_playing         = (team_target != CS_TEAM_T && team_target != CS_TEAM_CT);
  new bool:not_in_same_team    = (same_team && (team_target != team_id && team_id != CS_TEAM_SPECTATOR));
  new bool:not_in_wanted_team  = (team && (team_target != team));

  if (is_observer || cannot_see_entities || not_playing || not_in_same_team || not_in_wanted_team)
  {
    return 0;
  }

  return target;
}

public client_PostThink(id)
{
  if (is_user_alive(id) || !USER_ENABLED(id))
  {
    return PLUGIN_CONTINUE;
  }
    
  new grenade = camera_grenade_to_follow[id];

  if (is_valid_ent(grenade))
  {
    new grenade_owner = entity_get_edict(grenade, EV_ENT_owner);
    if (is_user_connected(grenade_owner))
    {
      camera_follow_grenade(id, grenade);
    }

    return PLUGIN_CONTINUE;
  }
  else 
  {
    camera_grenade_to_follow[id] = 0;
    
    new Entities:follow = player_follow[id];

    switch (follow)
    {
      case NO_ENTITY: {}
      case C4:        camera_follow_c4(id);
      case FLAG_RED:  camera_follow_flag(id, follow);
      case FLAG_BLUE: camera_follow_flag(id, follow);
    }

    if (follow && player_follow_once[id])
    {
      player_follow[id] = NO_ENTITY;
    }
  }

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
  xs_vec_div_scalar(velocity, speed, velocity);

  // https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/dlls/wpn_shared/wpn_flashbang.cpp#L191
  // Max grenade speed should be 750
  speed = 100 + 0.2 * speed;

  xs_vec_add_scaled(spec_origin, velocity, -1.0 * speed, spec_origin);
  
  spec_origin[2] += 10.0;

  new trace;
  new Float:fraction;
  
  engfunc(EngFunc_TraceLine, origin, spec_origin, IGNORE_MONSTERS, 0, trace);
  get_tr2(trace, TR_flFraction, fraction);
  
  if (fraction < 1.0)
  {
    spec_origin[0] += velocity[0] * speed * (1 - (fraction * 0.8));
    spec_origin[1] += velocity[1] * speed * (1 - (fraction * 0.8));
    spec_origin[2] += velocity[2] * speed * (1 - (fraction * 0.8));
  }
  
  new Float:dir[3];
  xs_vec_sub(origin, spec_origin, dir);
  vector_to_angle(dir, angles);
  angles[0] *= -1.0;
  
  observer_set_mode(id, OBS_ROAMING);
  
  entity_set_origin(id, spec_origin);
  
  entity_set_vector(id, EV_VEC_angles, angles);
  entity_set_vector(id, EV_VEC_v_angle, angles);
  entity_set_vector(id, EV_VEC_punchangle, zeros);
  entity_set_int(id, EV_INT_fixangle, 1);
  
  return PLUGIN_HANDLED;
}

public observer_set_mode(id, mode)
{
  if (!is_user_connected(id))
  {
    return;
  }

  new old_mode = entity_get_int(id, EV_INT_iuser1);
  if (old_mode == mode)
  {
    return;
  }

  new forcecamera = get_force_camera();
  new CsTeams:team = cs_get_user_team(id);

  if (team != CS_TEAM_SPECTATOR)
  {
    if (forcecamera == CAMERA_MODE_SPEC_ONLY_TEAM)
    {
      if (mode == OBS_ROAMING)
      {
        mode = OBS_MAP_FREE; // is this correct?
      }
    }
    else if (forcecamera == CAMERA_MODE_SPEC_ONLY_FIRST_PERSON)
    {
      mode = OBS_IN_EYE;
    }
  }

  new target = get_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget");

  if (target)
  {
    target = observer_is_valid_target(id, target);
  }

  entity_set_int(id, EV_INT_iuser1, mode);

  if (mode == OBS_ROAMING)
  {
    target = 0;
  }
  else
  {
    if (!target)
    {
      target = observer_find_next_player(id);

      if (!target)
      {
        mode = OBS_ROAMING;
        entity_set_int(id, EV_INT_iuser1, OBS_ROAMING);
      }
    }
  }

  entity_set_int(id, EV_INT_iuser2, target);
  entity_set_int(id, EV_INT_iuser3, 0);

  camera_move_to_eyes(id);
  set_observer_crosshair(id, mode);

  set_ent_data(id, "CBasePlayer", "m_iObserverLastMode", mode);
  set_ent_data(id, "CBasePlayer", "m_bWasFollowing", 0);

  ClearSyncHud(id, hudsync1);
}

public camera_move_to_eyes(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_CONTINUE;
  }

  new target = get_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget");
  if (!is_user_alive(target))
  {
    return PLUGIN_CONTINUE;
  }

  new Float:eyes[3];
  new Float:view_ofs[3];
  entity_get_vector(target, EV_VEC_origin, eyes);
  entity_get_vector(target, EV_VEC_view_ofs, view_ofs);
  xs_vec_add(eyes, view_ofs, eyes);

  new Float:angles[3];
  entity_get_vector(target, EV_VEC_v_angle, angles);
  
  EF_MakeVectors(angles);
  
  new Float:v_forward[3];
  get_global_vector(GL_v_forward, v_forward);
  
  eyes[0] += v_forward[0] * 10;
  eyes[1] += v_forward[1] * 10;
  
  entity_set_origin(id, eyes);

  // angles[0] *= -3.0;
  
  entity_set_vector(id, EV_VEC_angles,     angles);
  entity_set_vector(id, EV_VEC_v_angle,    angles);
  entity_set_vector(id, EV_VEC_punchangle, zeros);
  
  entity_set_int(id, EV_INT_fixangle, 1);

  
  return PLUGIN_CONTINUE;  
}

// Thanks to "Numb / ConnorMcLeod | Wilian M." for "CS Revo: No Flash Team" code
public think_grenade(grenade)
{
  if (!camera_grenade_bits || !camera_enabled_bits || IS_THIS_GRENADE_C4(grenade) || IS_THIS_A_POPPED_SMOKE(grenade))
  {
    return HAM_IGNORED;
  }

  new grenade_owner = entity_get_edict(grenade, EV_ENT_owner);
  
  if (!is_user_connected(grenade_owner))
  {
    return HAM_IGNORED;
  }
  
  for (new id = 1; id <= MaxClients; ++id)
  {
    if (!IS_CAMERA_GRENADE_SET(id) || is_user_alive(id))
    {
      continue;
    }
    
    new target = get_ent_data_entity(id, "CBasePlayer", "m_hObserverTarget");
    
    if (target == grenade_owner)
    {
      camera_grenade_to_follow[id] = grenade;
    }
  }

  return HAM_HANDLED;
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
  
  observer_set_mode(id, OBS_IN_EYE);
  
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
  camera_enabled_bits &= ~(1 << id-1);
  camera_grenade_bits &= ~(1 << id-1);
  camera_debug_bits   &= ~(1 << id-1);
  
  camera_hooked[id]            = false;
  camera_grenade_to_follow[id] = 0;
  camera_ent_to_follow[id]     = 0;
  
  player_follow_once[id] = false;
  player_aimed[id]  = 0;
  next_action[id]   = 0.0;
  player_follow[id] = NO_ENTITY;
}


public client_disconnected(id)
{
  camera_enabled_bits &= ~(1 << id-1);
  camera_grenade_bits &= ~(1 << id-1);
  camera_debug_bits   &= ~(1 << id-1);
  
  camera_hooked[id]            = false;
  camera_grenade_to_follow[id] = 0;
  camera_ent_to_follow[id]     = 0;
  
  player_follow_once[id] = false;
  player_aimed[id]  = 0;
  next_action[id]   = 0.0;
  player_follow[id] = NO_ENTITY;
}


public task_find_flag_holders(task_id) // jctf_base.sma
{
  new ent = MAX_PLAYERS;
  new flags_found = 0;
  
  while ((ent = find_ent_by_class(ent, FLAG_CLASSNAME)) != 0)
  {
    new CsTeams:team = CsTeams:entity_get_int(ent, EV_INT_body);
    
    if (team == CS_TEAM_T || team == CS_TEAM_CT)
    {
      // DEBUG(1, print_chat, "task_find_flag_holders -> ent = %d, team = %d", ent, team);
      entities_flag[team] = ent;
      flags_found++;
    }
  }
  
  // DEBUG(1, print_chat, "task_find_flag_holders -> flags_found == %d", flags_found);
    
  if (flags_found != 2)
  {
    set_task(2.0, "task_find_flag_holders", task_id);
  }
  set_task(0.5, "task_check_spec_aiming", task_id+1, .flags = "b");
}

public task_check_spec_aiming(task_id)
{
  if (!camera_enabled_bits)
  {
    return;
  }
  
  for (new id = 1; id <= MaxClients; ++id)
  {
    if (!USER_ENABLED(id) || is_user_alive(id))
    {
      continue;
    }
    
    new obs_mode = entity_get_int(id, EV_INT_iuser1);
    
    if (obs_mode != OBS_ROAMING)
    {
      player_aimed[id] = 0;
      
      continue;
    }
    
    new ent;
    get_user_aiming(id, ent, _, 2000);
    
    if (!is_user_alive(ent))
    {
      player_aimed[id] = 0;
      continue;
    }
    
    static player_name[32];
    get_user_name(ent, player_name, charsmax(player_name));
    
    new CsTeams:team = cs_get_user_team(ent);
    new health = floatround(entity_get_float(ent, EV_FL_health) / entity_get_float(ent, EV_FL_max_health) * 100);

    player_aimed[id] = ent;
    
    new const team_names[CsTeams][] = {"", "TR", "CT", "SPECTATOR"};

    set_hudmessage(colors[team][0], colors[team][1], colors[team][2], -1.0, 0.52, 0, 6.0, 0.5, 0.0, 0.0, -1);
    ShowSyncHudMsg(id, hudsync1, "%s: %s^nHealth: %d%%", team_names[team], player_name, health);
    
    if (camera_hooked[id])
    {
      observer_set_mode(id, OBS_IN_EYE);
      observer_find_next_player(id, _, ent);
      camera_hooked[id] = false;
    }
  }
}

public camera_ent_c4(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  player_follow[id] = C4;
  player_fixangle[id] = true;
  
  return PLUGIN_HANDLED;
}


public camera_ent_flag_red(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  player_follow[id] = FLAG_RED;
  player_fixangle[id] = true;
  
  return PLUGIN_HANDLED;
}

public camera_ent_flag_blue(id)
{
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  player_follow[id] = FLAG_BLUE;
  player_fixangle[id] = true;
  
  return PLUGIN_HANDLED;
}


public camera_ent_unset(id)
{
  player_follow[id]   = NO_ENTITY;
  player_fixangle[id] = false;
}

public camera_follow_c4(id)
{
  if (!is_valid_ent(entity_c4))
  {
    return PLUGIN_CONTINUE;
  }

  if (is_user_alive(entity_c4))
  {
    new holder = entity_c4;
    
    observer_set_mode(id, OBS_IN_EYE);
    observer_find_next_player(id, _, holder);
    
    return PLUGIN_HANDLED;
  }
  
  camera_follow_ent(id, entity_c4, player_fixangle[id]);
  player_fixangle[id] = false;

  return PLUGIN_HANDLED;
}

public camera_follow_flag(id, Entities:type)
{
  new flag;

  if (type == FLAG_RED)
  {
    flag = entities_flag[CS_TEAM_T];
  }
  else
  {
    flag = entities_flag[CS_TEAM_CT];
  }

  if (!is_valid_ent(flag))
  {
    return PLUGIN_CONTINUE;
  }

  new holder = entity_get_edict(flag, EV_ENT_aiment);
  
  if (is_user_alive(holder)) // 0 is no holder, -1 is dropped
  {
    observer_set_mode(id, OBS_IN_EYE);
    
    new spectated = entity_get_int(id, EV_INT_iuser1);
    
    if (spectated != holder)
    {
      observer_find_next_player(id, _, holder);
    }
    return PLUGIN_HANDLED;
  }
  
  camera_follow_ent(id, flag, player_fixangle[id], 200.0, 60.0, Float:{0.0, 0.0, 45.0});
  player_fixangle[id] = false;

  return PLUGIN_HANDLED;
}

camera_follow_ent(id, ent, fixangle=0, Float:distance=200.0, Float:height=60.0, Float:offset[3]={0.0, 0.0, 0.0})
{
  observer_set_mode(id, OBS_ROAMING);
  
  new Float:ent_origin[3];
  new Float:player_origin[3];
  new Float:player_angles[3];
  new Float:v_forward[3];
  entity_get_vector(ent, EV_VEC_origin, ent_origin);
  xs_vec_add(ent_origin, offset, ent_origin);

  xs_vec_copy(ent_origin, player_origin);
  entity_get_vector(id, EV_VEC_v_angle, player_angles);

  angle_vector(player_angles, ANGLEVECTOR_FORWARD, v_forward);
  
  player_origin[0] -= v_forward[0] * distance;
  player_origin[1] -= v_forward[1] * distance;
  player_origin[2] += height;
  
  new trace;
  new Float:fraction;
  
  engfunc(EngFunc_TraceLine, ent_origin, player_origin, IGNORE_MONSTERS, 0, trace);
  get_tr2(trace, TR_flFraction, fraction);
  
  if (fraction < 1.0)
  {
    player_origin[0] += v_forward[0] * distance * (1 - (fraction * 0.9));
    player_origin[1] += v_forward[1] * distance * (1 - (fraction * 0.9));
  }
  
  entity_set_origin(id, player_origin);
  
  if (fixangle)
  {
    new Float:dir[3];
    xs_vec_sub(ent_origin, player_origin, dir);
    vector_to_angle(dir, player_angles);
    
    player_angles[0] *= -1.0;
    
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
  
  observer_set_mode(id, OBS_CHASE_LOCKED);
  
  return PLUGIN_HANDLED;
}


public camera_chase_unset(id)
{
  
  if (is_user_alive(id))
  {
    return PLUGIN_HANDLED;
  }
  
  observer_set_mode(id, OBS_IN_EYE);
  
  return PLUGIN_HANDLED;
}

public event_player_spawned(id)
{
  if (!is_user_connected(id) || !USER_ENABLED(id))
  {
    return;
  }

  cmd_obs(id);
  // client_print_color(id, print_team_grey, "%s Those features are only available to ^3Spectators^1.", PREFIX);
}


public event_player_joined_team()
{
  new id = read_data(1);
  if (!is_user_connected(id) || !USER_ENABLED(id))
  {
    return;
  }

  new team[2];
  read_data(2, team, charsmax(team))

  if (team[0] != 'S' && cs_get_user_team(id) != CS_TEAM_SPECTATOR)
  {
    cmd_obs(id);
    // client_print_color(id, print_team_grey, "%s Observer features are only available to ^3Spectators^1.", PREFIX);
  }
}


public task_fakeinput()
{
  static menu;
  static newmenu;
  static page;
  
  for (new id = 1; id <= MaxClients; id++)
  {
    if (!is_user_connected(id) || !USER_ENABLED(id))
    {
      continue;
    }

    player_menu_info(id, menu, newmenu, page);
    // DEBUG(id, print_chat, "(print_menu) (%02d) ret: %d, newmenu: %d, menu: %d", 1, ret, newmenu, menu);

    if (newmenu == -1 && menu <= 0)
    {
      menu_fakeinput(5234 + id);
    }
  }
}


public menu_fakeinput(id)
{
  id -= 5234;

  if (is_user_connected(id) && !is_user_alive(id) && USER_ENABLED(id))
  {
    show_menu(id, 1023, " ", _, "fakeinput");
  }

  return PLUGIN_HANDLED;
}

public menu_fakeinput_handler(id, key)
{
  if (!is_user_connected(id) || is_user_alive(id) || !USER_ENABLED(id))
  {
    return PLUGIN_HANDLED;
  }

  key = (key + 1);
  new slotcmd[7];
  formatex(slotcmd, charsmax(slotcmd), "slot%d", key);

  //client_print(id, print_chat, "(menu_fakeinput_handler) (%02d) selected '%s'", id, slotcmd);

  switch (key)
  {
    case 1: 
    {
      observer_set_mode(id, OBS_IN_EYE);
      observer_find_next_player(id, _, _, CS_TEAM_T);
    }
    case 2: 
    {
      observer_set_mode(id, OBS_IN_EYE);
      observer_find_next_player(id, _, _, CS_TEAM_CT);
    }
    case 5:
    {
      camera_ent_c4(id);
      player_follow_once[id] = true;
    }
    case 6:
    {
      camera_ent_flag_red(id);
      player_follow_once[id] = true;
    }
    case 7:
    {
      camera_ent_flag_blue(id);
      player_follow_once[id] = true;
    }
  }

  // client_cmd(id, slotcmd);
  set_task(0.1, "menu_fakeinput", 5234 + id);

  return PLUGIN_HANDLED;
}

public cmd_obs(id)
{
  if (!is_user_connected(id))
  {
    return PLUGIN_HANDLED;
  }

  if (is_user_alive(id) || cs_get_user_team(id) != CS_TEAM_SPECTATOR)
  {
    camera_enabled_bits &= ~(1 << (id-1));
    client_print_color(id, print_team_grey, "%s Observer features are only available to ^3Spectators^1.", PREFIX);

    return PLUGIN_HANDLED;
  }

  camera_enabled_bits ^= (1 << (id-1));

  if (USER_ENABLED(id))
  {
    client_print_color(id, id, "%s Advanced Observer is now ^4enabled^1.", PREFIX);
    
    new Float:now = get_gametime();
    next_action[id] = now + 3.0;

    if (!task_exists(TASK_ID_FAKEINPUT))
    {
      set_task(1.0, "task_fakeinput", TASK_ID_FAKEINPUT, _, _, "b");
    }
  }
  else
  {
    client_print_color(id, print_team_red, "%s Advanced Observer is now ^3disabled^1.", PREFIX);

    set_ent_data_float(id, "CBasePlayer", "m_flNextObserverInput", 0.0);

    if (task_exists(TASK_ID_FAKEINPUT) && !camera_enabled_bits)
    {
      remove_task(TASK_ID_FAKEINPUT);
    }
  }

  return PLUGIN_HANDLED;
}


public cmd_obsdebug(id)
{
  camera_debug_bits ^= (1 << id-1);
  client_print(id, print_chat, "Advanced Observer DEBUG %s.", camera_debug_bits & (1 << id-1) ? "enabled" : "disabled");
  
  return PLUGIN_HANDLED;
}

// https://github.com/s1lentq/ReGameDLL_CS/blob/efb06a7a201829bdbe13218bc5f5342e1f2ed8f1/regamedll/dlls/observer.cpp#L492
public set_observer_crosshair(id, mode)
{
  if (mode != OBS_ROAMING)
  {
    return;
  }

  message_begin(MSG_ONE_UNRELIABLE, MSG_ID_CROSSHAIR, _, id);
  write_byte(1);
  message_end();
}

// Spectator won't be fully blinded for quality of life reasons
public event_flashed(id)
{
  if (is_user_alive(id) || !USER_ENABLED(id))
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

  new Float:tmp = duration / 4096.0 / 3.0;
  
  set_hudmessage(200, 50, 0, -1.0, -1.0, 1, tmp, tmp, 0.1, 0.1, -1);
  ShowSyncHudMsg(id, hudsync1, "[FLASHED]");
  
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

  if (USER_ENABLED(victim))
  {
    set_ent_data(victim, "CBasePlayer", "m_canSwitchObserverModes", 1);
    
    new Float:now = get_gametime();
    next_action[victim] = now + 3.0;
  }
    
  if (!is_user_alive(killer) || !camera_enabled_bits)
  {
    return HAM_IGNORED;
  }
  
  for (new id = 1; id <= MaxClients; ++id)
  {
    if (is_user_alive(id) || is_user_bot(id))
    {
      continue;
    }

    if (!USER_ENABLED(id))
    {
      continue;
    }
    
    new spectated = entity_get_int(id, EV_INT_iuser2);
    
    if (id != victim && id != killer && spectated == victim)
    {
      observer_find_next_player(id, _, killer);
    }
  }
  
  return HAM_HANDLED;
}
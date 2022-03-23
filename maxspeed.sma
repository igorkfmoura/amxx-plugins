// MaxSpeed by lonewolf <igorkelvin@gmail.com>
// https://github.com/igorkelvin/amxx-plugins

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <xs>

#define PLUGIN  "Maxspeed"
#define VERSION "0.14"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PREFIX "^4[MaxSpeed]^1"

new cvar_enabled;
new cvar_maxspeed;
new cvar_surfspeed;
new cvar_duckspeed;
new cvar_swimspeed;
new cvar_usespeed;
new cvar_debug;
new cvar_noaccel;
new cvar_relative;

new bool:enabled;
new Float:maxspeed;
new Float:surfspeed;
new Float:duckspeed;
new Float:swimspeed;
new Float:usespeed;

new debug_is_enabled;
new noaccel_flags;
new maxspeed_is_relative;

new Float:user_oldspeed[MAX_PLAYERS+1];
new Float:hud_time[MAX_PLAYERS+1];

new bool:just_double_ducked[MAX_PLAYERS+1];
new bool:just_surfed[MAX_PLAYERS+1];
new bool:user_enabled_speed[MAX_PLAYERS+1];

enum State
{
  AIR,
  DDUCK,
  WATER,
  SURF,
  USE
};

new tags[State][10] =
{
  " ",
  "[DUCK]",
  "[WATER]",
  "[SURF]",
  "[+USE]"
}

enum (<<= 1)
{
  NOACCEL_AIR  = 1,
  NOACCEL_SWIM,
  NOACCEL_SURF,
  NOACCEL_USE
};


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  cvar_enabled   = create_cvar("amx_maxspeed_enabled",   "1",    _, "<0/1> Disable/Enable MaxSpeed Plugin");
  cvar_maxspeed  = create_cvar("amx_maxspeed",           "400",  _, "<0-2000> Maximum airspeed");
  cvar_surfspeed = create_cvar("amx_maxspeed_surfspeed", "2000", _,"<0-2000> Maximum speed while surfing");
  cvar_duckspeed = create_cvar("amx_maxspeed_duckspeed", "300",  _, "<0-2000> Maximum speed after double-ducking");
  cvar_swimspeed = create_cvar("amx_maxspeed_swimspeed", "400",  _, "<0-2000> Maximum speed on water");
  cvar_usespeed  = create_cvar("amx_maxspeed_usespeed",  "400",  _, "<0-2000> Maximum speed holding +use");
  cvar_debug     = create_cvar("amx_maxspeed_debug",     "0",    _, "<0/1> Enables ^"say /speed^" command");
  cvar_noaccel   = create_cvar("amx_maxspeed_noaccel",   "0",    _, "<0-15> Bitsum: 1-Airstrafe noaccel, 2-Swim noaccel, 4-Surf noaccel, 8-Use noaccel");
  cvar_relative  = create_cvar("amx_maxspeed_relative",  "1",    _, "<0/1> Maximum speed is relative to weapon maxspeed");
  
  bind_pcvar_num(cvar_enabled,     enabled);
  bind_pcvar_num(cvar_debug,       debug_is_enabled);
  bind_pcvar_num(cvar_noaccel,     noaccel_flags);
  bind_pcvar_num(cvar_relative,    maxspeed_is_relative);
  bind_pcvar_float(cvar_maxspeed,  maxspeed);
  bind_pcvar_float(cvar_surfspeed, surfspeed);
  bind_pcvar_float(cvar_duckspeed, duckspeed);
  bind_pcvar_float(cvar_swimspeed, swimspeed);
  bind_pcvar_float(cvar_usespeed,  usespeed);
  
  register_clcmd("say /speed", "handle_speed");
  
}

public client_connect(id)
{
  user_oldspeed[id]      = 0.0;
  just_double_ducked[id] = false;
  user_enabled_speed[id] = false;
  just_surfed[id]        = false;
}

public handle_speed(id)
{
  if (get_pcvar_num(cvar_debug))
  {
    user_enabled_speed[id] = !user_enabled_speed[id];
    client_print_color(id, print_team_default, "%s Speed debug %s.", PREFIX, user_enabled_speed[id] ? "enabled" : "disabled");
  }

  return PLUGIN_HANDLED;
}


public client_cmdStart(id)
{
  
  if(!is_user_alive(id) || !enabled) 
  {
    return PLUGIN_CONTINUE;
  }
  
  new button     = get_usercmd(usercmd_buttons);
  new oldbutton  = get_user_oldbutton(id);
  
  new just_released = (oldbutton ^ button) & oldbutton;
  
  if (!(just_released & IN_DUCK))
  {
    return PLUGIN_CONTINUE;
  }
  
  new user_flags = get_entity_flags(id);
  
  if(user_flags & FL_ONGROUND)
  {
    just_surfed[id] = false;
    
    // Check if double duck is happening this frame
    //   https://kz-rush.ru/en/article/countjump-physics
    //   https://forums.alliedmods.net/showthread.php?p=619219
    if (!(user_flags & FL_DUCKING) && entity_get_int(id, EV_INT_bInDuck))
    {
      just_double_ducked[id] = true;
    }
  }
  
  return PLUGIN_CONTINUE;
}


public client_PostThink(id)
{
  if (!is_user_connected(id) || !enabled)
  {
    return PLUGIN_CONTINUE;
  }
  
  new id_original = id;
  new bool:is_spectator = false;

  if (!is_user_alive(id))
  {
    if (!debug_is_enabled || !user_enabled_speed[id])
    {
      return PLUGIN_CONTINUE;
    }

    new target = entity_get_int(id, EV_INT_iuser2);
    
    if (!is_user_alive(target))
    {
      return PLUGIN_CONTINUE;
    }

    id = target;
    is_spectator = true;
  }
  
  new user_flags = get_entity_flags(id);
  new on_ladder = (entity_get_int(id, EV_INT_movetype) == MOVETYPE_FLY);

  if(user_flags & FL_ONGROUND || on_ladder)
  {
    just_surfed[id_original] = false;
    user_oldspeed[id_original] = 0.0;
    
    return PLUGIN_CONTINUE;
  }
  
  new Float:player_maxspeed = maxspeed;
  new bool:player_ducked    = just_double_ducked[id];
  new disable_acceleration  = noaccel_flags & NOACCEL_AIR;
  
  new tag[10];
  tag = tags[AIR];

  just_double_ducked[id_original] = false;
    
  new Float:velocity[3];
  new Float:speed;
  
  entity_get_vector(id, EV_VEC_velocity, velocity);
  speed = xs_vec_len_2d(velocity);
  
  if (player_ducked)
  {
    player_maxspeed = duckspeed;
    user_oldspeed[id_original] = speed;

    tag = tags[DDUCK];
  }
  else if (just_surfed[id] || is_user_surfing(id))
  {
    disable_acceleration = (noaccel_flags & NOACCEL_SURF);
    player_maxspeed = surfspeed;
    
    just_surfed[id_original] = true;
    tag = tags[SURF];
  }
  else if (entity_get_int(id, EV_INT_waterlevel))
  {
    just_surfed[id_original] = false;
    
    if (!(get_user_button(id) & IN_JUMP))
    {
      disable_acceleration = 0;
    }
    else
    {
      disable_acceleration = (noaccel_flags & NOACCEL_SWIM);
      player_maxspeed      = swimspeed;

      tag = tags[WATER];
    }
  }
  else if (get_user_button(id) & IN_USE)
  {
    disable_acceleration = (noaccel_flags & NOACCEL_USE);
    player_maxspeed      = usespeed;

    tag = tags[USE];
  }
  
  if (disable_acceleration && (user_oldspeed[id] > 0.0))
  {
    player_maxspeed = user_oldspeed[id];
  }
  else if (maxspeed_is_relative)
  {
    new Float:factor = entity_get_float(id, EV_FL_maxspeed) / 250.0; // 250.0 is knife's maxspeed
    player_maxspeed *= factor;
  }

  if (!is_spectator && (speed > player_maxspeed))
  {
    new Float:c;
  
    c = player_maxspeed / speed;
    speed *= c;

    velocity[0] *= c;
    velocity[1] *= c;

    entity_set_vector(id, EV_VEC_velocity, velocity);
  }
  
  user_oldspeed[id_original] = speed;

  show_speed(id_original, speed, player_maxspeed, tag)
  
  return PLUGIN_CONTINUE;
}

public is_user_surfing(id)
{
  new Float:origin[3];
  new Float:end[3];
  
  entity_get_vector(id, EV_VEC_origin, origin);
  xs_vec_copy(origin, end);
  
  end[2] -= 1.0;
  
  new hull = (get_entity_flags(id) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
  new Float:fraction;
  
  trace_hull(origin, hull, id, IGNORE_MONSTERS, end);
  traceresult(TR_Fraction, fraction);
  
  if (fraction == 1.0)
  {
    return 0;
  }
  
  new Float:normal[3];
  traceresult(TR_PlaneNormal, normal);
  
  new Float:cosine;
  new Float:vector_up[3] = {0.0, 0.0, 1.0};
  
  cosine = xs_vec_dot(normal, vector_up);

  //new Float:tilt = floatacos(cosine, degrees);
  //client_print(id, print_center, "[%3.3f°]", tilt);
  
  return (cosine <= 0.7);
}


show_speed(id, Float:speed, Float:player_maxspeed, tag[10] = "^0")
{
  if (tag[0] == '^0')
  {
    tag = tags[AIR];
  }
  
  if (!debug_is_enabled || !user_enabled_speed[id])
  {
    return;
  }

  new Float:now = get_gametime();
  if (now < hud_time[id])
  {
    return;
  }
  
  client_print(id, print_center, "%s %4.2f/%4.2f %s", tag, speed, player_maxspeed, tag)
  
  hud_time[id] = now + 0.2;
  return;
}



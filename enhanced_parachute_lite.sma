// EnhancedParachuteLite by lonewolf <igorkelvin@gmail.com>
// https://github.com/igorkelvin/amxx-plugins
//
// Based on CSRevo's Parachute Lite by Wilian M.

#include <amxmodx>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <xs>

#define PLUGIN  "Enhanced Parachute Lite"
#define VERSION "0.2"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PARACHUTE_GRAVITY 0.1337 // avoid rare coincidence with other plugins

new cvar_fallspeed;
new cvar_noaccel;
new cvar_maxspeed;

new Float:speed_last[MAX_PLAYERS+1];
new Float:user_gravity_old[MAX_PLAYERS+1];

new in_parachute[MAX_PLAYERS+1];
new keep_speed[MAX_PLAYERS+1];

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);

  cvar_fallspeed = create_cvar("parachute_fallspeed", "100",  FCVAR_ARCHIVE, "<0-2000> Parachute fallspeed. Default: 80");
  cvar_noaccel   = create_cvar("parachute_noaccel",   "0",   FCVAR_ARCHIVE, "<0|1> Disable speed gain on parachute. Default: 0");
  cvar_maxspeed  = create_cvar("parachute_maxspeed",  "2000", FCVAR_ARCHIVE, "<0-2000> Parachute maxspeed. Default: 2000");

  RegisterHam(Ham_Spawn, "player", "player_spawn", true);
}


public client_disconnected(id)
{
  user_gravity_old[id] = 0.0;
  speed_last[id] = 0.0;
  keep_speed[id] = false;
}


public player_spawn(id)
{
  if(!is_user_alive(id)) 
  {
    return HAM_IGNORED;
  }

  in_parachute[id] = false;
  speed_last[id] = 0.0;
  keep_speed[id] = false;
  
  return HAM_IGNORED;
}


public client_cmdStart(id)
{
  if(!is_user_alive(id))
  {
    return PLUGIN_CONTINUE;
  }
  
  new buttons = get_usercmd(usercmd_buttons);

  if (buttons & IN_USE && !in_parachute[id])
  {
    new flags = get_entity_flags(id);
    if (!(flags & FL_ONGROUND))
    {
      user_gravity_old[id] = entity_get_float(id, EV_FL_gravity);
      if ((user_gravity_old[id] < 0.00000001) || (user_gravity_old[id] > 99999999.9)) // solve conflict with "frostnades.amxx"
      {
        user_gravity_old[id] = 1.0;
      }
      in_parachute[id] = true;
    }
  }

  return PLUGIN_CONTINUE;
}


public client_PostThink(id)
{
  if(!is_user_alive(id) || !in_parachute[id])
  {
    return PLUGIN_CONTINUE;
  }
  
  new flags = get_entity_flags(id);
  new buttons = get_user_button(id);

  if(flags & FL_ONGROUND || !(buttons & IN_USE))
  {
    if(get_user_gravity(id) == PARACHUTE_GRAVITY)
    {
      set_user_gravity(id, user_gravity_old[id]);
    }
    
    in_parachute[id] = false;
    return PLUGIN_CONTINUE;
  }

  static Float:fallspeed;

  fallspeed = -1.0 * get_pcvar_float(cvar_fallspeed);
  fallspeed = (fallspeed >= 0.0) ? -60.0 : fallspeed;
  
  static Float:velocity[3];
  entity_get_vector(id, EV_VEC_velocity, velocity);
  
  if (velocity[2] >= fallspeed)
  {
    if(get_user_gravity(id) == PARACHUTE_GRAVITY)
    {
      set_user_gravity(id, user_gravity_old[id]);
    }
    return PLUGIN_CONTINUE;
  }
  
  new Float:speed = xs_vec_len_2d(velocity);
  
  if (keep_speed[id])
  {
    new Float:maxspeed;
    new noaccel = get_pcvar_num(cvar_noaccel);

    maxspeed = noaccel ? speed_last[id] : get_pcvar_float(cvar_maxspeed);

    if (speed > maxspeed)
    {
        new Float:c = maxspeed / speed;

        velocity[0] *= c;
        velocity[1] *= c;

        speed = c * speed;
        // client_print(id, print_chat, "keep_speed: %d, noaccel: %d, speed_last: %.1f, speed: %.1f, maxspeed: %.1f", keep_speed[id], noaccel, speed_last[id], speed, maxspeed);
    }
  }
    
  set_user_gravity(id, PARACHUTE_GRAVITY);
  keep_speed[id] = true;
  speed_last[id] = speed;
  
  velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed;  

  entity_set_vector(id, EV_VEC_velocity, velocity);
  // client_print(id, print_center, "[%.3f, %.3f]", speed, velocity[2]);

  return PLUGIN_CONTINUE;
}


// Enhanced MultiJump - Igor "lonewolf" Kelvin <igorkelvin@gmail.com
//
//
// Good source of knowledge:
// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/pm_shared/pm_shared.cpp

#include <amxmodx>
#include <engine>
#include <xs>

#define PLUGIN  "EnhancedMultiJump"
#define VERSION "0.3"
#define AUTHOR  "lonewolf"


// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/pm_shared/pm_shared.cpp#L2477
// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/pm_shared/pm_shared.cpp#L2487
  
new const Float:JUMP_TIME_WAIT = 0.2;
new const Float:JUMP_SPEED     = 268.32815729997475;
new const Float:FUSER2_DEFAULT = 1315.789429

new bool:ready_to_jump[MAX_PLAYERS + 1];

new Float:next_jump_time[MAX_PLAYERS + 1];
new Float:maxheight[MAX_PLAYERS + 1];

new airjumps[MAX_PLAYERS + 1];

new pcvar_maxjumps;

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  pcvar_maxjumps = create_cvar("amx_maxjumps", "1", _, "- maximum number of airjumps");
  
  new maxjumps = get_pcvar_num(pcvar_maxjumps);
  arrayset(airjumps, maxjumps, sizeof(airjumps));
}


public client_connect(id)
{
  ready_to_jump[id]  = false;
  next_jump_time[id] = 0.0;
}


public client_disconnected(id)
{
  ready_to_jump[id]  = false;
  next_jump_time[id] = 0.0;
}


public client_cmdStart(id)
{
  if (!is_user_alive(id) || ready_to_jump[id] || !airjumps[id])
  {
    return PLUGIN_CONTINUE;
  }
  
  new buttons = get_usercmd(usercmd_buttons, buttons);
  
  if (!(buttons & IN_JUMP))
  {
    return PLUGIN_CONTINUE;
  }
  
  if (get_entity_flags(id) & FL_ONGROUND)
  {
    new Float:fuser2 = entity_get_float(id, EV_FL_fuser2);
    
    next_jump_time[id] = get_gametime() + JUMP_TIME_WAIT; 
    maxheight[id]      = 45.0 * (100.0 - fuser2 * 0.001 * 19.0) * 0.01; // 45.0 height is fixed for 800 gravity
    
    // client_print(id, print_chat, "maxheight[%d]: %.3f", id, maxheight[id]);
    
    return PLUGIN_CONTINUE; 
  }

  if (get_gametime() < next_jump_time[id])
  {
    return PLUGIN_CONTINUE;
  }
  
  ready_to_jump[id]  = true;
  airjumps[id]--;
  
  return PLUGIN_HANDLED;
}

public client_PostThink(id)
{
  if (!is_user_alive(id))
  {
    return PLUGIN_CONTINUE;
  }
  
  if (get_entity_flags(id) & FL_ONGROUND)
  {
    ready_to_jump[id] = false;
    airjumps[id]      = get_pcvar_num(pcvar_maxjumps);
    
    return PLUGIN_CONTINUE;
  }
  
  if (!ready_to_jump[id])
  {
    return PLUGIN_CONTINUE;
  }
  
  new Float:velocity[3];
  entity_get_vector(id, EV_VEC_velocity, velocity);
  
  new Float:upspeed = velocity[2];
  
  if (upspeed <= 0.0)
  {
    velocity[2] = JUMP_SPEED;
  }
  else
  {
    new Float:gravity = get_cvar_float("sv_gravity") * entity_get_float(id, EV_FL_gravity);
    
    new Float:d = (JUMP_SPEED*JUMP_SPEED - upspeed*upspeed) / (2.0 * gravity);
    velocity[2] = xs_sqrt(2 * gravity * (45.0 + maxheight[id] - d));
    
    // client_print(id, print_chat, "[d:%.3f, g:%.3f]", d, gravity);
  }
  
  entity_set_vector(id, EV_VEC_velocity, velocity);
  entity_set_float(id, EV_FL_fuser2, FUSER2_DEFAULT);
  
  ready_to_jump[id]  = false;
  next_jump_time[id] = get_gametime() + JUMP_TIME_WAIT; 
  
  // client_print(id, print_center, "airjumps[%d]: %d", id, airjumps[id]);
  // client_print(id, print_center, "[%.3f, %.3f]", upspeed, velocity[2]);
  
  return PLUGIN_HANDLED;
}

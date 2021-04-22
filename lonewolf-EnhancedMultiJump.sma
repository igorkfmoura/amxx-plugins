// Enhanced MultiJump - lonewolf <igorkelvin@gmail.com>
// https://github.com/igorkelvin/amxx-plugins
//
// Inspired by twistedeuphoria's 'MultiJump': https://forums.alliedmods.net/showthread.php?t=10159
//
// Good source of knowledge:
// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/pm_shared/pm_shared.cpp

#include <amxmodx>
#include <engine>
#include <xs>

#define PLUGIN  "EnhancedMultiJump"
#define VERSION "0.4"
#define AUTHOR  "lonewolf"

// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/pm_shared/pm_shared.cpp#L2477
// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/pm_shared/pm_shared.cpp#L2487
  
new const Float:JUMP_TIME_WAIT = 0.2;
new const Float:JUMP_SPEED     = 268.32815729997475;
new const Float:FUSER2_DEFAULT = 1315.789429;

new bool:ready_to_jump[MAX_PLAYERS+1];

new Float:next_jump_time[MAX_PLAYERS+1];
new Float:fuser2[MAX_PLAYERS+1];

new airjumps[MAX_PLAYERS+1];

new pcvar_maxjumps;


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  pcvar_maxjumps = create_cvar("amx_maxjumps", "1", _, "<int> maximum number of airjumps");
  
  new maxjumps = get_pcvar_num(pcvar_maxjumps);
  arrayset(airjumps, maxjumps, sizeof(airjumps));
}


public client_connect(id)
{
  ready_to_jump[id]  = false;
  next_jump_time[id] = 0.0;
  fuser2[id] = 0.0
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
    fuser2[id] = entity_get_float(id, EV_FL_fuser2);
    next_jump_time[id] = get_gametime() + JUMP_TIME_WAIT; 
    
    return PLUGIN_CONTINUE; 
  }

  if (get_gametime() < next_jump_time[id])
  {
    return PLUGIN_CONTINUE;
  }
  
  ready_to_jump[id]  = true;
  
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
    // torricelli: vf^2 = vo^2 + 2*a*s
    // for jump height: vf = 0;
    new Float:gravity = get_cvar_float("sv_gravity") * entity_get_float(id, EV_FL_gravity);
    new Float:gravityinvbytwo = 1.0 / (2.0 * gravity);

    new Float:jump_height = (72000.0) * gravityinvbytwo; // 2.0 * 800.0 * 45.0 / (2.0 * gravity)
    new Float:upspeed_original = JUMP_SPEED * (1.0 - fuser2[id] * 0.00019);

    new Float:height_elapsed = (JUMP_SPEED * JUMP_SPEED - upspeed * upspeed) * gravityinvbytwo;
    new Float:maxheight;

    // Original Jump height
    maxheight = floatpower(upspeed_original, 2.0) * gravityinvbytwo;
    // Second Jump height
    maxheight += jump_height;

    fuser2[id] = 0.0; // for next airjumps
    velocity[2] = xs_sqrt(2.0 * gravity * (maxheight - height_elapsed));
  }
  
  entity_set_vector(id, EV_VEC_velocity, velocity);
  entity_set_float(id, EV_FL_fuser2, FUSER2_DEFAULT);
  
  airjumps[id]--;

  ready_to_jump[id]  = false;
  next_jump_time[id] = get_gametime() + JUMP_TIME_WAIT;

  return PLUGIN_CONTINUE;
}

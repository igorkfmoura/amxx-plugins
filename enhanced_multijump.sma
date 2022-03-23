// Enhanced MultiJump - lonewolf <igorkelvin@gmail.com>
// https://github.com/igorkelvin/amxx-plugins
//
// Inspired by twistedeuphoria's 'MultiJump': https://forums.alliedmods.net/showthread.php?t=10159
//
// Good source of knowledge:
// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/pm_shared/pm_shared.cpp

#include <amxmodx>
#include <reapi>
#include <xs>

#define PLUGIN  "Enhanced MultiJump"
#define VERSION "0.7.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/pm_shared/pm_shared.cpp#L2477
// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/pm_shared/pm_shared.cpp#L2487
  
new const Float:JUMP_TIME_WAIT = 0.2;
new const Float:JUMP_SPEED     = 268.32815729997475;
new const Float:FUSER2_DEFAULT = 1315.789429;
new const Float:BUNNYHOP_MAX_SPEED_FACTOR = 1.2;

new Float:next_jump_time[MAX_PLAYERS+1];
new Float:fuser2[MAX_PLAYERS+1];

new airjumps[MAX_PLAYERS+1];

new maxjumps;
new airjumplikebhop;
new Float:sv_gravity;

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  bind_pcvar_num(create_cvar("amx_maxjumps", "1", _, "<int> maximum number of airjumps", true, 0.0), maxjumps);
  bind_pcvar_num(create_cvar("amx_airjumplikebhop", "1", _, "<bool> Treat jump horizontal speed as bhop"), airjumplikebhop);
  bind_pcvar_float(get_cvar_pointer("sv_gravity"), sv_gravity);

  arrayset(airjumps, maxjumps, sizeof(airjumps));
  
  RegisterHookChain(RG_CBasePlayer_Jump, "on_CBasePlayer_Jump_Post", .post = false);
  RegisterHookChain(RG_CBasePlayer_PostThink, "on_CBasePlayer_PostThink", .post = false);
}


public client_connect(id)
{
  next_jump_time[id] = 0.0;
  fuser2[id] = 0.0
}


public on_CBasePlayer_Jump_Post(id)
{
  if (!is_user_alive(id) || !airjumps[id])
  {
    return HC_CONTINUE;
  }
  
  new on_ladder = (get_entvar(id, var_movetype) == MOVETYPE_FLY);
  if (get_entvar(id, var_flags) & FL_ONGROUND || on_ladder)
  {
    fuser2[id] = get_entvar(id, var_fuser2);
    next_jump_time[id] = get_gametime() + JUMP_TIME_WAIT;

    return HC_CONTINUE; 
  }

  if (get_gametime() < next_jump_time[id])
  {
    return HC_CONTINUE;
  }
  
  if (airjumps[id] > maxjumps)
  {
    airjumps[id] = maxjumps;

    if (!maxjumps)
    {
      return HC_CONTINUE;
    }
  }

  new Float:velocity[3];
  get_entvar(id, var_velocity, velocity);
  
  new Float:upspeed = velocity[2];
  
  if (airjumplikebhop)
  {
    new Float:speed = xs_sqrt(velocity[0]*velocity[0] + velocity[1]*velocity[1] + 16.0) // simulating upspeed of -4.0 u/s as in a normal bhop
    new Float:maxspeed = get_entvar(id, var_maxspeed);
    new Float:maxscaledspeed = BUNNYHOP_MAX_SPEED_FACTOR * maxspeed;

    if (maxscaledspeed > 0.0 && speed > maxscaledspeed)
    {
      new Float:fraction = (maxscaledspeed / speed) * 0.8;
      velocity[0] *= fraction;
      velocity[1] *= fraction;
    }
  }

  if (upspeed <= 0.0)
  {
    velocity[2] = JUMP_SPEED;
  }
  else
  {
    // torricelli: vf^2 = vo^2 + 2*a*s
    // for jump height: vf = 0;
    new Float:gravity = sv_gravity * Float:get_entvar(id, var_gravity);
    new Float:gravityinvbytwo = 1.0 / (2.0 * gravity);
    
    new Float:jump_height = (72000.0) * gravityinvbytwo; // 2.0 * 800.0 * 45.0 / (2.0 * gravity)
    new Float:upspeed_original = JUMP_SPEED * (1.0 - fuser2[id] * 0.00019);

    new Float:height_elapsed = (JUMP_SPEED * JUMP_SPEED - upspeed * upspeed) * gravityinvbytwo;
    new Float:maxheight;

    // Original Jump height
    maxheight = floatpower(upspeed_original, 2.0) * gravityinvbytwo;
    // Second Jump height
    maxheight += jump_height;
    
    // client_print_color(id, print_team_red, "^3[1] ^4gravity:^1 %.1f, ^4sv_gravity:^1 %.1f, ^4var_gravity:^1 %.1f", gravity, sv_gravity, Float:get_entvar(id, var_gravity));
    // client_print_color(id, print_team_red, "^3[2] ^4jump_height:^1 %.1f, ^4upspeed_original:^1 %.1f, ^4fuser2:^1 %.1f", jump_height, upspeed_original, fuser2[id]);
    // client_print_color(id, print_team_red, "^3[3] ^4height_elapsed:^1 %.1f, ^4maxheight:^1 %.1f", height_elapsed, maxheight);

    fuser2[id] = 0.0; // for next airjumps
    velocity[2] = xs_sqrt(2.0 * gravity * (maxheight - height_elapsed));

    // client_print_color(id, print_team_red, "^3[4] ^4velocity[2]:^1 %.1f", velocity[2]);
  }
  
  set_entvar(id, var_velocity, velocity);
  set_entvar(id, var_fuser2, FUSER2_DEFAULT);
  
  airjumps[id]--;

  next_jump_time[id] = get_gametime() + JUMP_TIME_WAIT;

  return HC_CONTINUE;
}


public on_CBasePlayer_PostThink(id)
{
  if (!is_user_alive(id) || airjumps[id] == maxjumps)
  {
    return PLUGIN_CONTINUE;
  }
  
  new on_ladder = (get_entvar(id, var_movetype) == MOVETYPE_FLY);
  if (get_entvar(id, var_flags) & FL_ONGROUND || on_ladder)
  {
    airjumps[id] = maxjumps;
  }
  
  return PLUGIN_CONTINUE;
}

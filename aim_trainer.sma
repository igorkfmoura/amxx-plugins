#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define PLUGIN  "Aim Trainer"
#define VERSION "0.2"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

new hudsync1;
new hudsync2;

new bool:enabled[MAX_PLAYERS + 1];

new Float:prefire_precision[MAX_PLAYERS + 1];
new Float:prefire_speed[MAX_PLAYERS + 1];
new prefire_flags[MAX_PLAYERS + 1];

new Float:last_shot_time[MAX_PLAYERS + 1];
new just_houstered[MAX_PLAYERS + 1];
new Float:timer[MAX_PLAYERS + 1];


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  register_clcmd("say /aim", "cmd_aim");
  
  RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "deagle_shot_pre");
  RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "deagle_shot_post", 1);

  RegisterHam(Ham_Item_Deploy, "weapon_deagle", "deagle_spawn");
  RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "deagle_spawn");

  hudsync1 = CreateHudSyncObj();
  hudsync2 = CreateHudSyncObj();
}


public client_connect(id)
{
  enabled[id] = false;
  timer[id] = 0.0;
  prefire_flags[id] = 0;
}


public client_disconnected(id)
{
  enabled[id] = false;
  timer[id] = 0.0;
  prefire_flags[id] = 0;
}


public cmd_aim(id)
{
  enabled[id] = !enabled[id];
  client_print(id, print_center, "AimTrainer %s!", enabled[id] ? "Enabled" : "Disabled");
}

public client_PreThink(id)
{
  if (!enabled[id])
  {
    return PLUGIN_CONTINUE;
  }
  
  new Float:t = timer[id];
  if (t <= 0.0)
  {
    return PLUGIN_CONTINUE;
  }
  
  new Float:time_remaining = t - get_gametime();
  if (time_remaining < 0.0)
  {
    timer[id] = 0.0;
    return PLUGIN_CONTINUE;
  }

  set_hudmessage(0, 255, 100, -1.0, -0.35, 0, 0.0, 0.02, 0.1, 0.1, -1);
  ShowSyncHudMsg(id, hudsync2, "[%.2f]", time_remaining);
  
  return PLUGIN_CONTINUE;
}


public deagle_spawn(weapon_ent)
{
  new owner  = entity_get_edict(weapon_ent, EV_ENT_owner)
  just_houstered[owner] = 1;
}


// https://github.com/s1lentq/ReGameDLL_CS/blob/efb06a7a201829bdbe13218bc5f5342e1f2ed8f1/regamedll/dlls/wpn_shared/wpn_deagle.cpp#L74
public deagle_shot_pre(weapon_ent)
{ 
  if (!is_valid_ent(weapon_ent))
  {
    return HAM_IGNORED;  
  }
  
  new owner  = entity_get_edict(weapon_ent, EV_ENT_owner)
  if (!enabled[owner])
  {
    return HAM_IGNORED;
  }
  
  new shotsfired = get_ent_data(weapon_ent, "CBasePlayerWeapon", "m_iShotsFired");
  if (shotsfired)
  {
    prefire_flags[owner] = 0;
    return HAM_IGNORED;
  }

  new Float:velocity[3];
  entity_get_vector(owner, EV_VEC_velocity, velocity);
  
  prefire_precision[owner] = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flAccuracy");
  last_shot_time[owner]    = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flLastFire");
  prefire_speed[owner]     = xs_vec_len_2d(velocity);
  prefire_flags[owner]     = get_entity_flags(owner);
  
  return HAM_IGNORED;
}

public deagle_shot_post(weapon_ent)
{
  if (!is_valid_ent(weapon_ent))
  {
    return HAM_IGNORED;  
  }
  
  new owner = entity_get_edict(weapon_ent, EV_ENT_owner)
  
  if (!enabled[owner])
  {
    return HAM_IGNORED;
  }
  
  new flags = prefire_flags[owner];
  if (!flags)
  {
    return HAM_IGNORED;
  }

  new Float:p1    = prefire_precision[owner];
  new Float:p2    = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flAccuracy");
  new Float:speed = prefire_speed[owner];
  
  new Float:spread;
  new warning_state[33];
  
  if (!(flags & FL_ONGROUND))
  {
    spread = 1.5 * (1 - p1);
    formatex(warning_state, charsmax(warning_state), "IN AIR");
  }
  else if (speed > 0.0)
  {
    spread = 0.25 * (1 - p1);
    formatex(warning_state, charsmax(warning_state), "IN MOVEMENT");
  }
  else if (flags & FL_DUCKING)
  {
    spread = 0.115 * (1 - p1);
    formatex(warning_state, charsmax(warning_state), "DUCKED");
  }
  else
  {
    spread = 0.13 * (1 - p1);
    formatex(warning_state, charsmax(warning_state), "STANDING");
  }
    
  new Float:t1 = last_shot_time[owner];
  new Float:t2 = get_gametime();
  new Float:delta    = t2 - t1;
  new Float:tperfect = 0.4 + ((0.9 - p1) / 0.35);
  
  set_hudmessage(200, 100, 0, -1.0, 0.35, 0, 0.0, 3.0, 0.1, 0.1, -1);
    
  if (just_houstered[owner])
  {
    just_houstered[owner] = 0;
    ShowSyncHudMsg(owner, hudsync1, "SPREAD: %.3f %s^n", spread, warning_state);
  }
  else {
    ShowSyncHudMsg(owner, hudsync1, "SPREAD: %.3f %s^n[%.3fs from last shot]^n%.3f seconds %s!", spread, warning_state, delta, xs_fabs(delta - tperfect), ((delta - tperfect) > 0.0) ? "LATE" : "EARLIER");
  }
  
  new Float:next_perfect = 0.4 - ((p2 - 0.9) / 0.35);
  timer[owner] = t2 + next_perfect;

  return HAM_IGNORED;
}

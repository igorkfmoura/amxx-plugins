#include <amxmodx>
#include <engine>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_stocks>
#include <cstrike>
#include <hamsandwich>
#include <xs>

#define PLUGIN  "AimTrainer"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

#define PM_VEC_DUCK_VIEW     12
#define PM_VEC_VIEW          17

#define TASK_DEAGLE 322

new sprite_laserbeam;
new hudsync1;
new hudsync2;

new bool:enabled[MAX_PLAYERS + 1];

new Float:prefire_precision[MAX_PLAYERS + 1];
new Float:prefire_speed[MAX_PLAYERS + 1];
new prefire_flags[MAX_PLAYERS + 1];

new Float:last_shot_time[MAX_PLAYERS + 1];
new Float:timer[MAX_PLAYERS + 1];

public plugin_precache( )
{
  sprite_laserbeam = precache_model("sprites/laserbeam.spr");
}


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  register_clcmd("say /aim",     "cmd_aim");
  
  RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "deagle_shot_pre");
  RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "deagle_shot_post", 1);
  
  RegisterHam(Ham_Item_Holster, "weapon_deagle", "deagle_holster");
  RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "deagle_holster");
  
  hudsync1 = CreateHudSyncObj();
  hudsync2 = CreateHudSyncObj();
}


public deagle_holster(weapon_ent)
{
  new owner  = entity_get_edict(weapon_ent, EV_ENT_owner)
  
  prefire_precision[owner] = 0.0;
  prefire_speed[owner]     = 0.0;
  prefire_flags[owner]     = 0;
  timer[owner] = 0.0;
  
  last_shot_time[owner] = 0.0;
}


public client_connect(id)
{
  enabled[id] = false;
  
  prefire_precision[id] = 0.0;
  prefire_speed[id]     = 0.0;
  prefire_flags[id]     = 0;
  timer[id] = 0.0;
  
  last_shot_time[id] = 0.0;
}


public client_disconnected(id)
{
  
  enabled[id] = false;
  
  prefire_precision[id] = 0.0;
  prefire_speed[id]     = 0.0;
  prefire_flags[id]     = 0;
  timer[id] = 0.0;
  
  last_shot_time[id] = 0.0;
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
  
  if (t > 0.0)
  {
    new Float:now = get_gametime();
    if (t <= now)
    {
      timer[id] = 0.0;
      return PLUGIN_CONTINUE;
    }
    
    set_hudmessage(0, 255, 100, -1.0, -0.35, 0, 0.0, 0.02, 0.1, 0.1, -1);
    ShowSyncHudMsg(id, hudsync2, "[%.3f]", now - t);
  }
  
  return PLUGIN_CONTINUE;
}

public task_drawlaser(task_id)
{
  new id = task_id - TASK_DEAGLE;
  
  new Float:eyes[3];
  new Float:tmp[3];
  
  entity_get_vector(id, EV_VEC_origin, eyes);
  entity_get_vector(id, EV_VEC_view_ofs, tmp);
  xs_vec_add(eyes, tmp, eyes);
  
  new Float:v_angle[3];
  new Float:punchangle[3];
  new Float:aim[3];
  
  entity_get_vector(id, EV_VEC_v_angle, v_angle);
  entity_get_vector(id, EV_VEC_punchangle, punchangle);
  xs_vec_add(v_angle, punchangle, aim);
    
  EF_MakeVectors(aim);
  get_global_vector(GL_v_forward, aim);
  
  new Float:aim_end[3];
  xs_vec_add_scaled(eyes, aim, 4096.0, aim_end);
  
  new trace_result;
  engfunc(EngFunc_TraceLine, eyes, aim_end, DONT_IGNORE_MONSTERS, id, trace_result);
  get_tr2(trace_result, TR_vecEndPos, aim_end);
  
  new start[3];
  new end[3];
  FVecIVec(eyes, start);
  FVecIVec(aim_end, end);
  
  UTIL_laserbeam(id, start, end, {255, 0, 0}, 10);
}


public deagle_spawn(weapon_ent)
{
  new clip   = cs_get_weapon_ammo(weapon_ent);
  new owner  = entity_get_edict(weapon_ent, EV_ENT_owner)
  
  last_shot_time[owner] = 0.0;
}


// https://github.com/s1lentq/ReGameDLL_CS/blob/efb06a7a201829bdbe13218bc5f5342e1f2ed8f1/regamedll/dlls/wpn_shared/wpn_deagle.cpp#L74
public deagle_shot_pre(weapon_ent)
{ 
  if (!is_valid_ent(weapon_ent))
  {
    return HAM_IGNORED;  
  }
  
  new clip   = cs_get_weapon_ammo(weapon_ent);
  new owner  = entity_get_edict(weapon_ent, EV_ENT_owner)
  
  if (!enabled[owner])
  {
    return HAM_IGNORED;
  }
  
  // task_drawlaser(owner + TASK_DEAGLE);
  
  new Float:velocity[3];
  
  entity_get_vector(owner, EV_VEC_velocity, velocity);
  
  prefire_precision[owner] = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flAccuracy");
  prefire_speed[owner] = xs_vec_len_2d(velocity);
  prefire_flags[owner] = get_entity_flags(owner);
  
  // client_print(owner, print_chat, "pre p1: %f, speed: %f", prefire_precision[owner], prefire_speed[owner]);
  return HAM_IGNORED;
}

public deagle_shot_post(weapon_ent)
{
  if (!is_valid_ent(weapon_ent))
  {
    return HAM_IGNORED;  
  }
  
  new clip  = cs_get_weapon_ammo(weapon_ent);
  new owner = entity_get_edict(weapon_ent, EV_ENT_owner)
  
  if (!enabled[owner])
  {
    return HAM_IGNORED;
  }
  
  new Float:p1    = prefire_precision[owner];
  new Float:p2    = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flAccuracy");
  new Float:speed = prefire_speed[owner];
  new flags       = prefire_flags[owner];
  
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
    formatex(warning_state, charsmax(warning_state), "PERFECT");
  }
  else
  {
    spread = 0.13 * (1 - p1);
    formatex(warning_state, charsmax(warning_state), "STANDING");
  }
    
  
  new Float:t1 = last_shot_time[owner];
  new Float:t2 = get_gametime();
  new Float:delta    = t2 - t1;
  new Float:tperfect = 0.4 - ((p1 - 0.9) / 0.35);
  
  set_hudmessage(200, 100, 0, -1.0, 0.35, 0, 0.0, 3.0, 0.1, 0.1, -1);
    
  if (t1 == 0.0)
  {
    ShowSyncHudMsg(owner, hudsync1, "SPREAD: %.3f %s^n", spread, warning_state);
  }
  else{
    ShowSyncHudMsg(owner, hudsync1, "SPREAD: %.3f %s^n[%.3fs from last shot]^n%.3f seconds %s!", spread, warning_state, delta, xs_fabs(delta - tperfect), ((delta - tperfect) > 0.0) ? "LATE" : "EARLIER");
  }
  
  // client_print(owner, print_chat, "pos  %f-> %f, %f -> %f [%f]... tp:%f", p1, p2, t1, t2, delta, tperfect);
  last_shot_time[owner] = t2;
  
  new Float:next_perfect = 0.4 - ((p2 - 0.9) / 0.35);
  timer[owner] = t2 + next_perfect;
  // UTIL_screenfade(owner, tperfect);
  
  return HAM_IGNORED;
}

stock UTIL_screenfade(id, Float:duration = 0.15, Float:hold_time = 0.0, color[3] = {0, 50, 255}, alpha = 100)
{
  new _duration  = floatround(duration  * 4096);
  new _hold_time = floatround(hold_time * 4096);
  
  message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
  write_short(_duration);
  write_short(_hold_time);
  write_short(1);
  write_byte(color[0]);
  write_byte(color[1]);
  write_byte(color[2]);
  write_byte(alpha);
  message_end();
}

stock UTIL_removefade(id)
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short(0);
	write_short(0);
	write_short(0);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	message_end();
}

stock UTIL_laserbeam(id, start[3], end[3], color[3] = {0, 50, 255}, duration = 1, width = 1, amplitude = 0)
{
  message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, _, id);
  write_byte(TE_BEAMPOINTS);
  write_coord(start[0]);
  write_coord(start[1]);
  write_coord(start[2]);
  write_coord(end[0]);
  write_coord(end[1]);
  write_coord(end[2]);
  write_short(sprite_laserbeam);
  write_byte(1);
  write_byte(1);
  write_byte(duration);
  write_byte(width);
  write_byte(amplitude);
  write_byte(color[0]);
  write_byte(color[1]);
  write_byte(color[2]);
  write_byte(255);
  write_byte(0);
  message_end();
}

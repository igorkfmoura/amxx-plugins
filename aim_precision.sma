#include <amxmodx>
#include <engine>
#include <beams>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_stocks>
#include <cstrike>
#include <xs>

#define PLUGIN  "Aim Precision"
#define VERSION "0.2"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

new const seed_table[256] =
{
  28985, 27138, 26457, 9451,  17764, 10909, 28790, 8716,  6361,  4853,  17798, 21977, 19643, 20662, 10834, 20103,
  27067, 28634, 18623, 25849, 8576,  26234, 23887, 18228, 32587, 4836,  3306,  1811,  3035,  24559, 18399, 315,
  26766, 907,   24102, 12370, 9674,  2972,  10472, 16492, 22683, 11529, 27968, 30406, 13213, 2319,  23620, 16823,
  10013, 23772, 21567, 1251,  19579, 20313, 18241, 30130, 8402,  20807, 27354, 7169,  21211, 17293, 5410,  19223,
  10255, 22480, 27388, 9946,  15628, 24389, 17308, 2370,  9530,  31683, 25927, 23567, 11694, 26397, 32602, 15031,
  18255, 17582, 1422,  28835, 23607, 12597, 20602, 10138, 5212,  1252,  10074, 23166, 19823, 31667, 5902,  24630,
  18948, 14330, 14950, 8939,  23540, 21311, 22428, 22391, 3583,  29004, 30498, 18714, 4278,  2437,  22430, 3439,
  28313, 23161, 25396, 13471, 19324, 15287, 2563,  18901, 13103, 16867, 9714,  14322, 15197, 26889, 19372, 26241,
  31925, 14640, 11497, 8941,  10056, 6451,  28656, 10737, 13874, 17356, 8281,  25937, 1661,  4850,  7448,  12744,
  21826, 5477,  10167, 16705, 26897, 8839,  30947, 27978, 27283, 24685, 32298, 3525,  12398, 28726, 9475,  10208,
  617,   13467, 22287, 2376,  6097,  26312, 2974,  9114,  21787, 28010, 4725,  15387, 3274,  10762, 31695, 17320,
  18324, 12441, 16801, 27376, 22464, 7500,  5666,  18144, 15314, 31914, 31627, 6495,  5226,  31203, 2331,  4668,
  12650, 18275, 351,   7268,  31319, 30119, 7600,  2905,  13826, 11343, 13053, 15583, 30055, 31093, 5067,  761,
  9685,  11070, 21369, 27155, 3663,  26542, 20169, 12161, 15411, 30401, 7580,  31784, 8985,  29367, 20989, 14203,
  29694, 21167, 10337, 1706,  28578, 887,   3373,  19477, 14382, 675,   7033,  15111, 26138, 12252, 30996, 21409,
  25678, 18555, 13256, 23316, 22407, 16727, 991,   9236,  5373,  29402, 6117,  15241, 27715, 19291, 19888, 19847
};

new bool:enabled[MAX_PLAYERS + 1];
new beams[MAX_PLAYERS + 1];

static const Float:colors[CsTeams][3] = 
{
  {  0.0,  0.0,   0.0},
  {255.0, 50.0,   0.0},
  {  0.0, 50.0, 255.0},
  {  0.0,  0.0,   0.0},
}

static const sprite_laser[] = "sprites/laserbeam.spr";
public plugin_precache( )
{
  precache_model(sprite_laser);
}


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  RegisterHam(Ham_Spawn,  "player", "event_player_spawn",  .Post = true)
  RegisterHam(Ham_Killed, "player", "event_player_killed", .Post = true);

  register_clcmd("say /precision", "cmd_test");
}


public client_connect(id)
{
  enabled[id] = false;
}


public client_disconnected(id)
{
  enabled[id] = false;
  if (is_valid_ent(beams[id]))
  {
    remove_entity(beams[id]);
    beams[id] = 0;
  }
}


public cmd_test(id)
{
  enabled[id] = !enabled[id];
  client_print(id, print_center, "Test %s!", enabled[id] ? "Enabled" : "Disabled");
}


public client_PostThink(id)
{
  new beam = beams[id];
  if (!enabled[id] || !is_user_alive(id))
  {
    if (is_valid_ent(beam))
    {
      remove_entity(beam);
      beams[id] = 0;
    }
      
    return PLUGIN_CONTINUE;
  }
  
  new weapon_ent = cs_get_user_weapon_entity(id);
  new Float:precision = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flAccuracy");
  
  new weapon_name[32];
  entity_get_string(weapon_ent, EV_SZ_classname, weapon_name, charsmax(weapon_name));
  // client_print(id, print_center, "%s", weapon_name);
  
  new Float:velocity[3];
  entity_get_vector(id, EV_VEC_velocity, velocity);

  new Float:speed = xs_vec_len_2d(velocity);
  new flags       = get_entity_flags(id);
  
  new Float:spread;
  if (equal(weapon_name, "weapon_deagle"))
  {
    if (!(flags & FL_ONGROUND))
    {
      spread = 0.04 * (1 - precision);
    }
    else if (speed > 140.0)
    {
      spread = 0.25 * (1 - precision);
    }
    else
    {
      spread = 0.13 * (1 - precision);
    }
  }
  else if (equal(weapon_name, "weapon_ak47"))
  {
    if (!(flags & FL_ONGROUND))
    {
      spread = 0.04 + (0.4 * precision);
    }
    else if (speed > 140.0)
    {
      spread = 0.04 + (0.07 * precision);
    }
    else
    {
      spread = 0.0275 * precision;
    }
  }
  else
  {
    return PLUGIN_CONTINUE;
  }
  
  new Float:eyes[3];
  new Float:view_ofs[3];
  
  entity_get_vector(id, EV_VEC_origin, eyes);
  entity_get_vector(id, EV_VEC_view_ofs, view_ofs);
  
  xs_vec_add(eyes, view_ofs, eyes);
  
  new Float:v_angle[3];
  new Float:punchangle[3];
  new Float:aim[3];
  
  entity_get_vector(id, EV_VEC_v_angle, v_angle);
  entity_get_vector(id, EV_VEC_punchangle, punchangle);
  xs_vec_add(v_angle, punchangle, aim);
    
  EF_MakeVectors(aim);
  get_global_vector(GL_v_forward, aim);
  
  new Float:v_right[3];
  get_global_vector(GL_v_right, v_right);
  
  new Float:v_up[3];
  get_global_vector(GL_v_up, v_up);
  
  new shared_rand = get_ent_data(id, "CBasePlayer", "random_seed");
  // client_print(id, print_chat, "random_seed: %d", shared_rand);
  
  new Float:x;
  new Float:y;
  
  x = UTIL_SharedRandomFloat(shared_rand + 0, -0.5, 0.5) + UTIL_SharedRandomFloat(shared_rand + 1, -0.5, 0.5);
  y = UTIL_SharedRandomFloat(shared_rand + 2, -0.5, 0.5) + UTIL_SharedRandomFloat(shared_rand + 3, -0.5, 0.5);
    
  new Float:aim_end[3];
  
  xs_vec_add_scaled(aim, v_right, x * spread, aim);
  xs_vec_add_scaled(aim, v_up,    y * spread, aim);
  
  xs_vec_add_scaled(eyes, aim, 32.0, eyes);
  xs_vec_add_scaled(eyes, aim, 4096.0, aim_end);
  
  new trace_result;
  engfunc(EngFunc_TraceLine, eyes, aim_end, DONT_IGNORE_MONSTERS, id, trace_result);
  get_tr2(trace_result, TR_vecEndPos, aim_end);
  
  Beam_PointsInit(beam, eyes, aim_end);
  
  return PLUGIN_CONTINUE;
}


public event_player_killed(id)
{
  if (is_valid_ent(beams[id]))
  {
    remove_entity(beams[id]);
    beams[id] = 0;
  }
  
  return HAM_HANDLED;
}


public event_player_spawn(id)
{
  if (!is_user_alive(id))
  {
    return HAM_IGNORED;
  }
  
  if (!is_valid_ent(beams[id]))
  {
    beams[id] = Beam_Create(sprite_laser, 1.0);
  }
  
  new CsTeams:team = cs_get_user_team(id);
  Beam_SetColor(beams[id], colors[team]);
  
  return HAM_HANDLED;
}


// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/dlls/util.cpp#L64
public Float:UTIL_SharedRandomFloat(seed, Float:low, Float:high)
{
  new _low = low;
  new _high = high;
  new range = floatround(high - low);
  
  new glSeed;
  
  // U_Srand()
  glSeed  = seed_table[(seed + _low + _high) & 0xFF];
  
  //U_Random();
  glSeed *= 69069;
  glSeed += seed_table[glSeed & 0xFF] + 1;
  
  //U_Random();
  glSeed *= 69069;
  glSeed += seed_table[glSeed & 0xFF] + 1;
  
  new Float:ret = low;

  if (range)
  {
    glSeed *= 69069;
    glSeed += seed_table[glSeed & 0xFF] + 1;
   
    new Float:offset = float(glSeed & 0xFFFF) / 0x10000;
    ret = (low + offset * range);
  }
  
  return ret;
}

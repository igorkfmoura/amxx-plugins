#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>

#define PLUGIN  "test-fillammo"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

#define PREFIX "^4[FillAmmo]^1"

enum AmmoInfo
{
  WEAPONID,
  CLIP,
  BPAMMO
};

new weapons[][AmmoInfo] =
{
  {CSW_NONE,        0,   0},
  {CSW_P228,       13,  52},
  {CSW_NONE,        0,   0},
  {CSW_SCOUT,      10,  90},
  {CSW_NONE,        0,   0},
  {CSW_XM1014,      7,  32},
  {CSW_NONE,        0,   0},
  {CSW_MAC10,      30, 100},
  {CSW_AUG,        30,  90},
  {CSW_NONE,        0,   0},
  {CSW_ELITE,      30, 120},
  {CSW_FIVESEVEN,  20, 100},
  {CSW_UMP45,      25, 100},
  {CSW_SG550,      30,  90},
  {CSW_GALIL,      35,  90},
  {CSW_FAMAS,      25,  90},
  {CSW_USP,        12, 100},
  {CSW_GLOCK18,    20, 120},
  {CSW_AWP,        10,  30},
  {CSW_MP5NAVY,    30, 120},
  {CSW_M249,      100, 200},
  {CSW_M3,          8,  32},
  {CSW_M4A1,       30,  90},
  {CSW_TMP,        30, 120},
  {CSW_G3SG1,      20,  90},
  {CSW_NONE,        0,   0},
  {CSW_DEAGLE,      7,  35},
  {CSW_SG552,      30,  90},
  {CSW_AK47,       30,  90},
  {CSW_NONE,        0,   0},
  {CSW_P90,        50, 100},
  {CSW_NONE,        0,   0},
  {CSW_NONE,        0,   0},
  {CSW_NONE,        0,   0}
};

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  register_clcmd("say /test", "cmd_test");
}

public cmd_test(id)
{
  for (new slot = CS_WEAPONSLOT_PRIMARY; slot <= CS_WEAPONSLOT_SECONDARY; ++slot)
  {
    new weapon_id = get_ent_data_entity(id, "CBasePlayer", "m_rgpPlayerItems", slot);
    if (is_valid_ent(weapon_id))
    {
      new weapon_type = get_ent_data(weapon_id, "CBasePlayerItem", "m_iId");
      if (weapon_type > 0 && weapon_type <= CSW_P90 && weapons[weapon_type][WEAPONID])
      {
        static weapon_name[32];
        cs_get_item_alias(weapon_type, weapon_name, charsmax(weapon_name));

        cs_set_weapon_ammo(weapon_id, weapons[weapon_type][CLIP]);
        cs_set_user_bpammo(id, weapon_type, weapons[weapon_type][BPAMMO]);

        client_print_color(id, id, "%s Refilling ^3%s^1 ammo...", PREFIX, weapon_name);
      }
    }
  }
}
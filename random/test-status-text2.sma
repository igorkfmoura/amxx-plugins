#include <amxmodx>
#include <engine>
#include <cstrike>

#define PLUGIN  "test-status-text"
#define VERSION "0.2"
#define AUTHOR  "lonewolf"

#define MAX_SBAR_STRING 128

static bool:hooking_statustext[MAX_PLAYERS+1];

enum
{
  SBAR_ID_TARGETTYPE = 1,
  SBAR_ID_TARGETNAME,
  SBAR_ID_TARGETHEALTH,
  SBAR_END
};
  
new bool:enabled[MAX_PLAYERS + 1];

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  register_message(get_user_msgid("StatusValue"), "msg_statusvalue");

  register_clcmd("say /test", "cmd_test");
}

public client_connect(id)
{
  enabled[id] = false;
  hooking_statustext[id] = false;
}


public client_disconnected(id)
{
  enabled[id] = false;
}

public cmd_test(id)
{
  enabled[id] = !enabled[id];
  client_print(id, print_center, "Test %s!", enabled[id] ? "Enabled" : "Disabled");
}

public msg_statusvalue(msgid, msgdest, msgent)
{
  if (!enabled[msgent] || hooking_statustext[msgent])
  {
    return PLUGIN_CONTINUE;
  }

  if (!is_user_alive(msgent))
  {
    return PLUGIN_HANDLED;
  }

  new argc = get_msg_args();
  if (argc != 2)
  {
    return PLUGIN_HANDLED;
  }

  new type = get_msg_arg_int(1);
  if (type != SBAR_ID_TARGETNAME)
  {
    return PLUGIN_CONTINUE;
  }

  new target = get_msg_arg_int(2);

  if (is_user_alive(target))
  {
    hooking_statustext[msgent] = true;
    
    update_statusbar(msgent, target);
    
    hooking_statustext[msgent] = false;
  }
  else 
  {
    clean_statusbar(msgent);
  }

  return PLUGIN_CONTINUE;
}


public update_statusbar(id, target)
{
  new CsTeams:id_team     = cs_get_user_team(id);
  new CsTeams:target_team = cs_get_user_team(target);
  
  new health = floatround(entity_get_float(target, EV_FL_health) / entity_get_float(target, EV_FL_max_health) * 100);
  new armor  = floatround(entity_get_float(target, EV_FL_armorvalue));
  new kills  = get_user_frags(target);
  
  static name[MAX_NAME_LENGTH];
  get_user_name(target, name, charsmax(name));

  // https://github.com/s1lentq/ReGameDLL_CS/blob/9736437cb8e6bff3e0044d91422ef38edce269f2/regamedll/dlls/player.cpp#L7759
  //
  // Original:
  // new const str[32] = "1 %c1: %p2^n2  %h: %i3%%";

  new str[128];
  if (id_team == target_team)
  {
    formatex(str, charsmax(str), "1 '%%p2':^n2  Class: '%s', Health: %d, Armor: %d, Ammo Packs: %d", "Humano", health, armor, kills);
  }
  else
  {
    clean_statusbar(id);
    return;
  }
  
  message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), _, id);
  write_byte(0);
  write_string(str);
  message_end();
}

public clean_statusbar(id)
{  
  message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), _, id);
  write_string(" ");
  message_end();
  
  for (new i = SBAR_ID_TARGETTYPE; i < SBAR_END; ++i)
  {
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusValue"), _, id);
    write_byte(i);
    write_short(0);
    message_end();
  }

}

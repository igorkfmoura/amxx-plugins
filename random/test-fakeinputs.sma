#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <xs>

#define PLUGIN  "test-inputs"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

#define PREFIX "[test-inputs]"

new bool:enabled[MAX_PLAYERS + 1];
new menuid_fakeinput;

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  // register_forward(FM_ClientCommand, "client_command");
  menuid_fakeinput = register_menuid("fakeinput");

  register_menucmd(menuid_fakeinput, 1023, "menu_fakeinput_handler");

  register_clcmd("say /test", "cmd_test");

  set_task(1.0, "print_menu", 531, _, _, "b");
}

public print_menu(id)
{
  new menu;
  new keys;
//   new newmenu;
//   new page;
  
//   new ret = player_menu_info(1, menu, newmenu, page);
//   client_print(1, print_chat, "(print_menu) (%02d) ret: %d, newmenu: %d, menu: %d", 1, ret, newmenu, menu);
  
  get_user_menu(1, menu, keys);
  if (menu == menuid_fakeinput)
  {
    client_print(1, print_chat, "(print_menu) (%02d) viewing menuid_fakeinput: %d", 1, menu);
  }
}

public client_connect(id)
{
  enabled[id] = false;
}


public client_disconnected(id)
{
  enabled[id] = false;
}

public cmd_test(id)
{
  enabled[id] = !enabled[id];
  client_print(id, print_center, "Fakeinput %s!", enabled[id] ? "enabled" : "disabled");

  menu_fakeinput(5234 + id);

  return PLUGIN_HANDLED;
}

public menu_fakeinput(id)
{
  id -= 5234;

  if (enabled[id])
  {
    show_menu(id, 1023, " ", _, "fakeinput");
  }

  return PLUGIN_HANDLED;
}

public menu_fakeinput_handler(id, key)
{
  key = (key + 1) % 10;
  new slotcmd[7];
  formatex(slotcmd, charsmax(slotcmd), "slot%d", key);

  client_print(id, print_chat, "(menu_fakeinput_handler) (%02d) selected '%s'", id, slotcmd);

  client_cmd(id, slotcmd);
  set_task(0.1, "menu_fakeinput", 5234 + id);

  return PLUGIN_HANDLED;
}
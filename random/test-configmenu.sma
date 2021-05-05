#include <amxmodx>
#include <engine>
#include <xs>
#include <cstrike>

#define PLUGIN  "test-configmenu"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

#define PREFIX  "^4[test-menu]^1"

enum Config
{
  CFG_ON = 0,
  CFG_LINE,
  CFG_BOX,
  CFG_NAME,
  CFG_HEALTH_ARMOR,
  CFG_WEAPON,
  CFG_CLIP_AMMO,
  CFG_DISTANCE,
  CFG_TEAMMATES,
  CFG_AIM_VEC,
};

new config[MAX_PLAYERS+1][Config];
new config_default[Config] =
{
  1, // CFG_ON, 
  1, // CFG_LINE,
  1, // CFG_BOX,
  1, // CFG_NAME,
  1, // CFG_HEALTH_ARMOR,
  1, // CFG_WEAPON,
  1, // CFG_CLIP_AMMO,
  1, // CFG_DISTANCE,
  1, // CFG_TEAM_MATES,
  1, // CFG_AIM_VEC,
};

new config_text[Config][33] = 
{
  "Admin Spectator",
  "Display Lines",
  "Show Player's Box",
  "Show Player's Name",
  "Show Health & Armor",
  "Show Weapon",
  "Show Clip & Ammo",
  "Show Distance",
  "Show Teammates",
  "Show Aim Vector",
};

new menu_on_off_text[2][33] = 
{
  "is \rdisabled\w",
  "is \yenabled\w",
};

new menu_config_callback_id;

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  menu_config_callback_id = menu_makecallback("menu_config_callback");

  register_clcmd("say /test",  "cmd_test");
  register_clcmd("say /test2",  "cmd_test2");
  register_clcmd("say /esp",   "cmd_esp");
}


public client_connect(id)
{
  new len = sizeof(config_default);
  for (new i = 0; i < len; ++i)
  {
    config[id][Config:i] = config_default[Config:i];
  }
}


public cmd_test(id)
{
  menu_config(id);
}

public cmd_test2(id)
{
  menu_main(id);
}

public cmd_esp(id)
{
  config[id][CFG_ON] = !config[id][CFG_ON];
  
  static enabled_text[2][33] = {"^3disabled^1", "^4enabled^1"};

  client_print_color(id, print_team_red, "%s %s %s", PREFIX, config_text[CFG_ON], enabled_text[config[id][CFG_ON]]);

  new menu;
  new newmenu;
  new page;

  if (!player_menu_info(id, menu, newmenu, page) || newmenu == -1)
  {
    return;
  }
  
  new item_name[10];
  menu_item_getinfo(newmenu, 0, _, _, _, item_name, charsmax(item_name));

  if (strncmp(item_name, config_text[CFG_LINE], charsmax(item_name)))
  {
    return;
  }

  menu_destroy(newmenu);
  menu_config(id, page);
}


menu_main(id, page=0)
{
  static enable_text[2][33] = {"disable", "enable"};
  new bool:is_enabled = bool:config[id][CFG_ON];

  new title[128];
  formatex(title, charsmax(title), "\wAdmin Spectator %s^n\d(use ^"say /esp^" to %s)^n", menu_on_off_text[is_enabled], enable_text[!is_enabled]);
  
  new menu = menu_create(title, "menu_main_handler");

  enum menu_item
  { 
    text[33], 
    info[33], 
    access,
    callback
  };
  
  new options[][menu_item] = 
  {
    {"Config Menu",                   "", ADMIN_ALL,  -1},
    {"Adjust Cvars \r(Admin only)\r", "", ADMIN_CVAR, -1},
    {"",                              "", ADMIN_ALL,  -1},
    {"Credits",                       "", ADMIN_ALL,  -1}
  }

  new len = sizeof(options);
  for (new i = 0; i < len; ++i)
  {
    if (options[i][text][0] != '^0')
    {
      menu_additem(menu, options[i][text], options[i][info], options[i][access], options[i][callback]);
    }
    else
    {
      menu_addtext2(menu, options[i][text]);
    }
  }

  menu_display(id, menu, page);
}


public menu_main_handler(id, menu, selected)
{
  if (selected == MENU_EXIT  || !is_user_connected(id))
  {
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  switch (selected)
  {
    case 0:
    {
      menu_destroy(menu);
      menu_config(id);
    }
    case 1:
    {
      client_print_color(id, print_team_default, "%s Menu 3 not implemented because it would use the same", PREFIX);
      client_print_color(id, print_team_default, "%s principle as /test menu. If you really want it,", PREFIX);
      client_print_color(id, print_team_default, "%s send me an e-mail igorkelvin@gmail.com", PREFIX);
    }
    case 3:
    {
      menu_credits(id);
      menu_destroy(menu);
      menu_main(id);
    }
  }
  return PLUGIN_HANDLED;
}

menu_credits(id)
{
  static timer[MAX_PLAYERS+1];
  

  new text[192] = "%s v%s^n\
                made by %s^n\
                ^n\
                Thanks for using it!^n\
                ^n\
                Check this plugin and more on:^n\
                https://github.com/igorkelvin/amxx-plugins^n\
                ^n\
                (link on console for easy copy-paste)";

  format(text, charsmax(text), text, PLUGIN, VERSION, AUTHOR);

  if (timer[id] < get_gametime())
  {
    set_hudmessage(50, 255, 0, -1.0, -1.0, 2, 0.1, 2.0, 0.1, 0.1, -1);
    show_hudmessage(id, text);

    timer[id] = floatround(get_gametime()) + 15;
  }
  
  client_print(id, print_console, "^n-------------^n%s v%s by %s^nhttps://github.com/igorkelvin/amxx-plugins^n-------------^n^n", PLUGIN, VERSION, AUTHOR);
  client_cmd(id, "spk ./valve/sound/scientist/c1a3_sci_thankgod.wav");

}


menu_config(id, page=0)
{
  static enable_text[2][33] = {"disable", "enable"};
  new bool:is_enabled = bool:config[id][CFG_ON];

  new title[128];
  formatex(title, charsmax(title), "\wAdmin Spectator %s^n\d(use ^"say /esp^" to %s)^n^n\wPage", menu_on_off_text[is_enabled], enable_text[!is_enabled]);
  
  new menu = menu_create(title, "menu_config_handler");

  new len = sizeof(config_default);
  for (new i = 1; i < len; ++i)
  {
    new item_text[64];
    new Config:item = Config:i;
    new bool:is_enabled = bool:config[id][Config:i];
    new info[2];
    
    num_to_str(is_enabled, info, charsmax(info));
    formatex(item_text, charsmax(item_text), "%s %s", config_text[item], menu_on_off_text[is_enabled])

    menu_additem(menu, item_text, info, ADMIN_ALL, menu_config_callback_id);
  }

  menu_display(id, menu, page);
}


public menu_config_callback(id, menu, item)
{
  new bool:is_enabled = bool:config[id][CFG_ON];
  
  if (is_enabled)
  {
    return ITEM_IGNORE;
  }
  return ITEM_DISABLED;
}

public menu_config_handler(id, menu, selected)
{
  if (selected == MENU_EXIT  || !is_user_connected(id))
  {
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  new Config:item = Config:(selected + 1);
  
  if (selected >= 0 && selected < (sizeof(config_default) - 1))
  {
    config[id][item] = !config[id][item];
  }

  new menu, newmenu, page;
  player_menu_info(id, menu, newmenu, page);

  menu_destroy(menu);
  menu_config(id, page);
  return PLUGIN_HANDLED;
}

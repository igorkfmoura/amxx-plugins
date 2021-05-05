#include <amxmodx>
#include <engine>
#include <xs>

#define PLUGIN  "test-conditionals"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

new bool:enabled[MAX_PLAYERS + 1];

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  register_clcmd("say /test", "cmd_test");
}

public client_connect(id)
{
  enabled[id] = false;
}


public client_disconnected(id)
{
  enabled[id] = false;
}

new c = 10;

public cmd_test(id)
{
  enabled[id] = !enabled[id];
  
  static a = 0;
  static b = 5;
  
  if (a++ != 0 && b++ == 5 || do_test())
  {
    // will be executed only first time
	client_print(id, print_chat, "Inside a = %d, b = %d, c = %d", a, b, c);
	return;
  }
  
  client_print(id, print_chat, "Outside a = %d, b = %d, c = %d", a, b, c);
  
}

// never will be executed
public do_test()
{
  client_print(0, print_chat, "Inside do_test()");
  c++;
}

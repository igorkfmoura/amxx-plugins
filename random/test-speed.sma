#include <amxmodx>
#include <engine>
#include <xs>

#define PLUGIN  "test-speed"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

new bool:enabled[MAX_PLAYERS + 1];

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  register_clcmd("say /speed", "cmd_speed");
}

public client_connect(id)
{
  enabled[id] = false;
}


public client_disconnected(id)
{
  enabled[id] = false;
}

public cmd_speed(id)
{
  enabled[id] = !enabled[id];
  client_print(0, print_center, "Test %s!", enabled[id] ? "Enabled" : "Disabled");
}


public client_PostThink(id)
{ 
  if (!enabled[id] || !is_user_connected(id))
  {
    return PLUGIN_CONTINUE;
  }
    
  new Float:velocity[3];
  new Float:speed;
  
  entity_get_vector(id, EV_VEC_velocity, velocity);
  speed = xs_vec_len_2d(velocity);
  
  client_print(id, print_center, "[%.3f, %.3f]", speed, velocity[2]);
  
  return PLUGIN_CONTINUE;
}

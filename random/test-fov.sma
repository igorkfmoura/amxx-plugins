#include <amxmodx>
#include <engine>

#define PLUGIN  "test-fov"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  register_clcmd("say", "cmd_say");
}


public cmd_say(id)
{
  if (!is_user_connected(id))
  {
    return PLUGIN_HANDLED;
  }

  new saytext[64];
  read_args(saytext, charsmax(saytext));
  remove_quotes(saytext);

  new command[32];
  new arg[32];
  parse(saytext, command, charsmax(command), arg, charsmax(arg));

  new fov = str_to_num(arg);
  if (!fov && arg[0] != '0')
  {
      set_fov(id, 90);
  }
  else
  {
    if (equal(command, "/fov"))
    {
      set_fov(id, fov);

      return PLUGIN_HANDLED;
    }
  }
  
  return PLUGIN_CONTINUE;
}


public set_fov(id, fov)
{
  if(id && !is_user_connected(id))
  {
  	return;
  }

  static MSG_SetFOV;  
  if(!MSG_SetFOV)
  	MSG_SetFOV = get_user_msgid("SetFOV");  

  message_begin(MSG_ONE_UNRELIABLE, MSG_SetFOV, _, id);
  write_byte(fov);
  message_end();
}

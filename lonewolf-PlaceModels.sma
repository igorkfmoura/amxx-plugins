#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <json>

#define PLUGIN  "PlaceModels"
#define VERSION "0.0.3"
#define AUTHOR  "lonewolf"

new const CHAT_PREFIX[] = "^4[PlaceModels]^1"
// new const MODEL_PATH[] = "models/bannertest.mdl";
new JSON_FILE[96] = "PlaceModels.json";
new CONFIG_PATH[64];

new JSON:root;

enum _:Model
{
  ENTITY,
  MODEL_NUM,
  SKIN,
  Float:ORIGIN[3],
  Float:ANGLES[3]
};

enum _:Precache
{
  PATH[64],
  SKINS_NUM
};

new Array:models;
new Array:models_precached;

public plugin_end()
{
  ArrayDestroy(models);
  ArrayDestroy(models_precached);
}


public plugin_precache()
{
  models = ArrayCreate(Model);
  models_precached = ArrayCreate(Precache);

  get_configsdir(CONFIG_PATH, charsmax(CONFIG_PATH));
  format(JSON_FILE, charsmax(JSON_FILE), "%s/%s", CONFIG_PATH, JSON_FILE);

  root = json_parse(JSON_FILE, .is_file=true, .with_comments=true);

  if (root == Invalid_JSON)
  {
    set_fail_state("[%s] Failed to parse file ^"%s^"!", PLUGIN, JSON_FILE);
  }

  if (json_get_type(root) != JSONObject)
  {
    set_fail_state("[%s] Json isn't an object!", PLUGIN);
  }

  if (!json_object_has_value(root, "models_precached"))
  {
    set_fail_state("[%s] Json don't have 'models_precached' value!", PLUGIN);
  }

  new JSON:models_to_precache = json_object_get_value(root, "models_precached");
  if (models_to_precache == Invalid_JSON)
  {
    set_fail_state("[%s] 'models_precached' == Invalid_JSON!", PLUGIN);
  }
  
  if (json_get_type(models_to_precache) != JSONArray)
  {
    set_fail_state("[%s] 'models_precached' is not an array!", PLUGIN);
  }
  
  new JSON:tmp;
  new count = json_array_get_count(models_to_precache);
  for (new i = 0; i < count; ++i)
  {
    tmp = json_array_get_value(models_to_precache, i);
    if (tmp != Invalid_JSON)
    {
      new model_to_precache[Precache];
      json_object_get_string(tmp, "path", model_to_precache[PATH], charsmax(model_to_precache[PATH]));
      model_to_precache[SKINS_NUM] = json_object_get_number(tmp, "skins_num");

      precache_model(model_to_precache[PATH]);
      ArrayPushArray(models_precached, model_to_precache);

      server_print("[%s] Precached '%s'.", PLUGIN, model_to_precache[PATH]);
    }
  }
  
  json_free(tmp);
  json_free(models_to_precache)
}


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  models_load_json();

  register_clcmd("test", "cmd_test");
  register_clcmd("say /place", "cmd_place");
}


public cmd_test(id)
{
  if (!is_user_connected(id))
  {
    return PLUGIN_HANDLED;
  }

  new newmodel = model_create(0, random_num(0, 1));
  model_place_on_crosshair(id, newmodel);

  return PLUGIN_CONTINUE;
}


public cmd_place(id)
{
  if (!is_user_connected(id))
  {
    return PLUGIN_HANDLED;
  }

  if (!(get_user_flags(id) & ADMIN_CVAR))
  {
    client_print_color(id, print_team_red, "%s ^4/place^1 command is exclusive to ^3admins^1.");
    return PLUGIN_HANDLED;
  }

  menu_place(id);

  return PLUGIN_HANDLED;
}


public menu_place(id)
{
  new menu = menu_create("Menu PlaceModels", "menu_place_handler");

  new count = ArraySize(models);
  for (new i = 0; i < count; ++i)
  {
    new item[64];
    new model[Model];
    new precached[Precache];

    ArrayGetArray(models, i, model);
    ArrayGetArray(models_precached, model[MODEL_NUM], precached);

    format(item, charsmax(item), "\y%s\d [%d]", precached[PATH], model[SKIN]);
    menu_additem(menu, item, fmt("%s", i), ADMIN_CVAR);
  }

  menu_additem(menu, "New", "new", ADMIN_CVAR);
  menu_display(id, menu);
}


public menu_place_handler(id, menu, item)
{
  return PLUGIN_CONTINUE;
}


public models_load_json()
{
  new JSON:models_placed = json_object_get_value(root, "models_placed");

  if (json_get_type(models_placed) != JSONArray)
  {
    json_free(models_placed);
    set_fail_state("[%s] 'models_placed' is not an array!", PLUGIN);
  }
  
  new JSON:tmp;
  new JSON:tmp2;
  new count = json_array_get_count(models_placed);
  for (new i = 0; i < count; ++i)
  {
    tmp = json_array_get_value(models_placed, i);
    if (tmp == Invalid_JSON)
    {
      continue;
    }
    
    new model[Model];
    model[MODEL_NUM] =  json_object_get_number(tmp, "model_num");
    model[SKIN]      =  json_object_get_number(tmp, "skin");

    tmp2 = json_object_get_value(tmp, "origin");
    
    new Float:origin[3];
    model[ORIGIN][0] = origin[0] = json_array_get_real(tmp2, 0); 
    model[ORIGIN][1] = origin[1] = json_array_get_real(tmp2, 1);
    model[ORIGIN][2] = origin[2] = json_array_get_real(tmp2, 2);

    tmp2 = json_object_get_value(tmp, "angles");

    new Float:angles[3];
    model[ANGLES][0] = angles[0] = json_array_get_real(tmp2, 0); 
    model[ANGLES][1] = angles[1] = json_array_get_real(tmp2, 1);
    model[ANGLES][2] = angles[2] = json_array_get_real(tmp2, 2);

    model[ENTITY] = model_create(model[MODEL_NUM], model[SKIN]);
    model_move(model[ENTITY], origin, angles);

    ArrayPushArray(models, model);
  }
  
  json_free(models_placed);
  json_free(tmp);
  json_free(tmp2);
}


public model_create(model_num, skin)
{
  new model = create_entity("info_target");
  if (!is_valid_ent(model))
  {
    set_fail_state("Failed to create entity ^"%s^".", "info_target");
    return PLUGIN_HANDLED;
  }

  new precached[Precache];
  ArrayGetArray(models_precached, model_num, precached);

  entity_set_string(model, EV_SZ_classname, "placedmodel");
  entity_set_model(model, precached[PATH]);
  entity_set_int(model, EV_INT_skin, skin);

  server_print("[%s] Created model '%s' with skin %d [%d].", PLUGIN, precached[PATH], skin, model);

  return model;
}


public model_place_on_crosshair(id, model)
{
  new Float:start[3];
  new Float:view_ofs[3];

  entity_get_vector(id, EV_VEC_origin, start);
  entity_get_vector(id, EV_VEC_view_ofs, view_ofs);
  start[0] += view_ofs[0];
  start[1] += view_ofs[1];
  start[2] += view_ofs[2];

  new Float:angles[3];
  new Float:v_forward[3];
  entity_get_vector(id, EV_VEC_v_angle, angles);
  angle_vector(angles, ANGLEVECTOR_FORWARD, v_forward);
  
  new Float:end[3];
  end[0] = start[0] + v_forward[0] * 2000.0;
  end[1] = start[1] + v_forward[1] * 2000.0;
  end[2] = start[2] + v_forward[2] * 2000.0;
  
  trace_line(-1, start, end, end);
  // if (!ret && traceresult(TR_Hit) == -1)
  // {
  //   client_print_color(id, print_team_default, "%s Failed on trace! ret: %d, TR_Hit: %d", CHAT_PREFIX, ret, traceresult(TR_Hit));
  //   return PLUGIN_CONTINUE;
  // }

  new Float:normal[3];
  traceresult(TR_PlaneNormal, normal);

  normal[0] *= -1.0;
  normal[1] *= -1.0;
  normal[2] *= -1.0;

  end[0] += normal[0] * -15.0;
  end[1] += normal[1] * -15.0;
  end[2] += normal[2] * -15.0;
  
  vector_to_angle(normal, angles);

  model_move(model, end, angles);

  return PLUGIN_CONTINUE;
}


public model_move(model, Float:origin[3], Float:angles[3])
{
  if (!is_valid_ent(model))
  {
    return;
  }

  entity_set_origin(model, origin);
  entity_set_vector(model, EV_VEC_angles, angles);

  client_print_color(0, print_team_default, "%s Placed model #%d ^4successfully^1.", CHAT_PREFIX, model);
  client_print_color(0, print_team_red,     "%s  ORIGIN: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, origin[0], origin[1], origin[2]);
  client_print_color(0, print_team_blue,    "%s  ANGLES: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, angles[0], angles[1], angles[2]);
}
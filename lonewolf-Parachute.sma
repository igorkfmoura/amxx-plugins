#include <amxmodx>
#include <engine>
#include <fun>
#include <hamsandwich>

#define PLUGIN  "RECRUTA: Paraquedas Lite + NoAccel"
#define VERSION "1.2"
#define AUTHOR  "MOISES nPQ + lonewolf"

new xCvarSpeed;
new xCvarNoAccel;
new xKeepSpeed[33];
new Float:xSpeedOld[33];
new Float:xOldUserGravity[33];
new xCvarMaxSpeed;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	xCvarSpeed   = register_cvar("parachute_speed", "60"); // 60 � A VELOCIDADE EM QUE O PLAYER CAI USANDO PARAQUEDAS
	xCvarNoAccel = register_cvar("parachute_noaccel", "1"); // 1 -> Ativado, 0 -> Normal sem interferir
	xCvarMaxSpeed = register_cvar("parachute_maxspeed", "400"); // M�xima velocidade em units/seconds (correndo com faca = 250)

	RegisterHam(Ham_Spawn, "player", "xPlayerSpawnPost", true);
}

public client_disconnected(id)
{
	xSpeedOld[id]  = 0.0;
	xOldUserGravity[id] = 0.0;
	xKeepSpeed[id] = false;
}

public xPlayerSpawnPost(id)
{
	if(!is_user_alive(id)) 
	{
		return HAM_IGNORED;
	}

	xSpeedOld[id]  = 0.0;
	xKeepSpeed[id] = false;
	
	// fixar gravidade real de outros plugins, evita conflito :)
	xOldUserGravity[id] = entity_get_float(id, EV_FL_gravity)
	
	return HAM_IGNORED;
}

public client_PreThink(id)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE;
	}
	
	static Float:xFallSpeed, xButton, xFlags, Float:xMaxSpeed;

	xFallSpeed = (get_pcvar_float(xCvarSpeed) - 8.0) * -1.0; // Compensar a falta do 'set_user_gravity'
	xFallSpeed = (xFallSpeed >= 0.0) ? -52.0 : xFallSpeed;   // Pra n�o dar problema caso algu�m configure errado
	
	xMaxSpeed  = get_pcvar_float(xCvarMaxSpeed);
	xButton    = get_user_button(id);
	xFlags     = get_entity_flags(id);
	
	if((xFlags & FL_ONGROUND))
	{
		if(get_user_gravity(id) == 0.1) //todo: usar xKeepSpeed, fiquei com pregui�a de abrir o cs
		{
			set_user_gravity(id, xOldUserGravity[id]);
		}
			
		return PLUGIN_CONTINUE;
	}

	if(!(xButton & IN_USE))
	{
		if(get_user_gravity(id) == 0.1)
		{
			set_user_gravity(id, xOldUserGravity[id]);
		}
		
		xKeepSpeed[id] = false;
		return PLUGIN_CONTINUE;
	}
	
	static Float:xVelocity[3];
	entity_get_vector(id, EV_VEC_velocity, xVelocity);
	
	// if (xVelocity[2] >= 0.0)
	if (xVelocity[2] >= xFallSpeed)
	{
		set_user_gravity(id, xOldUserGravity[id]);
		
		return PLUGIN_CONTINUE;
	}
	
	// L�gica do NoAccel
	new xNoAccel = get_pcvar_num(xCvarNoAccel);
	new Float:xSpeed = floatsqroot(xVelocity[0] * xVelocity[0] + xVelocity[1] * xVelocity[1]); // M�dulo da velocidade independente da dire��o
	
	if (xKeepSpeed[id] && xNoAccel && (xSpeed > xMaxSpeed) && (xSpeed > xSpeedOld[id]))
	{
		new Float:c = xSpeedOld[id] / xSpeed;
		
		//Atenua as velocidades sem mudar a dire��o
		xVelocity[0] *= c;
		xVelocity[1] *= c;
			
		xSpeed = c * xSpeed;
	}
	
	// Debug de velocidade, tirar quando terminar de testar
	//set_hudmessage(200, 100, 0, -1.0, 0.35, 0, 6.0, 1.0, 0.1, 0.2, -1);
	//show_hudmessage(id, "%.3f units/second^n%.3f vertical", xSpeed, xVelocity[2])
	
	set_user_gravity(id, 0.1);
	xKeepSpeed[id] = true;
	xSpeedOld[id]  = xSpeed;
	// Fim da L�gica do NoAccel
	
	xVelocity[2] = (xVelocity[2] + 40.0 < xFallSpeed) ? xVelocity[2] + 40.0 : xFallSpeed;
	entity_set_vector(id, EV_VEC_velocity, xVelocity);
	
	return PLUGIN_CONTINUE;
}

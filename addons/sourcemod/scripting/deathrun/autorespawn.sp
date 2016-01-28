bool	autorespawn_Active	= false;
int		autorespawn_Seconds	= 0;
Handle	autorespawn_TimerHandle;

void RoundStart_AutoRespawn ( )
{
	if ( !config_AutoRespawn.IntValue )
	{
		return;
	}
	
	autorespawn_Active		= true;
	autorespawn_Seconds		= config_AutoRespawn.IntValue;
	autorespawn_TimerHandle	= CreateTimer ( 1.0, respawn_Timer );
}

void PluginStart_AutoRespawn ( )
{
	config_AutoRespawn		= CreateConVar ( "dr_autorespawn",		"15",	"How many seconds after round start players respawn?",	FCVAR_NONE, true, 0.0, true, 600.0	);
	config_AutoRespawnHint	= CreateConVar ( "dr_autorespawn_hint",	"1",	"Display autorespawn timer hint?",						FCVAR_NONE, true, 0.0, true, 1.0	);
}

void PlayerDeath_AutoRespawn ( Event ev )
{
	if ( !config_AutoRespawn.IntValue )
	{
		return;
	}
	
	int client = GetClientOfUserId ( ev.GetInt ( "userid" ) );
	
	// check player is not choosen and timer active
	if ( autorespawn_Active && ( GetClientTeam ( client ) == GetPlayersTeam ( ) ) )
	{
		// respawn with delay in 1 second
		CreateTimer ( 1.0, respawn_SpawnTimer, client );
	}
}

void RoundEnd_AutoRespawn ( )
{
	// if round ended less then timer - destroy them
	autorespawn_Active = false;
}

public Action respawn_Timer ( Handle timer )
{
	if ( config_AutoRespawn.IntValue && autorespawn_Active )
	{
		// count here
		autorespawn_Seconds--;
		
		if ( config_AutoRespawnHint.BoolValue )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintHintTextToAll (	"  {{#00FFFF==%t}}\n  %t", "AUTORESPAWN", "AUTORESPAWN_TIME_LEFT", autorespawn_Seconds );
			}
			else if ( GameVersion == Engine_CSS )
			{
				PrintHintTextToAll ( "%t: %t", "AUTORESPAWN", "AUTORESPAWN_TIME_LEFT", autorespawn_Seconds );
			}
		}
		
		// if another timer in this handle - destroy this
		if ( autorespawn_TimerHandle != INVALID_HANDLE )
		{
			KillTimer ( autorespawn_TimerHandle );
		}
		
		// if count finished (0 seconds)
		if ( autorespawn_Seconds <= 0 )
		{
			autorespawn_Active = false;
		}
		
		autorespawn_TimerHandle = CreateTimer ( 1.0, respawn_Timer );
	}
}

public Action respawn_SpawnTimer ( Handle timer, int client )
{
	if ( IsClientInGame( client ) )
	{
		CS_RespawnPlayer ( client );
	}
}
void PluginStart_Events( )
{
	HookEvent( "player_death",		event_PlayerDeath, 		EventHookMode_Pre	);
	HookEvent( "player_disconnect",	event_PlayerDisconnect, EventHookMode_Pre	);
	HookEvent( "player_connect",	event_PlayerConnect, 	EventHookMode_Pre	);
	HookEvent( "player_team",		event_PlayerTeam,		EventHookMode_Pre	);
	HookEvent( "round_end",			event_RoundEnd								);
	HookEvent( "round_start",		event_RoundStart							);
}

public Action event_PlayerTeam ( Event ev, const char[] name, bool dontBroadcast )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action event_PlayerConnect ( Event ev, const char[] name, bool dontBroadcast )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action event_RoundStart ( Event ev, const char[] name, bool dontBroadcast )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	RoundStart_AutoRespawn	( );
	RoundStart_Random		( );
	
	return Plugin_Continue;
}

public Action event_PlayerDisconnect ( Event ev, const char[] name, bool dontBroadcast )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	PlayerDisconnect_Bans	( ev );
	PlayerDisconnect_Random	( ev );
	
	return Plugin_Handled;
}

public Action event_RoundEnd ( Event ev, const char[] name, bool dontBroadcast )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	RoundEnd_Random			(    );	
	RoundEnd_WinPoints		( ev );
	RoundEnd_AutoRespawn	(    );
	
	return Plugin_Continue;
}

public Action event_PlayerDeath( Event ev, const char[] name, bool dontBroadcast )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	PlayerDeath_AutoRespawn	( ev );
	PlayerDeath_SaveScores	( ev );
	
	int client = GetClientOfUserId ( ev.GetInt ( "userid" ) );
	int attacker = GetClientOfUserId ( ev.GetInt ( "attacker" ) );
	
	if ( ( config_RandomPlayers.IntValue > 1 ) && ( attacker == 0 ) && ( GetClientTeam ( client ) == GetPlayersTeam ( ) ) )
	{
		int choosen = GetChoosenID ( );
		
		if ( choosen == 0 )
		{
			ev.SetInt ( "attacker",	0 );
		}
		else
		{
			ev.SetInt ( "attacker",	GetClientUserId ( choosen )	);
		}
		
		ev.SetString ( "weapon", "inferno" );
	}
	
	return Plugin_Continue;
}
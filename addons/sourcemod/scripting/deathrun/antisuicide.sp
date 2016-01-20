void PluginStart_AntiSuicide ( )
{
	config_AntiSuicide = CreateConVar ( "dr_antisuicide", "1", "Enable antisuicide for choosens?", FCVAR_NONE, true, 0.0, true, 1.0 );
	
	RegConsoleCmd (	"kill",		command_Suicide  );
	RegConsoleCmd (	"explode",	command_Suicide  );
	RegConsoleCmd (	"spectate",	command_Spectate );
}

public Action command_Spectate ( int client, int args )
{
	if ( !config_Enabled.BoolValue || !config_RandomPlayers.IntValue || !config_AntiSuicide.BoolValue )
	{
		return Plugin_Continue;
	}
	
	if ( ( GetClientTeam ( client ) == config_RandomPlayers.IntValue ) && ( config_RandomPlayers.IntValue != 1 ) )
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action command_Suicide ( int client, int args )
{
	if ( !config_Enabled.BoolValue || !config_RandomPlayers.IntValue || !config_AntiSuicide.BoolValue )
	{
		return Plugin_Continue;
	}
	
	if ( ( GetClientTeam ( client ) == config_RandomPlayers.IntValue ) && ( config_RandomPlayers.IntValue != 1 ) )
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CHOOSENS_CANT_SUICIDE" );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CHOOSENS_CANT_SUICIDE" );
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
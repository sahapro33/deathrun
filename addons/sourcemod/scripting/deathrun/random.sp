int RoundCounter = 0;

void PluginStart_Random ( )
{
	config_RandomPlayers	= CreateConVar ( "dr_random",		"2", "Type of player randomizing, or disable this feature",	FCVAR_NONE, true, 0.0, true, 3.0	);
	config_RandomRate		= CreateConVar ( "dr_random_rate",	"0", "How many players for one choosen player",				FCVAR_NONE, true, 0.0, true, 64.0	);
	
	RegConsoleCmd ( "jointeam", command_JoinTeam );
}

void OnMapStart_Random ( )
{
	RoundCounter = 0;
}

void RoundStart_Random ( )
{
	if ( config_RandomPlayers.IntValue < 2 )
	{
		return;
	}
	
	if ( RoundCounter == 0 )
	{
		CreateTimer ( 1.5, FixForFirstRound );
	}
	
	RoundCounter++;
}

// Fix for players on choosens spawn
// Fix for choosen immortality
public Action FixForFirstRound ( Handle timer )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame ( i ) || !IsPlayerAlive ( i ) )
		{
			continue;
		}
		
		CS_RespawnPlayer ( i );
	}
	
	return Plugin_Continue;
}

public Action command_JoinTeam( int client, int args )
{
	if ( !config_Enabled.BoolValue || ( config_RandomPlayers.IntValue == 0 ) )
	{
		return Plugin_Continue;
	}
	
	if ( !IsClientInGame ( client ) )
	{
		return Plugin_Continue;
	}
	
	char buffer [ 2 ];
	int  startidx = 0;
	
	if ( !GetCmdArgString ( buffer, sizeof( buffer ) ) )
	{
		return Plugin_Handled;
	}
	
	if ( buffer	[ strlen( buffer ) - 1 ] == '"' )
	{
		buffer	[ strlen( buffer ) - 1 ] = '\0';
		startidx = 1;
	}
	
	int CurrentTeam		= GetClientTeam			( client				);
	int SelectedTeam	= StringToInt			( buffer [ startidx ]	);
	
	int ChoosensNum		= GetTeamClientCount	( CS_TEAM_T				);
	
	int ChoosensTeam	= config_RandomPlayers.IntValue;
	int PlayersTeam		= GetPlayersTeam ( );
		
	if ( SelectedTeam == ChoosensTeam )
	{
		if ( ChoosensNum == 0 )
		{
			ChangeClientTeam ( client, ChoosensTeam );
		}
		else if ( CurrentTeam != PlayersTeam )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_CHOOSENS_TEAM" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_CHOOSENS_TEAM" );
			}
			
			if ( CurrentTeam != ChoosensTeam )
			{
				ChangeClientTeam ( client, PlayersTeam );
			}
		}
		
	}
	else if ( SelectedTeam == PlayersTeam )
	{
		if ( CurrentTeam != ChoosensTeam )
		{
			ChangeClientTeam ( client, PlayersTeam );
		}
		else
		{
			if ( config_AntiSuicide.BoolValue )
			{
				if ( GameVersion == Engine_CSGO )
				{
					CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
				}
				else if ( GameVersion == Engine_CSS )
				{
					CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
				}
			}
			else
			{
				ChangeClientTeam ( client, PlayersTeam );
			}
		}
	}
	else if ( ( SelectedTeam == CS_TEAM_SPECTATOR ) || ( SelectedTeam == CS_TEAM_NONE ) )
	{
		if ( CurrentTeam != ChoosensTeam )
		{
			ChangeClientTeam ( client, CS_TEAM_SPECTATOR );
		}
		else
		{
			if ( config_AntiSuicide.BoolValue )
			{
				if ( GameVersion == Engine_CSGO )
				{
					CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
				}
				else if ( GameVersion == Engine_CSS )
				{
					CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
				}
			}
			else
			{
				ChangeClientTeam ( client, CS_TEAM_SPECTATOR );
			}
		}
	}
	
	return Plugin_Handled;
}

void RoundEnd_Random ( )
{
	if ( !config_RandomPlayers.IntValue )
	{
		return;
	}
	
	if ( config_RandomPlayers.IntValue == 1 )
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "MIXING_PLAYERS" );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "MIXING_PLAYERS" );
		}
		
		CreateTimer ( 1.0, MixingPlayers );
	}
	else
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_CHOOSENS" );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_CHOOSENS" );
		}
		
		CreateTimer ( 1.0, ChoosePlayers );
	}
	
	// round end immortality (after change player team some players can kill)
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame ( i ) || !IsPlayerAlive ( i ) )
		{
			continue;
		}
		
		SetEntProp ( i, Prop_Data, "m_takedamage", 0, 1 );
	}
}

void PlayerDisconnect_Random ( Event ev )
{
	if ( config_RandomPlayers.IntValue > 1 )
	{
		int client = GetClientOfUserId ( ev.GetInt ( "userid" ) );
		
		if ( !IsClientInGame( client ) || GetClientTeam ( client ) == config_RandomPlayers.IntValue )
		{
			if ( GetTeamClientCount ( config_RandomPlayers.IntValue ) <= 1 )
			{
				int ChoosenPlayer = GetRandomPlayer ( );
				
				if ( ChoosenPlayer == -1 )
				{
					if ( GameVersion == Engine_CSGO )
					{
						CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
					}
					else if ( GameVersion == Engine_CSS )
					{
						CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
					}
					
					return;
				}
				
				NewChoosens [ ChoosenPlayer ] = true;
				
				char name [ 16 ];
				GetClientName ( ChoosenPlayer, name, sizeof ( name ) );
				
				if ( GameVersion == Engine_CSGO )
				{
					CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "REPLACE_CHOOSEN", name );
				}
				else if ( GameVersion == Engine_CSS )
				{
					CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "REPLACE_CHOOSEN", name );
				}
				
				CS_SwitchTeam		( ChoosenPlayer, config_RandomPlayers.IntValue	);
				CS_RespawnPlayer	( ChoosenPlayer				);
			}
		}
	}
}

int GetChoosenID ( )
{
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame ( i ) )
		{
			continue;
		}
		
		if ( GetClientTeam ( i ) == config_RandomPlayers.IntValue )
		{
			return i;
		}
	}
	
	return 0;
}

public Action MixingPlayers ( Handle timer )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	int PlayersInTeam = view_as < int > ( GetPlayersCount() / 2 );
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame ( i ) )
		{
			continue;
		}
		
		if ( GetClientTeam ( i ) < 2 )
		{
			continue;
		}
		
		int RandomTeam = GetRandomInt ( CS_TEAM_T, CS_TEAM_CT );
		
		if ( GetTeamClientCount ( RandomTeam )  < PlayersInTeam )
		{
			CS_SwitchTeam ( i, RandomTeam );
		}
		else
		{
			CS_SwitchTeam ( i, AnotherTeam ( RandomTeam ) );
		}
	}
	
	return Plugin_Continue;
}

public Action ChoosePlayers ( Handle timer )
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	int NewTeam = config_RandomPlayers.IntValue;
	int OldTeam = GetPlayersTeam( );
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		OldChoosens [ i ] = false;
		NewChoosens [ i ] = false;
		
		if ( !IsClientInGame ( i ) )
		{
			continue;
		}
		
		if ( GetClientTeam ( i ) == NewTeam )
		{
			CS_SwitchTeam ( i, OldTeam );
			OldChoosens [ i ] = true;
		}
	}
	
	int ChoosensNum = 1;
	
	if ( config_RandomRate.IntValue != 0 )
	{
		ChoosensNum = view_as < int > ( GetTeamClientCount ( OldTeam ) / config_RandomRate.IntValue );
	}
	
	char buffer [ 256 ];
	
	for ( int i = 0; i < ChoosensNum; i++ )
	{
		int ChoosenPlayer = GetRandomPlayer ( );
		
		if ( ChoosenPlayer == -1 )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
			}
			
			return Plugin_Continue;
		}
		
		NewChoosens [ ChoosenPlayer ] = true;
		
		char name [ 16 ];
		GetClientName ( ChoosenPlayer, name, sizeof ( name ) );
		
		
		if ( ChoosensNum == 1 )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "NEW_CHOOSEN", name );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "NEW_CHOOSEN", name );
			}
		}
		else
		{
			if ( i == 0 )
			{
				Format ( buffer, sizeof( buffer ), "{RED}%s", name );
			}
			else
			{
				Format ( buffer, sizeof( buffer ), "%s{LIGHTGREEN}, {RED}%s", buffer, name );
			}
		}
		
		CS_SwitchTeam ( ChoosenPlayer, NewTeam );
		
		if ( IsPlayerAlive ( ChoosenPlayer ) )
		{
			CS_RespawnPlayer	( ChoosenPlayer										);
			SetEntProp			( ChoosenPlayer, Prop_Data, "m_takedamage", 0, 1	);
		}
	}
	
	if ( ChoosensNum != 1 )
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t%s", "DEATHRUN", "NEW_CHOOSENS", buffer );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t%s", "DEATHRUN", "NEW_CHOOSENS", buffer );
		}
	}
	
	return Plugin_Continue;
}

int GetRandomPlayer ()
{
	int[]	PlayerList = new int [ MaxClients + 1 ];
	int		PlayerCount;
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame ( i ) )
		{
			continue;
		}
		
		if ( GetClientTeam ( i ) < 2 )
		{
			continue;
		}
		
		if ( NewChoosens [ i ] || OldChoosens [ i ] )
		{
			continue;
		}
		
		PlayerList [ PlayerCount++ ] = i;
	}
	
	if ( PlayerCount == 0 )
	{
		return -1;
	}
	
	return PlayerList [ GetRandomInt ( 0, PlayerCount - 1 ) ];
}
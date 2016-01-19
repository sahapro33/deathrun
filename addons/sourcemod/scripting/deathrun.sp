#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgo_colors>
#include <morecolors>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_NAME			"Deathrun"
#define PLUGIN_DESCRIPTION	"Deathrun manager for CS:S and CS:GO"
#define PLUGIN_VERSION		"2.0.dev6"
#define PLUGIN_AUTHOR		"selax"
#define PLUGIN_URL			"https://github.com/selax/deathrun"

#define ROUNDEND_CTS_WIN			8
#define ROUNDEND_TERRORISTS_WIN		9

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= PLUGIN_URL
};

EngineVersion GameVersion;

Handle	config_Enabled;
Handle	config_BlockUsePickup;
Handle	config_MinPlayers;
Handle	config_Scores;
Handle	config_RandomPlayers;
Handle	config_RandomRate;
Handle	config_AutoRespawn;
Handle	config_AutoRespawnHint;
Handle	config_AutoBan;

bool	OldChoosens	[ MAXPLAYERS + 1 ];
bool	NewChoosens	[ MAXPLAYERS + 1 ];

int		kills		[ MAXPLAYERS + 1 ];
int		deaths		[ MAXPLAYERS + 1 ];
int		assists		[ MAXPLAYERS + 1 ];
int		score		[ MAXPLAYERS + 1 ];

bool	respawn_Active	= false;
int		respawn_Seconds	= 0;
Handle	respawn_TimerHandle;

public void OnPluginStart()
{
	GameVersion = GetEngineVersion( );
	
	CreateConVar( "dr_version", PLUGIN_VERSION, PLUGIN_URL, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	config_Enabled			= CreateConVar( "dr_enable",			"1",	"Enable the deathrun manager plugin?",					FCVAR_NONE, true, 0.0, true, 1.0	);
	config_BlockUsePickup	= CreateConVar( "dr_blockusepickup",	"1",	"Block pickup weapons by use?",							FCVAR_NONE, true, 0.0, true, 1.0	);
	config_MinPlayers		= CreateConVar( "dr_minplayers",		"4",	"Minimum players for deathrun plugin work",				FCVAR_NONE, true, 2.0, true, 16.0	);
	config_Scores			= CreateConVar( "dr_scores",			"1",	"Enable the scores manager?",							FCVAR_NONE, true, 0.0, true, 1.0	);
	config_RandomPlayers	= CreateConVar( "dr_random",			"2",	"Type of player randomizing, or disable this feature",	FCVAR_NONE, true, 0.0, true, 3.0	);
	config_RandomRate		= CreateConVar( "dr_random_rate",		"0",	"How many players for one choosen player",				FCVAR_NONE, true, 0.0, true, 64.0	);
	config_AutoRespawn		= CreateConVar( "dr_autorespawn",		"15",	"How many seconds after round start players respawn?",	FCVAR_NONE, true, 0.0, true, 99.0	);
	config_AutoRespawnHint	= CreateConVar( "dr_autorespawn_hint",	"1",	"Display autorespawn timer hint?",							FCVAR_NONE, true, 0.0, true, 1.0	);
	config_AutoBan			= CreateConVar( "dr_autoban",			"60",	"How many minutes ban for choosen disconnect?",			FCVAR_NONE, true, 0.0, true, 99.0	);
	
	LoadTranslations(						"plugin.deathrun"	);
	
	AutoExecConfig( false,					"main", "deathrun"	);
	
	RegConsoleCmd(	"sm_rs",				command_ResetScore	);
	RegConsoleCmd(	"sm_resetscore",		command_ResetScore	);
	
	RegConsoleCmd(	"jointeam",				command_JoinTeam	);
	RegConsoleCmd(	"kill",					command_Suicide		);
	RegConsoleCmd(	"explode",				command_Suicide		);
	RegConsoleCmd(	"spectate",				command_Spectate	);
	
	HookEvent(		"player_death",			event_PlayerDeath							);
	HookEvent(		"player_disconnect",	event_PlayerDisconnect, EventHookMode_Pre	);
	HookEvent(		"player_connect",		event_PlayerConnect, 	EventHookMode_Pre	);
	HookEvent(		"player_team",			event_PlayerTeam,		EventHookMode_Pre	);
	HookEvent(		"round_end",			event_RoundEnd								);
	HookEvent(		"round_start",			event_RoundStart							);
}

public Action event_PlayerTeam( Handle event, const char[] name, bool dontBroadcast )
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action event_PlayerConnect( Handle event, const char[] name, bool dontBroadcast )
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

// if choosen disconnect - move another player to choosens team
void CheckChoosensTeam( )
{
	int NewTeam = GetConVarInt( config_RandomPlayers );
	
	if ( GetTeamClientCount( NewTeam ) <= 1 )
	{
		int ChoosenPlayer = RandomPlayers();
		
		if ( ChoosenPlayer == -1 )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
			}
			
			return;
		}
		
		NewChoosens[ ChoosenPlayer ] = true;
		
		char name[ 16 ];
		GetClientName( ChoosenPlayer, name, sizeof ( name ) );
		
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "REPLACE_CHOOSEN", name );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "REPLACE_CHOOSEN", name );
		}
		
		CS_SwitchTeam( ChoosenPlayer, NewTeam );
		
		CS_RespawnPlayer( ChoosenPlayer );
	}
}

public Action event_PlayerDisconnect( Handle event, const char[] name, bool dontBroadcast )
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	int client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( ( GetClientTeam( client ) == GetConVarInt( config_RandomPlayers ) ) && ( GetConVarInt( config_RandomPlayers ) > 1 ) )
	{
		if ( GetConVarInt( config_AutoBan ) != 0 )
		{
			if ( IsClientInGame( client ) && ( GetPlayersCount() >= GetConVarInt( config_MinPlayers ) ) )
			{
				char reason[ 64 ], cname[ 64 ], steamid[ 64 ];
				
				GetEventString( event, "networkid", steamid, sizeof( steamid ) );
				GetEventString( event, "reason", reason, sizeof ( reason ) );
				
				if ( StrEqual( reason, "Disconnect", false ) )
				{
					
					if( !GetClientName( client, cname, sizeof( cname ) ) )
					{
						Format( cname, sizeof( cname ), "Unconnected" );
					}
					
					BanClient( client, GetConVarInt( config_AutoBan ), BANFLAG_AUTHID, "Выход из команды террористов", "Выход из команды террористов" );
					
					if ( GameVersion == Engine_CSGO )
					{
						CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CHOOSEN_DISCONNECTED", cname, GetConVarInt( config_AutoBan ) );
					}
					else if ( GameVersion == Engine_CSS )
					{
						CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CHOOSEN_DISCONNECTED", cname, GetConVarInt( config_AutoBan ) );
					}
				}
			}
		}
		
		CheckChoosensTeam( );
	}
	
	return Plugin_Handled;
}

public Action event_RoundStart( Handle event, const char[] name, bool dontBroadcast )
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	if ( GetConVarInt( config_AutoRespawn ) != 0 )
	{
		respawn_Active		= true;
		respawn_Seconds		= GetConVarInt	( config_AutoRespawn );
		respawn_TimerHandle	= CreateTimer	( 1.0, respawn_Timer );
	}
	
	return Plugin_Continue;
}

public Action respawn_Timer( Handle timer )
{
	if ( ( GetConVarInt( config_AutoRespawn ) != 0 ) && respawn_Active )
	{
		respawn_Seconds--;
		
		if ( GetConVarBool( config_AutoRespawnHint ) )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintHintTextToAll	(	"  {{#00FFFF==%t}}\n  %t",	"AUTORESPAWN", "AUTORESPAWN_TIME_LEFT",	respawn_Seconds );
			}
			else if ( GameVersion == Engine_CSS )
			{
				PrintHintTextToAll		(	"%t: %t",					"AUTORESPAWN", "AUTORESPAWN_TIME_LEFT",	respawn_Seconds );
			}
		}
		
		if ( respawn_TimerHandle != INVALID_HANDLE )
		{
			KillTimer( respawn_TimerHandle );
		}
		
		if ( respawn_Seconds <= 0 )
		{
			respawn_Active = false;
		}
		
		respawn_TimerHandle = CreateTimer( 1.0, respawn_Timer );
	}
}

public Action respawn_SpawnTimer( Handle timer, int client )
{
	CS_RespawnPlayer( client );
}

public Action command_Spectate( int client, int args )
{
	if ( !GetConVarBool( config_Enabled ) || ( GetConVarInt( config_RandomPlayers ) == 0 ) )
	{
		return Plugin_Continue;
	}
	
	if ( ( GetClientTeam( client ) == GetConVarInt( config_RandomPlayers ) ) && ( GetConVarInt( config_RandomPlayers ) != 1 ) )
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action command_Suicide( int client, int args )
{
	if ( !GetConVarBool( config_Enabled ) || ( GetConVarInt( config_RandomPlayers ) == 0 ) )
	{
		return Plugin_Continue;
	}
	
	if ( ( GetClientTeam( client ) == GetConVarInt( config_RandomPlayers ) ) && ( GetConVarInt( config_RandomPlayers ) != 1 ) )
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CHOOSENS_CANT_SUICIDE" );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CHOOSENS_CANT_SUICIDE" );
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action command_JoinTeam( int client, int args )
{
	if ( !GetConVarBool( config_Enabled ) || ( GetConVarInt( config_RandomPlayers ) == 0 ) )
	{
		return Plugin_Continue;
	}
	
	if ( !IsClientInGame( client ) )
	{
		return Plugin_Continue;
	}
	
	char buffer [ 2 ];
	int startidx = 0;
	
	if ( !GetCmdArgString( buffer, sizeof( buffer ) ) )
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
//	int PlayersNum		= GetTeamClientCount	( CS_TEAM_CT			);
	
	int ChoosensTeam	= GetConVarInt			( config_RandomPlayers	);
	int PlayersTeam		= GetPlayersTeam		(						);
		
	if ( SelectedTeam == ChoosensTeam )
	{
		if ( ChoosensNum == 0 )
		{
			ChangeClientTeam( client, ChoosensTeam );
		}
		else if ( CurrentTeam != PlayersTeam )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_CHOOSENS_TEAM" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_CHOOSENS_TEAM" );
			}
			
			if ( CurrentTeam != ChoosensTeam )
			{
				ChangeClientTeam( client, PlayersTeam );
			}
		}
		
	}
	else if ( SelectedTeam == PlayersTeam )
	{
		if ( CurrentTeam != ChoosensTeam )
		{
			ChangeClientTeam( client, PlayersTeam );
		}
		else
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
			}
		}
	}
	else if ( ( SelectedTeam == CS_TEAM_SPECTATOR ) || ( SelectedTeam == CS_TEAM_NONE ) )
	{
		if ( CurrentTeam != ChoosensTeam )
		{
			ChangeClientTeam( client, CS_TEAM_SPECTATOR );
		}
		else
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "CANT_JOIN_ANOTHER" );
			}
		}
	}
	
	return Plugin_Handled;
}

public Action command_ResetScore( int client, int args )
{
	if ( !GetConVarBool( config_Enabled ) || !GetConVarBool( config_Scores ) )
	{
		return Plugin_Continue;
	}
	
	ResetPlayerScoreCounters( client );
	
	return Plugin_Continue;
}

public void OnClientPutInServer( int client )
{
	SDKHook( client, SDKHook_WeaponCanUse,	OnWeaponCanUse	);
	SDKHook( client, SDKHook_WeaponDrop,	OnWeaponDrop	);
	
	if ( !GetConVarBool( config_Enabled ) )
	{
		return;
	}
	
	if ( GetConVarBool( config_Scores ) )
	{
		ResetPlayerScoreCounters( client );
	}
}

public Action OnWeaponCanUse(int client, int weapon) 
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	if ( GetConVarBool( config_BlockUsePickup ) )
	{
		if ( GetClientButtons( client ) & IN_USE )
		{
			return Plugin_Handled; 
		}
	}
	
	return Plugin_Continue; 
}

public Action OnWeaponDrop(int client, int weapon) 
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	if ( GetConVarBool( config_BlockUsePickup ) )
	{
		if ( GetClientButtons( client ) & IN_USE )
		{
			return Plugin_Handled; 
		}
	}
	
	return Plugin_Continue; 
} 

void ResetPlayerScoreCounters( int client )
{
	kills	[ client ] = 0 ;
	deaths	[ client ] = 0 ;
	assists	[ client ] = 0 ;
	score	[ client ] = 0 ;
}

public Action event_RoundEnd( Handle event, const char[] name, bool dontBroadcast )
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	if ( GetConVarInt( config_RandomPlayers ) != 0 )
	{
		
		if ( GetConVarInt( config_RandomPlayers ) == 1 )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "MIXING_PLAYERS" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "MIXING_PLAYERS" );
			}
		}
		else
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_CHOOSENS" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_CHOOSENS" );
			}
			
			CreateTimer( 1.0, ChoosePlayers );
		}
		
		// round end immortality(after change player team some players can kill)
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( !IsClientInGame( i ) || !IsPlayerAlive( i ) )
			{
				continue;
			}
			
			SetEntProp( i, Prop_Data, "m_takedamage", 0, 1 );
		}
	}
	
	if ( GetConVarBool( config_Scores ) )
	{
		int reason = GetEventInt( event, "reason" );
		
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientInGame( i ) )
			{
				int team = GetClientTeam( i );
				
				if ( ( team == CS_TEAM_T  ) && ( reason == ROUNDEND_TERRORISTS_WIN	) )
				{
					assists [ i ] ++ ;
					score	[ i ] ++ ;
				}
				else if ( ( team == CS_TEAM_CT ) && ( reason == ROUNDEND_CTS_WIN	) )
				{
					assists [ i ] ++ ;
					score	[ i ] ++ ;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action ChoosePlayers( Handle timer )
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	int NewTeam = GetConVarInt( config_RandomPlayers );
	int OldTeam = GetPlayersTeam( );
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		OldChoosens[ i ] = false;
		NewChoosens[ i ] = false;
		
		if ( !IsClientInGame( i ) )
		{
			continue;
		}
		
		if ( GetClientTeam( i ) == NewTeam )
		{
			CS_SwitchTeam( i, OldTeam );
			OldChoosens[ i ] = true;
		}
	}
	
	int ChoosensNum = 1;
	
	if ( GetConVarInt( config_RandomRate ) != 0 )
	{
		ChoosensNum = view_as<int>( GetTeamClientCount( OldTeam ) / GetConVarInt( config_RandomRate ) );
	}
	
	char buffer[ 256 ];
	
	for (int i = 0; i < ChoosensNum; i++)
	{
		int ChoosenPlayer = RandomPlayers();
		
		if ( ChoosenPlayer == -1 )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "RANDOMIZING_ERROR" );
			}
			
			return Plugin_Continue;
		}
		
		NewChoosens[ ChoosenPlayer ] = true;
		
		char name[ 16 ];
		GetClientName( ChoosenPlayer, name, sizeof ( name ) );
		
		
		if ( ChoosensNum == 1 )
		{
			if ( GameVersion == Engine_CSGO )
			{
				CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "NEW_CHOOSEN", name );
			}
			else if ( GameVersion == Engine_CSS )
			{
				CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t", "DEATHRUN", "NEW_CHOOSEN", name );
			}
		}
		else
		{
			if ( i == 0 )
			{
				Format( buffer, sizeof( buffer ), "{RED}%s", name );
			}
			else
			{
				Format( buffer, sizeof( buffer ), "%s{LIGHTGREEN}, {RED}%s", buffer, name );
			}
		}
		
		CS_SwitchTeam( ChoosenPlayer, NewTeam );
		
		if ( IsPlayerAlive( ChoosenPlayer ) )
		{
			CS_RespawnPlayer	( ChoosenPlayer										);
			SetEntProp			( ChoosenPlayer, Prop_Data, "m_takedamage", 0, 1	);
		}
	}
	
	if ( ChoosensNum != 1 )
	{
		if ( GameVersion == Engine_CSGO )
		{
			CGOPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t%s", "DEATHRUN", "NEW_CHOOSENS", buffer );
		}
		else if ( GameVersion == Engine_CSS )
		{
			CPrintToChatAll( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t%s", "DEATHRUN", "NEW_CHOOSENS", buffer );
		}
	}
	
	return Plugin_Continue;
}

int RandomPlayers()
{
	int[]	PlayerList = new int[ MaxClients + 1 ];
	int		PlayerCount;
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame( i ) )
		{
			continue;
		}
		
		if ( GetClientTeam( i ) < 2 )
		{
			continue;
		}
		
		if ( NewChoosens[ i ] || OldChoosens[ i ] )
		{
			continue;
		}
		
		PlayerList[ PlayerCount++ ] = i;
	}
	
	if ( PlayerCount == 0 )
	{
		return -1;
	}
	
	return PlayerList[ GetRandomInt( 0, PlayerCount - 1 ) ];
}

public Action event_PlayerDeath( Handle event, const char[] name, bool dontBroadcast )
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return Plugin_Continue;
	}
	
	int victim		= GetClientOfUserId( GetEventInt( event, "userid"	) );
	int attacker	= GetClientOfUserId( GetEventInt( event, "attacker"	) );
	
	if ( GetConVarBool( config_Scores ) )
	{
		if ( ( victim != attacker ) && ( victim != 0 ) && ( attacker != 0 ) )
		{
			kills  [ attacker ] ++ ;
			score  [ attacker ] ++ ;
			deaths [ victim   ] ++ ;
		}
	}
	
	if ( GetConVarInt( config_AutoRespawn ) != 0 )
	{
		if ( respawn_Active && GetClientTeam( victim ) == GetPlayersTeam() )
		{
			CreateTimer( 1.0, respawn_SpawnTimer, victim );
		}
	}
	
	return Plugin_Continue;
}

public void OnGameFrame()
{
	if ( !GetConVarBool( config_Enabled ) )
	{
		return;
	}
	
	if ( GetConVarBool( config_Scores ) )
	{
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientInGame( i ) )
			{
				SetEntProp							( i,	Prop_Data, "m_iFrags",	kills	[ i ] );
				SetEntProp							( i,	Prop_Data, "m_iDeaths",	deaths	[ i ] );
				
				if ( GameVersion == Engine_CSGO )
				{
					CS_SetClientAssists				( i,							assists [ i ] );
					CS_SetClientContributionScore	( i,							score   [ i ] );
				}
			}
		}
	}
}

int GetPlayersCount()
{
	return GetTeamClientCount( CS_TEAM_T ) + GetTeamClientCount( CS_TEAM_CT );
}

int GetPlayersTeam()
{
	if ( GetConVarInt( config_RandomPlayers ) == CS_TEAM_T )
	{
		return CS_TEAM_CT;
	}
	else
	{
		return CS_TEAM_T;
	}
}
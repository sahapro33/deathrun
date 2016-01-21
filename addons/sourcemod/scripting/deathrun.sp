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
#define PLUGIN_VERSION		"2.0.dev8"
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

ConVar	config_Enabled;
ConVar	config_BlockUsePickup;
ConVar	config_WinPoint;
ConVar	config_AutoRespawn;
ConVar	config_AutoRespawnHint;
ConVar	config_AutoBan;
ConVar	config_MinPlayers;
ConVar	config_RandomPlayers;
ConVar	config_RandomRate;
ConVar	config_Scores;
ConVar	config_KillForSuicide;
ConVar	config_AntiSuicide;

bool	OldChoosens	[ MAXPLAYERS + 1 ];
bool	NewChoosens	[ MAXPLAYERS + 1 ];

int		kills		[ MAXPLAYERS + 1 ];
int		deaths		[ MAXPLAYERS + 1 ];
int		score		[ MAXPLAYERS + 1 ];

#include "deathrun/random.sp"
#include "deathrun/antisuicide.sp"
#include "deathrun/autorespawn.sp"
#include "deathrun/bans.sp"
#include "deathrun/events.sp"
#include "deathrun/savescores.sp"
#include "deathrun/winpoints.sp"

public void OnPluginStart ( )
{
	GameVersion = GetEngineVersion ( );
	
	CreateConVar ( "dr_version", PLUGIN_VERSION, PLUGIN_URL, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	config_Enabled			= CreateConVar ( "dr_enable",			"1",	"Enable the deathrun manager plugin?",					FCVAR_NONE, true, 0.0, true, 1.0	);
	config_BlockUsePickup	= CreateConVar ( "dr_blockusepickup",	"1",	"Block pickup weapons by use?",							FCVAR_NONE, true, 0.0, true, 1.0	);
	
	LoadTranslations ( "plugin.deathrun" );
	
	AutoExecConfig ( false, "main", "deathrun"	);
	
	PluginStart_AntiSuicide	( );
	PluginStart_Events		( );
	PluginStart_AutoRespawn	( );
	PluginStart_Scores		( );
	PluginStart_Bans		( );
	PluginStart_Random		( );
	PluginStart_WinPoints	( );
}

public void OnClientPutInServer ( int client )
{
	SDKHook( client, SDKHook_WeaponCanUse,	OnWeaponCanUse	);
	SDKHook( client, SDKHook_WeaponDrop,	OnWeaponDrop	);
	
	if ( !config_Enabled.BoolValue )
	{
		return;
	}
	
	OnClientPutInServer_SaveScores ( client );
}

public Action OnWeaponCanUse ( int client, int weapon ) 
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	if ( config_BlockUsePickup.BoolValue )
	{
		if ( GetClientButtons ( client ) & IN_USE )
		{
			return Plugin_Handled; 
		}
	}
	
	return Plugin_Continue; 
}

public Action OnWeaponDrop ( int client, int weapon ) 
{
	if ( !config_Enabled.BoolValue )
	{
		return Plugin_Continue;
	}
	
	if ( config_BlockUsePickup.BoolValue )
	{
		if ( GetClientButtons ( client ) & IN_USE )
		{
			return Plugin_Handled; 
		}
	}
	
	return Plugin_Continue; 
}

public void OnGameFrame( )
{
	if ( !config_Enabled.BoolValue )
	{
		return;
	}
	
	OnGameFrame_SaveScores ( );
}

int GetPlayersCount ( )
{
	return GetTeamClientCount ( CS_TEAM_T ) + GetTeamClientCount ( CS_TEAM_CT );
}

int GetPlayersTeam ( )
{
	return AnotherTeam ( config_RandomPlayers.IntValue );
}

int AnotherTeam ( int team )
{
	if ( team == CS_TEAM_T )
	{
		return CS_TEAM_CT;
	}
	else
	{
		return CS_TEAM_T;
	}
}
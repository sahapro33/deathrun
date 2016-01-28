void PluginStart_Bans ( )
{
	config_AutoBan		= CreateConVar ( "dr_autoban",		"60",	"How many minutes ban for choosen disconnect?",	FCVAR_NONE, true, 0.0, true, 99.0 );
	config_MinPlayers	= CreateConVar ( "dr_minplayers",	"4",	"Minimum players for ban disconnected choosen",	FCVAR_NONE, true, 2.0, true, 16.0 );
}

void PlayerDisconnect_Bans ( Event ev )
{
	int client = GetClientOfUserId ( ev.GetInt ( "userid" ) );
	
	if ( client == 0 )
	{
		return;
	}
	
	if ( IsClientInGame ( client ) )
	{
		if ( ( GetClientTeam ( client ) == config_RandomPlayers.IntValue ) && ( config_RandomPlayers.IntValue > 1 ) )
		{
			if ( config_AutoBan.IntValue != 0 )
			{
				if ( GetPlayersCount( ) >= config_MinPlayers.IntValue )
				{
					char	reason	[ 64 ],
							cname	[ 64 ],
							steamid	[ 64 ];
					
					ev.GetString ( "networkid",	steamid,	sizeof ( steamid	) );
					ev.GetString ( "reason",	reason,		sizeof ( reason		) );
					
					if ( StrEqual ( reason, "Disconnect", false ) )
					{
						
						if( !GetClientName ( client, cname, sizeof( cname ) ) )
						{
							Format ( cname, sizeof ( cname ), "Unconnected" );
						}
						
						// need changes
						BanClient ( client, config_AutoBan.IntValue, BANFLAG_AUTHID, "Disconnected choosen", "Disconnected choosen" );
						
						DRPrintToChatAll ( "{GREEN}%t {OLIVE}> {LIGHTGREEN}%t {RED}%s {LIGHTGREEN}%t", "DEATHRUN", "CHOOSEN", cname, "CHOOSEN_DISCONNECTED", config_AutoBan.IntValue );
					}
				}
			}
		}
	}
}
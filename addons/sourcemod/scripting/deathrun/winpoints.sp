void PluginStart_WinPoints ( )
{
	config_WinPoint = CreateConVar ( "dr_pointforwin", "2", "Who get point for win?", FCVAR_NONE, true, 0.0, true, 6.0 );
}

void RoundEnd_WinPoints ( Event ev )
{
	if ( !config_WinPoint.IntValue )
	{
		return;
	}
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame ( i ) )
		{
			continue;
		}
		
		int team = GetClientTeam ( i );
		
		if ( ( team == CS_TEAM_T ) && ( ev.GetInt ("reason") == ROUNDEND_TERRORISTS_WIN ) )
		{
			switch ( config_WinPoint.IntValue )
			{
				case 1:
				{
					AddPoint ( i );
				}
				
				case 2:
				{
					if ( IsPlayerAlive ( i ) )
					{
						AddPoint ( i );
					}
				}
				
				case 3:
				{
					if ( config_RandomPlayers.IntValue == CS_TEAM_T )
					{
						AddPoint ( i );
					}
				}
				
				case 4:
				{
					if ( ( config_RandomPlayers.IntValue == CS_TEAM_T ) && IsPlayerAlive ( i ) )
					{
						AddPoint ( i );
					}
				}
				
				case 5:
				{
					if ( config_RandomPlayers.IntValue == CS_TEAM_CT )
					{
						AddPoint ( i );
					}
				}
				
				case 6:
				{
					if ( ( config_RandomPlayers.IntValue == CS_TEAM_CT ) && IsPlayerAlive ( i ) )
					{
						AddPoint ( i );
					}
				}
			}
		}
		else if ( ( team == CS_TEAM_CT ) && ( ev.GetInt ("reason") == ROUNDEND_CTS_WIN ) )
		{
			switch ( config_WinPoint.IntValue )
			{
				case 1:
				{
					AddPoint ( i );
				}
				
				case 2:
				{
					if ( IsPlayerAlive ( i ) )
					{
						AddPoint ( i );
					}
				}
				
				case 3:
				{
					if ( config_RandomPlayers.IntValue == CS_TEAM_CT )
					{
						AddPoint ( i );
					}
				}
				
				case 4:
				{
					if ( ( config_RandomPlayers.IntValue == CS_TEAM_CT ) && IsPlayerAlive ( i ) )
					{
						AddPoint ( i );
					}
				}
				
				case 5:
				{
					if ( config_RandomPlayers.IntValue == CS_TEAM_T )
					{
						AddPoint ( i );
					}
				}
				
				case 6:
				{
					if ( ( config_RandomPlayers.IntValue == CS_TEAM_T ) && IsPlayerAlive ( i ) )
					{
						AddPoint ( i );
					}
				}
			}
		}
	}
}

void AddPoint ( int client )
{
	if ( GameVersion == Engine_CSGO )
	{
		if ( config_Scores.BoolValue )
		{
			score [ client ] ++ ;
		}
		else
		{
			CS_SetClientContributionScore ( client, CS_GetClientContributionScore ( client ) + 1 );
		}
	}
	else if ( GameVersion == Engine_CSS )
	{
		
		if ( config_Scores.BoolValue )
		{
			kills [ client ] ++ ;
		}
		else
		{
			SetEntProp ( client, Prop_Data, "m_iFrags", GetClientFrags ( client ) + 1 );
		}
	}
}
function [ o ] = playerTeamData( genData, teamDat, player )

% error message
emsg = "ERROR: playerTeamData: ";

pInd = getHeaderInd( genData, 'Name' );
TeamInd = getHeaderInd( genData, 'TEAM' );
if( length( pInd ) < 1 || length( TeamInd ) < 1 )
    emsg = strcat( emsg, "Invalid General Data" );
    error( emsg );
end

% find player team
ind = find( strcmp( genData{ :, pInd }, player ) );
if( length( ind ) < 1 )
    emsg = strcat( emsg, "Player Is not listed" );
    error( emsg );
end

team = genData{ ind, TeamInd };

o = getTeamData( teamDat, team( 1 ) );

end
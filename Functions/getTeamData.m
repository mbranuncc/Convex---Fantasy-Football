function [ o ] = getTeamData( teamData, team )

% error message
emsg = "ERROR: getTeamData: ";

% find team name in teamData
ind = find( strcmp( teamData{ :, getHeaderInd( teamData, 'Team' ) }, cellstr( team ) ), 1, 'first' );
if( length( ind ) < 1 ) 
    emsg = strcat( emsg, "Team does not exist" );
    error( emsg );
end

o = teamData( ind, : );

end
function [ pts ] = pts4Player( player, wk, data )

% define generic error message
emsg = "ERROR: pts4Player: ";

% find the column which has the player name
nameInd = getHeaderInd( data, 'Name' );
if( length( nameInd ) < 1 ) 
    emsg = strcat( emsg, "Data set is not correct. No 'Name' header." );
    error( emsg );
end

% find the column with wk number
wkInd = getHeaderInd( data, 'WK' );
if( length( nameInd ) < 1 ) 
    emsg = strcat( emsg, "Data set is not correct. No 'WK' header." );
    error( emsg );
end

% find the column with fantasy pts
ptsInd = getHeaderInd( data, 'FPTS' );
if( length( nameInd ) < 1 ) 
    emsg = strcat( emsg, "Data set is not correct. No 'FPTS' header." );
    error( emsg );
end

% now find the player
% playerInds = [];
try
    playerInds = find( strcmp( data{ :, nameInd }, cellstr( player ) ) ); 
catch
    playerInds = find( data{ :, nameInd } == player ); 
end

% find the appropriate week
found = 0;
for i = 1:length( playerInds )
    cWk = data{ playerInds( i ), wkInd };
    if( cWk == wk )
        found = 1;
        break;
    end
end

if( found )
    pts = data{ playerInds( i ), ptsInd };
else
    pts = 0;
end

end
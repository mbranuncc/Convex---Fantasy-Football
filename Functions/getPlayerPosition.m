function [ o ] = getPlayerPosition( data, player )

% error message
emsg = "ERROR: getPlayerPosition: ";

playerInd = getHeaderInd( data, 'Name' );
positionInd = getHeaderInd( data, 'POS' );
if( length( playerInd ) < 1 || length( positionInd ) < 1 )
    emsg = strcat( emsg, "Data set incorrect" );
    error( emsg );
end

pInd = find( strcmp( data{ :, playerInd }, player ), 1, 'first' );

o = data{ pInd, positionInd };

end
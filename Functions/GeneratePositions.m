function [ QB, RB, WR, TE, DST, K ] = GeneratePositions( data )

% denote error message
emsg = "ERROR: GeneratePositions: ";

% remove data for the following reasons:
% 1) Expected Points are 0
% 2) Expected Risk Equals or Exceeds 100

% 1)
ptsInd = getHeaderInd( data, "ExpectedPoints" );
inds2Keep = find( data{ :, ptsInd } > 0 );

tD = data( inds2Keep, : );

% 2)
rskInd = getHeaderInd( tD, "risk" );
inds2Keep = find( tD{ :, rskInd } < 100 );

tD = tD( inds2Keep, : );

posInd = getHeaderInd( data, "Position" );

% position array
posArr = [ "QB", "RB", "WR", "TE", "DST", "K" ];
for i = 1:length( posArr )
   inds = find( strcmp( tD{ :, posInd }, posArr( i ) ) );
   if( length( inds ) < 1 )
       emsg = strcat( emsg, sprintf("No players found at position: %s\n", posArr( i ) ) );
       error( emsg );
   end
    
   if( posArr( i ) == "QB" )
        QB = tD( inds, : );
   elseif( posArr( i ) == "RB" )
       RB = tD( inds, : );
   elseif( posArr( i ) == "WR" )
       WR = tD( inds, : );
   elseif( posArr( i ) == "TE" )
       TE = tD( inds, : );
   elseif( posArr( i ) == "DST" )
       DST = tD( inds, : );
   elseif( posArr( i ) == "K" )
       K = tD( inds, : );
   else
       error( emsg );
   end
   
end

end
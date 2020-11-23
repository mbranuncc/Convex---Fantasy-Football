function [ pts ] = ExpectedPts_RR( data, player, wk, k )

% error message
emsg = "ERROR: ExpectedPts: ";

% loop through and call pts4Player to get the data set for polyfit
pts = zeros( wk - 1, 1 );
for i = 1:length( pts )
   pts( i ) = pts4Player( player, i, data ); 
end

% use polyfit
games = 1:wk-1;
p = ridge( games', pts, k );

f = polyval( p, wk );
if( f < 0 )
    f = 0;
end

pts = f;

end
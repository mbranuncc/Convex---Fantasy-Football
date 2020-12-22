function [ pts ] = ExpectedPts_RR( data, player, wk, order, alpha )

% error message
emsg = "ERROR: ExpectedPts: ";

% loop through and call pts4Player to get the data set for polyfit
pts = zeros( wk - 1, 1 );
for i = 1:length( pts )
   pts( i ) = pts4Player( player, i, data ); 
end

% use cvx for ridged regression
u = 1:wk-1;
A = vander( u' );
A = A( :, ( wk-1 ) - order + [ 1:order ] );

% cvx version of ridged regression
% cvx_begin quiet
%     variable x1( order );
%     minimize ( ( A * x1 - pts )' * ( A * x1 - pts ) + alpha * x1' * x1 );
% cvx_end

[ ~, n ] = size( A );
I = eye( n ) * alpha;
x1 = inv( A' * A + I ) * A' * pts;

% uncomment seciton for plotting to debug
% u2 = linspace( 0, wk, 1000 );
% vpol = x1( 1 ) * ones( 1, 1000 );
% for i = 2:order
%     vpol = vpol.*u2 + x1( i );
% end
% vpol( end )
% figure(1)
% plot( u2, vpol, '-', u, pts, 'o' );

f = polyval( x1, wk );

pts = f;

end
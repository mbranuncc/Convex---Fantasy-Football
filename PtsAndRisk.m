clc; clearvars -except AssortedData; close all

fprintf( "CAUTION: This script takes approximately 60 minutes to calculate full sheet...Press any key to continue...\n" );
pause();

tic;

lines2read = 5910;
if( exist( 'AssortedData', 'var' ) ~= 1 )
    AssortedData = AssortedDataimport( "FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", [ 2 lines2read ] );
end
    
C = unique( AssortedData{ 1:end, 2 } );
pNum = length( C );

max_num_games = max( AssortedData{ 1:end, 7 } );

v = zeros( length( C ), max_num_games );

curr_ind = 1;
for name = C'
   t = find( AssortedData{ 1:end, 2 } == name );
   
   for i = t'
       wk = AssortedData{ i, 7 };
        v( curr_ind, wk ) = AssortedData{ i , 22 };
   end
   
   curr_ind = curr_ind + 1;
end

m = max_num_games; % set the number of games to be evaluated
order = 4;
if( m < order )
    n = m;
else
    n = order;
end
s = 0; % offset

u = 1:m;
A = vander( u' );
A = A( :, m - n + [ 1:n ] );

u2 = linspace( 0, m + 1, 1000 );

alpha = linspace( 0, 1, 30 ); % can't be negative, otherwise it would be concave
% RRSig = zeros( length( alpha ), 2 );
RRSig = zeros( pNum, 2 );
ind = 1;

for a = alpha
    clear x1 cost;
    cvx_begin quiet
        variables x1( pNum, n );
        
        cost = 0;
        for i = 1:pNum
               s1 = A * x1( i , : )';
               s2 = v( i, 1:m )';
               s3 = s1 - s2;
               s4 = norm( s3 );
               s5 = a * norm( x1( i, 1:n ) );
               cost = cost + s5;
        end
        
        minimize ( cost );
    
    cvx_end

    errSum = 0;
    for i = 1:pNum
        vpol = x1( i, 1 ) * ones( 1, 1000 );
        for j = 2:n
            vpol = vpol.*u2 + x1( i, j );
        end
        
        RREx = vpol( end );
        
        var = std( v( i, : ) ) + 2*eps;
        xbar = mean( v( i, : ) );
        
        t = ( RREx - xbar ) / var;
        errSum = errSum + t;
    end
    
    RRSig( ind, 1 ) = errSum;
    RRSig( ind, 2 ) = a;
    
    progress_bar( ind, length( alpha ), 0 );
    ind = ind + 1;
end

%%
[ val, I ] = min( abs( RRSig( :, 1 ) ) );

fprintf("Optimal Alpha Chosen: %3.4f\n", RRSig( I, 2 ) );

nm = [];
exPts = [];
exVar = [];
pos = [];
wk = [];
for i = 1:pNum
    cvx_begin quiet
        variable x2( n );
        minimize ( norm( A * x2( : ) - v( i, 1:m )' ) ...
                        + RRSig( I, 2 ) * norm( x2( : ) ) );
    cvx_end

    vpol = x2( 1 ) * ones( 1, 1000 );
    for j = 2:n
        vpol = vpol.*u2 + x2( j );
    end
    
%     figure;
%     tle = C( i );
%     title( tle );
%     hold on
%         plot( u2, vpol, '-', u, v( i, : ), 'o' );
%     hold off
    
    RREx = vpol( end );

    var = std( v( i, : ) ) + 2*eps;
    xbar = mean( v( i, : ) );

    t = ( RREx - xbar ) / var;
    
    if( RREx < 2 * eps )
        RREx = 0;
    end
    
    nm = [ nm; C( i ) ];
    exPts = [ exPts; RREx ];
    exVar = [ exVar; abs( t ) ];
    wk = [ wk; m + 1 ];
    
    progress_bar( i, pNum, 0 );
end

T = table( nm, exPts, exVar, wk );
writetable( T, 'outpt.csv', 'Delimiter', ',' );

tt = toc;
fprintf("Total Time for %d lines read and %d players: %4.4f min\n", lines2read-1, pNum, tt/60.0 );
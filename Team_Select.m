clc; clearvars -except AssortedData; close all

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Team Select
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic;

des_pts = 120;

lines2read = 1173;
if( exist( 'AssortedData', 'var' ) ~= 1 )
    AssortedData = importOutput( "FantasyDatacom_WkByWk.xlsm", "Output", [ 2 lines2read ] );
end
    
% find QBs in list
QB = find( AssortedData{ :, 5 } == "QB" );
QBv = zeros( length( QB ), 2 );
for i = 1:length( QB )
    QBv( i, 1 ) = AssortedData{ QB( i ), 2 };
    QBv( i, 2 ) = AssortedData{ QB( i ), 3 };
end

% find RBs in list
RB = find( AssortedData{ :, 5 } == "RB" );
RBv = zeros( length( RB ), 2 );
for i = 1:length( RB )
    RBv( i, 1 ) = AssortedData{ RB( i ), 2 };
    RBv( i, 2 ) = AssortedData{ RB( i ), 3 };
end

% find WRs in list
WR = find( AssortedData{ :, 5 } == "WR" );
WRv = zeros( length( WR ), 2 );
for i = 1:length( WR )
    WRv( i, 1 ) = AssortedData{ WR( i ), 2 };
    WRv( i, 2 ) = AssortedData{ WR( i ), 3 };
end

TE = find( AssortedData{ :, 5 } == "TE" );
TEv = zeros( length( TE ), 2 );
for i = 1:length( TE )
    TEv( i, 1 ) = AssortedData{ TE( i ), 2 };
    TEv( i, 2 ) = AssortedData{ TE( i ), 3 };
end

K = find( AssortedData{ :, 5 } == "K" );
Kv = zeros( length( K ), 2 );
for i = 1:length( K )
    Kv( i, 1 ) = AssortedData{ K( i ), 2 };
    Kv( i, 2 ) = AssortedData{ K( i ), 3 };
end

%normalize array sizes

% first, get all array sizes
[ mQB, ~ ] = size( QBv );
[ mRB, ~ ] = size( RBv );
[ mWR, ~ ] = size( WRv );
[ mTE, ~ ] = size( TEv );
[ mK, ~ ] = size( Kv );

Asize = [ mQB, mRB, mWR, mTE, mK ];
[ m ] = size( Asize );
p = max( Asize );

% create A matrix with appropriate zero elements
A = [ QBv( :, 1 )', zeros( 1, p - mQB );
        RBv( :, 1 )', zeros( 1, p - mRB );
        WRv( :, 1 )', zeros( 1, p - mWR );
        TEv( :, 1 )', zeros( 1, p - mTE );
        Kv( :, 1 )', zeros( 1, p - mK ) ];

% clear QBv RBv WRv TEv Kv Asize;

% redefine matrix with appropriate position counts
A = [ A( 1, : ); A( 2, : ); A( 2, : ); A( 3, : ); A( 3, : ); A( 4, : ); A( 5, : ) ];

[ m, n ] = size( A );

% create random risk matrix for now
rQB = QBv( :, 2 )';
rRB = RBv( :, 2 )';
rWR = WRv( :, 2 )';
rTE = TEv( :, 2 )';
rK = Kv( :, 2 )';

r = [ rQB, ones( 1, p - mQB );
        rRB, ones( 1, p - mRB );
        rRB, ones( 1, p - mRB );
        rWR, ones( 1, p - mWR );
        rWR, ones( 1, p - mWR );
        rTE, ones( 1, p - mTE );
        rK,  ones( 1, p - mK ) ];
    
clear rQB rRB rWR rTE rK mQB mRB mWR mTE mK Asize p;

cvx_begin quiet
    cvx_solver Mosek
    cvx_precision high
    
    % switch to fractional value of x
    variable x( m, n ) integer;
    
    minimize ( HadamardProdSum( r, x ) );
    
    subject to
        HadamardProdSum( A, x ) >= des_pts;
        x >= 0;
        x <= 1;
        sum( sum( x ) ) == m;

        for i = 1:m
            trace( diag( x( i, : ) ) ) <= 1.0;
        end
        
        for i = 1:n
            trace( diag( x( 2:3, i ) ) ) <= 1.0;
            trace( diag( x( 4:5, i ) ) ) <= 1.0;
        end
cvx_end


%%
pts = HadamardProdSum( A, x );
rsk = HadamardProdSum( r, x );

fprintf( "Expected Points: %f\n", pts );
fprintf( "Expected Risk: %f\n", rsk );

[ row, col ] = find( x > 0 );

picks = [ row, col ];
picks = sortrows( picks, 1 );

[ m, ~ ] = size( picks );

for t = 1:m
   if( t == 1 )
       qbPick = AssortedData{ QB( picks( t, 2 ) ), 1 };
   elseif( t == 2 )
       rb1Pick = AssortedData{ RB( picks( t, 2 ) ), 1 };
   elseif( t == 3 )
       rb2Pick = AssortedData{ RB( picks( t, 2 ) ), 1 };
   elseif( t == 4 )
       wr1Pick = AssortedData{ WR( picks( t, 2 ) ), 1 };
   elseif( t == 5 )
       wr2Pick = AssortedData{ WR( picks( t, 2 ) ), 1 };
   elseif( t == 6 )
       tePick = AssortedData{ TE( picks( t, 2 ) ), 1 };
   elseif( t == 7 )
       kPick = AssortedData{ K( picks( t, 2 ) ), 1 };
   else
       fprintf("ERROR\n");
   end 
end

%%
T = table( qbPick, rb1Pick, rb2Pick, wr1Pick, wr2Pick, tePick, kPick );
disp( T );

toc;
        
function [ o ] = HadamardProdSum( m1, m2 )
    sum = 0;
    
    [ r1, c1 ] = size( m1 );
    [ r2, c2 ] = size( m2 );
    
    if( r1 ~= r2 || c1 ~= c2 )
        o = -1;
        return;
    end
    
    for i = 1:r1
        for j = 1:c1
            sum = sum + m1( i, j ) * m2( i, j );
        end
    end

    o = sum;
end
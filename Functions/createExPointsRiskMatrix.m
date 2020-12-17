function [ A, b ] = createExPointsRiskMatrix( QB, RB, WR, TE, DST, K )

% error message
emsg = "ERROR: createExPointsMatrix: ";

% assume that all of the matrices are the same setup
exPtsInd = getHeaderInd( QB, 'ExpectedPoints' );
riskInd = getHeaderInd( QB, 'risk' );

% setup vectors
[ QBvl, ~ ] = size( QB );
[ RBvl, ~ ] = size( RB );
[ WRvl, ~ ] = size( WR );
[ TEvl, ~ ] = size( TE );
[ DSTvl, ~ ] = size( DST );
[ Kvl, ~ ] = size( K );

p = max( [ QBvl, RBvl, WRvl, TEvl, DSTvl, Kvl ] );

QBv = zeros( QBvl, 2 );
RBv = zeros( RBvl, 2 );
WRv = zeros( WRvl, 2 );
TEv = zeros( TEvl, 2 );
DSTv = zeros( DSTvl, 2 );
Kv = zeros( Kvl, 2 );

% populate data
QBv( :, 1 ) = QB{ :, exPtsInd };
QBv( :, 2 ) = QB{ :, riskInd };

RBv( :, 1 ) = RB{ :, exPtsInd };
RBv( :, 2 ) = RB{ :, riskInd };

WRv( :, 1 ) = WR{ :, exPtsInd };
WRv( :, 2 ) = WR{ :, riskInd };

TEv( :, 1 ) = TE{ :, exPtsInd };
TEv( :, 2 ) = TE{ :, riskInd };

DSTv( :, 1 ) = DST{ :, exPtsInd };
DSTv( :, 2 ) = DST{ :, riskInd };

Kv( :, 1 ) = K{ :, exPtsInd };
Kv( :, 2 ) = K{ :, riskInd };

% create preliminary A matrix
A = [ QBv( :, 1 )', zeros( 1, p - QBvl );
        RBv( :, 1 )', zeros( 1, p - RBvl );
        WRv( :, 1 )', zeros( 1, p - WRvl );
        TEv( :, 1 )', zeros( 1, p - TEvl );
        DSTv( :, 1 )', zeros( 1, p - DSTvl );
        Kv( :, 1 )', zeros( 1, p - Kvl ) ];
    
% redefine matrix with appropriate position counts
A = [ A( 1, : ); A( 2, : ); A( 2, : ); A( 3, : ); A( 3, : ); A( 4, : ); A( 5, : ); A( 6, : ) ];


% create preliminary b
b = [ QBv( :, 2 )', 1000 * ones( 1, p - QBvl );
        RBv( :, 2 )', 1000 * ones( 1, p - RBvl );
        WRv( :, 2 )', 1000 * ones( 1, p - WRvl );
        TEv( :, 2 )', 1000 * ones( 1, p - TEvl );
        DSTv( :, 2 )', 1000 * ones( 1, p - DSTvl );
        Kv( :, 2 )', 1000 * ones( 1, p - Kvl ) ];
    
b = [ b( 1, : ); b( 2, : ); b( 2, : ); b( 3, : ); b( 3, : ); b( 4, : ); b( 5, : ); b( 6, : ) ];
end
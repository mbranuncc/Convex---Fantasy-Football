clc;
clearvars -except SammyWatkinsTest
close all

n = 6;
m = 10;
s = 1;

u = 1:m;

v = zeros( 1, m );
for i = 1:m-1
    v( i ) = SammyWatkinsTest{ i + s + 1, 22 };
end
v( end ) = mean( v( 1:end-1 ) );

A = vander( u' );
A = A( :, m - n + [ 1: n ] );
x = A \ ( v' );

u2 = linspace( 0, m + 1, 1000 );

alpha = linspace( 0, 1, 30 );
stdRegSig = zeros( length( alpha ), 2 );
RRSig = zeros( length( alpha ), 2 );
ind = 1;

for a = alpha
    cvx_begin quiet
        variable x1( n );
        minimize ( ( A * x1 - v' )' * ( A * x1 - v' ) + a * x1' * x1 );
    cvx_end

    vpol = x( 1 ) * ones( 1, 1000 );
    vpol1 = x1( 1 ) * ones( 1, 1000 );
    for i = 2:n
        vpol = vpol.*u2 + x( i );
        vpol1 = vpol1.*u2 + x1( i );
    end

    stdRegEx = vpol( end );
    RREx = vpol1( end );
    % 
    % std( vpol )
    var = std( v );
    m = mean( v );

    stdRegSig( ind, 1 ) = ( stdRegEx - m ) / var;
    RRSig( ind, 1 ) = ( RREx - m ) / var;
    stdRegSig( ind, 2 ) = a;
    RRSig( ind, 2 ) = a;
   
    ind = ind + 1;
end

%%
[ val, I ] = min( abs( RRSig( :, 1 ) ) );

cvx_begin quiet
    variable x1( n );
    minimize ( ( A * x1 - v' )' * ( A * x1 - v' ) + RRSig( I, 2 ) * x1' * x1 );
cvx_end

vpol = x( 1 ) * ones( 1, 1000 );
vpol1 = x1( 1 ) * ones( 1, 1000 );
for i = 2:n
    vpol = vpol.*u2 + x( i );
    vpol1 = vpol1.*u2 + x1( i );
end

plot( u2, vpol, '-', u, v, 'o' );
hold on
    plot( u2, vpol1, '-' );
hold off

legend( 'Standard', 'Data', 'Ridge Regression' );

stdRegEx = vpol( end );
RREx = vpol1( end );

var = std( v );
m = mean( v );

stdRegSig1 = ( stdRegEx - m ) / var;
RRSig1 = ( RREx - m ) / var;

fprintf( "Mean: %3.2f, StDev: %3.2f\n", m, var );
fprintf( "Linear Regression Expected Value: %3.2f, z = %3.2f\n", stdRegEx, abs( stdRegSig1 ) );
fprintf( "Ridge Regression Expected Value: %3.2f, z = %3.2f\n", RREx, abs( RRSig1 ) );
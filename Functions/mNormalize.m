function [ o ] = mNormalize( r, scale )

emsg = "ERROR: mNormalize - ";

if( numel( scale ) ~= 2 )
    error( sprintf( "%s scale INCORRECT INPUT", emsg ) );
end

if( scale( 1 ) >= scale( 2 ) )
    error( sprintf( "%s scale INCORRECT FORMAT", emsg ) );
end

[ rM, rN ] = size( r );
if( rM < 2 || rN < 2 )
    error( sprintf( "%s r INCORRECT INPUT", emsg ) );
end

rMin = min( r, [], 'all' );
% rMin = min( min( r ) );

o = r + sign( rMin - scale( 1 ) ) * ( rMin - scale( 1 ) );
rMax = max( o, [], 'all' );

o = scale( 2 ) * o / rMax;

end
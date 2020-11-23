function [ ox ] = teamSelector( A, b, des_pts )


fprintf("Starting Team Optimization...");

[ m, n ] = size( A );

r = b;

cvx_begin quiet
    cvx_solver Mosek
    cvx_precision high
    
    variable x( m, n ) integer
    
    minimize ( HadamardProdSum( r, x ) );
    
    subject to
        HadamardProdSum( A,  x ) >= des_pts;
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

fprintf("%s\n", cvx_status );

ox = x;

end
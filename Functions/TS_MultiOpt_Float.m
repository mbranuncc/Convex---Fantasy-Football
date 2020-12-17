function [ ox ] = TS_MultiOpt_Float( A, b, des_pts, rsk_wght, scr_wght, des_rsk )

% non-integer checker

fprintf("Starting Team Optimization...");

[ m, n ] = size( A );

r = b;

% rsk_wght = 0.1;
% scr_wght = 1 - rsk_wght;
% des_rsk = 15;

cvx_begin quiet
%     cvx_solver Mosek
    cvx_precision high
    
    variable x( m, n );
    
    minimize ( rsk_wght * HadamardProdSum( r, x ) + scr_wght * HadamardProdSum( A,  x ) );
    
    subject to
        HadamardProdSum( A,  x ) >= des_pts;
%         HadamardProdSum( r, x ) <= des_rsk;
        x >= 0.0;
        x <= 1.0;
%         sum( sum( x ) ) <= m;
        
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
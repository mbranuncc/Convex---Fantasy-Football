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
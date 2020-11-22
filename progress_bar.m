function progress_bar( curr, maxV, tarArr )

num_slots = 40;
if( maxV < num_slots )
    num_slots = maxV;
end
n = maxV / num_slots;

clc;

inspect_digit = mod( curr, 8 );
% this is not working properly...maybe pass some sort of status variable?
if( mod( inspect_digit, 8 ) == 0 )
    start_key = "/";
elseif( mod( inspect_digit, 7 ) == 0 )
    start_key = "-";
elseif( mod( inspect_digit, 6 ) == 0 )
    start_key = "\";
elseif( mod( inspect_digit, 5 ) == 0 )
    start_key = "|";
elseif( mod( inspect_digit, 4 ) == 0 )
    start_key = "/";
elseif( mod( inspect_digit, 3 ) == 0 )
    start_key = "-";
elseif( mod( inspect_digit, 2 ) == 0 )
    start_key = "\";
else
    start_key = "|";
end

fprintf( "%s > ", start_key );
for i = 1:num_slots
    if( curr > n * i - 1 )
        fprintf("=");
    else
        fprintf("-");
    end
end
fprintf("> %3.2f %%\n", ( curr / maxV ) * 100 );

end
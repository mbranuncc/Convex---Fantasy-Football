clc; clearvars -except AssortedData; close all

% fprintf( "CAUTION: This script takes approximately 60 minutes to calculate full sheet...Press any key to continue...\n" );
% pause();

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

% loop through players and use polyfit and polyval for estimates
nm = [];
exPts = [];
% exVar = [];
wk = [];

g = 1:m;
for i = 1:pNum
   tg = v( i, : );
   p = polyfit( g, tg, order );
   x = m + 1;
   f = polyval( p, x );
   if( f < 0 )
       f = 0;
   end
   
    nm = [ nm; C( i ) ];
    exPts = [ exPts; f ];
%     exVar = [ exVar; 1 ];
    wk = [ wk; x ];
end

% T = table( nm, exPts, exVar, wk );
T = table( nm, exPts, wk );
writetable( T, 'outpt.csv', 'Delimiter', ',' );

tt = toc;
fprintf("Total Time for %d lines read and %d players: %4.4f min\n", lines2read-1, pNum, tt/60.0 );
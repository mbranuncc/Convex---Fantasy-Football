clc; clear all; close all

addpath( "Functions/" );
addpath( "Functions/export_fig" );

exVal = @ExpectedPts_RR;

tmSelVec = { @TS_MultiOpt_Int, @TS_MultiOpt_Float, @TS_UniOpt_Int };
tmSelName = { "TS\_MultiOpt\_Int", "TS\_MultiOpt\_Float", "TS\_UniOpt\_Int" };
times = zeros( length( tmSelVec ), 1 );

%%
% Working Parameters
fittingOrder = 3;
alpha = 15;
des_pts = 80;

wk = 16;

stp = 0.05;
rsk_wght = 0:stp:1;
scr_wght = 1 - rsk_wght;
des_rsk = 15;

%%

% Load Injury data
InjuryDataGenerator;
load( 'Injury.mat' );

[ wks, all ] = generateDataSet( "FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", 6268, 17 );

train = wks{ 1 };
for i = 2:wk-1
     train = vertcat( train, wks{ i } );
end

validate = wks{ wk };

% load Team Rankings Data
TeamRankingsGenerator;
load( 'TeamRankings.mat' );


currentWeights = [0.301, 0.483, .419, 0.1866 ];
Player = unique( train{ 1:end, getHeaderInd( train, 'Name' ) } );
pNum = length( Player );

% create output variables
ExpectedPoints = zeros( pNum,  1 );
risk = zeros( pNum, 1 );
Week = zeros( pNum, 1 );
Position = strings( pNum, 1 );

pareto = zeros( 4, length( rsk_wght ) );

for i = 1:length( Player )
   % get data from the player's team
   playerTeam = playerTeamData( train, TeamRankings, Player( i ) );

   % get data from the player's opponent
   oppTeam = playerTeam{ 1, getHeaderInd( playerTeam, strcat( "x", int2str( wk ) ) ) };
   if( strcmp( oppTeam, "BYE" ) )
       risk( i ) = 100;
       continue;
   end
   oppTeam = getTeamData( TeamRankings, oppTeam );

   v1 = getHeaderInd( playerTeam, "Rank" );
   v2 = getHeaderInd( playerTeam, "AveragePtDiff" );
   v3 = getHeaderInd( playerTeam, "MaxWin" );
   v4 = getHeaderInd( playerTeam, "MaxLoss" );

   aV = [ playerTeam{ 1, v1 } - oppTeam{ 1, v1 };
          playerTeam{ 1, v2 } - oppTeam{ 1, v2 };
          playerTeam{ 1, v3 } - oppTeam{ 1, v3 };
          playerTeam{ 1, v4 } - oppTeam{ 1, v4 } ];

   risk( i ) = currentWeights * aV;
   ExpectedPoints( i ) = exVal( train, Player( i ), wk, fittingOrder, alpha );
   Week( i ) = wk;
   Position( i ) = cellstr( getPlayerPosition( train, Player( i ) ) );

   progress_bar( i, pNum, 0, 0 );
end

%%

for z = 1:length( tmSelVec )
    tmSel = tmSelVec{ z };
    tic;
    for j = 1:length(rsk_wght)
        T = table( Player, ExpectedPoints, risk, Week, Position );

        [ QB, RB, WR, TE, DST, K ] = GeneratePositions( T );
        [ A, r ] = createExPointsRiskMatrix( QB, RB, WR, TE, DST, K );

        r = mNormalize( r, [ 0 1 ] );
        
        playerInd = getHeaderInd( QB, 'Player' );
        ptsInd = getHeaderInd( QB, 'ExpectedPoints' );
        riskInd = getHeaderInd( QB, 'risk' );
        
        % plug normalized values back into tables
        QB{ :, riskInd } = r( 1, 1:length( QB{ :, riskInd } ) )';
        RB{ :, riskInd } = r( 2, 1:length( RB{ :, riskInd } ) )';
        WR{ :, riskInd } = r( 4, 1:length( WR{ :, riskInd } ) )';
        TE{ :, riskInd } = r( 6, 1:length( TE{ :, riskInd } ) )';
        DST{ :, riskInd } = r( 7, 1:length( DST{ :, riskInd } ) )';
        K{ :, riskInd } = r( 8, 1:length( K{ :, riskInd } ) )';

        [ x ] = tmSel( A, r, des_pts, rsk_wght( j ), scr_wght( j ), des_rsk );

        [ row, col ] = find( x > 0.3 );

        picks = [ row, col ];
        picks = sortrows( picks, 1 );

%         playerInd = getHeaderInd( QB, 'Player' );
%         ptsInd = getHeaderInd( QB, 'ExpectedPoints' );
%         riskInd = getHeaderInd( QB, 'risk' );                              

        posNames = [ "QB", "RB1", "RB2", "WR1", "WR2", "TE", "DST", "K" ];
        posDBs = { QB; RB; RB; WR; WR; TE; DST; K };

        tot_score = 0.0;
        tot_risk = 0.0;

        for p = 1:length( row )
            DB = posDBs{ picks( p, 1 ) };
            tmp = full( x );
            
            
            if( picks( p, 2 ) <= size( DB, 1 ) )
                tot_score = tot_score + DB{ picks( p, 2 ), ptsInd };
                tot_risk = tot_risk + DB{ picks( p, 2 ), riskInd };
            end
        end

        pareto( :, j ) = [ scr_wght( j ), rsk_wght( j ), tot_score, tot_risk ]';

        progress_bar( j, length( rsk_wght ), z, length( tmSelVec ) );
    end
    tme = toc;
    times( z ) = tme;
    %%
    figure;
%     subplot( 2, 1, 1 )
    semilogx( pareto( 3, 1:end-1 ), pareto( 4, 1:end-1 ), 'o-' );
    xlabel( 'Expected Points' );
    ylabel( 'Risk' );
    % ylabel( 'Expected points' );
    title( tmSelName{ z } );
    
    export_fig( strcat( "Media/", strrep( cellstr( tmSelName{ z } ), "\", "" ), ".png" ) );

    % axis( [ min( rsk_wght ) * 0.9, max( rsk_wght ) * 1.1 0 max( pareto( 3, : ) ) * 1.1 ] );

%     hold on
%         subplot( 2, 1, 2 )
%         plot( pareto( 2, : ), pareto( 4, : ) );
%         title( 'Assigned Risk' );
% 
%     %     axis( [ min( rsk_wght ) * 0.9, max( rsk_wght ) * 1.1, 0, max( pareto( 4, : ) ) * 1.1 ] );
%     hold off
    
    fprintf( "%s run time: %3.3f\n", tmSelName{ z }, tme );
end

%%
figure;
v = diag( times );
bar( v );
legend( tmSelName );
export_fig( "Media/Run Times.png" );

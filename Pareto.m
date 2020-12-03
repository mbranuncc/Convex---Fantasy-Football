clc; clear all; close all

addpath( "Fucntion/" );

exVal = @ExpectedPts_RR;

tmSel = @teamSelector_v2;

%%
% Working Parameters
fittingOrder = 3;
alpha = 15;
des_pts = 80;

wk = 16;

stp = 0.1;
rsk_wght = 0:stp:1;
scr_wght = 1;
des_rsk = 15;

%%

% Load Injury data
InjuryDataGenerator;
load( 'Injury.mat' );

[ wks, all ] = generateDataSet( "FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", 6268, 16 );

train = wks{ 1 };
for i = 2:wk-1
     train = vertcat( train, wks{ i } );
end

validate = wks{ wk };

% load Team Rankings Data
TeamRankingsGenerator;
load( 'TeamRankings.mat' );


currentWeights = [1, 0.35, -1.9041, 0.4 ];
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
       risk( i ) = 1000;
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

   progress_bar( i, pNum, 0 );
end

%%
for j = rsk_wght
    T = table( Player, ExpectedPoints, risk, Week, Position );

    [ QB, RB, WR, TE, DST, K ] = GeneratePositions( T );
    [ A, r ] = createExPointsRiskMatrix( QB, RB, WR, TE, DST, K );

    [ x ] = tmSel( A, r, des_pts, j, scr_wght, des_rsk );

    [ row, col ] = find( x > 0.3 );

    picks = [ row, col ];
    picks = sortrows( picks, 1 );

    playerInd = getHeaderInd( QB, 'Player' );
    ptsInd = getHeaderInd( QB, 'ExpectedPoints' );
    riskInd = getHeaderInd( QB, 'risk' );                              

    posNames = [ "QB", "RB1", "RB2", "WR1", "WR2", "TE", "DST", "K" ];
    posDBs = { QB; RB; RB; WR; WR; TE; DST; K };

    tot_score = 0.0;
    tot_risk = 0.0;

    for p = 1:length( row )
        DB = posDBs{ picks( p, 1 ) };
        tmp = full( x );

        tot_score = tot_score + DB{ picks( p, 2 ), ptsInd };
        tot_risk = tot_risk + DB{ picks( p, 2 ), riskInd };
    end

    pareto( :, find( rsk_wght == j, 1, 'first' ) ) = [ scr_wght, j, tot_score, tot_risk ]';
    
    progress_bar( find( rsk_wght == j, 1, 'first' ), length( rsk_wght ), 0 );
end

%%
plot( pareto( 2, : ), pareto( 3, : ) );
xlabel( '\lambda' );
ylabel( 'Expected points' );
title( 'Fantasy Football Pareto' );

axis( [ min( rsk_wght ) * 0.9, max( rsk_wght ) * 1.1 0 max( pareto( 3, : ) ) * 1.1 ] );


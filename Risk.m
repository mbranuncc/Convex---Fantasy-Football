clc; clear all; close all

tic;

wk = 12;
fittingOrder = 5;

% Load Injury data
InjuryDataGenerator;
load( 'Injury.mat' );

% Load General Data
DataSetGenerator;
load( 'Training.mat' );
train = T;

load( 'Validation.mat' );
validate = T;

load( 'Testing.mat' );
testing = T;

% load Team Rankings Data
TeamRankingsGenerator;
load( 'TeamRankings.mat' );

Player = unique( train{ 1:end, 2 } );
pNum = length( Player );

% create output variables
ExpectedPoints = zeros( pNum,  1 );
risk = zeros( pNum, 1 );
Week = zeros( pNum, 1 );
Position = strings( pNum, 1 );

% just for testing
currentWeights = [ 1, 0.35, .1, .4 ];
prevErr = -1;

while( 1 )
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

       % create the following vector of interest
       % 1) difference in ranking
       % 2) difference in average pt diff
       % 3) difference in max win
       % 4) difference in max loss
       v1 = getHeaderInd( playerTeam, "Rank" );
       v2 = getHeaderInd( playerTeam, "AveragePtDiff" );
       v3 = getHeaderInd( playerTeam, "MaxWin" );
       v4 = getHeaderInd( playerTeam, "MaxLoss" );

       aV = [ playerTeam{ 1, v1 } - oppTeam{ 1, v1 };
              playerTeam{ 1, v2 } - oppTeam{ 1, v2 };
              playerTeam{ 1, v3 } - oppTeam{ 1, v3 };
              playerTeam{ 1, v4 } - oppTeam{ 1, v4 } ];

       risk( i ) = currentWeights * aV;
       ExpectedPoints( i ) = ExpectedPts_LR( train, Player( i ), wk, fittingOrder );
%        ExpectedPoints( i ) = ExpectedPts_RR( train, Player( i ), wk, 0.1 );
       Week( i ) = wk;
       Position( i ) = cellstr( getPlayerPosition( train, Player( i ) ) );

       progress_bar( i, pNum, 0 );
    end

    %%
    T = table( Player, ExpectedPoints, risk, Week, Position );

    [ QB, RB, WR, TE, DST, K ] = GeneratePositions( T );
    [ A, r ] = createExPointsRiskMatrix( QB, RB, WR, TE, DST, K );

    [ x ] = teamSelector( A, r, 30 );

    [ row, col ] = find( x > 0.9 );

    picks = [ row, col ];
    picks = sortrows( picks, 1 );

    playerInd = getHeaderInd( QB, 'Player' );
    ptsInd = getHeaderInd( QB, 'ExpectedPoints' );
    riskInd = getHeaderInd( QB, 'risk' );

    fprintf("Selected Team: \n" )
    fprintf("QB: %s, pts: %f, risk: %f\n", QB{ picks( 1, 2 ), playerInd }, QB{ picks( 1, 2 ), ptsInd }, ...
                                           QB{ picks( 1, 2 ), riskInd } );
    fprintf("RB1: %s, pts: %f, risk: %f\n", RB{ picks( 2, 2 ), playerInd }, RB{ picks( 2, 2 ), ptsInd }, ...
                                           RB{ picks( 2, 2 ), riskInd } );
    fprintf("RB2: %s, pts: %f, risk: %f\n", RB{ picks( 3, 2 ), playerInd }, RB{ picks( 3, 2 ), ptsInd }, ...
                                           RB{ picks( 3, 2 ), riskInd } );
    fprintf("WR1: %s, pts: %f, risk: %f\n", WR{ picks( 4, 2 ), playerInd }, WR{ picks( 4, 2 ), ptsInd }, ...
                                           WR{ picks( 4, 2 ), riskInd } );
    fprintf("WR2: %s, pts: %f, risk: %f\n", WR{ picks( 5, 2 ), playerInd }, WR{ picks( 5, 2 ), ptsInd }, ...
                                           WR{ picks( 5, 2 ), riskInd } );
    fprintf("TE: %s, pts: %f, risk: %f\n", TE{ picks( 6, 2 ), playerInd }, TE{ picks( 6, 2 ), ptsInd }, ...
                                           TE{ picks( 7, 2 ), riskInd } );
    fprintf("DST: %s, pts: %f, risk: %f\n", DST{ picks( 7, 2 ), playerInd }, DST{ picks( 7, 2 ), ptsInd }, ...
                                           DST{ picks( 7, 2 ), riskInd } );
    fprintf("K: %s, pts: %f, risk: %f\n", K{ picks( 8, 2 ), playerInd }, K{ picks( 8, 2 ), ptsInd }, ...
                                           K{ picks( 8, 2 ), riskInd } );                                   


   % calculating error and formulating weights change
    qbDiff = pts4Player( QB{ picks( 1, 2 ), playerInd }, wk, validate ) - QB{ picks( 1, 2 ), ptsInd };
    rb1Diff = pts4Player( RB{ picks( 2, 2 ), playerInd }, wk, validate ) - RB{ picks( 2, 2 ), ptsInd };
    rb2Diff = pts4Player( RB{ picks( 3, 2 ), playerInd }, wk, validate ) - RB{ picks( 3, 2 ), ptsInd };
    wr1Diff = pts4Player( WR{ picks( 4, 2 ), playerInd }, wk, validate ) - WR{ picks( 4, 2 ), ptsInd };
    wr2Diff = pts4Player( WR{ picks( 5, 2 ), playerInd }, wk, validate ) - WR{ picks( 5, 2 ), ptsInd };
    teDiff = pts4Player( TE{ picks( 6, 2 ), playerInd }, wk, validate ) - TE{ picks( 6, 2 ), ptsInd };
    dstDiff = pts4Player( DST{ picks( 7, 2 ), playerInd }, wk, validate ) - DST{ picks( 7, 2 ), ptsInd };
    kDiff = pts4Player( K{ picks( 8, 2 ), playerInd }, wk, validate ) - K{ picks( 8, 2 ), ptsInd };

    diff = [ qbDiff, rb1Diff, rb2Diff, wr1Diff, wr2Diff, teDiff, dstDiff, kDiff ];
    currErr = diff * diff';
    if( currErr < prevErr )
        break;
    end
    
    
    prevErr = currErr;
    grads = eye( 4 );
    grads( 1, 1 ) = 0.9;
    grads( 2, 2 ) = 0.2;
    grads( 3, 3 ) = 0.5;
    grads( 4, 4 ) = 1.1;
    currentWeights = currentWeights * grads;
end

toc


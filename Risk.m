clc; clear all; close all

addpath( "Functions/" );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define functions to use for expected value and team selection
exVal = @ExpectedPts_RR;
% exVal = @ExpectedPts_LG;
% exVal = @ExpectedPts_LR;

tmSel = @TS_MultiOpt_Int; % use this one if Mosek is not installed
% tmSel = @TS_UniOpt_Int; % <- Requries Mosek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


tic;

outputFileName = "Generated Teams.txt";
fd = fopen( outputFileName, 'w' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define working parameters

fittingOrder = 3;
alpha = 15;
des_pts = 80;

dataSets = [ 1, 15;
            16, 17 ];

wk = dataSets( 2, 1 );

gradVel = .001;
gradStep = .1;

rsk_wght = 0.1;
scr_wght = 0.9;
des_rsk = 15;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numValidate = dataSets( 2, 2 ) - dataSets( 2, 1 ) + 1;
if( numValidate < 1 )
    emsg = "ERROR: Risk - validate week set must be in numerical order";
    error( emsg );
end

% Load Injury data
InjuryDataGenerator;
load( 'Injury.mat' );

[ wks, all ] = generateDataSet( "FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", 6268, max( max( dataSets ) ) );

% load Team Rankings Data
TeamRankingsGenerator;
load( 'TeamRankings.mat' );

% just for testing
currentWeights = [ 1, 0.35, .1, .4 ];
prevErr = -1;
weightsArr = [];

counter = 0;
while( 1 )
    wk = dataSets( 2, 1 );
    
    totalErr = 0;
    for j = 1:numValidate        
        % Generate relevant training and validation week sets
        % this is incorrect, not updating by prediction week
        train = wks{ dataSets( 1, 1 ) };
        for i = dataSets( 1, 1 )+1:wk-1
             train = vertcat( train, wks{ i } );
        end

        validate = wks{ wk };
%         for i = dataSets( 2, 1 ) + 1:dataSets( 2, 2 )
%             validate = vertcat( validate, wks{ i } ); 
%         end
        
        Player = unique( train{ 1:end, getHeaderInd( train, 'Name' ) } );
        pNum = length( Player );

        % create output variables
        ExpectedPoints = zeros( pNum,  1 );
        risk = zeros( pNum, 1 );
        Week = zeros( pNum, 1 );
        Position = strings( pNum, 1 );
        
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
           ExpectedPoints( i ) = exVal( train, Player( i ), wk, fittingOrder, alpha );
           Week( i ) = wk;
           Position( i ) = cellstr( getPlayerPosition( train, Player( i ) ) );

           progress_bar( i, pNum, 0 );
        end

        %%
        T = table( Player, ExpectedPoints, risk, Week, Position );

        [ QB, RB, WR, TE, DST, K ] = GeneratePositions( T );
        [ A, r ] = createExPointsRiskMatrix( QB, RB, WR, TE, DST, K );

    %     [ x ] = teamSelector( A, r, des_pts );
        [ x ] = tmSel( A, r, des_pts, rsk_wght, scr_wght, des_rsk );

        [ row, col ] = find( x > 0.3 );

        picks = [ row, col ];
        picks = sortrows( picks, 1 );

        playerInd = getHeaderInd( QB, 'Player' );
        ptsInd = getHeaderInd( QB, 'ExpectedPoints' );
        riskInd = getHeaderInd( QB, 'risk' );

        fprintf("Selected Team for Week %d: \n", wk );                                

        posNames = [ "QB", "RB1", "RB2", "WR1", "WR2", "TE", "DST", "K" ];
        posDBs = { QB; RB; RB; WR; WR; TE; DST; K };

        tot_score = 0.0;
        tot_risk = 0.0;

        for p = 1:length( row )
            DB = posDBs{ picks( p, 1 ) };
            tmp = full( x );
            fprintf( "%s: %s, pts: %f, risk: %f, weight: %5.4f\n", posNames( picks( p, 1 ) ), ...
                       DB{ picks( p, 2 ), playerInd }, DB{ picks( p, 2 ), ptsInd }, ...
                        DB{ picks( p, 2 ), riskInd }, tmp( picks( p, 1 ), picks( p, 2 ) ) );

            fprintf( fd, "%s: %s, pts: %f, risk: %f, weight: %5.4f\n", posNames( picks( p, 1 ) ), ...
                       DB{ picks( p, 2 ), playerInd }, DB{ picks( p, 2 ), ptsInd }, ...
                        DB{ picks( p, 2 ), riskInd }, tmp( picks( p, 1 ), picks( p, 2 ) ) );

            tot_score = tot_score + DB{ picks( p, 2 ), ptsInd };
            tot_risk = tot_risk + DB{ picks( p, 2 ), riskInd };
        end

        fprintf( "Total Team Score: %f, Total Team Risk: %f\n", tot_score, tot_risk );
        fprintf( fd, "Total Team Score: %f, Total Team Risk: %f\n", tot_score, tot_risk );
        for y = 1:length( currentWeights )
            fprintf( fd, "Weight %d: %f, ", y, currentWeights( y ) );
        end
        fprintf( fd, "\n\n" );

       % calculating error and formulating weights change
        diff = zeros( length( row ), 1 );
        for p = 1:length( row )
            DB = posDBs{ picks( p, 1 ) };
            diff( p ) = pts4Player( DB{ picks( p, 2 ), playerInd }, wk, validate ) - DB{ picks( p, 2 ), ptsInd };
        end

        currErr = diff' * diff;
        totalErr = totalErr + currErr;
        
        wk = wk + 1;
        if( wk > dataSets( 2, 2 ) )
            break;
        end
    end
    
%     if( ( totalErr < prevErr ) || ( counter > 4 ) )
    if( counter > ( 5*4 - 1 ) )
        break;
    end

    prevErr = totalErr;
    
    [ newWeights, weightsArr ] = updateWeights( currentWeights, currErr, prevErr, weightsArr, gradVel, gradStep );
    
    currentWeights = newWeights;
    
    counter = counter + 1;
end

%%
fclose( 'all' );

delete( 'Injury.mat' );
delete( 'TeamRankings.mat' );

save( 'weights.mat', 'weightsArr' );

clc; clear all; close all

toc

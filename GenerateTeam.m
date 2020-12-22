clc; clear all; close all

parameters;

addpath( "Functions/" );
addpath( "Functions/export_fig" );

exVal = @ExpectedPts_RR;

tmSelVec = { @TS_MultiOpt_Int };
tmSelName = { "TS\_MultiOpt\_Int" };

%%
% Working Parameters

load( 'parameters.mat' );

wk = max( max( dataSets ) ) + 1;

rsk_wght = rArr( 2 );
scr_wght = 1 - rsk_wght;

fileName = "Selected Team.txt";
fd = fopen( fileName, 'w' );

%%

% Load Injury data
InjuryDataGenerator;
load( 'Injury.mat' );

[ wks, all ] = generateDataSet( "FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", 6268, wk );

train = wks{ 1 };
for i = 2:wk-1
     train = vertcat( train, wks{ i } );
end

validate = wks{ wk };

% load Team Rankings Data
TeamRankingsGenerator;
load( 'TeamRankings.mat' );


currentWeights = baseWeights;
Player = unique( train{ 1:end, getHeaderInd( train, 'Name' ) } );
pNum = length( Player );

% create output variables
ExpectedPoints = zeros( pNum,  1 );
risk = zeros( pNum, 1 );
Week = zeros( pNum, 1 );
Position = strings( pNum, 1 );

for i = 1:length( Player )
   % check if player is injured
   injInd = find( strcmp( Player( i ), Injury{ :, 1 } ) == 1, 1, 'first' );
   if( injInd > 0 )
       if( Injury{ injInd, 2 } > 0 )
           risk( i ) = rMax;
           continue;
       end
   end

   % get data from the player's team
   playerTeam = playerTeamData( train, TeamRankings, Player( i ) );

   % get data from the player's opponent
   oppTeam = playerTeam{ 1, getHeaderInd( playerTeam, strcat( "x", int2str( wk ) ) ) };
   if( strcmp( oppTeam, "BYE" ) )
       risk( i ) = rMax;
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
    for j = 1:length( rsk_wght )
        T = table( Player, ExpectedPoints, risk, Week, Position );

        [ QB, RB, WR, TE, DST, K ] = GeneratePositions( T );
        [ A, r ] = createExPointsRiskMatrix( QB, RB, WR, TE, DST, K, rMax );

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


       % calculating error and formulating weights change
        diff = zeros( length( row ), 1 );
        for p = 1:length( row )
            DB = posDBs{ picks( p, 1 ) };
            diff( p ) = pts4Player( DB{ picks( p, 2 ), playerInd }, wk, validate ) - DB{ picks( p, 2 ), ptsInd };
        end

        currErr = diff' * diff / length( row )^2; % error divided by number of players selected. Hopefully biases against solutions where a full team isn't successfully picked

        fprintf( "\n" );
        fprintf( fd, "Average Error: %f\n", currErr );
        fprintf( fd, "\n\n" );

    end
    tme = toc;
    
    fprintf( "%s run time: %3.3f\n", tmSelName{ z }, tme );
end

fclose( 'all' );
clc; clear all; close all

parameters;

addpath( "Functions/" );


load( 'parameters.mat' );

tic;

outputFileName = "Generated Teams.txt";
fd = fopen( outputFileName, 'w' );

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

for z = 1:length( rArr )

    rsk_wght = rArr( z );
    scr_wght = 1 - rsk_wght;

    currentWeights = baseWeights;

    prevErr = -1;
    weightsArr = [];
    gradHist = [];
    errHist = [];
    totalErrHist = [];

    counter = 0;
    cutOff = 8 * ( numel( currentWeights ) + 1 );
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

            Player = unique( train{ 1:end, getHeaderInd( train, 'Name' ) } );
            pNum = length( Player );

            % create output variables
            ExpectedPoints = zeros( pNum,  1 );
            risk = zeros( pNum, 1 );
            Week = zeros( pNum, 1 );
            Position = strings( pNum, 1 );

            for ( i = 1:length( Player ) )
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
               ExpectedPoints( i ) = exVal( train, Player( i ), wk, fittingOrder, RR_weight );
               Week( i ) = wk;
               Position( i ) = cellstr( getPlayerPosition( train, Player( i ) ) );

               progress_bar( i, pNum, counter, cutOff );
            end

            %%
            T = table( Player, ExpectedPoints, risk, Week, Position );

            [ QB, RB, WR, TE, DST, K ] = GeneratePositions( T );
            [ A, r ] = createExPointsRiskMatrix( QB, RB, WR, TE, DST, K, rMax );

            % normalize risk
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

            % perform team selection
            [ x, cvx_status ] = tmSel( A, r, des_pts, rsk_wght, scr_wght, des_rsk );

            % pick any player over arbitrary threshold
            [ row, col ] = find( x > 0.3 );

            picks = [ row, col ];
            picks = sortrows( picks, 1 );

            fprintf("Selected Team for Week %d with cvx_status: %s\n", wk, cvx_status );
            fprintf( fd, "Selected Team for Week %d with cvx_status: %s\n", wk, cvx_status ); 

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
            totalErr = totalErr + currErr;

            errHist = [ errHist; totalErr ];

            fprintf( "\n" );
            fprintf( fd, "Average Error: %f\n", currErr );
            fprintf( fd, "\n\n" );

            wk = wk + 1;
            if( wk > dataSets( 2, 2 ) )
                break;
            end
        end

        totalErrHist = [ totalErrHist; totalErr ];
        
        if( counter > cutOff )
            break;
        end

        prevErr = totalErr;

        [ newWeights, weightsArr, gradient, t ] = gradWeights( currentWeights, totalErr, prevErr, weightsArr, alpha, t, gradStep );

        if( numel( gradient ) == 1 )
            tmp = zeros( length( currentWeights ), 1 );
            tmp( 1 ) = gradient;
            gradHist = [ gradHist; [ tmp', t ] ];
        else 
            gradHist = [ gradHist; [ gradient', t ] ];
        end


        ng = norm( gradient );
        if( ng <= endPt )
            break;
        end

        currentWeights = newWeights;

        counter = counter + 1;
    end

    %%
    plot( errHist, 'o-' );
    saveas( sprintf( "Media/Descent_Path_A%2.2f_r%2.2f_a%1.6f.png", scr_wght, rsk_wght, alpha ) );
    save( sprintf( "Media/gradient_A%2.2f_r%2.2f_a%1.6f.mat", scr_wght, rsk_wght, alpha ), 'gradHist' );
    save( sprintf( "Media/errHist_A%2.2f_r%2.2f_a%1.6f.mat", scr_wght, rsk_wght, alpha ), 'errHist' );
    save( sprintf( "Media/weightsArr_A%2.2f_r%2.2f_a%1.6f.mat", scr_wght, rsk_wght, alpha ), 'weightsArr' );
end
fclose( 'all' );

delete( 'Injury.mat' );
delete( 'TeamRankings.mat' );

clc; clear all;

toc

clc; clear all; close all

parameters;

addpath( "Functions/" );
addpath( "Functions/export_fig" );

% exVal = @ExpectedPts_RR;

tmSelVec = { @TS_MultiOpt_Int, @TS_MultiOpt_Float, @TS_UniOpt_Int };
tmSelName = { "TS\_MultiOpt\_Int", "TS\_MultiOpt\_Float", "TS\_UniOpt\_Int" };
times = zeros( length( tmSelVec ), 1 );

%%
% Working Parameters
% fittingOrder = 3;
% alpha = 15;
% des_pts = 80;


load( 'parameters.mat' );

wk = max( max( dataSets ) ) + 1;

stp = 0.05;
rsk_wght = stp:stp:1-stp;
scr_wght = 1 - rsk_wght;

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

pareto = zeros( 4, length( rsk_wght ) );

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
    for j = 1:length(rsk_wght)
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

    semilogx( pareto( 3, 1:end ), pareto( 4, 1:end ), 'o-' );
    xlabel( 'Expected Points' );
    ylabel( 'Risk' );

    title( tmSelName{ z } );
    
    saveas( strcat( "Media/", strrep( cellstr( tmSelName{ z } ), "\", "" ), ".png" ) );
    
    fprintf( "%s run time: %3.3f\n", tmSelName{ z }, tme );
end

%%
figure;
v = diag( times );
bar( v );
legend( tmSelName );
% export_fig( "Media/Run Times.png" );
saveas( "Media/Run Times.png" );

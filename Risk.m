clc; clearvars -except Injury AssortedData TeamRankings; close all

tic;

wk = 17;

lines2read = 1196;
if( exist( 'Injury', 'var' ) ~= 1 )
    Injury = Injuryimport( "FantasyDatacom_WkByWk.xlsm", "Injury List", [ 2 lines2read ] );
end

lines2read = 33;
if( exist( 'AssortedData', 'var' ) ~= 1 )
    TeamRankings = RankingsImport( "FantasyDatacom_WkByWk.xlsm", "Team Rankings", [ 2 lines2read ] );
end

lines2read = 6268;
if( exist( 'AssortedData', 'var' ) ~= 1 )
    AssortedData = AssortedDataimport( "FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", [ 2 lines2read ] );
end

C = unique( AssortedData{ 1:end, 2 } );
pNum = length( C );

risk = zeros( pNum, 1 );
[ mTR, nTR ] = size( TeamRankings );
[ mAD, nAD ] = size( AssortedData );

for i = 1:pNum
    % check if injurt is present, set risk to 100 then skip
    if( Injury{ i, 2 } == 1 )
        risk( i ) = 100;
        continue;
    end
    
    % get the team of the player
    ind = find( AssortedData{ :, 2 } == C( i ), 1, 'first' );
    team = AssortedData{ ind, 5 };
    
    % store stats from player team
    tInd = find( TeamRankings{ :, 2 } == cellstr( team ), 1, 'first' );
    
    % Wins = 3, Loses, Ties, Total Pt Diff, Average Pt Diff, Pt Variange
    % Max Loss, Max Win, Rank
    pTeam = TeamRankings{ tInd, 3:12 };
    
    % get opponent team
    opp = TeamRankings{ tInd, wk+12 };
    tInd = find( TeamRankings{ :, 2 } == cellstr( opp ), 1, 'first' );
    
    oppTeam = TeamRankings{ tInd, 3:12 };
    
end


toc


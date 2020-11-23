clc;

fprintf("Importing Team Rankings Data...\n");

% set error message
emsg = "ERROR: TeamRankingsGenerator: ";

lines2read = 33;
TeamRankings = RankingsImport( "FantasyDatacom_WkByWk.xlsm", "Team Rankings", [ 2 lines2read ] );

save( 'TeamRankings.mat', 'TeamRankings' );
clc;

fprintf("Importing Injury Data...\n");

% set error message
emsg = "ERROR: InjuryDataGenerator: ";

lines2read = 1196;
Injury = Injuryimport( "FantasyDatacom_WkByWk.xlsm", "Injury List", [ 2 lines2read ] );

save( 'Injury.mat', 'Injury' );
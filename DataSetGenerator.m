clc;

fprintf("Creating Data Sets...\n");

% define error message
emsg = "ERROR: DataSetGenerator: ";

% define desired dataSet types
dataSets = [ "Training", "Validation", "Testing" ];
dataSetWks = [ 1 10;
               11 16;
               17 17 ];
           
if( numel( dataSets ) ~= numel( dataSetWks ) / 2 )
    emsg = strcat( emsg, " Verify that data set designations are correct" );
    error( emsg );
end

% load data
lines2read = 6268;
AssortedData = AssortedDataimport( "FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", [ 2 lines2read ] );

% ensure that data is sorted by incrementing week
AssortedData = sortrows( AssortedData, getHeaderInd( AssortedData, 'WK' ), 'ascend' );

% loop through data sets
wkInd = getHeaderInd( AssortedData, 'WK' );
for i = 1:numel( dataSets )
   % find the start and end of set
   strt = dataSetWks( i, 1 );
   endd = dataSetWks( i, 2 );
   
   strtInd = find( AssortedData{ :, wkInd } == strt, 1, 'first' );
   endInd = find( AssortedData{ :, wkInd } == endd, 1, 'last' );
   if( length( strtInd ) < 0 || length( endInd ) < 0 )
       emsg = strcat( emsg, sprintf("Couldn't find weeks associated with %s", dataSets( i ) ) );
       error( emsg );
   end
   
   T =  AssortedData( strtInd:endInd, : );
   fName = sprintf("%s.mat", dataSets( i ) );
   save( fName, 'T' );
end

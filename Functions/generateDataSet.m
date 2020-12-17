function [ wks, all ] = generateDataSet( excel_sheet, sheet_name, lines2read, wk_stop )

fprintf( "Creating data sets from %s:%s\n", excel_sheet, sheet_name );
fprintf( "Training data set to be: 1-%d, Testing data set to be %d\n", wk_stop-1, wk_stop );

emsg = "ERROR: generateDataSet";

% load data
AssortedData = AssortedDataimport( excel_sheet, sheet_name, [ 2, lines2read ] );

% ensure that data is sorted by incrementing week
AssortedData = sortrows( AssortedData, getHeaderInd( AssortedData, 'WK' ), 'ascend' );

all = AssortedData;

% loop through and create data set for each week
wkInd  = getHeaderInd( AssortedData, 'WK' );
for i = 1:wk_stop
   inds = find( AssortedData{ :, wkInd } == i ); 
   if( length( inds ) < 1 )
       emsg = strcat( emsg, sprintf("Couldn't find week associated with %s", i ) );
       error( emsg );
   end
   
%    tmp{ 1 } = AssortedData( inds( 1 ), : );
%    for j = 2:length( inds )
%        tmp{ j } = AssortedData( inds( j ), : );
%    end
   tmp = AssortedData( inds, : );
   
   wks{ i } = tmp;
end

end
function [ newWeights, weightsArr ] = updateWeights( currentWeights, currErr, prevErr, weightsArr, alpha, step_size )
% function to update the weights used to calculate the risk based on 'n'
% number of factors

% add current weights and error to weightsArr
weightsArr = [ weightsArr; [ currentWeights, currErr ] ];

% verify gradient scheme
% look at the numbers of terms being evaluated
numTerms = length( currentWeights );

% based on method, iterations per loop is numTerms+1
iterNum = numTerms + 1;

% mod( rows( weightsArr ), iterNum ) should be the index of the weights
% array to be updated
ind = mod( size( weightsArr, 1 ) + iterNum, iterNum );

% update the desired ind from base which is weightsArr( iterNum*k ) where k
% is the largest integer where iterNum*k exists in array
baseInd = floor( size( weightsArr, 1 ) / iterNum )+1;
if( size( weightsArr, 1 ) / iterNum  == baseInd-1 )
    fprintf( "This should be the ind where all weights should be updated\n" );
    
    % calculate gradient from last iteration loop
    baseError = weightsArr( end - numTerms, end );
    
    Egrads = zeros( numTerms, 1 );
    for i = 1:length( Egrads )
       stepErr = weightsArr( end - numTerms + i, end );
       
       Egrads( i ) = ( baseError - stepErr ) / step_size;
    end
    
    base = weightsArr( ( baseInd - 2 ) * iterNum + 1, : );
    
    newWeights = base( 1:numTerms );
    newWeights = newWeights - alpha * Egrads';
else
    if( ( baseInd - 2 ) * iterNum + 1 < 1 )
        baseInd = 1;
    end
    base = weightsArr( baseInd, : );

    newWeights = base( 1:numTerms );
    newWeights( ind ) = newWeights( ind ) + step_size;
end

end
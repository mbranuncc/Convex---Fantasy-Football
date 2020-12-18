function [ newWeights, weightsArr, gradient, pt ] = updateWeights( currentWeights, currErr, prevErr, weightsArr, alpha, t, step_size )
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

% baseInd = floor( size( weightsArr, 1 ) / iterNum )+1;
baseInd = mod( size( weightsArr, 1 ), iterNum );
baseInd = ceil( ( size( weightsArr, 1 ) - baseInd ) / iterNum );
if( size( weightsArr, 1 ) / iterNum  == baseInd )
%     fprintf( "This should be the ind where all weights should be updated\n" );
    
    baseInd = ( baseInd - 1 ) * iterNum + 1;
    if( baseInd < 1 )
        baseInd = 1;
    end
    
    % calculate gradient from last iteration loop
    baseError = weightsArr( end - numTerms, end );
    
    Egrads = zeros( numTerms, 1 );
    for i = 1:length( Egrads )
       stepErr = weightsArr( end - numTerms + i, end );
       
       Egrads( i ) = -1 * ( baseError - stepErr ) / step_size;
    end
    
    base = weightsArr( baseInd, : );
    
    newWeights = base( 1:numTerms );
    newWeights = newWeights - alpha * Egrads';
    
    gradient = Egrads;
else
    baseInd = ( baseInd ) * iterNum + 1;
    if( baseInd < 1 )
        baseInd = 1;
    end
    base = weightsArr( baseInd, : );

    newWeights = base( 1:numTerms );
    newWeights( ind ) = newWeights( ind ) + step_size;
    
    gradient = 100;
end

pt = t;

end
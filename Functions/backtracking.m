function [ newWeights, weightsArr, gradient, pt ] = backtracking( currentWeights, currErr, prevErr, weightsArr, alpha, t, step_size )
% function to update the weights used to calculate the risk based on 'n'
% number of factors

% add current weights and error to weightsArr with extra flag for
% backtracking
weightsArr = [ weightsArr; [ currentWeights, currErr, 0 ] ];

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
if( size( weightsArr, 1 ) > 1 && weightsArr( end-1, end ) > 0 )
    % handle backtracking
    
    % remove last array and store
    holder = weightsArr( end, : );
    weightsArr = weightsArr( 1:end-1, : );
    
    % end backtracking
%     weightsArr( end, end ) = 0;

    % check if last backtrack worked
%     holder = weightsArr( end, : );
%     weightsArr = weightsArr( 1:end-1, : );
    
    baseInd = ( baseInd - 1 ) * iterNum + 1;
    if( baseInd < 1 )
        baseInd = 1;
    end
    
    % calculate gradient from last iteration loop
    baseError = weightsArr( baseInd, end - 1 );
    
    Egrads = zeros( numTerms, 1 );
    for i = 1:length( Egrads )
       stepErr = weightsArr( baseInd + i - 1, end - 1 );
       
       Egrads( i ) = -1 * ( baseError - stepErr ) / step_size;
    end
    
    base = weightsArr( baseInd, : );
    holderErr = holder( end - 1 );
    
    
    tmp = baseError + alpha * t * ( Egrads' * Egrads );
    if( holderErr <= tmp )
        % stop backtracking
%         weightsArr = [ weightsArr; [ currentWeights, holder( end - 2 ), 0 ] ];
        weightsArr( end, end ) = 0;
        
        newWeights = base( 1:numTerms );
        newWeights = newWeights + t * Egrads';
        
        gradient = Egrads;
        pt = 0.001; % reset t for future iterations
    else
        pt = 0.3 * t;
        
        newWeights = base( 1:numTerms );
        newWeights = newWeights + pt * Egrads';

        gradient = Egrads;
    end
elseif( size( weightsArr, 1 ) / iterNum  == baseInd )
%     fprintf( "This should be the ind where all weights should be updated\n" );
    
    baseInd = ( baseInd - 1 ) * iterNum + 1;
    if( baseInd < 1 )
        baseInd = 1;
    end
    
    % calculate gradient from last iteration loop
    baseError = weightsArr( end - numTerms, end - 1 );
    
    Egrads = zeros( numTerms, 1 );
    for i = 1:length( Egrads )
       stepErr = weightsArr( end - numTerms + i - 1, end - 1 );
       
       Egrads( i ) = -1 * ( baseError - stepErr ) / step_size;
    end
    
    base = weightsArr( baseInd, : );
    
    newWeights = base( 1:numTerms );
    newWeights = newWeights + t * Egrads';
    
    gradient = Egrads;
    
    % initiate backtracking
%     weightsArr = weightsArr( 1:end-1, : );
    weightsArr( end, end ) = 1;
    pt = t;
else
    baseInd = ( baseInd ) * iterNum + 1;
    if( baseInd < 1 )
        baseInd = 1;
    end
    base = weightsArr( baseInd, : );

    newWeights = base( 1:numTerms );
    newWeights( ind ) = newWeights( ind ) + step_size;
    
    gradient = 100;
    pt = t;
end

end
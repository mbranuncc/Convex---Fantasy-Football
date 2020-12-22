clc; clear all; close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Create parameters .mat
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath( "Functions/" );
 
exVal = @ExpectedPts_RR;
% exVal = @ExpectedPts_LG;
% exVal = @ExpectedPts_LR;

tmSel = @TS_MultiOpt_Float;
% tmSel = @TS_MultiOpt_Int; % use this one if Mosek is not installed
% tmSel = @TS_UniOpt_Int; % <- Requries Mosek

% gradWeights = @updateWeights;
gradWeights = @backtracking;

fittingOrder = 3;
RR_weight = 15;
des_pts = 80;

dataSets = [ 1, 14;
            15, 16 ];

wk = dataSets( 2, 1 );

alpha = 1;
gradStep = .01;
t = 1;
endPt = 1;

rMax = 1000;

rArr = 0.1:0.1:0.9;
des_rsk = 15;

baseWeights = [ -3.978, -.5674, -.3081, -.2718 ];

save( 'parameters.mat' );
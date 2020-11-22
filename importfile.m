function QB = importfile1(filename, dataLines)
%IMPORTFILE1 Import data from a text file
%  QB = IMPORTFILE1(FILENAME) reads data from text file FILENAME for the
%  default selection.  Returns the data as a table.
%
%  QB = IMPORTFILE1(FILE, DATALINES) reads data for the specified row
%  interval(s) of text file FILENAME. Specify DATALINES as a positive
%  scalar integer or a N-by-2 array of positive scalar integers for
%  dis-contiguous row intervals.
%
%  Example:
%  QB = importfile1("D:\Documents\School\Grad School\Fall 2020\ECGR 5090\Project\QB.csv", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 04-Nov-2020 10:12:59

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 2, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Name", "Score"];
opts.VariableTypes = ["string", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Name", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Name", "EmptyFieldRule", "auto");

% Import the data
QB = readtable(filename, opts);

end
function AssortedData = AssortedDataimport(workbookFile, sheetName, dataLines)
%IMPORTFILE1 Import data from a spreadsheet
%  FANTASYDATACOMWKBYWK = IMPORTFILE1(FILE) reads data from the first
%  worksheet in the Microsoft Excel spreadsheet file named FILE.
%  Returns the data as a table.
%
%  FANTASYDATACOMWKBYWK = IMPORTFILE1(FILE, SHEET) reads from the
%  specified worksheet.
%
%  FANTASYDATACOMWKBYWK = IMPORTFILE1(FILE, SHEET, DATALINES) reads from
%  the specified worksheet for the specified row interval(s). Specify
%  DATALINES as a positive scalar integer or a N-by-2 array of positive
%  scalar integers for dis-contiguous row intervals.
%
%  Example:
%  FantasyDatacomWkByWk = importfile1("D:\Documents\School\Grad School\Fall 2020\ECGR 5090\Project\Convex - Fantasy Football\FantasyDatacom_WkByWk.xlsm", "Data-2019RegSeason", [2, 6268]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 23-Nov-2020 10:47:50

%% Input handling

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% If row start and end points are not specified, define defaults
if nargin <= 2
    dataLines = [2, 6268];
end

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 25);

% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = "A" + dataLines(1, 1) + ":Y" + dataLines(1, 2);

% Specify column names and types
opts.VariableNames = ["RK", "Name", "Helper", "Outcome", "TEAM", "HOMEAWAY", "WL", "PtDifferential", "POS", "WK", "OPP", "YDSPASS", "TDPASS", "INTPASS", "YDSRUSH", "TDRUSH", "RECREC", "YDSREC", "TDREC", "SCK", "INT", "FF", "RF", "FPTSG", "FPTS"];
opts.VariableTypes = ["double", "string", "string", "categorical", "categorical", "categorical", "categorical", "double", "categorical", "double", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify variable properties
opts = setvaropts(opts, ["Name", "Helper"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Name", "Helper", "Outcome", "TEAM", "HOMEAWAY", "WL", "POS", "OPP"], "EmptyFieldRule", "auto");

% Import the data
AssortedData = readtable(workbookFile, opts, "UseExcel", false);

for idx = 2:size(dataLines, 1)
    opts.DataRange = "A" + dataLines(idx, 1) + ":Y" + dataLines(idx, 2);
    tb = readtable(workbookFile, opts, "UseExcel", false);
    AssortedData = [AssortedData; tb]; %#ok<AGROW>
end

end
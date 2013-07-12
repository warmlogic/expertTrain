function [instructions] = et_processTextInstruct(instructFile,origText,replacementText)
%function [instructions] = et_processTextInstruct(instructFile,origText,replacementText)
%
% Input:
%  instructFile:    path to instructions file
%  origText:        cell array of text strings to be replaced
%                   (all instances will be replaced)
%  replacementText: cell array of strings with which to replace origText,
%                   in the same order as origText
%
% Output:
%  instructions:    string of instructions
%
% NB: 

if nargin == 2
  error('Need to input both origText and replacementText.')
end

if ~exist('origText','var') || isempty(origText)
  origText = {};
end

if ~exist('replacementText','var') || isempty(replacementText)
  replacementText = {};
end

if length(origText) ~= length(replacementText)
  error('origText and replacementText must be the same length.');
end

if exist(instructFile,'file')
  fid = fopen(instructFile, 'rt');
else
  error('Instructions file does not exist: %s',instructFile);
end
instructions = fread(fid, [1, inf], '*char');
fclose(fid);

% turn carriage returns into newlines
instructions = strrep(instructions,sprintf('\r'),sprintf('\n'));

if ~isempty(origText)
  for i = 1:length(origText)
    [findOrig] = strfind(instructions,origText{i});
    fprintf('%s: replacing %d instances of ''%s'' with ''%s''.\n',instructFile,length(findOrig),origText{i},replacementText{i});
    instructions = strrep(instructions,origText{i},replacementText{i});
  end
end

end % function

function [shuffledStims,randind] = et_shuffleStims(origStims,valueField,maxConsec)
% function [shuffledStims,randind] = et_shuffleStims(origStims,valueField,maxConsec)
%
% Description:
%  Shuffle stimuli until there are no more than X consecutive stimuli of a
%  given type in a row.
%
% Input:
%  origStims:  Struct. Stimuli to shuffle. Assumes that the field
%              stims.(valueField) consists of integers.
%  valueField: String. Name of the field on which the order is contingent.
%              (default = '')
%  maxConsec:  Integer. Maximum number of consecutive stimuli from the same
%              value field. (default = 0; no contingencies on valueField)
%
% Output:
%  shuffledStims: Stimuli in shuffled order.
%  randind:       The shuffled indices.
%
% NB: Makes 1,000,000 shuffle attempts before erroring due to not finding a
%     solution.
%

if ~exist('valueField','var') || isempty(valueField)
  valueField = '';
end
if ~exist('maxConsec','var') || isempty(maxConsec)
  maxConsec = 0;
end

not_good = true;
maxShuffle = 1000000;
shuffleCount = 1;
if maxConsec > 0
  fprintf('Shuffle count: %s',repmat(' ',1,length(num2str(maxShuffle))));
end
while not_good
  % shuffle the stimuli
  randind = randperm(length(origStims));
  % debug
  %randind = 1:length(stims);
  %fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  % shuffle the exemplars
  stims = origStims(randind);
  
  if maxConsec > 0
    fprintf(1,[repmat('\b',1,length(num2str(shuffleCount))),'%d'],shuffleCount);
    
    % pull the contents out
    if isnumeric(stims(1).(valueField)) || islogical(stims(1).(valueField))
      stimValues = [stims.(valueField)];
    elseif ischar(stims(1).(valueField))
      stimValues = {stims.(valueField)};
    end
    
    possibleValues = unique(stimValues);
    % initialize to count how many of each value we find
    consecCount = zeros(1,length(possibleValues));
    
    % increment the value for the first stimulus
    consecCount(ismember(possibleValues,stimValues(1))) = 1;
    
    for i = 2:length(stimValues)
      if ismember(stimValues(i),stimValues(i-1))
        % if we found a repeat, add 1 to the count
        consecCount(ismember(possibleValues,stimValues(i))) = consecCount(ismember(possibleValues,stimValues(i))) + 1;
        if consecCount(ismember(possibleValues,stimValues(i))) > maxConsec
          % if we hit the maximum number, break out
          break
        end
      else
        % if it's not a repeat, reset the count
        consecCount = zeros(1,length(possibleValues));
        consecCount(ismember(possibleValues,stimValues(i))) = 1;
      end
      
    end
  else
    consecCount = 0;
  end
  
  if maxConsec > 0 && any(consecCount > maxConsec)
    shuffleCount = shuffleCount + 1;
  elseif ~any(consecCount > maxConsec)
    not_good = false;
    shuffledStims = stims;
    if maxConsec > 0
      fprintf('\n');
    end
    fprintf('Successfully shuffled the stimuli');
    if maxConsec > 0
      fprintf(' contingent on the %s field',valueField);
    end
    fprintf('.\n');
  end
  
  if shuffleCount == maxShuffle && not_good
    error('\nUnsuccessful. Performed %d shuffle attempts. That is too many.',maxShuffle);
  end
end % while

end

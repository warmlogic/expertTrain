function [stims,randind] = et_shuffleStims(origStims,valueField,maxConsec)
% function [stims,randind] = et_shuffleStims(origStims,valueField,maxConsec)
%
% Description:
%  Shuffle stimuli until there are no more than X consecutive stimuli of a
%  given type in a row.
%
% Input:
%  origStims:  Struct. Stimuli to shuffle. Assumes that the field
%              stims.(valueField) consists of integers.
%  valueField: Cell of strings. Name(s) of the field on which the order is
%              contingent. (default = {''})
%  maxConsec:  Array (length of valueField). Maximum number of consecutive
%              stimuli from the corresponding value field. (default = 0; no
%              contingencies on valueField)
%
% Output:
%  stims:      Stimuli in shuffled order.
%  randind:    The shuffled indices.
%
% NB: Makes 1,000,000 shuffle attempts before erroring due to not finding a
%     solution.
%

if ~exist('valueField','var') || isempty(valueField)
  valueField = {''};
end
if ~iscell(valueField)
  valueField = {valueField};
end

if ~exist('maxConsec','var') || isempty(maxConsec)
  maxConsec = zeros(1,length(valueField));
end
if all(maxConsec == 0)
  testingConsec = false;
else
  testingConsec = true;
end

% not_good = true;
not_good = true(1,length(valueField));
maxShuffle = 1000000;
shuffleCount = 1;
if testingConsec
  fprintf('Shuffle count: %s',repmat(' ',1,length(num2str(maxShuffle))));
end
while any(not_good)
  % shuffle the stimuli
  randind = randperm(length(origStims));
  % debug
  %randind = 1:length(stims);
  %fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  % shuffle the exemplars
  stims = origStims(randind);
  
  if testingConsec
    fprintf(1,[repmat('\b',1,length(num2str(shuffleCount))),'%d'],shuffleCount);
    
    for vf = 1:length(valueField)
      
      % TODO: I think I need a while loop in here for this vf
      
      % pull the contents out
      if isnumeric(stims(1).(valueField{vf})) || islogical(stims(1).(valueField{vf}))
        stimValues = [stims.(valueField{vf})];
      elseif ischar(stims(1).(valueField{vf}))
        stimValues = {stims.(valueField{vf})};
      else
        error('%s is not set up to handle data of class ''%s''.',mfilename,class(stims(1).(valueField{vf})));
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
          if consecCount(ismember(possibleValues,stimValues(i))) > maxConsec(vf)
            % if we hit the maximum number, break out
            break
          end
        else
          % if it's not a repeat, reset the count
          consecCount = zeros(1,length(possibleValues));
          consecCount(ismember(possibleValues,stimValues(i))) = 1;
        end
        
      end
      
      if any(consecCount > maxConsec(vf))
        shuffleCount = shuffleCount + 1;
      elseif ~any(consecCount > maxConsec(vf))
        not_good(vf) = false;
      end
      
    end
    if shuffleCount == maxShuffle && any(not_good)
      error('\nUnsuccessful. Performed %d shuffle attempts. That is too many.',maxShuffle);
    end
  else
    break
  end
  
end % while

fprintf('\nSuccessfully shuffled the stimuli');
if testingConsec
  fprintf(' contingent on the field(s):%s',sprintf(repmat(' %s',1,length(valueField)),valueField{:}));
end
fprintf('.\n');

end

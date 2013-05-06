function [shuffledStims] = et_shuffleStims(stims,valueField,maxConsec)
% function [shuffledStims] = et_shuffleStims(stims,valueField,maxConsec)
%
% Description:
%  Shuffle stimuli until there are no more than X consecutive stimuli of a
%  given type in a row.
%
% Input:
%  stims:      Struct. Stimuli to shuffle. Assumes that the field
%              stims.(valueField) consists of integers.
%  valueField: String. Name of the field on which the order is contingent.
%  maxConsec:  Integer. Maximum number of consecutive stimuli from the same
%              family.
%
% Output:
%  shuffledStims: Stimuli in shuffled order.
%
% NB: Makes 10000 shuffle attempts before erroring.
%

not_good = true;
maxShuffle = 10000;
shuffleCount = 0;
while not_good
  randsel = randperm(length(stims));
  % debug
  %randsel = 1:length(stims);
  %fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  % shuffle the exemplars
  stims = stims(randsel);
  
  stimValues = [stims.(valueField)];
  possibleValues = unique(stimValues);
  consecCount = zeros(1,length(possibleValues));
  
  consecCount(stimValues(1)) = 1;
  
  for i = 2:length(stimValues)
    if stimValues(i) == stimValues(i-1)
      % if we found a repeat, add 1 to the count
      consecCount(stimValues(i)) = consecCount(stimValues(i)) + 1;
      if consecCount(stimValues(i)) > maxConsec
        % if we hit the maximum number, break out
        break
      end
    else
      % if it's not a repeat, reset the count
      consecCount = zeros(1,length(possibleValues));
      consecCount(stimValues(i)) = 1;
    end
  end
  if any(consecCount > maxConsec)
    shuffleCount = shuffleCount + 1;
    fprintf('.');
  else
    not_good = false;
    shuffledStims = stims;
    fprintf('\nSuccessfully shuffled the stimuli contingent on the %s field.\n',valueField);
  end
  
  if shuffleCount == maxShuffle
    error('\nPerformed %d shuffle attempts. That is too many.',maxShuffle);
  end
end % while

end

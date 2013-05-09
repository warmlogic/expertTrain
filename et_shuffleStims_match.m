function [shuffledStims] = et_shuffleStims_match(sameStims,diffStims,stim2MinRepeatSpacing)
% function [shuffledStims] = et_shuffleStims_match(sameStims,diffStims,stim2MinRepeatSpacing)
%
% Description:
%  Take in the same and different stimuli and put them in experiment
%  presentation order
% 
% Input:
%  sameStims:             stim1s and stim2s in the "same" condition
%  diffStims:             stim1s and stim2s in the "diff" condition
%  stim2MinRepeatSpacing: minimum number of trials needed between exact
%                         repeats of a given stimulus as stim2
%
% Output:
%  shuffledStims: all same and diff trials shuffled together
%
% Notes on stim2MinRepeatSpacing:
%
% This is only applicable for the main matching task, not the daily, but we
% can still run it in all cases.
%
% The same simuli in the same and  different condition should not follow
% each other directly. There should be at least 2-3 items in between two
% identical Stim 2.
%
% Allowable sequence: aa2-aa1; ah3-aj2; ag6-ag1; ab1-aa1
% Not allowable:      aa2-aa1; ah3-aj2; ab1-aa1; ag6-ag1

allStims = cat(1,sameStims,diffStims);

not_good = true;
maxShuffle = 1000000;
shuffleCount = 1;
fprintf('Shuffle count: %s',repmat(' ',1,length(num2str(maxShuffle))));
while not_good
  randind = randperm(length(allStims));
  allStims = allStims(randind);
  fprintf(1,[repmat('\b',1,length(num2str(shuffleCount))),'%d'],shuffleCount);
  
  allStims2Ind = find([allStims.matchStimNum] == 2);
  for i = (stim2MinRepeatSpacing+1):length(allStims2Ind)
    foundMatch = false;
    
    for j = 1:stim2MinRepeatSpacing
      % for each previous stim, see if it is an exact match
      
      % This checks each previous stim2. This is right because we will
      % loop over only half of these stimuli, while finding its pair.  That
      % means we only want to check stim2s.
      if (allStims(allStims2Ind(i)).familyNum == allStims(allStims2Ind(i-j)).familyNum) &&...
          (allStims(allStims2Ind(i)).speciesNum == allStims(allStims2Ind(i-j)).speciesNum) &&...
          (allStims(allStims2Ind(i)).exemplarNum == allStims(allStims2Ind(i-j)).exemplarNum)
        
      % % This checks each previous stim. This is not right because we will
      % % loop over only half of these stimuli, while finding its pair.
      % % That means we might be checking some stim1s here.
      % if (allStims(allStims2Ind(i)).familyNum == allStims(allStims2Ind(i) - j).familyNum) &&...
      %     (allStims(allStims2Ind(i)).speciesNum == allStims(allStims2Ind(i) - j).speciesNum) &&...
      %     (allStims(allStims2Ind(i)).exemplarNum == allStims(allStims2Ind(i) - j).exemplarNum)
        
        foundMatch = true;
        % break out of checking the previous stimuli
        break
      end
    end
    
    if foundMatch
      % break out of checking any stimuli in this shuffle
      break
    end
    
  end
  
  if foundMatch
    shuffleCount = shuffleCount + 1;
  else
    not_good = false;
    shuffledStims = allStims;
    fprintf('\nSuccessfully shuffled the stimuli.\n');
  end
  
  if shuffleCount == maxShuffle && not_good
    error('\nPerformed %d shuffle attempts. That is too many.',maxShuffle);
  end
end

end

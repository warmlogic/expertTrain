function [shuffledStims] = et_shuffleStims(stims,maxConsecFamily)
% function [shuffledStims] = et_shuffleStims(stims,maxConsecFamily)
%
% Input:
%  stims:           Struct of stimuli to shuffle. Assumes that the field
%                   stims.familyNum consists of 1s and 2s.
%  maxConsecFamily: Integer. Maximum number of consecutive stimuli from the
%                   same family.
%
% Output:
%  shuffledStims: Stimuli in shuffled order.
%
% NB: Makes 1000 shuffle attempts before erroring.
%

not_good = true;
maxShuffle = 1000;
shuffleCount = 0;
while not_good
  %randsel = randperm(length(stims));
  % debug
  randsel = 1:length(stims);
  fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  % shuffle the exemplars
  stims = stims(randsel);
  
  familyNums = [stims.familyNum];
  if familyNums(1) == 1
    consecCount_f1 = 1;
    consecCount_f2 = 0;
  elseif familyNums(1) == 2
    consecCount_f1 = 0;
    consecCount_f2 = 1;
  end
  
  for i = 2:length(familyNums)
    if familyNums(i) == familyNums(i-1)
      if familyNums(i) == 1
        consecCount_f1 = consecCount_f1 + 1;
        %consecCount_f2_v = 0;
        if consecCount_f1 > maxConsecFamily
          break
        end
      elseif familyNums(i) == 2
        %consecCount_f1_v = 0;
        consecCount_f2 = consecCount_f2 + 1;
        if consecCount_f2 > maxConsecFamily
          break
        end
      end
    else
      if familyNums(i) == 1
        consecCount_f1 = 1;
        consecCount_f2 = 0;
      elseif familyNums(i) == 2
        consecCount_f1 = 0;
        consecCount_f2 = 1;
      end
    end
  end
  if consecCount_f1 <= maxConsecFamily && consecCount_f2 <= maxConsecFamily
    not_good = false;
    shuffledStims = stims;
  else
    shuffleCount = shuffleCount + 1;
  end
  if shuffleCount == maxShuffle
    error('Performed %d shuffle attempts. That is too many.',maxShuffle);
  end
end % while

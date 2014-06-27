function [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount)

% TODO: don't need to store expParam.session.(sesName).match.same and
% expParam.session.(sesName).match.diff because allStims gets created and
% is all we need. Instead, replace them with sameStims and diffStims.

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

if ~isfield(phaseCfg,'familyNames')
  if ~phaseCfg.isExp
    phaseCfg.familyNames = cfg.stim.practice.familyNames;
  else
    phaseCfg.familyNames = cfg.stim.familyNames;
  end
end

if ~isfield(cfg.stim,'orderPairsByDifficulty')
  cfg.stim.orderPairsByDifficulty = false;
end

if ~isfield(cfg.stim,'writePairsToFile')
  if isfield(cfg.stim,'newSpecies')
    cfg.stim.writePairsToFile = true;
  else
    cfg.stim.writePairsToFile = false;
  end
end

% initialize to hold all the same and different stimuli
expParam.session.(sesName).(phaseName)(phaseCount).same = [];
expParam.session.(sesName).(phaseName)(phaseCount).diff = [];

if ~phaseCfg.isExp
  % this is the practice session
  for f = 1:length(cfg.stim.practice.familyNames)
    if ismember(cfg.stim.practice.familyNames{f},phaseCfg.familyNames)
      [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
        expParam.session.(sprintf('f%dPractice',f)),...
        expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
        phaseCfg.nSame,phaseCfg.nDiff,...
        phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst);
    end
  end
  % add in the 'trained' field because we need it for running the task
  for e = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).same)
    expParam.session.(sesName).(phaseName)(phaseCount).same(e).trained = false;
  end
  for e = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).diff)
    expParam.session.(sesName).(phaseName)(phaseCount).diff(e).trained = false;
  end
else
  % this is the real experiment
  for f = 1:length(cfg.stim.familyNames)
    if ismember(cfg.stim.familyNames{f},phaseCfg.familyNames)
      if isfield(cfg.stim,'newSpecies')
        [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
          expParam.session.(sprintf('f%dNew',f))] = et_divvyStims_match(...
          expParam.session.(sprintf('f%dNew',f)),...
          expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
          phaseCfg.nSameNew,phaseCfg.nDiffNew,...
          phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
          %phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,length(cfg.stim.newSpecies) * (phaseCfg.nSameNew+phaseCfg.nDiffNew));
          
          % trained
          [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
            expParam.session.(sprintf('f%dTrained',f))] = et_divvyStims_match(...
            expParam.session.(sprintf('f%dTrained',f)),...
            expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
            phaseCfg.nSame,phaseCfg.nDiff,...
            phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
          
          % untrained
          [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
            expParam.session.(sprintf('f%dUntrained',f))] = et_divvyStims_match(...
            expParam.session.(sprintf('f%dUntrained',f)),...
            expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
            phaseCfg.nSame,phaseCfg.nDiff,...
            phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
      else
        % trained
        [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
          expParam.session.(sprintf('f%dTrained',f)),...
          expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
          phaseCfg.nSame,phaseCfg.nDiff,...
          phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst);
        
        % untrained
        [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
          expParam.session.(sprintf('f%dUntrained',f)),...
          expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
          phaseCfg.nSame,phaseCfg.nDiff,...
          phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst);
      end
    end
  end
end

if isfield(cfg.stim,'newSpecies') && cfg.stim.orderPairsByDifficulty
  % set up for reading difficulty rating files
  cols = struct;
  cols.fam = 1;
  cols.s1 = 2;
  cols.s2 = 3;
  cols.diff = 4;
  
  % can only pair trained with trained, untrained with untrained, and
  % new with new
  
  % Within Spec Pairs
  WithinSpecRateFile = fullfile(cfg.files.stimDir,'WithinSpecRate.txt');
  if exist(WithinSpecRateFile,'file')
    sameSpecRate = load(WithinSpecRateFile);
  else
    error('Within species difficulty rating file does not exist: %s',WithinSpecRateFile);
  end
  if expParam.difficulty == 1 %Difficulty condition 1 goes from easiest to hardest
    [~, ord] = sort(sameSpecRate(:,4),'ascend');
  elseif expParam.difficulty == 2 %goes from hardest to easiest
    [~, ord] = sort(sameSpecRate(:,4),'descend');
  elseif expParam.difficulty == 3 %goes in a totally random order
    ord = randperm(size(sameSpecRate,1));
  end
  sameSpecRate = sameSpecRate(ord,:);
  
  % initialize to reorder pairs
  stimCount = 0;
  stimOrder = zeros(1,length(expParam.session.(sesName).(phaseName)(phaseCount).same));
  
  % go through each species pair
  for sp = 1:size(sameSpecRate,1)
    theseTrials_spec1_ind = find(...
      [expParam.session.(sesName).(phaseName)(phaseCount).same.familyNum] == sameSpecRate(sp,cols.fam) & ...
      [expParam.session.(sesName).(phaseName)(phaseCount).same.speciesNum] == sameSpecRate(sp,cols.s1));
      %[expParam.session.(sesName).(phaseName)(phaseCount).same.matchStimNum] == 1 & ...
    
    theseTrials_spec2_ind = find(...
      [expParam.session.(sesName).(phaseName)(phaseCount).same.familyNum] == sameSpecRate(sp,cols.fam) & ...
      [expParam.session.(sesName).(phaseName)(phaseCount).same.speciesNum] == sameSpecRate(sp,cols.s2));
      %[expParam.session.(sesName).(phaseName)(phaseCount).same.matchStimNum] == 2 & ...
    
    if ~isempty(theseTrials_spec1_ind) && ~isempty(theseTrials_spec2_ind) && length(theseTrials_spec1_ind) == length(theseTrials_spec2_ind)
      theseTrials_spec1 = expParam.session.(sesName).(phaseName)(phaseCount).same(theseTrials_spec1_ind);
      theseTrials_spec2 = expParam.session.(sesName).(phaseName)(phaseCount).same(theseTrials_spec2_ind);
      
      theseTrials_stim1_ind = theseTrials_spec1_ind([theseTrials_spec1.matchStimNum] == 1);
      theseTrials_stim2_ind = theseTrials_spec2_ind([theseTrials_spec2.matchStimNum] == 2);
      
      theseTrials_stim1 = expParam.session.(sesName).(phaseName)(phaseCount).same(theseTrials_stim1_ind);
      theseTrials_stim2 = expParam.session.(sesName).(phaseName)(phaseCount).same(theseTrials_stim2_ind);
      
      for t = 1:length(theseTrials_stim1)
        % find the paired stimulus, with the same training and new status
        this_s2_ind = find([theseTrials_stim2.matchStimNum] ~= theseTrials_stim1(t).matchStimNum & [theseTrials_stim2.matchPairNum] == theseTrials_stim1(t).matchPairNum & [theseTrials_stim2.trained] == theseTrials_stim1(t).trained & [theseTrials_stim2.new] == theseTrials_stim1(t).new);
        
        if length(this_s2_ind) == 1
          % add the difficulty rating
          expParam.session.(sesName).(phaseName)(phaseCount).same(theseTrials_stim1_ind(t)).difficulty = sameSpecRate(sp,cols.diff);
          expParam.session.(sesName).(phaseName)(phaseCount).same(theseTrials_stim2_ind(t)).difficulty = sameSpecRate(sp,cols.diff);
          
          stimCount = stimCount + 1;
          stimOrder(theseTrials_stim1_ind(t)) = stimCount;
          stimCount = stimCount + 1;
          stimOrder(theseTrials_stim2_ind(t)) = stimCount;
        else
          error('Did not find s2');
        end
        
      end
    else
      error('Did not find the same number of stimuli');
    end
  end
  
  % reorder same species stimuli
  [~,i] = sort(stimOrder);
  expParam.session.(sesName).(phaseName)(phaseCount).same = expParam.session.(sesName).(phaseName)(phaseCount).same(i);
  
  % Between Spec Pairs
  BetweenSpecRateFile = fullfile(cfg.files.stimDir,'BetweenSpecRate.txt');
  if exist(BetweenSpecRateFile,'file')
    diffSpecRate = load(BetweenSpecRateFile);
  else
    error('Between species difficulty rating file does not exist: %s',BetweenSpecRateFile);
  end
  if expParam.difficulty == 1 %Difficulty condition 1 goes from easiest to hardest
    [~, ord] = sort(diffSpecRate(:,4),'ascend');
  elseif expParam.difficulty == 2 %goes from hardest to easiest
    [~, ord] = sort(diffSpecRate(:,4),'descend');
  elseif expParam.difficulty == 3 %goes in a totally random order
    ord = randperm(size(diffSpecRate,1));
  end
  diffSpecRate = diffSpecRate(ord,:);
  
  % initialize to reorder pairs
  stimCount = 0;
  stimOrder = zeros(1,length(expParam.session.(sesName).(phaseName)(phaseCount).diff));
  
  % go through each species pair
  for sp = 1:size(diffSpecRate,1)
    % trained/untrained and new species must be paired within that category
    if (~ismember(diffSpecRate(sp,cols.s1),cfg.stim.newSpecies) && ~ismember(diffSpecRate(sp,cols.s2),cfg.stim.newSpecies)) || (ismember(diffSpecRate(sp,cols.s1),cfg.stim.newSpecies) && ismember(diffSpecRate(sp,cols.s2),cfg.stim.newSpecies))
      
      theseTrials_spec1_ind = find(...
        [expParam.session.(sesName).(phaseName)(phaseCount).diff.familyNum] == diffSpecRate(sp,cols.fam) & ...
        [expParam.session.(sesName).(phaseName)(phaseCount).diff.speciesNum] == diffSpecRate(sp,cols.s1));
      %[expParam.session.(sesName).(phaseName)(phaseCount).diff.matchStimNum] == 1 & ...
      
      theseTrials_spec2_ind = find(...
        [expParam.session.(sesName).(phaseName)(phaseCount).diff.familyNum] == diffSpecRate(sp,cols.fam) & ...
        [expParam.session.(sesName).(phaseName)(phaseCount).diff.speciesNum] == diffSpecRate(sp,cols.s2));
      %[expParam.session.(sesName).(phaseName)(phaseCount).diff.matchStimNum] == 2 & ...
      
      if ~isempty(theseTrials_spec1_ind) && ~isempty(theseTrials_spec2_ind) && length(theseTrials_spec1_ind) == length(theseTrials_spec2_ind)
        theseTrials_spec1 = expParam.session.(sesName).(phaseName)(phaseCount).diff(theseTrials_spec1_ind);
        theseTrials_spec2 = expParam.session.(sesName).(phaseName)(phaseCount).diff(theseTrials_spec2_ind);
        
        for t = 1:length(theseTrials_spec1)
          this_spec2_ind = ...
            [theseTrials_spec2.familyNum] == theseTrials_spec1(t).familyNum & ...
            [theseTrials_spec2.matchPairNum] == theseTrials_spec1(t).matchPairNum & ...
            [theseTrials_spec2.matchStimNum] ~= theseTrials_spec1(t).matchStimNum & ...
            [theseTrials_spec2.trained] == theseTrials_spec1(t).trained & ...
            [theseTrials_spec2.new] == theseTrials_spec1(t).new;

          this_spec2 = theseTrials_spec2(this_spec2_ind);
          
          if length(this_spec2) == 1
            % add the difficulty rating
            expParam.session.(sesName).(phaseName)(phaseCount).diff(theseTrials_spec1_ind(t)).difficulty = diffSpecRate(sp,cols.diff);
            expParam.session.(sesName).(phaseName)(phaseCount).diff(theseTrials_spec2_ind(this_spec2_ind)).difficulty = diffSpecRate(sp,cols.diff);
            
            stimCount = stimCount + 1;
            stimOrder(theseTrials_spec2_ind(this_spec2_ind)) = stimCount;
            stimCount = stimCount + 1;
            stimOrder(theseTrials_spec1_ind(t)) = stimCount;
          %else
          %  error('Did not find s2');
          end
        end
      else
        error('Did not find the same number of stimuli');
      end
    end
  end
  
  % reorder diff species stimuli
  [~,i] = sort(stimOrder);
  expParam.session.(sesName).(phaseName)(phaseCount).diff = expParam.session.(sesName).(phaseName)(phaseCount).diff(i);
  
  % shuffle matchStimNum=1 within difficulty level, then concatenate with
  % matchStimNum=2; trained and untrained stimuli, as well as old/new
  % stimuli, were in alternating chunks, so this will purposely mix up
  % training and old/new status within a difficulty level
  shuffledSame = [];
  difficulties = unique([expParam.session.(sesName).(phaseName)(phaseCount).same.difficulty],'stable');
  for i = 1:length(difficulties)
    thisDiffic_s1 = expParam.session.(sesName).(phaseName)(phaseCount).same([expParam.session.(sesName).(phaseName)(phaseCount).same.difficulty] == difficulties(i) & [expParam.session.(sesName).(phaseName)(phaseCount).same.matchStimNum] == 1);
    thisDiffic_s1 = thisDiffic_s1(randperm(length(thisDiffic_s1)));
    
    thisDiffic = [];
    thisDiffic_s2 = expParam.session.(sesName).(phaseName)(phaseCount).same([expParam.session.(sesName).(phaseName)(phaseCount).same.difficulty] == difficulties(i) & [expParam.session.(sesName).(phaseName)(phaseCount).same.matchStimNum] == 2);
    for d = 1:length(thisDiffic_s1)
      thisDiffic = cat(1,thisDiffic,thisDiffic_s1(d));
      s2 = thisDiffic_s2([thisDiffic_s2.familyNum] == thisDiffic_s1(d).familyNum & [thisDiffic_s2.matchPairNum] == thisDiffic_s1(d).matchPairNum & [thisDiffic_s2.new] == thisDiffic_s1(d).new & [thisDiffic_s2.trained] == thisDiffic_s1(d).trained);
      if length(s2) == 1
        thisDiffic = cat(1,thisDiffic,s2);
      else
        fprintf('Found more than 1 s2\n');
        keyboard
      end
    end
    shuffledSame = cat(1,shuffledSame,thisDiffic);
  end
  expParam.session.(sesName).(phaseName)(phaseCount).same = shuffledSame;
  
  shuffledDiff = [];
  difficulties = unique([expParam.session.(sesName).(phaseName)(phaseCount).diff.difficulty],'stable');
  for i = 1:length(difficulties)
    thisDiffic_s1 = expParam.session.(sesName).(phaseName)(phaseCount).diff([expParam.session.(sesName).(phaseName)(phaseCount).diff.difficulty] == difficulties(i) & [expParam.session.(sesName).(phaseName)(phaseCount).diff.matchStimNum] == 1);
    thisDiffic_s1 = thisDiffic_s1(randperm(length(thisDiffic_s1)));
    
    thisDiffic = [];
    thisDiffic_s2 = expParam.session.(sesName).(phaseName)(phaseCount).diff([expParam.session.(sesName).(phaseName)(phaseCount).diff.difficulty] == difficulties(i) & [expParam.session.(sesName).(phaseName)(phaseCount).diff.matchStimNum] == 2);
    for d = 1:length(thisDiffic_s1)
      thisDiffic = cat(1,thisDiffic,thisDiffic_s1(d));
      s2 = thisDiffic_s2([thisDiffic_s2.familyNum] == thisDiffic_s1(d).familyNum & [thisDiffic_s2.matchPairNum] == thisDiffic_s1(d).matchPairNum & [thisDiffic_s2.new] == thisDiffic_s1(d).new & [thisDiffic_s2.trained] == thisDiffic_s1(d).trained);
      if length(s2) == 1
        thisDiffic = cat(1,thisDiffic,s2);
      else
        fprintf('Found more than 1 s2\n');
        keyboard
      end
    end
    shuffledDiff = cat(1,shuffledDiff,thisDiffic);
  end
  expParam.session.(sesName).(phaseName)(phaseCount).diff = shuffledDiff;
  
%   % alternate same/diff stimulus pairs
%   expParam.session.(sesName).(phaseName)(phaseCount).allStims = [];
%   stimCount = 0;
%   for i = 1:2:length(expParam.session.(sesName).(phaseName)(phaseCount).same)
%     stimCount = stimCount + 2;
%     expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).same(stimCount-1));
%     expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).same(stimCount));
%     
%     expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).diff(stimCount-1));
%     expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).diff(stimCount));
%   end
  
  % mix together same/diff stiulus pairs using random permutation;
  % difficulty level increases/decreases within same (and different) trials
  sameDiffOrder = cat(2,ones(1,length(expParam.session.(sesName).(phaseName)(phaseCount).same) / 2),2*ones(1,length(expParam.session.(sesName).(phaseName)(phaseCount).same) / 2));
  sameDiffOrder = sameDiffOrder(randperm(length(sameDiffOrder)));
  expParam.session.(sesName).(phaseName)(phaseCount).allStims = [];
  sameCount = 0;
  diffCount = 0;
  % 1=same, 2=diff, pull stimuli from each pool in the randomized order
  for i = 1:length(sameDiffOrder)
    if sameDiffOrder(i) == 1
      sameCount = sameCount + 2;
      expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).same(sameCount-1));
      expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).same(sameCount));
    elseif sameDiffOrder(i) == 2
      diffCount = diffCount + 2;
      expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).diff(diffCount-1));
      expParam.session.(sesName).(phaseName)(phaseCount).allStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).allStims,expParam.session.(sesName).(phaseName)(phaseCount).diff(diffCount));
    end
  end
  
else
  % shuffle same and diff together for the experiment
  fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,phaseCount);
  [expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
    expParam.session.(sesName).(phaseName)(phaseCount).same,...
    expParam.session.(sesName).(phaseName)(phaseCount).diff,...
    phaseCfg.stim2MinRepeatSpacing);
end

fprintf('Done.\n');

end % function

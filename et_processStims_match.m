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

if ~isfield(phaseCfg,'refillFamiliesIfEmpty')
  phaseCfg.refillFamiliesIfEmpty = false;
end

if ~isfield(phaseCfg,'forceFamilyRefill')
  phaseCfg.forceFamilyRefill = false;
end

if ~isfield(cfg.stim,'orderPairsByDifficulty') || (isfield(cfg.stim,'orderPairsByDifficulty') && isempty(cfg.stim.orderPairsByDifficulty))
  cfg.stim.orderPairsByDifficulty = false;
end

if ~isfield(phaseCfg,'reuseStimsSameDiff') || (isfield(phaseCfg,'reuseStimsSameDiff') && isempty(phaseCfg.reuseStimsSameDiff))
  phaseCfg.reuseStimsSameDiff = false;
end

if ~isfield(cfg.stim,'writePairsToFile') || (isfield(cfg.stim,'writePairsToFile') && isempty(cfg.stim.writePairsToFile))
  if strcmp(expParam.expName,'EBUG_UMA')
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
  if strcmp(expParam.expName,'EBUG_UMA') && isfield(cfg.stim,'newSpecies')
    if isfield(phaseCfg,'nBlocks') && ~isempty(phaseCfg.nBlocks) && phaseCfg.nBlocks > 1
      % initialize to hold all the same and different stimuli
      expParam.session.(sesName).(phaseName)(phaseCount).same = cell(1,phaseCfg.nBlocks);
      expParam.session.(sesName).(phaseName)(phaseCount).diff = cell(1,phaseCfg.nBlocks);
      
      for f = 1:length(cfg.stim.familyNames)
        if ismember(cfg.stim.familyNames{f},phaseCfg.familyNames)
          
%           thisFamilyNew = expParam.session.(sprintf('f%dNew',f));
%           thisFamilyTrained = expParam.session.(sprintf('f%dTrained',f));
%           thisFamilyUntrained = expParam.session.(sprintf('f%dUntrained',f));
          
          for b = 1:phaseCfg.nBlocks
            if (cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill) || (cfg.stim.refillFamiliesIfEmpty && phaseCfg.refillFamiliesIfEmpty)
              if (cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill) || (cfg.stim.refillFamiliesIfEmpty && phaseCfg.refillFamiliesIfEmpty)
                if isempty(expParam.session.(sprintf('f%dNew',f)))
                  fprintf('\t\tRan out of %s stimuli! Refilling...\n',sprintf('f%dNew',f));
                  expParam.session.(sprintf('f%dNew',f)) = expParam.session.(sprintf('f%dNew_orig',f));
                elseif cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill
                  fprintf('\t\tForcing reset of %s stimuli!\n',sprintf('f%dNew',f));
                  expParam.session.(sprintf('f%dNew',f)) = expParam.session.(sprintf('f%dNew_orig',f));
                end
                if isempty(expParam.session.(sprintf('f%dTrained',f)))
                  fprintf('\t\tRan out of %s stimuli! Refilling...\n',sprintf('f%dTrained',f));
                  expParam.session.(sprintf('f%dTrained',f)) = expParam.session.(sprintf('f%dTrained_orig',f));
                elseif cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill
                  fprintf('\t\tForcing reset of %s stimuli!\n',sprintf('f%dTrained',f));
                  expParam.session.(sprintf('f%dTrained',f)) = expParam.session.(sprintf('f%dTrained_orig',f));
                end
                if isempty(expParam.session.(sprintf('f%dUntrained',f)))
                  fprintf('\t\tRan out of %s stimuli! Refilling...\n',sprintf('f%dUntrained',f));
                  expParam.session.(sprintf('f%dUntrained',f)) = expParam.session.(sprintf('f%dUntrained_orig',f));
                elseif cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill
                  fprintf('\t\tForcing reset of %s stimuli!\n',sprintf('f%dUntrained',f));
                  expParam.session.(sprintf('f%dUntrained',f)) = expParam.session.(sprintf('f%dUntrained_orig',f));
                end
              end
            end
            
            [expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
              expParam.session.(sprintf('f%dNew',f))] = et_divvyStims_match(...
              expParam.session.(sprintf('f%dNew',f)),...
              expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
              phaseCfg.nSameNew,phaseCfg.nDiffNew,...
              phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
            %phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,length(cfg.stim.newSpecies) * (phaseCfg.nSameNew+phaseCfg.nDiffNew));
            
            % trained
            [expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
              expParam.session.(sprintf('f%dTrained',f))] = et_divvyStims_match(...
              expParam.session.(sprintf('f%dTrained',f)),...
              expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
              phaseCfg.nSame,phaseCfg.nDiff,...
              phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
            
            % untrained
            [expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
              expParam.session.(sprintf('f%dUntrained',f))] = et_divvyStims_match(...
              expParam.session.(sprintf('f%dUntrained',f)),...
              expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
              phaseCfg.nSame,phaseCfg.nDiff,...
              phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
            
%             [expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
%               thisFamilyNew] = et_divvyStims_match(...
%               thisFamilyNew,...
%               expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
%               phaseCfg.nSameNew,phaseCfg.nDiffNew,...
%               phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
%             %phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,length(cfg.stim.newSpecies) * (phaseCfg.nSameNew+phaseCfg.nDiffNew));
%             
%             % trained
%             [expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
%               thisFamilyTrained] = et_divvyStims_match(...
%               thisFamilyTrained,...
%               expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
%               phaseCfg.nSame,phaseCfg.nDiff,...
%               phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
%             
%             % untrained
%             [expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
%               thisFamilyUntrained] = et_divvyStims_match(...
%               thisFamilyUntrained,...
%               expParam.session.(sesName).(phaseName)(phaseCount).same{b},expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
%               phaseCfg.nSame,phaseCfg.nDiff,...
%               phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,[],phaseCfg.reuseStimsSameDiff);
            
            for i = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).same{b})
              expParam.session.(sesName).(phaseName)(phaseCount).same{b}(i).block = b;
            end
            for i = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).diff{b})
              expParam.session.(sesName).(phaseName)(phaseCount).diff{b}(i).block = b;
            end
          end
          
        end
      end
    else
      % no blocks
      for f = 1:length(cfg.stim.familyNames)
        if ismember(cfg.stim.familyNames{f},phaseCfg.familyNames)
          if (cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill) || (cfg.stim.refillFamiliesIfEmpty && phaseCfg.refillFamiliesIfEmpty)
            if isempty(expParam.session.(sprintf('f%dNew',f)))
              fprintf('\t\tRan out of %s stimuli! Refilling...\n',sprintf('f%dNew',f));
              expParam.session.(sprintf('f%dNew',f)) = expParam.session.(sprintf('f%dNew_orig',f));
            elseif cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill
              fprintf('\t\tForcing reset of %s stimuli!\n',sprintf('f%dNew',f));
              expParam.session.(sprintf('f%dNew',f)) = expParam.session.(sprintf('f%dNew_orig',f));
            end
            if isempty(expParam.session.(sprintf('f%dTrained',f)))
              fprintf('\t\tRan out of %s stimuli! Refilling...\n',sprintf('f%dTrained',f));
              expParam.session.(sprintf('f%dTrained',f)) = expParam.session.(sprintf('f%dTrained_orig',f));
            elseif cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill
              fprintf('\t\tForcing reset of %s stimuli!\n',sprintf('f%dTrained',f));
              expParam.session.(sprintf('f%dTrained',f)) = expParam.session.(sprintf('f%dTrained_orig',f));
            end
            if isempty(expParam.session.(sprintf('f%dUntrained',f)))
              fprintf('\t\tRan out of %s stimuli! Refilling...\n',sprintf('f%dUntrained',f));
              expParam.session.(sprintf('f%dUntrained',f)) = expParam.session.(sprintf('f%dUntrained_orig',f));
            elseif cfg.stim.forceFamilyRefill && phaseCfg.forceFamilyRefill
              fprintf('\t\tForcing reset of %s stimuli!\n',sprintf('f%dUntrained',f));
              expParam.session.(sprintf('f%dUntrained',f)) = expParam.session.(sprintf('f%dUntrained_orig',f));
            end
          end
          
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
        end
      end
    end
  else
    for f = 1:length(cfg.stim.familyNames)
      if ismember(cfg.stim.familyNames{f},phaseCfg.familyNames)
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

if phaseCfg.isExp && strcmp(expParam.expName,'EBUG_UMA') && isfield(cfg.stim,'newSpecies')
  % species number and species strings must match up (a=1, b=2, c=3, etc.)
  
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
  
  % Between Spec Pairs
  BetweenSpecRateFile = fullfile(cfg.files.stimDir,'BetweenSpecRate.txt');
  if exist(BetweenSpecRateFile,'file')
    diffSpecRate = load(BetweenSpecRateFile);
  else
    error('Between species difficulty rating file does not exist: %s',BetweenSpecRateFile);
  end
  
  if cfg.stim.orderPairsByDifficulty
    if expParam.difficulty == 1 %Difficulty condition 1 goes from easiest to hardest
      [~, ord] = sort(sameSpecRate(:,4),'ascend');
    elseif expParam.difficulty == 2 %goes from hardest to easiest
      [~, ord] = sort(sameSpecRate(:,4),'descend');
    elseif expParam.difficulty == 3 %goes in a totally random order
      ord = randperm(size(sameSpecRate,1));
    end
    sameSpecRate = sameSpecRate(ord,:);
    
    if expParam.difficulty == 1 %Difficulty condition 1 goes from easiest to hardest
      [~, ord] = sort(diffSpecRate(:,4),'ascend');
    elseif expParam.difficulty == 2 %goes from hardest to easiest
      [~, ord] = sort(diffSpecRate(:,4),'descend');
    elseif expParam.difficulty == 3 %goes in a totally random order
      ord = randperm(size(diffSpecRate,1));
    end
    diffSpecRate = diffSpecRate(ord,:);
    
    % =============================
    % Within
    % =============================
    
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
    
    % =============================
    % Between
    % =============================
    
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
    if isfield(phaseCfg,'nBlocks') && ~isempty(phaseCfg.nBlocks) && phaseCfg.nBlocks > 1
      expParam.session.(sesName).(phaseName)(phaseCount).allStims = cell(1,phaseCfg.nBlocks);
      
      for b = 1:phaseCfg.nBlocks
        % add the difficulty rating
        
        % within (same species)
        blockSameStims = expParam.session.(sesName).(phaseName)(phaseCount).same{b};
        stim2ind = find([blockSameStims.matchStimNum] == 2);
        withinDifficulty = sameSpecRate(:,cols.diff);
        for i = 1:length(stim2ind)
          stim1ind = find(...
            ([blockSameStims.familyNum] == blockSameStims(stim2ind(i)).familyNum) &...
            ([blockSameStims.speciesNum] == blockSameStims(stim2ind(i)).speciesNum) &...
            ([blockSameStims.trained] == blockSameStims(stim2ind(i)).trained) &...
            ([blockSameStims.new] == blockSameStims(stim2ind(i)).new) &...
            ([blockSameStims.matchPairNum] == blockSameStims(stim2ind(i)).matchPairNum) &...
            ([blockSameStims.matchStimNum] ~= blockSameStims(stim2ind(i)).matchStimNum));
          
          if length(stim1ind) == 1
            thisDifficulty = withinDifficulty(sameSpecRate(:,cols.fam) == blockSameStims(stim2ind(i)).familyNum & ((sameSpecRate(:,cols.s2) == blockSameStims(stim2ind(i)).speciesNum & sameSpecRate(:,cols.s1) == blockSameStims(stim1ind).speciesNum) | (sameSpecRate(:,cols.s1) == blockSameStims(stim2ind(i)).speciesNum & sameSpecRate(:,cols.s2) == blockSameStims(stim1ind).speciesNum)));
            if length(thisDifficulty) == 1
              expParam.session.(sesName).(phaseName)(phaseCount).same{b}(stim2ind(i)).difficulty = thisDifficulty;
              expParam.session.(sesName).(phaseName)(phaseCount).same{b}(stim1ind).difficulty = thisDifficulty;
            else
              keyboard
            end
          else
            keyboard
          end
        end
        
        % between (different species)
        blockDiffStims = expParam.session.(sesName).(phaseName)(phaseCount).diff{b};
        stim2ind = find([blockDiffStims.matchStimNum] == 2);
        betweenDifficulty = diffSpecRate(:,cols.diff);
        for i = 1:length(stim2ind)
          stim1ind = find(...
            ([blockDiffStims.familyNum] == blockDiffStims(stim2ind(i)).familyNum) &...
            ([blockDiffStims.speciesNum] ~= blockDiffStims(stim2ind(i)).speciesNum) &...
            ([blockDiffStims.trained] == blockDiffStims(stim2ind(i)).trained) &...
            ([blockDiffStims.new] == blockDiffStims(stim2ind(i)).new) &...
            ([blockDiffStims.matchPairNum] == blockDiffStims(stim2ind(i)).matchPairNum) &...
            ([blockDiffStims.matchStimNum] ~= blockDiffStims(stim2ind(i)).matchStimNum));
          
          if length(stim1ind) == 1
            thisDifficulty = betweenDifficulty(diffSpecRate(:,cols.fam) == blockDiffStims(stim2ind(i)).familyNum & ((diffSpecRate(:,cols.s2) == blockDiffStims(stim2ind(i)).speciesNum & diffSpecRate(:,cols.s1) == blockDiffStims(stim1ind).speciesNum) | (diffSpecRate(:,cols.s1) == blockDiffStims(stim2ind(i)).speciesNum & diffSpecRate(:,cols.s2) == blockDiffStims(stim1ind).speciesNum)));
            if length(thisDifficulty) == 1
              expParam.session.(sesName).(phaseName)(phaseCount).diff{b}(stim2ind(i)).difficulty = thisDifficulty;
              expParam.session.(sesName).(phaseName)(phaseCount).diff{b}(stim1ind).difficulty = thisDifficulty;
            else
              keyboard
            end
          else
            keyboard
          end
        end
        
        fprintf('Shuffling %s matching (%d) block %d task stimuli.\n',sesName,phaseCount,b);
        [expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_shuffleStims_match(...
          expParam.session.(sesName).(phaseName)(phaseCount).same{b},...
          expParam.session.(sesName).(phaseName)(phaseCount).diff{b},...
          phaseCfg.stim2MinRepeatSpacing);
      end
    else
      
      % within (same species)
      sameStims = expParam.session.(sesName).(phaseName)(phaseCount).same;
      stim2ind = find([sameStims.matchStimNum] == 2);
      withinDifficulty = sameSpecRate(:,cols.diff);
      for i = 1:length(stim2ind)
        stim1ind = find(...
          ([sameStims.familyNum] == sameStims(stim2ind(i)).familyNum) &...
          ([sameStims.speciesNum] == sameStims(stim2ind(i)).speciesNum) &...
          ([sameStims.trained] == sameStims(stim2ind(i)).trained) &...
          ([sameStims.new] == sameStims(stim2ind(i)).new) &...
          ([sameStims.matchPairNum] == sameStims(stim2ind(i)).matchPairNum) &...
          ([sameStims.matchStimNum] ~= sameStims(stim2ind(i)).matchStimNum));
        
        if length(stim1ind) == 1
          thisDifficulty = withinDifficulty(sameSpecRate(:,cols.fam) == sameStims(stim2ind(i)).familyNum & ((sameSpecRate(:,cols.s2) == sameStims(stim2ind(i)).speciesNum & sameSpecRate(:,cols.s1) == sameStims(stim1ind).speciesNum) | (sameSpecRate(:,cols.s1) == sameStims(stim2ind(i)).speciesNum & sameSpecRate(:,cols.s2) == sameStims(stim1ind).speciesNum)));
          if length(thisDifficulty) == 1
            expParam.session.(sesName).(phaseName)(phaseCount).same(stim2ind(i)).difficulty = thisDifficulty;
            expParam.session.(sesName).(phaseName)(phaseCount).same(stim1ind).difficulty = thisDifficulty;
          else
            keyboard
          end
        else
          keyboard
        end
      end
      
      % between (different species)
      diffStims = expParam.session.(sesName).(phaseName)(phaseCount).diff;
      stim2ind = find([diffStims.matchStimNum] == 2);
      betweenDifficulty = diffSpecRate(:,cols.diff);
      for i = 1:length(stim2ind)
        stim1ind = find(...
          ([diffStims.familyNum] == diffStims(stim2ind(i)).familyNum) &...
          ([diffStims.speciesNum] ~= diffStims(stim2ind(i)).speciesNum) &...
          ([diffStims.trained] == diffStims(stim2ind(i)).trained) &...
          ([diffStims.new] == diffStims(stim2ind(i)).new) &...
          ([diffStims.matchPairNum] == diffStims(stim2ind(i)).matchPairNum) &...
          ([diffStims.matchStimNum] ~= diffStims(stim2ind(i)).matchStimNum));
        
        if length(stim1ind) == 1
          thisDifficulty = betweenDifficulty(diffSpecRate(:,cols.fam) == diffStims(stim2ind(i)).familyNum & ((diffSpecRate(:,cols.s2) == diffStims(stim2ind(i)).speciesNum & diffSpecRate(:,cols.s1) == diffStims(stim1ind).speciesNum) | (diffSpecRate(:,cols.s1) == diffStims(stim2ind(i)).speciesNum & diffSpecRate(:,cols.s2) == diffStims(stim1ind).speciesNum)));
          if length(thisDifficulty) == 1
            expParam.session.(sesName).(phaseName)(phaseCount).diff(stim2ind(i)).difficulty = thisDifficulty;
            expParam.session.(sesName).(phaseName)(phaseCount).diff(stim1ind).difficulty = thisDifficulty;
          else
            keyboard
          end
        else
          keyboard
        end
      end
      
      % shuffle same and diff together for the experiment
      fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,phaseCount);
      [expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
        expParam.session.(sesName).(phaseName)(phaseCount).same,...
        expParam.session.(sesName).(phaseName)(phaseCount).diff,...
        phaseCfg.stim2MinRepeatSpacing);
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

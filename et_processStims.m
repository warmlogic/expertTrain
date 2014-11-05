function [cfg,expParam] = et_processStims(cfg,expParam)
% function [cfg,expParam] = et_processStims(cfg,expParam)
%
% Description:
%  Prepares the stimuli, mostly in experiment presentation order. This
%  function is run by any config_EXPNAME file.
%
% see also: config_EBUG, config_EBIRD, config_COMP, et_divvyStims,
%           et_divvyStims_match, et_shuffleStims, et_shuffleStims_match,
%           et_processStims_match, et_processStims_recog,
%           et_processStims_viewname, et_processStims_nametrain,
%           et_processStims_name, et_processStims_compare

%% Initial processing of the stimuli

% read in the stimulus list
fprintf('Loading stimulus list: %s...',cfg.stim.stimListFile);
fid = fopen(cfg.stim.stimListFile);
% the header line becomes the fieldnames
stim_fieldnames = regexp(fgetl(fid),'\t','split');
stimuli = textscan(fid,'%s%s%d%s%d%d%d%d','Delimiter','\t');
fclose(fid);
fprintf('Done.\n');

% find which field is familyNum (normally is field 3)
familyNumFieldNum = find(ismember(stim_fieldnames,'familyNum'));
% find which field is speciesNum (normally is field 5)
speciesNumFieldNum = find(ismember(stim_fieldnames,'speciesNum'));

% stimuli needed per family for all phases except recognition
phaseFamilyStimNeeded = cfg.stim.nSpecies * (cfg.stim.nTrained + cfg.stim.nUntrained);

% refillFamiliesIfEmpty is a hack for EBUG_UMA used in setting up its
% external eye tracking match phases and is intended for use when
% rmStims_orig=true. It stores the original families in a new field that
% doesn't get depleted, and if et_processStims_match detects an empty
% family field, it will fill it back up with the field of the original
% family. It does not work for practice.
if ~isfield(cfg.stim,'refillFamiliesIfEmpty')
  cfg.stim.refillFamiliesIfEmpty = false;
end
% forceFamilyRefill is a hack to allow the pre and post-test EEG sessions
% to get a refilled family set
if ~isfield(cfg.stim,'forceFamilyRefill')
  cfg.stim.forceFamilyRefill = false;
end

% are we doing a recognition phase?
nRecogBlocks = 0;
for s = 1:expParam.nSessions
  sesName = expParam.sesTypes{s};
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  recogCount = 0;
  
  % for each phase in this session, see if any are recognition phases
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case {'recog'}
        recogCount = recogCount + 1;
        nRecogBlocks = nRecogBlocks + cfg.stim.(sesName).(phaseName)(recogCount).nBlocks;
    end
  end
end

% figure out which species numbers to use in recognition
if nRecogBlocks > 0
  if ~isfield(cfg.stim,'nSpecies_recog')
    cfg.stim.nSpecies_recog = cfg.stim.nSpecies;
  end
  if ~isfield(cfg.stim,'yokeSpecies_recog')
    cfg.stim.yokeSpecies_recog = true;
  end
  
  if cfg.stim.nSpecies_recog < cfg.stim.nSpecies && mod(nRecogBlocks,2) ~= 0
    error('Hack alert: currently need to have even number of blocks for proper recognition setup.');
  end
  
  % initialize to store species per block
  cfg.stim.speciesNums_recog = [];
  
  for nr = 2:2:nRecogBlocks
    if cfg.stim.yokeSpecies_recog
      if length(cfg.stim.nSpecies_recog) == 1
        if cfg.stim.nSpecies_recog < cfg.stim.nSpecies
          randSpecies = randperm(cfg.stim.nSpecies);
          theseSpecNums_recog = sort(randSpecies(1:cfg.stim.nSpecies_recog));
          randSpecies2 = randSpecies(~ismember(randSpecies,theseSpecNums_recog));
          prevSpecNums_recog = sort(randSpecies2(1:cfg.stim.nSpecies_recog));
        elseif cfg.stim.nSpecies_recog == cfg.stim.nSpecies
          theseSpecNums_recog = 1:cfg.stim.nSpecies_recog;
          prevSpecNums_recog = theseSpecNums_recog;
        elseif cfg.stim.nSpecies_recog > cfg.stim.nSpecies
          error('More species specified for recognition (%d) than exist in the stimulus set (%d).',cfg.stim.nSpecies_recog,cfg.stim.nSpecies);
        end
        
        if length(cfg.stim.familyNames) > 1
          for f = 2:length(cfg.stim.familyNames)
            prevSpecNums_recog = cat(1,prevSpecNums_recog,prevSpecNums_recog);
            theseSpecNums_recog = cat(1,theseSpecNums_recog,theseSpecNums_recog);
          end
        end
        specNums_recog = cat(1,prevSpecNums_recog,theseSpecNums_recog);
        
      elseif size(cfg.stim.nSpecies_recog,2) > 1
        specNums_recog = cfg.stim.nSpecies_recog;
        % reset the nSpecies for recognition so we can use it to calculate
        % stimulus counts
        cfg.stim.nSpecies_recog = size(cfg.stim.nSpecies_recog,2);
      end
      cfg.stim.speciesNums_recog = cat(1,cfg.stim.speciesNums_recog,specNums_recog);
    else
      if length(cfg.stim.nSpecies_recog) == 1
        if cfg.stim.nSpecies_recog > cfg.stim.nSpecies
          error('More species specified for recognition (%d) than exist in the stimulus set (%d).',cfg.stim.nSpecies_recog,cfg.stim.nSpecies);
        else
          theseSpecNums_recog = nan(length(cfg.stim.familyNames),cfg.stim.nSpecies_recog);
          prevSpecNums_recog = nan(length(cfg.stim.familyNames),cfg.stim.nSpecies_recog);
          for f = 1:length(cfg.stim.familyNames)
            if cfg.stim.nSpecies_recog < cfg.stim.nSpecies
              randSpecies = randperm(cfg.stim.nSpecies);
              theseSpecNums_recog(f,:) = sort(randSpecies(1:cfg.stim.nSpecies_recog));
              randSpecies2 = randSpecies(~ismember(randSpecies,theseSpecNums_recog(f,:)));
              prevSpecNums_recog(f,:) = sort(randSpecies2(1:cfg.stim.nSpecies_recog));
            elseif cfg.stim.nSpecies_recog == cfg.stim.nSpecies
              theseSpecNums_recog(f,:) = 1:cfg.stim.nSpecies_recog;
              prevSpecNums_recog(f,:) = theseSpecNums_recog(f,:);
            end
          end
          specNums_recog = cat(1,prevSpecNums_recog,theseSpecNums_recog);
        end
      elseif length(cfg.stim.nSpecies_recog) > 1
        if size(cfg.stim.nSpecies_recog,1) > 1 && size(cfg.stim.nSpecies_recog,1) == length(cfg.stim.familyNames)
          specNums_recog = cfg.stim.nSpecies_recog;
        else
          error('If predefining recognition species choices per family, need to specify one row for each family');
        end
        % reset the nSpecies for recognition so we can use it to calculate
        % stimulus counts
        cfg.stim.nSpecies_recog = length(cfg.stim.nSpecies_recog);
      end
      cfg.stim.speciesNums_recog = cat(1,cfg.stim.speciesNums_recog,specNums_recog);
    end
  end % for
end

% determine the number of independent recognition phases
independentRecogCount = 0;
recogFamilyStimNeeded = 0;
for s = 1:expParam.nSessions
  sesName = expParam.sesTypes{s};
  recogCount = 0;
  % for each phase in this session, see if any are recognition phases
  for p = 1:length(expParam.session.(sesName).phases)
    phaseName = expParam.session.(sesName).phases{p};
    switch phaseName
      case {'recog'}
        recogCount = recogCount + 1;
        if ~isfield(cfg.stim.(sesName).(phaseName)(recogCount),'usePrevPhase') || isempty(cfg.stim.(sesName).(phaseName)(recogCount).usePrevPhase)
          independentRecogCount = independentRecogCount + 1;
          recogFamilyStimNeeded = recogFamilyStimNeeded + (cfg.stim.nSpecies_recog * (cfg.stim.(sesName).(phaseName)(recogCount).nStudyTarg + cfg.stim.(sesName).(phaseName)(recogCount).nTestLure));
        end
    end
  end
end
% stimuli needed per family for recognition phases
recogFamilyStimNeeded = recogFamilyStimNeeded * independentRecogCount;

% create a structure for each family with all the stim information

% find the indices for each family and select only cfg.stim.nSpecies
fprintf('Experiment: Selecting %d of %d possible species for each family.\n',cfg.stim.nSpecies,length(unique(stimuli{speciesNumFieldNum})));

% initialize to store the stimuli
stimStruct = struct();

% get the indices of each family and only the number of species wanted
for f = 1:length(cfg.stim.familyNames)
  fInd = eval([sprintf('stimuli{%d} == %d & (stimuli{%d} == %d',familyNumFieldNum,f,speciesNumFieldNum,1),...
    sprintf(repmat([' | ',sprintf('stimuli{%d}',speciesNumFieldNum),' == %d'],1,(cfg.stim.nSpecies - 1)),2:cfg.stim.nSpecies), ')']);
  stimStruct(f).fStims = struct(...
    stim_fieldnames{1},stimuli{1}(fInd),...
    stim_fieldnames{2},stimuli{2}(fInd),...
    stim_fieldnames{3},num2cell(stimuli{3}(fInd)),...
    stim_fieldnames{4},stimuli{4}(fInd),...
    stim_fieldnames{5},num2cell(stimuli{5}(fInd)),...
    stim_fieldnames{6},num2cell(stimuli{6}(fInd)),...
    stim_fieldnames{7},num2cell(stimuli{7}(fInd)),...
    stim_fieldnames{8},num2cell(stimuli{8}(fInd)));
  
  if length(stimStruct(f).fStims) < (phaseFamilyStimNeeded + recogFamilyStimNeeded)
    error('You have chosen %d stimuli for family %s (out of %d). This is not enough stimuli to accommodate all non-practice tasks.\nYou need at least %d for each of %d families (i.e., %d exemplars for each of %d species per family).',...
      length(stimStruct(f).fStims),cfg.stim.familyNames{f},sum(cfg.stim.nExemplars(f,:)),(phaseFamilyStimNeeded + recogFamilyStimNeeded),length(cfg.stim.familyNames),((phaseFamilyStimNeeded + recogFamilyStimNeeded) / cfg.stim.nSpecies),cfg.stim.nSpecies);
  end
end

%% Decide which will be the trained and untrained stimuli from each family

% Currently, when using cfg.stim.yokeTrainedExemplars, the
% cfg.stim.yokeExemplars_train vector simply looks for non-continuities in
% family numbers. e.g., [1 1 1 1 1 2 2 2 2 2] would yield two sets of
% families, with the same exemplar numbers being chosen for
% trained/untrained when the numbers are the same. However, something like
% [1 1 2 2 1 1 2 2 1 2] will not produce what you expect (i.e., two
% groupings of families); instead, it will produce six groupings.
%
% TODO: make cfg.stim.yokeExemplars_train more flexible, allowing
% non-contiguous groupings. For now, you need to just sort the family names
% in cfg.stim.familyNames properly.

if ~isfield(cfg.stim,'yokeTrainedExemplars')
  cfg.stim.yokeTrainedExemplars = false;
end

if ~cfg.stim.yokeTrainedExemplars
  cfg.stim.yokeExemplars_train = 1:length(cfg.stim.familyNames);
end

for f = 1:length(cfg.stim.familyNames)
  % initialize to store trained/untrained exemplar numbers (only used it
  % cfg.stim.yokeTrainedExemplars == true)
  if f == 1 || cfg.stim.yokeExemplars_train(f) ~= cfg.stim.yokeExemplars_train(f-1)
    exemplarNums_trained = [];
    exemplarNums_untrained = [];
  end
  
  % choose the new stimuli (not presented during trainig) before dividing
  % up trained and untrained species
  if isfield(cfg.stim,'newSpecies')
    expParam.session.(sprintf('f%dNew',f)) = [];
    [expParam.session.(sprintf('f%dNew',f)),stimStruct(f).fStims] = et_divvyStims(...
      stimStruct(f).fStims,[],cfg.stim.nNewExemplars,...
      cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice', 'trained', 'new'},{false, false, true},[],cfg.stim.newSpecies);
  end
  
  % choose the trained stimuli for this family
  expParam.session.(sprintf('f%dTrained',f)) = [];
  [expParam.session.(sprintf('f%dTrained',f)),stimStruct(f).fStims] = et_divvyStims(...
    stimStruct(f).fStims,[],cfg.stim.nTrained,...
    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice', 'trained', 'new'},{false, true, false},[],[],exemplarNums_trained);
  
  % choose the untrained stimuli for this family
  expParam.session.(sprintf('f%dUntrained',f)) = [];
  [expParam.session.(sprintf('f%dUntrained',f)),stimStruct(f).fStims] = et_divvyStims(...
    stimStruct(f).fStims,[],cfg.stim.nUntrained,...
    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice', 'trained', 'new'},{false, false, false},[],[],exemplarNums_untrained);
  
  % refill hacks
  if cfg.stim.forceFamilyRefill || cfg.stim.refillFamiliesIfEmpty
    if isfield(cfg.stim,'newSpecies')
      expParam.session.(sprintf('f%dNew_orig',f)) = expParam.session.(sprintf('f%dNew',f));
    end
    expParam.session.(sprintf('f%dTrained_orig',f)) = expParam.session.(sprintf('f%dTrained',f));
    expParam.session.(sprintf('f%dUntrained_orig',f)) = expParam.session.(sprintf('f%dUntrained',f));
  end
  
  if cfg.stim.yokeTrainedExemplars
    if f == 1 || cfg.stim.yokeExemplars_train(f) ~= cfg.stim.yokeExemplars_train(f-1)
      % only select the species that aren't in newSpecies; this only
      % matters for some experiments like EBUG_UMA
      if isfield(cfg.stim,'newSpecies')
        speciesNums = setdiff(1:cfg.stim.nSpecies,cfg.stim.newSpecies);
      else
        speciesNums = 1:cfg.stim.nSpecies;
      end
      
      % set up a matrix of one row per species in the first family denoting
      % the exemplar numbers
      exemplarNums_trained = nan(length(speciesNums),cfg.stim.nTrained);
      exemplarNums_untrained = nan(length(speciesNums),cfg.stim.nUntrained);
      
      % if this is the first family, or we need a new grouping, get the
      % species numbers that were chosen so we can apply them to the other
      % families in this grouping
      
      for s = 1:length(speciesNums)
        theseTrained = expParam.session.(sprintf('f%dTrained',f))([expParam.session.(sprintf('f%dTrained',f)).speciesNum] == speciesNums(s));
        theseUntrained = expParam.session.(sprintf('f%dUntrained',f))([expParam.session.(sprintf('f%dUntrained',f)).speciesNum] == speciesNums(s));
        
        exemplarNums_trained(s,:) = unique([theseTrained.exemplarNum]);
        exemplarNums_untrained(s,:) = unique([theseUntrained.exemplarNum]);
      end
    end
    
  end
end

%% if there are recognition phases, get those stimuli

% count how many times we use a recognition block
recogBlockInd = 0;
for s = 1:expParam.nSessions
  sesName = expParam.sesTypes{s};
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  recogCount = 0;
  
  % for each phase in this session, see if any are recognition phases
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case {'recog'}
        recogCount = recogCount + 1;
        
        if ~isfield(cfg.stim.(sesName).(phaseName)(recogCount),'familyNames')
          cfg.stim.(sesName).(phaseName)(recogCount).familyNames = cfg.stim.familyNames;
        end
        
        if ~isfield(cfg.stim.(sesName).(phaseName)(recogCount),'usePrevPhase') || isempty(cfg.stim.(sesName).(phaseName)(recogCount).usePrevPhase)
          expParam.session.(sesName).(phaseName)(recogCount).allStims = cell(1,cfg.stim.(sesName).(phaseName)(recogCount).nBlocks);
          for b = 1:cfg.stim.(sesName).(phaseName)(recogCount).nBlocks
            fprintf('Recognition, session %d (%s), block %d:\n',s,sesName,b);
            
            for f = 1:length(cfg.stim.familyNames)
              if ismember(cfg.stim.familyNames{f},cfg.stim.(sesName).(phaseName)(recogCount).familyNames)
                % set the right index for these species numbers
                recogBlockInd = recogBlockInd + 1;
                % get the stimuli for this block
                [expParam.session.(sesName).(phaseName)(recogCount).allStims{b},stimStruct(f).fStims] = et_divvyStims(...
                  stimStruct(f).fStims,expParam.session.(sesName).(phaseName)(recogCount).allStims{b},...
                  cfg.stim.(sesName).(phaseName)(recogCount).nStudyTarg + cfg.stim.(sesName).(phaseName)(recogCount).nTestLure,...
                  cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{false},[],cfg.stim.speciesNums_recog(recogBlockInd,:));
              end
            end
          end
        end
    end
  end
end

%% read the practice stimulus file, or grab stimuli from the main families for practice

if expParam.runPractice
  prac_phaseFamilyStimNeeded = cfg.stim.practice.nSpecies * cfg.stim.practice.nPractice;
  prac_independentRecogCount = 0;
  prac_recogFamilyStimNeeded = 0;
  % determine the number of independent practice recognition phases
  for s = 1:expParam.nSessions
    sesName = expParam.sesTypes{s};
    prac_recogCount = 0;
    % for each phase in this session, see if any are recognition phases
    for p = 1:length(expParam.session.(sesName).phases)
      phaseName = expParam.session.(sesName).phases{p};
      switch phaseName
        case {'prac_recog'}
          prac_recogCount = prac_recogCount + 1;
          if ~isfield(cfg.stim.(sesName).(phaseName)(prac_recogCount),'usePrevPhase') || isempty(cfg.stim.(sesName).(phaseName)(prac_recogCount).usePrevPhase)
            prac_independentRecogCount = prac_independentRecogCount + 1;
            prac_recogFamilyStimNeeded = prac_recogFamilyStimNeeded + (cfg.stim.practice.nSpecies * (cfg.stim.(sesName).(phaseName)(prac_recogCount).nStudyTarg + cfg.stim.(sesName).(phaseName)(prac_recogCount).nTestLure));
          end
      end
    end
  end
  prac_recogFamilyStimNeeded = prac_recogFamilyStimNeeded * prac_independentRecogCount;
  
  if cfg.stim.useSeparatePracStims
    % read in the stimulus list
    fprintf('Loading stimulus list: %s...',cfg.stim.practice.stimListFile);
    fid = fopen(cfg.stim.practice.stimListFile);
    % the header line becomes the fieldnames
    stim_fieldnames = regexp(fgetl(fid),'\t','split');
    stimuli = textscan(fid,'%s%s%d%s%d%d%d%d','Delimiter','\t');
    fclose(fid);
    fprintf('Done.\n');
    
    % create a structure for each family with all the stim information
    
    % find the indices for each family and select only cfg.stim.practice.nSpecies
    fprintf('Practice: Selecting %d of %d possible species for each family.\n',cfg.stim.practice.nSpecies,length(unique(stimuli{speciesNumFieldNum})));
    
    % initialize to store the stimuli
    stimStruct_prac = struct();
    
    % get the indices of each family and only the number of species wanted
    for f = 1:length(cfg.stim.practice.familyNames)
      fInd = eval([sprintf('stimuli{%d} == %d & (stimuli{%d} == %d',familyNumFieldNum,f,speciesNumFieldNum,1),...
        sprintf(repmat([' | ',sprintf('stimuli{%d}',speciesNumFieldNum),' == %d'],1,(cfg.stim.practice.nSpecies - 1)),2:cfg.stim.practice.nSpecies), ')']);
      stimStruct_prac(f).fStims = struct(...
        stim_fieldnames{1},stimuli{1}(fInd),...
        stim_fieldnames{2},stimuli{2}(fInd),...
        stim_fieldnames{3},num2cell(stimuli{3}(fInd)),...
        stim_fieldnames{4},stimuli{4}(fInd),...
        stim_fieldnames{5},num2cell(stimuli{5}(fInd)),...
        stim_fieldnames{6},num2cell(stimuli{6}(fInd)),...
        stim_fieldnames{7},num2cell(stimuli{7}(fInd)),...
        stim_fieldnames{8},num2cell(stimuli{8}(fInd)));
      
      if length(stimStruct_prac(f).fStims) < (prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded)
        error('You have chosen %d stimuli for family %s (out of %d). This is not enough stimuli to accommodate all practice tasks.\nYou need at least %d for each of %d families (i.e., %d exemplars for each of %d species per family).',...
          length(stimStruct_prac(f).fStims),cfg.stim.practice.familyNames{f},sum(cfg.stim.practice.nExemplars(f,:)),(prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded),length(cfg.stim.practice.familyNames),((prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded) / cfg.stim.practice.nSpecies),cfg.stim.practice.nSpecies);
      end
    end
  elseif ~cfg.stim.useSeparatePracStims
    % find the indices for each family and select only cfg.stim.nSpecies
    fprintf('Practice: Selecting %d of %d possible species for each family.\n',cfg.stim.practice.nSpecies,length(unique([stimStruct(f).fStims.speciesNum])));
    
    % initialize to store the practice stimuli
    stimStruct_prac = struct();
    
    for f = 1:length(cfg.stim.familyNames)
      stimStruct_prac(f).fStims = struct();
      [stimStruct_prac(f).fStims,stimStruct(f).fStims] = et_divvyStims(...
        stimStruct(f).fStims,[],((prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded) / cfg.stim.practice.nSpecies),...
        cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{},{},(prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded));
    end
  end
end

%% Decide which will be the practice stimuli from each family

if expParam.runPractice
  % practice
  for f = 1:length(cfg.stim.practice.familyNames)
    expParam.session.(sprintf('f%dPractice',f)) = [];
    [expParam.session.(sprintf('f%dPractice',f)),stimStruct_prac(f).fStims] = et_divvyStims(...
      stimStruct_prac(f).fStims,[],cfg.stim.practice.nPractice,...
      cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{true});
  end
end

%% if there are practice recognition phases, get those stimuli

if expParam.runPractice
  for s = 1:expParam.nSessions
    
    sesName = expParam.sesTypes{s};
    
    % counting the phases, in case any sessions have the same phase type
    % multiple times
    prac_recogCount = 0;
    
    % for each phase in this session, see if any are recognition phases
    for p = 1:length(expParam.session.(sesName).phases)
      
      phaseName = expParam.session.(sesName).phases{p};
      
      switch phaseName
        
        case {'prac_recog'}
          prac_recogCount = prac_recogCount + 1;
          
          if ~isfield(cfg.stim.(sesName).(phaseName)(prac_recogCount),'familyNames')
            cfg.stim.(sesName).(phaseName)(prac_recogCount).familyNames = cfg.stim.practice.familyNames;
          end
          
          if ~isfield(cfg.stim.(sesName).(phaseName)(prac_recogCount),'usePrevPhase') || isempty(cfg.stim.(sesName).(phaseName)(prac_recogCount).usePrevPhase)
            expParam.session.(sesName).(phaseName)(prac_recogCount).allStims = cell(1,cfg.stim.(sesName).(phaseName)(prac_recogCount).nBlocks);
            for b = 1:cfg.stim.(sesName).(phaseName)(prac_recogCount).nBlocks
              for f = 1:length(cfg.stim.practice.familyNames)
                if ismember(cfg.stim.practice.familyNames{f},cfg.stim.(sesName).(phaseName)(prac_recogCount).familyNames)
                  [expParam.session.(sesName).(phaseName)(prac_recogCount).allStims{b},stimStruct_prac(f).fStims] = et_divvyStims(...
                    stimStruct_prac(f).fStims,expParam.session.(sesName).(phaseName)(prac_recogCount).allStims{b},...
                    cfg.stim.(sesName).(phaseName)(prac_recogCount).nStudyTarg + cfg.stim.(sesName).(phaseName)(prac_recogCount).nTestLure,...
                    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{true});
                end
              end
            end
          end
      end
    end
  end
end

%% Configure each session and phase

for s = 1:expParam.nSessions
  sesName = expParam.sesTypes{s};
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  matchCount = 0;
  nameCount = 0;
  recogCount = 0;
  nametrainCount = 0;
  viewnameCount = 0;
  viewCount = 0;
  compareCount = 0;
  
  prac_matchCount = 0;
  prac_nameCount = 0;
  prac_recogCount = 0;
  
  % for each phase in this session, run the appropriate config function
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case {'match'}
        matchCount = matchCount + 1;
        phaseCount = matchCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            [expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
              expParam.session.(sesName).(phaseName)(phaseCount).same,...
              expParam.session.(sesName).(phaseName)(phaseCount).diff,...
              cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).stim2MinRepeatSpacing);
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
      case {'name'}
        nameCount = nameCount + 1;
        phaseCount = nameCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            [expParam.session.(sesName).(phaseName)(phaseCount).nameStims] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).nameStims,'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).nameMaxConsecFamily);
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
      case {'recog'}
        recogCount = recogCount + 1;
        phaseCount = recogCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            for b = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).targStims)
              [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_shuffleStims(...
                expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).studyMaxConsecFamily);
            end
            for b = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).allStims)
              [expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_shuffleStims(...
                expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},'targ',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).testMaxConsec);
            end
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
      case {'nametrain'}
        nametrainCount = nametrainCount + 1;
        phaseCount = nametrainCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            for b = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
              [expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b}] = et_shuffleStims(...
                expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).nameMaxConsecFamily);
            end
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_nametrain(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
      case {'viewname'}
        viewnameCount = viewnameCount + 1;
        phaseCount = viewnameCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            for b = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).viewStims)
              [expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b}] = et_shuffleStims(...
                expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).viewMaxConsecFamily);
            end
            for b = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
              [expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b}] = et_shuffleStims(...
                expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).nameMaxConsecFamily);
            end
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_viewname(cfg,expParam,sesName,phaseName,phaseCount);
        end
      case {'view'}
        viewCount = viewCount + 1;
        phaseCount = viewCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            [expParam.session.(sesName).(phaseName)(phaseCount).viewStims] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).viewStims,'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).viewMaxConsecFamily);
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
        else
          [cfg,expParam] = et_processStims_view(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
      case {'prac_match'}
        prac_matchCount = prac_matchCount + 1;
        phaseCount = prac_matchCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            [expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
              expParam.session.(sesName).(phaseName)(phaseCount).same,...
              expParam.session.(sesName).(phaseName)(phaseCount).diff,...
              cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).stim2MinRepeatSpacing);
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
      case {'prac_name'}
        prac_nameCount = prac_nameCount + 1;
        phaseCount = prac_nameCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            [expParam.session.(sesName).(phaseName)(phaseCount).nameStims] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).nameStims,'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).nameMaxConsecFamily);
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
      case {'prac_recog'}
        prac_recogCount = prac_recogCount + 1;
        phaseCount = prac_recogCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            for b = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).targStims)
              [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_shuffleStims(...
                expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).studyMaxConsecFamily);
            end
            for b = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).allStims)
              [expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_shuffleStims(...
                expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},'targ',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).testMaxConsec);
            end
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount);
        end
      
      case {'compare'}
        compareCount = compareCount + 1;
        phaseCount = compareCount;
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            [expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
              expParam.session.(sesName).(phaseName)(phaseCount).same,...
              expParam.session.(sesName).(phaseName)(phaseCount).diff,...
              cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).stim2MinRepeatSpacing);
          end
          
          % set up to receive data from previous phase cfg
          if phaseCount == 1
            for r = 1:length(cfg.stim.(sesName).(phaseName))
              thisCfg = cfg.stim.(sesName).(phaseName)(r);
              fn2 = fieldnames(cfg.stim.(thisCfg.usePrevPhase{1}).(thisCfg.usePrevPhase{2})(thisCfg.usePrevPhase{3}));
              fn1 = fieldnames(thisCfg);
              dummy = struct;
              for f = 1:length(fn1)
                dummy.(fn1{f}) = thisCfg.(fn1{f});
              end
              for f = 1:length(fn2)
                dummy.(fn2{f}) = [];
              end
              if r == 1
                fieldsToBeReplaced = dummy;
              else
                fieldsToBeReplaced(r) = dummy;
              end
            end
            cfg.stim.(sesName).(phaseName) = fieldsToBeReplaced;
          end
          % transfer data from previous phase cfg
          thatCfg = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          fn = fieldnames(thatCfg);
          for f = 1:length(fn)
            if isempty(cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}))
              cfg.stim.(sesName).(phaseName)(phaseCount).(fn{f}) = thatCfg.(fn{f});
            end
          end
          
%           if phaseCount == 1
%             cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           elseif phaseCount > 1
%             cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
%           end
        else
          [cfg,expParam] = et_processStims_compare(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
    end % switch
  end % for p
end % for s

end % function

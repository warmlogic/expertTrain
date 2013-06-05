function [expParam] = et_processStims_EBUG(cfg,expParam)
% function [expParam] = et_processStims_EBUG(cfg,expParam)
%
% Description:
%  Prepares the stimuli, mostly in experiment presentation order. This
%  function is run by config_EBUG.
%
% see also: config_EBUG, et_divvyStims, et_divvyStims_match,
% et_shuffleStims, et_shuffleStims_match, et_processStims_match,
% et_processStims_recog, et_processStims_viewname,
% et_processStims_nametrain, et_processStims_name

%% Initial processing of the stimuli

% familyNum is field 3
familyNumFieldNum = 3;
% speciesNum is field 5
speciesNumFieldNum = 5;

% read in the stimulus list
fprintf('Loading stimulus list: %s...',cfg.stim.stimListFile);
fid = fopen(cfg.stim.stimListFile);
% the header line becomes the fieldnames
stim_fieldnames = regexp(fgetl(fid),'\t','split');
stimuli = textscan(fid,'%s%s%d%s%d%d%d%d','Delimiter','\t');
fclose(fid);
fprintf('Done.\n');

% stimuli needed per family for all phases except recognition
phaseFamilyStimNeeded = cfg.stim.nSpecies * (cfg.stim.nTrained + cfg.stim.nUntrained);
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
          recogFamilyStimNeeded = recogFamilyStimNeeded + (cfg.stim.nSpecies * (cfg.stim.(sesName).(phaseName)(recogCount).nStudyTarg + cfg.stim.(sesName).(phaseName)(recogCount).nTestLure));
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

for f = 1:length(cfg.stim.familyNames)
  % trained
  expParam.session.(sprintf('f%dTrained',f)) = [];
  [expParam.session.(sprintf('f%dTrained',f)),stimStruct(f).fStims] = et_divvyStims(...
    stimStruct(f).fStims,[],cfg.stim.nTrained,...
    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice', 'trained'},{0, 1});
  
  % untrained
  expParam.session.(sprintf('f%dUntrained',f)) = [];
  [expParam.session.(sprintf('f%dUntrained',f)),stimStruct(f).fStims] = et_divvyStims(...
    stimStruct(f).fStims,[],cfg.stim.nUntrained,...
    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice', 'trained'},{0, 0});
end

%% if there are recognition phases, get those stimuli

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
        
        if ~isfield(cfg.stim.(sesName).(phaseName)(recogCount),'usePrevPhase') || isempty(cfg.stim.(sesName).(phaseName)(recogCount).usePrevPhase)
          expParam.session.(sesName).(phaseName)(recogCount).allStims = cell(1,cfg.stim.(sesName).(phaseName)(recogCount).nBlocks);
          for b = 1:cfg.stim.(sesName).(phaseName)(recogCount).nBlocks
            for f = 1:length(cfg.stim.familyNames)
              [expParam.session.(sesName).(phaseName)(recogCount).allStims{b},stimStruct(f).fStims] = et_divvyStims(...
                stimStruct(f).fStims,expParam.session.(sesName).(phaseName)(recogCount).allStims{b},...
                cfg.stim.(sesName).(phaseName)(recogCount).nStudyTarg + cfg.stim.(sesName).(phaseName)(recogCount).nTestLure,...
                cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{0});
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
    
    % find the indices for each family and select only cfg.stim.nSpecies
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
      stimStruct_prac(f).fStims,[],cfg.stim.practice.nExemplars,...
      cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{1});
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
          
          if ~isfield(cfg.stim.(sesName).(phaseName)(prac_recogCount),'usePrevPhase') || isempty(cfg.stim.(sesName).(phaseName)(prac_recogCount).usePrevPhase)
            expParam.session.(sesName).(phaseName)(prac_recogCount).allStims = cell(1,cfg.stim.(sesName).(phaseName)(prac_recogCount).nBlocks);
            for b = 1:cfg.stim.(sesName).(phaseName)(prac_recogCount).nBlocks
              for f = 1:length(cfg.stim.familyNames)
                [expParam.session.(sesName).(phaseName)(prac_recogCount).allStims{b},stimStruct_prac(f).fStims] = et_divvyStims(...
                  stimStruct_prac(f).fStims,expParam.session.(sesName).(phaseName)(prac_recogCount).allStims{b},...
                  cfg.stim.(sesName).(phaseName)(prac_recogCount).nStudyTarg + cfg.stim.(sesName).(phaseName)(prac_recogCount).nTestLure,...
                  cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{1});
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
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
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
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
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
            [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).studyMaxConsecFamily);
            [expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).studyMaxConsecFamily);
          end
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
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
            [expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b}] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).nameMaxConsecFamily);
          end
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
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
            [expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b}] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).viewMaxConsecFamily);
            [expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b}] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).nameMaxConsecFamily);
          end
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
        else
          [cfg,expParam] = et_processStims_viewname(cfg,expParam,sesName,phaseName,phaseCount);
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
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
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
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
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
            [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).studyMaxConsecFamily);
            [expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_shuffleStims(...
              expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},'familyNum',cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3}).studyMaxConsecFamily);
          end
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
        else
          [cfg,expParam] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount);
        end
        
    end % switch
  end % for p
end % for s

end % function

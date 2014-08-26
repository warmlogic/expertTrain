function [cfg,expParam] = space_processStims(cfg,expParam)
% function [cfg,expParam] = space_processStims(cfg,expParam)
%
% Description:
%  Prepares the stimuli, mostly in experiment presentation order. This
%  function is run by any config_EXPNAME file.
%
% see also: config_SPACE, et_shuffleStims, space_divvyStims
%           space_processStims_study, space_processStims_test,

%% Initial processing of the stimuli

% read in the stimulus list
fprintf('Loading image stimulus list: %s...',cfg.stim.imgStimListFile);
fid = fopen(cfg.stim.imgStimListFile);
% the header line becomes the fieldnames
stim_fieldnames = regexp(fgetl(fid),'\t','split');
imageStimuli = textscan(fid,'%s%s%d%d','Delimiter','\t');
fclose(fid);
fprintf('Done.\n');

% % number of stimuli needed per category
% categoryStimNeeded = ceil((cfg.stim.study_nPairs + cfg.stim.test_nPairs) / 2);

% create a structure for each category with all the stim information

% initialize to store the stimuli
imgStimStruct = struct();

% get the indices of each family and only the number of species wanted
for cn = 1:length(cfg.stim.categoryNames)
  cnInd = imageStimuli{ismember(stim_fieldnames,'categoryNum')} == cn;
  
  imgStimStruct(cn).catStims = struct(...
    stim_fieldnames{1},imageStimuli{1}(cnInd),...
    stim_fieldnames{2},imageStimuli{2}(cnInd),...
    stim_fieldnames{3},num2cell(imageStimuli{3}(cnInd)),...
    stim_fieldnames{4},num2cell(imageStimuli{4}(cnInd)));
  
  %   if length(stimStruct(cn).catStims) < categoryStimNeeded
  %     error('You have chosen %d stimuli for category %s (out of %d). This is not enough stimuli to accommodate all non-practice tasks.\nYou need at least %d for each of %d categories.',...
  %       length(stimStruct(cn).catStims),cfg.stim.categoryNames{cn},sum(cfg.stim.nExemplars(cn,:)),(categoryStimNeeded + recogFamilyStimNeeded),length(cfg.stim.categoryNames),((categoryStimNeeded + recogFamilyStimNeeded) / cfg.stim.nSpecies),cfg.stim.nSpecies);
  %   end
end

% read in the stimulus list
fprintf('Loading word stimulus list: %s...',cfg.stim.wordpoolListFile);
fid = fopen(cfg.stim.wordpoolListFile);
% the header line becomes the fieldnames
stim_fieldnames = regexp(fgetl(fid),'\t','split');
wordStimuli = textscan(fid,'%s%d','Delimiter','\t');
fclose(fid);
fprintf('Done.\n');

% initialize to store the stimuli
wordStimStruct.wordStims = struct(...
    stim_fieldnames{1},wordStimuli{1},...
    stim_fieldnames{2},num2cell(wordStimuli{2}));

%% read the practice stimulus file, or grab stimuli from the main category for practice

if expParam.runPractice
  if cfg.stim.useSeparatePracStims
    % read in the stimulus list
    fprintf('Loading image stimulus list: %s...',cfg.stim.practice.imgStimListFile);
    fid = fopen(cfg.stim.practice.imgStimListFile);
    % the header line becomes the fieldnames
    stim_fieldnames = regexp(fgetl(fid),'\t','split');
    imageStimuli_prac = textscan(fid,'%s%s%d%d','Delimiter','\t');
    fclose(fid);
    fprintf('Done.\n');
    
    % create a structure for each category with all the stim information
    
    % initialize to store the stimuli
    imgStimStruct_prac = struct();
    
    % get the indices of each family and only the number of species wanted
    for cn = 1:length(cfg.stim.practice.categoryNames)
      cnInd = imageStimuli_prac{ismember(stim_fieldnames,'categoryNum')} == cn;
      
      imgStimStruct_prac(cn).catStims = struct(...
        stim_fieldnames{1},imageStimuli_prac{1}(cnInd),...
        stim_fieldnames{2},imageStimuli_prac{2}(cnInd),...
        stim_fieldnames{3},num2cell(imageStimuli_prac{3}(cnInd)),...
        stim_fieldnames{4},num2cell(imageStimuli_prac{4}(cnInd)));
      
      %       if length(stimStruct_prac(cn).catStims) < (prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded)
      %         error('You have chosen %d stimuli for family %s (out of %d). This is not enough stimuli to accommodate all practice tasks.\nYou need at least %d for each of %d families (i.e., %d exemplars for each of %d species per family).',...
      %           length(stimStruct_prac(cn).catStims),cfg.stim.practice.categoryNames{cn},sum(cfg.stim.practice.nExemplars(cn,:)),(prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded),length(cfg.stim.practice.categoryNames),((prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded) / cfg.stim.practice.nSpecies),cfg.stim.practice.nSpecies);
      %       end
    end
    
    % read in the stimulus list
    fprintf('Loading word stimulus list: %s...',cfg.stim.practice.wordpoolListFile);
    fid = fopen(cfg.stim.practice.wordpoolListFile);
    % the header line becomes the fieldnames
    stim_fieldnames = regexp(fgetl(fid),'\t','split');
    wordStimuli_prac = textscan(fid,'%s%d','Delimiter','\t');
    fclose(fid);
    fprintf('Done.\n');
    
    % initialize to store the stimuli
    wordStimStruct_prac = struct();
    
    wordStimStruct_prac.wordStims = struct(...
      stim_fieldnames{1},wordStimuli_prac{1},...
      stim_fieldnames{2},num2cell(wordStimuli_prac{2}));
    
  elseif ~cfg.stim.useSeparatePracStims
    % find the indices for each family and select only cfg.stim.nSpecies
%     fprintf('Practice: Selecting %d of %d possible species for each family.\n',cfg.stim.practice.nSpecies,length(unique([imgStimStruct(cn).catStims.speciesNum])));
    
    % initialize to store the practice stimuli
    imgStimStruct_prac = struct();
    
    nPracStim = (((cfg.stim.practice.nPairs_study_targ_spaced + cfg.stim.practice.nPairs_study_targ_massed) * 2)...
      + cfg.stim.practice.nPairs_study_targ_onePres + cfg.stim.practice.nPairs_test_lure)...
      * length(cfg.stim.practice.categoryNames);
    
    for cn = 1:length(cfg.stim.practice.categoryNames)
      imgStimStruct_prac(cn).catStims = struct();
      [imgStimStruct_prac(cn).catStims,imgStimStruct(cn).catStims] = space_divvyStims(...
        imgStimStruct(cn).catStims,[],nPracStim / length(cfg.stim.practice.categoryNames),...
        cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{},{},[]);
      %imgStimStruct(cn).catStims,[],nPracStim,...
      %cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{},{},nPracStim / length(cfg.stim.practice.categoryNames));
      %cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{},{},(prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded));
    end
    
    wordStimStruct_prac.wordStims = struct();
    [wordStimStruct_prac.wordStims,wordStimStruct.wordStims] = space_divvyStims(...
      wordStimStruct.wordStims,[],nPracStim,...
      cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{},{},[]);
    %cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{},{},nPracStim / length(cfg.stim.practice.categoryNames));
    %cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{},{},(prac_phaseFamilyStimNeeded + prac_recogFamilyStimNeeded));
  end
end

% %% Decide which will be the practice stimuli from each category
% 
% if expParam.runPractice
%   % practice images
%   for cn = 1:length(cfg.stim.practice.categoryNames)
%     expParam.session.(sprintf('cn%dPractice',cn)) = [];
%     [expParam.session.(sprintf('cn%dPractice',cn)),imgStimStruct_prac(cn).catStims] = space_divvyStims(...
%       imgStimStruct_prac(cn).catStims,[],cfg.stim.practice.nPractice,...
%       cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{true});
%   end
%   
% %   % practice words
% %   expParam.session.(sprintf('cn%dPractice',cn)) = [];
% %   [expParam.session.(sprintf('cn%dPractice',cn)),wordStimStruct_prac.wordStims] = space_divvyStims(...
% %     wordStimStruct_prac.wordStims,[],cfg.stim.practice.nPractice,...
% %     cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice'},{true});
% end

%% Configure each session and phase

for s = 1:expParam.nSessions
  sesName = expParam.sesTypes{s};
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  expoCount = 0;
  msCount = 0;
  distCount = 0;
  crCount = 0;
  croCount = 0;
  
  prac_expoCount = 0;
  prac_msCount = 0;
  prac_distCount = 0;
  prac_crCount = 0;
  prac_croCount = 0;
  
  % for each phase in this session, run the appropriate config function
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case {'multistudy','prac_multistudy'}
        if strcmp(phaseName,'multistudy')
          msCount = msCount + 1;
          phaseCount = msCount;
        elseif strcmp(phaseName,'prac_multistudy')
          prac_msCount = prac_msCount + 1;
          phaseCount = prac_msCount;
        end
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            % shuffle the pairs, keeping them together...
            randind = randperm(length(expParam.session.(sesName).(phaseName)(phaseCount).studyStims_img));
            expParam.session.(sesName).(phaseName)(phaseCount).studyStims_img = expParam.session.(sesName).(phaseName)(phaseCount).studyStims_img(randind);
            expParam.session.(sesName).(phaseName)(phaseCount).studyStims_word = expParam.session.(sesName).(phaseName)(phaseCount).studyStims_word(randind);
            % and add a new pair number so they're in a different order
            for i = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).studyStims_img)
              expParam.session.(sesName).(phaseName)(phaseCount).studyStims_img(i).pairNum = i;
              expParam.session.(sesName).(phaseName)(phaseCount).studyStims_word(i).pairNum = i;
            end
          end
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
        else
          if phaseCfg.isExp
            [cfg,expParam,imgStimStruct,wordStimStruct] = space_processStims_study(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct,wordStimStruct);
          else
            [cfg,expParam,imgStimStruct_prac,wordStimStruct_prac] = space_processStims_study(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct_prac,wordStimStruct_prac);
          end
        end
        
        % if there was an exposure phase immediately before this phase,
        % shuffle the study stimuli and put them in the exposure struct.
        if p > 1 && (strcmp(expParam.session.(sesName).phases{p-1},'expo') || strcmp(expParam.session.(sesName).phases{p-1},'prac_expo'))
          if strcmp(expParam.session.(sesName).phases{p-1},'expo')
            expoCount = expoCount + 1;
            thisExpoCount = expoCount;
          elseif strcmp(expParam.session.(sesName).phases{p-1},'prac_expo')
            prac_expoCount = prac_expoCount + 1;
            thisExpoCount = prac_expoCount;
          end
          thisExpoName = expParam.session.(sesName).phases{p-1};
          
          expoStims = expParam.session.(sesName).(phaseName)(phaseCount).studyStims_img;
          
          % only need one exposure of each stimulus
          expoStims = expoStims([expoStims.presNum] == 1);
          
          fprintf('Shuffling %s %s (%d) task stimuli.\n',sesName,thisExpoName,thisExpoCount);
          [expoStims] = et_shuffleStims(...
            expoStims,'categoryNum',cfg.stim.(sesName).(thisExpoName)(thisExpoCount).expoMaxConsecCategory);
          %   studyStims_img.p1,'lag',phaseCfg.studyMaxConsecLag);
          %   studyStims_img.p1,'categoryStr',phaseCfg.studyMaxConsecCategory);
          
          expParam.session.(sesName).(thisExpoName)(thisExpoCount).expoStims_img = expoStims;
          
        end
        
      case {'distract_math','prac_distract_math'}
        if strcmp(phaseName,'distract_math')
          distCount = distCount + 1;
          phaseCount = distCount;
        elseif strcmp(phaseName,'prac_distract_math')
          prac_distCount = prac_distCount + 1;
          phaseCount = prac_distCount;
        end
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
        end
        
      case {'cued_recall','prac_cued_recall'}
        if strcmp(phaseName,'cued_recall')
          crCount = crCount + 1;
          phaseCount = crCount;
        elseif strcmp(phaseName,'prac_cued_recall')
          prac_crCount = prac_crCount + 1;
          phaseCount = prac_crCount;
        end
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            % shuffle the pairs, keeping them together...
            randind = randperm(length(expParam.session.(sesName).(phaseName)(phaseCount).testStims_img));
            expParam.session.(sesName).(phaseName)(phaseCount).testStims_img = expParam.session.(sesName).(phaseName)(phaseCount).testStims_img(randind);
            expParam.session.(sesName).(phaseName)(phaseCount).testStims_word = expParam.session.(sesName).(phaseName)(phaseCount).testStims_word(randind);
            % and add a new pair number so they're in a different order
            for i = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).testStims_img)
              expParam.session.(sesName).(phaseName)(phaseCount).testStims_img(i).pairNum = i;
              expParam.session.(sesName).(phaseName)(phaseCount).testStims_word(i).pairNum = i;
            end
          end
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
        else
          if phaseCfg.isExp
            [cfg,expParam,imgStimStruct,wordStimStruct] = space_processStims_test(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct,wordStimStruct,'multistudy');
          else
            [cfg,expParam,imgStimStruct_prac,wordStimStruct_prac] = space_processStims_test(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct_prac,wordStimStruct_prac,'prac_multistudy');
          end
        end
        
      case {'cued_recall_only','prac_cued_recall_only'}
        if strcmp(phaseName,'cued_recall_only')
          croCount = croCount + 1;
          phaseCount = croCount;
        elseif strcmp(phaseName,'prac_cued_recall_only')
          prac_croCount = prac_croCount + 1;
          phaseCount = prac_croCount;
        end
        phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
        
        if isfield(phaseCfg,'usePrevPhase') && ~isempty(phaseCfg.usePrevPhase)
          expParam.session.(sesName).(phaseName)(phaseCount) = expParam.session.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          if isfield(phaseCfg,'reshuffleStims') && phaseCfg.reshuffleStims
            % shuffle the pairs, keeping them together...
            randind = randperm(length(expParam.session.(sesName).(phaseName)(phaseCount).testStims_img));
            expParam.session.(sesName).(phaseName)(phaseCount).testStims_img = expParam.session.(sesName).(phaseName)(phaseCount).testStims_img(randind);
            expParam.session.(sesName).(phaseName)(phaseCount).testStims_word = expParam.session.(sesName).(phaseName)(phaseCount).testStims_word(randind);
            % and add a new pair number so they're in a different order
            for i = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).testStims_img)
              expParam.session.(sesName).(phaseName)(phaseCount).testStims_img(i).pairNum = i;
              expParam.session.(sesName).(phaseName)(phaseCount).testStims_word(i).pairNum = i;
            end
          end
          if phaseCount == 1
            cfg.stim.(sesName).(phaseName) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          elseif phaseCount > 1
            cfg.stim.(sesName).(phaseName)(phaseCount) = cfg.stim.(phaseCfg.usePrevPhase{1}).(phaseCfg.usePrevPhase{2})(phaseCfg.usePrevPhase{3});
          end
        else
          if phaseCfg.isExp
            [cfg,expParam,imgStimStruct,wordStimStruct] = space_processStims_test(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct,wordStimStruct,'multistudy');
          else
            [cfg,expParam,imgStimStruct_prac,wordStimStruct_prac] = space_processStims_test(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct_prac,wordStimStruct_prac,'prac_multistudy');
          end
        end
        
    end % switch
  end % for p
end % for s

end % function

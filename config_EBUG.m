function [cfg,expParam] = config_EBUG(cfg,expParam)
% function [cfg,expParam] = config_EBUG(cfg,expParam)
%
% Description:
%  Configuration function for creature expertise training experiment. This
%  file should be edited for your particular experiment. This function runs
%  process_EBUG_stimuli to prepare the stimuli for experiment presentation.
%
% see also: et_saveStimList, et_processStims_EBUG, et_processStims_name,
% et_processStims_viewname, et_processStims_recog, et_processStims_match

%% Experiment session information

% set up configuration structures to keep track of what day and phase we're
% on.

% do we want to record EEG using Net Station?
expParam.useNS = false;
% what host is netstation running on?
if expParam.useNS
  expParam.NSPort = 55513;
  
  % % D458
  expParam.NSHost = '128.138.223.251';
  
  % % D464
  % expParam.NSHost = '128.138.223.26'
  
  expParam.baselineRecordSecs = 10.0;
end

% sound defaults
playSound = true;
correctSound = 'high';
incorrectSound = 'low';
% matching task defaults
matchTextPrompt = true;

% Set the number of sessions
expParam.nSessions = 9;

% Pre-test, training day 1, training days 1-6, post-test, post-test delayed.
expParam.sesTypes = {'pretest','train1','train2','train3','train4','train5','train6','posttest','posttest_delay'};

% set up a field for each session type
expParam.session.pretest.phases = {'match','recog'};
expParam.session.train1.phases = {'viewname','name','match'};
expParam.session.train2.phases = {'match','name','match'};
expParam.session.train3.phases = {'match','name','match'};
expParam.session.train4.phases = {'match','name','match'};
expParam.session.train5.phases = {'match','name','match'};
expParam.session.train6.phases = {'match','name','match'};
expParam.session.posttest.phases = {'match','recog'};
expParam.session.posttest_delay.phases = {'match','recog'};

% % debug
% expParam.nSessions = 1;
% expParam.sesTypes = {'pretest'};
% % set up a field for each session type
% expParam.session.pretest.phases = {'match'};
% % expParam.session.pretest.phases = {'recog'};

% % debug
% expParam.nSessions = 1;
% expParam.sesTypes = {'train1'};
% %expParam.session.train1.phases = {'viewname'};
% %expParam.session.train1.phases = {'name'};
% expParam.session.train1.phases = {'viewname','name','match'};

% % debug
% expParam.nSessions = 1;
% expParam.sesTypes = {'train2'};
% % expParam.session.train2.phases = {'match'};
% %expParam.session.train2.phases = {'name'};
% expParam.session.train2.phases = {'match','name','match'};

%% do some error checking

possible_phases = {'match','recog','viewname','name'};
if length(expParam.sesTypes) ~= expParam.nSessions
  error('There should be %d sessions defined, but expParam.sesTypes contains %d sessions.',expParam.nSessions,length(expParam.sesTypes));
end
for s = 1:length(expParam.sesTypes)
  if isfield(expParam.session,expParam.sesTypes{s}) && ~isempty(expParam.session.(expParam.sesTypes{s}))
    if isfield(expParam.session.(expParam.sesTypes{s}),'phases') && ~isempty(expParam.session.(expParam.sesTypes{s}).phases)
      for p = 1:length(expParam.session.(expParam.sesTypes{s}).phases)
        if ~ismember(expParam.session.(expParam.sesTypes{s}).phases{p},possible_phases)
          error('%s is not a valid phase in expParam.session.%s.phases',expParam.session.(expParam.sesTypes{s}).phases{p},expParam.sesTypes{s});
        end
      end
    elseif ~isfield(expParam.session.(expParam.sesTypes{s}),'phases') || isempty(expParam.session.(expParam.sesTypes{s}).phases)
      error('Session phases not defined for %s! (in expParam.session.%s.phases)',expParam.sesTypes{s},expParam.sesTypes{s});
    end
  elseif ~isfield(expParam.session,expParam.sesTypes{s}) || isempty(expParam.session.(expParam.sesTypes{s}))
    error('expParam.session does not contain a field for session type ''%s''!',expParam.sesTypes{s});
  end
end

%% If this is session 1, setup the experiment

if expParam.sessionNum == 1
  
  %% Subject parameters
  
  % for counterbalancing
  
  % odd or even subject number
  if mod(str2double(expParam.subject(end)),2) == 0
    expParam.isEven = true;
  else
    expParam.isEven = false;
  end
  
  % subject number ends in 1-5 or 6-0
  if str2double(expParam.subject(end)) >= 1 && str2double(expParam.subject(end)) <= 5
    expParam.is15 = true;
  else
    expParam.is15 = false;
  end
  
  % timer for when to take a blink break (only when useNS=true)
  cfg.stim.secUntilBlinkBreak = 45.000;
  
  %% Stimulus parameters
  
  cfg.files.stimFileExt = '.bmp';
  cfg.stim.nFamilies = 2;
  % family names correspond to the directories in which stimuli reside
  cfg.stim.familyNames = {'a','s'};
  % assumes that each family has the same number of species
  cfg.stim.nSpecies = 10;
  % % debug
  % cfg.stim.nSpecies = 3;
  % initialize to store the number of exemplars for each species
  cfg.stim.nExemplars = zeros(cfg.stim.nFamilies,cfg.stim.nSpecies);
  
  cfg.files.imgDir = fullfile(cfg.files.expDir,'images');
  cfg.files.stimDir = fullfile(cfg.files.imgDir,'Creatures');
  % save an individual stimulus list for each subject
  cfg.stim.file = fullfile(cfg.files.subSaveDir,'stimList.txt');
  
  % set the resources directory
  cfg.files.resDir = fullfile(cfg.files.imgDir,'resources');
  
  % create the stimulus list if it doesn't exist
  shuffleSpecies = true;
  if ~exist(cfg.stim.file,'file')
    [cfg] = et_saveStimList(cfg,shuffleSpecies);
  else
    % % debug = warning instead of error
    % warning('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.file);
    error('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.file);
  end
  
  % basic/subordinate families (counterbalance based on even/odd subNum)
  if expParam.isEven
    cfg.stim.famNumBasic = 1;
    cfg.stim.famNumSubord = 2;
  else
    cfg.stim.famNumBasic = 2;
    cfg.stim.famNumSubord = 1;
  end
  % what to call the basic-level family in viewing and naming tasks
  cfg.text.basicFamStr = 'Other';
  
  % Number of trained and untrained per species per family
  cfg.stim.nTrained = 6;
  cfg.stim.nUntrained = 6;
  
  % % debug
  % cfg.stim.nTrained = 2;
  % cfg.stim.nUntrained = 2;
  
  % whether to remove the trained/untrained stims from the stimulus pool
  % after they are chosen
  cfg.stim.rmStims_init = true;
  % whether to shuffle the stimulus pool before choosing trained/untrained
  cfg.stim.shuffleFirst_init = true;

  % % subordinate family species numbers
  % cfg.stim.specNum(cfg.stim.famNumSubord,:)
  % % subordinate family species letters
  % cfg.stim.specStr(cfg.stim.famNumSubord,:)
  
  %% Define the response keys
  
  % the experimenter's secret key to continue the experiment
  cfg.keys.expContinue = 'g';
  
  % use spacebar for naming "other" family (basic-level naming)
  cfg.keys.otherKeyNames = {'space'};
  cfg.keys.s00 = KbName(cfg.keys.otherKeyNames{1});
  % for i = 1:length(cfg.keys.otherKeyNames)
  %   cfg.keys.(sprintf('s%.2d',i-1)) = KbName(cfg.keys.otherKeyNames{i});
  % end
  
  % keys for naming particular species (subordinate-level naming)
  
  cfg.keys.speciesKeyNames = {'a','s','d','f','v','n','j','k','l',';:'};
  %cfg.keys.speciesKeyNames = {'a','s','d','f','v','b','h','j','k','l'};
  
  % set the species keys
  for i = 1:length(cfg.keys.speciesKeyNames)
    % sXX, where XX is an integer, buffered with a zero if i <= 9
    %cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeyNames{cfg.keys.randKeyOrder(i)});
    cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeyNames{i});
  end
  
  % subordinate matching keys (counterbalanced based on subNum 1-5, 6-0)
  %cfg.keys.matchKeyNames = {'f','h'};
  cfg.keys.matchKeyNames = {'f','j'};
  if expParam.is15
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{1});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{2});
  else
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{2});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{1});
  end
  
  % recognition keys
  %cfg.keys.recogKeyNames = {{'a','s','d','f','h'},{'f','h','j','k','l'}};
  cfg.keys.recogKeyNames = {{'a','s','d','f','h'},{'f','j','k','l',';:'}};
  
  % recognition keys (counterbalanced based on even/odd and 1-5, 6-10)
  if expParam.isEven && expParam.is15 || ~expParam.isEven && ~expParam.is15
    cfg.keys.recogKeySet = 1;
    cfg.keys.recogKeyNames = cfg.keys.recogKeyNames{cfg.keys.recogKeySet};
    cfg.keys.recogDefUn = KbName(cfg.keys.recogKeyNames{1});
    cfg.keys.recogMayUn = KbName(cfg.keys.recogKeyNames{2});
    cfg.keys.recogMayF = KbName(cfg.keys.recogKeyNames{3});
    cfg.keys.recogDefF = KbName(cfg.keys.recogKeyNames{4});
    cfg.keys.recogRecoll = KbName(cfg.keys.recogKeyNames{5});
  elseif expParam.isEven && ~expParam.is15 || ~expParam.isEven && expParam.is15
    cfg.keys.recogKeySet = 2;
    cfg.keys.recogKeyNames = cfg.keys.recogKeyNames{cfg.keys.recogKeySet};
    cfg.keys.recogDefUn = KbName(cfg.keys.recogKeyNames{5});
    cfg.keys.recogMayUn = KbName(cfg.keys.recogKeyNames{4});
    cfg.keys.recogMayF = KbName(cfg.keys.recogKeyNames{3});
    cfg.keys.recogDefF = KbName(cfg.keys.recogKeyNames{2});
    cfg.keys.recogRecoll = KbName(cfg.keys.recogKeyNames{1});
  end
  
  %% Text size and symbol configuration
  
  cfg.text.basic = 32;
  cfg.text.fixsize = 32;
  cfg.text.fixSymbol = '+';
  cfg.text.respSymbol = '?';
  
  if matchTextPrompt
    cfg.text.matchSame = 'Same';
    cfg.text.matchDiff = 'Diff   ';
  end

  %% Session/phase configuration
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % pretest configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'pretest';
  
  % Matching
  
  % every stimulus is in both the same and the different condition.
  cfg.stim.(sesName).match.nSame = cfg.stim.nTrained;
  cfg.stim.(sesName).match.nDiff = cfg.stim.nTrained;
  % minimum number of trials needed between exact repeats of a given
  % stimulus as stim2
  cfg.stim.(sesName).match.stim2MinRepeatSpacing = 2;
  % whether to have "same" and "diff" text with the response prompt
  cfg.stim.(sesName).match.matchTextPrompt = matchTextPrompt;

  % rmStims_orig is false because all stimuli are used in both 'same' and
  % 'diff' conditions
  cfg.stim.(sesName).match.rmStims_orig = false;
  % rmStims_pair is true because pairs are removed after they're added
  cfg.stim.(sesName).match.rmStims_pair = true;
  cfg.stim.(sesName).match.shuffleFirst = true;
  
  % durations, in seconds
  cfg.stim.(sesName).match.isi = 0.5;
  cfg.stim.(sesName).match.stim1 = 0.8;
  cfg.stim.(sesName).match.stim2 = 0.8;
  % % random intervals are generated on the fly
  % cfg.stim.(sesName).match.preStim1 = 0.5 to 0.7;
  % cfg.stim.(sesName).match.preStim2 = 1.0 to 1.2;
  % % % Not setting a response time limit
  % cfg.stim.(sesName).match.response = 1.0;
  
  % Recognition
  
  % number of target and lure stimuli per species per family per study/test
  % block. Assumes all targets and lures are tested in a block.
  cfg.stim.(sesName).recog.nStudyTarg = 2;
  cfg.stim.(sesName).recog.nTestLure = 1;
  % maximum number of same family in a row during study task
  cfg.stim.(sesName).recog.studyMaxConsecFamily = 0;
  % maximum number of targets or lures in a row during test task
  cfg.stim.(sesName).recog.testMaxConsec = 0;
  
  % task parameters
  cfg.stim.(sesName).recog.nBlocks = 8;
  cfg.stim.(sesName).recog.nTargPerBlock = 40;
  cfg.stim.(sesName).recog.nLurePerBlock = 20;
  
  % do not reuse recognition stimuli in other parts of the experiment
  cfg.stim.(sesName).recog.rmStims = true;
  cfg.stim.(sesName).recog.shuffleFirst = true;
  
  % durations, in seconds
  cfg.stim.(sesName).recog.study_isi = 0.8;
  cfg.stim.(sesName).recog.study_preTarg = 0.2;
  cfg.stim.(sesName).recog.study_targ = 2.0;
  cfg.stim.(sesName).recog.test_isi = 0.8;
  cfg.stim.(sesName).recog.test_preStim = 0.2;
  cfg.stim.(sesName).recog.test_stim = 1.5;
  % % % Not setting a response time limit
  % cfg.stim.(sesName).recog.response = 1.5;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 1 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'train1';
  
  % Viewing+Naming
  
  % hard coded order of which species are presented in each block
  % (counterbalanced). Blocks are denoted by vectors.
  cfg.stim.(sesName).viewname.blockSpeciesOrder = {...
    [1, 2],...
    [1, 2, 3],...
    [1, 2, 3, 4],...
    [1, 2, 3, 4, 5],...
    [3, 4, 5, 6],...
    [4, 5, 6, 7],...
    [5, 6, 7, 8],...
    [6, 7, 8, 9],...
    [7, 8, 9, 10],...
    [8, 9, 10, 1],...
    [9, 10, 2, 3],...
    [10, 4, 5, 6],...
    [7, 8, 9, 10]};
  
  % hard coded stimulus indices for viewing block presentations
  % (counterbalanced). Blocks are denoted by cells, and the vectors within
  % each block represent the exemplar number(s) for each species, where the
  % index of each vector in the cell corresponds to the exemplar numbers
  % for that species (i.e., first vector is species 1, next vector is
  % species 2, etc.).
  
  cfg.stim.(sesName).viewname.viewIndices = {...
    {[1], [1]},...
    {[4], [4], [1]},...
    {[2], [2], [4], [1]},...
    {[5], [5], [2], [4], [1]},...
    {[5], [2], [4], [1]},...
    {[5], [2], [4], [1]},...
    {[5], [2], [4], [1]},...
    {[5], [2], [4], [1]},...
    {[5], [2], [4], [1]},...
    {[5], [2], [4], [3]},...
    {[5], [2], [3], [3]},...
    {[5], [2], [3], [3]},...
    {[3], [3], [3], [3]}};
  
  % hard coded stimulus indices for naming block presentations
  % (counterbalanced). Blocks are denoted by cells, and the vectors within
  % each block represent the exemplar number(s) for each species, where the
  % index of each vector in the cell corresponds to the exemplar numbers
  % for that species (i.e., first vector is species 1, next vector is
  % species 2, etc.).
  
  cfg.stim.(sesName).viewname.nameIndices = {...
    {[2, 3], [2, 3]},...
    {[5, 6], [5, 6], [2, 3]},...
    {[3, 4], [3, 4], [5, 6], [2, 3]},...
    {[1, 6], [1, 6], [3, 4], [5, 6], [2, 3]},...
    {[1, 6], [3, 4], [5, 6], [2, 3]},...
    {[1, 6], [3, 4], [5, 6], [2, 3]},...
    {[1, 6], [3, 4], [5, 6], [2, 3]},...
    {[1, 6], [3, 4], [5, 6], [2, 3]},...
    {[1, 6], [3, 4], [5, 6], [2, 3]},...
    {[1, 6], [3, 4], [5, 6], [4, 5]},...
    {[1, 6], [3, 4], [5, 6], [5, 6]},...
    {[1, 6], [5, 6], [5, 6], [5, 6]},...
    {[5, 6], [5, 6], [5, 6], [5, 6]}};
  
  % maximum number of repeated exemplars from each family in viewname/view
  cfg.stim.(sesName).viewname.viewMaxConsecFamily = 3;
  
  % maximum number of repeated exemplars from each family in viewname/name
  cfg.stim.(sesName).viewname.nameMaxConsecFamily = 3;
  
  % % debug
  % cfg.stim.(sesName).viewname.blockSpeciesOrder = {[1, 2],[1, 2, 3]};
  % cfg.stim.(sesName).viewname.viewIndices = {{[1], [1]}, {[2], [2], [2]}};
  % cfg.stim.(sesName).viewname.nameIndices = {{[2], [2]}, {[1], [1], [1]}};
  
  % durations, in seconds
  cfg.stim.(sesName).viewname.view_isi = 0.8;
  cfg.stim.(sesName).viewname.view_preStim = 0.2;
  cfg.stim.(sesName).viewname.view_stim = 4.0;
  cfg.stim.(sesName).viewname.name_isi = 0.5;
  % cfg.stim.(sesName).viewname.name_preStim = 0.5 to 0.7;
  cfg.stim.(sesName).viewname.name_stim = 1.0;
  cfg.stim.(sesName).viewname.name_response = 2.0;
  cfg.stim.(sesName).viewname.name_feedback = 1.0;
  
  % do we want to play feedback beeps?
  cfg.stim.(sesName).viewname.playSound = playSound;
  cfg.stim.(sesName).viewname.correctSound = correctSound;
  cfg.stim.(sesName).viewname.incorrectSound = incorrectSound;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.(sesName).name.nameMaxConsecFamily = 3;
  
  % durations, in seconds
  cfg.stim.(sesName).name.name_isi = 0.5;
  % cfg.stim.(sesName).name.name_preStim = 0.5 to 0.7;
  cfg.stim.(sesName).name.name_stim = 1.0;
  cfg.stim.(sesName).name.name_response = 2.0;
  cfg.stim.(sesName).name.name_feedback = 1.0;
  
  % do we want to play feedback beeps?
  cfg.stim.(sesName).name.playSound = playSound;
  cfg.stim.(sesName).name.correctSound = correctSound;
  cfg.stim.(sesName).name.incorrectSound = incorrectSound;
  
  % Matching
  
  % number per species per family (half because each stimulus is only in
  % same or different condition)
  cfg.stim.(sesName).match.nSame = cfg.stim.nTrained / 2;
  cfg.stim.(sesName).match.nDiff = cfg.stim.nTrained / 2;
  % minimum number of trials needed between exact repeats of a given
  % stimulus as stim2
  cfg.stim.(sesName).match.stim2MinRepeatSpacing = 2;
  % whether to have "same" and "diff" text with the response prompt
  cfg.stim.(sesName).match.matchTextPrompt = matchTextPrompt;
  
  % rmStims_orig is true because we're using half of stimuli in each cond
  cfg.stim.(sesName).match.rmStims_orig = true;
  % rmStims_pair is true because pairs are removed after they're added
  cfg.stim.(sesName).match.rmStims_pair = true;
  cfg.stim.(sesName).match.shuffleFirst = true;
  
  % durations, in seconds
  cfg.stim.(sesName).match.isi = 0.5;
  cfg.stim.(sesName).match.stim1 = 0.8;
  cfg.stim.(sesName).match.stim2 = 0.8;
  % % random intervals are generated on the fly
  % cfg.stim.(sesName).match.preStim1 = 0.5 to 0.7;
  % cfg.stim.(sesName).match.preStim2 = 1.0 to 1.2;
  % % % Not setting a response time limit
  % cfg.stim.(sesName).match.response = 1.0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 2-6 configuration (all these days are the same)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesNames = {'train2','train3','train4','train5','train6'};
  
  for s = 1:length(sesNames)
    sesName = sesNames{s};
    
    % Matching 1
    
    matchNum = 1;
    cfg.stim.(sesName).match(matchNum).nSame = cfg.stim.nTrained / 2;
    cfg.stim.(sesName).match(matchNum).nDiff = cfg.stim.nTrained / 2;
    cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing = 2;
    % whether to have "same" and "diff" text with the response prompt
    cfg.stim.(sesName).match(matchNum).matchTextPrompt = matchTextPrompt;
    
    % rmStims_orig is true because we're using half of stimuli in each cond
    cfg.stim.(sesName).match(matchNum).rmStims_orig = true;
    % rmStims_pair is true because pairs are removed after they're added
    cfg.stim.(sesName).match(matchNum).rmStims_pair = true;
    cfg.stim.(sesName).match(matchNum).shuffleFirst = true;
    
    % durations, in seconds
    cfg.stim.(sesName).match(matchNum).isi = 0.5;
    cfg.stim.(sesName).match(matchNum).stim1 = 0.8;
    cfg.stim.(sesName).match(matchNum).stim2 = 0.8;
    % % random intervals are generated on the fly
    % cfg.stim.(sesName).match(matchNum).preStim1 = 0.5 to 0.7;
    % cfg.stim.(sesName).match(matchNum).preStim2 = 1.0 to 1.2;
    % % % Not setting a response time limit
    % cfg.stim.(sesName).match(matchNum).response = 1.0;
    
    % Naming
    
    % maximum number of repeated exemplars from each family in naming
    cfg.stim.(sesName).name.nameMaxConsecFamily = 3;
    
    % durations, in seconds
    cfg.stim.(sesName).name.name_isi = 0.5;
    % cfg.stim.(sesName).name.name_preStim = 0.5 to 0.7;
    cfg.stim.(sesName).name.name_stim = 1.0;
    cfg.stim.(sesName).name.name_response = 2.0;
    cfg.stim.(sesName).name.name_feedback = 1.0;
    
    % do we want to play feedback beeps?
    cfg.stim.(sesName).name.playSound = playSound;
    cfg.stim.(sesName).name.correctSound = correctSound;
    cfg.stim.(sesName).name.incorrectSound = incorrectSound;
    
    % Matching 2
    
    matchNum = 2;
    cfg.stim.(sesName).match(matchNum).nSame = cfg.stim.nTrained / 2;
    cfg.stim.(sesName).match(matchNum).nDiff = cfg.stim.nTrained / 2;
    cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing = 2;
    % whether to have "same" and "diff" text with the response prompt
    cfg.stim.(sesName).match(matchNum).matchTextPrompt = matchTextPrompt;
    
    % rmStims_orig is true because we're using half of stimuli in each cond
    cfg.stim.(sesName).match(matchNum).rmStims_orig = true;
    % rmStims_pair is true because pairs are removed after they're added
    cfg.stim.(sesName).match(matchNum).rmStims_pair = true;
    cfg.stim.(sesName).match(matchNum).shuffleFirst = true;
    
    % durations, in seconds
    cfg.stim.(sesName).match(matchNum).isi = 0.5;
    cfg.stim.(sesName).match(matchNum).stim1 = 0.8;
    cfg.stim.(sesName).match(matchNum).stim2 = 0.8;
    % % random intervals are generated on the fly
    % cfg.stim.(sesName).match(matchNum).preStim1 = 0.5 to 0.7;
    % cfg.stim.(sesName).match(matchNum).preStim2 = 1.0 to 1.2;
    % % % Not setting a response time limit
    % cfg.stim.(sesName).match(matchNum).response = 1.0;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Posttest configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'posttest';
  
  % Matching
  
  % every stimulus is in both the same and the different condition.
  cfg.stim.(sesName).match.nSame = cfg.stim.nTrained;
  cfg.stim.(sesName).match.nDiff = cfg.stim.nTrained;
  cfg.stim.(sesName).match.stim2MinRepeatSpacing = 2;
  % whether to have "same" and "diff" text with the response prompt
  cfg.stim.(sesName).match.matchTextPrompt = matchTextPrompt;
  
  % rmStims_orig is false because all stimuli are used in both 'same' and
  % 'diff' conditions
  cfg.stim.(sesName).match.rmStims_orig = false;
  % rmStims_pair is true because pairs are removed after they're added
  cfg.stim.(sesName).match.rmStims_pair = true;
  cfg.stim.(sesName).match.shuffleFirst = true;
  
  % durations, in seconds
  cfg.stim.(sesName).match.isi = 0.5;
  cfg.stim.(sesName).match.stim1 = 0.8;
  cfg.stim.(sesName).match.stim2 = 0.8;
  % % random intervals are generated on the fly
  % cfg.stim.(sesName).match.preStim1 = 0.5 to 0.7;
  % cfg.stim.(sesName).match.preStim2 = 1.0 to 1.2;
  % % Not setting a response time limit
  % cfg.stim.(sesName).match.response = 1.0;
  
  % Recognition
  
  % number of target and lure stimuli. Assumes all targets and lures are
  % tested.
  cfg.stim.(sesName).recog.nStudyTarg = 2;
  cfg.stim.(sesName).recog.nTestLure = 1;
  % maximum number of same family in a row during study task
  cfg.stim.(sesName).recog.studyMaxConsecFamily = 0;
  % maximum number of targets or lures in a row during test task
  cfg.stim.(sesName).recog.testMaxConsec = 0;
  
  % do not reuse recognition stimuli in other parts of the experiment
  cfg.stim.(sesName).recog.rmStims = true;
  cfg.stim.(sesName).recog.shuffleFirst = true;
  
  % task parameters
  cfg.stim.(sesName).recog.nBlocks = 8;
  cfg.stim.(sesName).recog.nTargPerBlock = 40;
  cfg.stim.(sesName).recog.nLurePerBlock = 20;
  
  % durations, in seconds
  cfg.stim.(sesName).recog.study_isi = 0.8;
  cfg.stim.(sesName).recog.study_preTarg = 0.2;
  cfg.stim.(sesName).recog.study_targ = 2.0;
  cfg.stim.(sesName).recog.test_isi = 0.8;
  cfg.stim.(sesName).recog.test_preStim = 0.2;
  cfg.stim.(sesName).recog.test_stim = 1.5;
  % % Not setting a response time limit
  % cfg.stim.(sesName).recog.response = 1.5;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Posttest Delayed configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'posttest_delay';
  
  % Matching
  
  % every stimulus is in both the same and the different condition.
  cfg.stim.(sesName).match.nSame = cfg.stim.nTrained;
  cfg.stim.(sesName).match.nDiff = cfg.stim.nTrained;
  cfg.stim.(sesName).match.stim2MinRepeatSpacing = 2;
  % whether to have "same" and "diff" text with the response prompt
  cfg.stim.(sesName).match.matchTextPrompt = matchTextPrompt;
  
  % rmStims_orig is false because all stimuli are used in both 'same' and
  % 'diff' conditions
  cfg.stim.(sesName).match.rmStims_orig = false;
  % rmStims_pair is true because pairs are removed after they're added
  cfg.stim.(sesName).match.rmStims_pair = true;
  cfg.stim.(sesName).match.shuffleFirst = true;
  
  % durations, in seconds
  cfg.stim.(sesName).match.isi = 0.5;
  cfg.stim.(sesName).match.stim1 = 0.8;
  cfg.stim.(sesName).match.stim2 = 0.8;
  % % random intervals are generated on the fly
  % cfg.stim.(sesName).match.preStim1 = 0.5 to 0.7;
  % cfg.stim.(sesName).match.preStim2 = 1.0 to 1.2;
  % % Not setting a response time limit
  % cfg.stim.(sesName).match.response = 1.0;
  
  % Recognition
  
  % number of target and lure stimuli. Assumes all targets and lures are
  % tested.
  cfg.stim.(sesName).recog.nStudyTarg = 2;
  cfg.stim.(sesName).recog.nTestLure = 1;
  % maximum number of same family in a row during study task
  cfg.stim.(sesName).recog.studyMaxConsecFamily = 0;
  % maximum number of targets or lures in a row during test task
  cfg.stim.(sesName).recog.testMaxConsec = 0;
  
  % do not reuse recognition stimuli in other parts of the experiment
  cfg.stim.(sesName).recog.rmStims = true;
  cfg.stim.(sesName).recog.shuffleFirst = true;
  
  % task parameters
  cfg.stim.(sesName).recog.nBlocks = 8;
  cfg.stim.(sesName).recog.nTargPerBlock = 40;
  cfg.stim.(sesName).recog.nLurePerBlock = 20;
  
  % durations, in seconds
  cfg.stim.(sesName).recog.study_isi = 0.8;
  cfg.stim.(sesName).recog.study_preTarg = 0.2;
  cfg.stim.(sesName).recog.study_targ = 2.0;
  cfg.stim.(sesName).recog.test_isi = 0.8;
  cfg.stim.(sesName).recog.test_preStim = 0.2;
  cfg.stim.(sesName).recog.test_stim = 1.5;
  % % Not setting a response time limit
  % cfg.stim.(sesName).recog.response = 1.5;
  
  %% process the stimuli for the entire experiment
  
  [expParam] = et_processStims_EBUG(cfg,expParam);
  
  %% save the parameters
  
  fprintf('Saving experiment parameters: %s...',cfg.files.expParamFile);
  save(cfg.files.expParamFile,'cfg','expParam');
  fprintf('Done.\n');
  
end

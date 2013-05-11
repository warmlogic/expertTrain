function [cfg,expParam] = config_EBUG(cfg,expParam)
% function [cfg,expParam] = config_EBUG(cfg,expParam)
%
% Description:
%  Configuration function for creature expertise training experiment. This
%  file should be edited for your particular experiment. This function runs
%  process_EBUG_stimuli to prepare the stimuli for experiment presentation.
%
% see also: et_saveStimList, process_EBUG_stimuli

%% Experiment session information

% set up configuration structures to keep track of what day and phase we're
% on.

expParam.nSessions = 9;

% Pre-test, training day 1, training days 2-6, post-test, post-test delayed.
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

% session number is incremented after the run, so after the final
% session has been run it will be 1 greater than expParam.nSessions
if expParam.sessionNum <= expParam.nSessions
  fprintf('Starting session %d (%s).\n',expParam.sessionNum,expParam.sesTypes{expParam.sessionNum});
else
  error('All %s sessions have already been run!',expParam.nSessions);
end

%% If this is session 1, setup the experiment

if expParam.sessionNum == 1
  
  %% Subject parameters
  
  % for counterbalancing
  if mod(str2double(expParam.subject(end)),2) == 0
    expParam.isEven = true;
  else
    expParam.isEven = false;
  end
  if str2double(expParam.subject(end)) >= 1 && str2double(expParam.subject(end)) <= 5
    expParam.is15 = true;
  else
    expParam.is15 = false;
  end
  
  %% Stimulus parameters
  
  cfg.files.stimFileExt = '.bmp';
  cfg.stim.nFamilies = 2;
  % family names correspond to the directories in which stimuli reside
  cfg.stim.familyNames = {'a','s'};
  % assumes that each family has the same number of species
  cfg.stim.nSpecies = 10;
  % initialize to store the number of exemplars for each species
  cfg.stim.nExemplars = zeros(cfg.stim.nFamilies,cfg.stim.nSpecies);
  
  cfg.files.stimDir = fullfile(cfg.files.expDir,'images','Creatures');
  % save an individual stimulus list for each subject
  cfg.stim.file = fullfile(cfg.files.subSaveDir,'stimList.txt');
  
  % create the stimulus list if it doesn't exist
  shuffleSpecies = true;
  if ~exist(cfg.stim.file,'file')
    [cfg] = et_saveStimList(cfg,shuffleSpecies);
  else
    % debug = warning instead of error
    warning('Stimulus list should not exist at the beginning of Session %d: %s',cfg.stim.file,expParam.sessionNum);
    %error('Stimulus list should not exist at the beginning of Session %d: %s',cfg.stim.file,expParam.sessionNum);
  end
  
  % basic/subordinate families (counterbalance based on even/odd subNum)
  if expParam.isEven
    cfg.stim.famNumBasic = 1;
    cfg.stim.famNumSubord = 2;
  else
    cfg.stim.famNumBasic = 2;
    cfg.stim.famNumSubord = 1;
  end
  
  % Number of trained and untrained per species per family
  cfg.stim.nTrained = 6;
  cfg.stim.nUntrained = 6;
  
  %% Define the response keys
  
  % TODO: do we want the key order to be yoked to the training day 1 order
  % in the viewname task?
  
  % use spacebar for naming "other" family (basic-level naming)
  cfg.keys.otherKeyNames = {'space'};
  for i = 1:length(cfg.keys.otherKeyNames)
    cfg.keys.(sprintf('s%.2d',i-1)) = KbName(cfg.keys.otherKeyNames{i});
  end
  
  % keys for naming particular species (subordinate-level naming)
  
  % % I can't get PTB to use the semicolon
  %cfg.keys.speciesKeyNames = {'a','s','d','f','v','n','j','k','l','semicolon'};
  cfg.keys.speciesKeyNames = {'a','s','d','f','v','b','h','j','k','l'};
  
  % % only set the keys in a random order once per subject
  % cfg.keys.randKeyOrder = randperm(length(cfg.keys.speciesKeyNames));
  % % % debug - not randomized
  % % cfg.keys.randKeyOrder = 1:length(cfg.keys.speciesKeyNames);
  % % fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  
  % % subordinate family species number indices
  % cfg.stim.specNumInd(famNumSubord,:)
  
  % set the species keys
  for i = 1:length(cfg.keys.speciesKeyNames)
    % sXX, where XX is an integer, buffered with a zero if i <= 9
    %cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeyNames{cfg.keys.randKeyOrder(i)});
    cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeyNames{i});
  end
  
  % subordinate matching keys (counterbalanced based on subNum 1-5, 6-0)
  cfg.keys.matchKeyNames = {'f','h'};
  if expParam.is15
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{1});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{2});
  else
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{2});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{1});
  end
  
  % recognition keys (not counterbalanced)
  cfg.keys.recogKeyNames = {'a','s','d','f','h'};
  cfg.keys.recogDefUn = KbName(cfg.keys.recogKeyNames{1});
  cfg.keys.recogMayUn = KbName(cfg.keys.recogKeyNames{2});
  cfg.keys.recogMayF = KbName(cfg.keys.recogKeyNames{3});
  cfg.keys.recogDefF = KbName(cfg.keys.recogKeyNames{4});
  cfg.keys.recogRecoll = KbName(cfg.keys.recogKeyNames{5});
  
  % % recognition keys (counterbalanced based on even/odd and 1-5, 6-10)
  % cfg.keys.recogKeyNames = {'f','h'};
  % if expParam.isEven && expParam.is15 || ~expParam.isEven && ~expParam.is15
  %   cfg.keys.recogOld = KbName(cfg.keys.recogKeyNames{1});
  %   cfg.keys.recogNew = KbName(cfg.keys.recogKeyNames{2});
  % elseif expParam.isEven && ~expParam.is15 || ~expParam.isEven && expParam.is15
  %   cfg.keys.recogOld = KbName(cfg.keys.recogKeyNames{2});
  %   cfg.keys.recogNew = KbName(cfg.keys.recogKeyNames{1});
  % end
  
  % TODO: 5 responses: definitely/maybe unfamiliar/familiar, and recollect;
  %       a, s, d, f, h
  
  %% Session/phase configuration
  
  % TODO: add text size informaiton for instructions and on-screen text
  
  % Define text size (TODO: fix for this experiment)
  cfg.text.txtsize_instruct = 35;
  cfg.text.txtsize_break = 28;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % pretest configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching
  
  % every stimulus is in both the same and the different condition.
  cfg.stim.pretest.match.nSame = cfg.stim.nTrained;
  cfg.stim.pretest.match.nDiff = cfg.stim.nTrained;
  % minimum number of trials needed between exact repeats of a given
  % stimulus as stim2
  cfg.stim.pretest.match.stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.pretest.match.isi = 0.5;
  cfg.stim.pretest.match.stim1 = 0.8;
  cfg.stim.pretest.match.stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.pretest.match.preStim1 = 0.5 to 0.7;
  %cfg.stim.pretest.match.preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.pretest.match.response = 1.0;
  
  % Recognition
  
  % number of target and lure stimuli per species per family per study/test
  % block. Assumes all targets and lures are tested in a block.
  cfg.stim.pretest.recog.nStudyTarg = 2;
  cfg.stim.pretest.recog.nTestLure = 1;
  % maximum number of same family in a row during study task
  cfg.stim.pretest.recog.studyMaxConsecFamily = 0;
  % maximum number of targets or lures in a row during test task
  cfg.stim.pretest.recog.testMaxConsec = 0;
  
  % task parameters
  cfg.stim.pretest.recog.nBlocks = 8;
  cfg.stim.pretest.recog.nTargPerBlock = 40;
  cfg.stim.pretest.recog.nLurePerBlock = 20;
  
  % durations, in seconds
  cfg.stim.pretest.recog.study_isi = 0.8;
  cfg.stim.pretest.recog.study_preTarg = 0.2;
  cfg.stim.pretest.recog.test_isi = 0.8;
  cfg.stim.pretest.recog.test_preTarg = 0.2;
  cfg.stim.pretest.recog.test_stim = 1.5;
  % TODO: do we need response?
  cfg.stim.pretest.recog.response = 1.5;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 1 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Viewing+Naming
  
  % hard coded order of which species are presented in each block
  % (counterbalanced)
  cfg.stim.train1.viewname.blockSpeciesOrder = {...
    [1, 2],[1, 2, 3],[1, 2, 3, 4],[1, 2, 3, 4, 5],[3, 4, 5, 6],...
    [4, 5, 6, 7],[5, 6, 7, 8],[6, 7, 8, 9],[7, 8, 9, 10],...
    [8, 9, 10, 1],[9, 10, 2, 3],[10, 4, 5, 6],[7, 8, 9, 10]};
  % hard coded stimulus indices for viewing and naming block presentation
  % (counterbalanced)
  cfg.stim.train1.viewname.viewIndices = {...
    [1, 1], [4, 4, 1], [2, 2, 4, 1], [5, 5, 2, 4, 1],[5, 2, 4, 1],...
    [5, 2, 4, 1], [5, 2, 4, 1], [5, 2, 4, 1], [5, 2, 4, 1],...
    [5, 2, 4, 3], [5, 2, 3, 3], [5, 2, 3, 3], [3, 3, 3, 3]};
  cfg.stim.train1.viewname.nameIndices = {...
    [2, 3, 2, 3], [5, 6, 5, 6, 2, 3], [3, 4, 3, 4, 5, 6, 2, 3], [1, 6, 1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3],...
    [1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3],...
    [1, 6, 3, 4, 5, 6, 4, 5], [1, 6, 3, 4, 5, 6, 5, 6], [1, 6, 5, 6, 5, 6, 5, 6], [5, 6, 5, 6, 5, 6, 5, 6]};
  
  % number of exemplars per viewing block in viewname; don't need
  %cfg.stim.train1.viewname.exemplarPerView = 1;
  % maximum number of repeated exemplars from each family in viewname/view
  cfg.stim.train1.viewname.viewMaxConsecFamily = 3;
  
  % number of exemplars per naming block in viewname
  cfg.stim.train1.viewname.exemplarPerName = 2;
  % maximum number of repeated exemplars from each family in viewname/name
  cfg.stim.train1.viewname.nameMaxConsecFamily = 3;
  
  % durations, in seconds
  cfg.stim.train1.viewname.view_isi = 0.8;
  cfg.stim.train1.viewname.view_preStim = 0.2;
  cfg.stim.train1.viewname.view_stim = 4.0;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train1.name.nameMaxConsecFamily = 3;
  
  % durations, in seconds
  cfg.stim.train1.name.name_isi = 0.5;
  % cfg.stim.train1.name.name_preStim = 0.5 to 0.7;
  cfg.stim.train1.name.name_stim = 1.0;
  cfg.stim.train1.name.name_response = 2.0;
  cfg.stim.train1.name.name_feedback = 1.0;
  
  % Matching
  
  % number per species per family (half because each stimulus is only in
  % same or different condition)
  cfg.stim.train1.match.nSame = cfg.stim.nTrained / 2;
  cfg.stim.train1.match.nDiff = cfg.stim.nTrained / 2;
  % minimum number of trials needed between exact repeats of a given
  % stimulus as stim2
  cfg.stim.train1.match.stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train1.match.isi = 0.5;
  cfg.stim.train1.match.stim1 = 0.8;
  cfg.stim.train1.match.stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train1.match.preStim1 = 0.5 to 0.7;
  %cfg.stim.train1.match.preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train1.match.response = 1.0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 2 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  
  matchNum = 1;
  cfg.stim.train2.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train2.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train2.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train2.match(matchNum).isi = 0.5;
  cfg.stim.train2.match(matchNum).stim1 = 0.8;
  cfg.stim.train2.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train2.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train2.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train2.match(matchNum).response = 1.0;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train2.name.nameMaxConsecFamily = 3;
  
  % durations, in seconds
  cfg.stim.train2.name.name_isi = 0.5;
  % cfg.stim.train2.name.name_preStim = 0.5 to 0.7;
  cfg.stim.train2.name.name_stim = 1.0;
  cfg.stim.train2.name.name_response = 2.0;
  cfg.stim.train2.name.name_feedback = 1.0;
  
  % Matching 2
  
  matchNum = 2;
  cfg.stim.train2.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train2.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train2.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train2.match(matchNum).isi = 0.5;
  cfg.stim.train2.match(matchNum).stim1 = 0.8;
  cfg.stim.train2.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train2.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train2.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train2.match(matchNum).response = 1.0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 3 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  
  matchNum = 1;
  cfg.stim.train3.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train3.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train3.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train3.match(matchNum).isi = 0.5;
  cfg.stim.train3.match(matchNum).stim1 = 0.8;
  cfg.stim.train3.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train3.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train3.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train3.match(matchNum).response = 1.0;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train3.name.nameMaxConsecFamily = 3;
  
  % durations, in seconds
  cfg.stim.train3.name.name_isi = 0.5;
  % cfg.stim.train3.name.name_preStim = 0.5 to 0.7;
  cfg.stim.train3.name.name_stim = 1.0;
  cfg.stim.train3.name.name_response = 2.0;
  cfg.stim.train3.name.name_feedback = 1.0;
  
  % Matching 2
  
  matchNum = 2;
  cfg.stim.train3.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train3.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train3.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train3.match(matchNum).isi = 0.5;
  cfg.stim.train3.match(matchNum).stim1 = 0.8;
  cfg.stim.train3.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train3.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train3.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train3.match(matchNum).response = 1.0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 4 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  
  matchNum = 1;
  cfg.stim.train4.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train4.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train4.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train4.match(matchNum).isi = 0.5;
  cfg.stim.train4.match(matchNum).stim1 = 0.8;
  cfg.stim.train4.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train4.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train4.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train4.match(matchNum).response = 1.0;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train4.name.nameMaxConsecFamily = 3;
  
  % durations, in seconds
  cfg.stim.train4.name.name_isi = 0.5;
  % cfg.stim.train4.name.name_preStim = 0.5 to 0.7;
  cfg.stim.train4.name.name_stim = 1.0;
  cfg.stim.train4.name.name_response = 2.0;
  cfg.stim.train4.name.name_feedback = 1.0;
  
  % Matching 2
  
  matchNum = 2;
  cfg.stim.train4.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train4.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train4.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train4.match(matchNum).isi = 0.5;
  cfg.stim.train4.match(matchNum).stim1 = 0.8;
  cfg.stim.train4.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train4.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train4.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train4.match(matchNum).response = 1.0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 5 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  
  matchNum = 1;
  cfg.stim.train5.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train5.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train5.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train5.match(matchNum).isi = 0.5;
  cfg.stim.train5.match(matchNum).stim1 = 0.8;
  cfg.stim.train5.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train5.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train5.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train5.match(matchNum).response = 1.0;
  
  % Naming
  
  % durations, in seconds
  cfg.stim.train5.name.name_isi = 0.5;
  % cfg.stim.train5.name.name_preStim = 0.5 to 0.7;
  cfg.stim.train5.name.name_stim = 1.0;
  cfg.stim.train5.name.name_response = 2.0;
  cfg.stim.train5.name.name_feedback = 1.0;
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train5.name.nameMaxConsecFamily = 3;
  
  % Matching 2
  
  matchNum = 2;
  cfg.stim.train5.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train5.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train5.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train5.match(matchNum).isi = 0.5;
  cfg.stim.train5.match(matchNum).stim1 = 0.8;
  cfg.stim.train5.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train5.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train5.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train5.match(matchNum).response = 1.0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Training Day 6 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  
  matchNum = 1;
  cfg.stim.train6.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train6.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train6.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train6.match(matchNum).isi = 0.5;
  cfg.stim.train6.match(matchNum).stim1 = 0.8;
  cfg.stim.train6.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train6.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train6.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train6.match(matchNum).response = 1.0;
  
  % Naming
  
  % durations, in seconds
  cfg.stim.train6.name.name_isi = 0.5;
  % cfg.stim.train6.name.name_preStim = 0.5 to 0.7;
  cfg.stim.train6.name.name_stim = 1.0;
  cfg.stim.train6.name.name_response = 2.0;
  cfg.stim.train6.name.name_feedback = 1.0;
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train6.name.nameMaxConsecFamily = 3;
  
  % Matching 2
  
  matchNum = 2;
  cfg.stim.train6.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train6.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  cfg.stim.train6.match(matchNum).stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.train6.match(matchNum).isi = 0.5;
  cfg.stim.train6.match(matchNum).stim1 = 0.8;
  cfg.stim.train6.match(matchNum).stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.train6.match(matchNum).preStim1 = 0.5 to 0.7;
  %cfg.stim.train6.match(matchNum).preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.train6.match(matchNum).response = 1.0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Posttest configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching
  
  % every stimulus is in both the same and the different condition.
  cfg.stim.posttest.match.nSame = cfg.stim.nTrained;
  cfg.stim.posttest.match.nDiff = cfg.stim.nTrained;
  cfg.stim.posttest.match.stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.posttest.match.isi = 0.5;
  cfg.stim.posttest.match.stim1 = 0.8;
  cfg.stim.posttest.match.stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.posttest.match.preStim1 = 0.5 to 0.7;
  %cfg.stim.posttest.match.preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.posttest.match.response = 1.0;
  
  % Recognition
  
  % number of target and lure stimuli. Assumes all targets and lures are
  % tested.
  cfg.stim.posttest.recog.nStudyTarg = 2;
  cfg.stim.posttest.recog.nTestLure = 1;
  % maximum number of same family in a row during study task
  cfg.stim.posttest.recog.studyMaxConsecFamily = 0;
  % maximum number of targets or lures in a row during test task
  cfg.stim.posttest.recog.testMaxConsec = 0;
  
  % task parameters
  cfg.stim.posttest.recog.nBlocks = 8;
  cfg.stim.posttest.recog.nTargPerBlock = 40;
  cfg.stim.posttest.recog.nLurePerBlock = 20;
  
  % durations, in seconds
  cfg.stim.posttest.recog.study_isi = 0.8;
  cfg.stim.posttest.recog.study_preTarg = 0.2;
  cfg.stim.posttest.recog.test_isi = 0.8;
  cfg.stim.posttest.recog.test_preTarg = 0.2;
  cfg.stim.posttest.recog.test_stim = 1.5;
  % TODO: do we need response?
  cfg.stim.posttest.recog.response = 1.5;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Posttest Delayed configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Matching
  
  % every stimulus is in both the same and the different condition.
  cfg.stim.posttest_delay.match.nSame = cfg.stim.nTrained;
  cfg.stim.posttest_delay.match.nDiff = cfg.stim.nTrained;
  cfg.stim.posttest_delay.match.stim2MinRepeatSpacing = 2;
  
  % durations, in seconds
  cfg.stim.posttest_delay.match.isi = 0.5;
  cfg.stim.posttest_delay.match.stim1 = 0.8;
  cfg.stim.posttest_delay.match.stim2 = 0.8;
  % random intervals are generated on the fly
  %cfg.stim.posttest_delay.match.preStim1 = 0.5 to 0.7;
  %cfg.stim.posttest_delay.match.preStim2 = 1.0 to 1.2;
  % TODO: do we need response?
  cfg.stim.posttest_delay.match.response = 1.0;
  
  % Recognition
  
  % number of target and lure stimuli. Assumes all targets and lures are
  % tested.
  cfg.stim.posttest_delay.recog.nStudyTarg = 2;
  cfg.stim.posttest_delay.recog.nTestLure = 1;
  % maximum number of same family in a row during study task
  cfg.stim.posttest_delay.recog.studyMaxConsecFamily = 0;
  % maximum number of targets or lures in a row during test task
  cfg.stim.posttest_delay.recog.testMaxConsec = 0;
  
  % task parameters
  cfg.stim.posttest_delay.recog.nBlocks = 8;
  cfg.stim.posttest_delay.recog.nTargPerBlock = 40;
  cfg.stim.posttest_delay.recog.nLurePerBlock = 20;
  
  % durations, in seconds
  cfg.stim.posttest_delay.recog.study_isi = 0.8;
  cfg.stim.posttest_delay.recog.study_preTarg = 0.2;
  cfg.stim.posttest_delay.recog.test_isi = 0.8;
  cfg.stim.posttest_delay.recog.test_preTarg = 0.2;
  cfg.stim.posttest_delay.recog.test_stim = 1.5;
  % TODO: do we need response?
  cfg.stim.posttest_delay.recog.response = 1.5;
  
  %% process the stimuli for the entire experiment
  
  [expParam] = process_EBUG_stimuli(cfg,expParam);
  
  %% save the parameters
  
  fprintf('Saving experiment parameters: %s...',cfg.files.expParamFile);
  save(cfg.files.expParamFile,'cfg','expParam');
  fprintf('Done.\n');
  
end

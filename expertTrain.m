function expertTrain(subject)

% function expertTrain(subject)
%
% expertise training experiment
%
% 4 potential phases:
%  - Subordinate matching task
%  - Old/new recognition (example: OldNewRecogExp)
%  - Passive viewing (with confirmatory button press. what happens if they
%    press the wrong button?)
%  - Active naming
%
% Controlled by a cfg struct

% TODO: also have config file be an input argument

% TODO: Net Station integration http://docs.psychtoolbox.org/NetStation

%% any preliminary stuff

% bring the command window to the front
%commandwindow

% Clear Matlab/Octave window:
%clc
home

% check for Opengl compatibility, abort otherwise:
AssertOpenGL;

% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');

% Reseed the random-number generator for each experiment:
rng('shuffle');

%% Experiment database struct preparation

expParam = struct;

% TODO: read a config file with expName and session info below. expName
% line becomes unnecessary here, but needs to go before checking on subject
% and directories for saving data.

expParam.expName = 'ECRE'; % expertise - creature
% expParam.expName = 'EBRD'; % expertise - bird

%% start setting up config struct

cfg = struct;

% get screen dimensions
cfg.screenXY = get(0,'ScreenSize');
cfg.screenXY = cfg.screenXY(3:4); % e.g., [1440 900]
% % debug
% cfg.exp.screenXY = [1440 900];

% Set up the gray color value to be used
cfg.exp.gray = 181;

%% Set up the subject number and data

% debug
cd('/Users/matt/Documents/experiments/expertTrain');
subject = 'ECRE001';

if ~strcmp(subject(1:length(expParam.expName)),expParam.expName)
  error('Subject number must be in the format %sXXX (e.g., %s%.3d). You entered %s.',expParam.expName,expParam.expName,1,subject);
else
  subNum = strrep(subject,expParam.expName,'');
  if length(subNum) ~= 3
    error('Subject number must be in the format %sXXX (e.g., %s%.3d). You entered %s.',expParam.expName,expParam.expName,1,subject);
  else
    subNum = str2double(subNum);
    if isempty(subNum) || ~isreal(subNum) || subNum <= 0
      error('Subject number must be in the format %sXXX (e.g., %s%.3d). You entered %s.',expParam.expName,expParam.expName,1,subject);
    end
  end
end

% store the subject number
expParam.subject = subject;

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

% need to be in the experiment directory to run it
cfg.files.expDir = pwd;

% make sure the data directory exists, and that we can save data
cfg.files.dataSaveDir = fullfile(cfg.files.expDir,'data');
if ~exist(cfg.files.dataSaveDir,'dir')
  [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.dataSaveDir);
  if canSaveData == false
    error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
  end
end

% make sure subject directory exists
cfg.files.subSaveDir = fullfile(cfg.files.dataSaveDir,expParam.subject);
if ~exist(cfg.files.subSaveDir,'dir')
  [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.subSaveDir);
  if canSaveData == false
    error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
  end
end

% set name of the file for saving experiment parameters
cfg.files.expParamFile = fullfile(cfg.files.subSaveDir,'experimentParams.mat');
if exist(cfg.files.expParamFile,'file')
  % if it exists that means this subject has already run a session
  load(cfg.files.expParamFile);
else
  % if it doesn't exist that means we're starting a new subject
  expParam.sessionNum = 1;
end

%% Experiment session information

% set up configuration structures to keep track of what day and phase we're
% on.

% TODO: put this in a config file

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

%% make sure the session number is in order and directories/files exist

if expParam.sessionNum > expParam.nSessions
  % session number is incremented after the run, so after the final
  % session has been run it will be 1 greater than expParam.nSessions
  error('All %s sessions have already been run!',expParam.nSessions);
else
  fprintf('Starting session %d (%s).\n',expParam.sessionNum,expParam.sesTypes{expParam.sessionNum});
end

% make sure session directory exists
cfg.files.sesSaveDir = fullfile('data',expParam.subject,sprintf('session_%d',expParam.sessionNum));
if ~exist(cfg.files.sesSaveDir,'dir')
  [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.sesSaveDir);
  if canSaveData == false
    error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
  end
end
% set name of the session log file
cfg.files.sesLogFile = fullfile(cfg.files.sesSaveDir,'session.log');
if exist(cfg.files.sesLogFile,'file')
  error('Log file for this session already exists (%s). Resume support is not yet enabled.',cfg.files.sesLogFile);
end

%% Stimulus parameters

cfg.files.stimDir = fullfile(cfg.files.expDir,'images','Creatures');
cfg.stim.file = fullfile(cfg.files.stimDir,'stimList.txt');

% create the stimulus list if it doesn't exist
if ~exist(cfg.stim.file,'file')
  cfg = et_saveStimList(cfg);
end

%% make an initial save of experiment data
save(cfg.files.expParamFile,'cfg','expParam');

%% If this is session 1, setup the experiment

if expParam.sessionNum == 1
  
  %% Define the response keys
  
  % TODO: do we want the key order to be yoked to the training day 1 order
  % in the viewname task?
  
  % keys for naming species (subordinate-level naming)
  
  % % I can't get PTB to use the semicolon
  %cfg.keys.possibleKeys = {'a','s','d','f','v','n','j','k','l','semicolon'};
  cfg.keys.speciesKeys = {'a','s','d','f','v','b','h','j','k','l'};
  
  % only set the keys in a random order once per subject
  cfg.keys.randKeyOrder = randperm(length(cfg.keys.speciesKeys));
  % % debug - not randomized
  % cfg.keys.randKeyOrder = 1:length(cfg.keys.speciesKeys);
  % fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  
  % use spacebar for naming "other" family (basic-level naming)
  cfg.keys.s00 = KbName('space');
  
  % set the species keys
  for i = 1:length(cfg.keys.speciesKeys)
    % sXX, where XX is an integer, buffered with a zero if i <= 9
    cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeys{cfg.keys.randKeyOrder(i)});
  end
  
  %% Stimulus basics
  
  cfg.files.stimFileExt = '.bmp';
  cfg.stim.nFamilies = 2;
  % family names correspond to the directories in which stimuli reside
  cfg.stim.familyNames = {'a','s'};
  % assumes that each family has the same number of species
  cfg.stim.nSpecies = 10;
  % initialize to store the number of exemplars for each species
  cfg.stim.nExemplars = zeros(cfg.stim.nFamilies,cfg.stim.nSpecies);
  
  % counterbalance basic and subordinate families based on subject num
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
  
  %% Session/phase configuration
  
  % TODO: add event timing information
  
  
  % TODO: add text size informaiton for instructions and on-screen text
  
  % Define text size (TODO: fix for this experiment)
  cfg.exp.txtsize_instruct = 35;
  cfg.exp.txtsize_break = 28;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % pretest configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching: every stimulus is in both the same and the different
  % condition.
  cfg.stim.pretest.match.nSame = cfg.stim.nTrained;
  cfg.stim.pretest.match.nDiff = cfg.stim.nTrained;
  % minimum number of trials needed between exact repeats of a given
  % stimulus as stim2
  cfg.stim.pretest.match.stim2MinRepeatSpacing = 2;
  
  % Recognition: number of target and lure stimuli (assumes all targets
  % are lures are tested)
  cfg.stim.pretest.recog.nStudyTarg = 16;
  cfg.stim.pretest.recog.nTestLure = 8;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Training Day 1 configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Viewing+Naming
  
  % number of exemplars per viewing block in viewname; don't need
  %cfg.stim.train1.viewname.exemplarPerView = 1;
  % maximum number of repeated exemplars from each family in viewname
  cfg.stim.train1.viewname.viewMaxConsecFamily = 3;
  
  % number of exemplars per naming block in viewname
  cfg.stim.train1.viewname.exemplarPerName = 2;
  % maximum number of repeated exemplars from each family in viewname
  cfg.stim.train1.viewname.nameMaxConsecFamily = 3;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train1.name.nameMaxConsecFamily = 3;
  
  % Matching
  
  % number per species per family (half because each stimulus is only in
  % same or different condition)
  cfg.stim.train1.match.nSame = cfg.stim.nTrained / 2;
  cfg.stim.train1.match.nDiff = cfg.stim.nTrained / 2;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Training Day 2 configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  matchNum = 1;
  cfg.stim.train2.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train2.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train2.name.nameMaxConsecFamily = 3;
  
  % Matching
  matchNum = 2;
  cfg.stim.train2.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train2.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Training Day 3 configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  matchNum = 1;
  cfg.stim.train3.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train3.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train3.name.nameMaxConsecFamily = 3;
  
  % Matching
  matchNum = 2;
  cfg.stim.train3.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train3.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Training Day 4 configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  matchNum = 1;
  cfg.stim.train4.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train4.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train4.name.nameMaxConsecFamily = 3;
  
  % Matching
  matchNum = 2;
  cfg.stim.train4.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train4.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Training Day 5 configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  matchNum = 1;
  cfg.stim.train5.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train5.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train5.name.nameMaxConsecFamily = 3;
  
  % Matching
  matchNum = 2;
  cfg.stim.train5.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train5.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Training Day 6 configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching 1
  matchNum = 1;
  cfg.stim.train6.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train6.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  % Naming
  
  % maximum number of repeated exemplars from each family in naming
  cfg.stim.train6.name.nameMaxConsecFamily = 3;
  
  % Matching
  matchNum = 2;
  cfg.stim.train6.match(matchNum).nSame = cfg.stim.nTrained / 2;
  cfg.stim.train6.match(matchNum).nDiff = cfg.stim.nTrained / 2;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Posttest configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching: every stimulus is in both the same and the different
  % condition.
  cfg.stim.posttest.match.nSame = cfg.stim.nTrained;
  cfg.stim.posttest.match.nDiff = cfg.stim.nTrained;
  
  % Recognition: number of target and lure stimuli (assumes all targets
  % are lures are tested)
  cfg.stim.posttest.recog.nStudyTarg = 16;
  cfg.stim.posttest.recog.nTestLure = 8;
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Posttest Delayed configuration
  %%%%%%%%%%%%%%%%%%%%%%
  
  % Matching: every stimulus is in both the same and the different
  % condition.
  cfg.stim.posttest_delay.match.nSame = cfg.stim.nTrained;
  cfg.stim.posttest_delay.match.nDiff = cfg.stim.nTrained;
  
  % Recognition: number of target and lure stimuli (assumes all targets
  % are lures are tested)
  cfg.stim.posttest_delay.recog.nStudyTarg = 16;
  cfg.stim.posttest_delay.recog.nTestLure = 8;
  
  %% Initial processing of the stimuli
  
  % read in the stimulus list
  fprintf('Loading stimulus list: %s...',cfg.stim.file);
  fid = fopen(cfg.stim.file);
  stimuli = textscan(fid,'%s%s%d%s%d%d%d%d','Delimiter','\t','Headerlines',1);
  fclose(fid);
  fprintf('Done.\n');
  
  % create a structure for each family with all the stim information
  f1Ind = stimuli{3} == 1;
  f1Stim = struct('filename',stimuli{1}(f1Ind),'familyStr',stimuli{2}(f1Ind),'familyNum',num2cell(stimuli{3}(f1Ind)),'speciesStr',stimuli{4}(f1Ind),'speciesNum',num2cell(stimuli{5}(f1Ind)),'exemplarName',num2cell(stimuli{6}(f1Ind)),'exemplarNum',num2cell(stimuli{7}(f1Ind)),'number',num2cell(stimuli{8}(f1Ind)));
  f2Ind = stimuli{3} == 2;
  f2Stim = struct('filename',stimuli{1}(f2Ind),'familyStr',stimuli{2}(f2Ind),'familyNum',num2cell(stimuli{3}(f2Ind)),'speciesStr',stimuli{4}(f2Ind),'speciesNum',num2cell(stimuli{5}(f2Ind)),'exemplarName',num2cell(stimuli{6}(f2Ind)),'exemplarNum',num2cell(stimuli{7}(f2Ind)),'number',num2cell(stimuli{8}(f2Ind)));
  
  %% Decide which will be the trained and untrained stimuli from each family
  
  rmStims = true;
  shuffleFirst = true;
  
  % family 1 trained
  expParam.session.f1Trained = [];
  [f1Stim,expParam.session.f1Trained] = et_divvyStims(...
    f1Stim,[],cfg.stim.nTrained,rmStims,shuffleFirst,{'trained'},{1});
  
  % family 1 untrained
  expParam.session.f1Untrained = [];
  [f1Stim,expParam.session.f1Untrained] = et_divvyStims(...
    f1Stim,[],cfg.stim.nUntrained,rmStims,shuffleFirst,{'trained'},{0});
  
  % family 2 trained
  expParam.session.f2Trained = [];
  [f2Stim,expParam.session.f2Trained] = et_divvyStims(...
    f2Stim,[],cfg.stim.nTrained,rmStims,shuffleFirst,{'trained'},{1});
  
  % family 2 untrained
  expParam.session.f2Untrained = [];
  [f2Stim,expParam.session.f2Untrained] = et_divvyStims(...
    f2Stim,[],cfg.stim.nUntrained,rmStims,shuffleFirst,{'trained'},{0});
  
  %% Pretest
  
  sesName = 'pretest';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  % rmStims_orig is false because we're using all stimuli in both conds
  rmStims_orig = false;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match.same = [];
  expParam.session.(sesName).match.diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % shuffle them together for the experiment
  [expParam.session.(sesName).match.allStims] = et_shuffleStims_match(expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,cfg.stim.(sesName).match.stim2MinRepeatSpacing);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Recognition task
  %%%%%%%%%%%%%%%%%%%%%%
  
  rmStims = true;
  shuffleFirst = true;
  
  % initialize for storing both families together
  expParam.session.(sesName).recog.targ = [];
  expParam.session.(sesName).recog.lure = [];
  
  % family 1
  
  % targets
  [f1Stim,expParam.session.(sesName).recog.targ] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % lures
  [f1Stim,expParam.session.(sesName).recog.lure] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % family 2
  
  % add targets to the existing list
  [f2Stim,expParam.session.(sesName).recog.targ] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.targ,cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % add lures to the existing list
  [f2Stim,expParam.session.(sesName).recog.lure] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.lure,cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  %% Training Day 1
  
  sesName = 'train1';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Viewing+Naming task
  %%%%%%%%%%%%%%%%%%%%%%
  
  % get the stimuli from both families for selection (will shuffle later)
  f1Trained = expParam.session.f1Trained;
  f2Trained = expParam.session.f2Trained;
  
  % randomize the order in which species are added; order is different
  % for each family
  speciesOrder_f1 = randperm(cfg.stim.nSpecies);
  speciesOrder_f2 = randperm(cfg.stim.nSpecies);
  % % debug
  % speciesOrder_f1 = (1:cfg.stim.nSpecies);
  % speciesOrder_f2 = (1:cfg.stim.nSpecies);
  % fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  
  % hard coded order of which species are presented in each block
  % (counterbalanced)
  blockSpeciesOrder = {...
    [1, 2],[1, 2, 3],[1, 2, 3, 4],[1, 2, 3, 4, 5],[3, 4, 5, 6],...
    [4, 5, 6, 7],[5, 6, 7, 8],[6, 7, 8, 9],[7, 8, 9, 10],...
    [8, 9, 10, 1],[9, 10, 2, 3],[10, 4, 5, 6],[7, 8, 9, 10]};
  
  % hard coded stimulus indices for viewing and naming block presentation
  % (counterbalanced)
  viewIndices = {...
    [1, 1], [4, 4, 1], [2, 2, 4, 1], [5, 5, 2, 4, 1],[5, 2, 4, 1],...
    [5, 2, 4, 1], [5, 2, 4, 1], [5, 2, 4, 1], [5, 2, 4, 1],...
    [5, 2, 4, 3], [5, 2, 3, 3], [5, 2, 3, 3], [3, 3, 3, 3]};
  nameIndices = {...
    [2, 3, 2, 3], [5, 6, 5, 6, 2, 3], [3, 4, 3, 4, 5, 6, 2, 3], [1, 6, 1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3],...
    [1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3], [1, 6, 3, 4, 5, 6, 2, 3],...
    [1, 6, 3, 4, 5, 6, 4, 5], [1, 6, 3, 4, 5, 6, 5, 6], [1, 6, 5, 6, 5, 6, 5, 6], [5, 6, 5, 6, 5, 6, 5, 6]};
  
  % initialize viewing and naming cells, one for each block
  expParam.session.(sesName).viewname.view = cell(1,length(blockSpeciesOrder));
  expParam.session.(sesName).viewname.name = cell(1,length(blockSpeciesOrder));
  
  for b = 1:length(blockSpeciesOrder)
    for s = 1:length(blockSpeciesOrder{b})
      % family 1
      sInd_f1 = find([f1Trained.speciesNum] == speciesOrder_f1(blockSpeciesOrder{b}(s)));
      % shuffle the stimulus index
      randind_f1 = randperm(length(sInd_f1));
      % % debug
      % randind_f1 = 1:length(sInd_f1);
      % fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
      
      % shuffle the exemplars
      thisSpecies_f1 = f1Trained(sInd_f1(randind_f1));
      
      % add them to the list
      %fprintf('view f1: block %d, species %d, exemplar %d\n',b,blockSpeciesOrder{b}(s),viewIndices{b}(s));
      expParam.session.(sesName).viewname.view{b} = cat(1,expParam.session.(sesName).viewname.view{b},thisSpecies_f1(viewIndices{b}(s)));
      
      %fprintf('\tname f1: block %d, species %d, exemplar%s\n',b,blockSpeciesOrder{b}(s),sprintf(repmat(' %d',1,length(nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName)))),nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
      expParam.session.(sesName).viewname.name{b} = cat(1,expParam.session.(sesName).viewname.name{b},thisSpecies_f1(nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
      
      % family 2
      sInd_f2 = find([f1Trained.speciesNum] == speciesOrder_f2(blockSpeciesOrder{b}(s)));
      % shuffle the stimulus index
      randind_f2 = randperm(length(sInd_f2));
      % % debug
      % randind_f2 = 1:length(sInd_f2);
      % fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
      
      % shuffle the exemplars
      thisSpecies_f2 = f2Trained(sInd_f2(randind_f2));
      
      % add them to the viewing list
      %fprintf('view f2: block %d, species %d, exemplar %d\n',b,blockSpeciesOrder{b}(s),viewIndices{b}(s));
      % NB: not actually using cfg.stim.(sesName).viewname.exemplarPerView.
      % This needs to be modified if there's more than 1 exemplar per
      % view from a species. Currently "hardcoded" because number of
      % exemplars = viewIndices{b}(s).
      expParam.session.(sesName).viewname.view{b} = cat(1,expParam.session.(sesName).viewname.view{b},thisSpecies_f2(viewIndices{b}(s)));
      
      % add them to the naming list
      %fprintf('\tname f2: block %d, species %d, exemplar%s\n',b,blockSpeciesOrder{b}(s),sprintf(repmat(' %d',1,length(nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName)))),nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
      expParam.session.(sesName).viewname.name{b} = cat(1,expParam.session.(sesName).viewname.name{b},thisSpecies_f2(nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
    end
    
    % if there are more than X consecutive exemplars from the same
    % family, reshuffle. There's probably a better way to do this.
    
    % viewing
    [expParam.session.(sesName).viewname.view{b}] = et_shuffleStims(...
      expParam.session.(sesName).viewname.view{b},'familyNum',cfg.stim.(sesName).viewname.viewMaxConsecFamily);
    % naming
    [expParam.session.(sesName).viewname.name{b}] = et_shuffleStims(...
      expParam.session.(sesName).viewname.name{b},'familyNum',cfg.stim.(sesName).viewname.nameMaxConsecFamily);
    
  end % for each block
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Naming task (all stimuli)
  %%%%%%%%%%%%%%%%%%%%%%
  
  % put all the stimuli together
  expParam.session.(sesName).name.allStim = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
  % Reshuffle. No more than X conecutive exemplars from the same family.
  [expParam.session.(sesName).name.allStim] = et_shuffleStims(...
    expParam.session.(sesName).name.allStim,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match.same = [];
  expParam.session.(sesName).match.diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %% Training Day 2
  
  sesName = 'train2';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 1;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Naming task (all stimuli)
  %%%%%%%%%%%%%%%%%%%%%%
  
  % put all the stimuli together
  expParam.session.(sesName).name.allStim = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
  % Reshuffle. No more than X conecutive exemplars from the same family.
  [expParam.session.(sesName).name.allStim] = et_shuffleStims(...
    expParam.session.(sesName).name.allStim,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 2;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %% Training Day 3
  
  sesName = 'train3';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 1;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Naming task (all stimuli)
  %%%%%%%%%%%%%%%%%%%%%%
  
  % put all the stimuli together
  expParam.session.(sesName).name.allStim = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
  % Reshuffle. No more than X conecutive exemplars from the same family.
  [expParam.session.(sesName).name.allStim] = et_shuffleStims(...
    expParam.session.(sesName).name.allStim,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 2;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %% Training Day 4
  
  sesName = 'train4';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 1;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Naming task (all stimuli)
  %%%%%%%%%%%%%%%%%%%%%%
  
  % put all the stimuli together
  expParam.session.(sesName).name.allStim = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
  % Reshuffle. No more than X conecutive exemplars from the same family.
  [expParam.session.(sesName).name.allStim] = et_shuffleStims(...
    expParam.session.(sesName).name.allStim,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 2;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %% Training Day 5
  
  sesName = 'train5';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 1;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Naming task (all stimuli)
  %%%%%%%%%%%%%%%%%%%%%%
  
  % put all the stimuli together
  expParam.session.(sesName).name.allStim = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
  % Reshuffle. No more than X conecutive exemplars from the same family.
  [expParam.session.(sesName).name.allStim] = et_shuffleStims(...
    expParam.session.(sesName).name.allStim,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 2;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %% Training Day 6
  
  sesName = 'train6';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 1;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Naming task (all stimuli)
  %%%%%%%%%%%%%%%%%%%%%%
  
  % put all the stimuli together
  expParam.session.(sesName).name.allStim = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
  % Reshuffle. No more than X conecutive exemplars from the same family.
  [expParam.session.(sesName).name.allStim] = et_shuffleStims(...
    expParam.session.(sesName).name.allStim,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  matchNum = 2;
  % rmStims_orig is true because we're using half of stimuli in each cond
  rmStims_orig = true;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match(matchNum).same = [];
  expParam.session.(sesName).match(matchNum).diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
    cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %% Posttest
  
  sesName = 'posttest';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  % rmStims_orig is false because we're using all stimuli in both conds
  rmStims_orig = false;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match.same = [];
  expParam.session.(sesName).match.diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Recognition task
  %%%%%%%%%%%%%%%%%%%%%%
  
  rmStims = true;
  shuffleFirst = true;
  
  % initialize for storing both families together
  expParam.session.(sesName).recog.targ = [];
  expParam.session.(sesName).recog.lure = [];
  
  % family 1
  
  % targets
  [f1Stim,expParam.session.(sesName).recog.targ] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % lures
  [f1Stim,expParam.session.(sesName).recog.lure] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % family 2
  
  % add targets to the existing list
  [f2Stim,expParam.session.(sesName).recog.targ] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.targ,cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % add lures to the existing list
  [f2Stim,expParam.session.(sesName).recog.lure] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.lure,cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  %% Posttest Delayed
  
  sesName = 'posttest_delay';
  fprintf('Configuring %s...\n',sesName);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Matching task
  %%%%%%%%%%%%%%%%%%%%%%
  
  % rmStims_orig is false because we're using all stimuli in both conds
  rmStims_orig = false;
  rmStims_pair = true;
  shuffleFirst = true;
  
  % initialize to hold all the same and different stimuli
  expParam.session.(sesName).match.same = [];
  expParam.session.(sesName).match.diff = [];
  
  % family 1 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 1 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f1Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 trained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Trained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  % family 2 untrained
  [expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
    expParam.session.f2Untrained,...
    expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
    cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);
  
  %%%%%%%%%%%%%%%%%%%%%%
  % Recognition task
  %%%%%%%%%%%%%%%%%%%%%%
  
  rmStims = true;
  shuffleFirst = true;
  
  % initialize for storing both families together
  expParam.session.(sesName).recog.targ = [];
  expParam.session.(sesName).recog.lure = [];
  
  % family 1
  
  % targets
  [f1Stim,expParam.session.(sesName).recog.targ] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % lures
  [f1Stim,expParam.session.(sesName).recog.lure] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % family 2
  
  % add targets to the existing list
  [f2Stim,expParam.session.(sesName).recog.targ] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.targ,cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % add lures to the existing list
  [f2Stim,expParam.session.(sesName).recog.lure] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.lure,cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  %% save the parameters
  
  save(cfg.files.expParamFile,'cfg','expParam');
  
end

%% Run the experiment
fprintf('Running experiment: %s, subject %s, session %d...\n',expParam.expName,expParam.subject,expParam.sessionNum);

% Embed core of code in try ... catch statement. If anything goes wrong
% inside the 'try' block (Matlab error), the 'catch' block is executed to
% clean up, save results, close the onscreen window etc.
try
  %% Start data logging
  
  % Open data file and write column headers
  logFile = fopen(cfg.files.sesLogFile,'w');
  
  % TODO: set up logging for expertise experiment
  fprintf(logFile,'\nDate\tSubjno\tTrial\tCategory_Label\tBird_image\tCondition\tResp\tAccuray\tRT\tAnswer\tObj_ID_Number\tLabel_img_match\tBird_Family\tStimuli_Set\tBlock\tCounterbalance\tCorr_RT\tCount_Hit\tCount_FA\tCount_CR\tCount_Miss');
  
  %% Begin PTB display setup
  
  % Get screenNumber of stimulation display. We choose the display with
  % the maximum index, which is usually the right one, e.g., the external
  % display on a Laptop:
  screens = Screen('Screens');
  screenNumber = max(screens);
  
  % Open a double buffered fullscreen window on the stimulation screen
  % 'screenNumber' and choose/draw a gray background. 'windowPtr' is the handle
  % used to direct all drawing commands to that window - the "Name" of
  % the window. 'screenRect' is a rectangle defining the size of the window.
  % See "help PsychRects" for help on such rectangles and useful helper
  % functions:
  [windowPtr, screenRect] = Screen('OpenWindow',screenNumber, cfg.exp.gray, [0, 0, cfg.exp.screenXY(1), cfg.exp.screenXY(2)], 32, 2);
  
  % midWidth=round(RectWidth(ScreenRect)/2);    % get center coordinates
  % midLength=round(RectHeight(ScreenRect)/2);
  Screen('FillRect', windowPtr, cfg.exp.gray);  % put on a grey screen
  Screen('Flip',windowPtr);
  
  % Hide the mouse cursor:
  HideCursor;
  
  % Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
  % they are loaded and ready when we need them - without delays
  % in the wrong moment:
  KbCheck;
  WaitSecs(0.1);
  startExpt = GetSecs;
  
  % Set priority for script execution to realtime priority:
  priorityLevel = MaxPriority(w);
  Priority(priorityLevel);
  
  %% Run through the experiment
  
  % TODO: only pass this phase's cfg struct to each task?
  
  % find out what session this will be
  sesName = expParam.sesTypes{expParam.sessionNum};
  
  % make sure this session type has been configured
  if ~isfield(expParam.session,sesName)
    error('%s is not a configured session type',sesName);
  end
  
  % for each phase in this session, run the correct function
  for p = 1:length(expParam.session.(sesName).phases)
    
    switch expParam.session.(sesName).phases{p}
      
      case {'practice'}
        % Practice session
        
        % TODO: not sure what they'll do for practice
        fprintf('Not sure what to do for practice\n');
        
      case {'viewname'}
        % (Passive) Viewing task, with category response
        
        [cfg,logFile] = et_viewingNaming(cfg,expParam,logFile);
        
        % TODO: should this be separate et_viewing and et_naming functions?
        % Could step through blocks as
        % length(expParam.session.train1.viewname)
        
      case {'name'}
        % (Active) Naming task
        
        [cfg,logFile] = et_naming(cfg,expParam,logFile);
        
      case{'match'}
        % Subordinate Matching task (same/different)
        
        [cfg,logFile] = et_matching(cfg,expParam,logFile,sesName,expParam.session.(sesName).phases{p});
        
      case {'recog'}
        % Recognition (old/new) task
        
        [cfg,logFile] = et_recognition(cfg,expParam,logFile);
        
      otherwise
        warning('%s is not a configured phase in this session (%s)!\n',expParam.session.(sesName).phases{p},sesName);
    end
  end
  
  %% Session is done
  
  % increment the session number for next time
  expParam.sessionNum = expParam.sessionNum + 1;
  
  % save the experiment data
  save(cfg.files.expParamFile,'cfg','expParam');
  
  %   %% Practice Block (see corresponding m.file)
  %   blockPractice(practicefilename, windowPtr, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, practise_img,  ...
  %     timeout_img, txtsize_test, Res);
  %   %% Test Block 1 (see corresponding m.file)
  %   blockTest(testfilenameSetA1, windowPtr, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, dataFile, sdate, ...
  %     subNum, cbNum, test_img1, timeout_img, txtsize_test, ...
  %     corr_rt, Res, txtsize_takebreak);
  %   %% Test Block 2 (see corresponding m.file)
  %   blockTest(testfilenameSetA2, windowPtr, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, dataFile, sdate, ...
  %     subNum, cbNum, test_img2, timeout_img, txtsize_test, ...
  %     corr_rt, Res, txtsize_takebreak);
  %   %% Test Block 3 (see corresponding m.file)
  %   blockTest(testfilenameSetA3, windowPtr, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, dataFile, sdate, ...
  %     subNum, cbNum, test_img3, timeout_img, txtsize_test, ...
  %     corr_rt, Res, txtsize_takebreak);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Finish Message  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  Screen('PutImage', windowPtr, final_img, [1, 1, cfg.exp.screenXY(1), cfg.exp.screenXY(2)]);
  Screen('Flip', windowPtr);
  
  touch = 0; % Detect spacebar press to continue
  while ~touch
    [touch,tpress,keycode] = KbCheck;
    % if it's the spacebar
    if keycode(cfg.keys.s00)
      break
    else
      touch = 0;
    end
  end
  while KbCheck; end
  
  FlushEvents('keyDown');
  touch = 0;
  Screen('Close');
  
  % Cleanup at end of experiment - Close window, show mouse cursor, close
  % result file, switch Matlab/Octave back to priority 0 -- normal
  % priority:
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
  
  % End of experiment:
  return
  
catch ME
  % catch error: This is executed in case something goes wrong in the
  % 'try' part due to programming error etc.:
  
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % Do same cleanup as at the end of a regular session...
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
  
  % Output the error message that describes the error:
  psychrethrow(psychlasterror);
  
end % try ... catch


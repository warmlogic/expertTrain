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

% TODO: read a config file with expName and session info below. Next line
% becomes unnecessary, but needs to go before checking on subject and
% directories for saving data.

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

% TODO: set up subject database to keep track of what day and phase we're
% on. Pre-test day, training day 1, training days 2-6, post-test day.

% TODO: put this in a config file

expParam.nSessions = 9;

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

%% Define text size

% TODO: fix for this experiment
cfg.exp.txtsize_instruct = 35;
cfg.exp.txtsize_break = 28;

%% Define the response keys

% keys for naming species (subordinate-level naming)

% % I can't get PTB to use the semicolon
%cfg.keys.possibleKeys = {'a','s','d','f','v','n','j','k','l','semicolon'};
cfg.keys.speciesKeys = {'a','s','d','f','v','b','h','j','k','l'};

if ~isfield(cfg.keys,'keysAreSet')
  cfg.keys.keysAreSet = false;
end

% only set the keys in a random order once per subject
if ~cfg.keys.keysAreSet
  % cfg.keys.randKeyOrder = randperm(length(cfg.keys.speciesKeys));
  % debug - not randomized
  cfg.keys.randKeyOrder = 1:length(cfg.keys.speciesKeys);
  fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  
  % use spacebar for naming "other" family (basic-level naming)
  cfg.keys.s00 = KbName('space');
  
  % set the species keys
  for i = 1:length(cfg.keys.speciesKeys)
    % sXX, where XX is an integer, buffered with a zero if i <= 9
    cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeys{cfg.keys.randKeyOrder(i)});
  end
  
  % and store that we set the keys so we don't do it again next session
  cfg.keys.keysAreSet = true;
end

%% Stimulus parameters

cfg.files.stimDir = fullfile(cfg.files.expDir,'images','Creatures');
cfg.stim.file = fullfile(cfg.files.stimDir,'stimList.txt');

% 1980 items available in creature stimulus set

% old
% % exemplars per species, per family for training/matching task
% cfg.stim.exemplarsMatch = 12;
% % exemplars per species, per family for recognition task (creatures only)
% cfg.stim.exemplarsRecog = 72;

% % % debug
% % exemplars per species, per family for training/matching task
% cfg.stim.exemplarsMatch = 4;
% % exemplars per species, per family for recognition task (creatures only)
% cfg.stim.exemplarsRecog = 8;

%% Run the experiment

% Embed core of code in try ... catch statement. If anything goes wrong
% inside the 'try' block (Matlab error), the 'catch' block is executed to
% clean up, save results, close the onscreen window etc.
try
  fprintf('Running experiment: %s, subject %s, session %d...\n',expParam.expName,expParam.subject,expParam.sessionNum);
  
  % make an initial save of experiment data
  save(cfg.files.expParamFile,'cfg','expParam');
  
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
  
  % Each of the functions below defines a block of the experiment.
  % Which stimuli list is uploaded to each block is defined according to
  % which counterbalance the participant is in (look at lines: 88-99)
  
  %% If session 1, do stimulus setup
  
  if expParam.sessionNum == 1
%     % locate stimuli
%     fid = fopen(cfg.stim.file);
%     stimuli = textscan(fid,'%s%d%d%s%d%d','Delimiter','\t','Headerlines',1);
%     fclose(fid);
%     
%     % get the number of families
%     cfg.stim.nFamilies = length(unique(stimuli{2}));
%     % assumes that each family has the same number of species
%     cfg.stim.nSpecies = length(unique(stimuli{3}));
%     
%     % family names correspond to the directories in which stimuli reside
%     cfg.stim.familyNames = unique(stimuli{4});
%     
%     % put images in proper lists based on phases, with metadata for logging
%     %if expParam.isEven
%     %end
%     
%     cfg.stim.filename = stimuli{1};
%     cfg.stim.family = stimuli{2};
%     cfg.stim.species = stimuli{3};
%     cfg.stim.speciesStr = stimuli{4};
%     cfg.stim.exemplar = stimuli{5};
%     %cfg.stim.number = stimuli{6}; % for calculating number of trials
%     
%     % % debug
%     % n=1;
%     % thisStim = fullfile(cfg.files.stimDir,cfg.stim.speciesStr{n},cfg.stim.filename{n});
    
    %% configure creatures
    
    cfg.files.stimFileExt = '.bmp';
    cfg.stim.nFamilies = 2;
    % family names correspond to the directories in which stimuli reside
    cfg.stim.familyNames = {'a','s'};
    % assumes that each family has the same number of species
    cfg.stim.nSpecies = 10;
    % assumes that each species has the same number of exemplars
    cfg.stim.nExemplars = 99;
    
    % counterbalance basic and subordinate families
    if expParam.isEven
      cfg.stim.famBasic = 1;
      cfg.stim.famSubord = 2;
    else
      cfg.stim.famBasic = 2;
      cfg.stim.famSubord = 1;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%
    % pretest configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching: number of trained and untrained per species per family
    cfg.stim.pretest.match.nTrained = 6;
    cfg.stim.pretest.match.nUntrained = 6;
    
    % Recognition: number of target and lure stimuli (assumes all targets
    % are lures are tested)
    cfg.stim.pretest.recog.nStudyTarg = 16;
    cfg.stim.pretest.recog.nTestLure = 8;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Training Day 1 configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Viewing
    cfg.stim.train1.viewname.cond1 = 0;
    cfg.stim.train1.viewname.cond2 = 0;
    
    % Naming
    cfg.stim.train1.name.cond1 = 0;
    cfg.stim.train1.name.cond2 = 0;
    
    % Matching
    cfg.stim.train1.match.nTrained = 0;
    cfg.stim.train1.match.nUntrained = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Training Day 2 configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching
    cfg.stim.train2.match.nTrained = 0;
    cfg.stim.train2.match.nUntrained = 0;
    
    % Naming
    cfg.stim.train2.name.cond1 = 0;
    cfg.stim.train2.name.cond2 = 0;
    
    % Matching
    cfg.stim.train2.match.nTrained = 0;
    cfg.stim.train2.match.nUntrained = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Training Day 3 configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching
    cfg.stim.train3.match.nTrained = 0;
    cfg.stim.train3.match.nUntrained = 0;
    
    % Naming
    cfg.stim.train3.name.cond1 = 0;
    cfg.stim.train3.name.cond2 = 0;
    
    % Matching
    cfg.stim.train3.match.nTrained = 0;
    cfg.stim.train3.match.nUntrained = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Training Day 4 configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching
    cfg.stim.train4.match.nTrained = 0;
    cfg.stim.train4.match.nUntrained = 0;
    
    % Naming
    cfg.stim.train4.name.cond1 = 0;
    cfg.stim.train4.name.cond2 = 0;
    
    % Matching
    cfg.stim.train4.match.nTrained = 0;
    cfg.stim.train4.match.nUntrained = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Training Day 5 configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching
    cfg.stim.train5.match.nTrained = 0;
    cfg.stim.train5.match.nUntrained = 0;
    
    % Naming
    cfg.stim.train5.name.cond1 = 0;
    cfg.stim.train5.name.cond2 = 0;
    
    % Matching
    cfg.stim.train5.match.nTrained = 0;
    cfg.stim.train5.match.nUntrained = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Training Day 6 configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching
    cfg.stim.train6.match.nTrained = 0;
    cfg.stim.train6.match.nUntrained = 0;
    
    % Naming
    cfg.stim.train6.name.cond1 = 0;
    cfg.stim.train6.name.cond2 = 0;
    
    % Matching
    cfg.stim.train6.match.nTrained = 0;
    cfg.stim.train6.match.nUntrained = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Posttest configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching
    cfg.stim.posttest.match.nTrained = 0;
    cfg.stim.posttest.match.nUntrained = 0;
    
    % Recognition
    cfg.stim.posttest.recog.nStudyTarg = 16;
    cfg.stim.posttest.recog.nTestLure = 8;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Posttest Delayed configuration
    %%%%%%%%%%%%%%%%%%%%%%
    
    % Matching
    cfg.stim.posttest_delay.match.nTrained = 0;
    cfg.stim.posttest_delayed.match.nUntrained = 0;
    
    % Recognition
    cfg.stim.posttest_delay.recog.nStudyTarg = 16;
    cfg.stim.posttest_delay.recog.nTestLure = 8;
    
    
    %% create the stimulus list if it doesn't exist
    if ~exist(cfg.stim.file,'file')
      et_saveStimList(cfg);
    end
    
    % read in the stimulus list
    fprintf('Loading stimulus list: %s...',cfg.stim.file);
    fid = fopen(cfg.stim.file);
    stimuli = textscan(fid,'%s%s%d%s%d%d%d','Delimiter','\t','Headerlines',1);
    fclose(fid);
    fprintf('Done.\n');
    
    % create a structure for each family with all the stim information
    f1Ind = stimuli{3} == 1;
    f1Stim = struct('filename',stimuli{1}(f1Ind),'familyStr',stimuli{2}(f1Ind),'familyNum',num2cell(stimuli{3}(f1Ind)),'speciesStr',stimuli{4}(f1Ind),'speciesNum',num2cell(stimuli{5}(f1Ind)),'exemplar',num2cell(stimuli{6}(f1Ind)),'number',num2cell(stimuli{7}(f1Ind)));
    f2Ind = stimuli{3} == 2;
    f2Stim = struct('filename',stimuli{1}(f2Ind),'familyStr',stimuli{2}(f2Ind),'familyNum',num2cell(stimuli{3}(f2Ind)),'speciesStr',stimuli{4}(f2Ind),'speciesNum',num2cell(stimuli{5}(f2Ind)),'exemplar',num2cell(stimuli{6}(f2Ind)),'number',num2cell(stimuli{7}(f2Ind)));
    
    % debug
    f1Stim_orig = f1Stim;
    f2Stim_orig = f2Stim;
    
    %% Pretest
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    % family 1
    
    % trained
    expParam.session.pretest.match.f1Trained = [];
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.pretest.match.nTrained,{'pretest','match','f1Trained'});
    % untrained
    expParam.session.pretest.match.f1Untrained = [];
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.pretest.match.nUntrained,{'pretest','match','f1Untrained'});
    
    % family 2
    
    % trained
    expParam.session.pretest.match.f2Trained = [];
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.pretest.match.nTrained,{'pretest','match','f2Trained'});
    
    % untrained
    expParam.session.pretest.match.f2Untrained = [];
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.pretest.match.nUntrained,{'pretest','match','f2Untrained'});
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Recognition task
    %%%%%%%%%%%%%%%%%%%%%%
    
    % initialize for storing both families together
    expParam.session.pretest.recog.targ = [];
    expParam.session.pretest.recog.lure = [];
    
    % family 1
    
    % targets
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.pretest.recog.nStudyTarg,{'pretest','recog','targ'});
    % lures
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.pretest.recog.nTestLure,{'pretest','recog','lure'});
    
    % family 2
    
    % targets
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.pretest.recog.nStudyTarg,{'pretest','recog','targ'});
    % lures
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.pretest.recog.nTestLure,{'pretest','recog','lure'});
    
    %% Training Day 1
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Viewing+Naming task
    %%%%%%%%%%%%%%%%%%%%%%
    
    % get the stimuli from both families for selection (will shuffle later)
    f1Trained = expParam.session.pretest.match.f1Trained;
    f2Trained = expParam.session.pretest.match.f2Trained;
    
    % randomize the order in which species are added; order is different
    % for each family
    %speciesOrder_f1 = randperm(cfg.stim.nSpecies);
    %speciesOrder_f2 = randperm(cfg.stim.nSpecies);
    % debug
    speciesOrder_f1 = (1:cfg.stim.nSpecies);
    speciesOrder_f2 = (1:cfg.stim.nSpecies);
    fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
    
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
    
    % number of examplars per viewing and naming block
    %cfg.stim.examplarPerView = 1;
    cfg.stim.exemplarPerName = 2;
    
    % maximum number of repeated exemplars from each family
    cfg.stim.viewMaxConsecFamily = 3;
    cfg.stim.nameMaxConsecFamily = 3;
    
    % initialize viewing and naming cells, one for each block
    expParam.session.train1.viewname.view = cell(1,length(blockSpeciesOrder));
    expParam.session.train1.viewname.name = cell(1,length(blockSpeciesOrder));
    
    for b = 1:length(blockSpeciesOrder)
      for s = 1:length(blockSpeciesOrder{b})
        % family 1
        sInd_f1 = find([f1Trained.speciesNum] == speciesOrder_f1(blockSpeciesOrder{b}(s)));
        % shuffle the stimulus index
        %randsel_f1 = randperm(length(sInd_f1));
        % debug
        randsel_f1 = 1:length(sInd_f1);
        fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
        % shuffle the exemplars
        thisSpecies_f1 = f1Trained(sInd_f1(randsel_f1));
        
        % add them to the list
        %fprintf('view f1: block %d, species %d, examplar %d\n',b,blockSpeciesOrder{b}(s),viewIndices{b}(s));
        expParam.session.train1.viewname.view{b} = cat(1,expParam.session.train1.viewname.view{b},thisSpecies_f1(viewIndices{b}(s)));
        
        %fprintf('\tname f1: block %d, species %d, exemplar%s\n',b,blockSpeciesOrder{b}(s),sprintf(repmat(' %d',1,length(nameIndices{b}(((s*cfg.stim.exemplarPerName)-1):(s*cfg.stim.exemplarPerName)))),nameIndices{b}(((s*cfg.stim.exemplarPerName)-1):(s*cfg.stim.exemplarPerName))));
        expParam.session.train1.viewname.name{b} = cat(1,expParam.session.train1.viewname.name{b},thisSpecies_f1(nameIndices{b}(((s*cfg.stim.exemplarPerName)-1):(s*cfg.stim.exemplarPerName))));
        
        % family 2
        sInd_f2 = find([f1Trained.speciesNum] == speciesOrder_f2(blockSpeciesOrder{b}(s)));
        % shuffle the stimulus index
        %randsel_f2 = randperm(length(sInd_f2));
        % debug
        randsel_f2 = 1:length(sInd_f2);
        fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
        % shuffle the exemplars
        thisSpecies_f2 = f2Trained(sInd_f2(randsel_f2));
        
        % add them to the viewing list
        %fprintf('view f2: block %d, species %d, examplar %d\n',b,blockSpeciesOrder{b}(s),viewIndices{b}(s));
        % NB: not actually using cfg.stim.examplarPerView. This needs to be
        % modified if there's more than 1 exemplar per view from a species.
        expParam.session.train1.viewname.view{b} = cat(1,expParam.session.train1.viewname.view{b},thisSpecies_f2(viewIndices{b}(s)));
        
        % add them to the naming list
        %fprintf('\tname f2: block %d, species %d, exemplar%s\n',b,blockSpeciesOrder{b}(s),sprintf(repmat(' %d',1,length(nameIndices{b}(((s*cfg.stim.exemplarPerName)-1):(s*cfg.stim.exemplarPerName)))),nameIndices{b}(((s*cfg.stim.exemplarPerName)-1):(s*cfg.stim.exemplarPerName))));
        expParam.session.train1.viewname.name{b} = cat(1,expParam.session.train1.viewname.name{b},thisSpecies_f2(nameIndices{b}(((s*cfg.stim.exemplarPerName)-1):(s*cfg.stim.exemplarPerName))));
      end
      
      % if there are more than X consecutive exemplars from the same
      % family, reshuffle. There's probably a better way to do this.
      
      % viewing
      [expParam.session.train1.viewname.view{b}] = et_shuffleStims(expParam.session.train1.viewname.view{b},'familyNum',cfg.stim.viewMaxConsecFamily);
      % naming
      [expParam.session.train1.viewname.name{b}] = et_shuffleStims(expParam.session.train1.viewname.name{b},'familyNum',cfg.stim.nameMaxConsecFamily);
      
    end % for each block
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Naming task (all stimuli)
    %%%%%%%%%%%%%%%%%%%%%%
    
    % put all the stimuli together
    expParam.session.train1.name.allStim = cat(1,expParam.session.pretest.match.f1Trained,expParam.session.pretest.match.f2Trained);
    % Reshuffle. No more than X conecutive exemplars from the same family.
    [expParam.session.train1.name.allStim] = et_shuffleStims(expParam.session.train1.name.allStim,'familyNum',cfg.stim.nameMaxConsecFamily);
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
%     % family 1
%     % shuffle the stimulus index
%     %randsel_f1 = randperm(length(expParam.session.pretest.match.f1Trained));
%     % debug
%     randsel_f1 = 1:length(expParam.session.pretest.match.f1Trained);
%     fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
%     expParam.session.train1.match.f1Trained = expParam.session.pretest.match.f1Trained(randsel_f1);
%     % shuffle the stimulus index
%     %randsel_f1 = randperm(length(expParam.session.pretest.match.f1Trained));
%     % debug
%     randsel_f1 = 1:length(expParam.session.pretest.match.f1Untrained);
%     fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
%     expParam.session.train1.match.f1Untrained = expParam.session.pretest.match.f1Untrained(randsel_f1);
    
%     % family 2
%     % shuffle the stimulus index
%     %randsel_f2 = randperm(length(expParam.session.pretest.match.f2Trained));
%     % debug
%     randsel_f2 = 1:length(expParam.session.pretest.match.f2Trained);
%     fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
%     expParam.session.train1.match.f2Trained = expParam.session.pretest.match.f2Trained(randsel_f2);
%     % shuffle the stimulus index
%     %randsel_f2 = randperm(length(expParam.session.pretest.match.f2Trained));
%     % debug
%     randsel_f2 = 1:length(expParam.session.pretest.match.f2Untrained);
%     fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
%     expParam.session.train1.match.f2Untrained = expParam.session.pretest.match.f2Untrained(randsel_f2);

    % number per species per family
    cfg.stim.train1.match.nSame = cfg.stim.pretest.match.nTrained / 2;
    cfg.stim.train1.match.nDiff = cfg.stim.pretest.match.nTrained / 2;
    
    % family 1
    f1Trained = expParam.session.pretest.match.f1Trained;
    expParam.session.train1.match.same = [];
    [f1Trained,expParam] = et_divvyStims(cfg,expParam,f1Trained,...
      cfg.stim.train1.match.nSame,{'train1','match','same'});
    expParam.session.train1.match.diff = [];
    [f1Trained,expParam] = et_divvyStims(cfg,expParam,f1Trained,...
      cfg.stim.train1.match.nDiff,{'train1','match','diff'});
    
    % family 1
    f2Trained = expParam.session.pretest.match.f2Trained;
    expParam.session.train1.match.same = [];
    [f2Trained,expParam] = et_divvyStims(cfg,expParam,f2Trained,...
      cfg.stim.train1.match.nSame,{'train1','match','same'});
    expParam.session.train1.match.diff = [];
    [f2Trained,expParam] = et_divvyStims(cfg,expParam,f2Trained,...
      cfg.stim.train1.match.nDiff,{'train1','match','diff'});
    
    
    %% Training Day 2
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Naming task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %% Training Day 3
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Naming task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %% Training Day 4
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Naming task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %% Training Day 5
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Naming task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %% Training Day 6
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Naming task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %% Posttest
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Recognition task
    %%%%%%%%%%%%%%%%%%%%%%
    
    % initialize for storing both families together
    expParam.session.posttest.recog.targ = [];
    expParam.session.posttest.recog.lure = [];
    
    % family 1
    
    % targets
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.posttest.recog.nStudyTarg,{'posttest','recog','targ'});
    % lures
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.posttest.recog.nTestLure,{'posttest','recog','lure'});
    
    % family 2
    
    % targets
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.posttest.recog.nStudyTarg,{'posttest','recog','targ'});
    % lures
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.posttest.recog.nTestLure,{'posttest','recog','lure'});
    
    %% Posttest Delayed
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Matching task
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Recognition task
    %%%%%%%%%%%%%%%%%%%%%%
    
    % initialize for storing both families together
    expParam.session.posttest_delay.recog.targ = [];
    expParam.session.posttest_delay.recog.lure = [];
    
    % family 1
    
    % targets
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.posttest_delay.recog.nStudyTarg,{'posttest_delay','recog','targ'});
    % lures
    [f1Stim,expParam] = et_divvyStims(cfg,expParam,f1Stim,...
      cfg.stim.posttest_delay.recog.nTestLure,{'posttest_delay','recog','lure'});
    
    % family 2
    
    % targets
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.posttest_delay.recog.nStudyTarg,{'posttest_delay','recog','targ'});
    % lures
    [f2Stim,expParam] = et_divvyStims(cfg,expParam,f2Stim,...
      cfg.stim.posttest_delay.recog.nTestLure,{'posttest_delay','recog','lure'});
    
    
    % save the parameters
    save(cfg.files.expParamFile,'cfg','expParam');
  end
  
  %% session type
  
  thisSession = expParam.sesTypes{expParam.sessionNum};
  for p = 1:length(expParam.session.(thisSession).phases)
    %% Practice
    
    % not sure what they'll do for practice
    
    %% (Passive) Viewing task, with category response
    
    % TODO: individual cfgs for each task?
    
    if strcmp(expParam.session.(thisSession).phases{p},'viewname')
      [cfg,expParam] = et_viewingNaming(cfg,expParam,logFile);
      continue
    end
    
    %% (Active) Naming task
    
    if strcmp(expParam.session.(thisSession).phases{p},'name')
      [cfg,expParam] = et_naming(cfg,expParam,logFile);
      continue
    end
    
    %% Subordinate Matching task (same/different)
    
    if strcmp(expParam.session.(thisSession).phases{p},'match')
      [cfg,expParam] = et_matching(cfg,expParam,logFile);
      continue
    end
    
    %% Recognition (old/new) task
    
    if strcmp(expParam.session.(thisSession).phases{p},'recog')
      [cfg,expParam] = et_recognition(cfg,expParam,logFile);
      continue
    end
    
    % TODO: do we need to catch a case where thisSession does not have a
    % field in expParam.session?
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
      touch=0;
    end
  end
  while KbCheck; end
  
  FlushEvents('keyDown');
  touch = 0;
  Screen('Close');
  
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % Cleanup at end of experiment - Close window, show mouse cursor, close
  % result file, switch Matlab/Octave back to priority 0 -- normal
  % priority:
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
  % End of experiment:
  return;
  
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




%% boneyard

% cfg.stim.filename = stimuli{1};
% cfg.stim.familyStr = stimuli{2};
% cfg.stim.familyNum = stimuli{3};
% cfg.stim.speciesStr = stimuli{4};
% cfg.stim.speciesNum = stimuli{5};
% cfg.stim.exemplar = stimuli{6};
% % TODO: do we need "number"?
% cfg.stim.number = stimuli{7}; % for calculating number of trials

% basicShuffled = randperm(sum(cfg.stim.familyNum == cfg.stim.famBasic));
% subordShuffled = randperm(sum(cfg.stim.familyNum == cfg.stim.famSubord));


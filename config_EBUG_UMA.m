function [cfg,expParam] = config_EBUG_UMA(cfg,expParam)
% function [cfg,expParam] = config_EBUG_UMA(cfg,expParam)
%
% Description:
%  Configuration function for creature expertise training experiment. This
%  file should be edited for your particular experiment. This function runs
%  et_processStims to prepare the stimuli for experiment presentation.
%
% see also: et_saveStimList, et_processStims, et_processStims_match,
% et_processStims_recog, et_processStims_viewname,
% et_processStims_nametrain, et_processStims_name

%% Experiment defaults

% set up configuration structures to keep track of what day and phase we're
% on.

% IP address of computer running Net Station
expParam.NSHost = '10.0.0.42';

% Port that NS expects to receive data on
expParam.NSPort = 55513;

expParam.baselineRecordSecs = 20.0;

% sound defaults, these get set for each phase
playSound = true;
correctSound = 1000;
incorrectSound = 300;
correctVol = 0.4;
incorrectVol = 0.6;

% whether to print trial details to the command window
cfg.text.printTrialInfo = false;

% matching task defaults
matchTextPrompt = true;

% blink break (set to 0 if you don't want breaks)
if expParam.useNS
  % timer in secs for when to take a blink break (only when useNS=true)
  cfg.stim.secUntilBlinkBreak = 45.0;
else
  % timer in secs for when to take a blink break (only when useNS=false)
  cfg.stim.secUntilBlinkBreak = 90.0;
end

%% Experiment session information

% ================
% real setup with be something like this
% ================

% Set the number of sessions
expParam.nSessions = 10;

expParam.sesTypes = {'pretest_eye','pretest_eeg','train1','train2','train3','train4','train5', 'train6','posttest_eye','posttest_eeg'};
expParam.doNotRunSes = [true false false false false false false false true false];

% set up a field for each session type
expParam.session.pretest_eye.phases = {'prac_match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match'};
expParam.session.pretest_eeg.phases = {'match'};
expParam.session.train1.phases = {'prac_name', 'nametrain'};
expParam.session.train2.phases = {'nametrain'};
expParam.session.train3.phases = {'nametrain'};
expParam.session.train4.phases = {'nametrain'};
expParam.session.train5.phases = {'nametrain'};
expParam.session.train6.phases = {'nametrain'};
expParam.session.posttest_eye.phases = {'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match', 'match'};
expParam.session.posttest_eeg.phases = {'match'};

% ================
% temporary setup
% ================

% expParam.nSessions = 1;
% expParam.sesTypes = {'pretest_eye'};
% expParam.doNotRunSes = true;
% expParam.session.pretest_eye.phases = {'match', 'match', 'match'};

% expParam.nSessions = 4;
% expParam.sesTypes = {'pretest_eye','pretest_eeg','posttest_eye','posttest_eeg'};
% expParam.doNotRunSes = [true false true false];

% expParam.session.pretest_eye.phases = {'match', 'match', 'match'};
% expParam.session.pretest_eeg.phases = {'match'};
% expParam.session.pretest_eeg.phases = {'match', 'compare'};
% expParam.session.posttest_eye.phases = {'match', 'match', 'match'};
% expParam.session.posttest_eeg.phases = {'match'};
% expParam.session.posttest_eeg.phases = {'match', 'compare'};


%% do some error checking

possible_phases = {'match','name','recog','nametrain','viewname','prac_match','prac_name','prac_recog'};
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
  
  % Sets Counterbalance (1-4). Divides subject number by 3 and then rounds
  % answer up to nearest integer. To allow for more than 12 subjects,
  % divides the integer by 4 and finds the remainder. The -1 and +1 take
  % into account the way that Matlab creates indices.
  expParam.counterbalance = mod(ceil(str2double(expParam.subject(end-2:end))/3)-1,4)+1;
  
  % Sets the Difficulty (1-3). Subtracts 1 from the subject number, divides
  % this value by 3 and finds the remainder. The +1 takes into account the
  % way that Matlab creates indices.
  expParam.difficulty = mod(str2double(expParam.subject(end-2:end))-1,3)+1;
  
  %% Stimulus parameters
  
  % whether to present a white square during the stimulus
  cfg.stim.photoCell = false;
  cfg.stim.photoCellRectSize = 30;
  
  % whether to preload images; if true, could use a lot of memory
  cfg.stim.preloadImages = false;
  
  % the file extension for your images
  cfg.files.stimFileExt = '.bmp';
  
  % scale stimlus down (< 1) or up (> 1)
  cfg.stim.stimScale = 0.75;
  
  % image directory holds the stims and resources
  cfg.files.imgDir = fullfile(cfg.files.expDir,'images');
  
  % set the stimulus directory
  cfg.files.stimDir = fullfile(cfg.files.imgDir,'Creatures');
  
  % set the image resources directory
  cfg.files.resDir = fullfile(cfg.files.imgDir,'resources');
  
  % set the instructions directory
  cfg.files.instructDir = fullfile(cfg.files.expDir,'text','instructions');
  
  % family names correspond to the directories in which stimuli reside;
  % includes manipulations
  cfg.stim.familyNames = {'a', 's'};
  
  % assumes that each family has the same number of species
  cfg.stim.nSpecies = 10;
  
  % number of species to mark as "new"; left out of training; different
  % setups for different counterbalancings
  if expParam.counterbalance == 1
    cfg.stim.newSpecies = [1, 3, 5, 7, 9];
  elseif expParam.counterbalance == 2
    cfg.stim.newSpecies = [2, 4, 6, 8, 10];
  elseif expParam.counterbalance == 3
    cfg.stim.newSpecies = [1, 2, 5, 9, 10];
  elseif expParam.counterbalance == 4
    cfg.stim.newSpecies = [3, 4, 6, 7, 8];
  end
  cfg.stim.nNewExemplars = 12;
  
  % whether to use the same species order across families
  cfg.stim.yokeSpecies = false;
  if cfg.stim.yokeSpecies
    %cfg.stim.yokeTogether = [1 1 1 1 1 2 2 2 2 2];
    cfg.stim.yokeTogether = [1 2];
  end
  
  % Number of trained and untrained exemplars per species per family
  cfg.stim.nTrained = 6;
  cfg.stim.nUntrained = 6;
  
  % yoke exemplars across species within these family groups so training
  % status is the same for all finches and for all warblers; NB this
  % applies when there is some dependency between different families (e.g.,
  % different image conditions input as families)
  cfg.stim.yokeTrainedExemplars = false;
  if cfg.stim.yokeTrainedExemplars
    cfg.stim.yokeExemplars_train = [1 1 1 1 1 2 2 2 2 2];
  end
  
  % save an individual stimulus list for each subject
  cfg.stim.stimListFile = fullfile(cfg.files.subSaveDir,'stimList.txt');
  
  % create the stimulus list if it doesn't exist
  shuffleSpecies = true; % have the letter/species assignments randomized across participants
  if ~exist(cfg.stim.stimListFile,'file')
    [cfg] = et_saveStimList(cfg,cfg.files.stimDir,cfg.stim,shuffleSpecies);
  else
    % % debug = warning instead of error
    % warning('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.stimListFile);
    error('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.stimListFile);
  end
  
  % basic/subordinate families (counterbalance based on even/odd subNum)
  if expParam.isEven
    cfg.stim.famNumBasic = 1;
    cfg.stim.famNumSubord = 2;
    %cfg.stim.famNumBasic = [1 2 3 4 5];
    %cfg.stim.famNumSubord = [6 7 8 9 10];
  else
    cfg.stim.famNumBasic = 2;
    cfg.stim.famNumSubord = 1;
    %cfg.stim.famNumBasic = [6 7 8 9 10];
    %cfg.stim.famNumSubord = [1 2 3 4 5];
  end
  % what to call the basic-level family in viewing and naming tasks
  cfg.text.basicFamStr = 'Other';
  
  % whether to remove the trained/untrained stims from the stimulus pool
  % after they are chosen
  cfg.stim.rmStims_init = true;
  % whether to shuffle the stimulus pool before choosing trained/untrained
  cfg.stim.shuffleFirst_init = true;
  
  % % subordinate family species numbers
  % cfg.stim.specNum(cfg.stim.famNumSubord,:)
  % % subordinate family species letters
  % cfg.stim.specStr(cfg.stim.famNumSubord,:)
  
  % practice images stored in separate directories
  expParam.runPractice = true;
  
  if expParam.runPractice
    cfg.stim.useSeparatePracStims = true;
    
    % practice exemplars per species per family for all phases except
    % recognition (recognition stim count is determined by nStudyTarg and
    % nStudyLure in each prac_recog phase defined below)
    cfg.stim.practice.nPractice = 2;
    
    if cfg.stim.useSeparatePracStims
      cfg.files.stimDir_prac = fullfile(cfg.files.imgDir,'PracticeBirds');
      cfg.stim.practice.familyNames = {'Perching_', 'Wading_'};
      cfg.stim.practice.nSpecies = 2;
      
      % basic/subordinate families (counterbalance for even/odd subNum)
      if expParam.isEven
        cfg.stim.practice.famNumBasic = 1;
        cfg.stim.practice.famNumSubord = 2;
      else
        cfg.stim.practice.famNumBasic = 2;
        cfg.stim.practice.famNumSubord = 1;
      end
      
      cfg.stim.practice.yokeSpecies = false;
      if cfg.stim.practice.yokeSpecies
        cfg.stim.practice.yokeTogether = [1 1 1 1 1 2 2 2 2 2];
      end
      
      cfg.stim.practice.stimListFile = fullfile(cfg.files.subSaveDir,'stimList_prac.txt');
      
      shuffleSpecies = false;
      if ~exist(cfg.stim.practice.stimListFile,'file')
        [cfg] = et_saveStimList(cfg,cfg.files.stimDir_prac,cfg.stim.practice,shuffleSpecies);
      else
        % % debug = warning instead of error
        % warning('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.practice.stimListFile);
        error('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.practice.stimListFile);
      end
    else
      cfg.files.stimDir_prac = cfg.files.stimDir;
      cfg.stim.practice.familyNames = cfg.stim.familyNames;
      %cfg.stim.practice.nSpecies = cfg.stim.nSpecies;
      %cfg.stim.practice.yokeSpecies = cfg.stim.yokeSpecies;
      cfg.stim.practice.nSpecies = 2;
      cfg.stim.practice.famNumBasic = cfg.stim.famNumBasic;
      cfg.stim.practice.famNumSubord = cfg.stim.famNumSubord;
      
      cfg.stim.practice.yokeSpecies = false;
      if cfg.stim.practice.yokeSpecies
        cfg.stim.practice.yokeTogether = [1 1 1 1 1 2 2 2 2 2];
      end
      cfg.stim.practice.nExemplars = repmat(cfg.stim.practice.nPractice,length(cfg.stim.practice.familyNames),cfg.stim.practice.nSpecies);
    end
  end % runPractice
  
  %% Define the response keys
  
  % the experimenter's secret key to continue the experiment
  cfg.keys.expContinue = 'g';
  
  % which row of keys to use in matching and recognition tasks. Can be
  % 'upper' or 'middle'
  cfg.keys.keyRow = 'upper';
  
  % subordinate matching keys (counterbalanced based on subNum 1-5, 6-0)
  if strcmp(cfg.keys.keyRow,'upper')
    % upper row
    cfg.keys.matchKeyNames = {'r','u'};
  elseif strcmp(cfg.keys.keyRow,'middle')
    % middle row
    cfg.keys.matchKeyNames = {'f','j'};
  end
  if expParam.is15
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{1});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{2});
  else
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{2});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{1});
  end
  
  % use spacebar for naming "other" family (basic-level naming)
  cfg.keys.otherKeyNames = {'space'};
  cfg.keys.s00 = KbName(cfg.keys.otherKeyNames{1});
  
  % keys for naming particular species (subordinate-level naming)
  if strcmp(cfg.keys.keyRow,'upper')
    % upper row
    cfg.keys.speciesKeyNames = {'q','w','e','r','v','n','u','i','o','p'};
  elseif strcmp(cfg.keys.keyRow,'middle')
    % middle row
    if ismac || isunix
      cfg.keys.speciesKeyNames = {'a','s','d','f','v','n','j','k','l',';:'};
    elseif ispc
      cfg.keys.speciesKeyNames = {'a','s','d','f','v','n','j','k','l',';'};
    end
  end
  
  % set the species keys
  for i = 1:length(cfg.keys.speciesKeyNames)
    % sXX, where XX is an integer, buffered with a zero if i <= 9
    cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeyNames{i});
  end
  
  if strcmp(cfg.keys.keyRow,'upper')
    cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_black_upper.jpg');
    %cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_white_upper.jpg');
  elseif strcmp(cfg.keys.keyRow,'middle')
    cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_black_middle.jpg');
    %cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_white_middle.jpg');
  end
  
  % scale image down (< 1) or up (> 1)
  cfg.files.speciesNumKeyImgScale = 0.4;
  
  %% Screen, text, and symbol configuration for size and color
  
  % Choose a color value (e.g., 210 for gray) to be used as experiment backdrop
  %cfg.screen.bgColor = 181;
  cfg.screen.bgColor = 210;
  
  % font sizes
  %
  % basic: small messages printed to the screen
  % instruct: instructions
  % fixSize: fixation
  if ispc
    cfg.text.basicTextSize = 18;
    cfg.text.instructTextSize = 18;
    cfg.text.fixSize = 18;
  elseif ismac
    cfg.text.basicTextSize = 32;
    cfg.text.instructTextSize = 28;
    cfg.text.fixSize = 32;
    %cfg.text.basicTextSize = 28;
    %cfg.text.instructTextSize = 24;
    %cfg.text.fixSize = 28;
  elseif isunix
    cfg.text.basicTextSize = 24;
    cfg.text.instructTextSize = 18;
    cfg.text.fixSize = 24;
  end
  
  % text colors
  cfg.text.basicTextColor = uint8((rgb('Black') * 255) + 0.5);
  cfg.text.instructColor = uint8((rgb('Black') * 255) + 0.5);
  % text color when experimenter's attention is needed
  cfg.text.experimenterColor = uint8((rgb('Red') * 255) + 0.5);
  
  % number of characters wide at which any text will wrap
  cfg.text.instructCharWidth = 70;
  
  % key to push to dismiss instruction screen
  cfg.keys.instructContKey = 'space';
  
  % fixation info
  cfg.text.fixSymbol = '+';
  cfg.text.respSymbol = '?';
  cfg.text.fixationColor = uint8((rgb('Black') * 255) + 0.5);
  
  % fixation defaults; change in phases if you want other behavior
  fixDuringISI = true;
  fixDuringPreStim = true;
  fixDuringStim = true;
  
  if matchTextPrompt
    cfg.text.matchSame = 'Same';
    cfg.text.matchDiff = 'Diff';
  end
  
  % "respond faster" text
  cfg.text.respondFaster = 'No response recorded!\nRespond faster!';
  cfg.text.respondFasterColor = uint8((rgb('Red') * 255) + 0.5);
  cfg.text.respondFasterFeedbackTime = 1.5;
  
  % error text color
  cfg.text.errorTextColor = uint8((rgb('Red') * 255) + 0.5);
  
  % text for when they respond too fast
  cfg.text.tooFastText = 'Too fast!';
  
  % text for when they push multiple keys
  cfg.text.multiKeyText = 'Do not press multiple keys!\nRelease all keys except your response,\nthen release your response.';
  
  %% Session/phase configuration
  
  %% pretest eyetracking configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'pretest_eye';
  
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching - practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.practice.familyNames;
        
        % % every stimulus is in both the same and the different condition.
        % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.practice.nPractice;
        % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.practice.nPractice;
        % % rmStims_orig is false because all stimuli are used in both "same"
        % % and "diff" conditions
        % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
        
        % number per species per family (half because each stimulus is only in
        % same or different condition)
        % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.practice.nPractice / 2;
        % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.practice.nPractice / 2;
        
        % number per species per family...1 for short practice phase
        cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.practice.nPractice / 2;
        cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.practice.nPractice / 2;
        
        % rmStims_orig is true because half of stimuli are in "same" cond and
        % half are in "diff"
        cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamilies (and multiply by 2
        % if rmStims_orig=false). nSpecies = (nSame + nDiff) in practice.
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseCount).stim2MinRepeatSpacing = 0;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseCount).matchTextPrompt = matchTextPrompt;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_response = 2.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        if phaseCount == 1
          %[cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
          %  fullfile(cfg.files.instructDir,sprintf('%s_importantMessage_1.txt',expParam.expName)),...
          %  {'contKey'}, {cfg.keys.instructContKey});
          [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
            fullfile(cfg.files.instructDir,sprintf('%s_match_1_practice_intro.txt',expParam.expName)),...
            {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        elseif phaseCount > 1
          [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
            fullfile(cfg.files.instructDir,sprintf('%s_match_2_practice_intro.txt',expParam.expName)),...
            {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        end
        % whether to ask the participant if they have any questions; only
        % continues with experimenter's secret key
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.questions = true;
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).writePairsToFile = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
        
        if phaseCount == 1 || phaseCount == 3 || phaseCount == 4 || phaseCount == 6 || phaseCount == 7 || phaseCount == 9 || phaseCount == 10 || phaseCount == 12
          % 360 trials per phase (for eyetracking matching and moving
          % window phases)
          
          % number per species per family; every stimulus is in both the
          % same and the different condition.
          cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained;
          % rmStims_orig is false because all stimuli are used in both "same"
          % and "diff" conditions
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
          
          cfg.stim.(sesName).(phaseName)(phaseCount).nSameNew = cfg.stim.nNewExemplars / 2;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiffNew = cfg.stim.nNewExemplars / 2;
          
          % % number per species per family (half because each stimulus is only in
          % % same or different condition)
          % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained / 2;
          % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained / 2;
          % % rmStims_orig is true because half of stimuli are in "same"
          % cond and % half are in "diff"
          % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
          
          % % this is how to force all stimuli to be both stim1 and stim2
          % % in "same" and "diff" conds
          % cfg.stim.(sesName).(phaseName)(phaseCount).reuseStimsSameDiff = true;
          
          % rmStims_pair is true because pairs are removed after they're added
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
          cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
          
        elseif phaseCount == 2 || phaseCount == 5 || phaseCount == 8 || phaseCount == 11
          % 2 blocks, 180 trials per block (for eyetracking foveal and
          % peripheral masking blocks)
          
          % splits stimuli in half, one half for each block
          cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks = 2;
          
          % % every stimulus is in both the same and the different condition.
          % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained;
          % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained;
          % % rmStims_orig is false because all stimuli are used in both "same"
          % % and "diff" conditions
          % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
          
          % number per species per family (half because each stimulus is only in
          % same or different condition)
          cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained / 2;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained / 2;
          
          cfg.stim.(sesName).(phaseName)(phaseCount).nSameNew = cfg.stim.nNewExemplars / 4;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiffNew = cfg.stim.nNewExemplars / 4;
          
          % rmStims_orig is true because half of stimuli are in "same" cond and
          % half are in "diff"
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
          
          % this is how to force all stimuli to be both stim1 and stim2 in
          % "same" and "diff" conds
          cfg.stim.(sesName).(phaseName)(phaseCount).reuseStimsSameDiff = true;
          
          % rmStims_pair is true because pairs are removed after they're added
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
          cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
        end
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamilies (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseCount).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseCount).matchTextPrompt = matchTextPrompt;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_3_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
  end % ismember
  
  %% pretest EEG configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'pretest_eeg';
  
  if ismember(sesName,expParam.sesTypes)
    
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     % Matching - practice
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     phaseName = 'prac_match';
    %
    %     if ismember(phaseName,expParam.session.(sesName).phases)
    %       for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
    %         cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
    %
    %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
    %
    %         % only use stimuli from particular families
    %         cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.practice.familyNames;
    %
    %         % every stimulus is in both the same and the different condition.
    %         cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.practice.nPractice;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.practice.nPractice;
    %         % rmStims_orig is false because all stimuli are used in both "same"
    %         % and "diff" conditions
    %         cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
    %
    %         % % number per species per family (half because each stimulus is only in
    %         % % same or different condition)
    %         % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.practice.nPractice / 2;
    %         % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.practice.nPractice / 2;
    %         % % rmStims_orig is true because half of stimuli are in "same" cond and
    %         % % half are in "diff"
    %         % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
    %
    %         % rmStims_pair is true because pairs are removed after they're added
    %         cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
    %
    %         % nTrials = (nSame + nDiff) * nSpecies * nFamilies (and multiply by 2
    %         % if rmStims_orig=false). nSpecies = (nSame + nDiff) in practice.
    %
    %         % minimum number of trials needed between exact repeats of a given
    %         % stimulus as stim2
    %         cfg.stim.(sesName).(phaseName)(phaseCount).stim2MinRepeatSpacing = 0;
    %         % whether to have "same" and "diff" text with the response prompt
    %         cfg.stim.(sesName).(phaseName)(phaseCount).matchTextPrompt = matchTextPrompt;
    %
    %         % durations, in seconds
    %         cfg.stim.(sesName).(phaseName)(phaseCount).match_isi = 0.0;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 = 0.8;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 = 0.8;
    %         % random intervals are generated on the fly
    %         cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1 = [0.5 0.7];
    %         cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2 = [1.0 1.2];
    %         cfg.stim.(sesName).(phaseName)(phaseCount).match_response = 2.0;
    %
    %         % do we want to play feedback beeps?
    %         cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
    %
    %         % instructions
    %         %[cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
    %         %  fullfile(cfg.files.instructDir,sprintf('%s_importantMessage_1.txt',expParam.expName)),...
    %         %  {'contKey'}, {cfg.keys.instructContKey});
    %         [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
    %           fullfile(cfg.files.instructDir,sprintf('%s_match_1_practice_intro.txt',expParam.expName)),...
    %           {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
    %         % whether to ask the participant if they have any questions; only
    %         % continues with experimenter's secret key
    %         cfg.stim.(sesName).(phaseName)(phaseCount).instruct.questions = true;
    %
    %         expParam.session.(sesName).(phaseName)(phaseCount).date = [];
    %         expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
    %         expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
    %       end
    %     end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).writePairsToFile = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
        
        % 360 trials per phase
        
        % number per species per family; every stimulus is in both the
        % same and the different condition.
        cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained;
        cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained;
        % rmStims_orig is false because all stimuli are used in both "same"
        % and "diff" conditions
        cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).nSameNew = cfg.stim.nNewExemplars / 2;
        cfg.stim.(sesName).(phaseName)(phaseCount).nDiffNew = cfg.stim.nNewExemplars / 2;
        
        % % number per species per family (half because each stimulus is only in
        % % same or different condition)
        % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained / 2;
        % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained / 2;
        % % rmStims_orig is true because half of stimuli are in "same"
        % cond and % half are in "diff"
        % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
        
        % % this is how to force all stimuli to be both stim1 and stim2
        % % in "same" and "diff" conds
        % cfg.stim.(sesName).(phaseName)(phaseCount).reuseStimsSameDiff = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamilies (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseCount).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseCount).matchTextPrompt = matchTextPrompt;
        
        % only used if running Net Station, but need to set unconditionally
        % because session 1 doesn't use NS
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 180;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_3_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Comparison task
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     phaseName = 'compare';
%     
%     if ismember(phaseName,expParam.session.(sesName).phases)
%       for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
%         
%       end
%     end
    
  end % ismember
  
  %% Training Day 1 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'train1';
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Naming
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_name';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.practice.familyNames;
        
        % maximum number of repeated exemplars from each family in naming
        cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily = 3;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).name_isi = 0.5;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).name_stim = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_response = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback = 1.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        %[cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).text] = et_processTextInstruct(...
        %  fullfile(cfg.files.instructDir,sprintf('%s_importantMessage_2.txt',expParam.expName)),...
        %  {'contKey'}, {cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_name_1_practice_intro.txt',expParam.expName)),...
          {'nFamily','basicFamStr','contKey'},...
          {num2str(length(cfg.stim.(sesName).(phaseName)(phaseCount).familyNames)),cfg.text.basicFamStr,cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).image = cfg.files.speciesNumKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).imageScale = cfg.files.speciesNumKeyImgScale;
        % whether to ask the participant if they have any questions; only
        % continues with experimenter's secret key
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.questions = true;
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end % ismember
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Name training (introduce species in a rolling fashion)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'nametrain';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
        
        allSpecies = 1:cfg.stim.nSpecies;
        trainedSpecies = allSpecies(~ismember(allSpecies,cfg.stim.newSpecies));
        trainedSpecies = trainedSpecies(randperm(length(trainedSpecies)));
        
        % Increasing difficulty
        if expParam.difficulty == 1
          
          % select trainedSpecies by indexing into trainedSpecies for
          % blockSpeciesOrder
          cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = {...
            trainedSpecies([1]),...
            trainedSpecies([2]),...
            trainedSpecies([3]),...
            trainedSpecies([4]),...
            trainedSpecies([5]),...
            trainedSpecies([1:2]),...
            trainedSpecies([3:4]),...
            trainedSpecies([5,1]),...
            trainedSpecies([2:3]),...
            trainedSpecies([4:5]),...
            trainedSpecies([1:3]),...
            trainedSpecies([4,5,1]),...
            trainedSpecies([2,3,4]),...
            trainedSpecies([5,1,2]),...
            trainedSpecies([3:5]),...
            trainedSpecies([1:4]),...
            trainedSpecies([5,1,2,3]),...
            trainedSpecies([4,5,1,2]),...
            trainedSpecies([3,4,5,1]),...
            trainedSpecies([2:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5])};
          
          % hard coded stimulus indices for naming training block presentations
          % (counterbalanced). Blocks are denoted by cells. The vectors within each
          % block represent the exemplar number(s) for each species, corresponding
          % to the species numbers listed in blockSpeciesOrder (defined above). The
          % contents of each vector corresponds to the exemplar numbers for that
          % species.
          
          % Number of exemplars to show for each species
          cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
          for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices)
            cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{i} = repmat({1:6},size(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i}));
          end
          
          % Decreasing difficulty
        elseif expParam.difficulty == 2
          
          % select trainedSpecies by indexing into trainedSpecies for
          % blockSpeciesOrder
          cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = {...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:5]),...
            trainedSpecies([1:4]),...
            trainedSpecies([5,1,2,3]),...
            trainedSpecies([4,5,1,2]),...
            trainedSpecies([3,4,5,1]),...
            trainedSpecies([2:5]),...
            trainedSpecies([1:3]),...
            trainedSpecies([4,5,1]),...
            trainedSpecies([2,3,4]),...
            trainedSpecies([5,1,2]),...
            trainedSpecies([3:5]),...
            trainedSpecies([1:2]),...
            trainedSpecies([3:4]),...
            trainedSpecies([5,1]),...
            trainedSpecies([2:3]),...
            trainedSpecies([4:5]),...
            trainedSpecies([1]),...
            trainedSpecies([2]),...
            trainedSpecies([3]),...
            trainedSpecies([4]),...
            trainedSpecies([5])};
          
          % Number of exemplars to show for each species
          cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
          for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices)
            cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{i} = repmat({1:6},size(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i}));
          end
          
          % Random difficulty
        elseif expParam.difficulty == 3
          
          % hard-coded for 25 blocks
          nBlocks = 25;
          % the length of numberOfSpecies is the number of blocks
          numberOfSpecies = repmat(randperm(length(trainedSpecies)),1,ceil(nBlocks / length(trainedSpecies)));
          % randomize so the number of species doesn't repeat after
          % length(trainedSpecies) blocks
          nSpecIndex = randperm(nBlocks);
          numberOfSpecies = numberOfSpecies(nSpecIndex);
          
          % repeat the trained species numbers so we have enough species
          % numbers to choose from; not randomized because we need to
          % unique species in each block (i.e., can't have the same species
          % listed twice for a block)
          trainedSpecies_rep = repmat(trainedSpecies,1,ceil(sum(numberOfSpecies) / length(trainedSpecies)));
          
          % make sure to set up numberOfSpecies so its length is the number of blocks you want
          cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = cell(1,length(numberOfSpecies));
          specIndex = 1;
          for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)
            addTheseSpecies = trainedSpecies_rep(specIndex:specIndex+numberOfSpecies(i)-1);
            cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i} = addTheseSpecies;
            specIndex = specIndex + numberOfSpecies(i);
          end
          
          % Number of exemplars to show for each species
          cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
          for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices)
            cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{i} = repmat({1:6},size(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i}));
          end
        end
        
        % maximum number of repeated exemplars from each family in naming
        cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily = 3;
        
        % only used if running Net Station, but need to set unconditionally
        % because session 1 doesn't use NS
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks = 7;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).name_isi = 0.5;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).name_stim = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_response = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback = 1.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_nametrain_1_exp_intro.txt',expParam.expName)),...
          {'nBlocks','nFamily','nSpeciesTotal','basicFamStr','contKey'},...
          {num2str(length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)),...
          num2str(length(cfg.stim.(sesName).(phaseName)(phaseCount).familyNames)),...
          num2str(cfg.stim.nSpecies),cfg.text.basicFamStr,...
          cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).image = cfg.files.speciesNumKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).imageScale = cfg.files.speciesNumKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
      end
    end % ismember
    
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     % Naming
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     phaseName = 'name';
    %
    %     if ismember(phaseName,expParam.session.(sesName).phases)
    %       for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
    %         cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
    %
    %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
    %
    %         % only use stimuli from particular families
    %         cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'Finch_', 'Warbler_'};
    %
    %         % maximum number of repeated exemplars from each family in naming
    %         cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily = 3;
    %
    %         if expParam.useNS
    %           cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 120;
    %         end
    %
    %         % durations, in seconds
    %         cfg.stim.(sesName).(phaseName)(phaseCount).name_isi = 0.5;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim = [0.5 0.7];
    %         cfg.stim.(sesName).(phaseName)(phaseCount).name_stim = 1.0;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).name_response = 2.0;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback = 1.0;
    %
    %         % do we want to play feedback beeps?
    %         cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
    %
    %         % instructions
    %         [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).text] = et_processTextInstruct(...
    %           fullfile(cfg.files.instructDir,sprintf('%s_name_2_exp_intro.txt',expParam.expName)),...
    %           {'nFamily','basicFamStr','contKey'},...
    %           {num2str(length(cfg.stim.(sesName).(phaseName)(phaseCount).familyNames)),cfg.text.basicFamStr,...
    %           cfg.keys.instructContKey});
    %         cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).image = cfg.files.speciesNumKeyImg;
    %         cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).imageScale = cfg.files.speciesNumKeyImgScale;
    %
    %         expParam.session.(sesName).(phaseName)(phaseCount).date = [];
    %         expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
    %         expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
    %       end
    %     end
    
  end % ismember
  
  %% Training Day 2-6 configuration (all these days are the same)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesNames = {'train2','train3','train4','train5','train6'};
  
  for s = 1:length(sesNames)
    sesName = sesNames{s};
    
    if ismember(sesName,expParam.sesTypes)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Name training (introduce species in a rolling fashion)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      phaseName = 'nametrain';
      
      if ismember(phaseName,expParam.session.(sesName).phases)
        for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
          cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
          cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
          cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
          
          cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
          cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
          cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
          
          % only use stimuli from particular families
          cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
          
          allSpecies = 1:cfg.stim.nSpecies;
          trainedSpecies = allSpecies(~ismember(allSpecies,cfg.stim.newSpecies));
          trainedSpecies = trainedSpecies(randperm(length(trainedSpecies)));
          
          % Increasing difficulty
          if expParam.difficulty == 1
            
            % select trainedSpecies by indexing into trainedSpecies for
            % blockSpeciesOrder
            cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = {...
              trainedSpecies([1]),...
              trainedSpecies([2]),...
              trainedSpecies([3]),...
              trainedSpecies([4]),...
              trainedSpecies([5]),...
              trainedSpecies([1:2]),...
              trainedSpecies([3:4]),...
              trainedSpecies([5,1]),...
              trainedSpecies([2:3]),...
              trainedSpecies([4:5]),...
              trainedSpecies([1:3]),...
              trainedSpecies([4,5,1]),...
              trainedSpecies([2,3,4]),...
              trainedSpecies([5,1,2]),...
              trainedSpecies([3:5]),...
              trainedSpecies([1:4]),...
              trainedSpecies([5,1,2,3]),...
              trainedSpecies([4,5,1,2]),...
              trainedSpecies([3,4,5,1]),...
              trainedSpecies([2:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5])};
            
            % hard coded stimulus indices for naming training block presentations
            % (counterbalanced). Blocks are denoted by cells. The vectors within each
            % block represent the exemplar number(s) for each species, corresponding
            % to the species numbers listed in blockSpeciesOrder (defined above). The
            % contents of each vector corresponds to the exemplar numbers for that
            % species.
            
            % Number of exemplars to show for each species
            cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
            for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices)
              cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{i} = repmat({1:6},size(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i}));
            end
            
            % Decreasing difficulty
          elseif expParam.difficulty == 2
            
            % select trainedSpecies by indexing into trainedSpecies for
            % blockSpeciesOrder
            cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = {...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:5]),...
              trainedSpecies([1:4]),...
              trainedSpecies([5,1,2,3]),...
              trainedSpecies([4,5,1,2]),...
              trainedSpecies([3,4,5,1]),...
              trainedSpecies([2:5]),...
              trainedSpecies([1:3]),...
              trainedSpecies([4,5,1]),...
              trainedSpecies([2,3,4]),...
              trainedSpecies([5,1,2]),...
              trainedSpecies([3:5]),...
              trainedSpecies([1:2]),...
              trainedSpecies([3:4]),...
              trainedSpecies([5,1]),...
              trainedSpecies([2:3]),...
              trainedSpecies([4:5]),...
              trainedSpecies([1]),...
              trainedSpecies([2]),...
              trainedSpecies([3]),...
              trainedSpecies([4]),...
              trainedSpecies([5])};
            
            % Number of exemplars to show for each species
            cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
            for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices)
              cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{i} = repmat({1:6},size(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i}));
            end
            
            % Random difficulty
          elseif expParam.difficulty == 3
            
            % hard-coded for 25 blocks
            nBlocks = 25;
            % the length of numberOfSpecies is the number of blocks
            numberOfSpecies = repmat(randperm(length(trainedSpecies)),1,ceil(nBlocks / length(trainedSpecies)));
            % randomize so the number of species doesn't repeat after
            % length(trainedSpecies) blocks
            nSpecIndex = randperm(nBlocks);
            numberOfSpecies = numberOfSpecies(nSpecIndex);
            
            % repeat the trained species numbers so we have enough species
            % numbers to choose from; not randomized because we need to
            % unique species in each block (i.e., can't have the same species
            % listed twice for a block)
            trainedSpecies_rep = repmat(trainedSpecies,1,ceil(sum(numberOfSpecies) / length(trainedSpecies)));
            
            % make sure to set up numberOfSpecies so its length is the number of blocks you want
            cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = cell(1,length(numberOfSpecies));
            specIndex = 1;
            for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)
              addTheseSpecies = trainedSpecies_rep(specIndex:specIndex+numberOfSpecies(i)-1);
              cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i} = addTheseSpecies;
              specIndex = specIndex + numberOfSpecies(i);
            end
            
            % Number of exemplars to show for each species
            cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
            for i = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices)
              cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{i} = repmat({1:6},size(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{i}));
            end
          end
          
          % hard coded order of which species are presented in each block
          % (counterbalanced). Blocks are denoted by vectors.
          %cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = {...
          %  [1, 2],...
          %  [1, 2, 3],...
          %  [1, 2, 3, 4],...
          %  [1, 2, 3, 4, 5],...
          %  [3, 4, 5, 6],...
          %  [4, 5, 6, 7],...
          %  [5, 6, 7, 8],...
          %  [6, 7, 8, 9],...
          %  [7, 8, 9, 10],...
          %  [8, 9, 10, 1],...
          %  [9, 10, 2, 3],...
          %  [10, 4, 5, 6],...
          %  [7, 8, 9, 10]};
          
          % 8 species, 6 trained, 6 untrained
          % cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder = {...
          %  [1, 2],...
          %  [1, 2, 3],...
          %  [1, 2, 3, 4],...
          %  [1, 2, 3, 4, 5],...
          %  [3, 4, 5, 6],...
          %  [4, 5, 6, 7],...
          %  [5, 6, 7, 8],...
          %  [6, 7, 8, 1],...
          %  [7, 8, 1, 2],...
          %  [8, 2, 3, 4],...
          %  [3, 4, 5, 6],...
          %  [5, 6, 7, 8],...
          %  [7, 8, 1, 2]};
          
          % hard coded stimulus indices for naming training block presentations
          % (counterbalanced). Blocks are denoted by cells. The vectors within each
          % block represent the exemplar number(s) for each species, corresponding
          % to the species numbers listed in blockSpeciesOrder (defined above). The
          % contents of each vector corresponds to the exemplar numbers for that
          % species.
          
          % 10 species, 6 trained, 6 untrained
          % cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = {...
          %   {[1, 2, 3], [1, 2, 3]},...
          %   {[4, 5, 6], [4, 5, 6], [1, 2, 3]},...
          %   {[2, 3, 4], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [3, 4, 5]},...
          %   {[5, 1, 6], [2, 3, 4], [3, 5, 6], [3, 5, 6]},...
          %   {[5, 1, 6], [2, 5, 6], [3, 5, 6], [3, 5, 6]},...
          %   {[3, 5, 6], [3, 5, 6], [3, 5, 6], [3, 5, 6]}};
          
          % % 10 species, 4 trained, 4 untrained
          % cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = {...
          %   {[1, 2], [1, 2]},...
          %   {[3, 4], [3, 4], [1, 2]},...
          %   {[2, 3], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]},...
          %   {[1, 4], [2, 3], [3, 4], [1, 2]}};
          
          % % 8 species, 6 trained, 6 untrained
          % cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices = {...
          %   {[1, 2, 3], [1, 2, 3]},...
          %   {[4, 5, 6], [4, 5, 6], [1, 2, 3]},...
          %   {[2, 3, 4], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          %   {[5, 1, 6], [4, 5, 6], [1, 2, 3], [4, 5, 6]},...
          %   {[5, 1, 6], [4, 5, 6], [1, 2, 3], [3, 4, 5]},...
          %   {[4, 5, 6], [6, 1, 2], [1, 2, 3], [4, 5, 6]},...
          %   {[1, 2, 3], [3, 4, 5], [4, 5, 6], [1, 2, 3]}};
          
          % maximum number of repeated exemplars from each family in naming
          cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily = 3;
          
          % only used if running Net Station, but need to set unconditionally
          % because session 1 doesn't use NS
          cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks = 7;
          
          % durations, in seconds
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi = 0.5;
          cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim = [0.5 0.7];
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim = 1.0;
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response = 2.0;
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback = 1.0;
          
          % do we want to play feedback beeps?
          cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
          cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
          cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
          cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
          cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
          
          % instructions
          [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).text] = et_processTextInstruct(...
            fullfile(cfg.files.instructDir,sprintf('%s_nametrain_1_exp_intro.txt',expParam.expName)),...
            {'nBlocks','nFamily','nSpeciesTotal','basicFamStr','contKey'},...
            {num2str(length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)),...
            num2str(length(cfg.stim.(sesName).(phaseName)(phaseCount).familyNames)),...
            num2str(cfg.stim.nSpecies),cfg.text.basicFamStr,...
            cfg.keys.instructContKey});
          cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).image = cfg.files.speciesNumKeyImg;
          cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).imageScale = cfg.files.speciesNumKeyImgScale;
          
          expParam.session.(sesName).(phaseName)(phaseCount).date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
      end
    end
  end % s
  
  %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %     % Naming
  %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %     phaseName = 'name';
  %
  %     if ismember(phaseName,expParam.session.(sesName).phases)
  %       for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
  %         cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
  %
  %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
  %
  %         % only use stimuli from particular families
  %         cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'Finch_', 'Warbler_'};
  %
  %         % maximum number of repeated exemplars from each family in naming
  %         cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily = 3;
  %
  %         if expParam.useNS
  %           cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 120;
  %         end
  %
  %         % durations, in seconds
  %         cfg.stim.(sesName).(phaseName)(phaseCount).name_isi = 0.5;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim = [0.5 0.7];
  %         cfg.stim.(sesName).(phaseName)(phaseCount).name_stim = 1.0;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).name_response = 2.0;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback = 1.0;
  %
  %         % do we want to play feedback beeps?
  %         cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
  %
  %         % instructions
  %         [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).text] = et_processTextInstruct(...
  %           fullfile(cfg.files.instructDir,sprintf('%s_name_2_exp_intro.txt',expParam.expName)),...
  %           {'nFamily','basicFamStr','contKey'},...
  %           {num2str(length(cfg.stim.(sesName).(phaseName)(phaseCount).familyNames)),cfg.text.basicFamStr,...
  %           cfg.keys.instructContKey});
  %         cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).image = cfg.files.speciesNumKeyImg;
  %         cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).imageScale = cfg.files.speciesNumKeyImgScale;
  %
  %         expParam.session.(sesName).(phaseName)(phaseCount).date = [];
  %         expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
  %         expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
  %       end
  %     end
  
  %% Posttest configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'posttest_eye';
  
  if ismember(sesName,expParam.sesTypes)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching - practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        % do we want to use the stimuli from a previous phase? Set to an empty
        % cell if not.
        cfg.stim.(sesName).(phaseName)(phaseCount).usePrevPhase = {'pretest','prac_match',1};
        cfg.stim.(sesName).(phaseName)(phaseCount).reshuffleStims = true;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        % % do we want to use the stimuli from a previous phase? Set to an empty
        % % cell if not.
        % cfg.stim.(sesName).(phaseName)(phaseCount).usePrevPhase = {'pretest','match',phaseCount};
        % cfg.stim.(sesName).(phaseName)(phaseCount).reshuffleStims = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).writePairsToFile = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
        
        if phaseCount == 1 || phaseCount == 3 || phaseCount == 4 || phaseCount == 6 || phaseCount == 7 || phaseCount == 9 || phaseCount == 10 || phaseCount == 12
          % 360 trials per phase (for eyetracking matching and moving
          % window phases)
          
          % number per species per family; every stimulus is in both the
          % same and the different condition.
          cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained;
          % rmStims_orig is false because all stimuli are used in both "same"
          % and "diff" conditions
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
          
          cfg.stim.(sesName).(phaseName)(phaseCount).nSameNew = cfg.stim.nNewExemplars / 2;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiffNew = cfg.stim.nNewExemplars / 2;
          
          % % number per species per family (half because each stimulus is only in
          % % same or different condition)
          % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained / 2;
          % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained / 2;
          % % rmStims_orig is true because half of stimuli are in "same"
          % cond and % half are in "diff"
          % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
          
          % % this is how to force all stimuli to be both stim1 and stim2
          % % in "same" and "diff" conds
          % cfg.stim.(sesName).(phaseName)(phaseCount).reuseStimsSameDiff = true;
          
          % rmStims_pair is true because pairs are removed after they're added
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
          cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
          
        elseif phaseCount == 2 || phaseCount == 5 || phaseCount == 8 || phaseCount == 11
          % 2 blocks, 180 trials per block (for eyetracking foveal and
          % peripheral masking blocks)
          
          % splits stimuli in half, one half for each block
          cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks = 2;
          
          % % every stimulus is in both the same and the different condition.
          % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained;
          % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained;
          % % rmStims_orig is false because all stimuli are used in both "same"
          % % and "diff" conditions
          % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
          
          % number per species per family (half because each stimulus is only in
          % same or different condition)
          cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained / 2;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained / 2;
          
          cfg.stim.(sesName).(phaseName)(phaseCount).nSameNew = cfg.stim.nNewExemplars / 4;
          cfg.stim.(sesName).(phaseName)(phaseCount).nDiffNew = cfg.stim.nNewExemplars / 4;
          
          % rmStims_orig is true because half of stimuli are in "same" cond and
          % half are in "diff"
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
          
          % this is how to force all stimuli to be both stim1 and stim2 in
          % "same" and "diff" conds
          cfg.stim.(sesName).(phaseName)(phaseCount).reuseStimsSameDiff = true;
          
          % rmStims_pair is true because pairs are removed after they're added
          cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
          cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
        end
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamilies (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseCount).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseCount).matchTextPrompt = matchTextPrompt;
        
        %cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 240;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_3_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
  end % ismember
  
  %% pretest EEG configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'posttest_eeg';
  
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).writePairsToFile = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
        
        % 360 trials per phase
        
        % number per species per family; every stimulus is in both the
        % same and the different condition.
        cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained;
        cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained;
        % rmStims_orig is false because all stimuli are used in both "same"
        % and "diff" conditions
        cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).nSameNew = cfg.stim.nNewExemplars / 2;
        cfg.stim.(sesName).(phaseName)(phaseCount).nDiffNew = cfg.stim.nNewExemplars / 2;
        
        % % number per species per family (half because each stimulus is only in
        % % same or different condition)
        % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.nTrained / 2;
        % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.nTrained / 2;
        % % rmStims_orig is true because half of stimuli are in "same"
        % cond and % half are in "diff"
        % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
        
        % % this is how to force all stimuli to be both stim1 and stim2
        % % in "same" and "diff" conds
        % cfg.stim.(sesName).(phaseName)(phaseCount).reuseStimsSameDiff = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamilies (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseCount).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseCount).matchTextPrompt = matchTextPrompt;
        
        % only used if running Net Station, but need to set unconditionally
        % because session 1 doesn't use NS
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 240;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseCount).match_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_3_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Comparison task
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     phaseName = 'compare';
%     
%     if ismember(phaseName,expParam.session.(sesName).phases)
%       for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
%         
%       end
%     end
    
  end % ismember
  
  %% process the stimuli for the entire experiment
  
  [cfg,expParam] = et_processStims(cfg,expParam);
  
  %% write stimuli to file
  
  for s = 1:expParam.nSessions
    sesName = expParam.sesTypes{s};
    
    matchCount = 0;
    
    for p = 1:length(expParam.session.(sesName).phases)
      phaseName = expParam.session.(sesName).phases{p};
      
      switch phaseName
        
        case{'match'}
          % Subordinate Matching task (same/different)
          matchCount = matchCount + 1;
          phaseCount = matchCount;
          
          phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
          
          if phaseCfg.writePairsToFile
            if isfield(phaseCfg,'nBlocks') && ~isempty(phaseCfg.nBlocks) && phaseCfg.nBlocks > 1
              for b = 1:phaseCfg.nBlocks
                allStims = expParam.session.(sesName).(phaseName)(phaseCount).allStims{b};
                stim2 = allStims([allStims.matchStimNum] == 2);
                % initialize for storing stimulus 1s
                stim1 = struct([]);
                fn = fieldnames(stim2);
                for i = 1:length(fn)
                  stim1(1).(fn{i}) = [];
                end
                for i = 1:length(stim2)
                  % find stim2's corresponding pair, contingent upon whether this is a same
                  % or diff stimulus
                  if isfield(cfg.stim,'newSpecies')
                    if stim2(i).same
                      % same (same species)
                      stim1(i) = allStims(...
                        ([allStims.familyNum] == stim2(i).familyNum) &...
                        ([allStims.speciesNum] == stim2(i).speciesNum) &...
                        ([allStims.trained] == stim2(i).trained) &...
                        ([allStims.new] == stim2(i).new) &...
                        ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                        ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                      
                    else
                      % diff (different species)
                      stim1(i) = allStims(...
                        ([allStims.familyNum] == stim2(i).familyNum) &...
                        ([allStims.speciesNum] ~= stim2(i).speciesNum) &...
                        ([allStims.trained] == stim2(i).trained) &...
                        ([allStims.new] == stim2(i).new) &...
                        ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                        ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                    end
                  else
                    if stim2(i).same
                      % same (same species)
                      stim1(i) = allStims(...
                        ([allStims.familyNum] == stim2(i).familyNum) &...
                        ([allStims.speciesNum] == stim2(i).speciesNum) &...
                        ([allStims.trained] == stim2(i).trained) &...
                        ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                        ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                      
                    else
                      % diff (different species)
                      stim1(i) = allStims(...
                        ([allStims.familyNum] == stim2(i).familyNum) &...
                        ([allStims.speciesNum] ~= stim2(i).speciesNum) &...
                        ([allStims.trained] == stim2(i).trained) &...
                        ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                        ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                    end
                  end
                end
                
                % write the stimuli to file
                fid = fopen(fullfile(cfg.files.subSaveDir,sprintf('participant%d_%s_%s%d_b%d.txt',str2double(expParam.subject(end-2:end)),sesName,phaseName,phaseCount,b)),'w+t');
                for i = 1:length(stim1)
                  file1 = stim1(i).fileName;
                  familyStr1 = stim1(i).familyStr;
                  speciesStr1 = stim1(i).speciesStr;
                  exempNum1 = stim1(i).exemplarNum;
                  
                  file2 = stim2(i).fileName;
                  familyStr2 = stim2(i).familyStr;
                  speciesStr2 = stim2(i).speciesStr;
                  exempNum2 = stim2(i).exemplarNum;
                  
                  trained = stim1(i).trained;
                  same = stim1(i).same;
                  new = stim1(i).new;
                  if isfield(stim1(i),'difficulty')
                    difficulty = stim1(i).difficulty;
                    fprintf(fid,'%s\t%s\t%d\t%s\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%.2f\n',familyStr1,speciesStr1,exempNum1,familyStr2,speciesStr2,exempNum2,file1,file2,trained,same,new,difficulty);
                  else
                    fprintf(fid,'%s\t%s\t%d\t%s\t%s\t%d\t%s\t%s\t%d\t%d\t%d\n',familyStr1,speciesStr1,exempNum1,familyStr2,speciesStr2,exempNum2,file1,file2,trained,same,new);
                  end
                end
                fclose(fid);
              end
            else
              allStims = expParam.session.(sesName).(phaseName)(phaseCount).allStims;
              stim2 = allStims([allStims.matchStimNum] == 2);
              % initialize for storing stimulus 1s
              stim1 = struct([]);
              fn = fieldnames(stim2);
              for i = 1:length(fn)
                stim1(1).(fn{i}) = [];
              end
              for i = 1:length(stim2)
                % find stim2's corresponding pair, contingent upon whether this is a same
                % or diff stimulus
                if isfield(cfg.stim,'newSpecies')
                  if stim2(i).same
                    % same (same species)
                    stim1(i) = allStims(...
                      ([allStims.familyNum] == stim2(i).familyNum) &...
                      ([allStims.speciesNum] == stim2(i).speciesNum) &...
                      ([allStims.trained] == stim2(i).trained) &...
                      ([allStims.new] == stim2(i).new) &...
                      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                    
                  else
                    % diff (different species)
                    stim1(i) = allStims(...
                      ([allStims.familyNum] == stim2(i).familyNum) &...
                      ([allStims.speciesNum] ~= stim2(i).speciesNum) &...
                      ([allStims.trained] == stim2(i).trained) &...
                      ([allStims.new] == stim2(i).new) &...
                      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                  end
                else
                  if stim2(i).same
                    % same (same species)
                    stim1(i) = allStims(...
                      ([allStims.familyNum] == stim2(i).familyNum) &...
                      ([allStims.speciesNum] == stim2(i).speciesNum) &...
                      ([allStims.trained] == stim2(i).trained) &...
                      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                    
                  else
                    % diff (different species)
                    stim1(i) = allStims(...
                      ([allStims.familyNum] == stim2(i).familyNum) &...
                      ([allStims.speciesNum] ~= stim2(i).speciesNum) &...
                      ([allStims.trained] == stim2(i).trained) &...
                      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
                      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
                  end
                end
              end
              
              % write the stimuli to file
              fid = fopen(fullfile(cfg.files.subSaveDir,sprintf('participant%d_%s_%s%d.txt',str2double(expParam.subject(end-2:end)),sesName,phaseName,phaseCount)),'w+t');
              for i = 1:length(stim1)
                file1 = stim1(i).fileName;
                familyStr1 = stim1(i).familyStr;
                speciesStr1 = stim1(i).speciesStr;
                exempNum1 = stim1(i).exemplarNum;
                
                file2 = stim2(i).fileName;
                familyStr2 = stim2(i).familyStr;
                speciesStr2 = stim2(i).speciesStr;
                exempNum2 = stim2(i).exemplarNum;
                
                trained = stim1(i).trained;
                same = stim1(i).same;
                new = stim1(i).new;
                if isfield(stim1(i),'difficulty')
                  difficulty = stim1(i).difficulty;
                  fprintf(fid,'%s\t%s\t%d\t%s\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%.2f\n',familyStr1,speciesStr1,exempNum1,familyStr2,speciesStr2,exempNum2,file1,file2,trained,same,new,difficulty);
                else
                  fprintf(fid,'%s\t%s\t%d\t%s\t%s\t%d\t%s\t%s\t%d\t%d\t%d\n',familyStr1,speciesStr1,exempNum1,familyStr2,speciesStr2,exempNum2,file1,file2,trained,same,new);
                end
              end
              fclose(fid);
            end
          end
          
      end
    end
  end % s
  
  %% save the parameters
  
  fprintf('Saving experiment parameters: %s...',cfg.files.expParamFile);
  save(cfg.files.expParamFile,'cfg','expParam');
  fprintf('Done.\n');
  
  %% print out the experiment length
  
  % % maximum duration
  % et_calcExpDuration(cfg,expParam,'max');
  % medium duration
  et_calcExpDuration(cfg,expParam,'med');
  % % minimum duration
  % et_calcExpDuration(cfg,expParam,'min');
  
end % if expParam.sessionNum == 1

end % function

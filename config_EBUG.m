function [cfg,expParam] = config_EBUG(cfg,expParam)
% function [cfg,expParam] = config_EBUG(cfg,expParam)
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

% what host is netstation running on?
if expParam.useNS
  expParam.NSPort = 55513;
  
  % % D458
  % expParam.NSHost = '128.138.223.251';
  
  % D464
  expParam.NSHost = '128.138.223.26';
  
  expParam.baselineRecordSecs = 20.0;
end

% sound defaults, these get set for each phase
playSound = true;
correctSound = 1000;
incorrectSound = 300;
correctVol = 0.4;
incorrectVol = 0.6;

% whether to print trial details to the command window
cfg.text.printTrialInfo = true;

% matching task defaults
matchTextPrompt = true;

%% Experiment session information

% Set the number of sessions
expParam.nSessions = 9;

% Pre-test, training day 1, training days 1-6, post-test, post-test delayed.
expParam.sesTypes = {'pretest','train1','train2','train3','train4','train5','train6','posttest','posttest_delay'};

% set up a field for each session type
expParam.session.pretest.phases = {'prac_match','match','prac_recog','recog'};
expParam.session.train1.phases = {'prac_name','nametrain','name','match'};
expParam.session.train2.phases = {'match','name','match'};
expParam.session.train3.phases = {'match','name','match'};
expParam.session.train4.phases = {'match','name','match'};
expParam.session.train5.phases = {'match','name','match'};
expParam.session.train6.phases = {'match','name','match'};
expParam.session.posttest.phases = {'match','prac_recog','recog'};
expParam.session.posttest_delay.phases = {'prac_match','match','prac_recog','recog'};

% % demo - debug
% expParam.nSessions = 2;
% expParam.sesTypes = {'pretest','train1'};
% % expParam.session.pretest.phases = {'prac_match','prac_recog'};
% expParam.session.pretest.phases = {'prac_recog','recog'};
% expParam.session.train1.phases = {'prac_name','nametrain','name'};

% % debug
% expParam.nSessions = 1;
% expParam.sesTypes = {'train1'};
% expParam.session.train1.phases = {'prac_name','nametrain','name'};

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
  
  % blink break (set to 0 if you don't want breaks)
  if expParam.useNS
    % timer in secs for when to take a blink break (only when useNS=true)
    cfg.stim.secUntilBlinkBreak = 45.0;
  else
    % timer in secs for when to take a blink break (only when useNS=false)
    cfg.stim.secUntilBlinkBreak = 90.0;
  end
  
  %% Stimulus parameters
  
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
  
  % family names correspond to the directories in which stimuli reside
  cfg.stim.familyNames = {'a','s'};
  
  % assumes that each family has the same number of species
  cfg.stim.nSpecies = 10;
  
  % whether to use the same species order across families
  cfg.stim.yokeSpecies = false;
  if cfg.stim.yokeSpecies
    cfg.stim.yokeTogether = [1 1];
  end
  
  % Number of trained and untrained exemplars per species per family
  cfg.stim.nTrained = 6;
  cfg.stim.nUntrained = 6;
  
  % save an individual stimulus list for each subject
  cfg.stim.stimListFile = fullfile(cfg.files.subSaveDir,'stimList.txt');
  
  % create the stimulus list if it doesn't exist
  shuffleSpecies = true;
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
  else
    cfg.stim.famNumBasic = 2;
    cfg.stim.famNumSubord = 1;
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
  cfg.stim.useSeparatePracStims = true;
  
  if expParam.runPractice
    % practice exemplars per species per family for all phases except
    % recognition (recognition stim count is determined by nStudyTarg and
    % nStudyLure in each prac_recog phase defined below)
    cfg.stim.practice.nPractice = 2;
    
    if cfg.stim.useSeparatePracStims
      cfg.files.stimDir_prac = fullfile(cfg.files.imgDir,'PracticeBirds');
      cfg.stim.practice.familyNames = {'Perching_','Wading_'};
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
        cfg.stim.practice.yokeTogether = [1 1];
      end
      
      cfg.stim.practice.stimListFile = fullfile(cfg.files.subSaveDir,'stimList_prac.txt');
      
      shuffleSpecies = true;
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
      cfg.stim.practice.famNumBasic = cfg.stim.famNumBasic;
      cfg.stim.practice.famNumSubord = cfg.stim.famNumSubord;
      cfg.stim.practice.nSpecies = 2;
      cfg.stim.practice.yokeSpecies = false;
      if cfg.stim.practice.yokeSpecies
        cfg.stim.practice.yokeTogether = [1 1];
      end
      cfg.stim.practice.nExemplars = repmat(cfg.stim.practice.nPractice,length(cfg.stim.practice.familyNames),cfg.stim.practice.nSpecies);
    end
  end
  
  %% Define the response keys
  
  % the experimenter's secret key to continue the experiment
  cfg.keys.expContinue = 'g';
  
  % which row of keys to use in matching and recognition tasks. Can be
  % 'upper' or 'middle'
  cfg.keys.keyRow = 'upper';
  
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
  
  % recognition keys
  if strcmp(cfg.keys.keyRow,'upper')
    % upper row
    cfg.keys.recogKeyNames = {{'q','w','e','r','u'},{'r','u','i','o','p'}};
  elseif strcmp(cfg.keys.keyRow,'middle')
    % middle row
    if ismac || isunix
      cfg.keys.recogKeyNames = {{'a','s','d','f','j'},{'f','j','k','l',';:'}};
    elseif ispc
      cfg.keys.recogKeyNames = {{'a','s','d','f','j'},{'f','j','k','l',';'}};
    end
  end
  
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
  
  if strcmp(cfg.keys.keyRow,'upper')
    cfg.files.recogTestRespKeyImg = fullfile(cfg.files.resDir,sprintf('recogTest_resp_black_upper_%d.jpg',cfg.keys.recogKeySet));
    %cfg.files.recogTestRespKeyImg = fullfile(cfg.files.resDir,sprintf('recogTest_resp_white_upper_%d.jpg',cfg.keys.recogKeySet));
  elseif strcmp(cfg.keys.keyRow,'middle')
    cfg.files.recogTestRespKeyImg = fullfile(cfg.files.resDir,sprintf('recogTest_resp_black_middle_%d.jpg',cfg.keys.recogKeySet));
    %cfg.files.recogTestRespKeyImg = fullfile(cfg.files.resDir,sprintf('recogTest_resp_white_middle_%d.jpg',cfg.keys.recogKeySet));
  end
  
  % scale image down (< 1) or up (> 1)
  cfg.files.recogTestRespKeyImgScale = 0.4;
  
  %% Screen, text, and symbol configuration for size and color
  
  % Choose a gray color value to be used as experiment backdrop
  %cfg.screen.gray = 181;
  cfg.screen.gray = 210;
  
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
  
  %% pretest configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'pretest';
  
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching - practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = false;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.practice.familyNames;
        
        % every stimulus is in both the same and the different condition.
        cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.practice.nPractice;
        cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.practice.nPractice;
        % rmStims_orig is false because all stimuli are used in both "same"
        % and "diff" conditions
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = false;
        
        % % number per species per family (half because each stimulus is only in
        % % same or different condition)
        % cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.practice.nPractice / 2;
        % cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.practice.nPractice / 2;
        % % rmStims_orig is true because half of stimuli are in "same" cond and
        % % half are in "diff"
        % cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamiles (and multiply by 2
        % if rmStims_orig=false). nSpecies = (nSame + nDiff) in practice.
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseNum).stim2MinRepeatSpacing = 0;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseNum).matchTextPrompt = matchTextPrompt;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_response = 2.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.match.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_1_practice_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        % every stimulus is in both the same and the different condition.
        cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained;
        cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained;
        % rmStims_orig is false because all stimuli are used in both "same"
        % and "diff" conditions
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = false;
        
        % % number per species per family (half because each stimulus is only in
        % % same or different condition)
        % cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained / 2;
        % cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained / 2;
        % % rmStims_orig is true because half of stimuli are in "same" cond and
        % % half are in "diff"
        % cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamiles (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseNum).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseNum).matchTextPrompt = matchTextPrompt;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 240;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_response = 2.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.match.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_2_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Recognition - practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_recog';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = false;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.practice.familyNames;
        
        cfg.stim.(sesName).(phaseName)(phaseNum).nBlocks = 1;
        % number of target and lure stimuli per species per family per study/test
        % block. Assumes all targets and lures are tested in a block.
        cfg.stim.(sesName).(phaseName)(phaseNum).nStudyTarg = 2;
        cfg.stim.(sesName).(phaseName)(phaseNum).nTestLure = 1;
        
        % maximum number of same family in a row during study task
        cfg.stim.(sesName).(phaseName)(phaseNum).studyMaxConsecFamily = 0;
        % maximum number of targets or lures in a row during test task
        cfg.stim.(sesName).(phaseName)(phaseNum).testMaxConsec = 0;
        
        % do not reuse recognition stimuli in other parts of the experiment
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_preTarg = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_targ = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_preStim = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_stim = 1.5;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_response = 10.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_1_intro.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro(2).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_2_intro_recoll.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro(3).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_3_intro_other.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro(3).image = cfg.files.recogTestRespKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro(3).imageScale = cfg.files.recogTestRespKeyImgScale;
        
        nExemplars = cfg.stim.(sesName).(phaseName)(phaseNum).nStudyTarg * cfg.stim.practice.nSpecies * length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames);
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogStudy.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_4_practice_study.txt',expParam.expName)),...
          {'nExemplars','contKey'},{num2str(nExemplars),cfg.keys.instructContKey});
        
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_5_practice_test.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.image = cfg.files.recogTestRespKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.imageScale = cfg.files.recogTestRespKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Recognition
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'recog';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        cfg.stim.(sesName).(phaseName)(phaseNum).nBlocks = 8;
        % number of target and lure stimuli per species per family per study/test
        % block. Assumes all targets and lures are tested in a block.
        cfg.stim.(sesName).(phaseName)(phaseNum).nStudyTarg = 2;
        cfg.stim.(sesName).(phaseName)(phaseNum).nTestLure = 1;
        % maximum number of same family in a row during study task
        cfg.stim.(sesName).(phaseName)(phaseNum).studyMaxConsecFamily = 0;
        % maximum number of targets or lures in a row during test task
        cfg.stim.(sesName).(phaseName)(phaseNum).testMaxConsec = 0;
        
        % do not reuse recognition stimuli in other parts of the experiment
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nBlocks = 4;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_preTarg = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_targ = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_preStim = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_stim = 1.5;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_response = 10.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        nExemplars = cfg.stim.(sesName).(phaseName)(phaseNum).nStudyTarg * cfg.stim.nSpecies * length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames);
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_6_exp_intro.txt',expParam.expName)),...
          {'nBlocks','contKey'},{num2str(cfg.stim.(sesName).(phaseName)(phaseNum).nBlocks),cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogStudy.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_7_exp_study.txt',expParam.expName)),...
          {'nExemplars','contKey'},{num2str(nExemplars),cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_8_exp_test.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.image = cfg.files.recogTestRespKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.imageScale = cfg.files.recogTestRespKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
  end
  
  %% Training Day 1 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'train1';
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Naming
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_name';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = false;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.practice.familyNames;
        
        % maximum number of repeated exemplars from each family in naming
        cfg.stim.(sesName).(phaseName)(phaseNum).nameMaxConsecFamily = 3;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).name_isi = 0.5;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).name_stim = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_response = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_feedback = 1.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_name_1_practice_intro.txt',expParam.expName)),...
          {'nFamily','basicFamStr','contKey'},...
          {num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames)),cfg.text.basicFamStr,cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.image = cfg.files.speciesNumKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.imageScale = cfg.files.speciesNumKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Viewing+Naming (introduce species in a rolling fashion)
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     phaseName = 'viewname';
%     
%     if ismember(phaseName,expParam.session.(sesName).phases)
%       for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
%         cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
%         cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
%         
%         % only use stimuli from particular families
%         cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
%         
%         % hard coded order of which species are presented in each block
%         % (counterbalanced). Blocks are denoted by vectors.
%         cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder = {...
%           [1, 2],...
%           [1, 2, 3],...
%           [1, 2, 3, 4],...
%           [1, 2, 3, 4, 5],...
%           [3, 4, 5, 6],...
%           [4, 5, 6, 7],...
%           [5, 6, 7, 8],...
%           [6, 7, 8, 9],...
%           [7, 8, 9, 10],...
%           [8, 9, 10, 1],...
%           [9, 10, 2, 3],...
%           [10, 4, 5, 6],...
%           [7, 8, 9, 10]};
%         
%         % hard coded stimulus indices for viewing block presentations
%         % (counterbalanced). Blocks are denoted by cells. The vectors within each
%         % block represent the exemplar number(s) for each species, corresponding
%         % to the species numbers listed in blockSpeciesOrder (defined above). The
%         % contents of each vector corresponds to the exemplar numbers for that
%         % species.
%         
%         cfg.stim.(sesName).(phaseName)(phaseNum).viewIndices = {...
%           {[1], [1]},...
%           {[4], [4], [1]},...
%           {[2], [2], [4], [1]},...
%           {[5], [5], [2], [4], [1]},...
%           {[5], [2], [4], [1]},...
%           {[5], [2], [4], [1]},...
%           {[5], [2], [4], [1]},...
%           {[5], [2], [4], [1]},...
%           {[5], [2], [4], [1]},...
%           {[5], [2], [4], [3]},...
%           {[5], [2], [3], [3]},...
%           {[5], [2], [3], [3]},...
%           {[3], [3], [3], [3]}};
%         
%         % hard coded stimulus indices for naming block presentations
%         % (counterbalanced). Blocks are denoted by cells. The vectors within each
%         % block represent the exemplar number(s) for each species, corresponding
%         % to the species numbers listed in blockSpeciesOrder (defined above). The
%         % contents of each vector corresponds to the exemplar numbers for that
%         % species.
%         
%         cfg.stim.(sesName).(phaseName)(phaseNum).nameIndices = {...
%           {[2, 3], [2, 3]},...
%           {[5, 6], [5, 6], [2, 3]},...
%           {[3, 4], [3, 4], [5, 6], [2, 3]},...
%           {[1, 6], [1, 6], [3, 4], [5, 6], [2, 3]},...
%           {[1, 6], [3, 4], [5, 6], [2, 3]},...
%           {[1, 6], [3, 4], [5, 6], [2, 3]},...
%           {[1, 6], [3, 4], [5, 6], [2, 3]},...
%           {[1, 6], [3, 4], [5, 6], [2, 3]},...
%           {[1, 6], [3, 4], [5, 6], [2, 3]},...
%           {[1, 6], [3, 4], [5, 6], [4, 5]},...
%           {[1, 6], [3, 4], [5, 6], [5, 6]},...
%           {[1, 6], [5, 6], [5, 6], [5, 6]},...
%           {[5, 6], [5, 6], [5, 6], [5, 6]}};
%         
%         % maximum number of repeated exemplars from each family in viewname/view
%         cfg.stim.(sesName).(phaseName)(phaseNum).viewMaxConsecFamily = 3;
%         
%         % maximum number of repeated exemplars from each family in viewname/name
%         cfg.stim.(sesName).(phaseName)(phaseNum).nameMaxConsecFamily = 3;
%         
%         if expParam.useNS
%           cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nBlocks = 7;
%         end
%         
%         % durations, in seconds
%         cfg.stim.(sesName).(phaseName)(phaseNum).view_isi = 0.8;
%         cfg.stim.(sesName).(phaseName)(phaseNum).view_preStim = 0.2;
%         cfg.stim.(sesName).(phaseName)(phaseNum).view_stim = 4.0;
%         cfg.stim.(sesName).(phaseName)(phaseNum).name_isi = 0.5;
%         cfg.stim.(sesName).(phaseName)(phaseNum).name_preStim = [0.5 0.7];
%         cfg.stim.(sesName).(phaseName)(phaseNum).name_stim = 1.0;
%         cfg.stim.(sesName).(phaseName)(phaseNum).name_response = 2.0;
%         cfg.stim.(sesName).(phaseName)(phaseNum).name_feedback = 1.0;
%         
%         % do we want to play feedback beeps?
%         cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
%         cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
%         cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
%         cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
%         cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
%         
%         % instructions (view)
%         [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.view.text] = et_processTextInstruct(...
%           fullfile(cfg.files.instructDir,sprintf('%s_viewname_1_intro.txt',expParam.expName)),...
%           {'nBlocks','nFamily','nSpeciesTotal','basicFamStr','contKey'},...
%           {num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder)),...
%           num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames)),...
%           num2str(cfg.stim.nSpecies),cfg.text.basicFamStr,...
%           cfg.keys.instructContKey});
%         cfg.stim.(sesName).(phaseName)(phaseNum).instruct.view.image = cfg.files.speciesNumKeyImg;
%         cfg.stim.(sesName).(phaseName)(phaseNum).instruct.view.imageScale = cfg.files.speciesNumKeyImgScale;
%         
%         % instructions (name)
%         [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.text] = et_processTextInstruct(...
%           fullfile(cfg.files.instructDir,sprintf('%s_nametrain_1_exp_intro.txt',expParam.expName)),...
%           {'nBlocks','nFamily','nSpeciesTotal','basicFamStr','contKey'},...
%           {num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder)),...
%           num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames)),...
%           num2str(cfg.stim.nSpecies),cfg.text.basicFamStr,...
%           cfg.keys.instructContKey});
%         cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.image = cfg.files.speciesNumKeyImg;
%         cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.imageScale = cfg.files.speciesNumKeyImgScale;
%
%         expParam.session.(sesName).(phaseName)(phaseNum).view.date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
%         expParam.session.(sesName).(phaseName)(phaseNum).view.startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
%         expParam.session.(sesName).(phaseName)(phaseNum).view.endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
%         expParam.session.(sesName).(phaseName)(phaseNum).name.date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
%         expParam.session.(sesName).(phaseName)(phaseNum).name.startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
%         expParam.session.(sesName).(phaseName)(phaseNum).name.endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
%       end
%     end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Name training (introduce species in a rolling fashion)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'nametrain';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        % hard coded order of which species are presented in each block
        % (counterbalanced). Blocks are denoted by vectors.
        cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder = {...
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
        
        % hard coded stimulus indices for naming training block presentations
        % (counterbalanced). Blocks are denoted by cells. The vectors within each
        % block represent the exemplar number(s) for each species, corresponding
        % to the species numbers listed in blockSpeciesOrder (defined above). The
        % contents of each vector corresponds to the exemplar numbers for that
        % species.
        
        cfg.stim.(sesName).(phaseName)(phaseNum).nameIndices = {...
          {[1, 2, 3], [1, 2, 3]},...
          {[4, 5, 6], [4, 5, 6], [1, 2, 3]},...
          {[2, 3, 4], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          {[5, 1, 6], [5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          {[5, 1, 6], [2, 3, 4], [4, 5, 6], [1, 2, 3]},...
          {[5, 1, 6], [2, 3, 4], [4, 5, 6], [3, 4, 5]},...
          {[5, 1, 6], [2, 3, 4], [3, 5, 6], [3, 5, 6]},...
          {[5, 1, 6], [2, 5, 6], [3, 5, 6], [3, 5, 6]},...
          {[3, 5, 6], [3, 5, 6], [3, 5, 6], [3, 5, 6]}};
        
        % maximum number of repeated exemplars from each family in naming
        cfg.stim.(sesName).(phaseName)(phaseNum).nameMaxConsecFamily = 3;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nBlocks = 7;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).name_isi = 0.5;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).name_stim = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_response = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_feedback = 1.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_nametrain_1_exp_intro.txt',expParam.expName)),...
          {'nBlocks','nFamily','nSpeciesTotal','basicFamStr','contKey'},...
          {num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder)),...
          num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames)),...
          num2str(cfg.stim.nSpecies),cfg.text.basicFamStr,...
          cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.image = cfg.files.speciesNumKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.imageScale = cfg.files.speciesNumKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseNum).blockSpeciesOrder));
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Naming
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'name';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = true;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        % maximum number of repeated exemplars from each family in naming
        cfg.stim.(sesName).(phaseName)(phaseNum).nameMaxConsecFamily = 3;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 120;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).name_isi = 0.5;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).name_stim = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_response = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).name_feedback = 1.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_name_2_exp_intro.txt',expParam.expName)),...
          {'nFamily','basicFamStr','contKey'},...
          {num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames)),cfg.text.basicFamStr,cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.image = cfg.files.speciesNumKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.imageScale = cfg.files.speciesNumKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = true;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        % % every stimulus is in both the same and the different condition.
        % cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained;
        % cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained;
        % % rmStims_orig is false because all stimuli are used in both "same"
        % % and "diff" conditions
        % cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = false;
        
        % number per species per family (half because each stimulus is only in
        % same or different condition)
        cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained / 2;
        cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained / 2;
        % rmStims_orig is true because half of stimuli are in "same" cond and
        % half are in "diff"
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamiles (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseNum).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseNum).matchTextPrompt = matchTextPrompt;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 240;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.match.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_2_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
  end
  
  %% Training Day 2-6 configuration (all these days are the same)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesNames = {'train2','train3','train4','train5','train6'};
  
  for s = 1:length(sesNames)
    sesName = sesNames{s};
    
    if ismember(sesName,expParam.sesTypes)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Matching (1 and 2)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      phaseName = 'match';
      
      if ismember(phaseName,expParam.session.(sesName).phases)
        for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
          cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
          if phaseNum == 2
            cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = true;
          else
            cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
          end
          
          % only use stimuli from particular families
          cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
          
          % % every stimulus is in both the same and the different condition.
          % cfg.stim.(sesName).(phaseName)(matchNum).nSame = cfg.stim.nTrained;
          % cfg.stim.(sesName).(phaseName)(matchNum).nDiff = cfg.stim.nTrained;
          % % rmStims_orig is false because all stimuli are used in both "same"
          % % and "diff" conditions
          % cfg.stim.(sesName).(phaseName)(matchNum).rmStims_orig = false;
          
          % number per species per family (half because each stimulus is only in
          % same or different condition)
          cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained / 2;
          cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained / 2;
          % rmStims_orig is true because half of stimuli are in "same" cond and
          % half are in "diff"
          cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = true;
          
          % rmStims_pair is true because pairs are removed after they're added
          cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_pair = true;
          cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
          
          % nTrials = (nSame + nDiff) * nSpecies * nFamiles (and multiply by 2
          % if rmStims_orig=false)
          
          % minimum number of trials needed between exact repeats of a given
          % stimulus as stim2
          cfg.stim.(sesName).(phaseName)(phaseNum).stim2MinRepeatSpacing = 2;
          % whether to have "same" and "diff" text with the response prompt
          cfg.stim.(sesName).(phaseName)(phaseNum).matchTextPrompt = matchTextPrompt;
          
          if expParam.useNS
            cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 240;
          end
          
          % durations, in seconds
          cfg.stim.(sesName).(phaseName)(phaseNum).match_isi = 0.0;
          cfg.stim.(sesName).(phaseName)(phaseNum).match_stim1 = 0.8;
          cfg.stim.(sesName).(phaseName)(phaseNum).match_stim2 = 0.8;
          % random intervals are generated on the fly
          cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim1 = [0.5 0.7];
          cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim2 = [1.0 1.2];
          cfg.stim.(sesName).(phaseName)(phaseNum).match_response = 2.0;
          
          % do we want to play feedback beeps for no response?
          cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
          cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
          cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
          cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
          cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
          
          % instructions
          [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.match.text] = et_processTextInstruct(...
            fullfile(cfg.files.instructDir,sprintf('%s_match_2_exp_intro.txt',expParam.expName)),...
            {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
          
          expParam.session.(sesName).(phaseName)(phaseNum).date = [];
          expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
          expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
        end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Naming
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      phaseName = 'name';
      
      if ismember(phaseName,expParam.session.(sesName).phases)
        for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
          cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = true;
          
          % only use stimuli from particular families
          cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
          
          % maximum number of repeated exemplars from each family in naming
          cfg.stim.(sesName).(phaseName)(phaseNum).nameMaxConsecFamily = 3;
          
          if expParam.useNS
            cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 120;
          end
          
          % durations, in seconds
          cfg.stim.(sesName).(phaseName)(phaseNum).name_isi = 0.5;
          cfg.stim.(sesName).(phaseName)(phaseNum).name_preStim = [0.5 0.7];
          cfg.stim.(sesName).(phaseName)(phaseNum).name_stim = 1.0;
          cfg.stim.(sesName).(phaseName)(phaseNum).name_response = 2.0;
          cfg.stim.(sesName).(phaseName)(phaseNum).name_feedback = 1.0;
          
          % do we want to play feedback beeps?
          cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
          cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
          cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
          cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
          cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
          
          % instructions
          [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.text] = et_processTextInstruct(...
            fullfile(cfg.files.instructDir,sprintf('%s_name_2_exp_intro.txt',expParam.expName)),...
            {'nFamily','basicFamStr','contKey'},...
            {num2str(length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames)),cfg.text.basicFamStr,cfg.keys.instructContKey});
          cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.image = cfg.files.speciesNumKeyImg;
          cfg.stim.(sesName).(phaseName)(phaseNum).instruct.name.imageScale = cfg.files.speciesNumKeyImgScale;
          
          expParam.session.(sesName).(phaseName)(phaseNum).date = [];
          expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
          expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
        end
      end
      
    end
  end
  
  %% Posttest configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'posttest';
  
  if ismember(sesName,expParam.sesTypes)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        % every stimulus is in both the same and the different condition.
        cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained;
        cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained;
        % rmStims_orig is false because all stimuli are used in both "same"
        % and "diff" conditions
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = false;
        
        % % number per species per family (half because each stimulus is only in
        % % same or different condition)
        % cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained / 2;
        % cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained / 2;
        % % rmStims_orig is true because half of stimuli are in "same" cond and
        % % half are in "diff"
        % cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamiles (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseNum).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseNum).matchTextPrompt = matchTextPrompt;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 240;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.match.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_2_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Recognition - practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_recog';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        % do we want to use the stimuli from a previous phase? Set to an empty
        % cell if not.
        cfg.stim.(sesName).(phaseName)(phaseNum).usePrevPhase = {'pretest','prac_recog',1};
        cfg.stim.(sesName).(phaseName)(phaseNum).reshuffleStims = true;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Recognition
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'recog';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        cfg.stim.(sesName).(phaseName)(phaseNum).nBlocks = 8;
        % number of target and lure stimuli per species per family. Assumes all
        % targets and lures are tested.
        cfg.stim.(sesName).(phaseName)(phaseNum).nStudyTarg = 2;
        cfg.stim.(sesName).(phaseName)(phaseNum).nTestLure = 1;
        % maximum number of same family in a row during study task
        cfg.stim.(sesName).(phaseName)(phaseNum).studyMaxConsecFamily = 0;
        % maximum number of targets or lures in a row during test task
        cfg.stim.(sesName).(phaseName)(phaseNum).testMaxConsec = 0;
        
        % do not reuse recognition stimuli in other parts of the experiment
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nBlocks = 4;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_preTarg = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_targ = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_preStim = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_stim = 1.5;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_response = 10.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        nExemplars = cfg.stim.(sesName).(phaseName)(phaseNum).nStudyTarg * cfg.stim.nSpecies * length(cfg.stim.(sesName).(phaseName)(phaseNum).familyNames);
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_post_intro.txt',expParam.expName)),...
          {'nBlocks','nExemplars','contKey'},{num2str(cfg.stim.(sesName).(phaseName)(phaseNum).nBlocks),num2str(nExemplars),cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogStudy.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_post_study.txt',expParam.expName)),...
          {'nExemplars','contKey'},{num2str(nExemplars),cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_post_test.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.image = cfg.files.recogTestRespKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.imageScale = cfg.files.recogTestRespKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
  end
  
  %% Posttest Delayed configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'posttest_delay';
  
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching - practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        % do we want to use the stimuli from a previous phase? Set to an empty
        % cell if not.
        cfg.stim.(sesName).(phaseName)(phaseNum).usePrevPhase = {'pretest','prac_match',1};
        cfg.stim.(sesName).(phaseName)(phaseNum).reshuffleStims = true;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'match';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        % every stimulus is in both the same and the different condition.
        cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained;
        cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained;
        % rmStims_orig is false because all stimuli are used in both "same"
        % and "diff" conditions
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = false;
        
        % % number per species per family (half because each stimulus is only in
        % % same or different condition)
        % cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained / 2;
        % cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained / 2;
        % % rmStims_orig is true because half of stimuli are in "same" cond and
        % % half are in "diff"
        % cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = true;
        
        % rmStims_pair is true because pairs are removed after they're added
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_pair = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        % nTrials = (nSame + nDiff) * nSpecies * nFamiles (and multiply by 2
        % if rmStims_orig=false)
        
        % minimum number of trials needed between exact repeats of a given
        % stimulus as stim2
        cfg.stim.(sesName).(phaseName)(phaseNum).stim2MinRepeatSpacing = 2;
        % whether to have "same" and "diff" text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseNum).matchTextPrompt = matchTextPrompt;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 240;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).match_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim1 = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).match_stim2 = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim1 = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_preStim2 = [1.0 1.2];
        cfg.stim.(sesName).(phaseName)(phaseNum).match_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.match.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_match_2_exp_intro.txt',expParam.expName)),...
          {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Recognition - practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'prac_recog';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        % do we want to use the stimuli from a previous phase? Set to an empty
        % cell if not.
        cfg.stim.(sesName).(phaseName)(phaseNum).usePrevPhase = {'pretest','prac_recog',1};
        cfg.stim.(sesName).(phaseName)(phaseNum).reshuffleStims = true;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Recognition
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'recog';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        cfg.stim.(sesName).(phaseName)(phaseNum).nBlocks = 8;
        % number of target and lure stimuli per species per family. Assumes all
        % targets and lures are tested.
        cfg.stim.(sesName).(phaseName)(phaseNum).nStudyTarg = 2;
        cfg.stim.(sesName).(phaseName)(phaseNum).nTestLure = 1;
        % maximum number of same family in a row during study task
        cfg.stim.(sesName).(phaseName)(phaseNum).studyMaxConsecFamily = 0;
        % maximum number of targets or lures in a row during test task
        cfg.stim.(sesName).(phaseName)(phaseNum).testMaxConsec = 0;
        
        % do not reuse recognition stimuli in other parts of the experiment
        cfg.stim.(sesName).(phaseName)(phaseNum).rmStims = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).shuffleFirst = true;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nBlocks = 4;
        end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_preTarg = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_study_targ = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_isi = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_preStim = 0.2;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_test_stim = 1.5;
        cfg.stim.(sesName).(phaseName)(phaseNum).recog_response = 10.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogIntro.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_post_intro.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogStudy.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_post_study.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_recog_post_test.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.image = cfg.files.recogTestRespKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseNum).instruct.recogTest.imageScale = cfg.files.recogTestRespKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseNum).date = [];
        expParam.session.(sesName).(phaseName)(phaseNum).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseNum).endTime = [];
      end
    end
  end
  
  %% process the stimuli for the entire experiment
  
  [cfg,expParam] = et_processStims(cfg,expParam);
  
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
  
end

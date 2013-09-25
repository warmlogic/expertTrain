function [cfg,expParam] = config_SPACE(cfg,expParam)
% function [cfg,expParam] = config_SPACE(cfg,expParam)
%
% Description:
%  Configuration function for creature expertise training experiment. This
%  file should be edited for your particular experiment. This function runs
%  space_processStims to prepare the stimuli for experiment presentation.
%
% see also: space_saveStimList, space_processStims,
% space_processStims_study, space_processStims_test

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

% how to present stimuli. 1 = simultaneous. 2 = sequential. 3 = overlap.
studyPresent = 2;

% judgment task defaults
studyJudgment = false;
studyTextPrompt = false;
% recognition task defaults
recogTextPrompt = true;
% prompt if they response 'new'
newTextPrompt = true;

%% Experiment session information

% Set the number of sessions
expParam.nSessions = 1;

% Pre-test, training day 1, training days 1-6, post-test, post-test delayed.
expParam.sesTypes = {'oneDay'};

% % set up a field for each session type
expParam.session.oneDay.phases = {'multistudy','distract_math','cued_recall'};

% debug
% expParam.session.oneDay.phases = {'multistudy','cued_recall'};
% expParam.session.oneDay.phases = {'distract_math'};

% % debug
% expParam.nSessions = 1;
% expParam.sesTypes = {'oneDay'};
% expParam.session.oneDay.phases = {'multistudy','distract_math','cued_recall'};

%% do some error checking

possible_phases = {'multistudy','distract_math','cued_recall','prac_multistudy','prac_distract_math','prac_cued_recall'};
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
  
  % whether to preload images; if true, could use a lot of memory
  cfg.stim.preloadImages = false;
  
  % the file extension for your images
  %cfg.files.stimFileExt = '.bmp';
  cfg.files.stimFileExt = '.jpg';
  
  % resize the image to have a height of this many pixels
  cfg.stim.nRows = 480;
  % then crop the image to have this width (all face images are 3:2 ratio)
  cfg.stim.cropWidth = cfg.stim.nRows * (2/3);% 320;
  
  % scale stimlus down (< 1) or up (> 1)
  cfg.stim.stimScale = 0.75;
  
  % image directory holds the stims and resources
  cfg.files.imgDir = fullfile(cfg.files.expDir,'images');
  
  % set the stimulus directory
  cfg.files.imgStimDir = fullfile(cfg.files.imgDir,'Space');
  
  % category names correspond to the directories in which images reside
  cfg.stim.categoryNames = {'Faces', 'HouseInside'};
  
  % set the image resources directory
  cfg.files.resDir = fullfile(cfg.files.imgDir,'resources');
  
  % image directory holds the stims and resources
  cfg.files.textDir = fullfile(cfg.files.expDir,'text');
  
  % set the word pool directory
  cfg.files.wordpoolDir = fullfile(cfg.files.textDir,'pools','PEERS_wordpool');
  cfg.files.wordpool = fullfile(cfg.files.wordpoolDir,'wasnorm_wordpool.txt');
  cfg.files.wordpoolExclude = fullfile(cfg.files.wordpoolDir,'excluded_words.txt');
  
  % set the instructions directory
  cfg.files.instructDir = fullfile(cfg.files.textDir,'instructions');
  
  % save an individual stimulus list for each subject
  cfg.stim.imgStimListFile = fullfile(cfg.files.subSaveDir,'imgStimList.txt');
  cfg.stim.wordpoolListFile = fullfile(cfg.files.subSaveDir,'wordpoolList.txt');
  
  % create the stimulus list if it doesn't exist
  if ~exist(cfg.stim.imgStimListFile,'file') && ~exist(cfg.stim.wordpoolListFile,'file')
    [cfg] = space_saveStimList(cfg,cfg.files.imgStimDir,cfg.files.wordpoolDir,cfg.stim);
  else
    % % debug = warning instead of error
    % warning('Stimulus lists should not exist at the beginning of Session %d:\n%s\n%s',expParam.sessionNum,cfg.stim.imgStimListFile,cfg.stim.wordpoolListFile);
    error('Stimulus lists should not exist at the beginning of Session %d:\n%s\n%s',expParam.sessionNum,cfg.stim.imgStimListFile,cfg.stim.wordpoolListFile);
  end
  
  % whether to remove the trained/untrained stims from the stimulus pool
  % after they are chosen
  cfg.stim.rmStims_init = true;
  % whether to shuffle the stimulus pool before choosing stimuli
  cfg.stim.shuffleFirst_init = true;
  
  % practice images stored in separate directories
  expParam.runPractice = false;
  cfg.stim.useSeparatePracStims = false;
  
  if expParam.runPractice

  end
  
  % number of pairs for each image category
  %
  % number of study pairs: (((spaced + massed)*2) + onePres) * nCategories
  cfg.stim.nPairs_study_targ_spaced = 20;
  cfg.stim.nPairs_study_targ_massed = 16;
  cfg.stim.nPairs_study_targ_onePres = 10;
  
  cfg.stim.lags = [4 8 16];
  % cfg.stim.lags = [5 10 20];
  
  
  % total number of additional lure pairs is: nPairs * number of categories
  cfg.stim.nPairs_test_lure = 20;
  
%   cfg.stim.nPairs_study_targ_spaced = 8;
%   cfg.stim.nPairs_study_targ_massed = 4;
%   cfg.stim.nPairs_study_targ_onePres = 4;
%   
%   cfg.stim.lags = [2 4 8];
%   
%   % total number of additional lure pairs is: nPairs * number of categories
%   cfg.stim.nPairs_test_lure = 10;
  
  %   % even number of pairs
  %   if ~mod(cfg.stim.nPairs_study_targ_spaced,2) == 0
  %     error('Please use an even number of pairs (study target spaced pairs).');
  %   end
  %   if ~mod(cfg.stim.nPairs_study_targ_massed,2) == 0
  %     error('Please use an even number of pairs (study target massed pairs).');
  %   end
  %   if ~mod(cfg.stim.nPairs_test_lure,2) == 0
  %     error('Please use an even number of pairs (test lure pairs).');
  %   end
  
  
  %% Define the response keys
  
  % the experimenter's secret key to continue the experiment
  cfg.keys.expContinue = 'g';
  
  % which row of keys to use in matching and recognition tasks. Can be
  % 'upper' or 'middle'
  cfg.keys.keyRow = 'middle';
  
%   % use spacebar for naming "other" family (basic-level naming)
%   cfg.keys.otherKeyNames = {'space'};
%   cfg.keys.s00 = KbName(cfg.keys.otherKeyNames{1});
  
%   % keys for naming particular species (subordinate-level naming)
%   if strcmp(cfg.keys.keyRow,'upper')
%     % upper row
%     cfg.keys.speciesKeyNames = {'q','w','e','r','v','n','u','i','o','p'};
%   elseif strcmp(cfg.keys.keyRow,'middle')
%     % middle row
%     if ismac || isunix
%       cfg.keys.speciesKeyNames = {'a','s','d','f','v','n','j','k','l',';:'};
%     elseif ispc
%       cfg.keys.speciesKeyNames = {'a','s','d','f','v','n','j','k','l',';'};
%     end
%   end
%   
%   % set the species keys
%   for i = 1:length(cfg.keys.speciesKeyNames)
%     % sXX, where XX is an integer, buffered with a zero if i <= 9
%     cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeyNames{i});
%   end
%   
%   if strcmp(cfg.keys.keyRow,'upper')
%     cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_black_upper.jpg');
%     %cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_white_upper.jpg');
%   elseif strcmp(cfg.keys.keyRow,'middle')
%     cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_black_middle.jpg');
%     %cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_white_middle.jpg');
%   end
%   
%   % scale image down (< 1) or up (> 1)
%   cfg.files.speciesNumKeyImgScale = 0.4;
  
  % matching keys (counterbalanced based on subNum 1-5, 6-0)
  if strcmp(cfg.keys.keyRow,'upper')
    % upper row
    cfg.keys.studyKeyNames = {'r','u'};
  elseif strcmp(cfg.keys.keyRow,'middle')
    % middle row
    cfg.keys.studyKeyNames = {'f','j'};
  end
  if expParam.is15
    cfg.keys.judgeSame = KbName(cfg.keys.studyKeyNames{1});
    cfg.keys.judgeDiff = KbName(cfg.keys.studyKeyNames{2});
  else
    cfg.keys.judgeSame = KbName(cfg.keys.studyKeyNames{2});
    cfg.keys.judgeDiff = KbName(cfg.keys.studyKeyNames{1});
  end
  
  % math distractor key names
  cfg.keys.distMathKeyNames = {'-_','1!','2@','3#','4$','5%','6^','7&','8*','9(','0)','-','1','2','3','4','5','6','7','8','9','0'};
  cfg.keys.distMath = nan(1,length(cfg.keys.distMathKeyNames));
  for i = 1:length(cfg.keys.distMath)
    cfg.keys.distMath(i) = KbName(cfg.keys.distMathKeyNames(i));
  end
  
  if strcmp(cfg.keys.keyRow,'upper')
    % upper row
    cfg.keys.recogKeyNames = {'r','u'};
  elseif strcmp(cfg.keys.keyRow,'middle')
    % middle row
    cfg.keys.recogKeyNames = {'f','j'};
  end
  if expParam.is15
    cfg.keys.recogOld = KbName(cfg.keys.recogKeyNames{1});
    cfg.keys.recogNew = KbName(cfg.keys.recogKeyNames{2});
  else
    cfg.keys.recogOld = KbName(cfg.keys.recogKeyNames{2});
    cfg.keys.recogNew = KbName(cfg.keys.recogKeyNames{1});
  end
  
  cfg.keys.recallKeyNames = 'a':'z';
  cfg.keys.recall = nan(1,length(cfg.keys.recallKeyNames));
  for i = 1:length(cfg.keys.recall)
    cfg.keys.recall(i) = KbName(cfg.keys.recallKeyNames(i));
  end
  
  if strcmp(cfg.keys.keyRow,'upper')
    % upper row
    cfg.keys.newKeyNames = {'r','u'};
  elseif strcmp(cfg.keys.keyRow,'middle')
    % middle row
    cfg.keys.newKeyNames = {'f','j'};
  end
  if expParam.is15
    cfg.keys.newSure = KbName(cfg.keys.newKeyNames{1});
    cfg.keys.newMaybe = KbName(cfg.keys.newKeyNames{2});
  else
    cfg.keys.newSure = KbName(cfg.keys.newKeyNames{2});
    cfg.keys.newMaybe = KbName(cfg.keys.newKeyNames{1});
  end
  
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
  
  cfg.text.wordBackgroundColor = uint8((rgb('White') * 255) + 0.5);
  %cfg.text.wordBackgroundColor = rgb('White');
  %Screen('Preference', 'TextAlphaBlending', 1);
  
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
  
  if studyTextPrompt
    cfg.text.judgeSame = ' Related ';
    cfg.text.judgeDiff = 'Unrelated';
  end
  if recogTextPrompt
    cfg.text.recogOld = 'Old';
    cfg.text.recogNew = 'New';
  end
  if newTextPrompt
    cfg.text.newSure = ' Sure';
    cfg.text.newMaybe = 'Maybe';
  end
  cfg.text.recallPrompt = '???????';
  
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
  
  sesName = 'oneDay';
  
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Study events 1 and 2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'multistudy';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).stimWithPrompt = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = false;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).studyMaxConsecCategory = 3;
        cfg.stim.(sesName).(phaseName)(phaseCount).studyMaxConsecLag = 2;
        
        %cfg.stim.(sesName).(phaseName)(phaseCount).study_nPairs = 50;
        %cfg.stim.(sesName).(phaseName)(phaseCount).study_order = {{'image','word'},{'word','image'}};
        cfg.stim.(sesName).(phaseName)(phaseCount).study_order = {{'word','image'},{'word','image'}};
        %cfg.stim.(sesName).(phaseName)(phaseCount).study_order = {{'image','word'},{'image','word'}};
        
        % stimulus order. 1 = simultaneous. 2 = sequential. 3 = overlap.
        cfg.stim.(sesName).(phaseName)(phaseCount).studyPresent = studyPresent; 
        % 1: both stimuli on screen for study_stim1+study_stim2;
        %
        % 2: stim1 on for study_stim1, then stim2 on for study_stim2;
        %
        % 3: stim1 on for study_stim1, then both on for study_stim2.
        
        % whether to have judgment text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseCount).studyJudgment = studyJudgment;
        cfg.stim.(sesName).(phaseName)(phaseCount).studyTextPrompt = studyTextPrompt;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).study_isi = 0.0;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).study_preStim1 = [0.6 0.8];
        cfg.stim.(sesName).(phaseName)(phaseCount).study_stim1 = 1.5;
        cfg.stim.(sesName).(phaseName)(phaseCount).study_stim2 = 1.5;
        %cfg.stim.(sesName).(phaseName)(phaseCount).study_postPair = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseCount).study_response = 3.0;
        
        % do we want to play feedback beeps?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.study.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_study_1_exp_intro.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
          %{'sameKey','diffKey','contKey'},{KbName(cfg.keys.judgeSame),KbName(cfg.keys.judgeDiff),cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Distractor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'distract_math';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = false;
        
        %if expParam.useNS
        %  cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 240;
        %end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_isi = 0.0;
        %cfg.stim.(sesName).(phaseName)(phaseCount).dist_stim = 0.8;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_preStim = [0.25 0.5];
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_nVar = 3;
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_minNum = 1;
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_maxNum = 10;
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_plusMinus = false;
        %cfg.stim.(sesName).(phaseName)(phaseCount).dist_nProbs = 30;
        %cfg.stim.(sesName).(phaseName)(phaseCount).dist_maxTimeLimit = 60.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_nProbs = 10;
        cfg.stim.(sesName).(phaseName)(phaseCount).dist_maxTimeLimit = 20.0;
        %cfg.stim.(sesName).(phaseName)(phaseCount).dist_response = 10.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.dist.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_dist_1_exp_intro.txt',expParam.expName)),...
          {'contKey'},{cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'cued_recall';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        %cfg.stim.(sesName).(phaseName)(phaseCount).crMaxConsecTarg = 6;
        cfg.stim.(sesName).(phaseName)(phaseCount).crMaxConsecCategory = 4;
        
        if expParam.useNS
          cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 240;
        end
        
        % whether to have judgment text with the response prompt
        cfg.stim.(sesName).(phaseName)(phaseCount).recogTextPrompt = recogTextPrompt;
        cfg.stim.(sesName).(phaseName)(phaseCount).newTextPrompt = newTextPrompt;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_isi = 0.0;
        % random intervals are generated on the fly
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_preCueStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_cueStimOnly = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_recog_response = 5.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_recall_response = 10.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_new_response = 5.0;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_nAttempts = 2;
        cfg.stim.(sesName).(phaseName)(phaseCount).cr_corrSpell = false;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.cr.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_cr_1_exp_intro.txt',expParam.expName)),...
          {'recogOldKey','recogNewKey','recallPromptText','newSureKey','newMaybeKey','contKey'},...
          {KbName(cfg.keys.recogOld),KbName(cfg.keys.recogNew),cfg.text.recallPrompt,...
          KbName(cfg.keys.newSure),KbName(cfg.keys.newMaybe),...
          cfg.keys.instructContKey});
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
  end
  
  %% process the stimuli for the entire experiment
  
  [cfg,expParam] = space_processStims(cfg,expParam);
  
  %% save the parameters
  
  fprintf('Saving experiment parameters: %s...',cfg.files.expParamFile);
  save(cfg.files.expParamFile,'cfg','expParam');
  fprintf('Done.\n');
  
  %% print out the experiment length
  
  % % maximum duration
  % et_calcExpDuration(cfg,expParam,'max');
  % medium duration
  % et_calcExpDuration(cfg,expParam,'med');
  % % minimum duration
  % et_calcExpDuration(cfg,expParam,'min');
  
end
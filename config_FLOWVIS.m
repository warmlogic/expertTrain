function [cfg,expParam] = config_FLOWVIS(cfg,expParam)
% function [cfg,expParam] = config_FLOWVIS(cfg,expParam)
%
% Description:
%  Configuration function for the FLOWVIS visual expertise training experiment. This
%  file should be edited for your particular experiment. This function runs
%  et_processStims to prepare the stimuli for experiment presentation
%expParam.nSessions
% see also: et_saveStimList, et_processStims, et_processStims_match,
% et_processStims_recog, et_processStims_viewname,
% et_processStims_nametrain, et_processStims_name

%% Experiment defaults

% set up configuration structures to keep track of what day and phase we're
% on.

% %%FLOWVIS does not use EEG / netstation (useNS)
% what host is netstation running on?
% if expParam.useNS
%   expParam.NSPort = 55513;
%
%   % % D458
%   % expParam.NSHost = '128.138.223.251';
%
%   % D464
%   expParam.NSHost = '128.138.223.26';
%
%   expParam.baselineRecordSecs = 20.0;
% end

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

%% counterbalancing

% odd or even subject number
if mod(str2double(expParam.subject(end)),2) == 0
  expParam.isEven = true;
else
  expParam.isEven = false;
end

%% Experiment session information

% Set the number of sessions
% for FLOWVIS pilot, only 1 session, with pre and post tests in same
% session
expParam.nSessions = 1;

% practice, Pre-test, training day 1, post-test, all in one day
expParam.sesTypes = {'pilot'};
% set up a field for each session type
expParam.session.pilot.phases = {'prac_match','prac_name','match','name','match','match'};

%% do some error checking
% expParam.session.pilot.phases = {'match', 'match', 'match'};

possible_phases = {'match','name','view','prac_match','prac_name'};
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
  
  
  % subject number ends in 1-5 or 6-0
  if str2double(expParam.subject(end)) >= 1 && str2double(expParam.subject(end)) <= 5
    expParam.is15 = true;
  else
    expParam.is15 = false;
  end
  
  % No EEG/Net Station for FLOWVIS pilot, so this won't run
  % blink break (set to 0 if you don't want breaks)
  if expParam.useNS
    % timer in secs for when to take a blink break (only when useNS=true)
    cfg.stim.secUntilBlinkBreak = 45.0;
  else
    % timer in secs for when to take a blink break (only when useNS=false)
   cfg.stim.secUntilBlinkBreak = 1800;
  end
  
  %% Stimulus parameters
  
  % whether to present a white square during the stimulus
  cfg.stim.photoCell = false;
  cfg.stim.photoCellRectSize = 30;
  
  % whether to preload images; if true, could use a lot of memory
  cfg.stim.preloadImages = false;
  
  % the file extension for your images
  cfg.files.stimFileExt = '.jpg';
  
  % scale stimlus down (< 1) or up (> 1)
  cfg.stim.stimScale = 1.00;
  
  % image directory holds the stims and resources
  cfg.files.imgDir = fullfile(cfg.files.expDir,'images');
  
  % set the stimulus directory
  cfg.files.stimDir = fullfile(cfg.files.imgDir,'FlowVis');
  
  % set the image resources directory
  cfg.files.resDir = fullfile(cfg.files.imgDir,'resources');
  
  % set the instructions directory
  cfg.files.instructDir = fullfile(cfg.files.expDir,'text','instructions');
  
  % family names correspond to the directories in which stimuli reside;
  % includes manipulations
  cfg.stim.familyNames = {'VStreet_', 'Plain_'};
%   if expParam.isEven
%       cfg.stim.familyNames = {'VStreet_'};
%   else
%       cfg.stim.familyNames = {'Plain_'};
%   end
  
  
  % assumes that each family has the same number of species
  cfg.stim.nSpecies = 2;
  
  % whether to use the same species order across families
  cfg.stim.yokeSpecies = false;
  if cfg.stim.yokeSpecies
    cfg.stim.yokeTogether = [1 2];
  end
  
  % Number of trained and untrained exemplars per species per family
  cfg.stim.nTrained = 10;
  cfg.stim.nUntrained = 10;
  
  % yoke exemplars across species within these family groups so training
  % status is the same for all 
  cfg.stim.yokeTrainedExemplars = false;
  if cfg.stim.yokeTrainedExemplars
    cfg.stim.yokeExemplars_train = [1 1 1 1 1 2 2 2 2 2];
  end
  
  % save an individual stimulus list for each subject
  cfg.stim.stimListFile = fullfile(cfg.files.subSaveDir,'stimList.txt');
  
  % create the stimulus list if it doesn't exist
  shuffleSpecies = false;
  if ~exist(cfg.stim.stimListFile,'file')
    %[cfg] = et_saveStimList(cfg,cfg.files.stimDir,cfg.stim,shuffleSpecies);
    
    % manually input species number order to align with response key images
    % (numbers correspond to alphabetical ordering of species names)
    if expParam.is15
      [cfg] = et_saveStimList(cfg,cfg.files.stimDir,cfg.stim,shuffleSpecies,[1, 2]);
    else
      [cfg] = et_saveStimList(cfg,cfg.files.stimDir,cfg.stim,shuffleSpecies,[2, 1]);
    end
  else
    % % debug = warning instead of error
    % warning('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.stimListFile);
    error('Stimulus list should not exist at the beginning of Session %d: %s',expParam.sessionNum,cfg.stim.stimListFile);
  end
  
  % basic/subordinate families (counterbalance based on even/odd subNum)
  % NB for FLOWVIS, two groups (Turb, Lam) are at the species level, in  both VStreet and Plain
  % families
  
  
   if expParam.isEven
 cfg.stim.famNumBasic = [];
  cfg.stim.famNumSubord = [1 2];

   else
     cfg.stim.famNumBasic = [];
     cfg.stim.famNumSubord = [2 1];
   end
    
% used the two lines below when we only had one family  
 % cfg.stim.famNumBasic = [];
 % cfg.stim.famNumSubord = [1];

  % what to call the basic-level family in viewing and naming tasks
  cfg.text.basicFamStr = 'Other';
  
  % whether to remove the trained/untrained stims from the stimulus pool
  % after they are chosen
  cfg.stim.rmStims_init = true;
  % whether to shuffle the stimulus pool before choosing trained/untrained
  cfg.stim.shuffleFirst_init = true;
  
  % practice images stored in separate directories
  expParam.runPractice = true;
  cfg.stim.useSeparatePracStims = true;
  
  if expParam.runPractice
    % practice exemplars per species per family for all phases except
    % recognition (recognition stim count is determined by nStudyTarg and
    % nStudyLure in each prac_recog phase defined below)
    cfg.stim.practice.nPractice = 2;
    
    if cfg.stim.useSeparatePracStims
      cfg.files.stimDir_prac = fullfile(cfg.files.imgDir,'Practice');
      cfg.stim.practice.familyNames = {'Phase_'};
      cfg.stim.practice.nSpecies = 2;
      
      % basic/subordinate families
      cfg.stim.practice.famNumBasic = [];
      cfg.stim.practice.famNumSubord = [1];
      
      cfg.stim.practice.yokeSpecies = false;
      if cfg.stim.practice.yokeSpecies
        cfg.stim.practice.yokeTogether = [1 1 1 1 1 2 2 2 2 2];
      end
      
      cfg.stim.practice.stimListFile = fullfile(cfg.files.subSaveDir,'stimList_prac.txt');
      
      shuffleSpecies = false;
      if ~exist(cfg.stim.practice.stimListFile,'file')
        %[cfg] = et_saveStimList(cfg,cfg.files.stimDir_prac,cfg.stim.practice,shuffleSpecies);
        
        % manually input species number order to align with response key
        % images (numbers correspond to alphabetical ordering of species names)
        if expParam.is15
          [cfg] = et_saveStimList(cfg,cfg.files.stimDir_prac,cfg.stim.practice,shuffleSpecies,[1, 2]);
        else
          [cfg] = et_saveStimList(cfg,cfg.files.stimDir_prac,cfg.stim.practice,shuffleSpecies,[2, 1]);
        end
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
    
    % optional, for showing a response key image
    % solid, liquid
    if expParam.is15
      cfg.files.practice.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_solidLiquid_black_middle_2.jpg');
    else
      cfg.files.practice.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_solidLiquid_black_middle_1.jpg');
    end
    % scale image down (< 1) or up (> 1)
    cfg.files.practice.speciesNumKeyImgScale = 0.5;
  end
  
  %% Define the response keys
  
  % the experimenter's secret key to continue the experiment
  cfg.keys.expContinue = 'g';
  
  % keys for naming particular species (subordinate-level naming)
  cfg.keys.speciesKeyNames = {'f','j'};
  
  % set the species keys - 2 kinds of flow images
  for i = 1:length(cfg.keys.speciesKeyNames)
    % sXX, where XX is an integer, buffered with a zero if i <= 9
    cfg.keys.(sprintf('s%.2d',i)) = KbName(cfg.keys.speciesKeyNames{i});
  end
  
  % show keyboard image for f=1, j=2
  cfg.files.speciesNumKeyImg = fullfile(cfg.files.resDir,'speciesNum_FLOWVIS_black_middle_1.jpg');
  % scale image down (< 1) or up (> 1)
  cfg.files.speciesNumKeyImgScale = 0.4;
  
  cfg.keys.matchKeyNames = {'f','j'};
  if expParam.is15
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{1});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{2});
  else
    cfg.keys.matchSame = KbName(cfg.keys.matchKeyNames{2});
    cfg.keys.matchDiff = KbName(cfg.keys.matchKeyNames{1});
  end
  
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
  
  %% Training Day 1 configuration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  sesName = 'pilot';
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
        
        % response key image
        cfg.stim.(sesName).(phaseName)(phaseCount).respKeyWithPrompt = true;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'Phase_'};
        
        % maximum number of repeated exemplars from each family in naming
        % Since FLOWVIS is all one family, no max exemplars from one family
        cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily = 0;
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).name_isi = 0.5;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).name_stim = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_response = 2.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctFeedback = 'Correct!';
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectFeedback = 'Incorrect!';
        
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
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).image = cfg.files.practice.speciesNumKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).imageScale = cfg.files.practice.speciesNumKeyImgScale;
        % whether to ask the participant if they have any questions; only
        % continues with experimenter's secret key  WE ALREADY ASK THEM IF
        % THEY HAVE QUESTIONS ON PRACTICE MATCH, DON'T NEED A SECOND TIME
       cfg.stim.(sesName).(phaseName)(phaseCount).instruct.questions = true;
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
    %% Session/phase configuration
    
    %% pretest configuration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    sesName = 'pilot';
    
    if ismember(sesName,expParam.sesTypes)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Matching - practice
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      phaseName = 'prac_match';
      
      if ismember(phaseName,expParam.session.(sesName).phases)
        for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
          cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
          cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
          cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = false;
          
          cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
          cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
          cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
          
          % only use stimuli from particular families
          cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'Phase_'};
          
          % % every stimulus is in both the same and the different condition.
          % cfg.stim.(sesName).(phaseName)(phaseCount).nSame = cfg.stim.practice.nPractice;
          % cfg.stim.(sesName).(phaseName)(phaseCount).nDiff = cfg.stim.practice.nPractice;
          % % rmStims_orig is false because all stimuli are used in both "same"
          % % and "diff" conditions
          % cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = false;
          
          % number per species per family (half because each stimulus is only in
          % same or different condition)
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
          
          % do we want to play feedback beeps? - NO
          cfg.stim.(sesName).(phaseName)(phaseCount).playSound = false;
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
            %PILOT ONLY HAS 1 SESSION
            %[cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
            % fullfile(cfg.files.instructDir,sprintf('%s_match_2_practice_intro.txt',expParam.expName)),...
            % {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
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
              cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = false;
              
              cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
              cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
              cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
              
              % only use stimuli from particular families
              %           cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
              
              % only use stimuli from particular families
              if phaseCount == 3
                  if expParam.isEven
                      cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'Plain_'};
                  else
                      cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'VStreet_'};
                  end
              elseif phaseCount ~= 3
                  if expParam.isEven
                      cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'VStreet_'};
                  else
                      cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'Plain_'};
                  end
                  
              end
              
            
              
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
              % rmStims_orig is true because half of stimuli are in "same" cond and
              % half are in "diff"
              cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig = true;
              
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
              
              if expParam.useNS
                  cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 240;
              end
              
              % durations, in seconds
              cfg.stim.(sesName).(phaseName)(phaseCount).match_isi = 0.0;
              cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 = 0.8;
              cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 = 0.8;
              % random intervals are generated on the fly
              cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1 = [0.5 0.7];
              cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2 = [1.0 1.2];
              cfg.stim.(sesName).(phaseName)(phaseCount).match_response = 2.0;
              
              % do we want to play feedback beeps for no response?
              cfg.stim.(sesName).(phaseName)(phaseCount).playSound = false;
              cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
              cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
              cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
              cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
              
              % instructions
              
              if phaseCount == 3
                  [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
                      fullfile(cfg.files.instructDir,sprintf('%s_match_3_exp_intro.txt',expParam.expName)),...
                      {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
              elseif phaseCount ~= 3
                  [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.match(1).text] = et_processTextInstruct(...
                      fullfile(cfg.files.instructDir,sprintf('%s_match_exp_intro.txt',expParam.expName)),...
                      {'sameKey','diffKey','contKey'},{KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),cfg.keys.instructContKey});
              end
              
              
              expParam.session.(sesName).(phaseName)(phaseCount).date = [];
              expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
              expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
          end
      end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Naming - includes error-driven training for half of subjects
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'name';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseCount).respDuringStim = true;
        
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
        cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
        
        % response key image
        cfg.stim.(sesName).(phaseName)(phaseCount).respKeyWithPrompt = true;
        
        % only use stimuli from particular families
        if expParam.isEven
            cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'VStreet_'};
        else
            cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = {'Plain_'};
        end
       %cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
        
        % maximum number of repeated exemplars from each family in naming -
        % for FLOWVIS, set to zero, so no max consec set
        cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily = 0;
        
        %         if expParam.useNS
        %           cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials = 120;
        %         end
        
        % durations, in seconds
        cfg.stim.(sesName).(phaseName)(phaseCount).name_isi = 0.5;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseCount).name_stim = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).name_response = 2.0;
        % feedback for error-driven training
        cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback = 1.0;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctFeedback = 'Correct!';
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectFeedback = 'Incorrect!';
        
        % do we want to play feedback beeps? Yes for FLOWVIS - this is
        % error-driven feedback training
        cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_name_exp_intro.txt',expParam.expName)),...
          {'contKey'},...
          {cfg.keys.instructContKey});
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).image = cfg.files.speciesNumKeyImg;
        cfg.stim.(sesName).(phaseName)(phaseCount).instruct.name(1).imageScale = cfg.files.speciesNumKeyImgScale;
        
        expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
      end
    end
  end
  
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   % Viewing - task not in use for this iteration of experiment
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   phaseName = 'view';
%   
%   if ismember(phaseName,expParam.session.(sesName).phases)
%     for phaseCount = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
%       cfg.stim.(sesName).(phaseName)(phaseCount).isExp = true;
%       cfg.stim.(sesName).(phaseName)(phaseCount).impedanceBeforePhase = false;
%       
%       cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringISI = fixDuringISI;
%       cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringPreStim = fixDuringPreStim;
%       cfg.stim.(sesName).(phaseName)(phaseCount).fixDuringStim = fixDuringStim;
%       
%       % response key image
%       cfg.stim.(sesName).(phaseName)(phaseCount).respKeyWithPrompt = true;
%       
%       % only use stimuli from particular families
%       cfg.stim.(sesName).(phaseName)(phaseCount).familyNames = cfg.stim.familyNames;
%       
%       % maximum number of repeated exemplars from each family in view
%       cfg.stim.(sesName).(phaseName)(phaseCount).viewMaxConsecFamily = 0;
%       
%       %       if expParam.useNS
%       %         cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks = 7;
%       %       end
%       
%       % durations, in seconds
%       cfg.stim.(sesName).(phaseName)(phaseCount).view_isi = 0.5;
%       cfg.stim.(sesName).(phaseName)(phaseCount).view_preStim = 0.2;
%       cfg.stim.(sesName).(phaseName)(phaseCount).view_stim = 2.0;
%       
%       % do we want to play feedback beeps?
%       cfg.stim.(sesName).(phaseName)(phaseCount).playSound = playSound;
%       cfg.stim.(sesName).(phaseName)(phaseCount).correctSound = correctSound;
%       cfg.stim.(sesName).(phaseName)(phaseCount).incorrectSound = incorrectSound;
%       cfg.stim.(sesName).(phaseName)(phaseCount).correctVol = correctVol;
%       cfg.stim.(sesName).(phaseName)(phaseCount).incorrectVol = incorrectVol;
%       
%       % instructions (view)  with blocking removed for FLOWVIS pilot
%       [cfg.stim.(sesName).(phaseName)(phaseCount).instruct.view(1).text] = et_processTextInstruct(...
%         fullfile(cfg.files.instructDir,sprintf('%s_view_1_intro.txt',expParam.expName)), {'contKey'} , {cfg.keys.instructContKey});
%       cfg.stim.(sesName).(phaseName)(phaseCount).instruct.view(1).image = cfg.files.speciesNumKeyImg;
%       cfg.stim.(sesName).(phaseName)(phaseCount).instruct.view(1).imageScale = cfg.files.speciesNumKeyImgScale;
%       
%       expParam.session.(sesName).(phaseName)(phaseCount).view.date = [];
%       expParam.session.(sesName).(phaseName)(phaseCount).view.startTime = [];
%       expParam.session.(sesName).(phaseName)(phaseCount).view.endTime = [];
%     end
%   end
  
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

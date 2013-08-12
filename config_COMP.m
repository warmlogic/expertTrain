function [cfg,expParam] = config_COMP(cfg,expParam)
% function [cfg,expParam] = config_COMP(cfg,expParam)
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
expParam.nSessions = 1;

expParam.sesTypes = {'comparison'};

% set up a field for each session type
expParam.session.comparison.phases = {'compare'};

%% do some error checking

possible_phases = {'match','name','recog','nametrain','viewname','prac_match','prac_name','prac_recog','compare'};
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
    cfg.stim.secUntilBlinkBreak = 0;
    %cfg.stim.secUntilBlinkBreak = 90.0;
  end
  
  %% Stimulus parameters
  
  cfg.files.stimFileExt = '.bmp';
  
  % scale stimlus down (< 1) or up (> 1)
  cfg.stim.stimScale = 0.75;
  
  % image directory holds the stims and resources
  cfg.files.imgDir = fullfile(cfg.files.expDir,'images');
  
  % set the stimulus directory
  cfg.files.stimDir = fullfile(cfg.files.imgDir,'Army_StimDifficulty');
  
  % set the image resources directory
  cfg.files.resDir = fullfile(cfg.files.imgDir,'resources');
  
  % set the instructions directory
  cfg.files.instructDir = fullfile(cfg.files.expDir,'text','instructions');
  
  % family names correspond to the directories in which stimuli reside;
  % includes manipulations
  cfg.stim.familyNames = {'a', 's'};
  
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
  
  % whether to remove the trained/untrained stims from the stimulus pool
  % after they are chosen
  cfg.stim.rmStims_init = true;
  % whether to shuffle the stimulus pool before choosing trained/untrained
  cfg.stim.shuffleFirst_init = true;
  
  % practice images stored in separate directories
  expParam.runPractice = false;
  cfg.stim.useSeparatePracStims = false;
  
  %% Define the response keys
  
  % the experimenter's secret key to continue the experiment
  cfg.keys.expContinue = 'g';
  
  % how similar the two stimuli are
  cfg.keys.compareKeyNames = {'1','2','3','4','5'};
  
  % set the comparison keys
  for i = 1:length(cfg.keys.compareKeyNames)
    % cXX, where XX is an integer, buffered with a zero if i <= 9
    cfg.keys.(sprintf('c%.2d',i)) = KbName(cfg.keys.compareKeyNames{i});
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
  
  % number of characters wide at which any text will wrap
  cfg.text.instructCharWidth = 70;
  
  % key to push to dismiss instruction screen
  cfg.keys.instructContKey = 'space';
  
  % fixation info
  cfg.text.fixSymbol = '+';
  cfg.text.respSymbol = '?';
  cfg.text.fixationColor = uint8((rgb('Black') * 255) + 0.5);
  
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
  
  sesName = 'comparison';
  
  if ismember(sesName,expParam.sesTypes)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Comparison
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseName = 'compare';
    
    if ismember(phaseName,expParam.session.(sesName).phases)
      for phaseNum = 1:sum(ismember(expParam.session.(sesName).phases,phaseName))
        cfg.stim.(sesName).(phaseName)(phaseNum).isExp = true;
        cfg.stim.(sesName).(phaseName)(phaseNum).impedanceBeforePhase = false;
        cfg.stim.(sesName).(phaseName)(phaseNum).respDuringStim = true;
        
        % only use stimuli from particular families
        cfg.stim.(sesName).(phaseName)(phaseNum).familyNames = cfg.stim.familyNames;
        
        % % every stimulus is in both the same and the different condition.
        % cfg.stim.(sesName).(phaseName)(phaseNum).nSame = cfg.stim.nTrained;
        % cfg.stim.(sesName).(phaseName)(phaseNum).nDiff = cfg.stim.nTrained;
        % % rmStims_orig is false because all stimuli are used in both "same"
        % % and "diff" conditions
        % cfg.stim.(sesName).(phaseName)(phaseNum).rmStims_orig = false;
        
        cfg.stim.(sesName).(phaseName)(phaseNum).viewMaxConsecFamily = 3;
        
        % number per species per family (half because each stimulus is
        % presented first or second)
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
          %cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 240;
          cfg.stim.(sesName).(phaseName)(phaseNum).impedanceAfter_nTrials = 0;
        end
        
        % durations, in seconds - viewing
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_view_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_view_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_view_stim = 0.8;
        % durations, in seconds - between
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_bt_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_bt_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_bt_stim = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_bt_response = 2.0;
        % durations, in seconds - within
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_wi_isi = 0.0;
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_wi_preStim = [0.5 0.7];
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_wi_stim = 0.8;
        cfg.stim.(sesName).(phaseName)(phaseNum).comp_wi_response = 2.0;
        
        % do we want to play feedback beeps for no response?
        cfg.stim.(sesName).(phaseName)(phaseNum).playSound = playSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctSound = correctSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectSound = incorrectSound;
        cfg.stim.(sesName).(phaseName)(phaseNum).correctVol = correctVol;
        cfg.stim.(sesName).(phaseName)(phaseNum).incorrectVol = incorrectVol;
        
        % instructions
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.compView.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_comp_1_exp_view.txt',expParam.expName)),...
          {'partNum'},{'1'});
        
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.compBt.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_comp_2_exp_bt.txt',expParam.expName)),...
          {'partNum','leastSimKey','mostSimKey','contKey'},{'2',cfg.keys.compareKeyNames{1},cfg.keys.compareKeyNames{end},cfg.keys.instructContKey});
        
        [cfg.stim.(sesName).(phaseName)(phaseNum).instruct.compWi.text] = et_processTextInstruct(...
          fullfile(cfg.files.instructDir,sprintf('%s_comp_3_exp_wi.txt',expParam.expName)),...
          {'partNum','leastSimKey','mostSimKey','contKey'},{'3',cfg.keys.compareKeyNames{1},cfg.keys.compareKeyNames{end},cfg.keys.instructContKey});
        
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
  % et_calcExpDuration(cfg,expParam,'med');
  % % minimum duration
  % et_calcExpDuration(cfg,expParam,'min');
  
end

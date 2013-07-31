function expertTrain(expName,subNum,useNS)

% function expertTrain(expName,subNum,useNS)
%
% expertise training experiment
%
% 5 potential phases:
%  - Subordinate matching task
%  - Old/new recognition
%  - Name training
%  - Passive viewing (with confirmatory button press.)
%  - Active naming
%
%
%
% See the file README.md for more information
%
% see also: et_saveStimList, config_EBUG, et_processStims_EBUG,
% et_matching, et_viewing, et_naming, et_recognition
%

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

% need to be in the experiment directory to run it. See if this function is
% in the current directory; if it is then we're in the right spot.
%if exist(fullfile(pwd,sprintf('%s.m',mfilename)),'file')
if ~exist(fullfile(pwd,sprintf('%s.m','expertTrain')),'file')
  error('Must be in the experiment directory to run the experiment.');
end

%% process experiment name and subject number

if nargin < 3
  if nargin == 1
    % cannot proceed with one argument
    error('You provided one argument, but you need either zero or three! Must provide either no inputs (%s;) or provide experiment name (as a string), subject number (as an integer), and whether to use Net Station (1 or 0). E.g. %s(''%s'', 9, 1);',mfilename,mfilename,expName);
  elseif nargin == 2
    % cannot proceed with one argument
    error('You provided two arguments, but you need either zero or three! Must provide either no inputs (%s;) or provide experiment name (as a string), subject number (as an integer), and whether to use Net Station (1 or 0). E.g. %s(''%s'', 9, 1);',mfilename,mfilename,expName);
  elseif nargin == 0
    % if no variables are provided, use an input dialogue
    repeat = 1;
    while repeat
      prompt = {'Experiment name (alphanumerics only, no quotes)', 'Subject number (number(s) only)', 'Use Net Station? (1 = yes, 0 = no)'};
      defaultAnswer = {'', '', ''};
      options.Resize = 'on';
      answer = inputdlg(prompt,'Subject Information', 1, defaultAnswer, options);
      [expName, subNum, useNS] = deal(answer{:});
      if isempty(expName) || ~ischar(expName)
        h = errordlg('Experiment name must consist of characters. Try again.', 'Input Error');
        repeat = 1;
        uiwait(h);
        continue
      end
      if isempty(str2double(subNum)) || ~isnumeric(str2double(subNum)) || mod(str2double(subNum),1) ~= 0 || str2double(subNum) <= 0
        h = errordlg('Subject number must be an integer (e.g., 9) and greater than zero. Try again.', 'Input Error');
        repeat = 1;
        uiwait(h);
        continue
      end
      if isempty(str2double(useNS)) || ~isnumeric(str2double(useNS)) || (str2double(useNS) ~= 0 && str2double(useNS) ~= 1)
        h = errordlg('useNS must be either 1 or 0. Try again.', 'Input Error');
        repeat = 1;
        uiwait(h);
        continue
      end
      if ~exist(fullfile(pwd,sprintf('config_%s.m',expName)),'file')
        h = errordlg(sprintf('Configuration file for experiment with name ''%s'' does not exist (config_%s.m). Check the experiment name and try again.',expName,expName), 'Input Error');
        repeat = 1;
        uiwait(h);
        continue
      else
        subNum = str2double(subNum);
        useNS = logical(str2double(useNS));
        repeat = 0;
      end
    end
  end
elseif nargin == 3
  % the correct number of arguments
  
  % check the experiment name make sure the configuration file exists
  if ~isempty(expName) && ischar(expName)
    if ~exist(fullfile(pwd,sprintf('config_%s.m',expName)),'file')
      error('Configuration file for experiment with name ''%s'' does not exist (config_%s.m). Check the experiment name and try again.',expName,expName);
    end
  end
  if isempty(expName) || ~ischar(expName)
    error('Experiment name must consist of characters.');
  end
  
  % check the subject number
  if isempty(subNum)
    error('No subject number provided.');
  end
  if ~isnumeric(subNum) || mod(subNum,1) ~= 0 || subNum <= 0
    fprintf('As subject number (variable: ''subNum''), you entered: ');
    disp(subNum);
    error('Subject number must be an integer (e.g., 9) and greater than zero, and not a string or anything else.');
  end
  
  % check on using Net Station
  if isempty(useNS)
    error('Must provide whether to use Net Station (variable: ''useNS'', 1 or 0).');
  end
  if ~isnumeric(useNS) || (useNS ~= 0 && useNS ~= 1)
    fprintf('For whether to use Net Station (variable: ''useNS''), you entered: ');
    disp(useNS);
    error('useNS must be either 1 or 0.');
  else
    useNS = logical(useNS);
  end
  
elseif nargin > 3
  % cannot proceed with more than three arguments
  error('More than three arguments provided. This function only accetps three arguments: experiment name (as a string), subject number (as an integer), and whether to use Net Station (1=yes, 0=no).');
end

%% Experiment database struct preparation

expParam = struct;
cfg = struct;

% store the experiment name
expParam.expName = expName;
expParam.subject = sprintf('%s%.3d',expParam.expName,subNum);

% set the current directory as the experiment directory
cfg.files.expDir = pwd;

%% Set up the data directories and files

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
  
  % Make sure there is a session left to run.
  %
  % session number is incremented after the run, so after the final
  % session has been run it will be 1 greater than expParam.nSessions
  if expParam.sessionNum <= expParam.nSessions
    fprintf('Starting session %d (%s).\n',expParam.sessionNum,expParam.sesTypes{expParam.sessionNum});
  else
    error('All %s sessions have already been run!',expParam.nSessions);
  end
  
  % override whether to use Net Station, in case it is different for this
  % session
  expParam.useNS = useNS;
else
  % if it doesn't exist that means we're starting a new subject
  expParam.sessionNum = 1;
  
  % whether to use Net Station
  expParam.useNS = useNS;
  
  % Load the experiment's config file. Must create this for each experiment.
  if exist(fullfile(pwd,sprintf('config_%s.m',expParam.expName)),'file')
    [cfg,expParam] = eval(sprintf('config_%s(cfg,expParam);',expParam.expName));
  else
    error('Configuration file for %s experiment does not exist: %s',fullfile(pwd,sprintf('config_%s.m',expParam.expName)));
  end
end

%% Make sure the session number is in order and directories/files exist

% make sure session directory exists
cfg.files.sesSaveDir = fullfile('data',expParam.subject,sprintf('session_%d',expParam.sessionNum));
if ~exist(cfg.files.sesSaveDir,'dir')
  [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.sesSaveDir);
  if canSaveData == false
    error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
  end
end

% set name of the session log file
cfg.files.sesLogFile = fullfile(cfg.files.sesSaveDir,'session.txt');
if exist(cfg.files.sesLogFile,'file')
  %error('Log file for this session already exists (%s). Resuming a session is not yet supported.',cfg.files.sesLogFile);
  warning('Log file for this session already exists (%s).',cfg.files.sesLogFile);
  resumeUnanswered = 1;
  while resumeUnanswered
    resumeSession = input(sprintf('Do you want to resume %s session %d? (type 1 or 0 and press enter). ',expParam.subject,expParam.sessionNum));
    if isnumeric(resumeSession) && (resumeSession == 1 || resumeSession == 0)
      if resumeSession
        fprintf('Attempting to resume session %d (%s)...\n',expParam.sessionNum,cfg.files.sesLogFile);
        resumeUnanswered = 0;
      else
        fprintf('Exiting...\n');
        return
      end
    end
  end
end

%% Save the current experiment data

save(cfg.files.expParamFile,'cfg','expParam');

%% Run the experiment
fprintf('Running experiment: %s, subject %s, session %d...\n',expParam.expName,expParam.subject,expParam.sessionNum);

% Embed core of code in try ... catch statement. If anything goes wrong
% inside the 'try' block (Matlab error), the 'catch' block is executed to
% clean up, save results, close the onscreen window etc.
try
  %% Start data logging
  
  % Open data file and write column headers
  logFile = fopen(cfg.files.sesLogFile,'at');
  
  %% Begin PTB display setup
  
  % Get screenNumber of stimulation display. We choose the display with
  % the maximum index, which is usually the right one, e.g., the external
  % display on a Laptop:
  screens = Screen('Screens');
  screenNumber = max(screens);
  
  % Hide the mouse cursor:
  HideCursor;
  
  % don't display keyboard output
  %if ~ispc
  ListenChar(2);
  %end
  
  % Set up the gray color value to be used as experiment backdrop
  if ~isfield(cfg.screen,'gray')
    fprintf('You did not set a value for cfg.screen.gray! Setting experiment backdrop to the GrayIndex of this screen.\n');
    cfg.screen.gray = GrayIndex(screenNumber);
  end
  
  % Open a double buffered fullscreen window on the stimulation screen
  % 'screenNumber' and choose/draw a gray background. 'w' is the handle
  % used to direct all drawing commands to that window - the "Name" of
  % the window. 'wRect' is a rectangle defining the size of the window.
  % See "help PsychRects" for help on such rectangles and useful helper
  % functions:
  [w, wRect] = Screen('OpenWindow',screenNumber, cfg.screen.gray);
  % store the screen dimensions
  cfg.screen.wRect = wRect;
  
  % midWidth=round(RectWidth(wRect)/2);    % get center coordinates
  % midLength=round(RectHeight(wRect)/2);
  Screen('FillRect', w, cfg.screen.gray);
  % put on a grey screen
  Screen('Flip',w);
  
  % set some font display options
  if ispc
    Screen('Preference','DefaultFontName','Courier New');
    Screen('Preference','DefaultFontStyle',1);
    Screen('Preference','DefaultFontSize',18);
  elseif ismac
    Screen('Preference','DefaultFontName','Courier New');
    Screen('Preference','DefaultFontStyle',0);
    Screen('Preference','DefaultFontSize',18);
  elseif isunix
    Screen('Preference','DefaultFontName','Courier New');
    Screen('Preference','DefaultFontStyle',1);
    Screen('Preference','DefaultFontSize',18);
  end
  
  % Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
  % they are loaded and ready when we need them - without delays
  % in the wrong moment:
  KbCheck;
  WaitSecs(0.1);
  GetSecs;
  
  % Set priority for script execution to realtime priority:
  priorityLevel = MaxPriority(w);
  Priority(priorityLevel);
  
  %% Verify that Net Station will run
  
  if expParam.useNS
    Screen('TextSize', w, cfg.text.basicTextSize);
    % put wait for experimenter instructions on screen
    message = 'Experimenter:\nStart the Net Station application, apply the EEG cap, and check impedance measures...';
    DrawFormattedText(w, message, 'center', 'center', cfg.text.experimenterColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % % wait until g key is held for ~1 seconds
    % KbCheckHold(1000, {cfg.keys.expContinue}, -1);
    % wait until g key is pressed
    RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
    KbWait(-1,2);
    RestrictKeysForKbCheck([]);
    
    % connect
    [NSConnectStatus, NSConnectError] = et_NetStation('Connect', expParam.NSHost, expParam.NSPort); %#ok<NASGU>
    
    if NSConnectStatus
      error('!!! ERROR: Problem with Net Station connection. Check error messages for more information !!!');
    else
      fprintf('\nConnected to Net Station @ %s\n', expParam.NSHost);
      % synchronize
      [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU>
      if NSSyncStatus
        error('!!! ERROR: Problem with Net Station syncronization. Check error messages for more information !!!');
      end
      
      % start recording
      [NSStartStatus, NSStartError] = et_NetStation('StartRecording'); %#ok<NASGU>
      if NSStartStatus
        error('!!! ERROR: Problem with Net Station starting the recording. Check error messages for more information !!!');
      end
      
      % stop recording
      [NSStopStatus, NSStopError] = et_NetStation('StopRecording'); %#ok<NASGU>
      if NSStopStatus
        error('!!! ERROR: Problem with Net Station stopping the recording. Check error messages for more information !!!');
      end
    end
  end
  
  %% EEG baseline recording
  
  if expParam.useNS && expParam.baselineRecordSecs > 0
    Screen('TextSize', w, cfg.text.basicTextSize);
    %display instructions
    baselineMsg = sprintf('The experimenter will now record baseline activity.\nPlease remain still...');
    DrawFormattedText(w, baselineMsg, 'center', 'center', cfg.text.experimenterColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % % wait until g key is held for ~1 seconds
    % KbCheckHold(1000, {cfg.keys.expContinue}, -1);
    % wait until g key is pressed
    RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
    KbWait(-1,2);
    RestrictKeysForKbCheck([]);
    
    % start recording
    Screen('TextSize', w, cfg.text.basicTextSize);
    [NSStartStatus, NSStartError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
    DrawFormattedText(w,'Starting EEG recording...', 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    WaitSecs(5.0);
    
    % tag the start of the rest period
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'REST', GetSecs, .001); %#ok<NASGU,ASGLU>
    
    % draw a countdown -- no need for super accurate timing here
    Screen('TextSize', w, cfg.text.basicTextSize);
    for sec = expParam.baselineRecordSecs:-1:1
      DrawFormattedText(w, num2str(sec), 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      fprintf('%s ', num2str(sec));
      WaitSecs(1.0);
    end
    fprintf('\n');
    
    % tag the end of the rest period
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'REND', GetSecs, .001); %#ok<NASGU,ASGLU>
    
    % stop recording
    [NSStopStatus, NSStopError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
  end
  
%   %% Start Net Station recording for the experiment
%   
%   if expParam.useNS
%     Screen('TextSize', w, cfg.text.basicTextSize);
%     % start recording
%     [NSStartStatus, NSStartError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
%     DrawFormattedText(w,'Starting EEG recording...', 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
%     Screen('Flip', w);
%     WaitSecs(5.0);
%   end
  
  %% Run through the experiment
  
  % find out what session this will be
  sesName = expParam.sesTypes{expParam.sessionNum};
  
  % record the date and start time for this session
  expParam.session.(sesName).date = date;
  startTime = fix(clock);
  expParam.session.(sesName).startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  matchCount = 0;
  nameCount = 0;
  recogCount = 0;
  nametrainCount = 0;
  viewnameCount = 0;
  
  prac_matchCount = 0;
  prac_nameCount = 0;
  prac_recogCount = 0;
  
  % for each phase in this session, run the correct function
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case{'match'}
        % Subordinate Matching task (same/different)
        matchCount = matchCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(matchCount),'date')
          expParam.session.(sesName).(phaseName)(matchCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(matchCount),'startTime')
          expParam.session.(sesName).(phaseName)(matchCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(matchCount),'endTime')
          expParam.session.(sesName).(phaseName)(matchCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_match_%d.mat',sesName,phaseName,matchCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,matchCount);
        end
        
      case {'name'}
        % Naming task
        nameCount = nameCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(nameCount),'date')
          expParam.session.(sesName).(phaseName)(nameCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(nameCount),'startTime')
          expParam.session.(sesName).(phaseName)(nameCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(nameCount),'endTime')
          expParam.session.(sesName).(phaseName)(nameCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d.mat',sesName,phaseName,nameCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,nameCount);
        end
        
      case {'recog'}
        % Recognition (old/new) task
        recogCount = recogCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(recogCount),'date')
          expParam.session.(sesName).(phaseName)(recogCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(recogCount),'startTime')
          expParam.session.(sesName).(phaseName)(recogCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(recogCount),'endTime')
          expParam.session.(sesName).(phaseName)(recogCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_recog_%d.mat',sesName,phaseName,recogCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,recogCount);
        end

      case {'nametrain'}
        % Name training task
        nametrainCount = nametrainCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(nametrainCount),'date')
          expParam.session.(sesName).(phaseName)(nametrainCount).date = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(nametrainCount),'startTime')
          expParam.session.(sesName).(phaseName)(nametrainCount).startTime = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(nametrainCount),'endTime')
          expParam.session.(sesName).(phaseName)(nametrainCount).endTime = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        
        % for each name block
        for b = 1:length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder)
          phaseIsComplete = false;
          phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d_b%d.mat',sesName,phaseName,nametrainCount,b));
          if exist(phaseProgressFile,'file')
            load(phaseProgressFile);
            if exist('phaseComplete','var') && phaseComplete
              phaseIsComplete = true;
            end
          end
          
          if ~phaseIsComplete
            [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,nametrainCount,b);
          end
        end
        
      case {'viewname'}
        % Viewing task, with category response; intermixed with
        % Naming task
        viewnameCount = viewnameCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(viewnameCount).view,'date')
          expParam.session.(sesName).(phaseName)(viewnameCount).view.date = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(viewnameCount).view,'startTime')
          expParam.session.(sesName).(phaseName)(viewnameCount).view.startTime = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(viewnameCount).view,'endTime')
          expParam.session.(sesName).(phaseName)(viewnameCount).view.endTime = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        
        if ~isfield(expParam.session.(sesName).(phaseName)(viewnameCount).name,'date')
          expParam.session.(sesName).(phaseName)(viewnameCount).name.date = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(viewnameCount).name,'startTime')
          expParam.session.(sesName).(phaseName)(viewnameCount).name.startTime = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(viewnameCount).name,'endTime')
          expParam.session.(sesName).(phaseName)(viewnameCount).name.endTime = cell(1,length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder));
        end
        
        % for each view/name block
        for b = 1:length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder)
          % run the viewing task
          phaseIsComplete = false;
          phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_view_%d_b%d.mat',sesName,phaseName,viewnameCount,b));
          if exist(phaseProgressFile,'file')
            load(phaseProgressFile);
            if exist('phaseComplete','var') && phaseComplete
              phaseIsComplete = true;
            end
          end
          
          if ~phaseIsComplete
            [cfg,expParam] = et_viewing(w,cfg,expParam,logFile,sesName,phaseName,viewnameCount,b);
          end
          
          % then run the naming task
          phaseIsComplete = false;
          phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d_b%d.mat',sesName,phaseName,viewnameCount,b));
          if exist(phaseProgressFile,'file')
            load(phaseProgressFile);
            if exist('phaseComplete','var') && phaseComplete
              phaseIsComplete = true;
            end
          end
          
          if ~phaseIsComplete
            [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,viewnameCount,b);
          end
        end
        
      case{'prac_match'}
        % Subordinate Matching task (same/different)
        prac_matchCount = prac_matchCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_matchCount),'date')
          expParam.session.(sesName).(phaseName)(prac_matchCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_matchCount),'startTime')
          expParam.session.(sesName).(phaseName)(prac_matchCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_matchCount),'endTime')
          expParam.session.(sesName).(phaseName)(prac_matchCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_match_%d.mat',sesName,phaseName,prac_matchCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,prac_matchCount);
        end
        
      case {'prac_name'}
        % Naming task
        prac_nameCount = prac_nameCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_nameCount),'date')
          expParam.session.(sesName).(phaseName)(prac_nameCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_nameCount),'startTime')
          expParam.session.(sesName).(phaseName)(prac_nameCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_nameCount),'endTime')
          expParam.session.(sesName).(phaseName)(prac_nameCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d.mat',sesName,phaseName,prac_nameCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,prac_nameCount);
        end
        
      case {'prac_recog'}
        % Recognition (old/new) task
        prac_recogCount = prac_recogCount + 1;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_recogCount),'date')
          expParam.session.(sesName).(phaseName)(prac_recogCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_recogCount),'startTime')
          expParam.session.(sesName).(phaseName)(prac_recogCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(prac_recogCount),'endTime')
          expParam.session.(sesName).(phaseName)(prac_recogCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_recog_%d.mat',sesName,phaseName,prac_recogCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,prac_recogCount);
        end

      otherwise
        warning('%s is not a configured phase in this session (%s)!\n',phaseName,sesName);
    end
  end
  
  %% Session is done
  
  fprintf('Done with session %d (%s).\n',expParam.sessionNum,sesName);
  
  % record the end time for this session
  endTime = fix(clock);
  expParam.session.(sesName).endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6));
  
  % increment the session number for running the next session
  expParam.sessionNum = expParam.sessionNum + 1;
  
  % save the experiment data
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % close out the log file
  fclose(logFile);
  
  % end of EEG recording, hang up with netstation
  if expParam.useNS
    % stop recording
    %[NSStopStatus, NSStopError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
    fprintf('\nDisconnecting from Net Station @ %s\n', expParam.NSHost);
    [NSDisconnectStatus, NSDisconnectError] = et_NetStation('Disconnect'); %#ok<NASGU,ASGLU>
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Finish Message  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  message = sprintf('Thank you, this session is complete.\n\nPlease wait for the experimenter.');
  Screen('TextSize', w, cfg.text.basicTextSize);
  % put the instructions on the screen
  DrawFormattedText(w, message, 'center', 'center', cfg.text.experimenterColor, cfg.text.instructCharWidth);
  % Update the display to show the message:
  Screen('Flip', w);
  
  % % wait until g key is held for ~1 seconds
  % KbCheckHold(1000, {cfg.keys.expContinue}, -1);
  % wait until g key is pressed
  RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
  KbWait(-1,2);
  RestrictKeysForKbCheck([]);
  Screen('Flip', w);
  WaitSecs(1.000);
  
  % Cleanup at end of experiment - Close window, show mouse cursor, close
  % result file, switch Matlab/Octave back to priority 0 -- normal
  % priority:
  Screen('CloseAll');
  fclose('all');
  ShowCursor;
  %if ~ispc
  ListenChar;
  %end
  Priority(0);
  
  % End of experiment:
  return
  
catch ME %#ok<NASGU>
  % catch error: This is executed in case something goes wrong in the
  % 'try' part due to programming error etc.:
  
  sesName = expParam.sesTypes{expParam.sessionNum};
  fprintf('\nError during session %d (%s). Exiting gracefully (saving experimentParams.mat). You should restart Matlab before continuing.\n',expParam.sessionNum,sesName);
  
  % record the error date and time for this session
  errorDate = date;
  errorTime = fix(clock);
  expParam.session.(sesName).errorDate = errorDate;
  expParam.session.(sesName).errorTime = sprintf('%.2d:%.2d:%.2d',errorTime(4),errorTime(5),errorTime(6));
  
  fprintf(logFile,'Crash\t%s\t%s\n',errorDate,expParam.session.(sesName).errorTime);
  
  % save the experiment info in its current state
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % close out the session log file
  fclose(logFile);
  
  % save out the error information
  save(fullfile(cfg.files.sesSaveDir,sprintf('error_%s_ses%d_%s_%.2d%.2d%.2d.mat',expParam.subject,expParam.sessionNum,errorDate,errorTime(4),errorTime(5),errorTime(6))),'ME');
  
  % end of EEG recording, hang up with netstation
  if expParam.useNS
    % stop recording
    %[NSStopStatus, NSStopError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
    fprintf('\nDisconnecting from Net Station @ %s\n', expParam.NSHost);
    [NSDisconnectStatus, NSDisconnectError] = et_NetStation('Disconnect'); %#ok<NASGU,ASGLU>
  end
  
  % Do same cleanup as at the end of a regular session...
  Screen('CloseAll');
  fclose('all');
  ShowCursor;
  %if ~ispc
  ListenChar;
  %end
  Priority(0);
  
  % Output the error message that describes the error:
  psychrethrow(psychlasterror);
  
end % try ... catch


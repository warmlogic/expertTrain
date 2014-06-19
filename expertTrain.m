function expertTrain(expName,subNum,useNS,photoCellTest)
% function expertTrain(expName,subNum,useNS,photoCellTest)
%
% expertise training experiment (and more!)
%
% Many potential phases:
%  - Subordinate matching task (et_matching)
%  - Old/new recognition (et_recognition)
%  - Name training (et_naming with block setup)
%  - Passive viewing (with confirmatory button press.) (et_viewing)
%  - Active naming (et_naming)
%  - Comparison (similarity of two stimuli) (et_compare)
%  - Exposure with ratings (space_exposure)
%  - Pair associate studying (space_multistudy)
%  - Math distractor (space_distract_math)
%  - Cued recall with typing (space_cued_recall)
%
% Input:
%  expName:       the name of the experiment (as a string). You must set up
%                 a config_EXPNAME.m file describing the experiment
%                 configuration.
%  subNum:        the subject number (integer). This will get transformed
%                 into the full subject name EXPNAMEXXX; e.g., subNum=1 =
%                 EXPNAME001.
%  useNS:         whether to use Net Station (logical; 1 for yes, 0 for no)
%  photoCellTest: whether to conduct a photocell test (logical; 1 for yes,
%                 0 for no). Default = 0.
%
% NB: You can also launch the experiment by just running the command:
%     expertTrain;
%     A popup window will prompt for the above info. It is not possible to
%     run the photoCellTest using this method.
%
% See the file README.md for more information.
%
% see also: et_saveStimList, config_EBUG, config_EBIRD, config_COMP,
%           et_processStims, et_matching, et_viewing, et_naming,
%           et_recognition, et_compare

% see also: space_processStims, space_saveStimList, space_exposure,
%           space_multistudy, space_distract_math, space_cued_recall
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

% make sure there are somewhere betwen 0 and 4 arguments
minArg = 0;
maxArg = 4;
narginchk(minArg,maxArg);

if nargin == 0
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
  
  % default
  photoCellTest = false;
  
elseif nargin == 1
  % cannot proceed with one argument
  error('You provided 1 argument, but you need either zero or three! Must provide either no inputs (%s;) or provide experiment name (as a string), subject number (as an integer), and whether to use Net Station (1 or 0). E.g. %s(''%s'', 9, 1);',mfilename,mfilename,expName);
elseif nargin == 2
  % cannot proceed with one argument
  error('You provided 2 arguments, but you need either zero or three! Must provide either no inputs (%s;) or provide experiment name (as a string), subject number (as an integer), and whether to use Net Station (1 or 0). E.g. %s(''%s'', 9, 1);',mfilename,mfilename,expName);
elseif nargin >= 3
  % the correct number of arguments
  
  if nargin == 3
    % default
    photoCellTest = false;
  end
  
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
    error('Must provide whether to use Net Station (variable: ''useNS'', 1 (yes) or 0 (no)).');
  end
  if ~islogical(useNS)
    if ~isnumeric(useNS) || (useNS ~= 0 && useNS ~= 1)
      fprintf('For whether to use Net Station (variable: ''useNS''), you entered: ');
      disp(useNS);
      error('useNS must be either 1 or 0.');
    else
      useNS = logical(useNS);
    end
  end
  
  % check on using Net Station
  if isempty(photoCellTest)
    error('Must provide whether to run the photocell test (variable: ''photoCellTest'', 1 (yes) or 0 (no)).');
  end
  if ~islogical(photoCellTest)
    if ~isnumeric(photoCellTest) || (photoCellTest ~= 0 && photoCellTest ~= 1)
      fprintf('For whether to run the photocell test (variable: ''photoCellTest''), you entered: ');
      disp(photoCellTest);
      error('photoCellTest must be either 1 or 0.');
    else
      photoCellTest = logical(photoCellTest);
    end
    if photoCellTest && ~useNS
      error('If doing a photocell test, must use Net Station (set variable: ''useNS'' = 1)');
    end
  end
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
    % make sure we want to start this session
    startUnanswered = 1;
    if expParam.useNS
      NSstr = 'with Net Station enabled';
    else
      NSstr = 'WITHOUT Net Station enabled';
    end
    while startUnanswered
      startSession = input(sprintf('Do you want to start %s session %d (%s) %s? (type 1 or 0 and press enter). ',expParam.subject,expParam.sessionNum,expParam.sesTypes{expParam.sessionNum},NSstr));
      if isnumeric(startSession) && (startSession == 1 || startSession == 0)
        if startSession
          fprintf('Starting %s session %d (%s).\n',expParam.subject,expParam.sessionNum,expParam.sesTypes{expParam.sessionNum});
          startUnanswered = 0;
        else
          fprintf('Not starting %s session %d (%s)! If you typed the wrong subject number, exit Matlab and try again.\n',expParam.subject,expParam.sessionNum,expParam.sesTypes{expParam.sessionNum});
          return
        end
      end
    end
  else
    fprintf('All %s sessions for %s have already been run! Exiting...\n',expParam.nSessions,expParam.subject);
    return
  end
  
  % override whether to use Net Station, in case it is different for this
  % session
  expParam.useNS = useNS;
  
  % whether to do a photocell test
  expParam.photoCellTest = photoCellTest;
else
  % if it doesn't exist that means we're starting a new subject
  expParam.sessionNum = 1;
  
  % whether to use Net Station
  expParam.useNS = useNS;
  
  % whether to do a photocell test
  expParam.photoCellTest = photoCellTest;
  
  % make sure we want to start this session
  startUnanswered = 1;
  if expParam.useNS
    NSstr = 'with Net Station enabled';
  else
    NSstr = 'WITHOUT Net Station enabled';
  end
  while startUnanswered
    startSession = input(sprintf('Do you want to start %s session %d %s? (type 1 or 0 and press enter). ',expParam.subject,expParam.sessionNum,NSstr));
    if ~isempty(startSession) && isnumeric(startSession) && (startSession == 1 || startSession == 0)
      if startSession
        fprintf('Starting %s session %d.\n',expParam.subject,expParam.sessionNum);
        startUnanswered = 0;
      else
        fprintf('Not starting %s session %d! If you typed the wrong subject number, exit Matlab and try again.\n',expParam.subject,expParam.sessionNum);
        return
      end
    end
  end
  
  % Load the experiment's config file. Must create this for each experiment.
  if exist(fullfile(pwd,sprintf('config_%s.m',expParam.expName)),'file')
    [cfg,expParam] = eval(sprintf('config_%s(cfg,expParam);',expParam.expName));
    
    if strcmp(expParam.expName,'EBUG_UMA')
      return
    end
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
        fprintf('Attempting to resume %s session %d (%s)...\n',expParam.subject,expParam.sessionNum,cfg.files.sesLogFile);
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
  
  % set some font display options; must be set before opening w with Screen
  DefaultFontName = 'Courier New';
  DefaultFontStyle = 1;
  DefaultFontSize = 18;
  if ispc
    Screen('Preference','DefaultFontName',DefaultFontName);
    Screen('Preference','DefaultFontStyle',DefaultFontStyle);
    Screen('Preference','DefaultFontSize',DefaultFontSize);
  elseif ismac
    Screen('Preference','DefaultFontName',DefaultFontName);
    Screen('Preference','DefaultFontStyle',DefaultFontStyle);
    Screen('Preference','DefaultFontSize',DefaultFontSize);
  elseif isunix
    Screen('Preference','DefaultFontName',DefaultFontName);
    Screen('Preference','DefaultFontStyle',DefaultFontStyle);
    Screen('Preference','DefaultFontSize',DefaultFontSize);
  end
  
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
  
  % Set up the color value to be used as experiment background color
  if ~isfield(cfg.screen,'bgColor')
    cfg.screen.bgColor = GrayIndex(screenNumber);
    warning('You did not set a value for the background color (cfg.screen.bgColor in your config_%s.m)! It is recommended to set this value. Setting experiment backdrop to the GrayIndex of this screen (%d).',expParam.expName,cfg.screen.bgColor);
    manualBgColor = false;
  else
    manualBgColor = true;
  end
  
  if expParam.photoCellTest
    % override setting in config_EXPNAME to show white photocell rectangle
    cfg.stim.photoCell = true;
    
    %cfg.screen.bgColor = BlackIndex(screenNumber);
    %fprintf('Doing a photocell test. Setting experiment background color to the BlackIndex of this screen (%d).\n',cfg.screen.bgColor);
    %warning('Black text (e.g., instructions) may not be visible!');
  end
  
  if cfg.stim.photoCell && ~useNS
    warning('Photocell rectangle is only useful when recording in Net Station. Turning off photocell rectangle!!!\nTo stop this warning in the future, either set variable ''useNS'' to 1 (when running experiment), or turn off the photocell (cfg.stim.photoCell = false; in config_%s.m).',expParam.expName);
    cfg.stim.photoCell = false;
  end
  
  % Open a double buffered fullscreen window on the stimulation screen
  % 'screenNumber' and choose/draw a background color. 'w' is the handle
  % used to direct all drawing commands to that window - the "Name" of
  % the window. 'wRect' is a rectangle defining the size of the window.
  % See "help PsychRects" for help on such rectangles and useful helper
  % functions:
  [w, wRect] = Screen('OpenWindow', screenNumber, cfg.screen.bgColor);
  
  % Hack: something's weird with fonts in Mac Matlab (only 2013b? but
  % possibly also 2012b). It seems that the window needs to be closed and
  % opened again to get the font set correctly.
  if ismac && (~isempty(strfind(version,'2012b')) || ~isempty(strfind(version,'2013a')) || ~isempty(strfind(version,'2013b')))
    Screen('CloseAll');
    Screen('Preference','DefaultFontName',DefaultFontName);
    Screen('Preference','DefaultFontStyle',DefaultFontStyle);
    Screen('Preference','DefaultFontSize',DefaultFontSize);
    [w, wRect] = Screen('OpenWindow', screenNumber, cfg.screen.bgColor);
  end
  
  % store the screen dimensions
  cfg.screen.wRect = wRect;
  
  % set up the photocell test rectangle
  if cfg.stim.photoCell
    if ~isfield(cfg.stim,'photoCellRectSize')
      cfg.stim.photoCellRectSize = 50;
    end
    cfg.stim.photoCellRect = SetRect(0, 0, cfg.stim.photoCellRectSize, cfg.stim.photoCellRectSize);
    cfg.stim.photoCellRect = AlignRect(cfg.stim.photoCellRect,wRect,'bottom','right');
    cfg.stim.photoCellRectColor = uint8((rgb('White') * 255) + 0.5);
    %cfg.stim.photoCellRectColor = rgb('White');
    
    % color for when stimuli are not on screen
    cfg.stim.photoCellAntiRectColor = uint8((rgb('Black') * 255) + 0.5);
    %cfg.stim.photoCellAntiRectColor = rgb('Black');
  end
  
  if ~manualBgColor
    Screen('TextSize', w, cfg.text.basicTextSize);
    DrawFormattedText(w,sprintf('You did not set a value for the background color (cfg.screen.bgColor in config_%s.m)! It is recommended to set this value.\nHowever, I am automatically setting to GrayIndex of this screen (%d).\n\nPress any key to continue with these settings.',expParam.expName,cfg.screen.bgColor),'center','center',uint8((rgb('Red') * 255) + 0.5), 70);
    
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    % put message on screen
    Screen('Flip', w);
    
    RestrictKeysForKbCheck([]);
    KbWait(-1,2);
  end
  
  if expParam.photoCellTest
    Screen('TextSize', w, cfg.text.basicTextSize);
    %DrawFormattedText(w,sprintf('Doing a photocell test.\nSetting experiment background color to the BlackIndex of this screen (%d).\n\nBlack text (e.g., instructions) may not be visible but should proceed automatically!\n\nPress any key to continue.',cfg.screen.bgColor),'center','center',uint8((rgb('Red') * 255) + 0.5), 70);
    DrawFormattedText(w,'Doing a photocell test.\n\nAlign the photodiode with the black rectangle.\n\nThe experiment should proceed automatically!\n\nPress any key to continue.','center','center',uint8((rgb('Red') * 255) + 0.5), 70);
    
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    % put message on screen
    Screen('Flip', w);
    
    RestrictKeysForKbCheck([]);
    KbWait(-1,2);
  elseif ~expParam.photoCellTest && cfg.stim.photoCell
    Screen('TextSize', w, cfg.text.basicTextSize);
    DrawFormattedText(w,'Using photocell.\n\nAlign the photodiode with the black rectangle.\n\nPress any key to continue.','center','center',uint8((rgb('Red') * 255) + 0.5), 70);
    
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    % put message on screen
    Screen('Flip', w);
    
    RestrictKeysForKbCheck([]);
    KbWait(-1,2);
  end
  
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % put on the blank background color screen
  Screen('Flip',w);
  
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
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    
    % % wait until g key is held for ~1 seconds
    % KbCheckHold(1000, {cfg.keys.expContinue}, -1);
    % wait until g key is pressed
    RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
    KbWait(-1,2);
    RestrictKeysForKbCheck([]);
    
    fprintf('\nTrying to connect to Net Station @ %s, port %d...\n', expParam.NSHost, expParam.NSPort);
    % connect
    [NSConnectStatus, NSConnectError] = NetStation('Connect', expParam.NSHost, expParam.NSPort);
    
    if NSConnectStatus
      error('!!! ERROR: Problem with Net Station connection because of error: %s !!!',NSConnectError);
    else
      fprintf('\nConnected to Net Station @ %s, port %d.\n', expParam.NSHost, expParam.NSPort);
      % synchronize
      [NSSyncStatus, NSSyncError] = NetStation('Synchronize');
      if NSSyncStatus
        error('!!! ERROR: Problem with Net Station syncronization. because of error: %s !!!',NSSyncError);
      end
      
      % start recording
      [NSStartStatus, NSStartError] = NetStation('StartRecording');
      if NSStartStatus
        error('!!! ERROR: Problem with Net Station starting the recording because of error: %s !!!',NSStartError);
      end
      
      % stop recording
      [NSStopStatus, NSStopError] = NetStation('StopRecording');
      if NSStopStatus
        error('!!! ERROR: Problem with Net Station stopping the recording because of error: %s !!!',NSStopError);
      end
    end
  end
  
  %% EEG baseline recording
  
  if expParam.useNS && ~expParam.photoCellTest && expParam.baselineRecordSecs > 0
    Screen('TextSize', w, cfg.text.basicTextSize);
    %display instructions
    baselineMsg = sprintf('The experimenter will now record baseline activity.\nPlease remain still...');
    DrawFormattedText(w, baselineMsg, 'center', 'center', cfg.text.experimenterColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    
    % % wait until g key is held for ~1 seconds
    % KbCheckHold(1000, {cfg.keys.expContinue}, -1);
    % wait until g key is pressed
    RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
    KbWait(-1,2);
    RestrictKeysForKbCheck([]);
    
    % start recording
    Screen('TextSize', w, cfg.text.basicTextSize);
    [NSStartStatus, NSStartError] = NetStation('StartRecording');
    if NSStartStatus
      error('!!! ERROR: Problem with Net Station starting the recording because of error: %s !!!',NSStartError);
    end
    DrawFormattedText(w,'Starting EEG recording...', 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(5.0);
    
    % tag the start of the rest period
    [NSEventStatus, NSEventError] = NetStation('Event', 'REST', GetSecs, .001); %#ok<NASGU,ASGLU>
    
    % draw a countdown -- no need for super accurate timing here
    Screen('TextSize', w, cfg.text.basicTextSize);
    for sec = expParam.baselineRecordSecs:-1:1
      DrawFormattedText(w, num2str(sec), 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      fprintf('%s ', num2str(sec));
      WaitSecs(1.0);
    end
    fprintf('\n');
    
    % tag the end of the rest period
    [NSEventStatus, NSEventError] = NetStation('Event', 'REND', GetSecs, .001); %#ok<NASGU,ASGLU>
    
    % stop recording
    [NSStopStatus, NSStopError] = NetStation('StopRecording');
    if NSStopStatus
      error('!!! ERROR: Problem with Net Station stopping the recording because of error: %s !!!',NSStopError);
    end
  end
  
%   %% Start Net Station recording for the experiment
%   
%   if expParam.useNS
%     Screen('TextSize', w, cfg.text.basicTextSize);
%     % start recording
%     [NSStartStatus, NSStartError] = NetStation('StartRecording'); %#ok<NASGU,ASGLU>
%     DrawFormattedText(w,'Starting EEG recording...', 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
%     if cfg.stim.photoCell
%       Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
%     end
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
  compareCount = 0;
  
  prac_matchCount = 0;
  prac_nameCount = 0;
  prac_recogCount = 0;
  
  % spacing
  expoCount = 0;
  msCount = 0;
  distCount = 0;
  crCount = 0;
  
  prac_expoCount = 0;
  prac_msCount = 0;
  prac_distCount = 0;
  prac_crCount = 0;
  
  % for each phase in this session, run the correct function
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case{'match'}
        % Subordinate Matching task (same/different)
        matchCount = matchCount + 1;
        phaseCount = matchCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_match_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case {'name'}
        % Naming task
        nameCount = nameCount + 1;
        phaseCount = nameCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case {'recog'}
        % Recognition (old/new) task
        recogCount = recogCount + 1;
        phaseCount = recogCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_recog_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end

      case {'nametrain'}
        % Name training task
        nametrainCount = nametrainCount + 1;
        phaseCount = nametrainCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        
        % for each name block
        for b = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)
          phaseIsComplete = false;
          phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d_b%d.mat',sesName,phaseName,phaseCount,b));
          if exist(phaseProgressFile,'file')
            load(phaseProgressFile);
            if exist('phaseComplete','var') && phaseComplete
              phaseIsComplete = true;
            end
          end
          
          if ~phaseIsComplete
            [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,phaseCount,b);
          end
        end
        
      case {'viewname'}
        % Viewing task, with category response; intermixed with
        % Naming task
        viewnameCount = viewnameCount + 1;
        phaseCount = viewnameCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount).view,'date')
          expParam.session.(sesName).(phaseName)(phaseCount).view.date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount).view,'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).view.startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount).view,'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).view.endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount).name,'date')
          expParam.session.(sesName).(phaseName)(phaseCount).name.date = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount).name,'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).name.startTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount).name,'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).name.endTime = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
        end
        
        % for each view/name block
        for b = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)
          % run the viewing task
          phaseIsComplete = false;
          phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_view_%d_b%d.mat',sesName,phaseName,phaseCount,b));
          if exist(phaseProgressFile,'file')
            load(phaseProgressFile);
            if exist('phaseComplete','var') && phaseComplete
              phaseIsComplete = true;
            end
          end
          
          if ~phaseIsComplete
            [cfg,expParam] = et_viewing(w,cfg,expParam,logFile,sesName,phaseName,phaseCount,b);
          end
          
          % then run the naming task
          phaseIsComplete = false;
          phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d_b%d.mat',sesName,phaseName,phaseCount,b));
          if exist(phaseProgressFile,'file')
            load(phaseProgressFile);
            if exist('phaseComplete','var') && phaseComplete
              phaseIsComplete = true;
            end
          end
          
          if ~phaseIsComplete
            [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,phaseCount,b);
          end
        end
        
      case{'compare'}
        % Comparison task
        compareCount = compareCount + 1;
        phaseCount = compareCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_comp_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_compare(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case{'prac_match'}
        % Subordinate Matching task (same/different)
        prac_matchCount = prac_matchCount + 1;
        phaseCount = prac_matchCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_match_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case {'prac_name'}
        % Naming task
        prac_nameCount = prac_nameCount + 1;
        phaseCount = prac_nameCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_name_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case {'prac_recog'}
        % Recognition (old/new) task
        prac_recogCount = prac_recogCount + 1;
        phaseCount = prac_recogCount;
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_recog_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end

      case {'expo','prac_expo'}
        % Spacing exposure task
        if strcmp(phaseName,'expo')
          expoCount = expoCount + 1;
          phaseCount = expoCount;
        elseif strcmp(phaseName,'prac_expo')
          prac_expoCount = prac_expoCount + 1;
          phaseCount = prac_expoCount;
        end
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_expo_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = space_exposure(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case {'multistudy','prac_multistudy'}
        % Spacing study task
        if strcmp(phaseName,'multistudy')
          msCount = msCount + 1;
          phaseCount = msCount;
        elseif strcmp(phaseName,'prac_multistudy')
          prac_msCount = prac_msCount + 1;
          phaseCount = prac_msCount;
        end
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_multistudy_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = space_multistudy(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case {'distract_math','prac_distract_math'}
        % Spacing math distractor task
        if strcmp(phaseName,'distract_math')
          distCount = distCount + 1;
          phaseCount = distCount;
        elseif strcmp(phaseName,'prac_distract_math')
          prac_distCount = prac_distCount + 1;
          phaseCount = prac_distCount;
        end
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_distMath_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = space_distract_math(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      case {'cued_recall','prac_cued_recall'}
        % Spacing cued recall task
        if strcmp(phaseName,'cued_recall')
          crCount = crCount + 1;
          phaseCount = crCount;
        elseif strcmp(phaseName,'prac_cued_recall')
          prac_crCount = prac_crCount + 1;
          phaseCount = prac_crCount;
        end
        
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'date')
          expParam.session.(sesName).(phaseName)(phaseCount).date = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'startTime')
          expParam.session.(sesName).(phaseName)(phaseCount).startTime = [];
        end
        if ~isfield(expParam.session.(sesName).(phaseName)(phaseCount),'endTime')
          expParam.session.(sesName).(phaseName)(phaseCount).endTime = [];
        end
        
        phaseIsComplete = false;
        phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_cuedRecall_%d.mat',sesName,phaseName,phaseCount));
        if exist(phaseProgressFile,'file')
          load(phaseProgressFile);
          if exist('phaseComplete','var') && phaseComplete
            phaseIsComplete = true;
          end
        end
        
        if ~phaseIsComplete
          [cfg,expParam] = space_cued_recall(w,cfg,expParam,logFile,sesName,phaseName,phaseCount);
        end
        
      otherwise
        warning('%s is not a configured phase for %s session (%s)!\n',phaseName,expParam.subject,sesName);
    end
  end
  
  %% Session is done
  
  fprintf('Done with %s session %d (%s).\n',expParam.subject,expParam.sessionNum,sesName);
  
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
    %[NSStopStatus, NSStopError] = NetStation('StopRecording'); %#ok<NASGU,ASGLU>
    fprintf('\nDisconnecting from Net Station @ %s\n', expParam.NSHost);
    [NSDisconnectStatus, NSDisconnectError] = NetStation('Disconnect'); %#ok<NASGU,ASGLU>
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Finish Message  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  message = sprintf('Thank you, this session is complete.\n\nPlease wait for the experimenter.');
  Screen('TextSize', w, cfg.text.basicTextSize);
  % put the instructions on the screen
  DrawFormattedText(w, message, 'center', 'center', cfg.text.experimenterColor, cfg.text.instructCharWidth);
  % Update the display to show the message:
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  Screen('Flip', w);
  
  % % wait until g key is held for ~1 seconds
  % KbCheckHold(1000, {cfg.keys.expContinue}, -1);
  % wait until g key is pressed
  RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
  KbWait(-1,2);
  RestrictKeysForKbCheck([]);
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
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
  
catch ME
  % catch error: This is executed in case something goes wrong in the
  % 'try' part due to programming error etc.:
  
  sesName = expParam.sesTypes{expParam.sessionNum};
  fprintf('\nError during %s session %d (%s). Exiting gracefully (saving experimentParams.mat). You should restart Matlab before continuing.\n',expParam.subject,expParam.sessionNum,sesName);
  
  % record the error date and time for this session
  errorDate = date;
  errorTime = fix(clock);
  expParam.session.(sesName).errorDate = errorDate;
  expParam.session.(sesName).errorTime = sprintf('%.2d:%.2d:%.2d',errorTime(4),errorTime(5),errorTime(6));
  
  fprintf(logFile,'!!! ERROR: Crash %s %s\n',errorDate,expParam.session.(sesName).errorTime);
  
  % save the experiment info in its current state
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % close out the session log file
  fclose(logFile);
  
  % save out the error information
  errorFile = fullfile(cfg.files.sesSaveDir,sprintf('error_%s_ses%d_%s_%.2d%.2d%.2d.mat',expParam.subject,expParam.sessionNum,errorDate,errorTime(4),errorTime(5),errorTime(6)));
  fprintf('Saving error file %s.\n',errorFile);
  save(errorFile,'ME');
  errorReport = ME.getReport;
  if ~isempty(errorReport)
    fprintf('The error probably occurred because:\n');
    fprintf('%s',errorReport);
    fprintf('\n');
  end
  fprintf('To manually inspect the error, load the file with this command:\nload(''%s'');\n',errorFile);
  fprintf('\n\tType ME and look at the ''message'' field (i.e., ME.message) to see WHY the error occured.\n');
  fprintf('\tType ME.stack(1), ME.stack(2), etc. to see WHERE the error occurred.\n');
  
  % end of EEG recording, hang up with netstation
  if expParam.useNS
    % stop recording
    %[NSStopStatus, NSStopError] = NetStation('StopRecording'); %#ok<NASGU,ASGLU>
    fprintf('\nDisconnecting from Net Station @ %s\n', expParam.NSHost);
    [NSDisconnectStatus, NSDisconnectError] = NetStation('Disconnect'); %#ok<NASGU,ASGLU>
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


function expertTrain(expName,subNum)

% function expertTrain(expName,subNum)
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
%
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

if nargin < 2
  if nargin == 1
    % cannot proceed with one argument
    error('You provided one argument, but you need either zero or two! Must provide either no inputs (%s;) or provide both experiment name (as a string) and subject number (as an integer), e.g. %s(''%s'', 9);',mfilename,mfilename,expName);
  elseif nargin == 0
    % if no variables are provided, use an input dialogue
    repeat = 1;
    while repeat
      prompt = {'Experiment name (alphanumerics only, no quotes)', 'Subject number (number(s) only)'};
      defaultAnswer = {'', ''};
      options.Resize = 'on';
      answer = inputdlg(prompt,'Subject Information', 1, defaultAnswer, options);
      [expName, subNum] = deal(answer{:});
      if isempty(expName) || ~ischar(expName)
        h = errordlg('Experiment name must consist of characters. Try again.', 'Input Error');
        repeat = 1;
        uiwait(h);
      elseif isempty(str2double(subNum)) || ~isnumeric(str2double(subNum)) || mod(str2double(subNum),1) ~= 0 || str2double(subNum) <= 0
        h = errordlg('Subject number must be an integer (e.g., 9) and greater than zero. Try again.', 'Input Error');
        repeat = 1;
        uiwait(h);
      else
        if ~exist(fullfile(pwd,sprintf('config_%s.m',expName)),'file')
          h = errordlg(sprintf('Configuration file for experiment with name ''%s'' does not exist (config_%s.m). Check the experiment name and try again.',expName,expName), 'Input Error');
          repeat = 1;
          uiwait(h);
        else
          subNum = str2double(subNum);
          repeat = 0;
        end
      end
    end
  end
elseif nargin == 2
  % the correct number of arguments
  
  % check the experiment name make sure the configuration file exists
  if ~isempty(expName) && ischar(expName)
    if ~exist(fullfile(pwd,sprintf('config_%s.m',expName)),'file')
      error('Configuration file for experiment with name ''%s'' does not exist (config_%s.m). Check the experiment name and try again.',expName,expName);
    end
  elseif isempty(expName) || ~ischar(expName)
    error('Experiment name must consist of characters.');
  end
  
  % check the subject number
  if isempty(subNum)
    error('No subject number provided.');
  elseif ~isnumeric(subNum) || mod(subNum,1) ~= 0 || subNum <= 0
    fprintf('As subject number (variable: ''subNum''), you entered: ');
    disp(subNum);
    error('Subject number must be an integer (e.g., 9) and greater than zero, and not a string or anything else.');
  end
  
elseif nargin > 2
  % cannot proceed with more than two arguments
  error('More than two arguments provided. This function only accetps two arguments: experiment name (as a string) and subject number (as an integer).');
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
  
else
  % if it doesn't exist that means we're starting a new subject
  expParam.sessionNum = 1;
  
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
%cfg.files.sesLogFile = fullfile(cfg.files.sesSaveDir,'session.log');
% % debug - comment out exist sesLogFile check
if exist(cfg.files.sesLogFile,'file')
  error('Log file for this session already exists (%s). Resuming a session is not yet supported.',cfg.files.sesLogFile);
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
  logFile = fopen(cfg.files.sesLogFile,'wt');
  
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
    Screen('Preference','DefaultFontName','Arial');
    Screen('Preference','DefaultFontStyle',0);
    Screen('Preference','DefaultFontSize',18);
  elseif ismac
    Screen('Preference','DefaultFontName','Helvetica');
    Screen('Preference','DefaultFontStyle',0);
    Screen('Preference','DefaultFontSize',18);
  elseif isunix
    Screen('Preference','DefaultFontName','Arial');
    Screen('Preference','DefaultFontStyle',0);
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
    % synchronize
    [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU>
    % start recording
    [NSStartStatus, NSStartError] = et_NetStation('StartRecording'); %#ok<NASGU>
    
    if NSConnectStatus || NSSyncStatus || NSStartStatus
      error('!!! ERROR: Problem with Net Station connect/sync/start. Check error messages for more information !!!');
    else
      fprintf('\nConnected to Net Station @ %s\n', expParam.NSHost);
      % stop recording
      [NSStopStatus, NSStopError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
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
        
        et_matching(w,cfg,expParam,logFile,sesName,phaseName,matchCount);
        
      case {'name'}
        % Naming task
        nameCount = nameCount + 1;
        
        et_naming(w,cfg,expParam,logFile,sesName,phaseName,nameCount);
        
      case {'recog'}
        % Recognition (old/new) task
        recogCount = recogCount + 1;
        
        et_recognition(w,cfg,expParam,logFile,sesName,phaseName,recogCount);

      case {'nametrain'}
        % Name training task
        nametrainCount = nametrainCount + 1;
        
        % for each view/name block
        for b = 1:length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder)
          et_naming(w,cfg,expParam,logFile,sesName,phaseName,nametrainCount,b);
        end
        
      case {'viewname'}
        % Viewing task, with category response; intermixed with
        % Naming task
        viewnameCount = viewnameCount + 1;
        
        % for each view/name block
        for b = 1:length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder)
          % run the viewing task
          et_viewing(w,cfg,expParam,logFile,sesName,phaseName,viewnameCount,b);
          
          % then run the naming task
          et_naming(w,cfg,expParam,logFile,sesName,phaseName,viewnameCount,b);
        end
        
      case{'prac_match'}
        % Subordinate Matching task (same/different)
        prac_matchCount = prac_matchCount + 1;
        
        et_matching(w,cfg,expParam,logFile,sesName,phaseName,prac_matchCount);
        
      case {'prac_name'}
        % Naming task
        prac_nameCount = prac_nameCount + 1;
        
        et_naming(w,cfg,expParam,logFile,sesName,phaseName,prac_nameCount);
        
      case {'prac_recog'}
        % Recognition (old/new) task
        prac_recogCount = prac_recogCount + 1;
        
        et_recognition(w,cfg,expParam,logFile,sesName,phaseName,prac_recogCount);

      otherwise
        warning('%s is not a configured phase in this session (%s)!\n',phaseName,sesName);
    end
  end
  
  %% Session is done
  
  fprintf('Done with session %d.\n',expParam.sessionNum);
  
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
  if ~ispc
    ListenChar;
  end
  Priority(0);
  
  % End of experiment:
  return
  
catch ME
  % catch error: This is executed in case something goes wrong in the
  % 'try' part due to programming error etc.:
  
  fprintf('\nError during session %d. Exiting gracefully (saving experimentParams.mat).\n',expParam.sessionNum);
  
  % record the error date and time for this session
  errorDate = date;
  errorTime = fix(clock);
  expParam.session.(sesName).errorDate = errorDate;
  expParam.session.(sesName).errorTime = sprintf('%.2d:%.2d:%.2d',errorTime(4),errorTime(5),errorTime(6));
  
  % save the experiment info in its current state
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % close out the log file
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
  if ~ispc
    ListenChar;
  end
  Priority(0);
  
  % Output the error message that describes the error:
  psychrethrow(psychlasterror);
  
end % try ... catch


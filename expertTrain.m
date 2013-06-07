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

%% Experiment database struct preparation

expParam = struct;
cfg = struct;

% store the experiment name
expParam.expName = expName;

%% Set up the subject number and data

if isnumeric(subNum)
  % store the subject number
  expParam.subject = sprintf('%s%.3d',expParam.expName,subNum);
else
  fprintf('As subject number (variable: ''subNum''), you entered: ');
  disp(subNum);
  error('Subject number must be an integer (e.g., 9), not a string or anything else.');
end

% need to be in the experiment directory to run it. See if this function is
% in the current directory; if it is then we're in the right spot.
%if exist(fullfile(pwd,sprintf('%s.m',mfilename)),'file')
if exist(fullfile(pwd,sprintf('%s.m','expertTrain')),'file')
  cfg.files.expDir = pwd;
else
  error('Must be in the experiment directory to run the experiment.');
end

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
  logFile = fopen(cfg.files.sesLogFile,'w');
  
  %% Begin PTB display setup
  
  % Get screenNumber of stimulation display. We choose the display with
  % the maximum index, which is usually the right one, e.g., the external
  % display on a Laptop:
  screens = Screen('Screens');
  screenNumber = max(screens);
  
  % Hide the mouse cursor:
  HideCursor;
  
  % don't display keyboard output
  if ~ispc
    ListenChar(2);
  end
  
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
  
  % basic text size
  Screen('TextSize', w, cfg.text.basicTextSize);
  
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
    message = 'Experimenter:\nStart the Net Station application, apply the EEG cap, and check impedance measures...\n';
    DrawFormattedText(w, message, 'center', 'center', cfg.text.basicTextColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % wait until g key is held for ~1 seconds
    KbCheckHold(1000, {cfg.keys.expContinue}, -1);
    
    % connect
    [NSConnectStatus, NSConnectError] = NetStation('Connect', expParam.NSHost, expParam.NSPort);
    % synchronize
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize');
    % start recording
    [NSStartStatus, NSStartError] = NetStation('StartRecording');
    
    if NSConnectStatus || NSSyncStatus || NSStartStatus
      error('!!! ERROR: Problem with Netstation connect/sync/start. Check error messages for more information !!!');
    else
      fprintf('\nConnected to Netstation @ %s\n', expParam.NSHost);
      % stop recording
      [NSStopStatus, NSStopError] = NetStation('StopRecording');
    end
  end
  
  %% EEG baseline recording
  
  if expParam.useNS && expParam.baselineRecordSecs > 0
    Screen('TextSize', w, cfg.text.basicTextSize);
    %display instructions
    baselineMsg = sprintf('The experimenter will now record baseline activity\nPlease remain still...');
    DrawFormattedText(w, baselineMsg, 'center', 'center');
    Screen('Flip', w);
    
    % wait until g key is held for ~1 seconds
    KbCheckHold(1000, {cfg.keys.expContinue}, -1);
    
    % start recording
    Screen('TextSize', w, cfg.text.basicTextSize);
    [NSStartStatus, NSStartError] = NetStation('StartRecording');
    DrawFormattedText(w,'Starting EEG recording...', 'center', 'center');
    Screen('Flip', w);
    WaitSecs(5);
    
    [NSEventStatus, NSEventError] = NetStation('Event', 'REST', GetSecs, .001); % tag the start of the rest period
    
    % draw a countdown -- no need for super accurate timing here
    Screen('TextSize', w, cfg.text.basicTextSize);
    for sec = baselineRecordSecs:-1:1
      DrawFormattedText(w, num2str(sec), 'center', 'center');
      Screen('Flip', w);
      fprintf('%s ', num2str(sec));
      WaitSecs(1.0);
    end
    % stop recording
    [NSStopStatus, NSStopError] = NetStation('StopRecording');
  end
  
  %% Start Net Station recording for the experiment
  
  if expParam.useNS
    Screen('TextSize', w, cfg.text.basicTextSize);
    % start recording
    [NSStartStatus, NSStartError] = NetStation('StartRecording');
    DrawFormattedText(w,'Starting EEG recording...', 'center', 'center');
    Screen('Flip', w);
    WaitSecs(5);
  end
  
  %% Run through the experiment
  
  % find out what session this will be
  sesName = expParam.sesTypes{expParam.sessionNum};
  
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
        
        [logFile] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,matchCount);
        
      case {'name'}
        % Naming task
        nameCount = nameCount + 1;
        
        [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,nameCount);
        
      case {'recog'}
        % Recognition (old/new) task
        recogCount = recogCount + 1;
        
        [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,recogCount);

      case {'nametrain'}
        % Name training task
        nametrainCount = nametrainCount + 1;
        
        % for each view/name block
        for b = 1:length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder)
          [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,nametrainCount,b);
        end
        
      case {'viewname'}
        % Viewing task, with category response; intermixed with
        % Naming task
        viewnameCount = viewnameCount + 1;
        
        % for each view/name block
        for b = 1:length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder)
          % run the viewing task
          [logFile] = et_viewing(w,cfg,expParam,logFile,sesName,phaseName,viewnameCount,b);
          
          % then run the naming task
          [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,viewnameCount,b);
        end
        
      case{'prac_match'}
        % Subordinate Matching task (same/different)
        prac_matchCount = prac_matchCount + 1;
        
        [logFile] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,prac_matchCount);
        
      case {'prac_name'}
        % Naming task
        prac_nameCount = prac_nameCount + 1;
        
        [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,prac_nameCount);
        
      case {'prac_recog'}
        % Recognition (old/new) task
        prac_recogCount = prac_recogCount + 1;
        
        [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,prac_recogCount);

      otherwise
        warning('%s is not a configured phase in this session (%s)!\n',phaseName,sesName);
    end
  end
  
  %% Session is done
  
  fprintf('Done with session %d.\n',expParam.sessionNum);
  
  % increment the session number for next time
  expParam.sessionNum = expParam.sessionNum + 1;
  
  % save the experiment data
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % close out the log file
  fclose(logFile);
  
  % end of EEG recording, hang up with netstation
  if expParam.useNS
    % stop recording
    [NSStopStatus, NSStopError] = NetStation('StopRecording');
    fprintf('\nDisconnecting from Netstation @ %s\n', NSHost);
    [NSDisconnectStatus, NSDisconnectError] = NetStation('Disconnect');
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Finish Message  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  message = sprintf('Thank you, this session is complete.\n\nPlease wait for the experimenter.');
  Screen('TextSize', w, cfg.text.basicTextSize);
  % put the instructions on the screen
  DrawFormattedText(w, message, 'center', 'center');
  % Update the display to show the message:
  Screen('Flip', w);
  
  % wait until g key is held for ~1 seconds
  KbCheckHold(1000, {cfg.keys.expContinue}, -1);
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
  
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % close out the log file
  fclose(logFile);
  
  % end of EEG recording, hang up with netstation
  if expParam.useNS
    % stop recording
    [NSStopStatus, NSStopError] = NetStation('StopRecording');
    fprintf('\nDisconnecting from Netstation @ %s\n', NSHost);
    [NSDisconnectStatus, NSDisconnectError] = NetStation('Disconnect');
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


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
% see also: et_saveStimList, config_EBUG, process_EBUG_stimuli,
% et_matching, et_viewing, et_naming, et_recognition
%

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

% % debug
% cd('/Users/matt/Documents/experiments/expertTrain');
% expName = 'EBUG'; % expertise - creatures/shinebugs
% %expName = 'EBRD'; % expertise - birds
% subNum = 1;

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
% debug - commented out
% if exist(cfg.files.sesLogFile,'file')
%   error('Log file for this session already exists (%s). Resuming a session is not yet supported.',cfg.files.sesLogFile);
% end

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
  
  % TODO: set up logging for expertise experiment
  %fprintf(logFile,'\nDate\tSubjno\tTrial\tCategory_Label\tBird_image\tCondition\tResp\tAccuray\tRT\tAnswer\tObj_ID_Number\tLabel_img_match\tBird_Family\tStimuli_Set\tBlock\tCounterbalance\tCorr_RT\tCount_Hit\tCount_FA\tCount_CR\tCount_Miss');
  
  %% Begin PTB display setup
  
  % Get screenNumber of stimulation display. We choose the display with
  % the maximum index, which is usually the right one, e.g., the external
  % display on a Laptop:
  screens = Screen('Screens');
  screenNumber = max(screens);
  
  % Hide the mouse cursor:
  HideCursor;
  
  % Set up the gray color value to be used
  cfg.screen.gray = 181;
  %cfg.screen.gray = GrayIndex(screenNumber);
  
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
  Screen('TextSize', w, cfg.text.basic);
  
  % Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
  % they are loaded and ready when we need them - without delays
  % in the wrong moment:
  KbCheck;
  WaitSecs(0.1);
  GetSecs;
  
  % Set priority for script execution to realtime priority:
  priorityLevel = MaxPriority(w);
  Priority(priorityLevel);
  
  %% Run through the experiment
  
  % find out what session this will be
  sesName = expParam.sesTypes{expParam.sessionNum};
  
  % make sure this session type has been configured
  if ~isfield(expParam.session,sesName)
    error('%s is not a configured session type',sesName);
  end
  
  % for each phase in this session, run the correct function
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case {'practice'}
        % Practice session
        
        % TODO: not sure what they'll do for practice
        fprintf('Not sure what to do for practice\n');
        
      case {'viewname'}
        % (Passive) Viewing task, with category response; intermixed with
        % (Active) Naming task
        
        % for each view/name block
        for b = 1:length(cfg.stim.(sesName).(phaseName).blockSpeciesOrder)
          % run the viewing task
          [logFile] = et_viewing(w,cfg,expParam,logFile,sesName,phaseName,b);
          
          % then run the naming task
          [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,b);
        end
        
        % old
        %[cfg,logFile] = et_viewingNaming(cfg,expParam,logFile,sesName,phaseName);
        
      case {'name'}
        % (Active) Naming task
        
        [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName);
        
      case{'match'}
        % Subordinate Matching task (same/different)
        
        [logFile] = et_matching(w,cfg,expParam,logFile,sesName,phaseName);
        
      case {'recog'}
        % Recognition (old/new) task
        
        [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName);

      otherwise
        warning('%s is not a configured phase in this session (%s)!\n',phaseName,sesName);
    end
  end
  
  %% Session is done
  
  % increment the session number for next time
  expParam.sessionNum = expParam.sessionNum + 1;
  
  % save the experiment data
  save(cfg.files.expParamFile,'cfg','expParam');
  
  %   %% Practice Block (see corresponding m.file)
  %   blockPractice(practicefilename, w, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, practise_img,  ...
  %     timeout_img, txtsize_test, Res);
  %   %% Test Block 1 (see corresponding m.file)
  %   blockTest(testfilenameSetA1, w, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, dataFile, sdate, ...
  %     subNum, cbNum, test_img1, timeout_img, txtsize_test, ...
  %     corr_rt, Res, txtsize_takebreak);
  %   %% Test Block 2 (see corresponding m.file)
  %   blockTest(testfilenameSetA2, w, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, dataFile, sdate, ...
  %     subNum, cbNum, test_img2, timeout_img, txtsize_test, ...
  %     corr_rt, Res, txtsize_takebreak);
  %   %% Test Block 3 (see corresponding m.file)
  %   blockTest(testfilenameSetA3, w, spaceBar, sameresp, diffresp, ...
  %     fixdur, catdur, duration, nxt_trial_dur, blankdur, dataFile, sdate, ...
  %     subNum, cbNum, test_img3, timeout_img, txtsize_test, ...
  %     corr_rt, Res, txtsize_takebreak);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Finish Message  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  Screen('PutImage', w, final_img, [1, 1, cfg.screen.xy(1), cfg.screen.xy(2)]);
  Screen('Flip', w);
  
  touch = 0; % Detect spacebar press to continue
  while ~touch
    [touch,tpress,keycode] = KbCheck;
    % if it's the spacebar
    if keycode(cfg.keys.s00)
      break
    else
      touch = 0;
    end
  end
  while KbCheck; end
  
  FlushEvents('keyDown');
  touch = 0;
  Screen('Close');
  
  % Cleanup at end of experiment - Close window, show mouse cursor, close
  % result file, switch Matlab/Octave back to priority 0 -- normal
  % priority:
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
  
  fprintf('\n');
  
  % End of experiment:
  return
  
catch ME
  % catch error: This is executed in case something goes wrong in the
  % 'try' part due to programming error etc.:
  
  save(cfg.files.expParamFile,'cfg','expParam');
  
  % Do same cleanup as at the end of a regular session...
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
  
  fprintf('\n');
  
  % Output the error message that describes the error:
  psychrethrow(psychlasterror);
  
end % try ... catch


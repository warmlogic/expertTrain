function [cfg,expParam] = space_cued_recall_only(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = space_cued_recall_only(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
%
% Description:
%  This function runs the cued recall test task.
%
%  Intermixed test target and lure stimuli are stored in
%  expParam.session.(sesName).(phaseName)(phaseCount).testStims_img and
%  expParam.session.(sesName).(phaseName)(phaseCount).testStims_word.
%  Target+lure test stimuli must already be sorted in presentation order.
%
%
% Inputs:
%
%
% Outputs:
%
%
% NB:
%  Once agian, test targets+lures must already be sorted
%  in presentation order!
%
% NB:
%  Test response time is measured from when response key image appears on
%  screen.
%

% % durations, in seconds

fprintf('Running %s %s (cr) (%d)...\n',sesName,phaseName,phaseCount);

phaseNameForParticipant = 'test';

% whether to use GetChar (false) or GetKbChar (true)
%
% Linux, OS X, and Windows can use GetChar; I think Windows Vista and
% Windows 7 need to use GetKbChar, but I have not tested this
useKbCheck = false;

%% set the starting date and time for this phase

thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% determine the starting trial, useful for resuming

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_cro_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).testStims_img));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
else
  fprintf('All trials for %s %s (cr) (%d) have been completed. Moving on...\n',sesName,phaseName,phaseCount);
  % release any remaining textures
  Screen('Close');
  % go to the next block
  return
end

%% start the log file for this phase

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_cro_%d.txt',sesName,phaseName,phaseCount));
phLFile = fopen(phaseLogFile,'at');

%% record the starting date and time for this phase

expParam.session.(sesName).(phaseName)(phaseCount).date = thisDate;
expParam.session.(sesName).(phaseName)(phaseCount).startTime = startTime;

% put it in the log file
fprintf(logFile,'!!! Start of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);
fprintf(phLFile,'!!! Start of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);

thisGetSecs = GetSecs;
fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  phaseCount,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_START');

fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  phaseCount,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_START');

%% general preparation for recognition study and test

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
testStims_img = expParam.session.(sesName).(phaseName)(phaseCount).testStims_img;
testStims_word = expParam.session.(sesName).(phaseName)(phaseCount).testStims_word;

if phaseCfg.isExp
  imgStimDir = cfg.files.imgStimDir;
else
  imgStimDir = cfg.files.imgStimDir_prac;
end

% default is to preload the images
if ~isfield(cfg.stim,'preloadImages')
  cfg.stim.preloadImages = false;
end

% % read the proper old new response key image
% oldNewKeyImg = imread(cfg.files.recogTestOldNewRespKeyImg);
% oldNewKeyImgHeight = size(oldNewKeyImg,1) * cfg.files.respKeyImgScale;
% oldNewKeyImgWidth = size(oldNewKeyImg,2) * cfg.files.respKeyImgScale;
% oldNewKeyImg = Screen('MakeTexture',w,oldNewKeyImg);
% % read the proper sure maybe response key image
% sureMaybeKeyImg = imread(cfg.files.recogTestSureMaybeRespKeyImg);
% sureMaybeKeyImgHeight = size(sureMaybeKeyImg,1) * cfg.files.respKeyImgScale;
% sureMaybeKeyImgWidth = size(sureMaybeKeyImg,2) * cfg.files.respKeyImgScale;
% sureMaybeKeyImg = Screen('MakeTexture',w,sureMaybeKeyImg);
% 
% % set the old new response key image rectangle
% oldNewKeyImgRect = SetRect(0, 0, oldNewKeyImgWidth, oldNewKeyImgHeight);
% oldNewKeyImgRect = CenterRect(oldNewKeyImgRect, cfg.screen.wRect);
% oldNewKeyImgRect = AlignRect(oldNewKeyImgRect, cfg.screen.wRect, 'bottom', 'bottom');
% % set the sure maybe response key image rectangle
% sureMaybeKeyImgRect = SetRect(0, 0, sureMaybeKeyImgWidth, sureMaybeKeyImgHeight);
% sureMaybeKeyImgRect = CenterRect(sureMaybeKeyImgRect, cfg.screen.wRect);
% sureMaybeKeyImgRect = AlignRect(sureMaybeKeyImgRect, cfg.screen.wRect, 'bottom', 'bottom');

% default is to not print out trial details
if ~isfield(cfg.text,'printTrialInfo') || isempty(cfg.text.printTrialInfo)
  cfg.text.printTrialInfo = false;
end

% default is to not play sounds
if ~isfield(phaseCfg,'playSound') || isempty(phaseCfg.playSound)
  phaseCfg.playSound = false;
end
% initialize beep player if needed
if phaseCfg.playSound
  Beeper(1,0);
  if ~isfield(phaseCfg,'correctSound')
    phaseCfg.correctSound = 1000;
  end
  if ~isfield(phaseCfg,'incorrectSound')
    phaseCfg.incorrectSound = 300;
  end
  if ~isfield(phaseCfg,'correctVol')
    phaseCfg.correctVol = 0.4;
  end
  if ~isfield(phaseCfg,'incorrectVol')
    phaseCfg.incorrectVol = 0.6;
  end
end

% % are they allowed to respond while the stimulus is on the screen?
% if ~isfield(phaseCfg,'respDuringStim')
%   phaseCfg.respDuringStim = false;
% end

% default is to show fixation during ISI
if ~isfield(phaseCfg,'fixDuringISI')
  phaseCfg.fixDuringISI = true;
end
% default is to show fixation during preStim
if ~isfield(phaseCfg,'fixDuringPreStim')
  phaseCfg.fixDuringPreStim = true;
end
% default is to show fixation with the stimulus
if ~isfield(phaseCfg,'fixDuringStim')
  phaseCfg.fixDuringStim = true;
end

if ~isfield(phaseCfg,'impedanceAfter_nTrials')
  phaseCfg.impedanceAfter_nTrials = 0;
end

if ~isfield(phaseCfg,'showRespInBreak')
  phaseCfg.showRespInBreak = true;
end

% whether to ask the participant if they have any questions; only continues
% with experimenter's secret key
if ~isfield(phaseCfg.instruct,'questions')
  phaseCfg.instruct.questions = true;
end

% if expParam.photoCellTest
%   phaseCfg.impedanceBeforePhase = false;
%   phaseCfg.impedanceAfter_nTrials = 0;
%   phaseCfg.secUntilBlinkBreak = 0;
% end

%% set up text rectangles

% create a rectangle for placing fixation symbol using Screen('DrawText')
Screen('TextSize', w, cfg.text.fixSize);
fixRect = Screen('TextBounds', w, cfg.text.fixSymbol);
% center it in the middle of the screen
fixRect = CenterRect(fixRect, cfg.screen.wRect);
% get the X and Y coordinates
fixRectX = fixRect(1);
fixRectY = fixRect(2);

% create a rectangle for placing response symbol using Screen('DrawText')
Screen('TextSize', w, cfg.text.fixSize);
respRect = Screen('TextBounds', w, cfg.text.respSymbol);
% center it in the middle of the screen
respRect = CenterRect(respRect, cfg.screen.wRect);
% get the X and Y coordinates
respRectX = respRect(1);
respRectY = respRect(2);

%% Prepare the cued recall test task

stimImgRect_all = nan(length(testStims_img),4);
recallX_all = nan(length(testStims_img),1);
recallY_all = nan(length(testStims_img),1);
errorTextY_all = nan(length(testStims_img),1);

% initialize to hold all recallResponses
recallResp_all = {};
recallCounter = 0;
recallsInARowCounter = 0;

[~, screenCenterY] = RectCenter(cfg.screen.wRect);

% load up the stimuli for this block
testImgTex = nan(1,length(testStims_img));

message = sprintf('Preparing images, please wait...');
Screen('TextSize', w, cfg.text.basicTextSize);
% put the "preparing" message on the screen
DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
% Update the display to show the message:
Screen('Flip', w);

for i = 1:length(testStims_img)
  % make sure this stimulus exists
  stimImgFile = fullfile(imgStimDir,testStims_img(i).categoryStr,testStims_img(i).fileName);
  if exist(stimImgFile,'file')
    % load up this stim's texture
    stimImg = imread(stimImgFile);
    
    % resize the image, if necessary
    if size(stimImg,1) > cfg.stim.nRows
      stimImg = imresize(stimImg,[cfg.stim.nRows, NaN]);
    end
    % crop the image, if necessary
    if size(stimImg,2) > cfg.stim.cropWidth
      widthCenter = round(size(stimImg,2) / 2);
      stimImg = stimImg(:,(widthCenter - round(cfg.stim.cropWidth / 2)):(widthCenter + round(cfg.stim.cropWidth / 2)),:);
    end
    
    % set the coordinates that we will use later
    stimImgHeight = size(stimImg,1) * cfg.stim.stimScale;
    stimImgWidth = size(stimImg,2) * cfg.stim.stimScale;
    % set the stimulus image rectangle
    stimImgRect_all(i,:) = [0 0 stimImgWidth stimImgHeight];
    stimImgRect_all(i,:) = CenterRect(stimImgRect_all(i,:), cfg.screen.wRect);
    
    % put the recall text below the image
    Screen('TextSize', w, cfg.text.fixSize);
    recallRect = Screen('TextBounds', w, cfg.text.recallPrompt);
    recallRect = CenterRect(recallRect, cfg.screen.wRect);
    recallRect = AdjoinRect(recallRect, stimImgRect_all(i,:), RectBottom);
    recallX_all(i) = recallRect(1);
    recallY_all(i) = recallRect(2);
    %recallY_all(i) = screenCenterY + (stimImgHeight / 2);
    
    % text location for error (e.g., "too fast") or response text
    errorTextY_all(i) = screenCenterY + (stimImgHeight / 2);
    %responsePromptY_all(i) = screenCenterY + (stimImgHeight / 2);
    
    if cfg.stim.preloadImages
      testImgTex(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %testImgTex(i) = Screen('MakeTexture',w,stimImg,[],1);
      %elseif ~cfg.stim.preloadImages && i == length(testStims_img)
      % still need to load the last image to set the rectangle
      %  stimImg = imread(fullfile(imgStimDir,testStims_img(i).categoryStr,testStims_img(i).fileName));
    end
  else
    error('Test stimulus %s does not exist!',stimImgFile);
  end
end

%% do an impedance check before the phase begins, if desired

if ~isfield(phaseCfg,'impedanceBeforePhase')
  phaseCfg.impedanceBeforePhase = false;
end

if ~expParam.photoCellTest && expParam.useNS && phaseCfg.impedanceBeforePhase
  % run the impedance break
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  thisGetSecs = et_impedanceCheck(w, cfg, false, phaseName);
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
end

%% start NS recording, if desired

% put a message on the screen as experiment phase begins
message = sprintf('Starting %s phase...',phaseNameForParticipant);
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = sprintf('Starting data acquisition for %s phase...',phaseNameForParticipant);
  
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_START');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_START');
end
Screen('TextSize', w, cfg.text.basicTextSize);
% draw message to screen
DrawFormattedText(w, message, 'center', 'center', cfg.text.basicTextColor, cfg.text.instructCharWidth);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
% put it on
Screen('Flip', w);
% Wait before starting trial
WaitSecs(5.000);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
% Clear screen to background color (our 'bgColor' as set at the beginning):
Screen('Flip', w);

%% show the test instructions

if ~expParam.photoCellTest
  for i = 1:length(phaseCfg.instruct.cr)
    WaitSecs(1.000);
    et_showTextInstruct(w,cfg,phaseCfg.instruct.cr(i),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
  end
  % Wait a second before starting trial
  WaitSecs(1.000);
end

%% questions? only during practice. continues with experimenter's key.

if ~expParam.photoCellTest && ~phaseCfg.isExp && phaseCfg.instruct.questions
  questionsMsg.text = sprintf('If you have any questions about the %s phase,\nplease ask the experimenter now.\n\nPlease tell the experimenter when you are ready to begin the task.',phaseNameForParticipant);
  et_showTextInstruct(w,cfg,questionsMsg,cfg.keys.expContinue,...
    cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
  % Wait a second before continuing
  WaitSecs(1.000);
end

%% let them start when they're ready

if ~expParam.photoCellTest
  if phaseCfg.isExp
    expStr = '';
  else
    expStr = ' practice';
  end
  readyMsg.text = sprintf('Ready to begin%s %s phase.\nPress "%s" to start.',expStr,phaseNameForParticipant,cfg.keys.instructContKey);
  et_showTextInstruct(w,cfg,readyMsg,cfg.keys.instructContKey,...
    cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
  % Wait a second before starting trial
  WaitSecs(1.000);
end

%% Run cued recall test

% % only check these keys
% RestrictKeysForKbCheck([cfg.keys.recogOld, cfg.keys.recogNew, cfg.keys.newSure, cfg.keys.newMaybe]);

% start the blink break timer
if phaseCfg.isExp && phaseCfg.secUntilBlinkBreak > 0
  blinkTimerStart = GetSecs;
end

for i = trialNum:length(testStims_img)
  % do an impedance check after a certain number of trials
  if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(testStims_img) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
    % run the impedance break
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
    thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
    
%     RestrictKeysForKbCheck([cfg.keys.recogOld, cfg.keys.recogNew, cfg.keys.newSure, cfg.keys.newMaybe]);
    
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if (phaseCfg.cr_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.cr_isi == 0 && phaseCfg.fixDuringPreStim)
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip',w);
    WaitSecs(1.0);
    
    % reset the blink timer
    if phaseCfg.secUntilBlinkBreak > 0
      blinkTimerStart = GetSecs;
    end
  end
  
  % Do a blink break if specified time has passed
  if ~expParam.photoCellTest && phaseCfg.isExp && phaseCfg.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= phaseCfg.secUntilBlinkBreak && i > 3 && i < (length(testStims_img) - 3)
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    Screen('TextSize', w, cfg.text.basicTextSize);
    if expParam.useNS
      pauseMsg = 'Blink now.\n\n';
    else
      pauseMsg = '';
    end
    pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, length(testStims_img));
    
%     if phaseCfg.showRespInBreak
%       % draw response prompt, one on top of the other
%       Screen('DrawTexture', w, sureMaybeKeyImg, [], sureMaybeKeyImgRect);
%       
%       %Screen('DrawTexture', w, oldNewKeyImg, [], oldNewKeyImgRect);
%       Screen('DrawTexture', w, oldNewKeyImg, [], AdjoinRect(oldNewKeyImgRect,sureMaybeKeyImgRect,RectTop));
%     end
    
    % just draw straight into the main window since we don't need speed here
    DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    
    % listen for any keypress on any keyboard
    RestrictKeysForKbCheck([]);
    thisGetSecs = KbWait(-1,2);
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    % only check these keys
%     RestrictKeysForKbCheck([cfg.keys.recogOld, cfg.keys.recogNew, cfg.keys.newSure, cfg.keys.newMaybe]);
    
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if (phaseCfg.cr_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.cr_isi == 0 && phaseCfg.fixDuringPreStim)
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip',w);
    WaitSecs(1.0);
    
    % reset the timer
    blinkTimerStart = GetSecs;
  end
  
  % load the stimulus now if we didn't load it earlier
  if ~cfg.stim.preloadImages
    stimImg = imread(fullfile(imgStimDir,testStims_img(i).categoryStr,testStims_img(i).fileName));
    
    % resize the image, if necessary
    if size(stimImg,1) > cfg.stim.nRows
      stimImg = imresize(stimImg,[cfg.stim.nRows, NaN]);
    end
    % crop the image, if necessary
    if size(stimImg,2) > cfg.stim.cropWidth
      widthCenter = round(size(stimImg,2) / 2);
      stimImg = stimImg(:,(widthCenter - round(cfg.stim.cropWidth / 2)):(widthCenter + round(cfg.stim.cropWidth / 2)),:);
    end
    
    % create the texture
    testImgTex(i) = Screen('MakeTexture',w,stimImg);
  end
  
  % pull out the coordinates we need
  stimImgRect = stimImgRect_all(i,:);
  recallX = recallX_all(i);
  recallY = recallY_all(i);
  errorTextY = errorTextY_all(i);
  %responsePromptY = responsePromptY_all(i);
  
  % initialize
  test_preStimFixOn = nan;
  %test_imgOn = nan;
  % recognition
  % keyIsDown_recog = false;
  %recogEndRT = nan;
  %recogRespPromptOn = nan;
  %recogAcc = false;
  %recogRespKey = 'NO_RESPONSE_KEY';
  %recogResp = 'NO_RESPONSE';
  %recogResp_rt = int32(-1);
  % % new - sure/maybe response
  % keyIsDown_new = false;
  % newEndRT = nan;
  % newRespPromptOn = nan;
  % newAcc = false;
  % newRespKey = 'NO_RESPONSE_KEY';
  % newResp = 'NO_RESPONSE';
  % newResp_rt = int32(-1);
  % old - recall response
  madeRecallResp = false;
  recallEndRT = nan;
  recallRespPromptOn = nan;
  corrSpell = false;
  recallResp = 'NO_RESPONSE';
  recallResp_rt = int32(-1);
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.cr_isi > 0
    if phaseCfg.fixDuringISI
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
    end
    WaitSecs(phaseCfg.cr_isi);
  end
  
  % preStimulus period, with fixation if desired
  if length(phaseCfg.cr_preCueStim) == 1
    if phaseCfg.cr_preCueStim > 0
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [test_preStimFixOn] = Screen('Flip',w);
      else
        test_preStimFixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      WaitSecs(phaseCfg.cr_preCueStim);
    end
  elseif length(phaseCfg.cr_preCueStim) == 2
    if ~all(phaseCfg.cr_preCueStim == 0)
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [test_preStimFixOn] = Screen('Flip',w);
      else
        test_preStimFixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      % fixation on screen before stim for a random amount of time
      WaitSecs(phaseCfg.cr_preCueStim(1) + ((phaseCfg.cr_preCueStim(2) - phaseCfg.cr_preCueStim(1)).*rand(1,1)));
    end
  end
  
  % draw the stimulus
  Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
  if phaseCfg.fixDuringStim
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  end
  
  % photocell rect with stim
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
  end
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'test_imgOnset':
  [test_imgOn, test_imgOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d.\n',i,length(testStims_img),testStims_img(i).fileName,testStims_img(i).targ);
  end
  
  % while loop to show stimulus until "duration" seconds elapsed.
  while (GetSecs - test_imgOnset) <= phaseCfg.cr_cueStimOnly
%     % check for too-fast response
%     if ~phaseCfg.respDuringStim
%       [keyIsDown_recog] = KbCheck;
%       % if they press a key too early, tell them they responded too fast
%       if keyIsDown_recog
%         % draw the stimulus
%         Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
%         if phaseCfg.fixDuringStim
%           % and fixation on top of it
%           Screen('TextSize', w, cfg.text.fixSize);
%           Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
%           %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
%         end
%         % and the "too fast" text
%         Screen('TextSize', w, cfg.text.instructTextSize);
%         DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
%         % photocell rect with stim
%         if cfg.stim.photoCell
%           Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
%         end
%         Screen('Flip', w);
%         
%         keyIsDown_recog = 0;
%         break
%       end
%     else
%       [keyIsDown_recog, recogEndRT, keyCode] = KbCheck;
%       % if they push more than one key, don't accept it
%       if keyIsDown_recog && sum(keyCode) == 1
%         % wait for key to be released
%         while KbCheck(-1)
%           WaitSecs(0.0001);
%           
%           % % proceed if time is up, regardless of whether key is held
%           % if (GetSecs - recogRT) > phaseCfg.cr_recog_response
%           %   break
%           % end
%         end
%         % if cfg.text.printTrialInfo
%         %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - recogRT);
%         % end
%         if (keyCode(cfg.keys.recogOld) == 1 && all(keyCode(~cfg.keys.recogOld) == 0)) ||...
%             (keyCode(cfg.keys.recogNew) == 1 && all(keyCode(~cfg.keys.recogNew) == 0))
%           
%           recogRespPromptOn = nan;
%           break
%         end
%       elseif keyIsDown_recog && sum(keyCode) > 1
%         % draw the stimulus
%         Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
%         if phaseCfg.fixDuringStim
%           % and fixation on top of it
%           Screen('TextSize', w, cfg.text.fixSize);
%           Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
%           %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
%         end
%         % don't push multiple keys
%         Screen('TextSize', w, cfg.text.instructTextSize);
%         DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
%         % photocell rect with stim
%         if cfg.stim.photoCell
%           Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
%         end
%         % put them on the screen
%         Screen('Flip', w);
%         
%         keyIsDown_recog = 0;
%       end
%     end
    
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
%   % wait out any remaining time
%   while (GetSecs - test_imgOnset) <= phaseCfg.cr_cueStimOnly
%     % Wait <1 ms before checking the keyboard again to prevent
%     % overload of the machine at elevated Priority():
%     WaitSecs(0.0001);
%   end
%   
%   keyIsDown_recog = logical(keyIsDown_recog);
%   
%   if ~keyIsDown_recog
%     % draw the stimulus
%     Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
%     % draw response prompt
%     Screen('DrawTexture', w, oldNewKeyImg, [], oldNewKeyImgRect);
%     if phaseCfg.fixDuringStim
%       % and fixation on top of it
%       Screen('TextSize', w, cfg.text.fixSize);
%       Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
%       %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
%     end
%     
%     % photocell rect with stim
%     if cfg.stim.photoCell
%       Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
%     end
%     
%     % photocell rect with stim
%     if cfg.stim.photoCell
%       Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
%     end
%     % put them on the screen; measure RT from when response key img appears
%     [recogRespPromptOn, recogRespPromptStartRT] = Screen('Flip', w);
%     
%     % poll for a recogResp
%     while (GetSecs - recogRespPromptStartRT) <= phaseCfg.cr_recog_response
%       
%       [keyIsDown_recog, recogEndRT, keyCode] = KbCheck;
%       % if they push more than one key, don't accept it
%       if keyIsDown_recog && sum(keyCode) == 1
%         % wait for key to be released
%         while KbCheck(-1)
%           WaitSecs(0.0001);
%           
%           % % proceed if time is up, regardless of whether key is held
%           % if (GetSecs - recogRT(i)) > phaseCfg.cr_recog_response
%           %   break
%           % end
%         end
%         % if cfg.text.printTrialInfo
%         %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - recogRT);
%         % end
%         if (keyCode(cfg.keys.recogOld) == 1 && all(keyCode(~cfg.keys.recogOld) == 0)) ||...
%             (keyCode(cfg.keys.recogNew) == 1 && all(keyCode(~cfg.keys.recogNew) == 0))
%           break
%         end
%       elseif keyIsDown_recog && sum(keyCode) > 1
%         % draw the stimulus
%         Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
%         % draw response prompt
%         Screen('DrawTexture', w, oldNewKeyImg, [], oldNewKeyImgRect);
%         if phaseCfg.fixDuringStim
%           % and fixation on top of it
%           Screen('TextSize', w, cfg.text.fixSize);
%           Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
%           %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
%         end
%         % don't push multiple keys
%         Screen('TextSize', w, cfg.text.instructTextSize);
%         DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
%         
%         % photocell rect with stim
%         if cfg.stim.photoCell
%           Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
%         end
%         
%         % put them on the screen
%         Screen('Flip', w);
%         
%         keyIsDown_recog = 0;
%       end
%       % wait so we don't overload the system
%       WaitSecs(0.0001);
%     end
%     
%     keyIsDown_recog = logical(keyIsDown_recog);
%   end
%   
%   if ~keyIsDown_recog
%     if phaseCfg.playSound
%       Beeper(phaseCfg.incorrectSound,phaseCfg.incorrectVol);
%     end
%     
%     % "need to respond faster"
%     Screen('TextSize', w, cfg.text.instructTextSize);
%     DrawFormattedText(w,cfg.text.respondFaster,'center','center',cfg.text.respondFasterColor, cfg.text.instructCharWidth);
%     if cfg.stim.photoCell
%       Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
%     end
%     Screen('Flip', w);
%     
%     % need a new endRT
%     recogEndRT = GetSecs;
%     
%     % wait to let them view the feedback
%     WaitSecs(cfg.text.respondFasterFeedbackTime);
%   end
  
  % if this is an old image, get the word paired with it
  if testStims_img(i).targ
    thisWord = testStims_word([testStims_word.pairNum] == testStims_img(i).pairNum);
    if length(thisWord) == 1
      thisPairedWord = lower(thisWord.word);
      w_stimNum = int32(thisWord.stimNum);
    else
      error('Cannot have more than one word paired with an image');
    end
  else
    % otherwise leave it empty
    thisPairedWord = 'LURE_STIM';
    w_stimNum = int32(-1);
  end
  
%   if keyIsDown_recog && sum(keyCode) == 1
%     % get the key they pressed
%     recogRespKey = KbName(keyCode);
%     
%     if (keyCode(cfg.keys.recogOld) == 1 && all(keyCode(~cfg.keys.recogOld) == 0))
%       recogResp = 'old';
      
      % if they answer 'old', get their answer and type it to the screen
      dispRecallResp = cfg.text.recallPrompt;
      recallStr = '';
      if ~useKbCheck
        % Flush the keyboard buffer:
        FlushEvents;
      end
      
      % initialize
      typedRecallStr = false;
      
      if phaseCfg.cr_corrSpell && phaseCfg.cr_nAttempts > 0
        attemptCounter = 0;
      end
      
      % draw the stimulus
      Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
      if phaseCfg.fixDuringStim
        % and response symbol on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      % draw the recall resonse prompt
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, sprintf('%s',dispRecallResp), recallX, recallY, cfg.text.basicTextColor);
      
      % photocell rect and stim
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
      end
      [recallRespPromptOn, recallRespPromptStartRT] = Screen('Flip', w);
      
      while ~typedRecallStr
        while true
          %while (GetSecs - probOnset) <= phaseCfg.dist_response
          
          % reimplementing GetEchoString to get RT
          if useKbCheck
            [char, GetCharEndRT] = GetKbChar; %#ok<UNRCH>
          else
            [char, GetCharEndRT] = GetChar;
          end
          if isempty(char)
            return
          else
            % get the time the key was pressed using GetSecs
            respMadeRT = GetSecs;
          end
          
          switch (abs(char))
            case {13, 3, 10}
              % ctrl-C, enter, or return
              break
            case {8}
              % 8 = backspace
              
              if ~isempty(recallStr)
                recallStr = recallStr(1:length(recallStr)-1);
              end
              if ~isempty(recallStr)
                dispRecallResp = recallStr;
              else
                dispRecallResp = cfg.text.recallPrompt;
              end
            otherwise
              if ismember(char, cfg.keys.recallKeyNames)
                recallStr = [recallStr, char]; %#ok<AGROW>
              end
              if ~isempty(recallStr)
                dispRecallResp = recallStr;
              else
                dispRecallResp = cfg.text.recallPrompt;
              end
          end
          
          % draw the stimulus
          Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
          if phaseCfg.fixDuringStim
            % and response symbol on top of it
            Screen('TextSize', w, cfg.text.fixSize);
            Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
            %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % draw their text
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, sprintf('%s',dispRecallResp), recallX, recallY, cfg.text.basicTextColor);
          % photocell rect and stim
          if cfg.stim.photoCell
            Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
          end
          %[respMadeRT] = Screen('Flip', w);
          Screen('Flip', w);
          
          WaitSecs(0.0001);
        end
        
        if testStims_img(i).targ
          % if it's a targ stim, see if they needed the correct spelling
          if phaseCfg.cr_corrSpell
            attemptCounter = attemptCounter + 1;
            
            if strcmpi(recallStr,thisPairedWord)
              corrSpell = true;
              typedRecallStr = true;
              %break
            else
              corrSpell = false;
              if attemptCounter >= phaseCfg.cr_nAttempts
                typedRecallStr = true;
                %break
              end
            end
          else
            % if we're not checking spelling then set correct=true if they
            % made some kind of response
            if ~isempty(recallStr)
              corrSpell = true;
            end
            typedRecallStr = true;
            %break
          end
        else
          % this was a lure image and they're making a response
          corrSpell = false;
          typedRecallStr = true;
        end
      end
      
      % get the time they pressed return
      recallEndRT = respMadeRT;
      % only need the seconds, only for when using GetChar
      % recallEndRT = endRT.secs;
      
      % collect their response and make sure they're behaving appropriately
      if ~isempty(recallStr)
        recallResp = recallStr;
        recallResp_all = cat(1,recallResp_all,recallResp);
        madeRecallResp = true;
        
        % see if they're behaving badly (making the same response over and
        % over)
        recallCounter = recallCounter + 1;
        if recallCounter > 1
          if strcmpi(recallResp,recallResp_all(recallCounter-1))
            % they made the same response as last time
            recallsInARowCounter = recallsInARowCounter + 1;
          else
            recallsInARowCounter = 0;
          end
          
          if length(recallResp_all) > 2 && recallsInARowCounter >= 3
            % if they've made the same response more than 3 times in a row
            
            %if phaseCfg.playSound
            %  % play a loud angry beep
            %  Beeper(440, 0.9, 3);
            %end
            
            % tell them that they're not responding correctly
            tooManyInARowText1 = sprintf('It seems that you are not doing the task correctly.\n\nYou have made the response "%s" many times in a row.',recallResp);
            tooManyInARowText2 = sprintf('\n\nPlease talk to the experimenter now.\n\nPress "%s" when you know how to do the task correctly.',cfg.keys.instructContKey);
            
            Screen('TextSize', w, cfg.text.instructTextSize);
            DrawFormattedText(w,sprintf('%s%s',tooManyInARowText1,tooManyInARowText2),'center','center',cfg.text.instructColor, cfg.text.instructCharWidth);
            if cfg.stim.photoCell
              Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
            end
            Screen('Flip', w);
            
            fprintf(logFile,'!!! Same response too many times in a row\n');
            fprintf(phLFile,'!!! Same response too many times in a row\n');
            
            % wait until the key is pressed
            RestrictKeysForKbCheck(KbName(cfg.keys.instructContKey));
            KbWait(-1,2);
            RestrictKeysForKbCheck([]);
%             RestrictKeysForKbCheck([cfg.keys.recogOld, cfg.keys.recogNew, cfg.keys.newSure, cfg.keys.newMaybe]);
            
            % show preparation text
            DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
            if cfg.stim.photoCell
              Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
            end
            Screen('Flip', w);
            WaitSecs(2.0);
            
          elseif phaseCfg.isExp && length(recallResp_all) > 4 && sum(strcmpi(recallResp_all,recallResp)) / length(recallResp_all) >= (1/3)
            % if they've made the same response for >= 33% of the responses
            
            %if phaseCfg.playSound
            %  % play a loud angry beep
            %  Beeper(440, 0.9, 3);
            %end
            
            % tell them that they're not responding correctly
            tooManySameText1 = sprintf('You have made the response "%s" many times.\nIf you are trying to show that you do not remember a word, you should simply press Return when you see "%s".',recallResp,cfg.text.recallPrompt);
            tooManySameText2 = sprintf('\n\nOr, if you do not understand how to do the task, please talk to the experimenter now.\n\nPress "%s" when you know how to do the task correctly.',cfg.keys.instructContKey);
            
            Screen('TextSize', w, cfg.text.instructTextSize);
            DrawFormattedText(w,sprintf('%s%s',tooManySameText1,tooManySameText2),'center','center',cfg.text.instructColor, cfg.text.instructCharWidth);
            if cfg.stim.photoCell
              Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
            end
            Screen('Flip', w);
            
            fprintf(logFile,'!!! Same response too many times overall\n');
            fprintf(phLFile,'!!! Same response too many times overall\n');
            
            % wait until the key is pressed
            RestrictKeysForKbCheck(KbName(cfg.keys.instructContKey));
            KbWait(-1,2);
%             RestrictKeysForKbCheck([cfg.keys.recogOld, cfg.keys.recogNew, cfg.keys.newSure, cfg.keys.newMaybe]);
            RestrictKeysForKbCheck([]);
            
            % show preparation text
            DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
            if cfg.stim.photoCell
              Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
            end
            Screen('Flip', w);
            WaitSecs(2.0);
          end
        end
      end
      
%     elseif (keyCode(cfg.keys.recogNew) == 1 && all(keyCode(~cfg.keys.recogNew) == 0))
%       recogResp = 'new';
%       % elseif they answer 'new', ask 'sure' vs 'maybe'
%       
%       % draw the stimulus
%       Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
%       % draw response prompt
%       Screen('DrawTexture', w, sureMaybeKeyImg, [], sureMaybeKeyImgRect);
%       if phaseCfg.fixDuringStim
%         % and fixation on top of it
%         Screen('TextSize', w, cfg.text.fixSize);
%         Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
%         %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
%       end
%       % photocell rect and stim
%       if cfg.stim.photoCell
%         Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
%       end
%       % put them on the screen; measure RT from when response key img appears
%       [newRespPromptOn, newRespPromptStartRT] = Screen('Flip', w);
%       
%       % poll for a newResp
%       while (GetSecs - newRespPromptStartRT) <= phaseCfg.cr_new_response
%         
%         [keyIsDown_new, newEndRT, keyCode] = KbCheck;
%         % if they push more than one key, don't accept it
%         if keyIsDown_new && sum(keyCode) == 1
%           % wait for key to be released
%           while KbCheck(-1)
%             WaitSecs(0.0001);
%             
%             % % proceed if time is up, regardless of whether key is held
%             % if (GetSecs - recogRT(i)) > phaseCfg.cr_recog_response
%             %   break
%             % end
%           end
%           % if cfg.text.printTrialInfo
%           %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - recogRT);
%           % end
%           if (keyCode(cfg.keys.newSure) == 1 && all(keyCode(~cfg.keys.newSure) == 0)) ||...
%               (keyCode(cfg.keys.newMaybe) == 1 && all(keyCode(~cfg.keys.newMaybe) == 0))
%             break
%           end
%         elseif keyIsDown_new && sum(keyCode) > 1
%           % draw the stimulus
%           Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
%           % draw response prompt
%           Screen('DrawTexture', w, sureMaybeKeyImg, [], sureMaybeKeyImgRect);
%           if phaseCfg.fixDuringStim
%             % and fixation on top of it
%             Screen('TextSize', w, cfg.text.fixSize);
%             Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
%             %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
%           end
%           % don't push multiple keys
%           Screen('TextSize', w, cfg.text.instructTextSize);
%           DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
%           % photocell rect and stim
%           if cfg.stim.photoCell
%             Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
%           end
%           % put them on the screen
%           Screen('Flip', w);
%           
%           keyIsDown_new = 0;
%         end
%         % wait so we don't overload the system
%         WaitSecs(0.0001);
%       end
%       
%       keyIsDown_new = logical(keyIsDown_new);
%       
%       if ~keyIsDown_new
%         if phaseCfg.playSound
%           Beeper(phaseCfg.incorrectSound,phaseCfg.incorrectVol);
%         end
%         
%         % "need to respond faster"
%         Screen('TextSize', w, cfg.text.instructTextSize);
%         DrawFormattedText(w,cfg.text.respondFaster,'center','center',cfg.text.respondFasterColor, cfg.text.instructCharWidth);
%         if cfg.stim.photoCell
%           Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
%         end
%         Screen('Flip', w);
%         
%         % need a new endRT
%         newEndRT = GetSecs;
%         
%         % wait to let them view the feedback
%         WaitSecs(cfg.text.respondFasterFeedbackTime);
%       end
%       
%       if keyIsDown_new && sum(keyCode) == 1
%         % get the key they pressed
%         newRespKey = KbName(keyCode);
%         
%         if (keyCode(cfg.keys.newSure) == 1 && all(keyCode(~cfg.keys.newSure) == 0))
%           newResp = 'sure';
%         elseif (keyCode(cfg.keys.newMaybe) == 1 && all(keyCode(~cfg.keys.newMaybe) == 0))
%           newResp = 'maybe';
%         elseif keyCode(cfg.keys.newSure) == 0 && keyCode(cfg.keys.newMaybe) == 0
%           warning('Key other than a new response key was pressed. This should not happen.\n');
%           newResp = 'ERROR_OTHERKEY';
%         else
%           warning('Some other error occurred.\n');
%           newResp = 'ERROR_OTHER';
%         end
%       elseif keyIsDown_new && sum(keyCode) > 1
%         warning('Multiple keys were pressed.\n');
%         newAcc = false;
%         % get the keys they pressed
%         thisNewRespKey = KbName(keyCode);
%         newRespKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisNewRespKey)),thisNewRespKey{:}));
%         newResp = 'ERROR_MULTIKEY';
%       end
%       
%     elseif keyCode(cfg.keys.recogOld) == 0 && keyCode(cfg.keys.recogNew) == 0
%       warning('Key other than a recognition response key was pressed. This should not happen.\n');
%       recogAcc = false;
%       recogResp = 'ERROR_OTHERKEY';
%     else
%       warning('Some other error occurred.\n');
%       recogAcc = false;
%       recogResp = 'ERROR_OTHER';
%     end
%   elseif keyIsDown_recog && sum(keyCode) > 1
%     warning('Multiple keys were pressed.\n');
%     recogAcc = false;
%     % get the keys they pressed
%     thisRecogRespKey = KbName(keyCode);
%     recogRespKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisRecogRespKey)),thisRecogRespKey{:}));
%     recogResp = 'ERROR_MULTIKEY';
%   end
  
  if (phaseCfg.cr_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.cr_isi == 0 && phaseCfg.fixDuringPreStim)
    % draw fixation after response
    Screen('TextSize', w, cfg.text.fixSize);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  end
  
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % clear screen
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', testImgTex(i));
  
%   % compute old/new recognition response time
%   if phaseCfg.respDuringStim
%     measureRTfromHere = test_imgOnset;
%   else
%     measureRTfromHere = recogRespPromptStartRT;
%   end
%   recogResp_rt = int32(round(1000 * (recogEndRT - measureRTfromHere)));
  
  % compute accuracies and response times
%   if keyIsDown_recog
%     % compute response times and accuracy
%     if strcmp(recogResp,'old')
%       % compute accuracy
%       if testStims_img(i).targ
%         % hit
%         recogAcc = true;
%       elseif ~testStims_img(i).targ
%         % miss
%         recogAcc = false;
%       end
      
      % % there will always be a recallEndRT, so does not need to be
      % % conditional
      recallResp_rt = int32(round(1000 * (recallEndRT - recallRespPromptStartRT)));
      
%     elseif strcmp(recogResp,'new')
%       % compute accuracy
%       if testStims_img(i).targ
%         % false alarm
%         recogAcc = false;
%         newAcc = false;
%       elseif ~testStims_img(i).targ
%         % correct rejection
%         recogAcc = true;
%         newAcc = true;
%       end
%       
%       %if keyIsDown_new
%       % compute sure/maybe response time
%       newResp_rt = int32(round(1000 * (newEndRT - newRespPromptStartRT)));
%       %end
%     else
%       fprintf('recogResp was ''%s'' instead of ''old'' or ''new''. Something is wrong!\n',recogResp);
%     end
%   end
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d.\n',...
      i,length(testStims_img),testStims_img(i).fileName,testStims_img(i).targ);
    fprintf('\trecallResponse: %s (origWord = %s; spelled correctly = %d; rt = %d)\n',recallResp,thisPairedWord,corrSpell,recallResp_rt);
  end
  
  % img stimulus properties
  i_catNum = int32(testStims_img(i).categoryNum);
  i_stimNum = int32(testStims_img(i).stimNum);
  i_pairNum = int32(testStims_img(i).pairNum);
  % both stimuli
  targStatus = testStims_img(i).targ;
  spacStatus = testStims_img(i).spaced;
  studyLag = int32(testStims_img(i).lag);
  
  %% session log file
  
  % Write test stimulus presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
    test_imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'TEST_STIM',...
    i,...
    testStims_img(i).fileName,...
    i_stimNum,...
    targStatus,...
    spacStatus,...
    studyLag,...
    i_pairNum,...
    testStims_img(i).categoryStr,...
    i_catNum);
  
%   if ~isnan(recogRespPromptOn)
%     % Write test key image presentation to file:
%     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
%       recogRespPromptOn,...
%       expParam.subject,...
%       sesName,...
%       phaseName,...
%       phaseCount,...
%       phaseCfg.isExp,...
%       'RECOGTEST_RECOGRESPPROMPT',...
%       i,...
%       testStims_img(i).fileName,...
%       i_stimNum,...
%       targStatus,...
%       spacStatus,...
%       studyLag,...
%       i_pairNum,...
%       testStims_img(i).categoryStr,...
%       i_catNum);
%   end
  
%   % Write trial result to file:
%   fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
%     recogEndRT,...
%     expParam.subject,...
%     sesName,...
%     phaseName,...
%     phaseCount,...
%     phaseCfg.isExp,...
%     'RECOGTEST_RECOGRESP',...
%     i,...
%     testStims_img(i).fileName,...
%     i_stimNum,...
%     targStatus,...
%     spacStatus,...
%     studyLag,...
%     i_pairNum,...
%     testStims_img(i).categoryStr,...
%     i_catNum,...
%     recogResp,...
%     recogRespKey,...
%     recogAcc,...
%     recogResp_rt);
  
%   if ~isnan(newRespPromptOn)
%     % Write test key image presentation to file:
%     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
%       newRespPromptOn,...
%       expParam.subject,...
%       sesName,...
%       phaseName,...
%       phaseCount,...
%       phaseCfg.isExp,...
%       'RECOGTEST_NEWRESPPROMPT',...
%       i,...
%       testStims_img(i).fileName,...
%       i_stimNum,...
%       targStatus,...
%       spacStatus,...
%       studyLag,...
%       i_pairNum,...
%       testStims_img(i).categoryStr,...
%       i_catNum);
%     
%     % Write trial result to file:
%     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
%       newEndRT,...
%       expParam.subject,...
%       sesName,...
%       phaseName,...
%       phaseCount,...
%       phaseCfg.isExp,...
%       'RECOGTEST_NEWRESP',...
%       i,...
%       testStims_img(i).fileName,...
%       i_stimNum,...
%       targStatus,...
%       spacStatus,...
%       studyLag,...
%       i_pairNum,...
%       testStims_img(i).categoryStr,...
%       i_catNum,...
%       newResp,...
%       newRespKey,...
%       newAcc,...
%       newResp_rt);
%   end
  
%   if ~isnan(recallRespPromptOn)
    % Write test key image presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      recallRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'TEST_RECALLRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      i_stimNum,...
      targStatus,...
      spacStatus,...
      studyLag,...
      i_pairNum,...
      testStims_img(i).categoryStr,...
      i_catNum);
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\n',...
      recallEndRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'TEST_RECALLRESP',...
      i,...
      testStims_img(i).fileName,...
      i_stimNum,...
      targStatus,...
      spacStatus,...
      studyLag,...
      i_pairNum,...
      testStims_img(i).categoryStr,...
      i_catNum,...
      recallResp,...
      thisPairedWord,...
      w_stimNum,...
      corrSpell,...
      recallResp_rt);
%   end
  
  %% phase log file
  
  % Write test stimulus presentation to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
    test_imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'TEST_STIM',...
    i,...
    testStims_img(i).fileName,...
    i_stimNum,...
    targStatus,...
    spacStatus,...
    studyLag,...
    i_pairNum,...
    testStims_img(i).categoryStr,...
    i_catNum);
  
%   if ~isnan(recogRespPromptOn)
%     % Write test key image presentation to file:
%     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
%       recogRespPromptOn,...
%       expParam.subject,...
%       sesName,...
%       phaseName,...
%       phaseCount,...
%       phaseCfg.isExp,...
%       'RECOGTEST_RECOGRESPPROMPT',...
%       i,...
%       testStims_img(i).fileName,...
%       i_stimNum,...
%       targStatus,...
%       spacStatus,...
%       studyLag,...
%       i_pairNum,...
%       testStims_img(i).categoryStr,...
%       i_catNum);
%   end
%   
%   % Write trial result to file:
%   fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
%     recogEndRT,...
%     expParam.subject,...
%     sesName,...
%     phaseName,...
%     phaseCount,...
%     phaseCfg.isExp,...
%     'RECOGTEST_RECOGRESP',...
%     i,...
%     testStims_img(i).fileName,...
%     i_stimNum,...
%     targStatus,...
%     spacStatus,...
%     studyLag,...
%     i_pairNum,...
%     testStims_img(i).categoryStr,...
%     i_catNum,...
%     recogResp,...
%     recogRespKey,...
%     recogAcc,...
%     recogResp_rt);
%   
%   if ~isnan(newRespPromptOn)
%     % Write test key image presentation to file:
%     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
%       newRespPromptOn,...
%       expParam.subject,...
%       sesName,...
%       phaseName,...
%       phaseCount,...
%       phaseCfg.isExp,...
%       'RECOGTEST_NEWRESPPROMPT',...
%       i,...
%       testStims_img(i).fileName,...
%       i_stimNum,...
%       targStatus,...
%       spacStatus,...
%       studyLag,...
%       i_pairNum,...
%       testStims_img(i).categoryStr,...
%       i_catNum);
%     
%     % Write trial result to file:
%     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
%       newEndRT,...
%       expParam.subject,...
%       sesName,...
%       phaseName,...
%       phaseCount,...
%       phaseCfg.isExp,...
%       'RECOGTEST_NEWRESP',...
%       i,...
%       testStims_img(i).fileName,...
%       i_stimNum,...
%       targStatus,...
%       spacStatus,...
%       studyLag,...
%       i_pairNum,...
%       testStims_img(i).categoryStr,...
%       i_catNum,...
%       newResp,...
%       newRespKey,...
%       newAcc,...
%       newResp_rt);
%   end
  
%   if ~isnan(recallRespPromptOn)
    % Write test key image presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      recallRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'TEST_RECALLRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      i_stimNum,...
      targStatus,...
      spacStatus,...
      studyLag,...
      i_pairNum,...
      testStims_img(i).categoryStr,...
      i_catNum);
    
    % Write trial result to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\n',...
      recallEndRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'TEST_RECALLRESP',...
      i,...
      testStims_img(i).fileName,...
      i_stimNum,...
      targStatus,...
      spacStatus,...
      studyLag,...
      i_pairNum,...
      testStims_img(i).categoryStr,...
      i_catNum,...
      recallResp,...
      thisPairedWord,...
      w_stimNum,...
      corrSpell,...
      recallResp_rt);
%   end
  
  %% Write netstation logs
  
  if expParam.useNS
    % Write trial info to et_NetStation
    % mark every event with the following key code/value pairs
    % 'subn', subject number
    % 'sess', session type
    % 'phas', session phase name
    % 'pcou', phase count
    % 'expt', whether this is the experiment (1) or practice (0)
    % 'type', type of trial (recognition, recall, new)
    % 'trln', trial number
    % 'istm', image stimulus name
    % 'inum', image stimulus number
    % 'icts', image category string
    % 'ictn', image category number
    % 'targ', whether this is a target (1) or a lure (0)
    % 'spac', whether it was spaced (1) or not (0; massed or single pres)
    % 'slag', the spacing lag (>0=spaced, 0=massed, -1=single pres)
    % 'pnum', the pair number, for keeping image and word stimuli together
    % 'wstm', original paired word
    % 'wnum', paired word number
    
%     % recognition = rg
%     % 'rgrs', response string
%     % 'rgke', the name of the key pressed
%     % 'rgrt', the response time
%     % 'rgac', accuracy code (1=correct, 0=incorrect)
%     % 'rgkp', key pressed?(1=yes, 0=no)
    
    % recall = rc
    % 'rcrs', response string
    % 'rcrt', the response time
    % 'rcac', accuracy of spelling (1=correct, 0=incorrect)
    % 'rckp', key pressed?(1=yes, 0=no)
    
%     % new = nw
%     % 'nwrs', response string
%     % 'nwke', the name of the key pressed
%     % 'nwrt', the response time
%     % 'nwac', accuracy code (1=correct, 0=incorrect)
%     % 'nwkp', key pressed?(1=yes, 0=no)
    
    if ~isnan(test_preStimFixOn)
      % prestimulus fixation
      [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', test_preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'type', 'recognition', 'trln', int32(i),...
        'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
        'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
        'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
        'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp); %#ok<NASGU,ASGLU>
    end
    
    % img presentation
    [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', test_imgOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
      'expt',phaseCfg.isExp, 'type', 'recognition', 'trln', int32(i),...
      'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
      'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
      'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
      'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp); %#ok<NASGU,ASGLU>
    
%     if ~isnan(recogRespPromptOn)
%       % recognition response prompt
%       [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', recogRespPromptOn, .001,...
%         'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
%         'expt',phaseCfg.isExp, 'type', 'recognition', 'trln', int32(i),...
%         'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
%         'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
%         'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
%         'rgrs', recogResp, 'rgrt', recogResp_rt, 'rgac', recogAcc, 'rgkp', keyIsDown_recog,...
%         'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp,...
%         'nwrs', newResp, 'nwke', newRespKey, 'nwrt', newResp_rt, 'nwac', newAcc, 'nwkp', keyIsDown_new); %#ok<NASGU,ASGLU>
%     end
    
%     % did they make a recognition response?
%     if keyIsDown_recog
%       % button push
%       [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', recogEndRT, .001,...
%         'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
%         'expt',phaseCfg.isExp, 'type', 'recognition', 'trln', int32(i),...
%         'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
%         'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
%         'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
%         'rgrs', recogResp, 'rgrt', recogResp_rt, 'rgac', recogAcc, 'rgkp', keyIsDown_recog,...
%         'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp,...
%         'nwrs', newResp, 'nwke', newRespKey, 'nwrt', newResp_rt, 'nwac', newAcc, 'nwkp', keyIsDown_new); %#ok<NASGU,ASGLU>
%     end
    
%     if ~isnan(newRespPromptOn)
%       % new response prompt
%       [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', newRespPromptOn, .001,...
%         'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
%         'expt',phaseCfg.isExp, 'type', 'new', 'trln', int32(i),...
%         'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
%         'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
%         'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
%         'rgrs', recogResp, 'rgrt', recogResp_rt, 'rgac', recogAcc, 'rgkp', keyIsDown_recog,...
%         'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp,...
%         'nwrs', newResp, 'nwke', newRespKey, 'nwrt', newResp_rt, 'nwac', newAcc, 'nwkp', keyIsDown_new); %#ok<NASGU,ASGLU>
%       
%       % did they make a new response?
%       if keyIsDown_new
%         % button push
%         [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', newEndRT, .001,...
%           'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
%           'expt',phaseCfg.isExp, 'type', 'new', 'trln', int32(i),...
%           'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
%           'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
%           'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
%           'rgrs', recogResp, 'rgrt', recogResp_rt, 'rgac', recogAcc, 'rgkp', keyIsDown_recog,...
%           'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp,...
%           'nwrs', newResp, 'nwke', newRespKey, 'nwrt', newResp_rt, 'nwac', newAcc, 'nwkp', keyIsDown_new); %#ok<NASGU,ASGLU>
%       end
%     end
    
%     if ~isnan(recallRespPromptOn)
      % recall response prompt
      [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', recallRespPromptOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'type', 'recall', 'trln', int32(i),...
        'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
        'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
        'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
        'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp); %#ok<NASGU,ASGLU>
      
      % did they make a recall response?
      %
      % they have to push a button, so log it regardless of whether they
      % actually made a response
      [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', recallEndRT, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'type', 'recall', 'trln', int32(i),...
        'istm', testStims_img(i).fileName, 'inum', i_stimNum, 'icts', testStims_img(i).categoryStr, 'ictn', i_catNum,...
        'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
        'pnum', i_pairNum,'wstm', thisPairedWord, 'wnum', w_stimNum,...
        'rcrs', recallResp, 'rcrt', recallResp_rt, 'rcac', corrSpell, 'rckp', madeRecallResp); %#ok<NASGU,ASGLU>
%     end
    
  end % useNS
  
  % mark that we finished this trial
  trialComplete(i) = true;
  % save progress after each trial
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end % for stimuli

%% print "continue" screen

WaitSecs(2.0);

messageText = sprintf('You have finished the %s phase.\n\nPress "%s" to continue.',...
  phaseNameForParticipant,cfg.keys.instructContKey);
Screen('TextSize', w, cfg.text.instructTextSize);
DrawFormattedText(w,messageText,'center','center',cfg.text.instructColor, cfg.text.instructCharWidth);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
Screen('Flip', w);

if ~expParam.photoCellTest
  % wait until the key is pressed
  RestrictKeysForKbCheck(KbName(cfg.keys.instructContKey));
  KbWait(-1,2);
end
RestrictKeysForKbCheck([]);

if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
% go back to background color
Screen('Flip', w);

%% cleanup

% stop recording
if expParam.useNS
  WaitSecs(5.0);
  [NSSyncStatus, NSSyncError] = NetStation('StopRecording'); %#ok<NASGU,ASGLU>
  
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_STOP');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_STOP');
end

% reset the KbCheck
RestrictKeysForKbCheck([]);

% release any remaining textures, including the response key image
Screen('Close');

thisGetSecs = GetSecs;
fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  phaseCount,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_END');

fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  phaseCount,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_END');

% record the end time for this session
endTime = fix(clock);
endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6));
expParam.session.(sesName).(phaseName)(phaseCount).endTime = endTime;
% put it in the log file
fprintf(logFile,'!!! End of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);
fprintf(phLFile,'!!! End of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);

% close the phase log file
fclose(phLFile);

% save progress after finishing phase
phaseComplete = true; %#ok<NASGU>
save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');

%% print "continue into real experiment" screen

if ~phaseCfg.isExp
  WaitSecs(2.0);
  
  messageText = sprintf('You have now finished the practice phases.\n\nPlease let the experimenter know if you have any questions.\n\nPress "%s" to begin the real experiment.',...
    cfg.keys.instructContKey);
  Screen('TextSize', w, cfg.text.instructTextSize);
  DrawFormattedText(w,messageText,'center','center',cfg.text.instructColor, cfg.text.instructCharWidth);
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  Screen('Flip', w);
  
  if ~expParam.photoCellTest
    % wait until the key is pressed
    RestrictKeysForKbCheck(KbName(cfg.keys.instructContKey));
    KbWait(-1,2);
  end
  RestrictKeysForKbCheck([]);
  
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % go back to background color
  Screen('Flip', w);
end

end % function

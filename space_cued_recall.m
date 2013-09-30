function [cfg,expParam] = space_cued_recall(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = space_cued_recall(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
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
% cfg.stim.(sesName).(phaseName).cr_study_isi = 0.8;
% cfg.stim.(sesName).(phaseName).cr_study_preTarg = 0.2;
% cfg.stim.(sesName).(phaseName).cr_study_targ = 2.0;
% cfg.stim.(sesName).(phaseName).cr_isi = 0.8;
% cfg.stim.(sesName).(phaseName).cr_preCueStim = 0.2;
% cfg.stim.(sesName).(phaseName).cr_test_stim = 1.5;
% cfg.stim.(sesName).(phaseName).cr_response = 10.0;

fprintf('Running %s %s (cr) (%d)...\n',sesName,phaseName,phaseCount);

phaseNameForParticipant = 'test';

%% set the starting date and time for this phase

thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% determine the starting trial, useful for resuming

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_cr_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).testStims_img));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
  %save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','test_preStimFixOn','test_imgOn','recogRespPromptOn','recogRT');
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

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_cr_%d.txt',sesName,phaseName,phaseCount));
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

% read the proper old new response key image
oldNewKeyImg = imread(cfg.files.recogTestOldNewRespKeyImg);
oldNewKeyImgHeight = size(oldNewKeyImg,1) * cfg.files.respKeyImgScale;
oldNewKeyImgWidth = size(oldNewKeyImg,2) * cfg.files.respKeyImgScale;
oldNewKeyImg = Screen('MakeTexture',w,oldNewKeyImg);
% read the proper sure maybe response key image
sureMaybeKeyImg = imread(cfg.files.recogTestSureMaybeRespKeyImg);
sureMaybeKeyImgHeight = size(sureMaybeKeyImg,1) * cfg.files.respKeyImgScale;
sureMaybeKeyImgWidth = size(sureMaybeKeyImg,2) * cfg.files.respKeyImgScale;
sureMaybeKeyImg = Screen('MakeTexture',w,sureMaybeKeyImg);

% set the old new response key image rectangle
oldNewKeyImgRect = SetRect(0, 0, oldNewKeyImgWidth, oldNewKeyImgHeight);
oldNewKeyImgRect = CenterRect(oldNewKeyImgRect, cfg.screen.wRect);
oldNewKeyImgRect = AlignRect(oldNewKeyImgRect, cfg.screen.wRect, 'bottom', 'bottom');
% set the sure maybe response key image rectangle
sureMaybeKeyImgRect = SetRect(0, 0, sureMaybeKeyImgWidth, sureMaybeKeyImgHeight);
sureMaybeKeyImgRect = CenterRect(sureMaybeKeyImgRect, cfg.screen.wRect);
sureMaybeKeyImgRect = AlignRect(sureMaybeKeyImgRect, cfg.screen.wRect, 'bottom', 'bottom');

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

% are they allowed to respond while the stimulus is on the screen?
if ~isfield(phaseCfg,'respDuringStim')
  phaseCfg.respDuringStim = false;
end

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

%% Prepare the cued recall test task

% put it in the log file
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));
fprintf(logFile,'!!! Start of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);
fprintf(phLFile,'!!! Start of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);

stimImgRect_all = nan(length(testStims_img),4);
recallX_all = nan(length(testStims_img),1);
recallY_all = nan(length(testStims_img),1);
errorTextY_all = nan(length(testStims_img),1);
% responsePromptY_all = nan(length(testStims_img),1);

[~, screenCenterY] = RectCenter(cfg.screen.wRect);

% load up the stimuli for this block
testImgTex = nan(1,length(testStims_img));

message = sprintf('Preparing images, please wait...');
Screen('TextSize', w, cfg.text.basicTextSize);
% put the "preparing" message on the screen
DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
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

if expParam.useNS && phaseCfg.impedanceBeforePhase
  % run the impedance break
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  thisGetSecs = et_impedanceCheck(w, cfg, false);
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
end

%% start NS recording, if desired

% put a message on the screen as experiment phase begins
message = sprintf('Starting %s phase...',phaseNameForParticipant);
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = sprintf('Starting data acquisition for %s phase...',phaseNameForParticipant);
  
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_START');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_START');
end
Screen('TextSize', w, cfg.text.basicTextSize);
% draw message to screen
DrawFormattedText(w, message, 'center', 'center', cfg.text.basicTextColor, cfg.text.instructCharWidth);
% put it on
Screen('Flip', w);
% Wait before starting trial
WaitSecs(5.000);
% Clear screen to background color (our 'gray' as set at the beginning):
Screen('Flip', w);

%% show the test instructions

for i = 1:length(phaseCfg.instruct.cr)
  WaitSecs(1.000);
  et_showTextInstruct(w,phaseCfg.instruct.cr(i),cfg.keys.instructContKey,...
    cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
end

% Wait a second before starting trial
WaitSecs(1.000);

%% Run recognition and cued recall test

% only check these keys
RestrictKeysForKbCheck([cfg.keys.recogOld, cfg.keys.recogNew, cfg.keys.newSure, cfg.keys.newMaybe]);

% start the blink break timer
if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
  blinkTimerStart = GetSecs;
end

for i = trialNum:length(testStims_img)
  % Do a blink break if recording EEG and specified time has passed
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(testStims_img) - 3)
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
    % just draw straight into the main window since we don't need speed here
    DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % listen for any keypress on any keyboard
    RestrictKeysForKbCheck([]);
    thisGetSecs = KbWait(-1,2);
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    % only check these keys
    RestrictKeysForKbCheck([cfg.keys.recogOld, cfg.keys.recogNew, cfg.keys.newSure, cfg.keys.newMaybe]);
    
    if (phaseCfg.cr_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.cr_isi == 0 && phaseCfg.fixDuringPreStim)
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.cr_isi > 0
    if phaseCfg.fixDuringISI
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        [test_preStimFixOn] = Screen('Flip',w);
      else
        test_preStimFixOn = NaN;
        Screen('Flip',w);
      end
      WaitSecs(phaseCfg.cr_preCueStim);
    end
  elseif length(phaseCfg.cr_preCueStim) == 2
    if ~all(phaseCfg.cr_preCueStim == 0)
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        [test_preStimFixOn] = Screen('Flip',w);
      else
        test_preStimFixOn = NaN;
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
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  end
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'test_imgOnset':
  [test_imgOn, test_imgOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d.\n',i,length(testStims_img),testStims_img(i).fileName,testStims_img(i).targ);
  end
  
  % while loop to show stimulus until "duration" seconds elapsed.
  while (GetSecs - test_imgOnset) <= phaseCfg.cr_cueStimOnly
    % check for too-fast response
    if ~phaseCfg.respDuringStim
      [keyIsDown] = KbCheck;
      % if they press a key too early, tell them they responded too fast
      if keyIsDown
        % draw the stimulus
        Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        end
        % and the "too fast" text
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        Screen('Flip', w);
        
        keyIsDown = 0;
        break
      end
    else
      [keyIsDown, recogEndRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(0.0001);
          
          % % proceed if time is up, regardless of whether key is held
          % if (GetSecs - recogRT) > phaseCfg.cr_recog_response
          %   break
          % end
        end
        % if cfg.text.printTrialInfo
        %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - recogRT);
        % end
        if (keyCode(cfg.keys.recogOld) == 1 && all(keyCode(~cfg.keys.recogOld) == 0)) ||...
            (keyCode(cfg.keys.recogNew) == 1 && all(keyCode(~cfg.keys.recogNew) == 0))
          
          recogRespPromptOn = nan;
          break
        end
      elseif keyIsDown && sum(keyCode) > 1
        % draw the stimulus
        Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        end
        % don't push multiple keys
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        % put them on the screen
        Screen('Flip', w);
        
        keyIsDown = 0;
      end
    end
    
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % wait out any remaining time
  while (GetSecs - test_imgOnset) <= phaseCfg.cr_cueStimOnly
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  keyIsDown = logical(keyIsDown);
  
  if ~keyIsDown
    % draw the stimulus
    Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
    % draw response prompt
    Screen('DrawTexture', w, oldNewKeyImg, [], oldNewKeyImgRect);
    if phaseCfg.fixDuringStim
      % and fixation on top of it
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    % put them on the screen; measure RT from when response key img appears
    [recogRespPromptOn, recogRespPromptStartRT] = Screen('Flip', w);
    
    % poll for a recogResp
    while (GetSecs - recogRespPromptStartRT) <= phaseCfg.cr_recog_response
      
      [keyIsDown, recogEndRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(0.0001);
          
          % % proceed if time is up, regardless of whether key is held
          % if (GetSecs - recogRT(i)) > phaseCfg.cr_recog_response
          %   break
          % end
        end
        % if cfg.text.printTrialInfo
        %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - recogRT);
        % end
        if (keyCode(cfg.keys.recogOld) == 1 && all(keyCode(~cfg.keys.recogOld) == 0)) ||...
            (keyCode(cfg.keys.recogNew) == 1 && all(keyCode(~cfg.keys.recogNew) == 0))
          break
        end
      elseif keyIsDown && sum(keyCode) > 1
        % draw the stimulus
        Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
        % draw response prompt
        Screen('DrawTexture', w, oldNewKeyImg, [], oldNewKeyImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        end
        % don't push multiple keys
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        % put them on the screen
        Screen('Flip', w);
        
        keyIsDown = 0;
      end
      % wait so we don't overload the system
      WaitSecs(0.0001);
    end
    
    keyIsDown = logical(keyIsDown);
  end
  
  if ~keyIsDown
    if phaseCfg.playSound
      Beeper(phaseCfg.incorrectSound,phaseCfg.incorrectVol);
    end
    
    % "need to respond faster"
    Screen('TextSize', w, cfg.text.instructTextSize);
    DrawFormattedText(w,cfg.text.respondFaster,'center','center',cfg.text.respondFasterColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % need a new endRT
    recogEndRT = GetSecs;
    
    % wait to let them view the feedback
    WaitSecs(cfg.text.respondFasterFeedbackTime);
  end
  
  % if this is an old image, get the word paired with it
  if testStims_img(i).targ
    thisWord = testStims_word([testStims_word.pairNum] == testStims_img(i).pairNum);
    if length(thisWord) == 1
      thisPairedWord = lower(thisWord.word);
    else
      error('Cannot have more than one word paired with an image');
    end
  else
    % otherwise leave it empty
    thisPairedWord = '';
  end
  
  if keyIsDown && sum(keyCode) == 1
    % get the key they pressed
    recogRespKey = KbName(keyCode);
    
    if (keyCode(cfg.keys.recogOld) == 1 && all(keyCode(~cfg.keys.recogOld) == 0))
      recogResp = 'old';
      
      newRespPromptOn = nan;
      
      % if they answer 'old', get typed word response
      useKbCheck = false;
      
      % get their answer and type it to the screen
      dispRecallResp = cfg.text.recallPrompt;
      recallResp = '';
      if ~useKbCheck
        % Flush the keyboard buffer:
        FlushEvents;
      end
      
      madeWordResp = false;
      
      if phaseCfg.cr_corrSpell && phaseCfg.cr_nAttempts > 0
        attemptCounter = 0;
      end
      
      % draw the stimulus
      Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
      if phaseCfg.fixDuringStim
        % and fixation on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      % draw the recall resonse prompt
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, sprintf('%s',dispRecallResp), recallX, recallY, cfg.text.basicTextColor);
      
      [recallRespPromptOn, recallRespPromptStartRT] = Screen('Flip', w);
      
      %while isempty(recogResp)
      while ~madeWordResp
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
          end
          
          switch (abs(char))
            case {13, 3, 10}
              % ctrl-C, enter, or return
              break
            case {8}
              % 8 = backspace
              
              if ~isempty(recallResp)
                recallResp = recallResp(1:length(recallResp)-1);
              end
              if ~isempty(recallResp)
                dispRecallResp = recallResp;
              else
                dispRecallResp = cfg.text.recallPrompt;
              end
            otherwise
              if ismember(char, cfg.keys.recallKeyNames)
                recallResp = [recallResp, char]; %#ok<AGROW>
              end
              if ~isempty(recallResp)
                dispRecallResp = recallResp;
              else
                dispRecallResp = cfg.text.recallPrompt;
              end
          end
          
          % draw the stimulus
          Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
          if phaseCfg.fixDuringStim
            % and fixation on top of it
            Screen('TextSize', w, cfg.text.fixSize);
            DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % draw their text
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, sprintf('%s',dispRecallResp), recallX, recallY, cfg.text.basicTextColor);
          [respMadeRT] = Screen('Flip', w);
          
          WaitSecs(0.0001);
        end
        
        if testStims_img(i).targ
          % if it's a targ stim, see if they needed the correct spelling
          if phaseCfg.cr_corrSpell
            attemptCounter = attemptCounter + 1;
            
            if strcmpi(recallResp,thisPairedWord)
              corrSpell = true;
              madeWordResp = true;
              %break
            else
              corrSpell = false;
              if attemptCounter >= phaseCfg.cr_nAttempts
                madeWordResp = true;
                %break
              end
            end
          else
            corrSpell = true;
            madeWordResp = true;
            %break
          end
        else
          % this was a lure image and they're making a response
          corrSpell = false;
          madeWordResp = true;
        end
      end
      %end
      
      % get the time they pressed return
      recallEndRT = respMadeRT;
      % only need the seconds
      % recallEndRT = endRT.secs;
      
    elseif (keyCode(cfg.keys.recogNew) == 1 && all(keyCode(~cfg.keys.recogNew) == 0))
      recogResp = 'new';
      
      recallRespPromptOn = nan;
      
      % elseif they answer 'new', ask 'sure' vs 'maybe'
      
      % draw the stimulus
      Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
      % draw response prompt
      Screen('DrawTexture', w, sureMaybeKeyImg, [], sureMaybeKeyImgRect);
      if phaseCfg.fixDuringStim
        % and fixation on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      % put them on the screen; measure RT from when response key img appears
      [newRespPromptOn, newRespPromptStartRT] = Screen('Flip', w);
      
      % poll for a newResp
      while (GetSecs - newRespPromptStartRT) <= phaseCfg.cr_new_response
        
        [keyIsDown, newEndRT, keyCode] = KbCheck;
        % if they push more than one key, don't accept it
        if keyIsDown && sum(keyCode) == 1
          % wait for key to be released
          while KbCheck(-1)
            WaitSecs(0.0001);
            
            % % proceed if time is up, regardless of whether key is held
            % if (GetSecs - recogRT(i)) > phaseCfg.cr_recog_response
            %   break
            % end
          end
          % if cfg.text.printTrialInfo
          %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - recogRT);
          % end
          if (keyCode(cfg.keys.newSure) == 1 && all(keyCode(~cfg.keys.newSure) == 0)) ||...
              (keyCode(cfg.keys.newMaybe) == 1 && all(keyCode(~cfg.keys.newMaybe) == 0))
            break
          end
        elseif keyIsDown && sum(keyCode) > 1
          % draw the stimulus
          Screen('DrawTexture', w, testImgTex(i), [], stimImgRect);
          % draw response prompt
          Screen('DrawTexture', w, sureMaybeKeyImg, [], sureMaybeKeyImgRect);
          if phaseCfg.fixDuringStim
            % and fixation on top of it
            Screen('TextSize', w, cfg.text.fixSize);
            DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % don't push multiple keys
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          % put them on the screen
          Screen('Flip', w);
          
          keyIsDown = 0;
        end
        % wait so we don't overload the system
        WaitSecs(0.0001);
      end
      
      keyIsDown = logical(keyIsDown);
      
      if ~keyIsDown
        if phaseCfg.playSound
          Beeper(phaseCfg.incorrectSound,phaseCfg.incorrectVol);
        end
        
        % "need to respond faster"
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.respondFaster,'center','center',cfg.text.respondFasterColor, cfg.text.instructCharWidth);
        Screen('Flip', w);
        
        % need a new endRT
        newEndRT = GetSecs;
        
        % wait to let them view the feedback
        WaitSecs(cfg.text.respondFasterFeedbackTime);
      end
      
      if keyIsDown && sum(keyCode) == 1
        % get the key they pressed
        newRespKey = KbName(keyCode);
        
        if (keyCode(cfg.keys.newSure) == 1 && all(keyCode(~cfg.keys.newSure) == 0))
          newResp = 'sure';
        elseif (keyCode(cfg.keys.newMaybe) == 1 && all(keyCode(~cfg.keys.newMaybe) == 0))
          newResp = 'maybe';
        elseif keyCode(cfg.keys.newSure) == 0 && keyCode(cfg.keys.newMaybe) == 0
          warning('Key other than a new response key was pressed. This should not happen.\n');
          newResp = 'ERROR_OTHERKEY';
        else
          warning('Some other error occurred.\n');
          newResp = 'ERROR_OTHER';
        end
      elseif keyIsDown && sum(keyCode) > 1
        warning('Multiple keys were pressed.\n');
        newResp = 'ERROR_MULTIKEY';
        % get the keys they pressed
        thisNewResp = KbName(keyCode);
        newRespKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisNewResp)),thisNewResp{:}));
      elseif ~keyIsDown
        newAcc = false;
        newRespKey = 'none';
        newResp = 'none';
      end
      
    elseif keyCode(cfg.keys.recogOld) == 0 && keyCode(cfg.keys.recogNew) == 0
      warning('Key other than a recognition response key was pressed. This should not happen.\n');
      recogResp = 'ERROR_OTHERKEY';
    else
      warning('Some other error occurred.\n');
      recogResp = 'ERROR_OTHER';
    end
  elseif keyIsDown && sum(keyCode) > 1
    warning('Multiple keys were pressed.\n');
    recogResp = 'ERROR_MULTIKEY';
    % get the keys they pressed
    thisRecogResp = KbName(keyCode);
    recogRespKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisRecogResp)),thisRecogResp{:}));
  elseif ~keyIsDown
    recogAcc = false;
    recogRespKey = 'none';
    recogResp = 'none';
  end
  
  if (phaseCfg.cr_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.cr_isi == 0 && phaseCfg.fixDuringPreStim)
    % draw fixation after response
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  end
  
  % clear screen
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', testImgTex(i));
  
  % compute old/new recognition response time
  if phaseCfg.respDuringStim
    measureRTfromHere = test_imgOnset;
  else
    measureRTfromHere = recogRespPromptStartRT;
  end
  recogRespRT = int32(round(1000 * (recogEndRT - measureRTfromHere)));
  
  % compute response times and accuracy
  if strcmp(recogResp,'old')
    % compute recall response time
    recallRespRT = int32(round(1000 * (recallEndRT - recallRespPromptStartRT)));
    
    % compute accuracy
    if testStims_img(i).targ
      % hit
      recogAcc = true;
    elseif ~testStims_img(i).targ
      % miss
      recogAcc = false;
    end
    newAcc = NaN;
  elseif strcmp(recogResp,'new')
    % compute sure/maybe response time
    newRespRT = int32(round(1000 * (newEndRT - newRespPromptStartRT)));
    
    % compute accuracy
    if testStims_img(i).targ
      % false alarm
      recogAcc = false;
      newAcc = false;
    elseif ~testStims_img(i).targ
      % correct rejection
      recogAcc = true;
      newAcc = true;
    end
  end
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d. recogResponse: %s (key: %s; recogAcc = %d; rt = %d)\n',...
      i,length(testStims_img),testStims_img(i).fileName,testStims_img(i).targ,recogResp,recogRespKey,recogAcc,recogRespRT);
    if strcmp(recogResp,'new')
      fprintf('\tnewResponse: %s (key: %s; newAcc = %d; rt = %d)\n',newResp,newRespKey,newAcc,newRespRT);
    elseif strcmp(recogResp,'old')
      fprintf('\trecallResponse: %s (origWord = %s; spelled correctly = %d; rt = %d)\n',recallResp,thisPairedWord,corrSpell,recallRespRT);
    end
  end
  
  %% session log file
  
  % Write test stimulus presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
    test_imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'RECOGTEST_STIM',...
    i,...
    testStims_img(i).fileName,...
    int32(testStims_img(i).stimNum),...
    testStims_img(i).targ,...
    testStims_img(i).spaced,...
    int32(testStims_img(i).lag),...
    int32(testStims_img(i).pairNum),...
    testStims_img(i).categoryStr,...
    int32(testStims_img(i).categoryNum));
  
  if ~isnan(recogRespPromptOn)
    % Write test key image presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      recogRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_RECOGRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum));
  end
  
  % Write trial result to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
    recogEndRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'RECOGTEST_RECOGRESP',...
    i,...
    testStims_img(i).fileName,...
    int32(testStims_img(i).stimNum),...
    testStims_img(i).targ,...
    testStims_img(i).spaced,...
    int32(testStims_img(i).lag),...
    int32(testStims_img(i).pairNum),...
    testStims_img(i).categoryStr,...
    int32(testStims_img(i).categoryNum),...
    recogResp,...
    recogRespKey,...
    recogAcc,...
    recogRespRT);
  
  if ~isnan(newRespPromptOn)
    % Write test key image presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      newRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_NEWRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum));
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
      newEndRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_NEWRESP',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum),...
      newResp,...
      newRespKey,...
      newAcc,...
      newRespRT);
  end

  if ~isnan(recallRespPromptOn)
    % Write test key image presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      recallRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_RECALLRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum));
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
      recallEndRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_RECALLRESP',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum),...
      recallResp,...
      thisPairedWord,...
      corrSpell,...
      recallRespRT);
  end

  %% phase log file
  
  % Write test stimulus presentation to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
    test_imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'RECOGTEST_STIM',...
    i,...
    testStims_img(i).fileName,...
    int32(testStims_img(i).stimNum),...
    testStims_img(i).targ,...
    testStims_img(i).spaced,...
    int32(testStims_img(i).lag),...
    int32(testStims_img(i).pairNum),...
    testStims_img(i).categoryStr,...
    int32(testStims_img(i).categoryNum));
  
  if ~isnan(recogRespPromptOn)
    % Write test key image presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      recogRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_RECOGRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum));
  end
  
  % Write trial result to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
    recogEndRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'RECOGTEST_RECOGRESP',...
    i,...
    testStims_img(i).fileName,...
    int32(testStims_img(i).stimNum),...
    testStims_img(i).targ,...
    testStims_img(i).spaced,...
    int32(testStims_img(i).lag),...
    int32(testStims_img(i).pairNum),...
    testStims_img(i).categoryStr,...
    int32(testStims_img(i).categoryNum),...
    recogResp,...
    recogRespKey,...
    recogAcc,...
    recogRespRT);
  
  if ~isnan(newRespPromptOn)
    % Write test key image presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      newRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_NEWRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum));
    
    % Write trial result to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
      newEndRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_NEWRESP',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum),...
      newResp,...
      newRespKey,...
      newAcc,...
      newRespRT);
  end

  if ~isnan(recallRespPromptOn)
    % Write test key image presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
      recallRespPromptOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_RECALLRESPPROMPT',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum));
    
    % Write trial result to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\n',...
      recallEndRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'RECOGTEST_RECALLRESP',...
      i,...
      testStims_img(i).fileName,...
      int32(testStims_img(i).stimNum),...
      testStims_img(i).targ,...
      testStims_img(i).spaced,...
      int32(testStims_img(i).lag),...
      int32(testStims_img(i).pairNum),...
      testStims_img(i).categoryStr,...
      int32(testStims_img(i).categoryNum),...
      recallResp,...
      thisPairedWord,...
      corrSpell,...
      recallRespRT);
  end
  
  %% Write netstation logs
  
  if expParam.useNS
    % Write trial info to et_NetStation
    % mark every event with the following key code/value pairs
    % 'subn', subject number
    % 'sess', session type
    % 'phas', session phase name
    % 'pcou', phase count
    % 'expt', whether this is the experiment (1) or practice (0)
    % 'bloc', int32(b)lock number (training day 1 only)
    % 'part', whether this is a 'study' or 'test' trial
    % 'trln', trial number
    % 'stmn', stimulus name (family, species, exemplar)
    % 'spcn', species number (corresponds to keyboard)
    % 'sord', whether this is a subordinate (1) or basic (0) level family
    % 'targ', whether this is a target (1) or not (0)
    % 'rsps', response string
    % 'rspk', the name of the key pressed
    % 'rspt', the response time
    % 'corr', accuracy code (1=correct, 0=incorrect)
    % 'keyp', key pressed?(1=yes, 0=no)
    
    % write out the stimulus name
    stimName = sprintf('%s%s%d',...
      testStims_img(i).categoryStr,...
      testStims_img(i).speciesStr,...
      testStims_img(i).exemplarName);
    
    if ~isnan(test_preStimFixOn)
      % pretrial fixation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', test_preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'part','test',...
        'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', testStims_img(i).targ,...
        'rsps', recogResp, 'rspk', recogRespKey, 'rspt', recogRespRT, 'corr', recogAcc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % img presentation
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', test_imgOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
      'expt',phaseCfg.isExp,...
      'bloc', int32(b),...
      'part','test',...
      'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', testStims_img(i).targ,...
      'rsps', recogResp, 'rspk', recogRespKey, 'rspt', recogRespRT, 'corr', recogAcc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    if ~isnan(recogRespPromptOn)
      % response prompt
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'PROM', recogRespPromptOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'part','test',...
        'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', testStims_img(i).targ,...
        'rsps', recogResp, 'rspk', recogRespKey, 'rspt', recogRespRT, 'corr', recogAcc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % did they make a response?
    if keyIsDown
      % button push
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'RESP', recogRespRT, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'part','test',...
        'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', testStims_img(i).targ,...
        'rsps', recogResp, 'rspk', recogRespKey, 'rspt', recogRespRT, 'corr', recogAcc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % if this is a target, log the study stimulus with response
    if testStims_img(i).targ
      % find where it occurred in the study list
      sInd = find(ismember({targStims.fileName},testStims_img(i).fileName));
      
      % write out the stimulus name
      stimName = sprintf('%s%s%d',...
        targStims(sInd).categoryStr,...
        targStims(sInd).speciesStr,...
        targStims(sInd).exemplarName);
      
      if ~isnan(study_preStimFixOn(sInd))
        % pretrial fixation
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', study_preStimFixOn(sInd), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'bloc', int32(b),...
          'part','study',...
          'trln', int32(sInd), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
          'targ', targStims(sInd).targ,...
          'rsps', recogResp, 'rspk', recogRespKey, 'rspt', recogRespRT, 'corr', recogAcc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % img presentation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', study_imgOn(sInd), .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'part','study',...
        'trln', int32(sInd), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
        'targ', targStims(sInd).targ,...
        'rsps', recogResp, 'rspk', recogRespKey, 'rspt', recogRespRT, 'corr', recogAcc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
  end % useNS
  
  % mark that we finished this trial
  trialComplete(i) = true;
  % save progress after each trial
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end % for stimuli

% print "continue" screen
messageText = sprintf('You have finished the %s phase.\n\nPress "%s" to continue.',...
  phaseNameForParticipant,cfg.keys.instructContKey);
Screen('TextSize', w, cfg.text.instructTextSize);
DrawFormattedText(w,messageText,'center','center',cfg.text.instructColor, cfg.text.instructCharWidth);
Screen('Flip', w);

% wait until the key is pressed
RestrictKeysForKbCheck(KbName(cfg.keys.instructContKey));
KbWait(-1,2);
RestrictKeysForKbCheck([]);

% go back to gray
Screen('Flip', w);

%% cleanup

% stop recording
if expParam.useNS
  WaitSecs(5.0);
  [NSSyncStatus, NSSyncError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
  
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

end % function

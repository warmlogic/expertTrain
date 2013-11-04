function [cfg,expParam] = space_exposure(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = space_exposure(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
%
% Description:
%  This function runs the exposure task. There are no blocks, only
%  short (blink) breaks.
%  TODO: Maybe add a longer break in the middle and tell subjects that this
%  is the middle of the experiment.
%
%  The stimuli for the exposure task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phaseName).expoStims_img
%  as a struct.
%
%
% Inputs:
%
%
% Outputs:
%
%
%
% NB:
%  Once agian, stimuli must already be sorted in presentation order!
%
%
% NB:
%  presNum is the presentation number for this stimulus pair (1 or 2)
%  pairNum is to keep the image and word together (both stims are the same)
%  pairOrd is the order in which the image and word are shown (one is 1 and
%          the other is 2)




% NB:
%  When same and diff stimuli are combined, to find the corresponding pair
%  search for a matching familyNum (basic or subordinate), a matching or
%  different speciesNum field (same or diff condition), a matching or
%  different trained field, the same matchPairNum, and the opposite
%  matchStimNum (1 or 2).

% % durations, in seconds

% % keys

fprintf('Running %s %s (expo) (%d)...\n',sesName,phaseName,phaseCount);

phaseNameForParticipant = 'judgment';

%% set the starting date and time for this phase
thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% determine the starting trial, useful for resuming

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_expo_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).expoStims_img));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
else
  fprintf('All trials for %s %s (expo) (%d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount);
  % release any remaining textures
  Screen('Close');
  return
end

%% start the log file for this phase

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_expo_%d.txt',sesName,phaseName,phaseCount));
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

%% preparation

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
expoStims_img = expParam.session.(sesName).(phaseName)(phaseCount).expoStims_img;

if phaseCfg.isExp
  imgStimDir = cfg.files.imgStimDir;
else
  imgStimDir = cfg.files.imgStimDir_prac;
end

% default is to preload the images
if ~isfield(cfg.stim,'preloadImages')
  cfg.stim.preloadImages = false;
end

% read the proper exposure ranking key image
expoKeyImg = imread(cfg.files.exposureRankRespKeyImg);
expoKeyImgHeight = size(expoKeyImg,1) * cfg.files.respKeyImgScale;
expoKeyImgWidth = size(expoKeyImg,2) * cfg.files.respKeyImgScale;
expoKeyImg = Screen('MakeTexture',w,expoKeyImg);
% set the expo ranking response key image rectangle
expoKeyImgRect = SetRect(0, 0, expoKeyImgWidth, expoKeyImgHeight);
expoKeyImgRect = CenterRect(expoKeyImgRect, cfg.screen.wRect);
expoKeyImgRect = AlignRect(expoKeyImgRect, cfg.screen.wRect, 'bottom', 'bottom');

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
  phaseCfg.respDuringStim = true;
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

if ~isfield(phaseCfg,'impedanceAfter_nTrials')
  phaseCfg.impedanceAfter_nTrials = 0;
end

if ~isfield(phaseCfg,'showRespInBreak')
  phaseCfg.showRespInBreak = true;
end

if ~isfield(phaseCfg,'showRespBtStim')
  phaseCfg.showRespBtStim = true;
end

% whether to ask the participant if they have any questions; only continues
% with experimenter's secret key
if ~isfield(phaseCfg.instruct,'questions')
  phaseCfg.instruct.questions = true;
end

% whether to present a white square during the stimulus and a black square
% at all other times
if ~isfield(cfg.stim,'photoCell')
  cfg.stim.photoCell = false;
end

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

%% preload all stimuli for presentation

expoImgTex = nan(1,length(expoStims_img));

message = sprintf('Preparing images, please wait...');
Screen('TextSize', w, cfg.text.basicTextSize);
% put the "preparing" message on the screen
DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
% Update the display to show the message:
Screen('Flip', w);

% initialize to store image stimulus parameters
stimImgRect_all = nan(length(expoStims_img),4);
errorTextY_all = nan(length(expoStims_img),1);
%wordStimY_all = nan(length(expoStims_img),1);
%responsePromptY_all = nan(length(expoStims_img),1);

[~, screenCenterY] = RectCenter(cfg.screen.wRect);

for i = 1:length(expoStims_img)
  % make sure image stimulus exists
  stimImgFile = fullfile(imgStimDir,expoStims_img(i).categoryStr,expoStims_img(i).fileName);
  if exist(stimImgFile,'file')
    % load up stim's texture
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
    
    % text location for error (e.g., "too fast") text
    errorTextY_all(i) = screenCenterY + (stimImgHeight / 2);
    
    % text location for word stimulus
    %wordStimY_all(i) = screenCenterY;
    %wordStimY_all(i) = screenCenterY + (stimImgHeight / 2);
    
    % text location for response prompt
    %responsePromptY_all(i) = screenCenterY + (stimImgHeight / 2) + (screenCenterY * 0.05);
    
    if cfg.stim.preloadImages
      expoImgTex(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %studyImgTex(i) = Screen('MakeTexture',w,stimImg,[],1);
      %elseif ~cfg.stim.preloadImages && i == length(expoStims_img)
      %  % still need to load the last image to set the rectangle
      %  stimImg = imread(stimImgFile);
    end
  else
    error('Study stimulus %s does not exist!',stimImgFile);
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
% put it on
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
Screen('Flip', w);
% Wait before starting trial
WaitSecs(5.000);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
% Clear screen to background color (our 'gray' as set at the beginning):
Screen('Flip', w);

%% show the instructions

if ~expParam.photoCellTest
  for i = 1:length(phaseCfg.instruct.expo)
    WaitSecs(1.000);
    et_showTextInstruct(w,cfg,phaseCfg.instruct.expo(i),cfg.keys.instructContKey,...
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

%% run the exposure task

% only check these keys
RestrictKeysForKbCheck([cfg.keys.expoVA, cfg.keys.expoSA, cfg.keys.expoSU, cfg.keys.expoVU]);

% start the blink break timer
if phaseCfg.isExp && phaseCfg.secUntilBlinkBreak > 0
  blinkTimerStart = GetSecs;
end

for i = trialNum:length(expoStims_img)
  % do an impedance check after a certain number of trials
  if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(expoStims_img) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
    % run the impedance break
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
    thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
    
    RestrictKeysForKbCheck([cfg.keys.expoVA, cfg.keys.expoSA, cfg.keys.expoSU, cfg.keys.expoVU]);
    
    if phaseCfg.showRespInBreak
      % draw response prompt
      Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    end
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if phaseCfg.showRespInBreak
      % draw response prompt
      Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    end
    if (phaseCfg.expo_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.expo_isi == 0 && phaseCfg.fixDuringPreStim)
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
  if ~expParam.photoCellTest && phaseCfg.isExp && phaseCfg.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= phaseCfg.secUntilBlinkBreak && i > 3 && i < (length(expoStims_img) - 3)
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    Screen('TextSize', w, cfg.text.basicTextSize);
    if expParam.useNS
      pauseMsg = 'Blink now.\n\n';
    else
      pauseMsg = '';
    end
    pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, length(expoStims_img));
    
    if phaseCfg.showRespInBreak
      % draw response prompt
      Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    end
    % just draw straight into the main window since we don't need speed here
    DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    
    % listen for any keypress on any keyboard
    RestrictKeysForKbCheck([]);
    
    thisGetSecs = KbWait(-1,2);
    %thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    
    RestrictKeysForKbCheck([cfg.keys.expoVA, cfg.keys.expoSA, cfg.keys.expoSU, cfg.keys.expoVU]);
    
    if phaseCfg.showRespInBreak
      % draw response prompt
      Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    end
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if phaseCfg.showRespInBreak
      % draw response prompt
      Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    end
    if (phaseCfg.expo_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.expo_isi == 0 && phaseCfg.fixDuringPreStim)
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
    end
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip',w);
    WaitSecs(1.0);
    
    % reset the timer
    blinkTimerStart = GetSecs;
  end
  
  % load the image stimulus now if we didn't load it earlier
  if ~cfg.stim.preloadImages
    stimImg = imread(fullfile(imgStimDir,expoStims_img(i).categoryStr,expoStims_img(i).fileName));
    
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
    expoImgTex(i) = Screen('MakeTexture',w,stimImg);
  end
  
  % pull out the coordinates we need
  stimImgRect = stimImgRect_all(i,:);
  errorTextY = errorTextY_all(i);
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.expo_isi > 0
    if phaseCfg.showRespBtStim
      % draw response prompt
      Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    end
    if phaseCfg.fixDuringISI
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
    end
    WaitSecs(phaseCfg.expo_isi);
  end
  
  %   % preStimulus period, with fixation if desired
  %   if length(phaseCfg.expo_preStim) == 1
  %     if phaseCfg.expo_preStim > 0
  %       if phaseCfg.fixDuringPreStim
  %         if phaseCfg.showRespBtStim
  %           % draw response prompt
  %           Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
  %         end
  %         % draw fixation
  %         Screen('TextSize', w, cfg.text.fixSize);
  %         %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  %         Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  %         if cfg.stim.photoCell
  %           Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  %         end
  %         [preStimFixOn] = Screen('Flip',w);
  %       else
  %         if phaseCfg.showRespBtStim
  %           % draw response prompt
  %           Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
  %         end
  %         preStimFixOn = NaN;
  %         if cfg.stim.photoCell
  %           Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  %         end
  %         Screen('Flip',w);
  %       end
  %       WaitSecs(phaseCfg.expo_preStim);
  %     end
  %   elseif length(phaseCfg.expo_preStim) == 2
  %     if ~all(phaseCfg.expo_preStim == 0)
  %       if phaseCfg.fixDuringPreStim
  %         if phaseCfg.showRespBtStim
  %           % draw response prompt
  %           Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
  %         end
  %         % draw fixation
  %         Screen('TextSize', w, cfg.text.fixSize);
  %         %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  %         Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  %         if cfg.stim.photoCell
  %           Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  %         end
  %         [preStimFixOn] = Screen('Flip',w);
  %       else
  %         if phaseCfg.showRespBtStim
  %           % draw response prompt
  %           Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
  %         end
  %         preStimFixOn = NaN;
  %         if cfg.stim.photoCell
  %           Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  %         end
  %         Screen('Flip',w);
  %       end
  %       % fixation on screen before stim for a random amount of time
  %       WaitSecs(phaseCfg.expo_preStim(1) + ((phaseCfg.expo_preStim(2) - phaseCfg.expo_preStim(1)).*rand(1,1)));
  %     end
  %   end
  
  % preStimulus period, with fixation if desired
  if length(phaseCfg.expo_preStim) == 1 && phaseCfg.expo_preStim > 0
    preStimTime = phaseCfg.expo_preStim;
  elseif length(phaseCfg.expo_preStim) == 2 && ~all(phaseCfg.expo_preStim == 0)
    preStimTime = phaseCfg.expo_preStim(1) + ((phaseCfg.expo_preStim(2) - phaseCfg.expo_preStim(1)).*rand(1,1));
  else
    preStimTime = 0;
  end
  if preStimTime > 0
    if phaseCfg.fixDuringPreStim
      if phaseCfg.showRespBtStim
        % draw response prompt
        Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
      end
      % draw fixation
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      [preStimFixOn] = Screen('Flip',w);
    else
      if phaseCfg.showRespBtStim
        % draw response prompt
        Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
      end
      preStimFixOn = NaN;
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
    end
    % fixation on screen before stim for a random amount of time
    WaitSecs(preStimTime);
  end
  
  % draw the image stimulus
  Screen('DrawTexture', w, expoImgTex(i), [], stimImgRect);
  if phaseCfg.respDuringStim
    % draw response prompt
    Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
  end
  if phaseCfg.fixDuringStim
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  end
  
  % photocell rect with stim
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
  end
  
  % put the stimuli on the screen
  [imgOn, stimOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: stim (%s): category %d (%s).\n',i,length(expoStims_img),expoStims_img(i).fileName,expoStims_img(i).categoryNum,expoStims_img(i).categoryStr);
  end
  
  % while loop to show stimulus until subject response or until
  % "study_stim2" seconds elapse.
  while (GetSecs - stimOnset) <= phaseCfg.expo_stim
    
    % check for too-fast response
    if ~phaseCfg.respDuringStim
      [keyIsDown] = KbCheck;
      % if they press a key too early, tell them they responded too fast
      if keyIsDown
        % draw the image stimulus
        Screen('DrawTexture', w, expoImgTex(i), [], stimImgRect);
        % draw response prompt
        Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        end
        
        % and the "too fast" text
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        
        % photocell rect with stim
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
        end
        
        Screen('Flip', w);
        
        keyIsDown = 0;
        break
      end
    else
      [keyIsDown, endRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(0.0001);
          
          % % proceed if time is up, regardless of whether key is held
          % if (GetSecs - startRT) > phaseCfg.expo_response
          %   break
          % end
        end
        % if cfg.text.printTrialInfo
        %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
        % end
        if (keyCode(cfg.keys.expoVA) == 1 && all(keyCode(~cfg.keys.expoVA) == 0)) ||...
            (keyCode(cfg.keys.expoSA) == 1 && all(keyCode(~cfg.keys.expoSA) == 0)) ||...
            (keyCode(cfg.keys.expoSU) == 1 && all(keyCode(~cfg.keys.expoSU) == 0)) ||...
            (keyCode(cfg.keys.expoVU) == 1 && all(keyCode(~cfg.keys.expoVU) == 0))
          break
        end
      elseif keyIsDown && sum(keyCode) > 1
        % draw the image stimulus
        Screen('DrawTexture', w, expoImgTex(i), [], stimImgRect);
        % draw response prompt
        Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        end
        % don't push multiple keys
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        
        % photocell rect with stim
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
        end
        
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
  while (GetSecs - stimOnset) <= phaseCfg.expo_stim
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  keyIsDown = logical(keyIsDown);
  
  if keyIsDown
    % if they hit a key while the stimulus was on the screen (the only way
    % keyIsDown==1)
    
    % code that follows this if statement block will take the stimulus off
    % screen and give feedback if this is a practice phase
    
    respPromptOn = NaN;
  else
    % draw the image stimulus
    Screen('DrawTexture', w, expoImgTex(i), [], stimImgRect);
    % draw response prompt
    Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    if phaseCfg.fixDuringStim
      % and fixation on top of it
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
    end
    % photocell rect with stim
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
    end
    
    [respPromptOn, startRT] = Screen('Flip',w);
    
    % poll for a resp
    while (GetSecs - startRT) <= phaseCfg.expo_response
      
      [keyIsDown, endRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(0.0001);
          
          % % proceed if time is up, regardless of whether key is held
          % if (GetSecs - startRT) > phaseCfg.expo_response
          %   break
          % end
        end
        % if cfg.text.printTrialInfo
        %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
        % end
        if (keyCode(cfg.keys.expoVA) == 1 && all(keyCode(~cfg.keys.expoVA) == 0)) ||...
            (keyCode(cfg.keys.expoSA) == 1 && all(keyCode(~cfg.keys.expoSA) == 0)) ||...
            (keyCode(cfg.keys.expoSU) == 1 && all(keyCode(~cfg.keys.expoSU) == 0)) ||...
            (keyCode(cfg.keys.expoVU) == 1 && all(keyCode(~cfg.keys.expoVU) == 0))
          break
        end
      elseif keyIsDown && sum(keyCode) > 1
        % draw the image stimulus
        Screen('DrawTexture', w, expoImgTex(i), [], stimImgRect);
        % draw response prompt
        Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
        end
        % don't push multiple keys
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        
        % photocell rect with stim
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
        end
        
        % put them on the screen
        Screen('Flip', w);
        
        keyIsDown = 0;
      end
      % wait so we don't overload the system
      WaitSecs(0.0001);
    end
    
    keyIsDown = logical(keyIsDown);
  end
  
  % determine response and compute accuracy
  if keyIsDown
    if (keyCode(cfg.keys.expoVA) == 1 && all(keyCode(~cfg.keys.expoVA) == 0))
      resp = cfg.text.expoVAresp;
      message = '';
    elseif (keyCode(cfg.keys.expoSA) == 1 && all(keyCode(~cfg.keys.expoSA) == 0))
      resp = cfg.text.expoSAresp;
      message = '';
    elseif (keyCode(cfg.keys.expoSU) == 1 && all(keyCode(~cfg.keys.expoSU) == 0))
      resp = cfg.text.expoSUresp;
      message = '';
    elseif (keyCode(cfg.keys.expoVU) == 1 && all(keyCode(~cfg.keys.expoVU) == 0))
      resp = cfg.text.expoVUresp;
      message = '';
    elseif sum(keyCode) > 1
      warning('Multiple keys were pressed.\n');
      resp = 'ERROR_MULTIKEY';
    elseif sum(~ismember(find(keyCode == 1),[cfg.keys.expoVA, cfg.keys.expoSA, cfg.keys.expoSU, cfg.keys.expoVU])) > 0
      warning('Key other than expo VA/SA/SU/VU was pressed. This should not happen.\n');
      resp = 'ERROR_OTHERKEY';
    else
      warning('Some other error occurred.\n');
      resp = 'ERROR_OTHER';
    end
    %     if ~phaseCfg.isExp
    %       % only give feedback during practice
    %       feedbackTime = cfg.text.respondFasterFeedbackTime;
    %     else
    %       message = '';
    %       feedbackTime = 0.01;
    %     end
  else
    resp = 'NO_RESPONSE';
    %     % did not push a key
    %     acc = false;
    
    % need a new endRT
    endRT = GetSecs;
    
    % "need to respond faster"
    message = cfg.text.respondFaster;
    feedbackColor = cfg.text.respondFasterColor;
    feedbackTime = cfg.text.respondFasterFeedbackTime;
    if phaseCfg.playSound
      respSound = phaseCfg.incorrectSound;
      respVol = phaseCfg.incorrectVol;
    end
  end
  
  if ~isempty(message)
    if phaseCfg.playSound && (~phaseCfg.isExp || (phaseCfg.isExp && ~keyIsDown))
      Beeper(respSound,respVol);
    end
    Screen('TextSize', w, cfg.text.instructTextSize);
    DrawFormattedText(w,message,'center','center',feedbackColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    % wait to let them view the feedback
    WaitSecs(feedbackTime);
  end
  
  % get key pressed by subject
  if keyIsDown
    if sum(keyCode) == 1
      respKey = KbName(keyCode);
    elseif sum(keyCode) > 1
      thisResp = KbName(keyCode);
      respKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisResp)),thisResp{:}));
    end
  else
    respKey = 'NO_RESPONSE_KEY';
  end
  
  if (phaseCfg.expo_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.expo_isi == 0 && phaseCfg.fixDuringPreStim)
    if phaseCfg.showRespBtStim
      % draw response prompt
      Screen('DrawTexture', w, expoKeyImg, [], expoKeyImgRect);
    end
    % draw fixation after response
    Screen('TextSize', w, cfg.text.fixSize);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  end
  
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % clear screen
  Screen('Flip', w);
  
  % Close the image stimulus before next trial
  Screen('Close', expoImgTex(i));
  
  % compute response time
  if phaseCfg.respDuringStim
    measureRTfromHere = stimOnset;
  else
    measureRTfromHere = startRT;
  end
  rt = int32(round(1000 * (endRT - measureRTfromHere)));
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: response: %s (key: %s; rt = %d)\n',i,length(expoStims_img),resp,respKey,rt);
  end
  
  % img stimulus properties
  i_catNum = int32(expoStims_img(i).categoryNum);
  i_stimNum = int32(expoStims_img(i).stimNum);
  % both stimuli
  targStatus = expoStims_img(i).targ;
  spacStatus = expoStims_img(i).spaced;
  studyLag = int32(expoStims_img(i).lag);
  
  %% session log file
  
  % TODO: put image and word in correct order
  
  % Write image stimulus presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'EXPO_IMAGE',...
    i,...
    expoStims_img(i).fileName,...
    i_stimNum,...
    targStatus,...
    spacStatus,...
    studyLag,...
    int32(expoStims_img(i).presNum),...
    int32(expoStims_img(i).pairNum),...
    int32(expoStims_img(i).pairOrd),...
    expoStims_img(i).categoryStr,...
    i_catNum);
  
  % Write trial result to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'EXPO_RESP',...
    i,...
    resp,...
    respKey,...
    rt);
  
  %% phase log file
  
  % Write image stimulus presentation to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'EXPO_IMAGE',...
    i,...
    expoStims_img(i).fileName,...
    i_stimNum,...
    targStatus,...
    spacStatus,...
    studyLag,...
    int32(expoStims_img(i).presNum),...
    int32(expoStims_img(i).pairNum),...
    int32(expoStims_img(i).pairOrd),...
    expoStims_img(i).categoryStr,...
    i_catNum);
  
  % Write trial result to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'EXPO_RESP',...
    i,...
    resp,...
    respKey,...
    rt);
  
  %% Write netstation logs
  
  if expParam.useNS
    % Write trial info to et_NetStation
    % mark every event with the following key code/value pairs
    % 'subn', subject number
    % 'sess', session type
    % 'phas', session phase name
    % 'pcou', phase count
    % 'expt', whether this is the experiment (1) or practice (0)
    % 'trln', trial number
    % 'istm', image stimulus name
    % 'inum', image stimulus number
    % 'icts', image category string
    % 'ictn', image category number
    % 'targ', whether this is a target (1) or a lure (0)
    % 'spac', whether it was spaced (1) or not (0; massed or single pres)
    % 'slag', the spacing lag (>0=spaced, 0=massed, -1=single pres)
    % 'rsps', response string
    % 'rspk', the name of the key pressed
    % 'rspt', the response time
    % 'keyp', key pressed?(1=yes, 0=no)
    
    if ~isnan(preStimFixOn)
      % pre-stim1 fixation
      [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'trln', int32(i),...
        'istm', expoStims_img(i).fileName, 'inum', i_stimNum, 'icts', expoStims_img(i).categoryStr, 'ictn', i_catNum,...
        'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % image presentation
    [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', imgOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
      'expt', phaseCfg.isExp, 'trln', int32(i), 'type', 'image',...
      'istm', expoStims_img(i).fileName, 'inum', i_stimNum, 'icts', expoStims_img(i).categoryStr, 'ictn', i_catNum,...
      'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    if ~isnan(respPromptOn)
      % response prompt
      [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'trln', int32(i),...
        'istm', expoStims_img(i).fileName, 'inum', i_stimNum, 'icts', expoStims_img(i).categoryStr, 'ictn', i_catNum,...
        'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % did they make a response?
    if keyIsDown
      % button push
      [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'trln', int32(i), 'type', 'image',...
        'istm', expoStims_img(i).fileName, 'inum', i_stimNum, 'icts', expoStims_img(i).categoryStr, 'ictn', i_catNum,...
        'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
  end % useNS
  
  % mark that we finished this trial
  trialComplete(i) = true;
  % save progress after each trial
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

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

% release any remaining textures
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

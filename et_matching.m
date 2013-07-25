function [cfg,expParam] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_matching(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
%
% Description:
%  This function runs the matching task. There are no blocks, only short
%  (blink) breaks.
%  TODO: Maybe add a longer break in the middle and tell subjects that this
%  is the middle of the experiment.
%
%  The stimuli for the matching task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phaseName).allStims as a
%  struct.
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
% NB:
%  Field 'matchStimNum' denotes whether a stimulus is stim1 or stim2.
%  Field 'matchPairNum' denotes which two stimuli are paired. matchPairNum
%   overlaps in the same and different condition
%
% NB:
%  When same and diff stimuli are combined, to find the corresponding pair
%  search for a matching familyNum (basic or subordinate), a matching or
%  different speciesNum field (same or diff condition), a matching or
%  different trained field, the same matchPairNum, and the opposite
%  matchStimNum (1 or 2).

% % durations, in seconds
% cfg.stim.(sesName).(phaseName).match_isi = 0.0;
% cfg.stim.(sesName).(phaseName).match_stim1 = 0.8;
% cfg.stim.(sesName).(phaseName).match_stim2 = 0.8;
% % random intervals are generated on the fly
% cfg.stim.(sesName).(phaseName).match_preStim1 = [0.5 0.7];
% cfg.stim.(sesName).(phaseName).match_preStim2 = [1.0 1.2];
% cfg.stim.(sesName).(phaseName).match_response = 2.0;

% % keys
% cfg.keys.matchSame
% cfg.keys.matchDiff

fprintf('Running %s %s (match) (%d)...\n',sesName,phaseName,phaseCount);

%% set the starting date and time for this phase
thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% determine the starting trial, useful for resuming

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_match_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).allStims([expParam.session.(sesName).(phaseName)(phaseCount).allStims.matchStimNum] == 2)));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
else
  fprintf('All trials for %s %s (match) (%d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount);
  % release any remaining textures
  Screen('Close');
  return
end

%% start the log file for this phase

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_match_%d.txt',sesName,phaseName,phaseCount));
plf = fopen(phaseLogFile,'at');

%% record the starting date and time for this phase

expParam.session.(sesName).(phaseName)(phaseCount).date = thisDate;
expParam.session.(sesName).(phaseName)(phaseCount).startTime = startTime;

% put it in the log file
fprintf(logFile,'!!! Start of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);
fprintf(plf,'!!! Start of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);

thisGetSecs = GetSecs;
fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_START');

fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_START');

%% preparation

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
allStims = expParam.session.(sesName).(phaseName)(phaseCount).allStims;

if phaseCfg.isExp
  stimDir = cfg.files.stimDir;
else
  stimDir = cfg.files.stimDir_prac;
end

% set feedback text
correctFeedback = 'Correct!';
incorrectFeedback = 'Incorrect!';
sameFeedback =  'SAME';
diffFeedback =  'DIFFERENT';

% set feedback colors
correctColor = uint8((rgb('Green') * 255) + 0.5);
incorrectColor = uint8((rgb('Red') * 255) + 0.5);

% if we're using matchTextPrompt
if phaseCfg.matchTextPrompt
  if strcmp(KbName(cfg.keys.matchSame),'f') || strcmp(KbName(cfg.keys.matchSame),'r')
    leftKey = cfg.text.matchSame;
    rightKey = cfg.text.matchDiff;
  elseif strcmp(KbName(cfg.keys.matchSame),'j') || strcmp(KbName(cfg.keys.matchSame),'u')
    leftKey = cfg.text.matchDiff;
    rightKey = cfg.text.matchSame;
  end
end

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
    cfg.correctSound = 1000;
  end
  if ~isfield(phaseCfg,'incorrectSound')
    cfg.incorrectSound = 300;
  end
  if ~isfield(phaseCfg,'correctVol')
    cfg.correctVol = 0.4;
  end
  if ~isfield(phaseCfg,'incorrectVol')
    cfg.incorrectVol = 0.6;
  end
end

%% preload all stimuli for presentation

% get the stimulus 2s
stim2 = allStims([allStims.matchStimNum] == 2);
% initialize for storing stimulus 1s
stim1 = struct([]);
fn = fieldnames(stim2);
for i = 1:length(fn)
  stim1(1).(fn{i}) = [];
end

stim1Tex = nan(1,length(stim2));
stim2Tex = nan(1,length(stim2));

message = sprintf('Preparing images, please wait...');
Screen('TextSize', w, cfg.text.basicTextSize);
% put the "preparing" message on the screen
DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
% Update the display to show the message:
Screen('Flip', w);

for i = 1:length(stim2)
  % find stim2's corresponding pair, contingent upon whether this is a same
  % or diff stimulus
  if stim2(i).same
    % same (same species)
    stim1(i) = allStims(...
      ([allStims.familyNum] == stim2(i).familyNum) &...
      ([allStims.speciesNum] == stim2(i).speciesNum) &...
      ([allStims.trained] == stim2(i).trained) &...
      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
    
  else
    % diff (different species)
    stim1(i) = allStims(...
      ([allStims.familyNum] == stim2(i).familyNum) &...
      ([allStims.speciesNum] ~= stim2(i).speciesNum) &...
      ([allStims.trained] == stim2(i).trained) &...
      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
  end
  
  % load up stim2's texture
  stim2ImgFile = fullfile(stimDir,stim2(i).familyStr,stim2(i).fileName);
  if exist(stim2ImgFile,'file')
    stim2Img = imread(stim2ImgFile);
    stim2Tex(i) = Screen('MakeTexture',w,stim2Img);
    % TODO: optimized?
    %stim2tex(i) = Screen('MakeTexture',w,stim2Img,[],1);
  else
    error('Study stimulus %s does not exist!',stim2ImgFile);
  end
  
  % load up stim1's texture
  stim1ImgFile = fullfile(stimDir,stim1(i).familyStr,stim1(i).fileName);
  if exist(stim1ImgFile,'file')
    stim1Img = imread(stim1ImgFile);
    stim1Tex(i) = Screen('MakeTexture',w,stim1Img);
    % TODO: optimized?
    %stim1tex(i) = Screen('MakeTexture',w,stim1Img,[],1);
  else
    error('Study stimulus %s does not exist!',stim1ImgFile);
  end
end

% get the width and height of the final stimulus image
stimImgHeight = size(stim1Img,1) * cfg.stim.stimScale;
stimImgWidth = size(stim1Img,2) * cfg.stim.stimScale;
% set the stimulus image rectangle
stimImgRect = [0 0 stimImgWidth stimImgHeight];
stimImgRect = CenterRect(stimImgRect, cfg.screen.wRect);

% text location for error (e.g., "too fast") text
[~,errorTextY] = RectCenter(cfg.screen.wRect);
errorTextY = errorTextY + (stimImgHeight / 2);

%% do an impedance check before the phase begins, if desired

if ~isfield(phaseCfg,'impedanceBeforePhase')
  phaseCfg.impedanceBeforePhase = false;
end

if expParam.useNS && phaseCfg.impedanceBeforePhase
  % run the impedance break
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
  et_impedanceCheck(w, cfg, false);
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
end

%% start NS recording, if desired

% put a message on the screen as experiment phase begins
message = 'Starting matching phase...';
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = 'Starting data acquisition for matching phase...';
  
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'NS_REC_START');
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'NS_REC_START');
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

%% show the instructions

for i = 1:length(phaseCfg.instruct.match)
  WaitSecs(1.000);
  et_showTextInstruct(w,phaseCfg.instruct.match(i),cfg.keys.instructContKey,...
    cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
end

% Wait a second before starting trial
WaitSecs(1.000);

%% run the matching task

% only check these keys
RestrictKeysForKbCheck([cfg.keys.matchSame, cfg.keys.matchDiff]);

% start the blink break timer
if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
  blinkTimerStart = GetSecs;
end

for i = trialNum:length(stim2Tex)
  % do an impedance check after a certain number of trials
  if expParam.useNS && phaseCfg.isExp && i > 1 && i < length(stim2Tex) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
    % run the impedance break
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
    fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
    et_impedanceCheck(w, cfg, true);
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
    fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');    
    % reset the blink timer
    if cfg.stim.secUntilBlinkBreak > 0
      blinkTimerStart = GetSecs;
    end
  end
  
  % Do a blink break if recording EEG and specified time has passed
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(stim2Tex) - 3)
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_START');
    fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_START');
    Screen('TextSize', w, cfg.text.basicTextSize);
    pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(stim2Tex));
    % just draw straight into the main window since we don't need speed here
    DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % wait for kb release in case subject is holding down keys
    KbReleaseWait;
    KbWait(-1); % listen for keypress on either keyboard
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_END');
    fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_END');
    
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('Flip',w);
    WaitSecs(0.5);
    % reset the timer
    blinkTimerStart = GetSecs;
  end
  
  % Is this a subordinate (1) or basic (0) family/species? If subordinate,
  % get the species number.
  if phaseCfg.isExp
    famNumSubord = cfg.stim.practice.famNumSubord;
    famNumBasic = cfg.stim.practice.famNumBasic;
  else
    famNumSubord = cfg.stim.practice.famNumSubord;
    famNumBasic = cfg.stim.practice.famNumBasic;
  end
  if any(stim2(i).familyNum == famNumSubord)
    isSubord = true;
    specNum1 = int32(stim1(i).speciesNum);
    specNum2 = int32(stim2(i).speciesNum);
  elseif any(stim2(i).familyNum == famNumBasic)
    isSubord = false;
    specNum1 = int32(0);
    specNum2 = int32(0);
  end
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.match_isi > 0
    WaitSecs(phaseCfg.match_isi);
  end
  
  % draw fixation
  Screen('TextSize', w, cfg.text.fixSize);
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  [preStim1FixOn] = Screen('Flip',w);
  
  % fixation on screen before stim1 for a random amount of time
  WaitSecs(phaseCfg.match_preStim1(1) + ((phaseCfg.match_preStim1(2) - phaseCfg.match_preStim1(1)).*rand(1,1)));
  
  % draw the stimulus
  Screen('DrawTexture', w, stim1Tex(i), [], stimImgRect);
  % and fixation on top of it
  Screen('TextSize', w, cfg.text.fixSize);
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [img1On, stim1Onset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: stim1 (%s): family %d (%s), species %d (%s), exemplar %d (%d). Same (1) or diff (0): %d.\n',i,length(stim2Tex),stim1(i).fileName,stim1(i).familyNum,stim1(i).familyStr,stim1(i).speciesNum,stim1(i).speciesStr,stim1(i).exemplarNum,stim1(i).exemplarName,stim1(i).same);
  end
  
  % while loop to show stimulus until "duration" seconds elapsed.
  while (GetSecs - stim1Onset) <= phaseCfg.match_stim1
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % draw fixation
  Screen('TextSize', w, cfg.text.fixSize);
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  [preStim2FixOn] = Screen('Flip',w);
  
  % fixation on screen before stim2 for a random amount of time
  WaitSecs(phaseCfg.match_preStim2(1) + ((phaseCfg.match_preStim2(2) - phaseCfg.match_preStim2(1)).*rand(1,1)));
  
  % draw the stimulus
  Screen('DrawTexture', w, stim2Tex(i), [], stimImgRect);
  % and fixation on top of it
  Screen('TextSize', w, cfg.text.fixSize);
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [img2On, stim2Onset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: stim2 (%s): family %d (%s), species %d (%s), exemplar %d (%d). Same (1) or diff (0): %d.\n',i,length(stim2Tex),stim2(i).fileName,stim2(i).familyNum,stim2(i).familyStr,stim2(i).speciesNum,stim2(i).speciesStr,stim2(i).exemplarNum,stim2(i).exemplarName,stim2(i).same);
  end
  
  % while loop to show stimulus until subjects response or until
  % "duration" seconds elapsed.
  while (GetSecs - stim2Onset) <= phaseCfg.match_stim2
    % check for too-fast response in practice only
    if ~phaseCfg.isExp
      [keyIsDown] = KbCheck;
      % if they press a key too early, tell them they responded too fast
      if keyIsDown
        Screen('DrawTexture', w, stim2Tex(i), [], stimImgRect);
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('Flip', w);
      end
    end
    
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % draw response prompt
  Screen('TextSize', w, cfg.text.fixSize);
  if phaseCfg.matchTextPrompt
    responsePromptText = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
    DrawFormattedText(w,responsePromptText,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  else
    DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  end
  [respPromptOn, startRT] = Screen('Flip',w);
  
  % poll for a resp
  while 1
    if (GetSecs - startRT) > phaseCfg.match_response
      break
    end
    
    [keyIsDown, endRT, keyCode] = KbCheck;
    % if they push more than one key, don't accept it
    if keyIsDown && sum(keyCode) == 1
      % wait for key to be released, or time limit
      while KbCheck(-1)
        WaitSecs(0.0001);
        
        % % proceed if time is up, regardless of whether key is held
        % if (GetSecs - startRT) > phaseCfg.match_response
        %   break
        % end
      end
      % if cfg.text.printTrialInfo
      %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
      % end
      if (keyCode(cfg.keys.matchSame) == 1 && all(keyCode(~cfg.keys.matchSame) == 0)) ||...
          (keyCode(cfg.keys.matchDiff) == 1 && all(keyCode(~cfg.keys.matchDiff) == 0))
        break
      end
    elseif keyIsDown && sum(keyCode) > 1
      % draw response prompt
      Screen('TextSize', w, cfg.text.fixSize);
      if phaseCfg.matchTextPrompt
        responsePromptText = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
        DrawFormattedText(w,responsePromptText,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      else
        DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
  
  % determine response and compute accuracy
  if keyIsDown
    if (keyCode(cfg.keys.matchSame) == 1 && all(keyCode(~cfg.keys.matchSame) == 0))
      resp = 'same';
      if stim1(i).same
        acc = true;
        if ~phaseCfg.isExp
          message = sprintf('%s\n%s',correctFeedback,sameFeedback);
          if phaseCfg.playSound
            respSound = phaseCfg.correctSound;
            respVol = phaseCfg.correctVol;
          end
        end
        feedbackColor = correctColor;
      else
        acc = false;
        if ~phaseCfg.isExp
          message = sprintf('%s\n%s',incorrectFeedback,diffFeedback);
          if phaseCfg.playSound
            respSound = phaseCfg.incorrectSound;
            respVol = phaseCfg.incorrectVol;
          end
        end
        feedbackColor = incorrectColor;
      end
    elseif (keyCode(cfg.keys.matchDiff) == 1 && all(keyCode(~cfg.keys.matchDiff) == 0))
      resp = 'diff';
      if ~stim1(i).same
        acc = true;
        if ~phaseCfg.isExp
          message = sprintf('%s\n%s',correctFeedback,diffFeedback);
          if phaseCfg.playSound
            respSound = phaseCfg.correctSound;
            respVol = phaseCfg.correctVol;
          end
        end
        feedbackColor = correctColor;
      else
        acc = false;
        if ~phaseCfg.isExp
          message = sprintf('%s\n%s',incorrectFeedback,sameFeedback);
          if phaseCfg.playSound
            respSound = phaseCfg.incorrectSound;
            respVol = phaseCfg.correctVol;
          end
        end
        feedbackColor = incorrectColor;
      end
    elseif sum(keyCode) > 1
      warning('Multiple keys were pressed.\n');
      resp = 'ERROR_MULTIKEY';
    elseif sum(~ismember(find(keyCode == 1),[cfg.keys.matchDiff cfg.keys.matchSame])) > 0
      warning('Key other than same/diff was pressed. This should not happen.\n');
      resp = 'ERROR_OTHERKEY';
    else
      warning('Some other error occurred.\n');
      resp = 'ERROR_OTHER';
    end
    if ~phaseCfg.isExp
      feedbackTime = cfg.text.respondFasterFeedbackTime;
    else
      message = '';
      feedbackTime = 0.01;
    end
  else
    resp = 'none';
    % did not push a key
    acc = false;
    
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
  
  if phaseCfg.playSound && (~phaseCfg.isExp || (phaseCfg.isExp && ~keyIsDown))
    Beeper(respSound,respVol);
  end
  Screen('TextSize', w, cfg.text.instructTextSize);
  DrawFormattedText(w,message,'center','center',feedbackColor, cfg.text.instructCharWidth);
  Screen('Flip', w);
  % wait to let them view the feedback
  WaitSecs(feedbackTime);
  
  % get key pressed by subject
  if keyIsDown
    if sum(keyCode) == 1
      respKey = KbName(keyCode);
    elseif sum(keyCode) > 1
      thisResp = KbName(keyCode);
      respKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisResp)),thisResp{:}));
    end
  else
    respKey = 'none';
  end
  
  % Clear screen to background color after response
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', stim1Tex(i));
  Screen('Close', stim2Tex(i));
  
  % compute response time
  rt = int32(round(1000 * (endRT - startRT)));
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: same (1) or diff (0): %d. response: %s (key: %s) (acc = %d)\n',i,length(stim2Tex),stim1(i).same,resp,respKey,acc);
  end
  
  fNum1 = int32(stim1(i).familyNum);
  fNum2 = int32(stim2(i).familyNum);
  
  %% session log file
  
  % Write stim1 presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%i\t%s\t%i\t%s\t%s\t%i\t%i\t%i\t%i\t%i\t%i\n',...
    img1On,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'MATCH_STIM1',...
    i,...
    stim1(i).familyStr,...
    stim1(i).speciesStr,...
    stim1(i).exemplarName,...
    isSubord,...
    fNum1,...
    specNum1,...
    stim1(i).trained,...
    stim1(i).same);
  
  % Write stim2 presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%i\t%s\t%i\t%s\t%s\t%i\t%i\t%i\t%i\t%i\t%i\n',...
    img2On,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'MATCH_STIM2',...
    i,...
    stim2(i).familyStr,...
    stim2(i).speciesStr,...
    stim2(i).exemplarName,...
    isSubord,...
    fNum2,...
    specNum2,...
    stim2(i).trained,...
    stim2(i).same);
  
  % Write trial result to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%i\t%s\t%i\t%i\t%i\t%i\t%s\t%s\t%i\t%i\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'MATCH_RESP',...
    i,...
    isSubord,...
    stim2(i).trained,...
    stim2(i).same,...
    resp,...
    respKey,...
    acc,...
    rt);
  
  %% phase log file
  
  % Write stim1 presentation to file:
  fprintf(plf,'%f\t%s\t%s\t%s\t%i\t%s\t%i\t%s\t%s\t%i\t%i\t%i\t%i\t%i\t%i\n',...
    img1On,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'MATCH_STIM1',...
    i,...
    stim1(i).familyStr,...
    stim1(i).speciesStr,...
    stim1(i).exemplarName,...
    isSubord,...
    fNum1,...
    specNum1,...
    stim1(i).trained,...
    stim1(i).same);
  
  % Write stim2 presentation to file:
  fprintf(plf,'%f\t%s\t%s\t%s\t%i\t%s\t%i\t%s\t%s\t%i\t%i\t%i\t%i\t%i\t%i\n',...
    img2On,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'MATCH_STIM2',...
    i,...
    stim2(i).familyStr,...
    stim2(i).speciesStr,...
    stim2(i).exemplarName,...
    isSubord,...
    fNum2,...
    specNum2,...
    stim2(i).trained,...
    stim2(i).same);
  
  % Write trial result to file:
  fprintf(plf,'%f\t%s\t%s\t%s\t%i\t%s\t%i\t%i\t%i\t%i\t%s\t%s\t%i\t%i\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'MATCH_RESP',...
    i,...
    isSubord,...
    stim2(i).trained,...
    stim2(i).same,...
    resp,...
    respKey,...
    acc,...
    rt);
  
  %% Write netstation logs
  
  if expParam.useNS
    % Write trial info to et_NetStation
    % mark every event with the following key code/value pairs
    % 'subn', subject number
    % 'sess', session type
    % 'phase', session phase name
    % 'expt', whether this is the experiment (1) or practice (0)
    % 'trln', trial number
    % 'stmn', stimulus name (family, species, exemplar)
    % 'famn', family number
    % 'spcn', species number (corresponds to keyboard)
    % 'sord', whether this is a subordinate (1) or basic (0) level family
    % 'trai', whether this is a trained (1) or untrained (0) stimulus
    % 'same', whether this is a same (1) or different (0) trial
    % 'rsps', response string
    % 'rspk', the name of the key pressed
    % 'rspt', the response time
    % 'corr', accuracy code (1=correct, 0=incorrect)
    % 'keyp', key pressed?(1=yes, 0=no)
    
    % only for response prompt and response events
    % 'stm1', stimulus 1 name (family, species, exemplar)
    % 'stm2', stimulus 2 name (family, species, exemplar)
    % 'fam1', stimulus 1 family
    % 'fam2', stimulus 2 family
    % 'spc1', stimulus 1 species
    % 'spc2', stimulus 2 species
    
    % write out the stimulus name
    stim1Name = sprintf('%s%s%d',...
      stim1(i).familyStr,...
      stim1(i).speciesStr,...
      stim1(i).exemplarName);
    stim2Name = sprintf('%s%s%d',...
      stim2(i).familyStr,...
      stim2(i).speciesStr,...
      stim2(i).exemplarName);
  
    % pre-stim1 fixation
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', preStim1FixOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'trln', int32(i), 'stmn', stim1Name, 'famn', fNum1, 'spcn', specNum1,...
      'sord', isSubord, 'trai', stim1(i).trained, 'same', stim1(i).same,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    % stim1 presentation
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', img1On, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'trln', int32(i), 'stmn', stim1Name, 'famn', fNum1, 'spcn', specNum1,...
      'sord', isSubord, 'trai', stim1(i).trained, 'same', stim1(i).same,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    % pre-stim2 fixation
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', preStim2FixOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'trln', int32(i), 'stmn', stim2Name, 'famn', fNum2, 'spcn', specNum2,...
      'sord', isSubord, 'trai', stim2(i).trained, 'same', stim1(i).same,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    % stim2 presentation
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', img2On, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'trln', int32(i), 'stmn', stim2Name, 'famn', fNum2, 'spcn', specNum2,...
      'sord', isSubord, 'trai', stim2(i).trained, 'same', stim1(i).same,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    % response prompt
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'PROM', respPromptOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'trln', int32(i),...
      'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
      'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    % did they make a response?
    if keyIsDown
      % button push
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'RESP', endRT, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'trln', int32(i),...
      'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
      'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
  end % useNS
  
  % mark that we finished this trial
  trialComplete(i) = true;
  % save progress after each trial
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

%% cleanup

% stop recording
if expParam.useNS
  WaitSecs(5.0);
  [NSSyncStatus, NSSyncError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
  
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'NS_REC_STOP');
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'NS_REC_STOP');
end

% reset the KbCheck
RestrictKeysForKbCheck([]);

% release any remaining textures
Screen('Close');

thisGetSecs = GetSecs;
fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_END');

fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',...
  thisGetSecs,...
  expParam.subject,...
  sesName,...
  phaseName,...
  cfg.stim.(sesName).(phaseName)(phaseCount).isExp,...
  'PHASE_END');

% record the end time for this session
endTime = fix(clock);
endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6));
expParam.session.(sesName).(phaseName)(phaseCount).endTime = endTime;
% put it in the log file
fprintf(logFile,'!!! End of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);
fprintf(plf,'!!! End of %s %s (%d) (%s) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);

% close the phase log file
fclose(plf);

% save progress after finishing phase
phaseComplete = true; %#ok<NASGU>
save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');

end % function

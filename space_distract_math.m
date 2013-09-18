function [cfg,expParam] = space_distract_math(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = space_distract_math(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
%
% Description:
%  This function runs the math distractor task. There are no blocks, only
%  short (blink) breaks.
%  TODO: Maybe add a longer break in the middle and tell subjects that this
%  is the middle of the experiment.
%
%
% Inputs:
%
%
% Outputs:
%
%
%

% % durations, in seconds

% % keys

fprintf('Running %s %s (distMath) (%d)...\n',sesName,phaseName,phaseCount);

%% set the starting date and time for this phase
thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% determine the starting trial, useful for resuming

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_distMath_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,cfg.stim.(sesName).(phaseName)(phaseCount).dist_nProbs);
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
else
  fprintf('All trials for %s %s (distMath) (%d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount);
  % release any remaining textures
  Screen('Close');
  return
end

%% start the log file for this phase

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_distMath_%d.txt',sesName,phaseName,phaseCount));
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

% studyStims_img = expParam.session.(sesName).(phaseName)(phaseCount).studyStims_img;
% studyStims_word = expParam.session.(sesName).(phaseName)(phaseCount).studyStims_word;
%
% if phaseCfg.isExp
%   imgStimDir = cfg.files.imgStimDir;
% else
%   imgStimDir = cfg.files.imgStimDir_prac;
% end
%
% % default is to preload the images
% if ~isfield(cfg.stim,'preloadImages')
%   cfg.stim.preloadImages = false;
% end
%
% % if we're using textPrompt
% if phaseCfg.textPrompt
%   if strcmp(KbName(cfg.keys.judgeSame),'f') || strcmp(KbName(cfg.keys.judgeSame),'r')
%     leftKey = cfg.text.judgeSame;
%     rightKey = cfg.text.judgeDiff;
%   elseif strcmp(KbName(cfg.keys.judgeSame),'j') || strcmp(KbName(cfg.keys.judgeSame),'u')
%     leftKey = cfg.text.judgeDiff;
%     rightKey = cfg.text.judgeSame;
%   end
% end

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
%   phaseCfg.respDuringStim = true;
% end
%
% % default is to show fixation during ISI
% if ~isfield(phaseCfg,'fixDuringISI')
%   phaseCfg.fixDuringISI = true;
% end
% % default is to show fixation during preStim
% if ~isfield(phaseCfg,'fixDuringPreStim')
%   phaseCfg.fixDuringPreStim = true;
% end
% % default is to show fixation with the stimulus
% if ~isfield(phaseCfg,'fixDuringStim')
%   phaseCfg.fixDuringStim = true;
% end

% %% preload all stimuli for presentation
%
% studyImgTex = nan(1,length(studyStims_img));
%
% if cfg.stim.preloadImages
%   message = sprintf('Preparing images, please wait...');
%   Screen('TextSize', w, cfg.text.basicTextSize);
%   % put the "preparing" message on the screen
%   DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
% end
% % Update the display to show the message:
% Screen('Flip', w);
%
% % initialize to store image stimulus parameters
% stimImgRect_all = nan(length(studyStims_img),4);
% errorTextY_all = nan(length(studyStims_img),1);
% wordStimY_all = nan(length(studyStims_img),1);
% responsePromptY_all = nan(length(studyStims_img),1);
%
% for i = 1:length(studyStims_img)
%   % make sure image stimulus exists
%   stimImgFile = fullfile(imgStimDir,studyStims_img(i).categoryStr,studyStims_img(i).fileName);
%   if exist(stimImgFile,'file')
%     % load up stim's texture
%     stimImg = imread(stimImgFile);
%
%     % set the coordinates that we will use later
%     stimImgHeight = size(stimImg,1) * cfg.stim.stimScale;
%     stimImgWidth = size(stimImg,2) * cfg.stim.stimScale;
%     % set the stimulus image rectangle
%     stimImgRect_all(i,:) = [0 0 stimImgWidth stimImgHeight];
%     stimImgRect_all(i,:) = CenterRect(stimImgRect_all(i,:), cfg.screen.wRect);
%
%     % text location for error (e.g., "too fast") text
%     [~,screenCenter] = RectCenter(cfg.screen.wRect);
%     errorTextY_all(i) = screenCenter + (stimImgHeight / 2);
%
%     % text location for word stimulus
%     wordStimY_all(i) = screenCenter + (stimImgHeight / 2);
%
%     % text location for response prompt
%     responsePromptY_all(i) = screenCenter + (stimImgHeight / 2) + (screenCenter * 0.05);
%
%     if cfg.stim.preloadImages
%       studyImgTex(i) = Screen('MakeTexture',w,stimImg);
%       % TODO: optimized?
%       %studyImgTex(i) = Screen('MakeTexture',w,stimImg,[],1);
%     %elseif ~cfg.stim.preloadImages && i == length(studyStims_img)
%     %  % still need to load the last image to set the rectangle
%     %  stimImg = imread(stimImgFile);
%     end
%   else
%     error('Study stimulus %s does not exist!',stimImgFile);
%   end
% end

% % get the width and height of the final stimulus image
% stimImgHeight = size(stimImg,1) * cfg.stim.stimScale;
% stimImgWidth = size(stimImg,2) * cfg.stim.stimScale;
% % set the stimulus image rectangle
% stimImgRect = [0 0 stimImgWidth stimImgHeight];
% stimImgRect = CenterRect(stimImgRect, cfg.screen.wRect);
%
% % text location for error (e.g., "too fast") text
% [~,screenCenter] = RectCenter(cfg.screen.wRect);
% errorTextY = screenCenter + (stimImgHeight / 2);
%
% % text location for word stimulus
% wordStimY = screenCenter + (stimImgHeight / 2);
%
% % text location for response prompt
% responsePromptY = screenCenter + (stimImgHeight / 2) + (screenCenter * 0.05);

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
message = 'Starting math phase...';
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = 'Starting data acquisition for math phase...';
  
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

%% show the instructions

for i = 1:length(phaseCfg.instruct.dist)
  WaitSecs(1.000);
  et_showTextInstruct(w,phaseCfg.instruct.dist(i),cfg.keys.instructContKey,...
    cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
end

% Wait a second before starting trial
WaitSecs(1.000);

%% run the multistudy task

% % only check these keys
% RestrictKeysForKbCheck(KbName(cfg.keys.distMathKeyNames));

% % start the blink break timer
% if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
%   blinkTimerStart = GetSecs;
% end

mathStartTime = GetSecs;

for i = trialNum:phaseCfg.dist_nProbs
  %   % do an impedance check after a certain number of trials
  %   if expParam.useNS && phaseCfg.isExp && i > 1 && i < phaseCfg.dist_nProbs && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
  %     % run the impedance break
  %     thisGetSecs = GetSecs;
  %     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  %     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  %     thisGetSecs = et_impedanceCheck(w, cfg, true);
  %     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
  %     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
  %
  %     % % only check these keys
  %     % RestrictKeysForKbCheck([cfg.keys.judgeSame, cfg.keys.judgeDiff]);
  %
  %     % reset the blink timer
  %     if cfg.stim.secUntilBlinkBreak > 0
  %       blinkTimerStart = GetSecs;
  %     end
  %   end
  %
  %   % Do a blink break if recording EEG and specified time has passed
  %   if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (phaseCfg.dist_nProbs - 3)
  %     thisGetSecs = GetSecs;
  %     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
  %     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
  %     Screen('TextSize', w, cfg.text.basicTextSize);
  %     if expParam.useNS
  %       pauseMsg = 'Blink now.\n\n';
  %     else
  %       pauseMsg = '';
  %     end
  %     pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, phaseCfg.dist_nProbs);
  %     % just draw straight into the main window since we don't need speed here
  %     DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
  %     Screen('Flip', w);
  %
  %     % listen for any keypress on any keyboard
  %     RestrictKeysForKbCheck([]);
  %     thisGetSecs = KbWait(-1,2);
  %     %thisGetSecs = GetSecs;
  %     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
  %     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
  %     % % only check these keys
  %     % RestrictKeysForKbCheck([cfg.keys.judgeSame, cfg.keys.judgeDiff]);
  %
  %     if (phaseCfg.dist_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.dist_isi == 0 && phaseCfg.fixDuringPreStim)
  %       Screen('TextSize', w, cfg.text.fixSize);
  %       DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  %     end
  %     Screen('Flip',w);
  %     WaitSecs(0.5);
  %     % reset the timer
  %     blinkTimerStart = GetSecs;
  %   end
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.dist_isi > 0
    %if phaseCfg.fixDuringISI
    %  Screen('TextSize', w, cfg.text.fixSize);
    %  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    %  Screen('Flip',w);
    %end
    WaitSecs(phaseCfg.dist_isi);
  end
  
  % preStimulus period, with fixation if desired
  if length(phaseCfg.dist_preStim) == 1
    if phaseCfg.dist_preStim > 0
      Screen('Flip',w);
      WaitSecs(phaseCfg.dist_preStim);
    end
  elseif length(phaseCfg.dist_preStim) == 2
    if ~all(phaseCfg.dist_preStim == 0)
      Screen('Flip',w);
      % screen before stim for a random amount of time
      WaitSecs(phaseCfg.dist_preStim(1) + ((phaseCfg.dist_preStim(2) - phaseCfg.dist_preStim(1)).*rand(1,1)));
    end
  end
  
  % choose the numbers for the math problem
  if phaseCfg.dist_plusMinus
    theseVars = randi([-phaseCfg.dist_maxNum phaseCfg.dist_maxNum],1,phaseCfg.dist_nVar);
    if any(theseVars == 0)
      tvZero = find(theseVars == 0);
      for tv = 1:length(tvZero)
        theseVars(tvZero(tv)) = randperm(phaseCfg.dist_maxNum,1);
      end
    end
  else
    theseVars = randi([phaseCfg.dist_minNum phaseCfg.dist_maxNum],1,phaseCfg.dist_nVar);
  end
  
  % create the string to be shown on the screen
  tv_str = sprintf('%d',theseVars(1));
  for tv = 2:length(theseVars)
    if theseVars(tv) > 0
      addSign = '+';
    elseif theseVars(tv) < 0
      addSign = '-';
    end
    tv_str = sprintf('%s %s %d',tv_str,addSign,abs(theseVars(tv)));
  end
  tv_str = sprintf('%s =',tv_str);
  
  % display it
  [screenCenterX,screenCenterY] = RectCenter(cfg.screen.wRect);
  screenCenterX = screenCenterX * 0.85;
  Screen('TextSize', w, cfg.text.basicTextSize);
  Screen('DrawText', w, tv_str,screenCenterX,screenCenterY,cfg.text.basicTextColor);
  [probOn, probOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s %d.\n',i,phaseCfg.dist_nProbs,tv_str,sum(theseVars));
  end
  
  useKbCheck = false;
  
  % get their answer and type it to the screen
  resp = '';
  if ~useKbCheck
    % Flush the keyboard buffer:
    FlushEvents;
  end
  while isempty(resp)
    while true
      %while (GetSecs - probOnset) <= phaseCfg.dist_response
      
      % reimplementing GetEchoString to get RT
      if useKbCheck
        [char, endRT] = GetKbChar; %#ok<UNRCH>
      else
        [char, endRT] = GetChar;
      end
      if isempty(char)
        return
      end
      
      switch (abs(char))
        case {13, 3, 10}
          % ctrl-C, enter, or return
          break
        case 8
          % backspace
          if ~isempty(resp)
            resp = resp(1:length(resp)-1);
          end
        otherwise
          if ismember(char, cfg.keys.distMathKeyNames)
            resp = [resp, char]; %#ok<AGROW>
          end
      end
      
      Screen('DrawText', w, sprintf('%s %s',tv_str,resp), screenCenterX, screenCenterY, cfg.text.basicTextColor);
      Screen('Flip', w);
      
      %     [keyIsDown, endRT, keyCode] = KbCheck;
      %
      %     % poll for a resp
      %     if keyIsDown
      %       while KbCheck(-1)
      %         WaitSecs(0.0001);
      %       end % wait for key to be released
      %
      %       %if keyCode(40) == 1 || any(keyCode(KbName('Return')) == 1) || (IsWin && keyCode(13) == 1)
      %       if any(keyCode(KbName('Return')) == 1) || keyCode(KbName('Enter')) == 1 || (IsWin && keyCode(13) == 1)
      %         if ~isempty(resp)
      %           break
      %         end
      %       else
      %         if keyCode(KbName('DELETE')) == 1 || (IsWin && keyCode(8) == 1)
      %           if ~isempty(resp)
      %             resp = resp(1:end-1);
      %           end
      %         elseif sum(keyCode) == 1 && ismember(KbName(keyCode), cfg.keys.distMathKeyNames)
      %           thisKey = KbName(keyCode);
      %           resp = sprintf('%s%s',resp,thisKey(1));
      %         end
      %         %DrawFormattedText(w,sprintf('%s %s',tv_str,resp),'center','center',cfg.text.basicTextColor, cfg.text.instructCharWidth);
      %         Screen('DrawText', w, sprintf('%s %s',tv_str,resp), screenCenterX, screenCenterY, cfg.text.basicTextColor);
      %         Screen('Flip', w);
      %
      %       end
      %     end
      
      %WaitSecs(0.0001);
    end
  end
  if ~isempty(resp)
    % only need the seconds
    endRT = endRT.secs;
  end
  
  %if ~keyIsDown
  if isempty(resp)
    if phaseCfg.playSound
      Beeper(phaseCfg.incorrectSound,phaseCfg.incorrectVol);
    end
    
    % "need to respond faster"
    Screen('TextSize', w, cfg.text.instructTextSize);
    DrawFormattedText(w,cfg.text.respondFaster,'center','center',cfg.text.respondFasterColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    acc = false;
    
    % need a new endRT
    endRT = GetSecs;
    
    % wait to let them view the feedback
    WaitSecs(cfg.text.respondFasterFeedbackTime);
  else
    % collect their answer
    theirAnswer = str2double(resp);
    
    % check their answer
    if theirAnswer == sum(theseVars)
      % right
      acc = true;
      if phaseCfg.playSound
        respSound = phaseCfg.correctSound;
        respVol = phaseCfg.correctVol;
      end
    elseif theirAnswer ~= sum(theseVars)
      % wrong
      acc = false;
      if phaseCfg.playSound
        respSound = phaseCfg.incorrectSound;
        respVol = phaseCfg.incorrectVol;
      end
    end
    
    if phaseCfg.playSound
      Beeper(respSound,respVol);
    end
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s %d. Their answer: %s. Accuracy: %d.\n',i,phaseCfg.dist_nProbs,tv_str,sum(theseVars),resp,acc);
    end
  end
  
  %   %% session log file
  %
  %   % Write stim1 presentation to file:
  %   fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
  %     probOn,...
  %     expParam.subject,...
  %     sesName,...
  %     phaseName,...
  %     phaseCount,...
  %     phaseCfg.isExp,...
  %     'STUDY_WORD',...
  %     i,...
  %     thisWord,...
  %     w_stimNum,...
  %     targStatus,...
  %     spacStatus,...
  %     studyLag,...
  %     int32(studyStims_word(i).presNum),...
  %     int32(studyStims_word(i).pairNum),...
  %     int32(studyStims_word(i).pairOrd));
  %
  %   % Write image stimulus presentation to file:
  %   fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
  %     imgOn,...
  %     expParam.subject,...
  %     sesName,...
  %     phaseName,...
  %     phaseCount,...
  %     phaseCfg.isExp,...
  %     'STUDY_IMAGE',...
  %     i,...
  %     studyStims_img(i).fileName,...
  %     i_stimNum,...
  %     targStatus,...
  %     spacStatus,...
  %     studyLag,...
  %     int32(studyStims_img(i).presNum),...
  %     int32(studyStims_img(i).pairNum),...
  %     int32(studyStims_img(i).pairOrd),...
  %     studyStims_img(i).categoryStr,...
  %     i_catNum);
  %
  %   % Write trial result to file:
  %   fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
  %     endRT,...
  %     expParam.subject,...
  %     sesName,...
  %     phaseName,...
  %     phaseCount,...
  %     phaseCfg.isExp,...
  %     'STUDY_RESP',...
  %     i,...
  %     resp,...
  %     respKey,...
  %     rt);
  %
  %   %% phase log file
  %
  %   % Write stim1 presentation to file:
  %   fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
  %     probOn,...
  %     expParam.subject,...
  %     sesName,...
  %     phaseName,...
  %     phaseCount,...
  %     phaseCfg.isExp,...
  %     'STUDY_WORD',...
  %     i,...
  %     thisWord,...
  %     w_stimNum,...
  %     targStatus,...
  %     spacStatus,...
  %     studyLag,...
  %     int32(studyStims_word(i).presNum),...
  %     int32(studyStims_word(i).pairNum),...
  %     int32(studyStims_word(i).pairOrd));
  %
  %   % Write image stimulus presentation to file:
  %   fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n',...
  %     imgOn,...
  %     expParam.subject,...
  %     sesName,...
  %     phaseName,...
  %     phaseCount,...
  %     phaseCfg.isExp,...
  %     'STUDY_IMAGE',...
  %     i,...
  %     studyStims_img(i).fileName,...
  %     i_stimNum,...
  %     targStatus,...
  %     spacStatus,...
  %     studyLag,...
  %     int32(studyStims_img(i).presNum),...
  %     int32(studyStims_img(i).pairNum),...
  %     int32(studyStims_img(i).pairOrd),...
  %     studyStims_img(i).categoryStr,...
  %     i_catNum);
  %
  %   % Write trial result to file:
  %   fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
  %     endRT,...
  %     expParam.subject,...
  %     sesName,...
  %     phaseName,...
  %     phaseCount,...
  %     phaseCfg.isExp,...
  %     'STUDY_RESP',...
  %     i,...
  %     resp,...
  %     respKey,...
  %     rt);
  %
  %   %% Write netstation logs
  %
  %   if expParam.useNS
  %     % Write trial info to et_NetStation
  %     % mark every event with the following key code/value pairs
  %     % 'subn', subject number
  %     % 'sess', session type
  %     % 'phas', session phase name
  %     % 'pcou', phase count
  %     % 'expt', whether this is the experiment (1) or practice (0)
  %     % 'trln', trial number
  %     % 'stmn', stimulus name
  %     % 'snum', stimulus number
  %     % 'targ', whether this is a target (1) or a lure (0)
  %     % 'spac', whether it was spaced (1) or not (0; massed or single pres)
  %     % 'slag', the spacing lag (>0=spaced, 0=massed, -1=single pres)
  %     % 'pres', first (1) or second (2) presentation (single pres always = 1)
  %     % 'pnum', the pair number, for keeping image and word stimuli together
  %     % 'pord', image or word: which came first (1) and second (2)
  %
  %     % image only
  %     % 'cstr', category string
  %     % 'cnum', category number
  %
  %     % 'rsps', response string
  %     % 'rspk', the name of the key pressed
  %     % 'rspt', the response time
  %     % 'keyp', key pressed?(1=yes, 0=no)
  %
  %     % only for fixation, response prompt, and response events
  %     % 'istm', image stimulus name
  %     % 'inum', image stimulus number
  %     % 'icts', image stimulus category string
  %     % 'ictn', image stimulus category number
  %     % 'wstm', word stimulus
  %     % 'wnum', word stimulus number
  %
  %     if ~isnan(preStimFixOn)
  %       % pre-stim1 fixation
  %       [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', preStimFixOn, .001,...
  %         'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
  %         'expt',phaseCfg.isExp,...
  %         'trln', int32(i),...
  %         'istm', studyStims_img(i).fileName, 'inum', i_stimNum, 'icts', studyStims_img(i).categoryStr, 'ictn', i_catNum,...
  %         'wstm', thisWord, 'wnum', w_stimNum,...
  %         'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
  %         'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
  %     end
  %
  %     % image presentation
  %     [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', imgOn, .001,...
  %       'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
  %       'expt', phaseCfg.isExp,...
  %       'trln', int32(i), 'type', 'image', 'stmn', studyStims_img(i).fileName, 'snum', i_stimNum,...
  %       'cstr', studyStims_img(i).categoryStr, 'cnum', i_catNum,...
  %       'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
  %       'pres', int32(studyStims_img(i).presNum), 'pnum', int32(studyStims_img(i).pairNum), 'pord', int32(studyStims_img(i).pairOrd),...
  %       'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
  %
  %     % word presentation
  %     [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', probOn, .001,...
  %       'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
  %       'expt',phaseCfg.isExp,...
  %       'trln', int32(i), 'type', 'word', 'stmn', thisWord, 'snum', w_stimNum,...
  %       'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
  %       'pres', int32(studyStims_word(i).presNum), 'pnum', int32(studyStims_word(i).pairNum), 'pord', int32(studyStims_word(i).pairOrd),...
  %       'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
  %
  %     if ~isnan(respPromptOn)
  %       % response prompt
  %       [NSEventStatus, NSEventError] = et_NetStation('Event', 'PROM', respPromptOn, .001,...
  %         'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
  %         'expt',phaseCfg.isExp,...
  %         'trln', int32(i),...
  %         'istm', studyStims_img(i).fileName, 'inum', i_stimNum, 'icts', studyStims_img(i).categoryStr, 'ictn', i_catNum,...
  %         'wstm', thisWord, 'wnum', w_stimNum,...
  %         'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
  %         'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
  %     end
  %
  %     % did they make a response?
  %     if keyIsDown
  %       % button push
  %       [NSEventStatus, NSEventError] = et_NetStation('Event', 'RESP', endRT, .001,...
  %       'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
  %       'expt',phaseCfg.isExp,...
  %       'trln', int32(i),...
  %       'istm', studyStims_img(i).fileName, 'inum', i_stimNum, 'icts', studyStims_img(i).categoryStr, 'ictn', i_catNum,...
  %       'wstm', thisWord, 'wnum', w_stimNum,...
  %       'targ', targStatus, 'spac', spacStatus, 'slag', studyLag,...
  %       'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
  %     end
  %   end % useNS
  
  % mark that we finished this trial
  trialComplete(i) = true;
  % save progress after each trial
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
  
  % break out if time is up
  if (GetSecs - mathStartTime) > phaseCfg.dist_maxTimeLimit
    break
  end
end

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

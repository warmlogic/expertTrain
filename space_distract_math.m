function [cfg,expParam] = space_distract_math(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = space_distract_math(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
%
% Description:
%  This function runs the math distractor task. There are no blocks, only
%  short (blink) breaks.
%
%
% Inputs:
%
%
% Outputs:
%
%
%

fprintf('Running %s %s (distMath) (%d)...\n',sesName,phaseName,phaseCount);

phaseNameForParticipant = 'math';

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

trialAcc = false(phaseCfg.dist_nProbs,1);
trialRT = zeros(phaseCfg.dist_nProbs,1,'int32');

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

% if ~isfield(phaseCfg,'impedanceAfter_nTrials')
%   phaseCfg.impedanceAfter_nTrials = 0;
% end

% whether to ask the participant if they have any questions; only continues
% with experimenter's secret key
if ~isfield(phaseCfg.instruct,'questions')
  phaseCfg.instruct.questions = true;
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
Screen('Flip', w);
% Wait before starting trial
WaitSecs(5.000);
% Clear screen to background color (our 'gray' as set at the beginning):
Screen('Flip', w);

%% show the instructions

if ~expParam.photoCellTest
  for i = 1:length(phaseCfg.instruct.dist)
    WaitSecs(1.000);
    et_showTextInstruct(w,cfg,phaseCfg.instruct.dist(i),cfg.keys.instructContKey,...
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

%% run the distractor task

% % only check these keys
% RestrictKeysForKbCheck(KbName(cfg.keys.distMathKeyNames));

% % start the blink break timer
% if phaseCfg.isExp && phaseCfg.secUntilBlinkBreak > 0
%   blinkTimerStart = GetSecs;
% end

mathStartTime = GetSecs;

for i = trialNum:phaseCfg.dist_nProbs
  %   % do an impedance check after a certain number of trials
  %   if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < phaseCfg.dist_nProbs && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
  %     % run the impedance break
  %     thisGetSecs = GetSecs;
  %     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  %     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
  %     thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
  %     fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
  %     fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
  %
  %     % % only check these keys
  %     % RestrictKeysForKbCheck([cfg.keys.judgeSame, cfg.keys.judgeDiff]);
  %
  %     % show preparation text
  %     DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
  %     Screen('Flip', w);
  %     WaitSecs(2.0);
  %
  %     if (phaseCfg.dist_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.dist_isi == 0 && phaseCfg.fixDuringPreStim)
  %       Screen('TextSize', w, cfg.text.fixSize);
  %       DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  %     end
  %     Screen('Flip',w);
  %     WaitSecs(1.0);
  %     
  %     % reset the blink timer
  %     if phaseCfg.secUntilBlinkBreak > 0
  %       blinkTimerStart = GetSecs;
  %     end
  %   end
  %
  %   % Do a blink break if specified time has passed
  %   if ~expParam.photoCellTest && phaseCfg.isExp && phaseCfg.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= phaseCfg.secUntilBlinkBreak && i > 3 && i < (phaseCfg.dist_nProbs - 3)
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
  %     % show preparation text
  %     DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
  %     Screen('Flip', w);
  %     WaitSecs(2.0);
  %
  %     if (phaseCfg.dist_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.dist_isi == 0 && phaseCfg.fixDuringPreStim)
  %       Screen('TextSize', w, cfg.text.fixSize);
  %       DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  %     end
  %     Screen('Flip',w);
  %     WaitSecs(1.0);
  %     
  %     % reset the timer
  %     blinkTimerStart = GetSecs;
  %   end
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.dist_isi > 0
    if phaseCfg.fixDuringISI
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      Screen('Flip',w);
    end
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
    % don't use zeros in the math problems
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
  Screen('DrawText', w, tv_str, screenCenterX, screenCenterY, cfg.text.basicTextColor);
  
  if expParam.photoCellTest
    Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
  end
  
  [probOn, probOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s %d.\n',i,phaseCfg.dist_nProbs,tv_str,sum(theseVars));
  end
  
  % get their answer and type it to the screen
  resp = '';
  if ~useKbCheck
    % Flush the keyboard buffer:
    FlushEvents;
  end
  if ~expParam.photoCellTest
    while isempty(resp)
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
        
        % draw their text
        Screen('TextSize', w, cfg.text.basicTextSize);
        Screen('DrawText', w, sprintf('%s %s',tv_str,resp), screenCenterX, screenCenterY, cfg.text.basicTextColor);
        %[respMadeRT] = Screen('Flip', w);
        Screen('Flip', w);
        
        WaitSecs(0.0001);
      end
    end
  else
    WaitSecs(0.5);
    respMadeRT = GetSecs;
  end
  % get the time they pressed return
  endRT = respMadeRT;
  % only need the seconds, only for when using GetChar
  %endRT = endRT.secs;
  
  %if ~keyIsDown
  if isempty(resp)
    % need a new endRT
    %endRT = GetSecs;
    trialRT(i) = int32(round(1000 * (endRT - probOnset)));
    
    if phaseCfg.playSound
      Beeper(phaseCfg.incorrectSound,phaseCfg.incorrectVol);
    end
    
    % "need to respond faster"
    Screen('TextSize', w, cfg.text.instructTextSize);
    DrawFormattedText(w,cfg.text.respondFaster,'center','center',cfg.text.respondFasterColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    trialAcc(i) = false;
    
    % wait to let them view the feedback
    WaitSecs(cfg.text.respondFasterFeedbackTime);
    
    theirAnswer = -999;
  else
    % collect their answer
    theirAnswer = str2double(resp);
    
    trialRT(i) = int32(round(1000 * (endRT - probOnset)));
    
    % check their answer
    if theirAnswer == sum(theseVars)
      % right
      trialAcc(i) = true;
      if phaseCfg.playSound
        respSound = phaseCfg.correctSound;
        respVol = phaseCfg.correctVol;
      end
    elseif theirAnswer ~= sum(theseVars)
      % wrong
      trialAcc(i) = false;
      if phaseCfg.playSound
        respSound = phaseCfg.incorrectSound;
        respVol = phaseCfg.incorrectVol;
      end
    end
    
    if phaseCfg.playSound
      Beeper(respSound,respVol);
    end
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s %d. Their answer: %d. Accuracy: %d. RT: %d.\n',i,phaseCfg.dist_nProbs,tv_str,sum(theseVars),theirAnswer,trialAcc(i),trialRT(i));
    end
  end
  
  Screen('Flip', w);
  
  %% session log file
  
  % Write math problem presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\n',...
    probOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'MATH_PROB',...
    i,...
    tv_str);
  
  % Write response to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'MATH_RESP',...
    i,...
    theirAnswer,...
    trialAcc(i),...
    trialRT(i));
  
  %% phase log file
  
  % Write math problem presentation to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\n',...
    probOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'MATH_PROB',...
    i,...
    tv_str);
  
  % Write response to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'MATH_RESP',...
    i,...
    theirAnswer,...
    trialAcc(i),...
    trialRT(i));
  
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
    % 'math', math problem
    % 'resp', their answer
    % 'corr', accuracy (1 or 0)
    % 'rspt', response time
    
    % math problem presentation
    [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', probOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
      'expt', phaseCfg.isExp, 'trln', int32(i),...
      'math', tv_str, 'resp', int32(theirAnswer), 'corr', trialAcc(i), 'rspt', trialRT(i)); %#ok<NASGU,ASGLU>
    
    % did they make a response?
    if ~isempty(resp)
      % button push
      [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'trln', int32(i),...
        'math', tv_str, 'resp', int32(theirAnswer), 'corr', trialAcc(i), 'rspt', trialRT(i)); %#ok<NASGU,ASGLU>
    end
  end % useNS
  
  % mark that we finished this trial
  trialComplete(i) = true;
  % save progress after each trial
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
  
  % break out if time is up
  if (GetSecs - mathStartTime) > phaseCfg.dist_maxTimeLimit
    break
  end
end

%% print "continue" screen

WaitSecs(2.0);

completeTrialAcc = trialAcc(trialComplete);
completeTrialRT = trialRT(trialComplete);

% only print RT if they got at least one right
if ~isempty(completeTrialRT(completeTrialAcc))
  rt_str = sprintf('For the correct trials, on average you responded in %d ms.',...
    round(mean(completeTrialRT(completeTrialAcc))));
else
  rt_str = '';
end

% print accuracy and correct trial RT
accRtText = sprintf('You have finished the %s phase.\n\nYou got %d out of %d correct.\n%s\n\nPress "%s" to continue.',...
  phaseNameForParticipant,sum(completeTrialAcc),length(completeTrialAcc),rt_str,cfg.keys.instructContKey);
Screen('TextSize', w, cfg.text.instructTextSize);
DrawFormattedText(w,accRtText,'center','center',cfg.text.instructColor, cfg.text.instructCharWidth);
Screen('Flip', w);

if ~expParam.photoCellTest
  % wait until the key is pressed
  RestrictKeysForKbCheck(KbName(cfg.keys.instructContKey));
  KbWait(-1,2);
end
RestrictKeysForKbCheck([]);

% go back to gray
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

function [expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
%
% Description:
%  This function runs the recognition study and test tasks.
%
%  Study targets are stored in expParam.session.(sesName).(phaseName).targStims
%  and intermixed test targets and lures are stored in
%  expParam.session.(sesName).(phaseName).allStims as structs. Both study
%  targets and target+lure test stimuli must already be sorted in
%  presentation order.
%
%
% Inputs:
%
%
% Outputs:
%
%
% NB:
%  Once agian, study targets and test targets+lures must already be sorted
%  in presentation order!
%
% NB:
%  Test response time is measured from when response key image appears on
%  screen.
%

% % keys
% cfg.keys.recogKeyNames
% cfg.keys.recogDefUn
% cfg.keys.recogMayUn
% cfg.keys.recogMayF
% cfg.keys.recogDefF
% cfg.keys.recogRecoll

% % durations, in seconds
% cfg.stim.(sesName).(phaseName).recog_study_isi = 0.8;
% cfg.stim.(sesName).(phaseName).recog_study_preTarg = 0.2;
% cfg.stim.(sesName).(phaseName).recog_study_targ = 2.0;
% cfg.stim.(sesName).(phaseName).recog_test_isi = 0.8;
% cfg.stim.(sesName).(phaseName).recog_test_preStim = 0.2;
% cfg.stim.(sesName).(phaseName).recog_test_stim = 1.5;
% cfg.stim.(sesName).(phaseName).recog_response = 10.0;

fprintf('Running %s %s (%d)...\n',sesName,phaseName,phaseCount);

% record the starting date and time for this phase
expParam.session.(sesName).(phaseName)(phaseCount).date = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));
expParam.session.(sesName).(phaseName)(phaseCount).startTime = startTime;
% put it in the log file
fprintf(logFile,'Start of %s %s (%d)\t%s\t%s\n',sesName,phaseName,phaseCount,date,startTime);

%% general preparation for recognition study and test

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);
targStims = expParam.session.(sesName).(phaseName)(phaseCount).targStims;
allStims = expParam.session.(sesName).(phaseName)(phaseCount).allStims;

if phaseCfg.isExp
  stimDir = cfg.files.stimDir;
else
  stimDir = cfg.files.stimDir_prac;
end

% read the proper response key image
respKeyImg = imread(cfg.files.recogTestRespKeyImg);
respKeyImgHeight = size(respKeyImg,1) * cfg.files.recogTestRespKeyImgScale;
respKeyImgWidth = size(respKeyImg,2) * cfg.files.recogTestRespKeyImgScale;
respKeyImg = Screen('MakeTexture',w,respKeyImg);

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

%% do an impedance check before the phase begins, if desired

if ~isfield(phaseCfg,'impedanceBeforePhase')
  phaseCfg.impedanceBeforePhase = false;
end

if expParam.useNS && phaseCfg.impedanceBeforePhase
  % run the impedance break
  et_impedanceCheck(w, cfg, false);
end

%% start NS recording, if desired

% put a message on the screen as experiment phase begins
message = 'Starting recognition phase...';
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = 'Starting data acquisition for recognition phase...';
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

% initialize for storing some data
study_preStimFixOn = cell(1,phaseCfg.nBlocks);
study_imgOn = cell(1,phaseCfg.nBlocks);
test_preStimFixOn = cell(1,phaseCfg.nBlocks);
test_imgOn = cell(1,phaseCfg.nBlocks);
respKeyImgOn = cell(1,phaseCfg.nBlocks);
endRT = cell(1,phaseCfg.nBlocks);

%% Run recognition study and test

for b = 1:phaseCfg.nBlocks
  % initialize
  study_preStimFixOn{b} = nan(1,length(targStims{b}));
  study_imgOn{b} = nan(1,length(targStims{b}));
  test_preStimFixOn{b} = nan(1,length(allStims{b}));
  test_imgOn{b} = nan(1,length(allStims{b}));
  respKeyImgOn{b} = nan(1,length(allStims{b}));
  endRT{b} = nan(1,length(allStims{b}));
  
  %% do an impedance check before the block begins
  if expParam.useNS && phaseCfg.isExp && b > 1 && b < phaseCfg.nBlocks && mod((b - 1),phaseCfg.impedanceAfter_nBlocks) == 0
    % run the impedance break
    et_impedanceCheck(w, cfg, true);
  end
  
  %% prepare the recognition study task
  
  % load up the stimuli for this block
  blockStimTex = nan(1,length(targStims{b}));
  for i = 1:length(targStims{b})
    % this image
    stimImgFile = fullfile(stimDir,targStims{b}(i).familyStr,targStims{b}(i).fileName);
    if exist(stimImgFile,'file')
      stimImg = imread(stimImgFile);
      blockStimTex(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %blockStims(i) = Screen('MakeTexture',w,stimImg,[],1);
    else
      error('Study stimulus %s does not exist!',stimImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(stimImg,1) * cfg.stim.stimScale;
  stimImgWidth = size(stimImg,2) * cfg.stim.stimScale;
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect, cfg.screen.wRect);
  
  % text location for "too fast" text
  if ~phaseCfg.isExp
    [~,tooFastY] = RectCenter(cfg.screen.wRect);
    tooFastY = tooFastY + (stimImgHeight / 2);
  end
  
  %% show the study instructions
  
  for i = 1:length(phaseCfg.instruct.recogIntro)
    WaitSecs(1.000);
    et_showTextInstruct(w,phaseCfg.instruct.recogIntro(i),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
      {'blockNum'},{num2str(b)});
  end
  
  for i = 1:length(phaseCfg.instruct.recogStudy)
    WaitSecs(1.000);
    et_showTextInstruct(w,phaseCfg.instruct.recogStudy(i),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
      {'blockNum'},{num2str(b)});
  end
  
  % Wait a second before starting trial
  WaitSecs(1.000);
  
  %% run the recognition study task
  
  % start the blink break timer
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
    blinkTimerStart = GetSecs;
  end

  for i = 1:length(blockStimTex)
    % Do a blink break if specified time has passed
    if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(blockStimTex) - 3)
      Screen('TextSize', w, cfg.text.basicTextSize);
      pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(blockStimTex));
      % just draw straight into the main window since we don't need speed here
      DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      
      % wait for kb release in case subject is holding down keys
      KbReleaseWait;
      KbWait(-1); % listen for keypress on either keyboard
      
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
    if any(targStims{b}(i).familyNum == famNumSubord)
      isSubord = true;
      specNum = int32(targStims{b}(i).speciesNum);
    elseif any(targStims{b}(i).familyNum == famNumBasic)
      isSubord = false;
      specNum = int32(0);
    end
    
    % resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
    end
    
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    [study_preStimFixOn{b}(i)] = Screen('Flip',w);
    
    % ISI between trials
    if phaseCfg.recog_study_isi > 0
      WaitSecs(phaseCfg.recog_study_isi);
    end
    
    % fixation on screen before starting trial
    if phaseCfg.recog_study_preTarg > 0
      WaitSecs(phaseCfg.recog_study_preTarg);
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStimTex(i), [], stimImgRect);
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'startrt':
    [study_imgOn{b}(i), study_stimOnset] = Screen('Flip', w);
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s.\n',i,length(blockStimTex),allStims{b}(i).fileName);
    end
    
    % while loop to show stimulus until subjects response or until
    % "duration" seconds elapsed.
    while (GetSecs - study_stimOnset) <= phaseCfg.recog_study_targ
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    
    % Clear screen to background color after fixed 'duration'
    Screen('Flip', w);
    
    % close this stimulus before next trial
    Screen('Close', blockStimTex(i));
    
    % Write study stimulus presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%s\t%i\t%i\t%i\t%i\n',...
      study_imgOn{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCfg.isExp,...
      'RECOGSTUDY_TARG',...
      b,...
      i,...
      targStims{b}(i).familyStr,...
      targStims{b}(i).speciesStr,...
      targStims{b}(i).exemplarName,...
      isSubord,...
      specNum,...
      targStims{b}(i).targ);
    
    % Write netstation logs for nontargets only (this might not occur)
    if expParam.useNS
      if ~targStims{b}(i).targ
        % Write trial info to et_NetStation
        % mark every event with the following key code/value pairs
        % 'subn', subject number
        % 'sess', session type
        % 'phase', session phase name
        % 'expt', whether this is the experiment (1) or practice (0)
        % 'bloc', block number (training day 1 only)
        % 'part', whether this is a 'study' or 'test' trial
        % 'trln', trial number
        % 'stmn', stimulus name (family, species, exemplar)
        % 'spcn', species number (corresponds to keyboard)
        % 'sord', whether this is a subordinate (1) or basic (0) level family
        % 'targ', whether this is a target (always 1 for study)
        
        % write out the stimulus name
        stimName = sprintf('%s%s%d',...
          targStims{b}(i).familyStr,...
          targStims{b}(i).speciesStr,...
          targStims{b}(i).exemplarName);
        
        % pretrial fixation
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', study_preStimFixOn{b}(i), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
          'expt',phaseCfg.isExp,...
          'bloc', b,...
          'part','study',...
          'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
          'targ', targStims{b}(i).targ); %#ok<NASGU,ASGLU>
        
        % img presentation
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', study_imgOn{b}(i), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
          'expt',phaseCfg.isExp,...
          'bloc', b,...
          'part','study',...
          'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
          'targ', targStims{b}(i).targ); %#ok<NASGU,ASGLU>
      end
    end % useNS
    
  end % for stimuli
  
  %% Prepare the recognition test task
  
  % load up the stimuli for this block
  blockStimTex = nan(1,length(allStims{b}));
  for i = 1:length(allStims{b})
    % this image
    stimImgFile = fullfile(stimDir,allStims{b}(i).familyStr,allStims{b}(i).fileName);
    if exist(stimImgFile,'file')
      stimImg = imread(stimImgFile);
      blockStimTex(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %blockStims(i) = Screen('MakeTexture',w,stimImg,[],1);
    else
      error('Test stimulus %s does not exist!',stimImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(stimImg,1) * cfg.stim.stimScale;
  stimImgWidth = size(stimImg,2) * cfg.stim.stimScale;
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
  
  % set the response key image rectangle
  respKeyImgRect = CenterRect([0 0 respKeyImgWidth respKeyImgHeight], stimImgRect);
  respKeyImgRect = AdjoinRect(respKeyImgRect, stimImgRect, RectBottom);
  
  %% show the test instructions
  
  for i = 1:length(phaseCfg.instruct.recogTest)
    WaitSecs(1.000);
    et_showTextInstruct(w,phaseCfg.instruct.recogTest(i),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
  end
  
  % Wait a second before starting trial
  WaitSecs(1.000);
  
  %% Run the recognition test task
  
  % only check these keys
  RestrictKeysForKbCheck([cfg.keys.recogDefUn, cfg.keys.recogMayUn, cfg.keys.recogMayF, cfg.keys.recogDefF, cfg.keys.recogRecoll]);
  
  % start the blink break timer
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
    blinkTimerStart = GetSecs;
  end

  for i = 1:length(blockStimTex)
    % Do a blink break if recording EEG and specified time has passed
    if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(blockStimTex) - 3)
      Screen('TextSize', w, cfg.text.basicTextSize);
      pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(blockStimTex));
      % just draw straight into the main window since we don't need speed here
      DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      
      % wait for kb release in case subject is holding down keys
      KbReleaseWait;
      KbWait(-1); % listen for keypress on either keyboard
      
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
    if any(allStims{b}(i).familyNum == famNumSubord)
      isSubord = true;
      specNum = allStims{b}(i).speciesNum;
    elseif any(allStims{b}(i).familyNum == famNumBasic)
      isSubord = false;
      specNum = 0;
    end
    
    % resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
    end
    
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    [test_preStimFixOn{b}(i)] = Screen('Flip',w);
    
    % ISI between trials
    if phaseCfg.recog_test_isi > 0
      WaitSecs(phaseCfg.recog_test_isi);
    end
    
    % fixation on screen before starting trial
    if phaseCfg.recog_test_preStim > 0
      WaitSecs(phaseCfg.recog_test_preStim);
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStimTex(i), [], stimImgRect);
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'test_stimOnset':
    [test_imgOn{b}(i), test_stimOnset] = Screen('Flip', w);
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d.\n',i,length(blockStimTex),allStims{b}(i).fileName,allStims{b}(i).targ);
    end
    
    % while loop to show stimulus until "duration" seconds elapsed.
    while (GetSecs - test_stimOnset) <= phaseCfg.recog_test_stim
      % check for too-fast response in practice only
      if ~phaseCfg.isExp
        [keyIsDown] = KbCheck;
        % if they press a key too early, tell them they responded too fast
        if keyIsDown
          Screen('DrawTexture', w, blockStimTex(i), [], stimImgRect);
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.tooFast,'center',tooFastY,cfg.text.tooFastColor, cfg.text.instructCharWidth);
          Screen('TextSize', w, cfg.text.fixSize);
          DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          Screen('Flip', w);
        end
      end
      
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStimTex(i), [], stimImgRect);
    % with the response key image
    Screen('DrawTexture', w, respKeyImg, [], respKeyImgRect);
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    % put them on the screen; measure RT from when response key img appears
    [respKeyImgOn{b}(i), startRT] = Screen('Flip', w);
    
    % poll for a resp
    while 1
      if (GetSecs - startRT) > phaseCfg.recog_response
        break
      end
      
      [keyIsDown, endRT{b}(i), keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(0.0001);
        end
        % if cfg.text.printTrialInfo
        %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
        % end
        if (keyCode(cfg.keys.recogDefUn) == 1 && all(keyCode(~cfg.keys.recogDefUn) == 0)) ||...
            (keyCode(cfg.keys.recogMayUn) == 1 && all(keyCode(~cfg.keys.recogMayUn) == 0)) ||...
            (keyCode(cfg.keys.recogMayF) == 1 && all(keyCode(~cfg.keys.recogMayF) == 0)) ||...
            (keyCode(cfg.keys.recogDefF) == 1 && all(keyCode(~cfg.keys.recogDefF) == 0)) ||...
            (keyCode(cfg.keys.recogRecoll) == 1 && all(keyCode(~cfg.keys.recogRecoll) == 0))
          break
        end
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
      endRT = GetSecs;
      
      % wait to let them view the feedback
      WaitSecs(cfg.text.respondFasterFeedbackTime);
    end
    
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    
    % Clear screen to background color after response
    Screen('Flip', w);
    
    % Close this stimulus before next trial
    Screen('Close', blockStimTex(i));
    
    % compute response time
    rt = int32(round(1000 * (endRT - startRT)));
    
    % compute accuracy
    if keyIsDown
      if allStims{b}(i).targ && (keyCode(cfg.keys.recogMayF) == 1 || keyCode(cfg.keys.recogDefF) == 1 || keyCode(cfg.keys.recogRecoll) == 1)
        % target (hit)
        acc = true;
      elseif ~allStims{b}(i).targ && (keyCode(cfg.keys.recogDefUn) == 1 || keyCode(cfg.keys.recogMayUn) == 1)
        % lure (correct rejection)
        acc = true;
      else
        % miss or false alarm
        acc = false;
      end
    else
      % did not push a key
      acc = false;
    end
    
    % get the response
    if keyIsDown
      if keyCode(cfg.keys.recogRecoll) == 1
        resp = 'recollect';
      elseif keyCode(cfg.keys.recogDefF) == 1
        resp = 'definitelyFam';
      elseif keyCode(cfg.keys.recogMayF) == 1
        resp = 'maybeFam';
      elseif keyCode(cfg.keys.recogMayUn) == 1
        resp = 'maybeUnfam';
      elseif keyCode(cfg.keys.recogDefUn) == 1
        resp = 'definitelyUnfam';
      else
        warning('Key other than a recognition response key was pressed. This should not happen.\n');
        resp = 'ERROR';
      end
    elseif ~keyIsDown
      resp = 'none';
    end
    
    % get key pressed by subject
    respKey = KbName(keyCode);
    if isempty(respKey)
      respKey = 'none';
    end
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d. response: %s (key: %s) (acc = %d)\n',i,length(blockStimTex),allStims{b}(i).fileName,allStims{b}(i).targ,resp,respKey,acc);
    end
    
    % Write test stimulus presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%s\t%i\t%i\t%i\t%i\n',...
      test_imgOn{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCfg.isExp,...
      'RECOGTEST_STIM',...
      b,...
      i,...
      allStims{b}(i).familyStr,...
      allStims{b}(i).speciesStr,...
      allStims{b}(i).exemplarName,...
      isSubord,...
      specNum,...
      allStims{b}(i).targ);
    
    % Write test key image presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%s\t%i\t%i\t%i\t%i\n',...
      respKeyImgOn{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCfg.isExp,...
      'RECOGTEST_RESPKEYIMG',...
      b,...
      i,...
      allStims{b}(i).familyStr,...
      allStims{b}(i).speciesStr,...
      allStims{b}(i).exemplarName,...
      isSubord,...
      specNum,...
      allStims{b}(i).targ);
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%i\t%i\t%i\t%i\t%i\t%s\t%s\t%i\t%i\n',...
      endRT{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCfg.isExp,...
      'RECOGTEST_RESP',...
      b,...
      i,...
      allStims{b}(i).familyStr,...
      allStims{b}(i).speciesStr,...
      allStims{b}(i).exemplarName,...
      isSubord,...
      specNum,...
      allStims{b}(i).targ,...
      resp,...
      respKey,...
      acc,...
      rt);
    
    % Write netstation logs
    if expParam.useNS
      % Write trial info to et_NetStation
      % mark every event with the following key code/value pairs
      % 'subn', subject number
      % 'sess', session type
      % 'phase', session phase name
      % 'expt', whether this is the experiment (1) or practice (0)
      % 'bloc', block number (training day 1 only)
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
        allStims{b}(i).familyStr,...
        allStims{b}(i).speciesStr,...
        allStims{b}(i).exemplarName);
      
      % pretrial fixation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', test_preStimFixOn{b}(i), .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
        'expt',phaseCfg.isExp,...
        'bloc', b,...
        'part','test',...
        'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', allStims{b}(i).targ,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      % img presentation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', test_imgOn{b}(i), .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
        'expt',phaseCfg.isExp,...
        'bloc', b,...
        'part','test',...
        'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', allStims{b}(i).targ,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      % response prompt
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'PROM', respKeyImgOn{b}(i), .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
        'expt',phaseCfg.isExp,...
        'bloc', b,...
        'part','test',...
        'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', allStims{b}(i).targ,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'RESP', endRT{b}(i), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
          'expt',phaseCfg.isExp,...
          'bloc', b,...
          'part','test',...
          'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', allStims{b}(i).targ,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % if this is a target, log the study stimulus with response
      if allStims{b}(i).targ
        % find where it occurred in the study list
        sInd = find(ismember({targStims{b}.fileName},allStims{b}(i).fileName));
        
        % write out the stimulus name
        stimName = sprintf('%s%s%d',...
          targStims{b}(sInd).familyStr,...
          targStims{b}(sInd).speciesStr,...
          targStims{b}(sInd).exemplarName);
        
        % pretrial fixation
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', study_preStimFixOn{b}(sInd), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
          'expt',phaseCfg.isExp,...
          'bloc', b,...
          'part','study',...
          'trln', int32(sInd), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
          'targ', targStims{b}(sInd).targ,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
        
        % img presentation
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', study_imgOn{b}(sInd), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
          'expt',phaseCfg.isExp,...
          'bloc', b,...
          'part','study',...
          'trln', int32(sInd), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
          'targ', targStims{b}(sInd).targ,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
    end % useNS
    
  end % for stimuli
  
  % reset the KbCheck
  RestrictKeysForKbCheck([]);
  
end % for nBlocks

%% cleanup

% Close the response key image
Screen('Close',respKeyImg);

% stop recording
if expParam.useNS
  WaitSecs(5.0);
  [NSSyncStatus, NSSyncError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
end

% record the end time for this session
endTime = fix(clock);
endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6));
expParam.session.(sesName).(phaseName)(phaseCount).endTime = endTime;
% put it in the log file
fprintf(logFile,'End of %s %s (%d)\t%s\t%s\n',sesName,phaseName,phaseCount,date,endTime);

end % function

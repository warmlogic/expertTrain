function [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName)
% function [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName)
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
% cfg.stim.(sesName).(phaseName).study_isi = 0.8;
% cfg.stim.(sesName).(phaseName).study_preTarg = 0.2;
% cfg.stim.(sesName).(phaseName).study_targ = 2.0;
% cfg.stim.(sesName).(phaseName).test_isi = 0.8;
% cfg.stim.(sesName).(phaseName).test_preStim = 0.2;
% cfg.stim.(sesName).(phaseName).test_stim = 1.5;

% TODO: make instruction files. read in during config?

% TODO: blink breaks

% TODO: NS logging

fprintf('Running recognition task for %s %s...\n',sesName,phaseName);

%% general preparation for recognition study and test

phaseCfg = cfg.stim.(sesName).(phaseName);

% set some text color
instructColor = WhiteIndex(w);
fixationColor = WhiteIndex(w);

% read the proper response key image
testRespImgFile = fullfile(cfg.files.resDir,sprintf('recog_test_resp%d.jpg',cfg.keys.recogKeySet));
testRespImg = imread(testRespImgFile);
testRespImgHeight = size(testRespImg,1);
testRespImgWidth = size(testRespImg,2);
testRespImg = Screen('MakeTexture',w,testRespImg);

%% start NS recording, if desired

% NEW put a message on the screen as experiment phase begins
message = 'Starting experiment...';
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = NetStation('StartRecording');
  % synchronize
  [NSSyncStatus, NSSyncError] = NetStation('Synchronize');
  message = 'Starting data acquisition...';
end
DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w),70);
% draw message to screen
Screen('Flip', w);
% Wait before starting trial
WaitSecs(5.000);
% Clear screen to background color (our 'gray' as set at the
% beginning):
Screen('Flip', w);

%% Run recognition study and test

for b = 1:phaseCfg.nBlocks
  
  %% prepare the recognition study task
  
  recogphase = 'recog_study';
  
  % load up the stimuli for this block
  blockStimTex = nan(1,length(expParam.session.(sesName).(phaseName).targStims{b}));
  for i = 1:length(expParam.session.(sesName).(phaseName).targStims{b})
    % this image
    stimImgFile = fullfile(cfg.files.stimDir,expParam.session.(sesName).(phaseName).targStims{b}(i).familyStr,expParam.session.(sesName).(phaseName).targStims{b}(i).fileName);
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
  stimImgHeight = size(stimImg,1);
  stimImgWidth = size(stimImg,2);
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
  
  %% show the study instructions
  
  instructions = sprintf('Press ''%s'' to begin Recognition study task.','space');
  % put the instructions on the screen
  DrawFormattedText(w, instructions, 'center', 'center', instructColor);
  % Update the display to show the instruction text:
  Screen('Flip', w);
  % wait until spacebar is pressed
  RestrictKeysForKbCheck(KbName('space'));
  KbWait(-1,2);
  RestrictKeysForKbCheck([]);
  % Clear screen to background color (our 'gray' as set at the
  % beginning):
  Screen('Flip', w);
  
  % Wait a second before starting trial
  WaitSecs(1.000);
  
  %% run the recognition study task
  
  % set the fixation size
  Screen('TextSize', w, cfg.text.fixsize);
  
  % NEW start the blink break timer
  if expParam.useNS
    blinkTimerStart = GetSecs;
  end

  for i = 1:length(blockStimTex)
    % NEW Do a blink break if recording EEG and specified time has passed
    if expParam.useNS && i ~= 1 && i ~= length(blockStimTex) && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak
      Screen('TextSize', w, 32);
      pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(blockStimTex));
      % just draw straight into the main window since we don't need speed here
      DrawFormattedText(w, pauseMsg, 'center', 'center');
      Screen('Flip', w);
      
      % wait for kb release in case subject is holding down keys
      KbReleaseWait;
      KbWait(-1); % listen for keypress on either keyboard
      
      Screen('TextSize', w, cfg.text.fixsize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
      Screen('Flip',w);
      WaitSecs(0.5);
      % reset the timer
      blinkTimerStart = GetSecs;
    end
    
    % Is this a subordinate (1) or basic (0) family/species? If subordinate,
    % get the species number.
    if expParam.session.(sesName).(phaseName).targStims{b}(i).familyNum == cfg.stim.famNumSubord
      subord = 1;
      sNum = expParam.session.(sesName).(phaseName).targStims{b}(i).speciesNum;
    else
      subord = 0;
      sNum = 0;
    end
    
    % NEW resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = NetStation('Synchronize');
    end
    
    % draw fixation
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
    [preStimFixOn] = Screen('Flip',w);
    
    % ISI between trials
    WaitSecs(phaseCfg.study_isi);
    
    % fixation on screen before starting trial
    WaitSecs(phaseCfg.study_preTarg);
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStimTex(i), [], stimImgRect);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'startrt':
    [imgStudyOn, stimOnset] = Screen('Flip', w);
    
    % while loop to show stimulus until subjects response or until
    % "duration" seconds elapsed.
    while (GetSecs - stimOnset) <= phaseCfg.study_targ
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % Clear screen to background color after fixed 'duration'
    % % and draw fixation
    % DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
    Screen('Flip', w);
    
    % close this stimulus before next trial
    Screen('Close', blockStimTex(i));
    
    % Write study stimulus presentation to file:
    fprintf(logFile,'%f %s %s %s %s %s %i %i %s %s %i %i %i %i\n',...
      imgStudyOn,...
      expParam.subject,...
      'RECOGSTUDY_TARG',...
      sesName,...
      phaseName,...
      recogphase,...
      b,...
      i,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).familyStr,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).exemplarName,...
      subord,...
      sNum,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).targ);
    
    
    % NEW Write netstation logs
    if expParam.useNS
      % Write trial info to NetStation
      % mark every event with the following key code/value pairs
      % 'subn', subject number
      % 'sess', session type
      % 'phase', session phase name
      % 'bloc', block number (training day 1 only)
      % 'trln', trial number
      % 'stmn', stimulus name (family, species, exemplar)
      % 'spcn', species number (corresponds to keyboard)
      % 'sord', whether this is a subordinate (1) or basic (0) level family
      % 'targ', whether this is a target (always 1 for study)
      
      % write out the stimulus name
      stimName = sprintf('%s%s%d',...
        expParam.session.(sesName).(phaseName).targStims{b}(i).familyStr,...
        expParam.session.(sesName).(phaseName).targStims{b}(i).speciesStr,...
        expParam.session.(sesName).(phaseName).targStims{b}(i).exemplarName);
      
      % pretrial fixation
      [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
        'trln', i, 'stmn', stimName, 'spcn', sNum, 'sord', subord,...
        'targ', expParam.session.(sesName).(phaseName).targStims{b}(i).targ);
      
      % img presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'TIMG', imgOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
        'trln', i, 'stmn', stimName, 'spcn', sNum, 'sord', subord,...
        'targ', expParam.session.(sesName).(phaseName).targStims{b}(i).targ);
    end % useNS
    
  end % for stimuli
  
  %% Prepare the recognition test task
  
  recogphase = 'recog_test';
  
  % load up the stimuli for this block
  blockStimTex = nan(1,length(expParam.session.(sesName).(phaseName).allStims{b}));
  for i = 1:length(expParam.session.(sesName).(phaseName).allStims{b})
    % this image
    stimImgFile = fullfile(cfg.files.stimDir,expParam.session.(sesName).(phaseName).allStims{b}(i).familyStr,expParam.session.(sesName).(phaseName).allStims{b}(i).fileName);
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
  stimImgHeight = size(stimImg,1);
  stimImgWidth = size(stimImg,2);
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
  
  % set the response key image rectangle
  respKeyImgRect = CenterRect([0 0 testRespImgWidth testRespImgHeight],stimImgRect);
  respKeyImgRect = AdjoinRect(respKeyImgRect,stimImgRect,RectBottom);
  
  %% show the test instructions
  
  instructions = sprintf('Press ''%s'' to begin Recognition test task.','space');
  % put the instructions on the screen
  DrawFormattedText(w, instructions, 'center', 'center', instructColor);
  % Update the display to show the instruction text:
  Screen('Flip', w);
  % wait until spacebar is pressed
  RestrictKeysForKbCheck(KbName('space'));
  KbWait(-1,2);
  RestrictKeysForKbCheck([]);
  % Clear screen to background color (our 'gray' as set at the
  % beginning):
  Screen('Flip', w);
  
  % Wait a second before starting trial
  WaitSecs(1.000);
  
  %% Run the recognition test task
  
  % set the fixation size
  Screen('TextSize', w, cfg.text.fixsize);
  
  % only check these keys
  RestrictKeysForKbCheck([cfg.keys.recogDefUn, cfg.keys.recogMayUn, cfg.keys.recogMayF, cfg.keys.recogDefF, cfg.keys.recogRecoll]);
  
  % NEW start the blink break timer
  if expParam.useNS
    blinkTimerStart = GetSecs;
  end

  for i = 1:length(blockStimTex)
    % NEW Do a blink break if recording EEG and specified time has passed
    if expParam.useNS && i ~= 1 && i ~= length(blockStimTex) && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak
      Screen('TextSize', w, 32);
      pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(blockStimTex));
      % just draw straight into the main window since we don't need speed here
      DrawFormattedText(w, pauseMsg, 'center', 'center');
      Screen('Flip', w);
      
      % wait for kb release in case subject is holding down keys
      KbReleaseWait;
      KbWait(-1); % listen for keypress on either keyboard
      
      Screen('TextSize', w, cfg.text.fixsize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
      Screen('Flip',w);
      WaitSecs(0.5);
      % reset the timer
      blinkTimerStart = GetSecs;
    end
    
    % Is this a subordinate (1) or basic (0) family/species? If subordinate,
    % get the species number.
    if expParam.session.(sesName).(phaseName).allStims{b}(i).familyNum == cfg.stim.famNumSubord
      subord = 1;
      sNum = expParam.session.(sesName).(phaseName).allStims{b}(i).speciesNum;
    else
      subord = 0;
      sNum = 0;
    end
    
    % NEW resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = NetStation('Synchronize');
    end
    
    % draw fixation
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
    [preStimFixOn] = Screen('Flip',w);
    
    % ISI between trials
    WaitSecs(phaseCfg.test_isi);
    
    % fixation on screen before starting trial
    WaitSecs(phaseCfg.test_preStim);
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStimTex(i), [], stimImgRect);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'stimOnset':
    [imgTestOn, stimOnset] = Screen('Flip', w);
    
    % while loop to show stimulus until subjects response or until
    % "duration" seconds elapsed.
    while (GetSecs - stimOnset) <= phaseCfg.test_stim
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStimTex(i), [], stimImgRect);
    % draw the response key image
    Screen('DrawTexture', w, testRespImg, [], respKeyImgRect);
    % put them on the screen; measure RT from when response key img appears
    [respKeyImgOn, startRT] = Screen('Flip', w);
    
    % poll for a resp
    while 1
      [keyIsDown, endRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(0.0001);
        end
        % % debug
        % fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
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
    
    % Clear screen to background color after response
    % % and draw fixation
    % DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
    Screen('Flip', w);
    
    % Close this stimulus before next trial
    Screen('Close', blockStimTex(i));
    
    % compute response time
    rt = round(1000 * (endRT - startRT));
    
    % compute accuracy
    if expParam.session.(sesName).(phaseName).allStims{b}(i).targ && (keyCode(cfg.keys.recogMayF) == 1 || keyCode(cfg.keys.recogDefF) == 1 || keyCode(cfg.keys.recogRecoll) == 1)
      % target (hit)
      acc = 1;
    elseif ~expParam.session.(sesName).(phaseName).allStims{b}(i).targ && (keyCode(cfg.keys.recogDefUn) == 1 || keyCode(cfg.keys.recogMayUn) == 1)
      % lure (correct rejection)
      acc = 1;
    else
      % miss or false alarm
      acc = 0;
    end
    
    % get key pressed by subject
    respKey = KbName(keyCode);
    
    % Write test stimulus presentation to file:
    fprintf(logFile,'%f %s %s %s %s %s %i %i %s %s %i %i %i %i\n',...
      imgTestOn,...
      expParam.subject,...
      'RECOGTEST_STIM',...
      sesName,...
      phaseName,...
      recogphase,...
      b,...
      i,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).familyStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).exemplarName,...
      subord,...
      sNum,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).targ);
    
    % Write trial result to file:
    fprintf(logFile,'%f %s %s %s %s %s %i %i %s %i %i %i %i %i %s %i %i\n',...
      endRT,...
      expParam.subject,...
      'RECOGTEST_RESP',...
      sesName,...
      phaseName,...
      recogphase,...
      b,...
      i,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).familyStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).exemplarName,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).targ,...
      subord,...
      sNum,...
      respKey,...
      acc,...
      rt);
    
    % NEW Write netstation logs
    if expParam.useNS
      % Write trial info to NetStation
      % mark every event with the following key code/value pairs
      % 'subn', subject number
      % 'sess', session type
      % 'phase', session phase name
      % 'bloc', block number (training day 1 only)
      % 'trln', trial number
      % 'stmn', stimulus name (family, species, exemplar)
      % 'spcn', species number (corresponds to keyboard)
      % 'sord', whether this is a subordinate (1) or basic (0) level family
      % 'targ', whether this is a target (1) or not (0)
      % 'resk', the name of the key pressed
      % 'corr', accuracy code (1=correct, 0=incorrect)
      % 'keyp', key pressed?(1=yes, 0=no)
      
      % write out the stimulus name
      stimName = sprintf('%s%s%d',...
        expParam.session.(sesName).(phaseName).allStims{b}(i).familyStr,...
        expParam.session.(sesName).(phaseName).allStims{b}(i).speciesStr,...
        expParam.session.(sesName).(phaseName).allStims{b}(i).exemplarName);
      
      % pretrial fixation
      [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
        'trln', i, 'stmn', stimName, 'spcn', sNum, 'sord', subord, 'targ', expParam.session.(sesName).(phaseName).allStims{b}(i).targ,...
        'resk', respKey, 'corr', acc, 'keyp', keyIsDown);
      
      % img presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'TIMG', imgOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
        'trln', i, 'stmn', stimName, 'spcn', sNum, 'sord', subord, 'targ', expParam.session.(sesName).(phaseName).allStims{b}(i).targ,...
        'resk', respKey, 'corr', acc, 'keyp', keyIsDown);
      
      % response prompt
      [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
        'trln', i, 'stmn', stimName, 'spcn', sNum, 'sord', subord, 'targ', expParam.session.(sesName).(phaseName).allStims{b}(i).targ,...
        'resk', respKey, 'corr', acc, 'keyp', keyIsDown);
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
          'trln', i, 'stmn', stimName, 'spcn', sNum, 'sord', subord, 'targ', expParam.session.(sesName).(phaseName).allStims{b}(i).targ,...
          'resk', respKey, 'corr', acc, 'keyp', keyIsDown);
      end
    end % useNS
    
  end % for stimuli
  
  % reset the KbCheck
  RestrictKeysForKbCheck([]);
  
end % for nBlocks

%% cleanup

% NEW stop recording
if expParam.useNS
  WaitSecs(5.0);
  [NSSyncStatus, NSSyncError] = NetStation('StopRecording');
end

end % function

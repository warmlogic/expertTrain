function [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,b)
% function [logFile] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,b)
%
% Description:
%  This function runs the naming task.
%
%  The stimuli for the naming task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phaseName).nameStims as a
%  struct.
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

% % durations, in seconds
% cfg.stim.(sesName).(phaseName).name_isi = 0.5;
% % cfg.stim.(sesName).(phaseName).name_preStim = 0.5 to 0.7;
% cfg.stim.(sesName).(phaseName).name_stim = 1.0;
% cfg.stim.(sesName).(phaseName).name_response = 2.0;
% cfg.stim.(sesName).(phaseName).name_feedback = 1.0;

% % keys
% cfg.keys.sXX, where XX is an integer, buffered with a zero if i <= 9

% TODO: make instruction files. read in during config?

fprintf('Running naming task for %s %s...\n',sesName,phaseName);

%% preparation

phaseCfg = cfg.stim.(sesName).(phaseName);

% set some text color
instructColor = WhiteIndex(w);
fixationColor = WhiteIndex(w);

initial_sNumColor = BlackIndex(w);
correct_sNumColor = uint8((rgb('Green') * 255) + 0.5);
incorrect_sNumColor = uint8((rgb('Red') * 255) + 0.5);

% initialize beep player if needed
if phaseCfg.playSound
  Beeper(1,0);
end

% Small hack. Because training day 1 uses blocks, those are stored in
% cells. However, all other training days do not use blocks, and do not use
% cells, but we need to put them in a cell to access the stimuli correctly.
if ~iscell(expParam.session.(sesName).(phaseName).nameStims)
  runInBlocks = false;
  expParam.session.(sesName).(phaseName).nameStims = {expParam.session.(sesName).(phaseName).nameStims};
  if ~exist('b','var') || isempty(b)
    b = 1;
  else
    error('expParam.session.%s.%s.nameStims should not be a cell array when only running 1 block.',sesName,phaseName);
  end
else
  runInBlocks = true;
end

%% preload all stimuli for presentation

message = sprintf('Preparing images, please wait...');
% put the instructions on the screen
DrawFormattedText(w, message, 'center', 'center', instructColor);
% Update the display to show the message:
Screen('Flip', w);

% initialize
stimTex = nan(1,length(expParam.session.(sesName).(phaseName).nameStims{b}));

for i = 1:length(expParam.session.(sesName).(phaseName).nameStims{b})
  % load up this stim's texture
  stimImgFile = fullfile(cfg.files.stimDir,expParam.session.(sesName).(phaseName).nameStims{b}(i).familyStr,expParam.session.(sesName).(phaseName).nameStims{b}(i).fileName);
  if exist(stimImgFile,'file')
    stimImg = imread(stimImgFile);
    stimTex(i) = Screen('MakeTexture',w,stimImg);
    % TODO: optimized?
    %stimtex(i) = Screen('MakeTexture',w,stimImg,[],1);
  else
    error('Study stimulus %s does not exist!',stimImgFile);
  end
end

% % get the width and height of the final stimulus image
% stimImgHeight = size(stimImg,1);
% stimImgWidth = size(stimImg,2);
% stimImgRect = [0 0 stimImgWidth stimImgHeight];
% stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
% 
% % y-coordinate for stimulus number
% sNumY = round(stimImgRect(RectBottom) + (cfg.screen.wRect(RectBottom) * 0.05));

%% run the task

if runInBlocks
  nSpecies = length(unique(phaseCfg.blockSpeciesOrder{b}));
else
  nSpecies = cfg.stim.nSpecies;
end

instructions = sprintf([...
  'Naming task: block %d.\n',...
  'You will see creatures from %d families.\n In this block, there are %d different species in each family.\n',...
  'You will identify the different species of one family, and you will chunk the other family together as ''%s''.\n',...
  '\nYour job: Press the correct species key for the creatures that you learned previously.\n',...
  'key=species: %s=1, %s=2, %s=3, %s=4, %s=5, %s=6, %s=7, %s=8, %s=9, %s=10\n',...
  '''%s'' is the key for the ''%s'' family species members.\n',...
  '\nPress ''%s'' to begin naming task.'],...
  b,...
  cfg.stim.nFamilies,nSpecies,cfg.stim.basicFamStr,...
  KbName(cfg.keys.s01),KbName(cfg.keys.s02),KbName(cfg.keys.s03),KbName(cfg.keys.s04),KbName(cfg.keys.s05),...
  KbName(cfg.keys.s06),KbName(cfg.keys.s07),KbName(cfg.keys.s08),KbName(cfg.keys.s09),KbName(cfg.keys.s10),...
  KbName(cfg.keys.s00),cfg.stim.basicFamStr,...
  'space');
% put the instructions on the screen
DrawFormattedText(w, instructions, 'center', 'center', instructColor);
% Update the display to show the instruction text:
Screen('Flip', w);
% wait until spacebar is pressed
RestrictKeysForKbCheck(KbName('space'));
KbWait(-1,2);
RestrictKeysForKbCheck([]);

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

% set the fixation size
Screen('TextSize', w, cfg.text.fixsize);

% only check these keys
RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
  cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);

% NEW start the blink break timer
if expParam.useNS
  blinkTimerStart = GetSecs;
end

for i = 1:length(stimTex)
  % NEW Do a blink break if recording EEG and specified time has passed
  if expParam.useNS && i ~= 1 && i ~= length(stimTex) && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak
    Screen('TextSize', w, 32);
    pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(stimTex));
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
  
  % NEW resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize');
  end
  
  % set the species number
  if expParam.session.(sesName).(phaseName).nameStims{b}(i).familyNum == cfg.stim.famNumSubord
    sNum = expParam.session.(sesName).(phaseName).nameStims{b}(i).speciesNum;
  else
    sNum = 0;
  end
  
  % NEW Is this a subordinate (1) or basic (0) family/species?
  if expParam.session.(sesName).(phaseName).nameStims{b}(i).familyNum == cfg.stim.famNumSubord
    subord = 1;
  else
    subord = 0;
  end
  
  % ISI between trials
  WaitSecs(phaseCfg.name_isi);
  
  % draw fixation
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
  [preStimFixOn] = Screen('Flip',w);
  % generate random display times for fixation cross
  name_preStim = 0.5 + ((0.7 - 0.5).*rand(1,1));
  % fixation on screen before stim
  WaitSecs(name_preStim);
  
  % draw the stimulus
  Screen('DrawTexture', w, stimTex(i));
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [imgOn, stimOnset] = Screen('Flip', w);
  
  % while loop to show stimulus until subjects response or until
  % "duration" seconds elapsed.
  while (GetSecs - stimOnset) <= phaseCfg.name_stim
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % draw response prompt
  DrawFormattedText(w,cfg.text.respSymbol,'center','center',initial_sNumColor);
  [respPromptOn, startRT] = Screen('Flip',w);
  
  % poll for a resp
  while 1
    if (GetSecs - startRT) > phaseCfg.name_response
      break
    end
    
    [keyIsDown, endRT, keyCode] = KbCheck;
    % if they push more than one key, don't accept it
    if keyIsDown && sum(keyCode) == 1
      % wait for key to be released
      while KbCheck(-1)
        WaitSecs(0.0001);
      end
      % % debug
      % fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
      if keyIsDown
        % give immediate feedback
        if keyCode(cfg.keys.(sprintf('s%.2d',sNum))) == 1
          sNumColor = correct_sNumColor;
          if phaseCfg.playSound
            respSound = phaseCfg.correctSound;
          end
        elseif keyCode(cfg.keys.(sprintf('s%.2d',sNum))) == 0
          sNumColor = incorrect_sNumColor;
          if phaseCfg.playSound
            respSound = phaseCfg.incorrectSound;
          end
        end
        % draw species number in the appropriate color
        if sNum > 0
          DrawFormattedText(w,num2str(sNum),'center','center',sNumColor);
        else
          DrawFormattedText(w,cfg.stim.basicFamStr,'center','center',sNumColor);
        end
        Screen('Flip', w);
        
        if phaseCfg.playSound
          Beeper(respSound);
        end
  
        break
      end
    end
    % wait so we don't overload the system
    WaitSecs(0.0001);
  end
  
  % wait out any remaining time
  while (GetSecs - startRT) <= phaseCfg.name_response
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % wait to let them view the feedback
  WaitSecs(phaseCfg.name_feedback);
  
  % Clear screen to background color after response
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', stimTex(i));
  
  % compute response time
  rt = round(1000 * (endRT - startRT));
  
  % compute accuracy
  if keyIsDown && keyCode(cfg.keys.(sprintf('s%.2d',sNum))) == 1
    % pushed the right key
    acc = 1;
  elseif keyIsDown && keyCode(cfg.keys.(sprintf('s%.2d',sNum))) == 0
    % pushed the wrong key
    acc = 0;
  elseif ~keyIsDown
    % did not push a key
    acc = 0;
  end
  
  % get key pressed by subject
  resp = KbName(keyCode);
  if isempty(resp)
    resp = 'none';
  end
  
  % Write stimulus presentation to file:
  fprintf(logFile,'%f %s %s %s %s %i %i %s %s %i %i %i\n',...
    imgOn,...
    expParam.subject,...
    'NAME_STIM',...
    sesName,...
    phaseName,...
    b,...
    i,...
    expParam.session.(sesName).(phaseName).nameStims{b}(i).familyStr,...
    expParam.session.(sesName).(phaseName).nameStims{b}(i).speciesStr,...
    expParam.session.(sesName).(phaseName).nameStims{b}(i).exemplarName,...
    subord,...
    sNum);
  
  % Write response to file:
  fprintf(logFile,'%f %s %s %s %s %i %i %s %s %i %i %i %s %i %i\n',...
    endRT,...
    expParam.subject,...
    'NAME_RESP',...
    sesName,...
    phaseName,...
    b,...
    i,...
    expParam.session.(sesName).(phaseName).nameStims{b}(i).familyStr,...
    expParam.session.(sesName).(phaseName).nameStims{b}(i).speciesStr,...
    expParam.session.(sesName).(phaseName).nameStims{b}(i).exemplarName,...
    subord,...
    sNum,...
    resp,...
    acc,...
    rt);
  
  % NEW Write netstation logs
  if expParam.useNS
    % Write trial info to NetStation
    % mark every event with the following key code/value pairs
    % 'subn', subject number
    % 'trln', trial number
    % 'cond', cond code (1=target, 0=non-target)
    % 'imgt', type of image (0=scene, 1=face)
    % 'corr', accuracy code (-2=miss, -1=FA, 0=CR, 1=hit)
    % 'keyp', key pressed?(1=yes, 0=no)
    
    % write out the stimulus name
    stimName = sprintf('%s%s%d',...
      expParam.session.(sesName).(phaseName).nameStims{b}(i).familyStr,...
      expParam.session.(sesName).(phaseName).nameStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phaseName).nameStims{b}(i).exemplarName);
  
    % pretrial fixation
    [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
      'trln', i, 'stim', stimName, 'spcn', sNum, 'sord', subord,...
      'resp', resp, 'corr', acc, 'keyp', keyIsDown);
    
    % img presentation
    [NSEventStatus, NSEventError] = NetStation('Event', 'TIMG', imgOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
      'trln', i, 'stim', stimName, 'spcn', sNum, 'sord', subord,...
      'resp', resp, 'corr', acc, 'keyp', keyIsDown);
    
    % response prompt
    [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
      'trln', i, 'stim', stimName, 'spcn', sNum, 'sord', subord,...
      'resp', resp, 'corr', acc, 'keyp', keyIsDown);
    
    % did they make a response?
    if keyIsDown
      % button push
      [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'bloc', b,...
      'trln', i, 'stim', stimName, 'spcn', sNum, 'sord', subord,...
      'resp', resp, 'corr', acc, 'keyp', keyIsDown);
    end
  end % useNS
  
end

% NEW stop recording
if expParam.useNS
  WaitSecs(5.0);
  [NSSyncStatus, NSSyncError] = NetStation('StopRecording');
end

% reset the KbCheck
RestrictKeysForKbCheck([]);

end % function

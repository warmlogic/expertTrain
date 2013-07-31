function [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,phaseCount,b)
% function [cfg,expParam] = et_naming(w,cfg,expParam,logFile,sesName,phaseName,phaseCount,b)
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

fprintf('Running %s %s (name) (%d)...\n',sesName,phaseName,phaseCount);

%% set up blocks

% Small hack. Because training day 1 uses blocks, those stims are stored in
% cells. However, all other training days do not use blocks, and do not use
% cells, but we need to put them in a cell to access the stimuli correctly.
if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
  runInBlocks = false;
  expParam.session.(sesName).(phaseName)(phaseCount).nameStims = {expParam.session.(sesName).(phaseName)(phaseCount).nameStims};
  if ~exist('b','var') || isempty(b)
    b = 1;
  else
    error('input variable ''b'' should not be defined when only running 1 block.');
  end
else
  runInBlocks = true;
end

%% set the starting date and time for this phase

thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% determine the starting trial, useful for resuming

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_%d_name_b%d.mat',sesName,phaseName,phaseCount,b));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b}));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
else
  fprintf('All trials for %s %s (name) (%d) (block %d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount,b);
  % release any remaining textures
  Screen('Close');
  return
end

%% start the log file for this phase

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_name_%d_b%d.txt',sesName,phaseName,phaseCount,b));
plf = fopen(phaseLogFile,'at');

%% record the starting date and time for this phase

expParam.session.(sesName).(phaseName)(phaseCount).date{b} = thisDate;
expParam.session.(sesName).(phaseName)(phaseCount).startTime{b} = startTime;

% put it in the log file
fprintf(logFile,'!!! Start of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,startTime);
fprintf(plf,'!!! Start of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,startTime);

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
nameStims = expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b};

if phaseCfg.isExp
  stimDir = cfg.files.stimDir;
else
  stimDir = cfg.files.stimDir_prac;
end

% set text color for species numbers
initial_sNumColor = uint8((rgb('Black') * 255) + 0.5);
correct_sNumColor = uint8((rgb('Green') * 255) + 0.5);
incorrect_sNumColor = uint8((rgb('Red') * 255) + 0.5);

% for "respond faster" text
[~,respondFasterY] = RectCenter(cfg.screen.wRect);
respondFasterY = respondFasterY + (cfg.screen.wRect(RectBottom) * 0.04);

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

%% preload all stimuli for presentation

message = sprintf('Preparing images, please wait...');
Screen('TextSize', w, cfg.text.basicTextSize);
% put the "preparing" message on the screen
DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
% Update the display to show the message:
Screen('Flip', w);

% initialize
stimTex = nan(1,length(nameStims));

for i = 1:length(nameStims)
  % load up this stim's texture
  stimImgFile = fullfile(stimDir,nameStims(i).familyStr,nameStims(i).fileName);
  if exist(stimImgFile,'file')
    stimImg = imread(stimImgFile);
    stimTex(i) = Screen('MakeTexture',w,stimImg);
    % TODO: optimized?
    %stimtex(i) = Screen('MakeTexture',w,stimImg,[],1);
  else
    error('Study stimulus %s does not exist!',stimImgFile);
  end
end

% get the width and height of the final stimulus image
stimImgHeight = size(stimImg,1) * cfg.stim.stimScale;
stimImgWidth = size(stimImg,2) * cfg.stim.stimScale;
stimImgRect = [0 0 stimImgWidth stimImgHeight];
stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);

% text location for error (e.g., "too fast") text
[~,errorTextY] = RectCenter(cfg.screen.wRect);
errorTextY = errorTextY + (stimImgHeight / 2);

% % y-coordinate for stimulus number (below stim by 4% of the screen height)
% sNumY = round(stimImgRect(RectBottom) + (cfg.screen.wRect(RectBottom) * 0.04));

if runInBlocks
  theseSpecies = unique(phaseCfg.blockSpeciesOrder{b});
else
  theseSpecies = unique([nameStims.speciesNum]);
end
nSpecies = length(theseSpecies);

theseSpeciesStr = sprintf('%d',theseSpecies(1));
if nSpecies > 1
  theseSpeciesStr = sprintf('%s%s',theseSpeciesStr,sprintf(repmat(', %d',1,length(theseSpecies) - 1),theseSpecies(2:end)));
  theseSpeciesStr = strrep(theseSpeciesStr,num2str(theseSpecies(end)),sprintf('and %d',theseSpecies(end)));
end
if nSpecies < 3
  theseSpeciesStr = strrep(theseSpeciesStr,',','');
end

%% do an impedance check before the phase begins, if desired

if ~isfield(phaseCfg,'impedanceBeforePhase')
  phaseCfg.impedanceBeforePhase = false;
end

if expParam.useNS && phaseCfg.impedanceBeforePhase
  % run the impedance break
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
  thisGetSecs = et_impedanceCheck(w, cfg, false);
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
end

%% start NS recording, if desired

% put a message on the screen as experiment phase begins
message = 'Starting naming phase...';
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = 'Starting data acquisition for naming phase...';
  
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

if runInBlocks
  % don't show the instructions on the block with impedance break
  if b == 1 || mod((b - 1),phaseCfg.impedanceAfter_nBlocks) ~= 0
    showInstruct = true;
  elseif b > 1 && b < length(phaseCfg.blockSpeciesOrder) && mod((b - 1),phaseCfg.impedanceAfter_nBlocks) == 0
    showInstruct = false;
  end
else
  showInstruct = true;
end

if showInstruct
  for inst = 1:length(phaseCfg.instruct.name)
    WaitSecs(1.000);
    et_showTextInstruct(w,phaseCfg.instruct.name(inst),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
      {'blockNum','nSpecies','theseSpecies'},{num2str(b),num2str(nSpecies),theseSpeciesStr});
  end
  % Wait a second before starting trial
  WaitSecs(1.000);
end

%% run the naming task

% only check these keys
RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
  cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);

% start the blink break timer
if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
  blinkTimerStart = GetSecs;
end

% store accuracy and response time
trialAcc = false(length(stimTex),1);
trialRT = zeros(length(stimTex),1,'int32');

for i = trialNum:length(stimTex)
  % do an impedance check after a certain number of blocks or trials
  if runInBlocks
    if expParam.useNS && phaseCfg.isExp && b > 1 && b < length(phaseCfg.blockSpeciesOrder) && mod((b - 1),phaseCfg.impedanceAfter_nBlocks) == 0 && i == 1
      % run the impedance break before trial 1 of this block starts
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
      
      % show the instructions after the impedance check
      for inst = 1:length(phaseCfg.instruct.name)
        WaitSecs(1.000);
        et_showTextInstruct(w,phaseCfg.instruct.name(inst),cfg.keys.instructContKey,...
          cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
          {'blockNum','nSpecies','theseSpecies'},{num2str(b),num2str(nSpecies),theseSpeciesStr});
      end
      % Wait a second before starting trial
      WaitSecs(1.000);
      
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
        cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
      
      % reset the blink timer
      if cfg.stim.secUntilBlinkBreak > 0
        blinkTimerStart = GetSecs;
      end
    end
  else
    if expParam.useNS && phaseCfg.isExp && i > 1 && i < length(stimTex) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'IMPEDANCE_END');
      
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
        cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
      
      % reset the blink timer
      if cfg.stim.secUntilBlinkBreak > 0
        blinkTimerStart = GetSecs;
      end
    end
  end
  
  % Do a blink break if recording EEG and specified time has passed
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(stimTex) - 3)
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_START');
    fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_START');
    Screen('TextSize', w, cfg.text.basicTextSize);
    pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(stimTex));
    % just draw straight into the main window since we don't need speed here
    DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % listen for any keypress on any keyboard
    RestrictKeysForKbCheck([]);
    thisGetSecs = KbWait(-1,2);
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_END');
    fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCfg.isExp,'BLINK_END');
    % only check these keys
    RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
      cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
    
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
  if any(nameStims(i).familyNum == famNumSubord)
    isSubord = true;
    specNum = int32(nameStims(i).speciesNum);
  elseif any(nameStims(i).familyNum == famNumBasic)
    isSubord = false;
    specNum = int32(0);
  end
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.name_isi > 0
    WaitSecs(phaseCfg.name_isi);
  end
  
  % draw fixation
  Screen('TextSize', w, cfg.text.fixSize);
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  [preStimFixOn] = Screen('Flip',w);
  % fixation on screen before stim for a random amount of time
  WaitSecs(phaseCfg.name_preStim(1) + ((phaseCfg.name_preStim(2) - phaseCfg.name_preStim(1)).*rand(1,1)));
  
  % draw the stimulus
  Screen('DrawTexture', w, stimTex(i), [], stimImgRect);
  % and fixation on top of it
  Screen('TextSize', w, cfg.text.fixSize);
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [imgOn, stimOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, species num: %d.\n',i,length(stimTex),nameStims(i).fileName,specNum);
  end
  
  % while loop to show stimulus until "duration" seconds elapsed.
  while (GetSecs - stimOnset) <= phaseCfg.name_stim
    % check for too-fast response
    if ~phaseCfg.respDuringStim
      [keyIsDown] = KbCheck;
      % if they press a key too early, tell them they responded too fast
      if keyIsDown
        % draw the stimulus
        Screen('DrawTexture', w, stimTex(i), [], stimImgRect);
        % and fixation on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        % and the "too fast" text
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
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
          % if (GetSecs - startRT) > phaseCfg.name_stim
          %   break
          % end
        end
        % if cfg.text.printTrialInfo
        %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
        % end
        
        break
      elseif keyIsDown && sum(keyCode) > 1
        % draw the stimulus
        Screen('DrawTexture', w, stimTex(i), [], stimImgRect);
        % and fixation on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
  while (GetSecs - stimOnset) <= phaseCfg.name_stim
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  keyIsDown = logical(keyIsDown);
  
  if keyIsDown
    % if they hit a key while the stimulus was on the screen (the only way
    % keyIsDown==1), wait out any remaining stimulus time, take the
    % stimulus off screen, and give feedback (species number)
    
    % wait out any remaining time
    while (GetSecs - stimOnset) <= phaseCfg.name_stim
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    if (keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 1 && all(keyCode(~cfg.keys.(sprintf('s%.2d',specNum))) == 0))
      sNumColor = correct_sNumColor;
      if phaseCfg.playSound
        respSound = phaseCfg.correctSound;
        respVol = phaseCfg.correctVol;
      end
    elseif keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 0
      sNumColor = incorrect_sNumColor;
      if phaseCfg.playSound
        respSound = phaseCfg.incorrectSound;
        respVol = phaseCfg.incorrectVol;
      end
    end
    % draw species number in the appropriate color
    Screen('TextSize', w, cfg.text.basicTextSize);
    if specNum > 0
      DrawFormattedText(w,num2str(specNum),'center','center',sNumColor, cfg.text.instructCharWidth);
    else
      DrawFormattedText(w,cfg.text.basicFamStr,'center','center',sNumColor, cfg.text.instructCharWidth);
    end
    Screen('Flip', w);
    
    if phaseCfg.playSound
      Beeper(respSound,respVol);
    end
    
    respPromptOn = NaN;
    
  else
    % draw response prompt
    Screen('TextSize', w, cfg.text.basicTextSize);
    DrawFormattedText(w,cfg.text.respSymbol,'center','center',initial_sNumColor, cfg.text.instructCharWidth);
    [respPromptOn, startRT] = Screen('Flip',w);
    
    % poll for a resp
    while (GetSecs - startRT) <= phaseCfg.name_response
      
      [keyIsDown, endRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(0.0001);
          
          % % proceed if time is up, regardless of whether key is held
          % if (GetSecs - startRT) > phaseCfg.name_response
          %   break
          % end
        end
        % if cfg.text.printTrialInfo
        %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
        % end
        
        % give immediate feedback
        if (keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 1 && all(keyCode(~cfg.keys.(sprintf('s%.2d',specNum))) == 0))
          sNumColor = correct_sNumColor;
          if phaseCfg.playSound
            respSound = phaseCfg.correctSound;
            respVol = phaseCfg.correctVol;
          end
        elseif keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 0
          sNumColor = incorrect_sNumColor;
          if phaseCfg.playSound
            respSound = phaseCfg.incorrectSound;
            respVol = phaseCfg.incorrectVol;
          end
        end
        % draw species number in the appropriate color
        Screen('TextSize', w, cfg.text.basicTextSize);
        if specNum > 0
          DrawFormattedText(w,num2str(specNum),'center','center',sNumColor, cfg.text.instructCharWidth);
        else
          DrawFormattedText(w,cfg.text.basicFamStr,'center','center',sNumColor, cfg.text.instructCharWidth);
        end
        Screen('Flip', w);
        
        if phaseCfg.playSound
          Beeper(respSound,respVol);
        end
        
        break
      elseif keyIsDown && sum(keyCode) > 1
        % draw response prompt
        Screen('TextSize', w, cfg.text.basicTextSize);
        DrawFormattedText(w,cfg.text.respSymbol,'center','center',initial_sNumColor, cfg.text.instructCharWidth);
        % don't push multiple keys
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        % put them on the screen
        Screen('Flip',w);
        
        keyIsDown = 0;
      end
      % wait so we don't overload the system
      WaitSecs(0.0001);
    end
    
    keyIsDown = logical(keyIsDown);
    
    % % don't do this, just show the feedback
    % % wait out any remaining time
    % while (GetSecs - startRT) <= phaseCfg.name_response
    %   % Wait <1 ms before checking the keyboard again to prevent
    %   % overload of the machine at elevated Priority():
    %   WaitSecs(0.0001);
    % end
    
    % if they didn't respond, show correct response
    if ~keyIsDown
      sNumColor = incorrect_sNumColor;
      Screen('TextSize', w, cfg.text.basicTextSize);
      if specNum > 0
        DrawFormattedText(w,num2str(specNum),'center','center',sNumColor, cfg.text.instructCharWidth);
      else
        DrawFormattedText(w,cfg.text.basicFamStr,'center','center',sNumColor, cfg.text.instructCharWidth);
      end
      % "need to respond faster"
      Screen('TextSize', w, cfg.text.instructTextSize);
      DrawFormattedText(w,cfg.text.respondFaster,'center',respondFasterY,cfg.text.respondFasterColor, cfg.text.instructCharWidth);
      
      Screen('Flip', w);
      
      if phaseCfg.playSound
        respSound = phaseCfg.incorrectSound;
        respVol = phaseCfg.incorrectVol;
        Beeper(respSound,respVol);
      end
      
      % need a new endRT
      endRT = GetSecs;
    end
  end
  
  % wait to let them view the feedback
  WaitSecs(phaseCfg.name_feedback);
  
  % draw fixation
  Screen('TextSize', w, cfg.text.fixSize);
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  
  % Clear screen to background color after response
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', stimTex(i));
  
  % compute response time
  if phaseCfg.respDuringStim
    measureRTfromHere = stimOnset;
  else
    measureRTfromHere = startRT;
  end
  trialRT(i) = int32(round(1000 * (endRT - measureRTfromHere)));
  
  % compute accuracy
  if keyIsDown && sum(keyCode) == 1
    if (keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 1 && all(keyCode(~cfg.keys.(sprintf('s%.2d',specNum))) == 0))
      % pushed the right key
      trialAcc(i) = true;
    elseif keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 0
      % pushed the wrong key
      trialAcc(i) = false;
    end
  else
    % did not push a key
    trialAcc(i) = false;
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
    respKey = 'none';
  end
  
  % figure out which species number was chosen
  fn = fieldnames(cfg.keys);
  if keyIsDown && sum(keyCode) == 1
    % if they made a response
    for s = 1:length(fn)
      % go through each key fieldname that is s##
      if length(fn{s}) == 3 && strcmp(fn{s}(1),'s')
        if find(keyCode) == cfg.keys.(fn{s})
          % if the key that got hit is the same as this fieldname, then
          % this is the species that we want
          resp = num2str(str2double(fn{s}(2:3)));
          break
        end
      end
    end
  elseif keyIsDown && sum(keyCode) > 1
    warning('Multiple keys were pressed.\n');
    resp = 'ERROR_MULTIKEY';
  else
    resp = 'none';
  end
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, species num: %d. response: %s (key: %s; acc = %d; rt = %d)\n',i,length(stimTex),nameStims(i).fileName,specNum,resp,respKey,trialAcc(i),trialRT(i));
  end
  
  fNum = int32(nameStims(i).familyNum);
  
  %% session log file
  
  % Write stimulus presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%s\t%i\t%i\t%i\t%i\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'NAME_STIM',...
    b,...
    i,...
    nameStims(i).familyStr,...
    nameStims(i).speciesStr,...
    nameStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum);
  
  % Write response to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%s\t%i\t%i\t%i\t%i\t%s\t%s\t%i\t%i\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'NAME_RESP',...
    b,...
    i,...
    nameStims(i).familyStr,...
    nameStims(i).speciesStr,...
    nameStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum,...
    resp,...
    respKey,...
    trialAcc(i),...
    trialRT(i));
  
  %% phase log file
  
  % Write stimulus presentation to file:
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%s\t%i\t%i\t%i\t%i\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'NAME_STIM',...
    b,...
    i,...
    nameStims(i).familyStr,...
    nameStims(i).speciesStr,...
    nameStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum);
  
  % Write response to file:
  fprintf(plf,'%f\t%s\t%s\t%s\t%d\t%s\t%i\t%i\t%s\t%s\t%i\t%i\t%i\t%i\t%s\t%s\t%i\t%i\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCfg.isExp,...
    'NAME_RESP',...
    b,...
    i,...
    nameStims(i).familyStr,...
    nameStims(i).speciesStr,...
    nameStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum,...
    resp,...
    respKey,...
    trialAcc(i),...
    trialRT(i));
  
  %% Write netstation logs
  
  if expParam.useNS
    % Write trial info to et_NetStation
    % mark every event with the following key code/value pairs
    % 'subn', subject number
    % 'sess', session type
    % 'phase', session phase name
    % 'expt', whether this is the experiment (1) or practice (0)
    % 'bloc', block number (training day 1 only)
    % 'trln', trial number
    % 'stmn', stimulus name (family, species, exemplar)
    % 'famn', family number
    % 'spcn', species number (corresponds to keyboard)
    % 'sord', whether this is a subordinate (1) or basic (0) level family
    % 'rsps', response string
    % 'rspk', the name of the key pressed
    % 'rspt', the response time
    % 'corr', accuracy code (1=correct, 0=incorrect)
    % 'keyp', key pressed?(1=yes, 0=no)
    
    % write out the stimulus name
    stimName = sprintf('%s%s%d',...
      nameStims(i).familyStr,...
      nameStims(i).speciesStr,...
      nameStims(i).exemplarName);
    
    % pretrial fixation
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', preStimFixOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'bloc', b,...
      'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
      'rsps', resp, 'rspk', respKey, 'rspt', trialRT(i), 'corr', trialAcc(i), 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    % img presentation
    [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', imgOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'bloc', b,...
      'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
      'rsps', resp, 'rspk', respKey, 'rspt', trialRT(i), 'corr', trialAcc(i), 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    if ~isnan(respPromptOn)
      % response prompt
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'PROM', respPromptOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
        'expt',phaseCfg.isExp,...
        'bloc', b,...
        'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
        'rsps', resp, 'rspk', respKey, 'rspt', trialRT(i), 'corr', trialAcc(i), 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % did they make a response?
    if keyIsDown
      % button push
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'RESP', endRT, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName,...
      'expt',phaseCfg.isExp,...
      'bloc', b,...
      'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
      'rsps', resp, 'rspk', respKey, 'rspt', trialRT(i), 'corr', trialAcc(i), 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
  end % useNS
  
  % mark that we finished this trial
  trialComplete(i) = true;
  % save progress after each trial
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% print accuracy and correct trial RT
accRtText = sprintf('You got %d out of %d correct.\nFor the correct trials, on average you responded in %i ms.\n\nPress "%s" to continue.',sum(trialAcc),length(stimTex),round(mean(trialRT(trialAcc))),cfg.keys.instructContKey);
Screen('TextSize', w, cfg.text.instructTextSize);
DrawFormattedText(w,accRtText,'center','center',cfg.text.instructColor, cfg.text.instructCharWidth);
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
expParam.session.(sesName).(phaseName)(phaseCount).endTime{b} = endTime;
% put it in the log file
fprintf(logFile,'!!! End of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,endTime);
fprintf(plf,'!!! End of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,endTime);

% close the phase log file
fclose(plf);

% save progress after finishing phase
phaseComplete = true; %#ok<NASGU>
save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');

end % function

function [cfg,expParam] = et_viewing(w,cfg,expParam,logFile,sesName,phaseName,phaseCount,b)
% function [cfg,expParam] = et_viewing(w,cfg,expParam,logFile,sesName,phaseName,phaseCount,b)
%
% Descrption:
%  This function runs the viewing task.
%
%  Exposure: picture paired with label, must push corresponding key during
%  viewing so subjects learn better. Green if correct, red if incorrect.
%
%  The stimuli for the viewing task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phaseName).viewStims as a
%  struct.
%
% Inputs:
%  b:        Block number. Optional. Do not enter anything if only 1 block.
%
% Outputs:
%
%
%
% NB:
%  Once agian, stimuli must already be sorted in presentation order!
%

% % durations, in seconds
% cfg.stim.(sesName).(phaseName).view_isi = 0.8;
% cfg.stim.(sesName).(phaseName).view_preStim = 0.2;
% cfg.stim.(sesName).(phaseName).view_stim = 4.0;

% % keys
% cfg.keys.sXX, where XX is an integer, buffered with a zero if i <= 9
% cfg.keys.s00 is "other" (basic) family

fprintf('Running %s %s (view) (%d)...\n',sesName,phaseName,phaseCount);

phaseNameForParticipant = 'viewing';

%% set up blocks

% Small hack. Because training day 1 uses blocks, those stims are stored in
% cells. However, all other training days do not use blocks, and do not use
% cells, but we need to put them in a cell to access the stimuli correctly.
viewStims = expParam.session.(sesName).(phaseName)(phaseCount).viewStims;
if ~iscell(viewStims)
  runInBlocks = false;
  viewStims = {viewStims};
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
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_%d_view_b%d.mat',sesName,phaseName,phaseCount,b));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(viewStims{b}));
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

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_view_%d_b%d.txt',sesName,phaseName,phaseCount,b));
phLFile = fopen(phaseLogFile,'at');

%% record the starting date and time for this phase

expParam.session.(sesName).(phaseName)(phaseCount).date{b} = thisDate;
expParam.session.(sesName).(phaseName)(phaseCount).startTime{b} = startTime;

% put it in the log file
fprintf(logFile,'!!! Start of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,startTime);
fprintf(phLFile,'!!! Start of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,startTime);

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
viewStims = viewStims{b};

if phaseCfg.isExp
  stimDir = cfg.files.stimDir;
else
  stimDir = cfg.files.stimDir_prac;
end

% default is to preload the images
if ~isfield(cfg.stim,'preloadImages')
  cfg.stim.preloadImages = false;
end

% set the basic and subordinate family numbers
if phaseCfg.isExp
  famNumSubord = cfg.stim.famNumSubord;
  famNumBasic = cfg.stim.famNumBasic;
else
  famNumSubord = cfg.stim.practice.famNumSubord;
  famNumBasic = cfg.stim.practice.famNumBasic;
end

% set text color for species numbers
initial_sNumColor = uint8((rgb('Black') * 255) + 0.5);
correct_sNumColor = uint8((rgb('Green') * 255) + 0.5);
incorrect_sNumColor = uint8((rgb('Red') * 255) + 0.5);

% for "respond faster" text
[~,respondFasterY] = RectCenter(cfg.screen.wRect);
respondFasterY = respondFasterY + (cfg.screen.wRect(RectBottom) * 0.04);

% read the proper response key image, if desired
if ~isfield(phaseCfg,'respKeyWithPrompt')
  phaseCfg.respKeyWithPrompt = false;
end
if phaseCfg.respKeyWithPrompt
  if phaseCfg.isExp
    respKeyImg = imread(cfg.files.speciesNumKeyImg);
    respKeyImgHeight = size(respKeyImg,1) * cfg.files.speciesNumKeyImgScale;
    respKeyImgWidth = size(respKeyImg,2) * cfg.files.speciesNumKeyImgScale;
  else
    respKeyImg = imread(cfg.files.practice.speciesNumKeyImg);
    respKeyImgHeight = size(respKeyImg,1) * cfg.files.practice.speciesNumKeyImgScale;
    respKeyImgWidth = size(respKeyImg,2) * cfg.files.practice.speciesNumKeyImgScale;
  end
  respKeyImg = Screen('MakeTexture',w,respKeyImg);
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
Screen('TextSize', w, cfg.text.basicTextSize);
respRect = Screen('TextBounds', w, cfg.text.respSymbol);
% center it in the middle of the screen
respRect = CenterRect(respRect, cfg.screen.wRect);
% get the X and Y coordinates
respRectX = respRect(1);
respRectY = respRect(2);

%% preload all stimuli for presentation

if cfg.stim.preloadImages
  message = sprintf('Preparing images, please wait...');
  Screen('TextSize', w, cfg.text.basicTextSize);
  % put the "preparing" message on the screen
  DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
end
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
% Update the display to show the message:
Screen('Flip', w);

% initialize
viewStimTex = nan(1,length(viewStims));

for i = 1:length(viewStims)
  % make sure this stimulus exists
  stimImgFile = fullfile(stimDir,viewStims(i).familyStr,viewStims(i).fileName);
  if exist(stimImgFile,'file')
    if cfg.stim.preloadImages
      % load up this stim's texture
      stimImg = imread(stimImgFile);
      viewStimTex(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %viewStimTex(i) = Screen('MakeTexture',w,stimImg,[],1);
    elseif ~cfg.stim.preloadImages && i == length(viewStims)
      % still need to load the last image to set the rectangle
      stimImg = imread(fullfile(stimDir,viewStims(i).familyStr,viewStims(i).fileName));
    end
  else
    error('Study stimulus %s does not exist!',stimImgFile);
  end
end

% get the width and height of the final stimulus image
stimImgHeight = size(stimImg,1) * cfg.stim.stimScale;
stimImgWidth = size(stimImg,2) * cfg.stim.stimScale;
stimImgRect = [0 0 stimImgWidth stimImgHeight];
stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);

% set the response key image rectangle
respKeyImgRect = SetRect(0, 0, respKeyImgWidth, respKeyImgHeight);
respKeyImgRect = CenterRect(respKeyImgRect, cfg.screen.wRect);
respKeyImgRect = AlignRect(respKeyImgRect, cfg.screen.wRect, 'bottom', 'bottom');
% respKeyImgRect = CenterRect([0 0 respKeyImgWidth respKeyImgHeight], stimImgRect);
% respKeyImgRect = AdjoinRect(respKeyImgRect, stimImgRect, RectBottom);

% text location for error (e.g., "too fast") text
[~,errorTextY] = RectCenter(cfg.screen.wRect);
errorTextY = errorTextY + (stimImgHeight / 2);

% y-coordinate for stimulus number (below stim by 4% of the screen height)
sNumY = round(stimImgRect(RectBottom) + (cfg.screen.wRect(RectBottom) * 0.04));

if runInBlocks
  theseSpecies = unique(phaseCfg.blockSpeciesOrder{b});
else
  theseSpecies = unique([viewStims.speciesNum]);
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
  if ~expParam.photoCellTest
    for inst = 1:length(phaseCfg.instruct.view)
      WaitSecs(1.000);
      et_showTextInstruct(w,cfg,phaseCfg.instruct.view(inst),cfg.keys.instructContKey,...
        cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
        {'blockNum','nSpecies','theseSpecies'},{num2str(b),num2str(nSpecies),theseSpeciesStr});
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
    if runInBlocks
      readyMsg.text = sprintf('Ready to begin%s %s phase (block %d).\nPress "%s" to start.',expStr,phaseNameForParticipant,b,cfg.keys.instructContKey);
    else
      readyMsg.text = sprintf('Ready to begin%s %s phase.\nPress "%s" to start.',expStr,phaseNameForParticipant,cfg.keys.instructContKey);
    end
    et_showTextInstruct(w,cfg,readyMsg,cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
end

%% run the viewing task

if isfield(cfg.keys,'s00')
  restrictKeysStr = ', cfg.keys.s00';
else
  restrictKeysStr = '';
end
for i = 1:length(cfg.keys.speciesKeyNames)
  % sXX, where XX is an integer, buffered with a zero if i <= 9
  restrictKeysStr = cat(2,restrictKeysStr,sprintf(', cfg.keys.s%.2d',i));
end
restrictKeysStr = sprintf('[%s]',restrictKeysStr(3:end));

% only check these keys
RestrictKeysForKbCheck(eval(restrictKeysStr));
% RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
%   cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);

% start the blink break timer
if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
  blinkTimerStart = GetSecs;
end

for i = trialNum:length(viewStims)
  % do an impedance check after a certain number of blocks or trials
  if runInBlocks
    if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && b > 1 && b < length(phaseCfg.blockSpeciesOrder) && mod((b - 1),phaseCfg.impedanceAfter_nBlocks) == 0 && i == 1
      % run the impedance break before trial 1 of this block starts
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      if ~expParam.photoCellTest
        % show the instructions after the impedance check
        for inst = 1:length(phaseCfg.instruct.view)
          WaitSecs(1.000);
          et_showTextInstruct(w,cfg,phaseCfg.instruct.view(inst),cfg.keys.instructContKey,...
            cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
            {'blockNum','nSpecies','theseSpecies'},{num2str(b),num2str(nSpecies),theseSpeciesStr});
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
        readyMsg.text = sprintf('Ready to begin%s %s phase (block %d).\nPress "%s" to start.',expStr,phaseNameForParticipant,b,cfg.keys.instructContKey);
        et_showTextInstruct(w,cfg,readyMsg,cfg.keys.instructContKey,...
          cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
        % Wait a second before starting trial
        WaitSecs(1.000);
        
        % only check these keys
        RestrictKeysForKbCheck(eval(restrictKeysStr));
        % RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
        %   cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
        
        % reset the blink timer
        if cfg.stim.secUntilBlinkBreak > 0
          blinkTimerStart = GetSecs;
        end
      end
    end
  else
    if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(viewStims) && mod((i - 1),phaseCfg.impedanceAfter_nTrials)
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      % only check these keys
      RestrictKeysForKbCheck(eval(restrictKeysStr));
      % RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
      %   cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.view_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.view_isi == 0 && phaseCfg.fixDuringPreStim)
        Screen('TextSize', w, cfg.text.fixSize);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      end
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
      WaitSecs(1.0);
      
      % reset the blink timer
      if cfg.stim.secUntilBlinkBreak > 0
        blinkTimerStart = GetSecs;
      end
    end
  end
  
  % Do a blink break if specified time has passed
  if ~expParam.photoCellTest && phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(viewStims) - 3)
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    Screen('TextSize', w, cfg.text.basicTextSize);
    if expParam.useNS
      pauseMsg = 'Blink now.\n\n';
    else
      pauseMsg = '';
    end
    pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, length(viewStims));
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
    RestrictKeysForKbCheck(eval(restrictKeysStr));
    % RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
    %   cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
    
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if (phaseCfg.view_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.view_isi == 0 && phaseCfg.fixDuringPreStim)
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
  
  % load the stimulus now if we didn't load it earlier
  if ~cfg.stim.preloadImages
    stimImg = imread(fullfile(stimDir,viewStims(i).familyStr,viewStims(i).fileName));
    viewStimTex(i) = Screen('MakeTexture',w,stimImg);
  end
  
  % Is this a subordinate (1) or basic (0) family/species? If subordinate,
  % get the species number.
  if any(viewStims(i).familyNum == famNumSubord)
    isSubord = true;
    specNum = int32(viewStims(i).speciesNum);
  elseif any(viewStims(i).familyNum == famNumBasic)
    isSubord = false;
    specNum = int32(0);
  end
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.view_isi > 0
    if phaseCfg.fixDuringISI
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
    end
    WaitSecs(phaseCfg.view_isi);
  end
  
  % preStimulus period, with fixation if desired
  if length(phaseCfg.view_preStim) == 1
    if phaseCfg.view_preStim > 0
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [preStimFixOn] = Screen('Flip',w);
      else
        preStimFixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      WaitSecs(phaseCfg.view_preStim);
    end
  elseif length(phaseCfg.view_preStim) == 2
    if ~all(phaseCfg.view_preStim == 0)
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [preStimFixOn] = Screen('Flip',w);
      else
        preStimFixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      % fixation on screen before stim for a random amount of time
      WaitSecs(phaseCfg.view_preStim(1) + ((phaseCfg.view_preStim(2) - phaseCfg.view_preStim(1)).*rand(1,1)));
    end
  end
  
  % draw the stimulus
  Screen('DrawTexture', w, viewStimTex(i), [], stimImgRect);
  if phaseCfg.fixDuringStim
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  end
  % and species number below it
  Screen('TextSize', w, cfg.text.basicTextSize);
  if specNum > 0
    DrawFormattedText(w,num2str(specNum),'center',sNumY,initial_sNumColor, cfg.text.instructCharWidth);
  else
    DrawFormattedText(w,cfg.text.basicFamStr,'center',sNumY,initial_sNumColor, cfg.text.instructCharWidth);
  end
  if phaseCfg.respKeyWithPrompt
    % with the response key image
    Screen('DrawTexture', w, respKeyImg, [], respKeyImgRect);
  end
  
  % photocell rect with stim
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
  end
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [imgOn, stimOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, species num: %d.\n',i,length(viewStims),viewStims(i).fileName,specNum);
  end
  
  % while loop to show stimulus until subject response or until
  % "duration" seconds elapse.
  %
  % if we get a keyhit, change the color of the species number
  while (GetSecs - stimOnset) <= phaseCfg.view_stim
    
    [keyIsDown, endRT, keyCode] = KbCheck;
    % if they push more than one key, don't accept it
    if keyIsDown && sum(keyCode) == 1
      % wait for key to be released
      while KbCheck(-1)
        WaitSecs(0.0001);
        
        % % proceed if time is up, regardless of whether key is held
        % if (GetSecs - startRT) > phaseCfg.view_stim
        %   break
        % end
      end
      % if cfg.text.printTrialInfo
      %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - stimOnset);
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
      % draw the stimulus
      Screen('DrawTexture', w, viewStimTex(i), [], stimImgRect);
      if phaseCfg.fixDuringStim
        % and fixation on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      end
      % and species number below it in the appropriate color
      Screen('TextSize', w, cfg.text.basicTextSize);
      if specNum > 0
        DrawFormattedText(w,num2str(specNum),'center',sNumY,sNumColor, cfg.text.instructCharWidth);
      else
        DrawFormattedText(w,cfg.text.basicFamStr,'center',sNumY,sNumColor, cfg.text.instructCharWidth);
      end
      % photocell rect with stim
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      
      if phaseCfg.playSound
        Beeper(respSound,respVol);
      end
      
      break
    elseif keyIsDown && sum(keyCode) > 1
      % draw response prompt
      Screen('TextSize', w, cfg.text.basicTextSize);
      %DrawFormattedText(w,cfg.text.respSymbol,'center','center',initial_sNumColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, initial_sNumColor);
      if phaseCfg.respKeyWithPrompt
        % with the response key image
        Screen('DrawTexture', w, respKeyImg, [], respKeyImgRect);
      end
      % don't push multiple keys
      Screen('TextSize', w, cfg.text.instructTextSize);
      DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      % put them on the screen
      Screen('Flip',w);
      
      keyIsDown = 0;
    end
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  keyIsDown = logical(keyIsDown);
  
  % wait out any remaining time
  while (GetSecs - stimOnset) <= phaseCfg.view_stim
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % if they didn't make a response, give "incorrect" feedback
  if ~keyIsDown
    % draw the stimulus
    Screen('DrawTexture', w, viewStimTex(i), [], stimImgRect);
    if phaseCfg.fixDuringStim
      % and fixation on top of it
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
    end
    % and species number below it in the appropriate color
    Screen('TextSize', w, cfg.text.basicTextSize);
    if specNum > 0
      DrawFormattedText(w,num2str(specNum),'center',sNumY,incorrect_sNumColor, cfg.text.instructCharWidth);
    else
      DrawFormattedText(w,cfg.text.basicFamStr,'center',sNumY,incorrect_sNumColor, cfg.text.instructCharWidth);
    end
    % "need to respond faster"
    Screen('TextSize', w, cfg.text.instructTextSize);
    DrawFormattedText(w,cfg.text.respondFaster,'center',respondFasterY,cfg.text.respondFasterColor, cfg.text.instructCharWidth);
    % photocell rect with stim
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    if phaseCfg.playSound
      Beeper(phaseCfg.incorrectSound);
    end
    
    % need a new endRT
    endRT = GetSecs;
    
    % give an extra bit of time to see the number
    WaitSecs(cfg.text.respondFasterFeedbackTime);
  end
  
  if (phaseCfg.view_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.view_isi == 0 && phaseCfg.fixDuringPreStim)
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  end
  
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % Clear screen to background color after response
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', viewStimTex(i));
  
  % compute response time
  rt = int32(round(1000 * (endRT - stimOnset)));
  
  % compute accuracy
  if keyIsDown && sum(keyCode) == 1
    if (keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 1 && all(keyCode(~cfg.keys.(sprintf('s%.2d',specNum))) == 0))
      % pushed the right key
      acc = true;
    elseif keyCode(cfg.keys.(sprintf('s%.2d',specNum))) == 0
      % pushed the wrong key
      acc = false;
    end
  else
    % did not push a key
    acc = false;
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
    fprintf('Trial %d of %d: %s, species num: %d. response: %s (key: %s; acc = %d; rt = %d)\n',i,length(viewStims),viewStims(i).fileName,specNum,resp,respKey,acc,rt);
  end
  
  fNum = int32(viewStims(i).familyNum);
  
  %% session log file
  
  % Write stimulus presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'VIEW_STIM',...
    b,...
    i,...
    viewStims(i).familyStr,...
    viewStims(i).speciesStr,...
    viewStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum);
  
  % Write response to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'VIEW_RESP',...
    b,...
    i,...
    viewStims(i).familyStr,...
    viewStims(i).speciesStr,...
    viewStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum,...
    resp,...
    respKey,...
    acc,...
    rt);
  
  %% phase log file
  
  % Write stimulus presentation to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'VIEW_STIM',...
    b,...
    i,...
    viewStims(i).familyStr,...
    viewStims(i).speciesStr,...
    viewStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum);
  
  % Write response to file:
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
    phaseCfg.isExp,...
    'VIEW_RESP',...
    b,...
    i,...
    viewStims(i).familyStr,...
    viewStims(i).speciesStr,...
    viewStims(i).exemplarName,...
    isSubord,...
    specNum,...
    fNum,...
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
    % 'phas', session phase name
    % 'pcou', phase count
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
      viewStims(i).familyStr,...
      viewStims(i).speciesStr,...
      viewStims(i).exemplarName);
    
    if ~isnan(preStimFixOn)
      % pretrial fixation
      [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % img presentation
    [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', imgOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
      'expt',phaseCfg.isExp,...
      'bloc', int32(b),...
      'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
      'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    % did they make a response?
    if keyIsDown
      % button push
      [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
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
expParam.session.(sesName).(phaseName)(phaseCount).endTime{b} = endTime;
% put it in the log file
fprintf(logFile,'!!! End of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,endTime);
fprintf(phLFile,'!!! End of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,endTime);

% close phase log file
fclose(phLFile);

% save progress after finishing phase
phaseComplete = true; %#ok<NASGU>
save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');

end % function

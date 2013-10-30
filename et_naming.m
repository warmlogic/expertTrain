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

phaseNameForParticipant = 'naming';

%% set up blocks

% Small hack. Because training day 1 uses blocks, those stims are stored in
% cells. However, all other training days do not use blocks, and do not use
% cells, but we need to put them in a cell to access the stimuli correctly.
nameStims = expParam.session.(sesName).(phaseName)(phaseCount).nameStims;
if ~iscell(nameStims)
  runInBlocks = false;
  nameStims = {nameStims};
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
  trialComplete = false(1,length(nameStims{b}));
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
nameStims = nameStims{b};

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
% Update the display to show the message:
Screen('Flip', w);

% initialize
nameStimTex = nan(1,length(nameStims));

for i = 1:length(nameStims)
  % make sure this stimulus exists
  stimImgFile = fullfile(stimDir,nameStims(i).familyStr,nameStims(i).fileName);
  if exist(stimImgFile,'file')
    if cfg.stim.preloadImages
      % load up this stim's texture
      stimImg = imread(stimImgFile);
      nameStimTex(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %nameStimTex(i) = Screen('MakeTexture',w,stimImg,[],1);
    elseif ~cfg.stim.preloadImages && i == length(nameStims)
      % still need to load the last image to set the rectangle
      stimImg = imread(fullfile(stimDir,nameStims(i).familyStr,nameStims(i).fileName));
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
    for inst = 1:length(phaseCfg.instruct.name)
      WaitSecs(1.000);
      et_showTextInstruct(w,phaseCfg.instruct.name(inst),cfg.keys.instructContKey,...
        cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
        {'blockNum','nSpecies','theseSpecies'},{num2str(b),num2str(nSpecies),theseSpeciesStr});
    end
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
  
  %% questions? only during practice. continues with experimenter's key.
  
  if ~expParam.photoCellTest && ~phaseCfg.isExp && phaseCfg.instruct.questions
    questionsMsg.text = sprintf('If you have any questions about the %s phase,\nplease ask the experimenter now.\n\nPlease tell the experimenter when you are ready to begin the task.',phaseNameForParticipant);
    et_showTextInstruct(w,questionsMsg,cfg.keys.expContinue,...
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
    et_showTextInstruct(w,readyMsg,cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
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
trialAcc = false(length(nameStims),1);
trialRT = zeros(length(nameStims),1,'int32');

for i = trialNum:length(nameStims)
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
        for inst = 1:length(phaseCfg.instruct.name)
          WaitSecs(1.000);
          et_showTextInstruct(w,phaseCfg.instruct.name(inst),cfg.keys.instructContKey,...
            cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth,...
            {'blockNum','nSpecies','theseSpecies'},{num2str(b),num2str(nSpecies),theseSpeciesStr});
        end
        % Wait a second before starting trial
        WaitSecs(1.000);
      end
      
      %% questions? only during practice. continues with experimenter's key.
      
      if ~expParam.photoCellTest && ~phaseCfg.isExp && phaseCfg.instruct.questions
        questionsMsg.text = sprintf('If you have any questions about the %s phase,\nplease ask the experimenter now.\n\nPlease tell the experimenter when you are ready to begin the task.',phaseNameForParticipant);
        et_showTextInstruct(w,questionsMsg,cfg.keys.expContinue,...
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
        et_showTextInstruct(w,readyMsg,cfg.keys.instructContKey,...
          cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
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
    end
  else
    if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(nameStims) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
        cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.name_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.name_isi == 0 && phaseCfg.fixDuringPreStim)
        Screen('TextSize', w, cfg.text.fixSize);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
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
  if ~expParam.photoCellTest && phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(nameStims) - 3)
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    Screen('TextSize', w, cfg.text.basicTextSize);
    if expParam.useNS
      pauseMsg = 'Blink now.\n\n';
    else
      pauseMsg = '';
    end
    pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, length(nameStims));
    % just draw straight into the main window since we don't need speed here
    DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    
    % listen for any keypress on any keyboard
    RestrictKeysForKbCheck([]);
    thisGetSecs = KbWait(-1,2);
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
    % only check these keys
    RestrictKeysForKbCheck([cfg.keys.s01, cfg.keys.s02, cfg.keys.s03, cfg.keys.s04, cfg.keys.s05,...
      cfg.keys.s06, cfg.keys.s07, cfg.keys.s08, cfg.keys.s09, cfg.keys.s10, cfg.keys.s00]);
    
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if (phaseCfg.name_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.name_isi == 0 && phaseCfg.fixDuringPreStim)
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
    end
    Screen('Flip',w);
    WaitSecs(1.0);
    
    % reset the timer
    blinkTimerStart = GetSecs;
  end
  
  % load the stimulus now if we didn't load it earlier
  if ~cfg.stim.preloadImages
    stimImg = imread(fullfile(stimDir,nameStims(i).familyStr,nameStims(i).fileName));
    nameStimTex(i) = Screen('MakeTexture',w,stimImg);
  end

  % Is this a subordinate (1) or basic (0) family/species? If subordinate,
  % get the species number.
  if any(nameStims(i).familyNum == famNumSubord)
    isSubord = true;
    specNum = int32(nameStims(i).speciesNum);
  elseif any(nameStims(i).familyNum == famNumBasic)
    isSubord = false;
    specNum = int32(0);
  end
  
  % resynchronize netstation before the start of drawing
  if expParam.useNS
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.name_isi > 0
    if phaseCfg.fixDuringISI
      Screen('TextSize', w, cfg.text.fixSize);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      Screen('Flip',w);
    end
    WaitSecs(phaseCfg.name_isi);
  end
  
  % preStimulus period, with fixation if desired
  if length(phaseCfg.name_preStim) == 1
    if phaseCfg.name_preStim > 0
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        [preStimFixOn] = Screen('Flip',w);
      else
        preStimFixOn = NaN;
        Screen('Flip',w);
      end
      WaitSecs(phaseCfg.name_preStim);
    end
  elseif length(phaseCfg.name_preStim) == 2
    if ~all(phaseCfg.name_preStim == 0)
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        [preStimFixOn] = Screen('Flip',w);
      else
        preStimFixOn = NaN;
        Screen('Flip',w);
      end
      % fixation on screen before stim for a random amount of time
      WaitSecs(phaseCfg.name_preStim(1) + ((phaseCfg.name_preStim(2) - phaseCfg.name_preStim(1)).*rand(1,1)));
    end
  end
  
  % draw the stimulus
  Screen('DrawTexture', w, nameStimTex(i), [], stimImgRect);
  if phaseCfg.fixDuringStim
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  end
  
  if expParam.photoCellTest
    Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
  end
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [imgOn, stimOnset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: %s, species num: %d.\n',i,length(nameStims),nameStims(i).fileName,specNum);
  end
  
  % while loop to show stimulus until "duration" seconds elapsed.
  while (GetSecs - stimOnset) <= phaseCfg.name_stim
    % check for too-fast response
    if ~phaseCfg.respDuringStim
      [keyIsDown] = KbCheck;
      % if they press a key too early, tell them they responded too fast
      if keyIsDown
        % draw the stimulus
        Screen('DrawTexture', w, nameStimTex(i), [], stimImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        end
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
        Screen('DrawTexture', w, nameStimTex(i), [], stimImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
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
  while (GetSecs - stimOnset) <= phaseCfg.name_stim
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  keyIsDown = logical(keyIsDown);
  
  if keyIsDown
    % if they hit a key while the stimulus was on the screen (the only way
    % keyIsDown==1), take the stimulus off screen, and give feedback
    % (species number)
    
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
    % TODO: make text rectangles
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
    %DrawFormattedText(w,cfg.text.respSymbol,'center','center',initial_sNumColor, cfg.text.instructCharWidth);
    Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, initial_sNumColor);
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
        % TODO: make text rectangles
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
        %DrawFormattedText(w,cfg.text.respSymbol,'center','center',initial_sNumColor, cfg.text.instructCharWidth);
        Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, initial_sNumColor);
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
      % TODO: make text rectangles
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
  
  if (phaseCfg.name_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.name_isi == 0 && phaseCfg.fixDuringPreStim)
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
  end
  
  % Clear screen to background color after response
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', nameStimTex(i));
  
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
    fprintf('Trial %d of %d: %s, species num: %d. response: %s (key: %s; acc = %d; rt = %d)\n',i,length(nameStims),nameStims(i).fileName,specNum,resp,respKey,trialAcc(i),trialRT(i));
  end
  
  fNum = int32(nameStims(i).familyNum);
  
  %% session log file
  
  % Write stimulus presentation to file:
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
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
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
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
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
    imgOn,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
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
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
    endRT,...
    expParam.subject,...
    sesName,...
    phaseName,...
    phaseCount,...
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
      nameStims(i).familyStr,...
      nameStims(i).speciesStr,...
      nameStims(i).exemplarName);
    
    if ~isnan(preStimFixOn)
      % pretrial fixation
      [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
        'rsps', resp, 'rspk', respKey, 'rspt', trialRT(i), 'corr', trialAcc(i), 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % img presentation
    [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', imgOn, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
      'expt',phaseCfg.isExp,...
      'bloc', int32(b),...
      'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
      'rsps', resp, 'rspk', respKey, 'rspt', trialRT(i), 'corr', trialAcc(i), 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    
    if ~isnan(respPromptOn)
      % response prompt
      [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum, 'sord', isSubord,...
        'rsps', resp, 'rspk', respKey, 'rspt', trialRT(i), 'corr', trialAcc(i), 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
    end
    
    % did they make a response?
    if keyIsDown
      % button push
      [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
      'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
      'expt',phaseCfg.isExp,...
      'bloc', int32(b),...
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
accRtText = sprintf('You have finished the %s phase.\n\nYou got %d out of %d correct.\nFor the correct trials, on average you responded in %d ms.\n\nPress "%s" to continue.',phaseNameForParticipant,sum(trialAcc),length(trialAcc),round(mean(trialRT(trialAcc))),cfg.keys.instructContKey);
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
expParam.session.(sesName).(phaseName)(phaseCount).endTime{b} = endTime;
% put it in the log file
fprintf(logFile,'!!! End of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,endTime);
fprintf(phLFile,'!!! End of %s %s (%d) (block %d) (%s) %s %s\n',sesName,phaseName,phaseCount,b,mfilename,thisDate,endTime);

% close the phase log file
fclose(phLFile);

% save progress after finishing phase
phaseComplete = true; %#ok<NASGU>
save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');

end % function

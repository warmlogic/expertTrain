function [cfg,expParam] = et_compare(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_compare(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
%
% Description:
%  This function runs the comparison task. There are no blocks, only short
%  (blink) breaks.
%  TODO: Maybe add a longer break in the middle and tell subjects that this
%  is the middle of the experiment.
%
%  The stimuli for the comparison task must already be in presentation
%  order. They are stored in
%  expParam.session.(sesName).(phaseName).viewStims, btSpeciesStims, and
%  wiSpeciesStims as structs.
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
%  Field 'compStimNum' denotes whether a stimulus is stim1 or stim2.
%  Field 'compPairNum' denotes which two stimuli are paired.
%
% NB:
%  to find the corresponding pair member, search for the same compPairNum
%  and the opposite compStimNum (1 or 2).

% % keys
% cfg.keys.compareKeyNames, encoded as:
% cfg.keys.c01
% cfg.keys.c02
% cfg.keys.c03
% cfg.keys.c04
% cfg.keys.c05

fprintf('Running %s %s (compare) (%d)...\n',sesName,phaseName,phaseCount);

phaseNameForParticipant = 'comparison';

%% set the starting date and time for this phase
thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% main phase progress file

% set up progress file, to resume this phase in case of a crash, etc.
mainPhaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_comp_%d.mat',sesName,phaseName,phaseCount));
if exist(mainPhaseProgressFile,'file')
  load(mainPhaseProgressFile);
else
  phaseComplete = false; %#ok<NASGU>
  save(mainPhaseProgressFile,'thisDate','startTime','phaseComplete');
end

%% start the log file for this phase

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_comp_%d.txt',sesName,phaseName,phaseCount));
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

if phaseCfg.isExp
  stimDir = cfg.files.stimDir;
else
  stimDir = cfg.files.stimDir_prac;
end

% default is to preload the images
if ~isfield(cfg.stim,'preloadImages')
  cfg.stim.preloadImages = false;
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

if ~isfield(cfg.text,'respReminder')
  cfg.text.respReminder = true;
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


if cfg.text.respReminder
  % create a rectangle for placing response reminder using Screen('DrawText')
  Screen('TextSize', w, cfg.text.instructTextSize);
  respReminderRect = Screen('TextBounds', w, cfg.text.respReminderText);
  % center it in the bottom middle of the screen
  respReminderRect = AlignRect(respReminderRect,cfg.screen.wRect,'center','bottom');
  % get the X and Y coordinates
  respReminderRectX = respReminderRect(1);
  respReminderRectY = respReminderRect(2);
  
  %respReminderRectY = cfg.screen.wRect(RectBottom) - (cfg.screen.wRect(RectBottom) * 0.05);
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

%% determine the starting trial, useful for resuming - viewing

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_comp_view_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).viewStims));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
  runView = true;
else
  fprintf('All trials for %s %s (comp) (%d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount);
  % release any remaining textures
  Screen('Close');
  runView = false;
end

if runView
  
  %% preload viewing stimuli for presentation
  
  viewStims = expParam.session.(sesName).(phaseName)(phaseCount).viewStims;
  
  if cfg.stim.preloadImages
    message = sprintf('Preparing part 1 images, please wait...');
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
  vStimTex = nan(1,length(viewStims));
  
  for i = 1:length(viewStims)
    % make sure this stimulus exists
    vStimImgFile = fullfile(stimDir,viewStims(i).familyStr,viewStims(i).fileName);
    if exist(vStimImgFile,'file')
      if cfg.stim.preloadImages
        % load up this stim's texture
        vStimImg = imread(vStimImgFile);
        vStimTex(i) = Screen('MakeTexture',w,vStimImg);
        % TODO: optimized?
        %vStimTex(i) = Screen('MakeTexture',w,vStimImg,[],1);
      elseif ~cfg.stim.preloadImages && i == length(viewStims)
        % still need to load the last image to set the rectangle
        vStimImg = imread(fullfile(stimDir,viewStims(i).familyStr,viewStims(i).fileName));
      end
    else
      error('Study stimulus %s does not exist!',vStimImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(vStimImg,1) * cfg.stim.stimScale;
  stimImgWidth = size(vStimImg,2) * cfg.stim.stimScale;
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
  
  %% show the instructions - view
  
  if ~expParam.photoCellTest
    for i = 1:length(phaseCfg.instruct.compView)
      WaitSecs(1.000);
      et_showTextInstruct(w,cfg,phaseCfg.instruct.compView(i),cfg.keys.instructContKey,...
        cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    end
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
  
  %% questions? only during practice. continues with experimenter's key.
  
  if ~expParam.photoCellTest && ~phaseCfg.isExp && phaseCfg.instruct.questions
    questionsMsg.text = sprintf('If you have any questions about the %s phase (part 1), please ask the experimenter now.\n\nPlease tell the experimenter when you are ready to begin the task.',phaseNameForParticipant);
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
    readyMsg.text = sprintf('Ready to begin%s %s phase (part 1).\nPress "%s" to start.',expStr,phaseNameForParticipant,cfg.keys.instructContKey);
    et_showTextInstruct(w,cfg,readyMsg,cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
  
  %% run the comparison - view task
  
  % start the blink break timer
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
    blinkTimerStart = GetSecs;
  end
  
  for i = trialNum:length(viewStims)
    % do an impedance check after a certain number of blocks or trials
    if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(viewStims) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.comp_view_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_view_isi == 0 && phaseCfg.fixDuringPreStim)
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
      if cfg.stim.secUntilBlinkBreak > 0
        blinkTimerStart = GetSecs;
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
      
      thisGetSecs = KbWait(-1,2);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.comp_view_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_view_isi == 0 && phaseCfg.fixDuringPreStim)
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
      vStimImg = imread(fullfile(stimDir,viewStims(i).familyStr,viewStims(i).fileName));
      vStimTex(i) = Screen('MakeTexture',w,vStimImg);
    end
    
    % resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
    end
    
    fNum = int32(viewStims(i).familyNum);
    specNum = int32(viewStims(i).speciesNum);
    
    % ISI between trials
    if phaseCfg.comp_view_isi > 0
      if phaseCfg.fixDuringISI
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      WaitSecs(phaseCfg.comp_view_isi);
    end
    
    % preStimulus period, with fixation if desired
    if length(phaseCfg.comp_view_preStim) == 1
      if phaseCfg.comp_view_preStim > 0
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
        WaitSecs(phaseCfg.comp_view_preStim);
      end
    elseif length(phaseCfg.comp_view_preStim) == 2
      if ~all(phaseCfg.comp_view_preStim == 0)
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
        WaitSecs(phaseCfg.comp_view_preStim(1) + ((phaseCfg.comp_view_preStim(2) - phaseCfg.comp_view_preStim(1)).*rand(1,1)));
      end
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, vStimTex(i), [], stimImgRect);
    if phaseCfg.fixDuringStim
      % and fixation on top of it
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
    
    % while loop to show stimulus until "duration" seconds elapse.
    while (GetSecs - stimOnset) <= phaseCfg.comp_view_stim
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % Clear screen to background color, with fixation if desired
    if (phaseCfg.comp_view_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_view_isi == 0 && phaseCfg.fixDuringPreStim)
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    
    % Close this stimulus before next trial
    Screen('Close', vStimTex(i));
    
    %% session log file
    
    % Write stimulus presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\n',...
      imgOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_VIEW_STIM',...
      i,...
      viewStims(i).familyStr,...
      viewStims(i).speciesStr,...
      viewStims(i).exemplarName,...
      fNum,...
      specNum);
    
    %% phase log file
    
    % Write stimulus presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\n',...
      imgOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_VIEW_STIM',...
      i,...
      viewStims(i).familyStr,...
      viewStims(i).speciesStr,...
      viewStims(i).exemplarName,...
      fNum,...
      specNum);
    
    %% Write netstation logs
    
    if expParam.useNS
      % Write trial info to et_NetStation
      % mark every event with the following key code/value pairs
      % 'subn', subject number
      % 'sess', session type
      % 'phas', session phase name
      % 'pcou', phase count
      % 'expt', whether this is the experiment (1) or practice (0)
      % 'part', which part of the experiment we're in
      % 'trln', trial number
      % 'stmn', stimulus name (family, species, exemplar)
      % 'famn', family number
      % 'spcn', species number (corresponds to keyboard)
      
      % write out the stimulus name
      stimName = sprintf('%s%s%d',...
        viewStims(i).familyStr,...
        viewStims(i).speciesStr,...
        viewStims(i).exemplarName);
      
      if ~isnan(preStimFixOn)
        % pretrial fixation
        [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp, 'part', 'view', 'trln', int32(i),...
          'stmn', stimName, 'famn', fNum, 'spcn', specNum); %#ok<NASGU,ASGLU>
      end
      
      % img presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', imgOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'part', 'view', 'trln', int32(i),...
        'stmn', stimName, 'famn', fNum, 'spcn', specNum); %#ok<NASGU,ASGLU>
    end % useNS
    
    % mark that we finished this trial
    trialComplete(i) = true;
    % save progress after each trial
    save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
  end
  
  % cleanup
  
  endTime = fix(clock);
  endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6)); %#ok<NASGU>
  % save progress after finishing phase
  phaseComplete = true; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');
end

%% determine the starting trial, useful for resuming - between species

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_comp_bt_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims([expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims.compStimNum] == 2)));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
  runBt = true;
else
  fprintf('All trials for %s %s (comp between) (%d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount);
  % release any remaining textures
  Screen('Close');
  runBt = false;
end

if runBt
  %% preload between stimuli for presentation
  
  btSpeciesStims = expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims;
  
  % get the stimulus 2s
  btStim2 = btSpeciesStims([btSpeciesStims.compStimNum] == 2);
  % initialize for storing stimulus 1s
  btStim1 = struct([]);
  fn = fieldnames(btStim2);
  for i = 1:length(fn)
    btStim1(1).(fn{i}) = [];
  end
  
  btStim1Tex = nan(1,length(btStim2));
  btStim2Tex = nan(1,length(btStim2));
  
  if cfg.stim.preloadImages
    message = sprintf('Preparing part 2 images, please wait...');
    Screen('TextSize', w, cfg.text.basicTextSize);
    % put the "preparing" message on the screen
    DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
  end
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % Update the display to show the message:
  Screen('Flip', w);
  
  for i = 1:length(btStim2)
    % find btStim2's corresponding pair
    btStim1(i) = btSpeciesStims(...
      ([btSpeciesStims.compPairNum] == btStim2(i).compPairNum) &...
      ([btSpeciesStims.compStimNum] ~= btStim2(i).compStimNum));
    
    % make sure btStim2 exists
    btStim2ImgFile = fullfile(stimDir,btStim2(i).familyStr,btStim2(i).fileName);
    if exist(btStim2ImgFile,'file')
      if cfg.stim.preloadImages
        % load up btStim2's texture
        btStim2Img = imread(btStim2ImgFile);
        btStim2Tex(i) = Screen('MakeTexture',w,btStim2Img);
        % TODO: optimized?
        %btStim2Tex(i) = Screen('MakeTexture',w,btStim2Img,[],1);
      end
    else
      error('Study stimulus %s does not exist!',btStim2ImgFile);
    end
    
    % make sure btStim1 exists
    btStim1ImgFile = fullfile(stimDir,btStim1(i).familyStr,btStim1(i).fileName);
    if exist(btStim1ImgFile,'file')
      if cfg.stim.preloadImages
        % load up btStim1's texture
        btStim1Img = imread(btStim1ImgFile);
        btStim1Tex(i) = Screen('MakeTexture',w,btStim1Img);
        % TODO: optimized?
        %btStim1Tex(i) = Screen('MakeTexture',w,btStim1Img,[],1);
      elseif ~cfg.stim.preloadImages && i == length(btStim2)
        % still need to load the last image to set the rectangle
        btStim1Img = imread(fullfile(stimDir,btStim1(i).familyStr,btStim1(i).fileName));
      end
    else
      error('Study stimulus %s does not exist!',btStim1ImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(btStim1Img,1) * cfg.stim.stimScale;
  stimImgWidth = size(btStim1Img,2) * cfg.stim.stimScale;
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect, cfg.screen.wRect);
  % Stimulus rectangles shifted to left and right by 60% of image width
  stim1ImgRect = OffsetRect(stimImgRect,RectWidth(stimImgRect) * 0.6,0);
  stim2ImgRect = OffsetRect(stimImgRect,RectWidth(stimImgRect) * 0.6 * -1,0);
  
  % text location for error (e.g., "too fast") text
  [~,errorTextY] = RectCenter(cfg.screen.wRect);
  errorTextY = errorTextY + (stimImgHeight / 2);
  
  %% show the instructions - between
  
  if ~expParam.photoCellTest
    for i = 1:length(phaseCfg.instruct.compBt)
      WaitSecs(1.000);
      et_showTextInstruct(w,cfg,phaseCfg.instruct.compBt(i),cfg.keys.instructContKey,...
        cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    end
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
  
  %% questions? only during practice. continues with experimenter's key.
  
  if ~expParam.photoCellTest && ~phaseCfg.isExp && phaseCfg.instruct.questions
    questionsMsg.text = sprintf('If you have any questions about the %s phase (part 2), please ask the experimenter now.\n\nPlease tell the experimenter when you are ready to begin the task.',phaseNameForParticipant);
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
    readyMsg.text = sprintf('Ready to begin%s %s phase (part 2).\nPress "%s" to start.',expStr,phaseNameForParticipant,cfg.keys.instructContKey);
    et_showTextInstruct(w,cfg,readyMsg,cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
  
  %% run the comparison - between task
  
  % only check these keys
  RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
  
  % start the blink break timer
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
    blinkTimerStart = GetSecs;
  end
  
  for i = trialNum:length(btStim2)
    % do an impedance check after a certain number of trials
    if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(btStim2) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.comp_bt_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_bt_isi == 0 && phaseCfg.fixDuringPreStim)
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
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
    
    % Do a blink break if specified time has passed
    if ~expParam.photoCellTest && phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(btStim2) - 3)
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      Screen('TextSize', w, cfg.text.basicTextSize);
      if expParam.useNS
        pauseMsg = 'Blink now.\n\n';
      else
        pauseMsg = '';
      end
      pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, length(btStim2));
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
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.comp_bt_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_bt_isi == 0 && phaseCfg.fixDuringPreStim)
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
      WaitSecs(1.0);
      
      % reset the timer
      blinkTimerStart = GetSecs;
    end
    
    % load the stimuli now if we didn't load them earlier
    if ~cfg.stim.preloadImages
      btStim1Img = imread(fullfile(stimDir,btStim1(i).familyStr,btStim1(i).fileName));
      btStim2Img = imread(fullfile(stimDir,btStim2(i).familyStr,btStim2(i).fileName));
      btStim1Tex(i) = Screen('MakeTexture',w,btStim1Img);
      btStim2Tex(i) = Screen('MakeTexture',w,btStim2Img);
    end
    
    % resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
    end
    
    % ISI between trials
    if phaseCfg.comp_bt_isi > 0
      if phaseCfg.fixDuringISI
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
      WaitSecs(phaseCfg.comp_bt_isi);
    end
    
    % preStimulus period, with fixation if desired
    if cfg.text.respReminder
      Screen('TextSize', w, cfg.text.instructTextSize);
      Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
      %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
    end
    if length(phaseCfg.comp_bt_preStim) == 1
      if phaseCfg.comp_bt_preStim > 0
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
        WaitSecs(phaseCfg.comp_bt_preStim);
      end
    elseif length(phaseCfg.comp_bt_preStim) == 2
      if ~all(phaseCfg.comp_bt_preStim == 0)
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
        WaitSecs(phaseCfg.comp_bt_preStim(1) + ((phaseCfg.comp_bt_preStim(2) - phaseCfg.comp_bt_preStim(1)).*rand(1,1)));
      end
    end
    
    % draw the stimuli
    Screen('DrawTexture', w, btStim1Tex(i), [], stim1ImgRect);
    Screen('DrawTexture', w, btStim2Tex(i), [], stim2ImgRect);
    if phaseCfg.fixDuringStim
      % and fixation
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    if cfg.text.respReminder
      Screen('TextSize', w, cfg.text.instructTextSize);
      Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
      %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
    end
    
    % photocell rect with stim
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
    end
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'stimOnset':
    [imgOn, stimOnset] = Screen('Flip', w);
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: stim1 (%s): family %d (%s), species %d (%s), exemplar %d (%d).\n',i,length(btStim2),btStim1(i).fileName,btStim1(i).familyNum,btStim1(i).familyStr,btStim1(i).speciesNum,btStim1(i).speciesStr,btStim1(i).exemplarNum,btStim1(i).exemplarName);
      fprintf('Trial %d of %d: stim2 (%s): family %d (%s), species %d (%s), exemplar %d (%d).\n',i,length(btStim2),btStim2(i).fileName,btStim2(i).familyNum,btStim2(i).familyStr,btStim2(i).speciesNum,btStim2(i).speciesStr,btStim2(i).exemplarNum,btStim2(i).exemplarName);
    end
    
    % while loop to show stimulus until subject response or until
    % "comp_bt_stim" seconds elapse.
    while (GetSecs - stimOnset) <= phaseCfg.comp_bt_stim
      % check for too-fast response
      if ~phaseCfg.respDuringStim
        [keyIsDown] = KbCheck;
        % if they press a key too early, tell them they responded too fast
        if keyIsDown
          % draw the stimuli
          Screen('DrawTexture', w, btStim1Tex(i), [], stim1ImgRect);
          Screen('DrawTexture', w, btStim2Tex(i), [], stim2ImgRect);
          if phaseCfg.fixDuringStim
            % and fixation
            Screen('TextSize', w, cfg.text.fixSize);
            Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
            %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % and the "too fast" text
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          if cfg.text.respReminder
            Screen('TextSize', w, cfg.text.instructTextSize);
            Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
            %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
          end
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
            % if (GetSecs - startRT) > phaseCfg.comp_bt_response
            %   break
            % end
          end
          % if cfg.text.printTrialInfo
          %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
          % end
          if (keyCode(cfg.keys.c01) == 1 && all(keyCode(~cfg.keys.c01) == 0)) ||...
              (keyCode(cfg.keys.c02) == 1 && all(keyCode(~cfg.keys.c02) == 0)) ||...
              (keyCode(cfg.keys.c03) == 1 && all(keyCode(~cfg.keys.c03) == 0)) ||...
              (keyCode(cfg.keys.c04) == 1 && all(keyCode(~cfg.keys.c04) == 0)) ||...
              (keyCode(cfg.keys.c05) == 1 && all(keyCode(~cfg.keys.c05) == 0))
            break
          end
        elseif keyIsDown && sum(keyCode) > 1
          % draw the stimuli
          Screen('DrawTexture', w, btStim1Tex(i), [], stim1ImgRect);
          Screen('DrawTexture', w, btStim2Tex(i), [], stim2ImgRect);
          if phaseCfg.fixDuringStim
            % and fixation
            Screen('TextSize', w, cfg.text.fixSize);
            Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
            %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % don't push multiple keys
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          if cfg.text.respReminder
            Screen('TextSize', w, cfg.text.instructTextSize);
            Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
            %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
          end
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
    while (GetSecs - stimOnset) <= phaseCfg.comp_bt_stim
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
      % draw response prompt
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      [respPromptOn, startRT] = Screen('Flip',w);
      
      % poll for a resp
      while (GetSecs - startRT) <= phaseCfg.comp_bt_response
        
        [keyIsDown, endRT, keyCode] = KbCheck;
        % if they push more than one key, don't accept it
        if keyIsDown && sum(keyCode) == 1
          % wait for key to be released
          while KbCheck(-1)
            WaitSecs(0.0001);
            
            % % proceed if time is up, regardless of whether key is held
            % if (GetSecs - startRT) > phaseCfg.comp_bt_response
            %   break
            % end
          end
          % if cfg.text.printTrialInfo
          %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
          % end
          if (keyCode(cfg.keys.c01) == 1 && all(keyCode(~cfg.keys.c01) == 0)) ||...
              (keyCode(cfg.keys.c02) == 1 && all(keyCode(~cfg.keys.c02) == 0)) ||...
              (keyCode(cfg.keys.c03) == 1 && all(keyCode(~cfg.keys.c03) == 0)) ||...
              (keyCode(cfg.keys.c04) == 1 && all(keyCode(~cfg.keys.c04) == 0)) ||...
              (keyCode(cfg.keys.c05) == 1 && all(keyCode(~cfg.keys.c05) == 0))
            break
          end
        elseif keyIsDown && sum(keyCode) > 1
          % draw response prompt
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          % don't push multiple keys
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          if cfg.text.respReminder
            Screen('TextSize', w, cfg.text.instructTextSize);
            Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
            %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
          end
          if cfg.stim.photoCell
            Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
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
      if (keyCode(cfg.keys.c01) == 1 && all(keyCode(~cfg.keys.c01) == 0))
        resp = '1';
      elseif (keyCode(cfg.keys.c02) == 1 && all(keyCode(~cfg.keys.c02) == 0))
        resp = '2';
      elseif (keyCode(cfg.keys.c03) == 1 && all(keyCode(~cfg.keys.c03) == 0))
        resp = '3';
      elseif (keyCode(cfg.keys.c04) == 1 && all(keyCode(~cfg.keys.c04) == 0))
        resp = '4';
      elseif (keyCode(cfg.keys.c05) == 1 && all(keyCode(~cfg.keys.c05) == 0))
        resp = '5';
      end
      message = '';
    else
      % did not push a key
      resp = 'none';
      
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
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
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
        respKey = respKey(1);
      elseif sum(keyCode) > 1
        thisResp = KbName(keyCode);
        respKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisResp)),thisResp{:}));
      end
    else
      respKey = 'none';
    end
    
    if (phaseCfg.comp_bt_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_bt_isi == 0 && phaseCfg.fixDuringPreStim)
      % draw fixation after response
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    
    if cfg.text.respReminder
      Screen('TextSize', w, cfg.text.instructTextSize);
      Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
      %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
    end
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    % clear the screen
    Screen('Flip', w);
    
    % Close this stimulus before next trial
    Screen('Close', btStim1Tex(i));
    Screen('Close', btStim2Tex(i));
    
    % compute response time
    if phaseCfg.respDuringStim
      measureRTfromHere = stimOnset;
    else
      measureRTfromHere = startRT;
    end
    rt = int32(round(1000 * (endRT - measureRTfromHere)));
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: response: %s (key: %s; rt = %d)\n',i,length(btStim2),resp,respKey,rt);
    end
    
    fNum1 = int32(btStim1(i).familyNum);
    fNum2 = int32(btStim2(i).familyNum);
    specNum1 = int32(btStim1(i).speciesNum);
    specNum2 = int32(btStim2(i).speciesNum);
    
    %% session log file
    
    % Write stim presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
      imgOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_BT_STIM',...
      i,...
      btStim1(i).familyStr,...
      btStim1(i).speciesStr,...
      btStim1(i).exemplarName,...
      fNum1,...
      specNum1,...
      btStim1(i).trained,...
      btStim2(i).familyStr,...
      btStim2(i).speciesStr,...
      btStim2(i).exemplarName,...
      fNum2,...
      specNum2,...
      btStim2(i).trained);
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_BT_RESP',...
      i,...
      resp,...
      respKey,...
      rt);
    
    %% phase log file
    
    % Write stim presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
      imgOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_BT_STIM',...
      i,...
      btStim1(i).familyStr,...
      btStim1(i).speciesStr,...
      btStim1(i).exemplarName,...
      fNum1,...
      specNum1,...
      btStim1(i).trained,...
      btStim2(i).familyStr,...
      btStim2(i).speciesStr,...
      btStim2(i).exemplarName,...
      fNum2,...
      specNum2,...
      btStim2(i).trained);
    
    % Write trial result to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_BT_RESP',...
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
      % 'part', which part of the experiment we're in
      % 'trln', trial number
      % 'stm1', stimulus 1 name (family, species, exemplar)
      % 'stm2', stimulus 2 name (family, species, exemplar)
      % 'fam1', family 1 number
      % 'fam2', family 2 number
      % 'spc1', species 1 number (corresponds to keyboard)
      % 'spc2', species 2 number (corresponds to keyboard)
      % 'rsps', response string
      % 'rspk', the name of the key pressed
      % 'rspt', the response time
      % 'keyp', key pressed?(1=yes, 0=no)
      
      % write out the stimulus name
      stim1Name = sprintf('%s%s%d',...
        btStim1(i).familyStr,...
        btStim1(i).speciesStr,...
        btStim1(i).exemplarName);
      stim2Name = sprintf('%s%s%d',...
        btStim2(i).familyStr,...
        btStim2(i).speciesStr,...
        btStim2(i).exemplarName);
      
      if ~isnan(preStimFixOn)
        % pre-stim fixation
        [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp, 'part', 'between', 'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % stim presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', imgOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'part', 'between', 'trln', int32(i),...
        'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(respPromptOn)
        % response prompt
        [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp, 'part', 'between', 'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp, 'part', 'between', 'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
    end % useNS
    
    % mark that we finished this trial
    trialComplete(i) = true;
    % save progress after each trial
    save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
  end
  
  % cleanup
  
  endTime = fix(clock);
  endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6)); %#ok<NASGU>
  % save progress after finishing phase
  phaseComplete = true; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');
end

%% determine the starting trial, useful for resuming - within species

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_comp_wi_%d.mat',sesName,phaseName,phaseCount));
if exist(phaseProgressFile,'file')
  load(phaseProgressFile);
else
  trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims([expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims.compStimNum] == 2)));
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
end

% find the starting trial
incompleteTrials = find(~trialComplete);
if ~isempty(incompleteTrials)
  trialNum = incompleteTrials(1);
  runWi = true;
else
  fprintf('All trials for %s %s (comp within) (%d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount);
  % release any remaining textures
  Screen('Close');
  runWi = false;
end

if runWi
  %% preload within stimuli for presentation
  
  wiSpeciesStims = expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims;
  
  % get the stimulus 2s
  wiStim2 = wiSpeciesStims([wiSpeciesStims.compStimNum] == 2);
  % initialize for storing stimulus 1s
  wiStim1 = struct([]);
  fn = fieldnames(wiStim2);
  for i = 1:length(fn)
    wiStim1(1).(fn{i}) = [];
  end
  
  wiStim1Tex = nan(1,length(wiStim2));
  wiStim2Tex = nan(1,length(wiStim2));
  
  if cfg.stim.preloadImages
    message = sprintf('Preparing part 3 images, please wait...');
    Screen('TextSize', w, cfg.text.basicTextSize);
    % put the "preparing" message on the screen
    DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
  end
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % Update the display to show the message:
  Screen('Flip', w);
  
  for i = 1:length(wiStim2)
    % find wiStim2's corresponding pair
    wiStim1(i) = wiSpeciesStims(...
      ([wiSpeciesStims.compPairNum] == wiStim2(i).compPairNum) &...
      ([wiSpeciesStims.compStimNum] ~= wiStim2(i).compStimNum));
    
    % make sure wiStim2 exists
    wiStim2ImgFile = fullfile(stimDir,wiStim2(i).familyStr,wiStim2(i).fileName);
    if exist(wiStim2ImgFile,'file')
      if cfg.stim.preloadImages
        % load up wiStim2's texture
        wiStim2Img = imread(wiStim2ImgFile);
        wiStim2Tex(i) = Screen('MakeTexture',w,wiStim2Img);
        % TODO: optimized?
        %wiStim2Tex(i) = Screen('MakeTexture',w,wiStim2Img,[],1);
      end
    else
      error('Study stimulus %s does not exist!',wiStim2ImgFile);
    end
    
    % make sure wiStim1 exists
    wiStim1ImgFile = fullfile(stimDir,wiStim1(i).familyStr,wiStim1(i).fileName);
    if exist(wiStim1ImgFile,'file')
      if cfg.stim.preloadImages
        % load up wiStim1's texture
        wiStim1Img = imread(wiStim1ImgFile);
        wiStim1Tex(i) = Screen('MakeTexture',w,wiStim1Img);
        % TODO: optimized?
        %wiStim1Tex(i) = Screen('MakeTexture',w,wiStim1Img,[],1);
      elseif ~cfg.stim.preloadImages && i == length(wiStim2)
        % still need to load the last image to set the rectangle
        wiStim1Img = imread(fullfile(stimDir,wiStim1(i).familyStr,wiStim1(i).fileName));
      end
    else
      error('Study stimulus %s does not exist!',wiStim1ImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(wiStim1Img,1) * cfg.stim.stimScale;
  stimImgWidth = size(wiStim1Img,2) * cfg.stim.stimScale;
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect, cfg.screen.wRect);
  % Stimulus rectangles shifted to left and right by 60% of image width
  stim1ImgRect = OffsetRect(stimImgRect,RectWidth(stimImgRect) * 0.6,0);
  stim2ImgRect = OffsetRect(stimImgRect,RectWidth(stimImgRect) * 0.6 * -1,0);
  
  % text location for error (e.g., "too fast") text
  [~,errorTextY] = RectCenter(cfg.screen.wRect);
  errorTextY = errorTextY + (stimImgHeight / 2);
  
  %% show the instructions - within
  
  if ~expParam.photoCellTest
    for i = 1:length(phaseCfg.instruct.compWi)
      WaitSecs(1.000);
      et_showTextInstruct(w,cfg,phaseCfg.instruct.compWi(i),cfg.keys.instructContKey,...
        cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    end
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
  
  %% questions? only during practice. continues with experimenter's key.
  
  if ~expParam.photoCellTest && ~phaseCfg.isExp && phaseCfg.instruct.questions
    questionsMsg.text = sprintf('If you have any questions about the %s phase (part 3), please ask the experimenter now.\n\nPlease tell the experimenter when you are ready to begin the task.',phaseNameForParticipant);
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
    readyMsg.text = sprintf('Ready to begin%s %s phase (part 3).\nPress "%s" to start.',expStr,phaseNameForParticipant,cfg.keys.instructContKey);
    et_showTextInstruct(w,cfg,readyMsg,cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
    % Wait a second before starting trial
    WaitSecs(1.000);
  end
  
  %% run the comparison - within task
  
  % only check these keys
  RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
  
  % start the blink break timer
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
    blinkTimerStart = GetSecs;
  end
  
  for i = trialNum:length(wiStim2)
    % do an impedance check after a certain number of trials
    if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(wiStim2) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.comp_wi_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_wi_isi == 0 && phaseCfg.fixDuringPreStim)
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
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
    
    % Do a blink break if specified time has passed
    if ~expParam.photoCellTest && phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(wiStim2) - 3)
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      Screen('TextSize', w, cfg.text.basicTextSize);
      if expParam.useNS
        pauseMsg = 'Blink now.\n\n';
      else
        pauseMsg = '';
      end
      pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, length(wiStim2));
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
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
      
      % show preparation text
      DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip', w);
      WaitSecs(2.0);
      
      if (phaseCfg.comp_wi_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_wi_isi == 0 && phaseCfg.fixDuringPreStim)
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
      WaitSecs(1.0);
      
      % reset the timer
      blinkTimerStart = GetSecs;
    end
    
    % load the stimuli now if we didn't load them earlier
    if ~cfg.stim.preloadImages
      wiStim1Img = imread(fullfile(stimDir,wiStim1(i).familyStr,wiStim1(i).fileName));
      wiStim2Img = imread(fullfile(stimDir,wiStim2(i).familyStr,wiStim2(i).fileName));
      wiStim1Tex(i) = Screen('MakeTexture',w,wiStim1Img);
      wiStim2Tex(i) = Screen('MakeTexture',w,wiStim2Img);
    end
    
    % resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
    end
    
    % ISI between trials
    if phaseCfg.comp_wi_isi > 0
      if phaseCfg.fixDuringISI
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
      WaitSecs(phaseCfg.comp_wi_isi);
    end
    
    % preStimulus period, with fixation if desired
    if cfg.text.respReminder
      Screen('TextSize', w, cfg.text.instructTextSize);
      Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
      %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
    end
    if length(phaseCfg.comp_wi_preStim) == 1
      if phaseCfg.comp_wi_preStim > 0
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
        WaitSecs(phaseCfg.comp_wi_preStim);
      end
    elseif length(phaseCfg.comp_wi_preStim) == 2
      if ~all(phaseCfg.comp_wi_preStim == 0)
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
        WaitSecs(phaseCfg.comp_wi_preStim(1) + ((phaseCfg.comp_wi_preStim(2) - phaseCfg.comp_wi_preStim(1)).*rand(1,1)));
      end
    end
    
    % draw the stimuli
    Screen('DrawTexture', w, wiStim1Tex(i), [], stim1ImgRect);
    Screen('DrawTexture', w, wiStim2Tex(i), [], stim2ImgRect);
    if phaseCfg.fixDuringStim
      % and fixation
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    if cfg.text.respReminder
      Screen('TextSize', w, cfg.text.instructTextSize);
      Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
      %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
    end
    
    % photocell rect with stim
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
    end
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'stimOnset':
    [imgOn, stimOnset] = Screen('Flip', w);
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: stim1 (%s): family %d (%s), species %d (%s), exemplar %d (%d).\n',i,length(wiStim2),wiStim1(i).fileName,wiStim1(i).familyNum,wiStim1(i).familyStr,wiStim1(i).speciesNum,wiStim1(i).speciesStr,wiStim1(i).exemplarNum,wiStim1(i).exemplarName);
      fprintf('Trial %d of %d: stim2 (%s): family %d (%s), species %d (%s), exemplar %d (%d).\n',i,length(wiStim2),wiStim2(i).fileName,wiStim2(i).familyNum,wiStim2(i).familyStr,wiStim2(i).speciesNum,wiStim2(i).speciesStr,wiStim2(i).exemplarNum,wiStim2(i).exemplarName);
    end
    
    % while loop to show stimulus until subject response or until
    % "comp_wi_stim" seconds elapse.
    while (GetSecs - stimOnset) <= phaseCfg.comp_wi_stim
      % check for too-fast response
      if ~phaseCfg.respDuringStim
        [keyIsDown] = KbCheck;
        % if they press a key too early, tell them they responded too fast
        if keyIsDown
          % draw the stimuli
          Screen('DrawTexture', w, wiStim1Tex(i), [], stim1ImgRect);
          Screen('DrawTexture', w, wiStim2Tex(i), [], stim2ImgRect);
          if phaseCfg.fixDuringStim
            % and fixation
            Screen('TextSize', w, cfg.text.fixSize);
            Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
            %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % and the "too fast" text
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          if cfg.text.respReminder
            Screen('TextSize', w, cfg.text.instructTextSize);
            Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
            %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
          end
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
            % if (GetSecs - startRT) > phaseCfg.comp_wi_response
            %   break
            % end
          end
          % if cfg.text.printTrialInfo
          %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
          % end
          if (keyCode(cfg.keys.c01) == 1 && all(keyCode(~cfg.keys.c01) == 0)) ||...
              (keyCode(cfg.keys.c02) == 1 && all(keyCode(~cfg.keys.c02) == 0)) ||...
              (keyCode(cfg.keys.c03) == 1 && all(keyCode(~cfg.keys.c03) == 0)) ||...
              (keyCode(cfg.keys.c04) == 1 && all(keyCode(~cfg.keys.c04) == 0)) ||...
              (keyCode(cfg.keys.c05) == 1 && all(keyCode(~cfg.keys.c05) == 0))
            break
          end
        elseif keyIsDown && sum(keyCode) > 1
          % draw the stimuli
          Screen('DrawTexture', w, wiStim1Tex(i), [], stim1ImgRect);
          Screen('DrawTexture', w, wiStim2Tex(i), [], stim2ImgRect);
          if phaseCfg.fixDuringStim
            % and fixation
            Screen('TextSize', w, cfg.text.fixSize);
            Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
            %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % don't push multiple keys
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          if cfg.text.respReminder
            Screen('TextSize', w, cfg.text.instructTextSize);
            Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
            %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
          end
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
    while (GetSecs - stimOnset) <= phaseCfg.comp_wi_stim
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
      % draw response prompt
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      [respPromptOn, startRT] = Screen('Flip',w);
      
      % poll for a resp
      while (GetSecs - startRT) <= phaseCfg.comp_wi_response
        
        [keyIsDown, endRT, keyCode] = KbCheck;
        % if they push more than one key, don't accept it
        if keyIsDown && sum(keyCode) == 1
          % wait for key to be released
          while KbCheck(-1)
            WaitSecs(0.0001);
            
            % % proceed if time is up, regardless of whether key is held
            % if (GetSecs - startRT) > phaseCfg.comp_wi_response
            %   break
            % end
          end
          % if cfg.text.printTrialInfo
          %   fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
          % end
          if (keyCode(cfg.keys.c01) == 1 && all(keyCode(~cfg.keys.c01) == 0)) ||...
              (keyCode(cfg.keys.c02) == 1 && all(keyCode(~cfg.keys.c02) == 0)) ||...
              (keyCode(cfg.keys.c03) == 1 && all(keyCode(~cfg.keys.c03) == 0)) ||...
              (keyCode(cfg.keys.c04) == 1 && all(keyCode(~cfg.keys.c04) == 0)) ||...
              (keyCode(cfg.keys.c05) == 1 && all(keyCode(~cfg.keys.c05) == 0))
            break
          end
        elseif keyIsDown && sum(keyCode) > 1
          % draw response prompt
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.respSymbol, respRectX, respRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          % don't push multiple keys
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          if cfg.text.respReminder
            Screen('TextSize', w, cfg.text.instructTextSize);
            Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
            %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
          end
          if cfg.stim.photoCell
            Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
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
      if (keyCode(cfg.keys.c01) == 1 && all(keyCode(~cfg.keys.c01) == 0))
        resp = '1';
      elseif (keyCode(cfg.keys.c02) == 1 && all(keyCode(~cfg.keys.c02) == 0))
        resp = '2';
      elseif (keyCode(cfg.keys.c03) == 1 && all(keyCode(~cfg.keys.c03) == 0))
        resp = '3';
      elseif (keyCode(cfg.keys.c04) == 1 && all(keyCode(~cfg.keys.c04) == 0))
        resp = '4';
      elseif (keyCode(cfg.keys.c05) == 1 && all(keyCode(~cfg.keys.c05) == 0))
        resp = '5';
      end
      message = '';
    else
      % did not push a key
      resp = 'none';
      
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
      if cfg.text.respReminder
        Screen('TextSize', w, cfg.text.instructTextSize);
        Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
        %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
      end
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
        respKey = respKey(1);
      elseif sum(keyCode) > 1
        thisResp = KbName(keyCode);
        respKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisResp)),thisResp{:}));
      end
    else
      respKey = 'none';
    end
    
    if (phaseCfg.comp_wi_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.comp_wi_isi == 0 && phaseCfg.fixDuringPreStim)
      % draw fixation after response
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    
    if cfg.text.respReminder
      Screen('TextSize', w, cfg.text.instructTextSize);
      Screen('DrawText', w, cfg.text.respReminderText, respReminderRectX, respReminderRectY, cfg.text.instructColor);
      %DrawFormattedText(w, cfg.text.respReminderText, 'center', respReminderRectY, cfg.text.instructColor, cfg.text.instructCharWidth);
    end
    
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    % clear the screen
    Screen('Flip', w);
    
    % Close this stimulus before next trial
    Screen('Close', wiStim1Tex(i));
    Screen('Close', wiStim2Tex(i));
    
    % compute response time
    if phaseCfg.respDuringStim
      measureRTfromHere = stimOnset;
    else
      measureRTfromHere = startRT;
    end
    rt = int32(round(1000 * (endRT - measureRTfromHere)));
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: response: %s (key: %s; rt = %d)\n',i,length(wiStim2),resp,respKey,rt);
    end
    
    fNum1 = int32(wiStim1(i).familyNum);
    fNum2 = int32(wiStim2(i).familyNum);
    specNum1 = int32(wiStim1(i).speciesNum);
    specNum2 = int32(wiStim2(i).speciesNum);
    
    %% session log file
    
    % Write stim presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
      imgOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_WI_STIM',...
      i,...
      wiStim1(i).familyStr,...
      wiStim1(i).speciesStr,...
      wiStim1(i).exemplarName,...
      fNum1,...
      specNum1,...
      wiStim1(i).trained,...
      wiStim2(i).familyStr,...
      wiStim2(i).speciesStr,...
      wiStim2(i).exemplarName,...
      fNum2,...
      specNum2,...
      wiStim2(i).trained);
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_WI_RESP',...
      i,...
      resp,...
      respKey,...
      rt);
    
    %% phase log file
    
    % Write stim presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
      imgOn,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_WI_STIM',...
      i,...
      wiStim1(i).familyStr,...
      wiStim1(i).speciesStr,...
      wiStim1(i).exemplarName,...
      fNum1,...
      specNum1,...
      wiStim1(i).trained,...
      wiStim2(i).familyStr,...
      wiStim2(i).speciesStr,...
      wiStim2(i).exemplarName,...
      fNum2,...
      specNum2,...
      wiStim2(i).trained);
    
    % Write trial result to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_WI_RESP',...
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
      % 'part', which part of the experiment we're in
      % 'trln', trial number
      % 'stm1', stimulus 1 name (family, species, exemplar)
      % 'stm2', stimulus 2 name (family, species, exemplar)
      % 'fam1', family 1 number
      % 'fam2', family 2 number
      % 'spc1', species 1 number (corresponds to keyboard)
      % 'spc2', species 2 number (corresponds to keyboard)
      % 'rsps', response string
      % 'rspk', the name of the key pressed
      % 'rspt', the response time
      % 'keyp', key pressed?(1=yes, 0=no)
      
      % write out the stimulus name
      stim1Name = sprintf('%s%s%d',...
        wiStim1(i).familyStr,...
        wiStim1(i).speciesStr,...
        wiStim1(i).exemplarName);
      stim2Name = sprintf('%s%s%d',...
        wiStim2(i).familyStr,...
        wiStim2(i).speciesStr,...
        wiStim2(i).exemplarName);
      
      if ~isnan(preStimFixOn)
        % pre-stim fixation
        [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStimFixOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp, 'part', 'within', 'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % stim presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', imgOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp, 'part', 'within', 'trln', int32(i),...
        'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(respPromptOn)
        % response prompt
        [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp, 'part', 'within', 'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp, 'part', 'within', 'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
    end % useNS
    
    % mark that we finished this trial
    trialComplete(i) = true;
    % save progress after each trial
    save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
  end
  
  % cleanup
  
  endTime = fix(clock);
  endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6)); %#ok<NASGU>
  % save progress after finishing phase
  phaseComplete = true; %#ok<NASGU>
  save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');
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
save(mainPhaseProgressFile,'thisDate','startTime','phaseComplete','endTime');

end % function

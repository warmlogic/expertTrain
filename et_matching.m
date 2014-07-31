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

phaseNameForParticipant = 'matching';

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
allStims = expParam.session.(sesName).(phaseName)(phaseCount).allStims;

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
if phaseCfg.matchTextPrompt
  responsePromptText = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
else
  responsePromptText = cfg.text.respSymbol;
end
Screen('TextSize', w, cfg.text.fixSize);
respRect = Screen('TextBounds', w, responsePromptText);
% center it in the middle of the screen
respRect = CenterRect(respRect, cfg.screen.wRect);
% % get the X and Y coordinates
respRectX = respRect(1);
respRectY = respRect(2);

%% preload all stimuli for presentation

% get the stimulus 2s
stim2 = allStims([allStims.matchStimNum] == 2);
% initialize for storing stimulus 1s
stim1 = struct([]);
fn = fieldnames(stim2);
for i = 1:length(fn)
  stim1(1).(fn{i}) = [];
end

matchStim1Tex = nan(1,length(stim2));
matchStim2Tex = nan(1,length(stim2));

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

for i = 1:length(stim2)
  % find stim2's corresponding pair, contingent upon whether this is a same
  % or diff stimulus
  if isfield(stim2(i),'new')
    if stim2(i).same
      % same (same species)
      stim1(i) = allStims(...
        ([allStims.familyNum] == stim2(i).familyNum) &...
        ([allStims.speciesNum] == stim2(i).speciesNum) &...
        ([allStims.trained] == stim2(i).trained) &...
        ([allStims.new] == stim2(i).new) &...
        ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
        ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
      
    else
      % diff (different species)
      stim1(i) = allStims(...
        ([allStims.familyNum] == stim2(i).familyNum) &...
        ([allStims.speciesNum] ~= stim2(i).speciesNum) &...
        ([allStims.trained] == stim2(i).trained) &...
        ([allStims.new] == stim2(i).new) &...
        ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
        ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
    end
  else
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
  end
  
  % make sure stim2 exists
  stim2ImgFile = fullfile(stimDir,stim2(i).familyStr,stim2(i).fileName);
  if exist(stim2ImgFile,'file')
    if cfg.stim.preloadImages
      % load up stim2's texture
      stim2Img = imread(stim2ImgFile);
      matchStim2Tex(i) = Screen('MakeTexture',w,stim2Img);
      % TODO: optimized?
      %matchStim2Tex(i) = Screen('MakeTexture',w,stim2Img,[],1);
    end
  else
    error('Study stimulus %s does not exist!',stim2ImgFile);
  end
  
  % make sure stim1 exists
  stim1ImgFile = fullfile(stimDir,stim1(i).familyStr,stim1(i).fileName);
  if exist(stim1ImgFile,'file')
    if cfg.stim.preloadImages
      % load up stim1's texture
      stim1Img = imread(stim1ImgFile);
      matchStim1Tex(i) = Screen('MakeTexture',w,stim1Img);
      % TODO: optimized?
      %matchStim1Tex(i) = Screen('MakeTexture',w,stim1Img,[],1);
    elseif ~cfg.stim.preloadImages && i == length(stim2)
      % still need to load the last image to set the rectangle
      stim1Img = imread(fullfile(stimDir,stim1(i).familyStr,stim1(i).fileName));
    end
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

if ~expParam.photoCellTest
  for i = 1:length(phaseCfg.instruct.match)
    WaitSecs(1.000);
    et_showTextInstruct(w,cfg,phaseCfg.instruct.match(i),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
  end
  % Wait a second before continuing
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

%% run the matching task

% only check these keys
RestrictKeysForKbCheck([cfg.keys.matchSame, cfg.keys.matchDiff]);

% start the blink break timer
if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
  blinkTimerStart = GetSecs;
end

for i = trialNum:length(stim2)
  % do an impedance check after a certain number of trials
  if ~expParam.photoCellTest && expParam.useNS && phaseCfg.isExp && i > 1 && i < length(stim2) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
    % run the impedance break
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
    thisGetSecs = et_impedanceCheck(w, cfg, true, phaseName);
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
    
    % only check these keys
    RestrictKeysForKbCheck([cfg.keys.matchSame, cfg.keys.matchDiff]);
    
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if (phaseCfg.match_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.match_isi == 0 && phaseCfg.fixDuringPreStim)
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
  if ~expParam.photoCellTest && phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(stim2) - 3)
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
    Screen('TextSize', w, cfg.text.basicTextSize);
    if expParam.useNS
      pauseMsg = 'Blink now.\n\n';
    else
      pauseMsg = '';
    end
    pauseMsg = sprintf('%sReady for trial %d of %d.\nPress any key to continue.', pauseMsg, i, length(stim2));
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
    RestrictKeysForKbCheck([cfg.keys.matchSame, cfg.keys.matchDiff]);
    
    % show preparation text
    DrawFormattedText(w, 'Get ready...', 'center', 'center', cfg.text.fixationColor, cfg.text.instructCharWidth);
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    Screen('Flip', w);
    WaitSecs(2.0);
    
    if (phaseCfg.match_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.match_isi == 0 && phaseCfg.fixDuringPreStim)
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
  
  % load the stimuli now if we didn't load them earlier
  if ~cfg.stim.preloadImages
    stim1Img = imread(fullfile(stimDir,stim1(i).familyStr,stim1(i).fileName));
    stim2Img = imread(fullfile(stimDir,stim2(i).familyStr,stim2(i).fileName));
    matchStim1Tex(i) = Screen('MakeTexture',w,stim1Img);
    matchStim2Tex(i) = Screen('MakeTexture',w,stim2Img);
  end
  
  % Is this a subordinate (1) or basic (0) family/species? If subordinate,
  % get the species number.
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
    [NSSyncStatus, NSSyncError] = NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  end
  
  % ISI between trials
  if phaseCfg.match_isi > 0
    if phaseCfg.fixDuringISI
      Screen('TextSize', w, cfg.text.fixSize);
      Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
      %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      if cfg.stim.photoCell
        Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
      end
      Screen('Flip',w);
    end
    WaitSecs(phaseCfg.match_isi);
  end
  
  % preStimulus period, with fixation if desired
  if length(phaseCfg.match_preStim1) == 1
    if phaseCfg.match_preStim1 > 0
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [preStim1FixOn] = Screen('Flip',w);
      else
        preStim1FixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      WaitSecs(phaseCfg.match_preStim1);
    end
  elseif length(phaseCfg.match_preStim1) == 2
    if ~all(phaseCfg.match_preStim1 == 0)
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [preStim1FixOn] = Screen('Flip',w);
      else
        preStim1FixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      % fixation on screen before stim for a random amount of time
      WaitSecs(phaseCfg.match_preStim1(1) + ((phaseCfg.match_preStim1(2) - phaseCfg.match_preStim1(1)).*rand(1,1)));
    end
  end
  
  % draw the stimulus
  Screen('DrawTexture', w, matchStim1Tex(i), [], stimImgRect);
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
  [img1On, stim1Onset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: stim1 (%s): family %d (%s), species %d (%s), exemplar %d (%d). Same (1) or diff (0): %d.\n',i,length(stim2),stim1(i).fileName,stim1(i).familyNum,stim1(i).familyStr,stim1(i).speciesNum,stim1(i).speciesStr,stim1(i).exemplarNum,stim1(i).exemplarName,stim1(i).same);
  end
  
  % while loop to show stimulus until "duration" seconds elapsed.
  while (GetSecs - stim1Onset) <= phaseCfg.match_stim1
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % preStimulus period, with fixation if desired
  if length(phaseCfg.match_preStim2) == 1
    if phaseCfg.match_preStim2 > 0
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [preStim2FixOn] = Screen('Flip',w);
      else
        preStim2FixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      WaitSecs(phaseCfg.match_preStim2);
    end
  elseif length(phaseCfg.match_preStim2) == 2
    if ~all(phaseCfg.match_preStim2 == 0)
      if phaseCfg.fixDuringPreStim
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
        %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        [preStim2FixOn] = Screen('Flip',w);
      else
        preStim2FixOn = NaN;
        if cfg.stim.photoCell
          Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
        end
        Screen('Flip',w);
      end
      % fixation on screen before stim for a random amount of time
      WaitSecs(phaseCfg.match_preStim2(1) + ((phaseCfg.match_preStim2(2) - phaseCfg.match_preStim2(1)).*rand(1,1)));
    end
  end
  
  % draw the stimulus
  Screen('DrawTexture', w, matchStim2Tex(i), [], stimImgRect);
  if phaseCfg.fixDuringStim
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  end
  
  % photocell rect with stimulus
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellRectColor, cfg.stim.photoCellRect);
  end
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [img2On, stim2Onset] = Screen('Flip', w);
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: stim2 (%s): family %d (%s), species %d (%s), exemplar %d (%d). Same (1) or diff (0): %d.\n',i,length(stim2),stim2(i).fileName,stim2(i).familyNum,stim2(i).familyStr,stim2(i).speciesNum,stim2(i).speciesStr,stim2(i).exemplarNum,stim2(i).exemplarName,stim2(i).same);
  end
  
  % while loop to show stimulus until subject response or until
  % "match_stim2" seconds elapse.
  while (GetSecs - stim2Onset) <= phaseCfg.match_stim2
    % check for too-fast response
    if ~phaseCfg.respDuringStim
      [keyIsDown] = KbCheck;
      % if they press a key too early, tell them they responded too fast
      if keyIsDown
        % draw the stimulus
        Screen('DrawTexture', w, matchStim2Tex(i), [], stimImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        end
        % and the "too fast" text
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        % photocell rect with stimulus
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
        % draw the stimulus
        Screen('DrawTexture', w, matchStim2Tex(i), [], stimImgRect);
        if phaseCfg.fixDuringStim
          % and fixation on top of it
          Screen('TextSize', w, cfg.text.fixSize);
          Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
          %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        end
        % don't push multiple keys
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
        % photocell rect with stimulus
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
  while (GetSecs - stim2Onset) <= phaseCfg.match_stim2
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
    Screen('DrawText', w, responsePromptText, respRectX, respRectY, cfg.text.fixationColor);
    %if phaseCfg.matchTextPrompt
    %  responsePromptText = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
    %  DrawFormattedText(w,responsePromptText,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    %else
    %  DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    %end
    if cfg.stim.photoCell
      Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
    end
    [respPromptOn, startRT] = Screen('Flip',w);
    
    % poll for a resp
    while (GetSecs - startRT) <= phaseCfg.match_response
      
      [keyIsDown, endRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
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
        Screen('DrawText', w, responsePromptText, respRectX, respRectY, cfg.text.fixationColor);
        %if phaseCfg.matchTextPrompt
        %  responsePromptText = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
        %  DrawFormattedText(w,responsePromptText,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        %else
        %  DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        %end
        
        % don't push multiple keys
        Screen('TextSize', w, cfg.text.instructTextSize);
        DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
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
    if (keyCode(cfg.keys.matchSame) == 1 && all(keyCode(~cfg.keys.matchSame) == 0))
      resp = 'same';
      if stim1(i).same
        acc = true;
        % only give feedback during practice
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
        % only give feedback during practice
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
        % only give feedback during practice
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
        % only give feedback during practice
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
      % only give feedback during practice
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
  
  if ~isempty(message)
    if phaseCfg.playSound && (~phaseCfg.isExp || (phaseCfg.isExp && ~keyIsDown))
      Beeper(respSound,respVol);
    end
    Screen('TextSize', w, cfg.text.instructTextSize);
    DrawFormattedText(w,message,'center','center',feedbackColor, cfg.text.instructCharWidth);
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
    elseif sum(keyCode) > 1
      thisResp = KbName(keyCode);
      respKey = sprintf('multikey%s',sprintf(repmat(' %s',1,numel(thisResp)),thisResp{:}));
    end
  else
    respKey = 'none';
  end
  
  if (phaseCfg.match_isi > 0 && phaseCfg.fixDuringISI) || (phaseCfg.match_isi == 0 && phaseCfg.fixDuringPreStim)
    % draw fixation after response
    Screen('TextSize', w, cfg.text.fixSize);
    Screen('DrawText', w, cfg.text.fixSymbol, fixRectX, fixRectY, cfg.text.fixationColor);
    %DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
  end
  
  if cfg.stim.photoCell
    Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
  end
  % clear screen
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', matchStim1Tex(i));
  Screen('Close', matchStim2Tex(i));
  
  % compute response time
  if phaseCfg.respDuringStim
    measureRTfromHere = stim2Onset;
  else
    measureRTfromHere = startRT;
  end
  rt = int32(round(1000 * (endRT - measureRTfromHere)));
  
  if cfg.text.printTrialInfo
    fprintf('Trial %d of %d: same (1) or diff (0): %d. response: %s (key: %s; acc = %d; rt = %d)\n',i,length(stim2),stim1(i).same,resp,respKey,acc,rt);
  end
  
  fNum1 = int32(stim1(i).familyNum);
  fNum2 = int32(stim2(i).familyNum);
  
  %% session log file
  
  if ~isfield(stim1(i),'new')
    % Write stim1 presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img1On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img2On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
  elseif isfield(stim1(i),'new')
    % add in whether this is a new species; assumes that "new species"
    % stimuli are always paired with other "new" stimuli
    
    % Write stim1 presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img1On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
      stim1(i).same,...
      stim1(i).new);
    
    % Write stim2 presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img2On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
      stim2(i).same,...
      stim2(i).new);
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'MATCH_RESP',...
      i,...
      isSubord,...
      stim2(i).trained,...
      stim2(i).same,...
      stim2(i).new,...
      resp,...
      respKey,...
      acc,...
      rt);
  end
  
  %% phase log file
  
  if ~isfield(stim1(i),'new')
    % Write stim1 presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img1On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img2On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
  elseif isfield(stim1(i),'new')
    % add in whether this is a new species; assumes that "new species"
    % stimuli are always paired with other "new" stimuli
    
    % Write stim1 presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img1On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
      stim1(i).same,...
      stim1(i).new);
    
    % Write stim2 presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
      img2On,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
      stim2(i).same,...
      stim2(i).new);
    
    % Write trial result to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'MATCH_RESP',...
      i,...
      isSubord,...
      stim2(i).trained,...
      stim2(i).same,...
      stim2(i).new,...
      resp,...
      respKey,...
      acc,...
      rt);
  end
  
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
    % 'stmn', stimulus name (family, species, exemplar)
    % 'famn', family number
    % 'spcn', species number (corresponds to keyboard)
    % 'snum', stimulus number (order in match presentation, 1 or 2)
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
    
    % 'news', whether this is a new species trial (1=yes, 0=no) (NB: only for some experiments!)
    
    % write out the stimulus name
    stim1Name = sprintf('%s%s%d',...
      stim1(i).familyStr,...
      stim1(i).speciesStr,...
      stim1(i).exemplarName);
    stim2Name = sprintf('%s%s%d',...
      stim2(i).familyStr,...
      stim2(i).speciesStr,...
      stim2(i).exemplarName);
    
    if ~isfield(stim1(i),'new')
      if ~isnan(preStim1FixOn)
        % pre-stim1 fixation
        [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStim1FixOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i), 'stmn', stim1Name, 'famn', fNum1, 'spcn', specNum1, 'snum', int32(stim1(i).matchStimNum),...
          'sord', isSubord, 'trai', stim1(i).trained, 'same', stim1(i).same,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % stim1 presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', img1On, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'trln', int32(i), 'stmn', stim1Name, 'famn', fNum1, 'spcn', specNum1, 'snum', int32(stim1(i).matchStimNum),...
        'sord', isSubord, 'trai', stim1(i).trained, 'same', stim1(i).same,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(preStim2FixOn)
        % pre-stim2 fixation
        [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStim2FixOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i), 'stmn', stim2Name, 'famn', fNum2, 'spcn', specNum2, 'snum', int32(stim2(i).matchStimNum),...
          'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % stim2 presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', img2On, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'trln', int32(i), 'stmn', stim2Name, 'famn', fNum2, 'spcn', specNum2, 'snum', int32(stim2(i).matchStimNum),...
        'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(respPromptOn)
        % response prompt
        [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
    elseif isfield(stim1(i),'new')
      if ~isnan(preStim1FixOn)
        % pre-stim1 fixation
        [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStim1FixOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i), 'stmn', stim1Name, 'famn', fNum1, 'spcn', specNum1, 'snum', int32(stim1(i).matchStimNum),...
          'sord', isSubord, 'trai', stim1(i).trained, 'same', stim1(i).same, 'news', stim1(i).new,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % stim1 presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', img1On, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'trln', int32(i), 'stmn', stim1Name, 'famn', fNum1, 'spcn', specNum1, 'snum', int32(stim1(i).matchStimNum),...
        'sord', isSubord, 'trai', stim1(i).trained, 'same', stim1(i).same, 'news', stim1(i).new,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(preStim2FixOn)
        % pre-stim2 fixation
        [NSEventStatus, NSEventError] = NetStation('Event', 'FIXT', preStim2FixOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i), 'stmn', stim2Name, 'famn', fNum2, 'spcn', specNum2, 'snum', int32(stim2(i).matchStimNum),...
          'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same, 'news', stim2(i).new,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % stim2 presentation
      [NSEventStatus, NSEventError] = NetStation('Event', 'STIM', img2On, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'trln', int32(i), 'stmn', stim2Name, 'famn', fNum2, 'spcn', specNum2, 'snum', int32(stim2(i).matchStimNum),...
        'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same, 'news', stim2(i).new,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(respPromptOn)
        % response prompt
        [NSEventStatus, NSEventError] = NetStation('Event', 'PROM', respPromptOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same, 'news', stim2(i).new,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = NetStation('Event', 'RESP', endRT, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'sord', isSubord, 'trai', stim2(i).trained, 'same', stim2(i).same, 'news', stim2(i).new,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
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

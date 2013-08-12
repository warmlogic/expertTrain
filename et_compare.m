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

% % durations, in seconds
% cfg.stim.(sesName).(phaseName).comp_isi = 0.0;
% cfg.stim.(sesName).(phaseName).comp_stim1 = 0.8;
% cfg.stim.(sesName).(phaseName).comp_stim2 = 0.8;
% % random intervals are generated on the fly
% cfg.stim.(sesName).(phaseName).comp_preStim1 = [0.5 0.7];
% cfg.stim.(sesName).(phaseName).comp_preStim2 = [1.0 1.2];
% cfg.stim.(sesName).(phaseName).comp_response = 2.0;

% % keys
% cfg.keys.compareKeyNames, encoded as:
% cfg.keys.c01
% cfg.keys.c02
% cfg.keys.c03
% cfg.keys.c04
% cfg.keys.c05

fprintf('Running %s %s (compare) (%d)...\n',sesName,phaseName,phaseCount);

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

% % set feedback colors
% correctColor = uint8((rgb('Green') * 255) + 0.5);
% incorrectColor = uint8((rgb('Red') * 255) + 0.5);

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

% TODO - always?
% are they allowed to respond while the stimulus is on the screen?
if ~isfield(phaseCfg,'respDuringStim')
  phaseCfg.respDuringStim = true;
end

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
message = 'Starting comparison phase...';
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = 'Starting data acquisition for comparison phase...';
  
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
  
  message = sprintf('Preparing images, please wait...');
  Screen('TextSize', w, cfg.text.basicTextSize);
  % put the instructions on the screen
  DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
  % Update the display to show the message:
  Screen('Flip', w);
  
  % initialize
  vStimTex = nan(1,length(viewStims));
  
  for i = 1:length(viewStims)
    % load up this stim's texture
    vStimImgFile = fullfile(stimDir,viewStims(i).familyStr,viewStims(i).fileName);
    if exist(vStimImgFile,'file')
      vStimImg = imread(vStimImgFile);
      vStimTex(i) = Screen('MakeTexture',w,vStimImg);
      % TODO: optimized?
      %stimtex(i) = Screen('MakeTexture',w,stimImg,[],1);
    else
      error('Study stimulus %s does not exist!',vStimImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(vStimImg,1) * cfg.stim.stimScale;
  stimImgWidth = size(vStimImg,2) * cfg.stim.stimScale;
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
  
%   % text location for error (e.g., "too fast") text
%   [~,errorTextY] = RectCenter(cfg.screen.wRect);
%   errorTextY = errorTextY + (stimImgHeight / 2);
  
  %% show the instructions - view
  
  for i = 1:length(phaseCfg.instruct.compView)
    WaitSecs(1.000);
    et_showTextInstruct(w,phaseCfg.instruct.compView(i),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
  end
  
  % Wait a second before starting trial
  WaitSecs(1.000);
  
  %% run the comparison - view task
  
  % start the blink break timer
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
    blinkTimerStart = GetSecs;
  end
  
  for i = trialNum:length(vStimTex)
    % do an impedance check after a certain number of blocks or trials
    if expParam.useNS && phaseCfg.isExp && i > 1 && i < length(vStimTex) && mod((i - 1),phaseCfg.impedanceAfter_nTrials)
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      % reset the blink timer
      if cfg.stim.secUntilBlinkBreak > 0
        blinkTimerStart = GetSecs;
      end
    end
    
    % Do a blink break if recording EEG and specified time has passed
    if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(vStimTex) - 3)
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      Screen('TextSize', w, cfg.text.basicTextSize);
      pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(vStimTex));
      % just draw straight into the main window since we don't need speed here
      DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      
      thisGetSecs = KbWait(-1,2);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('Flip',w);
      WaitSecs(0.5);
      % reset the timer
      blinkTimerStart = GetSecs;
    end
    
    % resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
    end
    
    fNum = int32(viewStims(i).familyNum);
    specNum = int32(viewStims(i).speciesNum);
    
    % ISI between trials
    if phaseCfg.comp_view_isi > 0
      WaitSecs(phaseCfg.comp_view_isi);
    end
    
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    [preStimFixOn] = Screen('Flip',w);
    
    % fixation on screen before stim
    if phaseCfg.comp_view_preStim > 0
      %WaitSecs(phaseCfg.comp_view_preStim);
      WaitSecs(phaseCfg.comp_view_preStim(1) + ((phaseCfg.comp_view_preStim(2) - phaseCfg.comp_view_preStim(1)).*rand(1,1)));
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, vStimTex(i), [], stimImgRect);
    % and fixation on top of it
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'stimOnset':
    [imgOn, stimOnset] = Screen('Flip', w);
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s, species num: %d.\n',i,length(vStimTex),viewStims(i).fileName,specNum);
    end
    
    % while loop to show stimulus until "duration" seconds elapse.
    while (GetSecs - stimOnset) <= phaseCfg.comp_view_stim
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % Clear screen to background color after response, with fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
      specNum,...
      fNum);
    
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
      specNum,...
      fNum);
    
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
      
      % write out the stimulus name
      stimName = sprintf('%s%s%d',...
        viewStims(i).familyStr,...
        viewStims(i).speciesStr,...
        viewStims(i).exemplarName);
      
      % pretrial fixation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum); %#ok<NASGU,ASGLU>
      
      % img presentation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', imgOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'trln', int32(i), 'stmn', stimName, 'famn', fNum, 'spcn', specNum); %#ok<NASGU,ASGLU>
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

% %% determine the starting trial, useful for resuming - between species
% 
% % set up progress file, to resume this phase in case of a crash, etc.
% phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_comp_bt_%d.mat',sesName,phaseName,phaseCount));
% if exist(phaseProgressFile,'file')
%   load(phaseProgressFile);
% else
%   trialComplete = false(1,length(expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims([expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims.compStimNum] == 2)));
%   phaseComplete = false; %#ok<NASGU>
%   save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete');
% end
% 
% % find the starting trial
% incompleteTrials = find(~trialComplete);
% if ~isempty(incompleteTrials)
%   trialNum = incompleteTrials(1);
%   runBt = true;
% else
%   fprintf('All trials for %s %s (comp between) (%d) have been completed. Moving on to next phase...\n',sesName,phaseName,phaseCount);
%   % release any remaining textures
%   Screen('Close');
%   runBt = false;
% end
% 
% if runBt
%   %% preload between stimuli for presentation
%   
%   btSpeciesStims = expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims;
%   
%   % get the stimulus 2s
%   btStim2 = btSpeciesStims([btSpeciesStims.compStimNum] == 2);
%   % initialize for storing stimulus 1s
%   btStim1 = struct([]);
%   fn = fieldnames(btStim2);
%   for i = 1:length(fn)
%     btStim1(1).(fn{i}) = [];
%   end
%   
%   btStim1Tex = nan(1,length(btStim2));
%   btStim2Tex = nan(1,length(btStim2));
%   
%   message = sprintf('Preparing images, please wait...');
%   Screen('TextSize', w, cfg.text.basicTextSize);
%   % put the "preparing" message on the screen
%   DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
%   % Update the display to show the message:
%   Screen('Flip', w);
%   
%   for i = 1:length(btStim2)
%     % find btStim2's corresponding pair
%     btStim1(i) = btSpeciesStims(...
%       ([btSpeciesStims.compPairNum] == btStim2(i).compPairNum) &...
%       ([btSpeciesStims.compStimNum] ~= btStim2(i).compStimNum));
%     
%     % TODO - make sure there's only 1 btStim1
%     if length(btSpeciesStims(...
%         ([btSpeciesStims.compPairNum] == btStim2(i).compPairNum) &...
%         ([btSpeciesStims.compStimNum] ~= btStim2(i).compStimNum))) > 1
%       keyboard
%     end
%     
%     % load up btStim2's texture
%     btStim2ImgFile = fullfile(stimDir,btStim2(i).familyStr,btStim2(i).fileName);
%     if exist(btStim2ImgFile,'file')
%       btStim2Img = imread(btStim2ImgFile);
%       btStim2Tex(i) = Screen('MakeTexture',w,btStim2Img);
%       % TODO: optimized?
%       %btStim2tex(i) = Screen('MakeTexture',w,btStim2Img,[],1);
%     else
%       error('Study stimulus %s does not exist!',btStim2ImgFile);
%     end
%     
%     % load up btStim1's texture
%     btStim1ImgFile = fullfile(stimDir,btStim1(i).familyStr,btStim1(i).fileName);
%     if exist(btStim1ImgFile,'file')
%       btStim1Img = imread(btStim1ImgFile);
%       btStim1Tex(i) = Screen('MakeTexture',w,btStim1Img);
%       % TODO: optimized?
%       %btStim1tex(i) = Screen('MakeTexture',w,btStim1Img,[],1);
%     else
%       error('Study stimulus %s does not exist!',btStim1ImgFile);
%     end
%   end
%   
%   % get the width and height of the final stimulus image
%   stimImgHeight = size(btStim1Img,1) * cfg.stim.stimScale;
%   stimImgWidth = size(btStim1Img,2) * cfg.stim.stimScale;
%   % set the stimulus image rectangle
%   stimImgRect = [0 0 stimImgWidth stimImgHeight];
%   stimImgRect = CenterRect(stimImgRect, cfg.screen.wRect);
%   % Stimulus rectangles shifted to left and right by 5% of screen width
%   stim1ImgRect = OffsetRect(stimImgRect,RectWidth(cfg.screen.wRect) * 0.05);
%   stim2ImgRect = OffsetRect(stimImgRect,RectWidth(cfg.screen.wRect) * 0.05 * -1);
%   
%   % % text location for error (e.g., "too fast") text
%   % [~,errorTextY] = RectCenter(cfg.screen.wRect);
%   % errorTextY = errorTextY + (stimImgHeight / 2);
%   
%   %% show the instructions - between
%   
%   for i = 1:length(phaseCfg.instruct.compBt)
%     WaitSecs(1.000);
%     et_showTextInstruct(w,phaseCfg.instruct.compBt(i),cfg.keys.instructContKey,...
%       cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
%   end
%   
%   % Wait a second before starting trial
%   WaitSecs(1.000);
%   
%   %% run the comparison - between task
%   
%   
%   
%   % cleanup
%   
%   endTime = fix(clock);
%   endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6)); %#ok<NASGU>
%   % save progress after finishing phase
%   phaseComplete = true; %#ok<NASGU>
%   save(phaseProgressFile,'thisDate','startTime','trialComplete','phaseComplete','endTime');
% end

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
  
  message = sprintf('Preparing images, please wait...');
  Screen('TextSize', w, cfg.text.basicTextSize);
  % put the "preparing" message on the screen
  DrawFormattedText(w, message, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
  % Update the display to show the message:
  Screen('Flip', w);
  
  for i = 1:length(wiStim2)
    % find wiStim2's corresponding pair
    wiStim1(i) = wiSpeciesStims(...
      ([wiSpeciesStims.compPairNum] == wiStim2(i).compPairNum) &...
      ([wiSpeciesStims.compStimNum] ~= wiStim2(i).compStimNum));
    
    % load up wiStim2's texture
    wiStim2ImgFile = fullfile(stimDir,wiStim2(i).familyStr,wiStim2(i).fileName);
    if exist(wiStim2ImgFile,'file')
      wiStim2Img = imread(wiStim2ImgFile);
      wiStim2Tex(i) = Screen('MakeTexture',w,wiStim2Img);
      % TODO: optimized?
      %wiStim2tex(i) = Screen('MakeTexture',w,wiStim2Img,[],1);
    else
      error('Study stimulus %s does not exist!',wiStim2ImgFile);
    end
    
    % load up wiStim1's texture
    wiStim1ImgFile = fullfile(stimDir,wiStim1(i).familyStr,wiStim1(i).fileName);
    if exist(wiStim1ImgFile,'file')
      wiStim1Img = imread(wiStim1ImgFile);
      wiStim1Tex(i) = Screen('MakeTexture',w,wiStim1Img);
      % TODO: optimized?
      %wiStim1tex(i) = Screen('MakeTexture',w,wiStim1Img,[],1);
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
  % Stimulus rectangles shifted to left and right by 5% of screen width
  stim1ImgRect = OffsetRect(stimImgRect,RectWidth(cfg.screen.wRect) * 0.05);
  stim2ImgRect = OffsetRect(stimImgRect,RectWidth(cfg.screen.wRect) * 0.05 * -1);
  
  % text location for error (e.g., "too fast") text
  [~,errorTextY] = RectCenter(cfg.screen.wRect);
  errorTextY = errorTextY + (stimImgHeight / 2);
  
  %% show the instructions - within
  
  for i = 1:length(phaseCfg.instruct.compWi)
    WaitSecs(1.000);
    et_showTextInstruct(w,phaseCfg.instruct.compWi(i),cfg.keys.instructContKey,...
      cfg.text.instructColor,cfg.text.instructTextSize,cfg.text.instructCharWidth);
  end
  
  % Wait a second before starting trial
  WaitSecs(1.000);
  
  %% run the comparison - within task
  
  % only check these keys
  RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
  
  % start the blink break timer
  if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0
    blinkTimerStart = GetSecs;
  end
  
  for i = trialNum:length(wiStim2Tex)
    % do an impedance check after a certain number of trials
    if expParam.useNS && phaseCfg.isExp && i > 1 && i < length(wiStim2Tex) && mod((i - 1),phaseCfg.impedanceAfter_nTrials) == 0
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
      
      % reset the blink timer
      if cfg.stim.secUntilBlinkBreak > 0
        blinkTimerStart = GetSecs;
      end
    end
    
    % Do a blink break if recording EEG and specified time has passed
    if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(wiStim2Tex) - 3)
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      Screen('TextSize', w, cfg.text.basicTextSize);
      pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(wiStim2Tex));
      % just draw straight into the main window since we don't need speed here
      DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      
      % listen for any keypress on any keyboard
      RestrictKeysForKbCheck([]);
      thisGetSecs = KbWait(-1,2);
      %thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.c01, cfg.keys.c02, cfg.keys.c03, cfg.keys.c04, cfg.keys.c05]);
      
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('Flip',w);
      WaitSecs(0.5);
      % reset the timer
      blinkTimerStart = GetSecs;
    end
    
    % resynchronize netstation before the start of drawing
    if expParam.useNS
      [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
    end
    
    % ISI between trials
    if phaseCfg.comp_wi_isi > 0
      WaitSecs(phaseCfg.comp_wi_isi);
    end
    
    % draw fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    [preStimFixOn] = Screen('Flip',w);
    
    % fixation on screen before stim1 for a random amount of time
    WaitSecs(phaseCfg.comp_wi_preStim(1) + ((phaseCfg.comp_wi_preStim(2) - phaseCfg.comp_wi_preStim(1)).*rand(1,1)));
    
    % draw the stimuli
    Screen('DrawTexture', w, wiStim1Tex(i), [], stim1ImgRect);
    Screen('DrawTexture', w, wiStim2Tex(i), [], stim2ImgRect);
    % and fixation
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'stimOnset':
    [imgOn, stimOnset] = Screen('Flip', w);
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: stim1 (%s): family %d (%s), species %d (%s), exemplar %d (%d).\n',i,length(wiStim2Tex),wiStim1(i).fileName,wiStim1(i).familyNum,wiStim1(i).familyStr,wiStim1(i).speciesNum,wiStim1(i).speciesStr,wiStim1(i).exemplarNum,wiStim1(i).exemplarName);
      fprintf('Trial %d of %d: stim2 (%s): family %d (%s), species %d (%s), exemplar %d (%d).\n',i,length(wiStim2Tex),wiStim2(i).fileName,wiStim2(i).familyNum,wiStim2(i).familyStr,wiStim2(i).speciesNum,wiStim2(i).speciesStr,wiStim2(i).exemplarNum,wiStim2(i).exemplarName);
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
          % and fixation
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
          % and fixation
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
      if phaseCfg.matchTextPrompt
        responsePromptText = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
        DrawFormattedText(w,responsePromptText,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      else
        DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
          if phaseCfg.matchTextPrompt
            responsePromptText = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
            DrawFormattedText(w,responsePromptText,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          else
            DrawFormattedText(w,cfg.text.respSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % don't push multiple keys
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.multiKeyText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
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
        resp = 1;
      elseif (keyCode(cfg.keys.c02) == 1 && all(keyCode(~cfg.keys.c02) == 0))
        resp = 2;
      elseif (keyCode(cfg.keys.c03) == 1 && all(keyCode(~cfg.keys.c03) == 0))
        resp = 3;
      elseif (keyCode(cfg.keys.c04) == 1 && all(keyCode(~cfg.keys.c04) == 0))
        resp = 4;
      elseif (keyCode(cfg.keys.c05) == 1 && all(keyCode(~cfg.keys.c05) == 0))
        resp = 5;
      end
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
    
    % draw fixation after response
    Screen('TextSize', w, cfg.text.fixSize);
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
      fprintf('Trial %d of %d: response: %s (key: %s; rt = %d)\n',i,length(wiStim2Tex),resp,respKey,rt);
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
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_RESP',...
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
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%d\n',...
      endRT,...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
      phaseCfg.isExp,...
      'COMP_RESP',...
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
      
      % pre-stim fixation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', preStimFixOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,'trln', int32(i),...
        'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      % stim presentation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', imgOn, .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,'trln', int32(i),...
        'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1, 'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(respPromptOn)
        % response prompt
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'PROM', respPromptOn, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'trln', int32(i),...
          'stm1', stim1Name, 'fam1', fNum1, 'spc1', specNum1,'stm2', stim2Name, 'fam2', fNum2, 'spc2', specNum2,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'RESP', endRT, .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,'trln', int32(i),...
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
save(mainPhaseProgressFile,'thisDate','startTime','phaseComplete','endTime');

end % function
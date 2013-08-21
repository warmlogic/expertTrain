function [cfg,expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName,phaseCount)
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

fprintf('Running %s %s (recog) (%d)...\n',sesName,phaseName,phaseCount);

%% set the starting date and time for this phase

thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% start the log file for this phase

phaseLogFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseLog_%s_%s_recog_%d.txt',sesName,phaseName,phaseCount));
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

% set up progress file, to resume this phase in case of a crash, etc.
phaseProgressFile_overall = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_recog_%d.mat',sesName,phaseName,phaseCount));
if ~exist(phaseProgressFile_overall,'file')
  phaseComplete = false; %#ok<NASGU>
  save(phaseProgressFile_overall,'thisDate','startTime','phaseComplete');
end

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
  phaseCfg.respDuringStim = false;
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
if ~isfield(phaseCfg,'fixWithStim')
  phaseCfg.fixWithStim = true;
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
message = 'Starting recognition phase...';
if expParam.useNS
  % start recording
  [NSStopStatus, NSStopError] = et_NetStation('StartRecording'); %#ok<NASGU,ASGLU>
  % synchronize
  [NSSyncStatus, NSSyncError] = et_NetStation('Synchronize'); %#ok<NASGU,ASGLU>
  message = 'Starting data acquisition for recognition phase...';
  
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
  
  %% determine the starting trial, useful for resuming
  
  % set up progress file, to resume this phase in case of a crash, etc.
  phaseProgressFile_study = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_recogstudy_%d.mat',sesName,phaseName,phaseCount));
  if exist(phaseProgressFile_study,'file')
    load(phaseProgressFile_study);
  else
    trialComplete = false(1,length(targStims{b}));
    phaseComplete = false; %#ok<NASGU>
    save(phaseProgressFile_study,'thisDate','startTime','trialComplete','phaseComplete','study_preStimFixOn','study_imgOn');
  end
  
  % find the starting trial
  incompleteTrials = find(~trialComplete);
  if ~isempty(incompleteTrials)
    trialNum = incompleteTrials(1);
    runRecogStudy = true;
  else
    fprintf('All trials for %s %s (recogstudy) (%d) have been completed. Moving on...\n',sesName,phaseName,phaseCount);
    % release any remaining textures
    Screen('Close');
    runRecogStudy = false;
  end
  
  %% prepare the recognition study task
  
  if runRecogStudy
    
    % put it in the log file
    startTime = fix(clock);
    startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));
    fprintf(logFile,'!!! Start of %s %s (%d) (%s study) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);
    fprintf(phLFile,'!!! Start of %s %s (%d) (%s study) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);
    
    % load up the stimuli for this block
    blockStudyStimTex = nan(1,length(targStims{b}));
    for i = 1:length(targStims{b})
      % this image
      stimImgFile = fullfile(stimDir,targStims{b}(i).familyStr,targStims{b}(i).fileName);
      if exist(stimImgFile,'file')
        stimImg = imread(stimImgFile);
        blockStudyStimTex(i) = Screen('MakeTexture',w,stimImg);
        % TODO: optimized?
        %blockStudyStimTex(i) = Screen('MakeTexture',w,stimImg,[],1);
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
    
    % text location for error (e.g., "too fast") text
    [~,errorTextY] = RectCenter(cfg.screen.wRect);
    errorTextY = errorTextY + (stimImgHeight / 2);
    
    %% do an impedance check before the block begins
    if expParam.useNS && phaseCfg.isExp && b > 1 && b < phaseCfg.nBlocks && mod((b - 1),phaseCfg.impedanceAfter_nBlocks) == 0
      % run the impedance break
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_START');
      thisGetSecs = et_impedanceCheck(w, cfg, true);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'IMPEDANCE_END');
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
    
    for i = trialNum:length(targStims{b})
      % Do a blink break if specified time has passed
      if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(targStims{b}) - 3)
        thisGetSecs = GetSecs;
        fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
        fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
        Screen('TextSize', w, cfg.text.basicTextSize);
        pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(targStims{b}));
        % just draw straight into the main window since we don't need speed here
        DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
        Screen('Flip', w);
        
        % listen for any keypress on any keyboard
        thisGetSecs = KbWait(-1,2);
        fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
        fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
        
        if phaseCfg.recog_study_isi > 0 && phaseCfg.fixDuringISI
          Screen('TextSize', w, cfg.text.fixSize);
          DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        end
        Screen('Flip',w);
        WaitSecs(0.5);
        % reset the timer
        blinkTimerStart = GetSecs;
      end
      
      % Is this a subordinate (1) or basic (0) family/species? If subordinate,
      % get the species number.
      if phaseCfg.isExp
        famNumSubord = cfg.stim.famNumSubord;
        famNumBasic = cfg.stim.famNumBasic;
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
      
      % ISI between trials
      if phaseCfg.recog_study_isi > 0
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
        Screen('Flip',w);
        WaitSecs(phaseCfg.recog_study_isi);
      end
      
      % TODO - remove commented
      
      % % draw fixation
      % Screen('TextSize', w, cfg.text.fixSize);
      % DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      % [study_preStimFixOn{b}(i)] = Screen('Flip',w);
      
      % % fixation on screen before starting trial
      % if phaseCfg.recog_study_preTarg > 0
      %   WaitSecs(phaseCfg.recog_study_preTarg);
      % end
      
      % preStimulus period, with fixation if desired
      if length(phaseCfg.recog_study_preTarg) == 1
        if phaseCfg.recog_study_preTarg > 0
          if phaseCfg.fixDuringPreStim
            % draw fixation
            Screen('TextSize', w, cfg.text.fixSize);
            DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
            [study_preStimFixOn{b}(i)] = Screen('Flip',w);
          else
            study_preStimFixOn{b}(i) = NaN;
            Screen('Flip',w);
          end
          WaitSecs(phaseCfg.recog_study_preTarg);
        end
      elseif length(phaseCfg.recog_study_preTarg) == 2
        if length(find(phaseCfg.recog_study_preTarg == 0)) ~= 2
          if phaseCfg.fixDuringPreStim
            % draw fixation
            Screen('TextSize', w, cfg.text.fixSize);
            DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
            [study_preStimFixOn{b}(i)] = Screen('Flip',w);
          else
            study_preStimFixOn{b}(i) = NaN;
            Screen('Flip',w);
          end
          % fixation on screen before stim for a random amount of time
          WaitSecs(phaseCfg.recog_study_preTarg(1) + ((phaseCfg.recog_study_preTarg(2) - phaseCfg.recog_study_preTarg(1)).*rand(1,1)));
        end
      end
      
      % draw the stimulus
      Screen('DrawTexture', w, blockStudyStimTex(i), [], stimImgRect);
      if phaseCfg.fixWithStim
        % and fixation on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      
      % Show stimulus on screen at next possible display refresh cycle,
      % and record stimulus onset time in 'startrt':
      [study_imgOn{b}(i), study_stimOnset] = Screen('Flip', w);
      
      if cfg.text.printTrialInfo
        fprintf('Trial %d of %d: %s.\n',i,length(targStims{b}),targStims{b}(i).fileName);
      end
      
      % while loop to show stimulus until subjects response or until
      % "duration" seconds elapsed.
      while (GetSecs - study_stimOnset) <= phaseCfg.recog_study_targ
        % Wait <1 ms before checking the keyboard again to prevent
        % overload of the machine at elevated Priority():
        WaitSecs(0.0001);
      end
      
      if phaseCfg.recog_study_isi > 0 && phaseCfg.fixDuringISI
        % draw fixation
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      
      % Clear screen to background color after fixed 'duration'
      Screen('Flip', w);
      
      % close this stimulus before next trial
      Screen('Close', blockStudyStimTex(i));
      
      %% session log file
      
      % Write study stimulus presentation to file:
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
        study_imgOn{b}(i),...
        expParam.subject,...
        sesName,...
        phaseName,...
        phaseCount,...
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
      
      %% phase log file
      
      % Write study stimulus presentation to file:
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
        study_imgOn{b}(i),...
        expParam.subject,...
        sesName,...
        phaseName,...
        phaseCount,...
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
      
      %% Write netstation logs for nontargets only (this might not occur)
      
      if expParam.useNS
        if ~targStims{b}(i).targ
          % Write trial info to et_NetStation
          % mark every event with the following key code/value pairs
          % 'subn', subject number
          % 'sess', session type
          % 'phas', session phase name
          % 'pcou', phase count
          % 'expt', whether this is the experiment (1) or practice (0)
          % 'bloc', int32(b)lock number (training day 1 only)
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
          
          if ~isnan(study_preStimFixOn{b}(i))
            % pretrial fixation
            [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', study_preStimFixOn{b}(i), .001,...
              'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
              'expt',phaseCfg.isExp,...
              'bloc', int32(b),...
              'part','study',...
              'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
              'targ', targStims{b}(i).targ); %#ok<NASGU,ASGLU>
          end
          
          % img presentation
          [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', study_imgOn{b}(i), .001,...
            'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
            'expt',phaseCfg.isExp,...
            'bloc', int32(b),...
            'part','study',...
            'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
            'targ', targStims{b}(i).targ); %#ok<NASGU,ASGLU>
        end
      end % useNS
      
      % mark that we finished this trial
      trialComplete(i) = true;
      % save progress after each trial
      save(phaseProgressFile_study,'thisDate','startTime','trialComplete','phaseComplete','study_preStimFixOn','study_imgOn');
    end % for stimuli
    
    % record the end time for this session
    endTime = fix(clock);
    endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6));
    % put it in the log file
    fprintf(logFile,'!!! End of %s %s (%d) (%s study) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);
    fprintf(phLFile,'!!! End of %s %s (%d) (%s study) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);
    
    % save progress after finishing phase
    phaseComplete = true; %#ok<NASGU>
    save(phaseProgressFile_study,'thisDate','startTime','trialComplete','phaseComplete','study_preStimFixOn','study_imgOn','endTime');
  end % runRecogStudy
  
  %% determine the starting trial, useful for resuming
  
  startTime = fix(clock);
  startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6)); %#ok<NASGU>
  
  % set up progress file, to resume this phase in case of a crash, etc.
  phaseProgressFile_test = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_%s_recogtest_%d.mat',sesName,phaseName,phaseCount));
  if exist(phaseProgressFile_test,'file')
    load(phaseProgressFile_test);
  else
    trialComplete = false(1,length(allStims{b}));
    phaseComplete = false; %#ok<NASGU>
    save(phaseProgressFile_test,'thisDate','startTime','trialComplete','phaseComplete','test_preStimFixOn','test_imgOn','respKeyImgOn','endRT');
  end
  
  % find the starting trial
  incompleteTrials = find(~trialComplete);
  if ~isempty(incompleteTrials)
    trialNum = incompleteTrials(1);
  else
    fprintf('All trials for %s %s (recogtest) (%d) have been completed. Moving on...\n',sesName,phaseName,phaseCount);
    % release any remaining textures
    Screen('Close');
    continue
  end
  
  %% Prepare the recognition test task
  
  % put it in the log file
  startTime = fix(clock);
  startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));
  fprintf(logFile,'!!! Start of %s %s (%d) (%s test) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);
  fprintf(phLFile,'!!! Start of %s %s (%d) (%s test) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,startTime);
  
  % load up the stimuli for this block
  blockTestStimTex = nan(1,length(allStims{b}));
  for i = 1:length(allStims{b})
    % this image
    stimImgFile = fullfile(stimDir,allStims{b}(i).familyStr,allStims{b}(i).fileName);
    if exist(stimImgFile,'file')
      stimImg = imread(stimImgFile);
      blockTestStimTex(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %blockTestStimTex(i) = Screen('MakeTexture',w,stimImg,[],1);
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
  
  for i = trialNum:length(allStims{b})
    % Do a blink break if recording EEG and specified time has passed
    if phaseCfg.isExp && cfg.stim.secUntilBlinkBreak > 0 && (GetSecs - blinkTimerStart) >= cfg.stim.secUntilBlinkBreak && i > 3 && i < (length(allStims{b}) - 3)
      thisGetSecs = GetSecs;
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_START');
      Screen('TextSize', w, cfg.text.basicTextSize);
      pauseMsg = sprintf('Blink now.\n\nReady for trial %d of %d.\nPress any key to continue.', i, length(allStims{b}));
      % just draw straight into the main window since we don't need speed here
      DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      
      % listen for any keypress on any keyboard
      RestrictKeysForKbCheck([]);
      thisGetSecs = KbWait(-1,2);
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'BLINK_END');
      % only check these keys
      RestrictKeysForKbCheck([cfg.keys.recogDefUn, cfg.keys.recogMayUn, cfg.keys.recogMayF, cfg.keys.recogDefF, cfg.keys.recogRecoll]);
      
      if phaseCfg.recog_test_isi > 0 && phaseCfg.fixDuringISI
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
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
    
    % ISI between trials
    if phaseCfg.recog_test_isi > 0
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      Screen('Flip',w);
      WaitSecs(phaseCfg.recog_test_isi);
    end
    
    % TODO - remove commented
    
    % % draw fixation
    % Screen('TextSize', w, cfg.text.fixSize);
    % DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    % [test_preStimFixOn{b}(i)] = Screen('Flip',w);
    
    % % fixation on screen before starting trial
    % if phaseCfg.recog_test_preStim > 0
    %   WaitSecs(phaseCfg.recog_test_preStim);
    % end
    
    % preStimulus period, with fixation if desired
    if length(phaseCfg.recog_test_preStim) == 1
      if phaseCfg.recog_test_preStim > 0
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          [test_preStimFixOn{b}(i)] = Screen('Flip',w);
        else
          test_preStimFixOn{b}(i) = NaN;
          Screen('Flip',w);
        end
        WaitSecs(phaseCfg.recog_test_preStim);
      end
    elseif length(phaseCfg.recog_test_preStim) == 2
      if length(find(phaseCfg.recog_test_preStim == 0)) ~= 2
        if phaseCfg.fixDuringPreStim
          % draw fixation
          Screen('TextSize', w, cfg.text.fixSize);
          DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          [test_preStimFixOn{b}(i)] = Screen('Flip',w);
        else
          test_preStimFixOn{b}(i) = NaN;
          Screen('Flip',w);
        end
        % fixation on screen before stim for a random amount of time
        WaitSecs(phaseCfg.recog_test_preStim(1) + ((phaseCfg.recog_test_preStim(2) - phaseCfg.recog_test_preStim(1)).*rand(1,1)));
      end
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, blockTestStimTex(i), [], stimImgRect);
    if phaseCfg.fixWithStim
      % and fixation on top of it
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'test_stimOnset':
    [test_imgOn{b}(i), test_stimOnset] = Screen('Flip', w);
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d.\n',i,length(allStims{b}),allStims{b}(i).fileName,allStims{b}(i).targ);
    end
    
    % while loop to show stimulus until "duration" seconds elapsed.
    while (GetSecs - test_stimOnset) <= phaseCfg.recog_test_stim
      % check for too-fast response
      if ~phaseCfg.respDuringStim
        [keyIsDown] = KbCheck;
        % if they press a key too early, tell them they responded too fast
        if keyIsDown
          % draw the stimulus
          Screen('DrawTexture', w, blockTestStimTex(i), [], stimImgRect);
          if phaseCfg.fixWithStim
            % and fixation on top of it
            Screen('TextSize', w, cfg.text.fixSize);
            DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
          end
          % and the "too fast" text
          Screen('TextSize', w, cfg.text.instructTextSize);
          DrawFormattedText(w,cfg.text.tooFastText,'center',errorTextY,cfg.text.errorTextColor, cfg.text.instructCharWidth);
          Screen('Flip', w);
          
          keyIsDown = 0;
          break
        end
      else
        [keyIsDown, endRT{b}(i), keyCode] = KbCheck;
        % if they push more than one key, don't accept it
        if keyIsDown && sum(keyCode) == 1
          % wait for key to be released
          while KbCheck(-1)
            WaitSecs(0.0001);
            
            % % proceed if time is up, regardless of whether key is held
            % if (GetSecs - startRT) > phaseCfg.recog_response
            %   break
            % end
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
        elseif keyIsDown && sum(keyCode) > 1
          % draw the stimulus
          Screen('DrawTexture', w, blockTestStimTex(i), [], stimImgRect);
          if phaseCfg.fixWithStim
            % and fixation on top of it
            Screen('TextSize', w, cfg.text.fixSize);
            DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
    while (GetSecs - test_stimOnset) <= phaseCfg.recog_test_stim
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    keyIsDown = logical(keyIsDown);
    
    if ~keyIsDown
      % draw the stimulus
      Screen('DrawTexture', w, blockTestStimTex(i), [], stimImgRect);
      % with the response key image
      Screen('DrawTexture', w, respKeyImg, [], respKeyImgRect);
      if phaseCfg.fixWithStim
        % and fixation on top of it
        Screen('TextSize', w, cfg.text.fixSize);
        DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
      end
      % put them on the screen; measure RT from when response key img appears
      [respKeyImgOn{b}(i), startRT] = Screen('Flip', w);
      
      % poll for a resp
      while (GetSecs - startRT) <= phaseCfg.recog_response
        
        [keyIsDown, endRT{b}(i), keyCode] = KbCheck;
        % if they push more than one key, don't accept it
        if keyIsDown && sum(keyCode) == 1
          % wait for key to be released
          while KbCheck(-1)
            WaitSecs(0.0001);
            
            % % proceed if time is up, regardless of whether key is held
            % if (GetSecs - startRT) > phaseCfg.recog_response
            %   break
            % end
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
        elseif keyIsDown && sum(keyCode) > 1
          % draw the stimulus
          Screen('DrawTexture', w, blockTestStimTex(i), [], stimImgRect);
          % with the response key image
          Screen('DrawTexture', w, respKeyImg, [], respKeyImgRect);
          if phaseCfg.fixWithStim
            % and fixation on top of it
            Screen('TextSize', w, cfg.text.fixSize);
            DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
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
    
    if ~keyIsDown
      if phaseCfg.playSound
        Beeper(phaseCfg.incorrectSound,phaseCfg.incorrectVol);
      end
      
      % "need to respond faster"
      Screen('TextSize', w, cfg.text.instructTextSize);
      DrawFormattedText(w,cfg.text.respondFaster,'center','center',cfg.text.respondFasterColor, cfg.text.instructCharWidth);
      Screen('Flip', w);
      
      % need a new endRT
      endRT{b}(i) = GetSecs;
      
      % wait to let them view the feedback
      WaitSecs(cfg.text.respondFasterFeedbackTime);
    end
    
    if phaseCfg.recog_test_isi > 0 && phaseCfg.fixDuringISI
      % draw fixation after response
      Screen('TextSize', w, cfg.text.fixSize);
      DrawFormattedText(w,cfg.text.fixSymbol,'center','center',cfg.text.fixationColor, cfg.text.instructCharWidth);
    end
    
    % clear screen
    Screen('Flip', w);
    
    % Close this stimulus before next trial
    Screen('Close', blockTestStimTex(i));
    
    % compute response time
    if phaseCfg.respDuringStim
      measureRTfromHere = test_stimOnset;
    else
      measureRTfromHere = startRT;
    end
    rt = int32(round(1000 * (endRT{b}(i) - measureRTfromHere)));
    
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
    if keyIsDown && sum(keyCode) == 1
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
      elseif keyCode(cfg.keys.recogRecoll) == 0 && keyCode(cfg.keys.recogDefF) == 0 && keyCode(cfg.keys.recogMayF) == 0 && keyCode(cfg.keys.recogMayUn) == 0 && keyCode(cfg.keys.recogDefUn) == 0
        warning('Key other than a recognition response key was pressed. This should not happen.\n');
        resp = 'ERROR_OTHERKEY';
      else
        warning('Some other error occurred.\n');
        resp = 'ERROR_OTHER';
      end
    elseif keyIsDown && sum(keyCode) > 1
      warning('Multiple keys were pressed.\n');
      resp = 'ERROR_MULTIKEY';
    elseif ~keyIsDown
      resp = 'none';
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
    
    if cfg.text.printTrialInfo
      fprintf('Trial %d of %d: %s, targ (1) or lure (0): %d. response: %s (key: %s; acc = %d; rt = %d)\n',i,length(allStims{b}),allStims{b}(i).fileName,allStims{b}(i).targ,resp,respKey,acc,rt);
    end
    
    %% session log file
    
    % Write test stimulus presentation to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
      test_imgOn{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    
    if ~isnan(respKeyImgOn{b}(i))
      % Write test key image presentation to file:
      fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
        respKeyImgOn{b}(i),...
        expParam.subject,...
        sesName,...
        phaseName,...
        phaseCount,...
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
    end
    
    % Write trial result to file:
    fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
      endRT{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    
    %% phase log file
    
    % Write test stimulus presentation to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
      test_imgOn{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    
    if ~isnan(respKeyImgOn{b}(i))
      % Write test key image presentation to file:
      fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\n',...
        respKeyImgOn{b}(i),...
        expParam.subject,...
        sesName,...
        phaseName,...
        phaseCount,...
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
    end
    
    % Write trial result to file:
    fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\n',...
      endRT{b}(i),...
      expParam.subject,...
      sesName,...
      phaseName,...
      phaseCount,...
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
    
    %% Write netstation logs
    
    if expParam.useNS
      % Write trial info to et_NetStation
      % mark every event with the following key code/value pairs
      % 'subn', subject number
      % 'sess', session type
      % 'phas', session phase name
      % 'pcou', phase count
      % 'expt', whether this is the experiment (1) or practice (0)
      % 'bloc', int32(b)lock number (training day 1 only)
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
      
      if ~isnan(test_preStimFixOn{b}(i))
        % pretrial fixation
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', test_preStimFixOn{b}(i), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'bloc', int32(b),...
          'part','test',...
          'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', allStims{b}(i).targ,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % img presentation
      [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', test_imgOn{b}(i), .001,...
        'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
        'expt',phaseCfg.isExp,...
        'bloc', int32(b),...
        'part','test',...
        'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', allStims{b}(i).targ,...
        'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      
      if ~isnan(respKeyImgOn{b}(i))
        % response prompt
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'PROM', respKeyImgOn{b}(i), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'bloc', int32(b),...
          'part','test',...
          'trln', int32(i), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord, 'targ', allStims{b}(i).targ,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
      
      % did they make a response?
      if keyIsDown
        % button push
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'RESP', endRT{b}(i), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'bloc', int32(b),...
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
        
        if ~isnan(study_preStimFixOn{b}(sInd))
          % pretrial fixation
          [NSEventStatus, NSEventError] = et_NetStation('Event', 'FIXT', study_preStimFixOn{b}(sInd), .001,...
            'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
            'expt',phaseCfg.isExp,...
            'bloc', int32(b),...
            'part','study',...
            'trln', int32(sInd), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
            'targ', targStims{b}(sInd).targ,...
            'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
        end
        
        % img presentation
        [NSEventStatus, NSEventError] = et_NetStation('Event', 'STIM', study_imgOn{b}(sInd), .001,...
          'subn', expParam.subject, 'sess', sesName, 'phas', phaseName, 'pcou', int32(phaseCount),...
          'expt',phaseCfg.isExp,...
          'bloc', int32(b),...
          'part','study',...
          'trln', int32(sInd), 'stmn', stimName, 'spcn', specNum, 'sord', isSubord,...
          'targ', targStims{b}(sInd).targ,...
          'rsps', resp, 'rspk', respKey, 'rspt', rt, 'corr', acc, 'keyp', keyIsDown); %#ok<NASGU,ASGLU>
      end
    end % useNS
    
    % mark that we finished this trial
    trialComplete(i) = true;
    % save progress after each trial
    save(phaseProgressFile_test,'thisDate','startTime','trialComplete','phaseComplete','test_preStimFixOn','test_imgOn','respKeyImgOn','endRT');
  end % for stimuli
  
  % reset the KbCheck
  RestrictKeysForKbCheck([]);
  
  % record the end time for this session
  endTime = fix(clock);
  endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6));
  % put it in the log file
  fprintf(logFile,'!!! End of %s %s (%d) (%s test) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);
  fprintf(phLFile,'!!! End of %s %s (%d) (%s test) %s %s\n',sesName,phaseName,phaseCount,mfilename,thisDate,endTime);
  
  % save progress after finishing phase
  phaseComplete = true; %#ok<NASGU>
  save(phaseProgressFile_test,'thisDate','startTime','trialComplete','phaseComplete','test_preStimFixOn','test_imgOn','respKeyImgOn','endRT','endTime');
end % for nBlocks

%% cleanup

% stop recording
if expParam.useNS
  WaitSecs(5.0);
  [NSSyncStatus, NSSyncError] = et_NetStation('StopRecording'); %#ok<NASGU,ASGLU>
  
  thisGetSecs = GetSecs;
  fprintf(logFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_STOP');
  fprintf(phLFile,'%f\t%s\t%s\t%s\t%d\t%d\t%s\n',thisGetSecs,expParam.subject,sesName,phaseName,phaseCount,phaseCfg.isExp,'NS_REC_STOP');
end

% Close the response key image
Screen('Close',respKeyImg);

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

phaseComplete = true; %#ok<NASGU>
save(phaseProgressFile_overall,'thisDate','startTime','phaseComplete','endTime');

end % function

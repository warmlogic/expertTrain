function et_calcExpDuration(cfg,expParam,durLimit)
% calculates the experiment duration

% if expParam.useNS

% set some constant durations (in seconds)

instructDur = 30;
blinkBreakDur = 5;
impedanceDur = 300; % 5 min = 300 seconds

% initialize
expDur = 0;

if ~exist('durLimit','var') || isempty(durLimit)
  error('durLimit variable not set properly! Can be ''min'',''med'', or ''max''.');
end

if strcmp(durLimit,'min')
  fprintf('Calculating MINIMUM experiment duration (responses limits are 0 sec).');
elseif strcmp(durLimit,'med')
  fprintf('Calculating MEDIUM experiment duration (responses limits are half length).');
elseif strcmp(durLimit,'max')
  fprintf('Calculating MAXIMUM experiment duration (responses limits are maximum length).');
end

if expParam.useNS
  fprintf(' Using EEG.\n');
else
  fprintf(' Not using EEG.\n');
end

for s = 1:expParam.nSessions
  % initialize
  sesDur = 0;
  
  % get the session name
  sesName = expParam.sesTypes{s};
  fprintf('\tSession %d/%d (%s)...\n',s,expParam.nSessions,sesName);
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  matchCount = 0;
  nameCount = 0;
  recogCount = 0;
  nametrainCount = 0;
  viewnameCount = 0;
  
  prac_matchCount = 0;
  prac_nameCount = 0;
  prac_recogCount = 0;
  
  % for each phase in this session, run the correct function
  for p = 1:length(expParam.session.(sesName).phases)
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case{'match'}
        % Subordinate Matching task (same/different)
        matchCount = matchCount + 1;
        phaseCount = matchCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1) + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).match_response / 2);
        end
        
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).allStims);
        
      case {'name'}
        % Naming task
        nameCount = nameCount + 1;
        phaseCount = nameCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
        
      case {'recog'}
        % Recognition (old/new) task
        recogCount = recogCount + 1;
        phaseCount = recogCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_preTarg + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_targ + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_preStim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).recog_response / 2);
        end
        
        nTrials = 0;
        nBlocks = cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks;
        
        for b = 1:nBlocks
          nTrials = nTrials + length(expParam.session.(sesName).(phaseName)(phaseCount).allStims{b});
        end
        
      case {'nametrain'}
        % Name training task
        nametrainCount = nametrainCount + 1;
        phaseCount = nametrainCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials = 0;
        nBlocks = length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder);
        
        % for each view/name block
        for b = 1:nBlocks
          nTrials = nTrials + length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b});
        end
        
      case {'viewname'}
        % Viewing task, with category response; intermixed with
        % Naming task
        viewnameCount = viewnameCount + 1;
        phaseCount = viewnameCount;
        
        trialDur_view = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).view_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).view_preStim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).view_stim;
        
        trialDur_name = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur_name = trialDur_name - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur_name = trialDur_name - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials_view = 0;
        nTrials_name = 0;
        
        nBlocks = length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder);
        
        % for each view/name block
        for b = 1:nBlocks
          nTrials_view = nTrials_view + length(expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b});
          nTrials_name = nTrials_name + length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b});
        end
        
        nTrials = nTrials_view + nTrials_name;
        
      case{'prac_match'}
        % Subordinate Matching task (same/different)
        prac_matchCount = prac_matchCount + 1;
        phaseCount = prac_matchCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1) + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).match_response / 2);
        end
        
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).allStims);
        
      case {'prac_name'}
        % Naming task
        prac_nameCount = prac_nameCount + 1;
        phaseCount = prac_nameCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
        
      case {'prac_recog'}
        % Recognition (old/new) task
        prac_recogCount = prac_recogCount + 1;
        phaseCount = prac_recogCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_preTarg + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_targ + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_preStim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).recog_response / 2);
        end
        
        nTrials = 0;
        nBlocks = cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks;
        
        for b = 1:nBlocks
          nTrials = nTrials + length(expParam.session.(sesName).(phaseName)(phaseCount).allStims{b});
        end
        
      otherwise
        warning('%s is not a configured phase in this session (%s)!\n',phaseName,sesName);
    end % switch
    
    % calculate the number of impedance breaks
    if expParam.useNS
      if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
        if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
          nImpedanceBreaks = floor(nTrials / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials) - 1;
        elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
          nImpedanceBreaks = floor(nBlocks / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks) - 1;
        end
      else
        nImpedanceBreaks = 0;
      end
    else
      nImpedanceBreaks = 0;
    end
    
    if ~strcmp(phaseName,'viewname')
      % calculate the phase duration without blink breaks
      phaseDur = instructDur + (trialDur * nTrials) + (nImpedanceBreaks * impedanceDur);
    else
      % calculate the phase duration without blink breaks
      phaseDur = instructDur + (trialDur_view * nTrials_view) + (trialDur_name * nTrials_name) + (nImpedanceBreaks * impedanceDur);
    end
    % calculate the number of blink breaks
    nBlinkBreaks = floor((trialDur * nTrials) / cfg.stim.secUntilBlinkBreak);
    % calculate the full phase duration
    phaseDur = phaseDur + (nBlinkBreaks * blinkBreakDur);
    
    if strcmp(durLimit,'min')
      fprintf('\t\tMINIMUM ');
    elseif strcmp(durLimit,'med')
      fprintf('\t\tMEDIUM ');
    elseif strcmp(durLimit,'max')
      fprintf('\t\tMAXIMUM ');
    end
    fprintf('phase %d/%d (%s):\t%.2f min. %d trials, %d blink breaks (every %d sec)',p,length(expParam.session.(sesName).phases),phaseName,(phaseDur / 60),nTrials,nBlinkBreaks,cfg.stim.secUntilBlinkBreak);
    if expParam.useNS
      if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
        fprintf(', %d impedance breaks',nImpedanceBreaks);
        if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
          fprintf(' (every %d trials).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials);
        elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
          fprintf(' (every %d blocks).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
        end
      else
        fprintf(', no impdance breaks during practice.\n');
      end
    else
      fprintf('.\n');
    end
    
    % add this phase to the session
    sesDur = sesDur + phaseDur;
  end % p
  
  if strcmp(durLimit,'min')
    fprintf('\tMINIMUM ');
  elseif strcmp(durLimit,'med')
    fprintf('\tMEDIUM ');
  elseif strcmp(durLimit,'max')
    fprintf('\tMAXIMUM ');
  end
  fprintf('session %d/%d (%s): %.2f min.\n\n',s,expParam.nSessions,sesName,(sesDur / 60));
  
  % add this session to the entire experiment
  expDur = expDur + sesDur;
end % s

if strcmp(durLimit,'min')
  fprintf('MINIMUM ');
elseif strcmp(durLimit,'med')
  fprintf('MEDIUM ');
elseif strcmp(durLimit,'max')
  fprintf('MAXIMUM ');
end
fprintf('%s experiment: %.2f min (across %d sessions).\n\n',expParam.expName,(expDur / 60),expParam.nSessions);

end
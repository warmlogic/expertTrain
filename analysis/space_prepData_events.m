function space_prepData_events(subjects)
% space_prepData_events(subjects)
%
% Purpose
%   Create behavioral events
%
% Inputs
%   subjects: a cell of subject numbers
%
% Outputs
%   Events (struct and NetStation) will be saved in:
%     ~/data/SPACE/Behavioral/Sessions/subject/events
%
% Assumptions
%   Each subject ran in one session (oneDay)
%
%   The behavioral data is located in:
%     ~/data/SPACE/Behavioral/Sessions/subject/session
%

expName = 'SPACE';

behDataFolder = 'Behavioral';
% behDataFolder = 'Behavioral_pilot';

serverDir = fullfile(filesep,'Volumes','curranlab','Data',expName,behDataFolder,'Sessions');
serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data',expName,behDataFolder,'Sessions');
localDir = fullfile(getenv('HOME'),'data',expName,behDataFolder,'Sessions');
if exist('serverDir','var') && exist(serverDir,'dir')
  dataroot = serverDir;
elseif exist('serverLocalDir','var') && exist(serverLocalDir,'dir')
  dataroot = serverLocalDir;
elseif exist('localDir','var') && exist(localDir,'dir')
  dataroot = localDir;
else
  error('No data directory found.');
end
saveDir = dataroot;

if ~exist('subjects','var') || isempty(subjects)
  subjects = {
    'SPACE001';
    'SPACE002';
    'SPACE003';
    'SPACE004';
    'SPACE005';
    'SPACE006';
    'SPACE007';
    'SPACE008';
    'SPACE009';
    'SPACE010';
    'SPACE011';
    'SPACE012';
    'SPACE013';
    'SPACE014';
    'SPACE015';
    'SPACE016';
    'SPACE017';
    'SPACE018';
    'SPACE019';
    'SPACE020';
    'SPACE021';
    'SPACE022';
    'SPACE027';
    'SPACE029';
    'SPACE037';
    'SPACE039'; % original EEG analyses stopped here
    'SPACE023';
    'SPACE024';
    'SPACE025';
    'SPACE026';
    'SPACE028';
    'SPACE030';
    'SPACE032';
    'SPACE034';
    'SPACE047';
    'SPACE049';
    'SPACE036';
    };
  
  %   % behavioral pilot
  %   subjects = {
  %     'SPACE001';
  %     'SPACE002';
  %     'SPACE003';
  %     'SPACE004';
  %     'SPACE005';
  %     'SPACE006';
  %     'SPACE007';
  %     'SPACE008';
  %     'SPACE009';
  %     'SPACE010';
  %     'SPACE011';
  %     'SPACE012';
  %     'SPACE013';
  %     'SPACE014';
  %     'SPACE015';
  %     'SPACE016';
  %     'SPACE017';
  %     'SPACE018';
  %     'SPACE019';
  %     'SPACE020';
  %     'SPACE021';
  %     'SPACE022';
  %     'SPACE023';
  %     'SPACE024';
  %     'SPACE025';
  %     'SPACE026';
  %     'SPACE027';
  %     'SPACE028';
  %     'SPACE029';
  %     'SPACE030';
  %     'SPACE031';
  %     'SPACE032';
  %     'SPACE033';
  %     'SPACE034';
  %     'SPACE035';
  %     'SPACE036';
  %     'SPACE037';
  %     'SPACE038'; % responded "J" to almost all cued recall prompts
  %     'SPACE039';
  %     'SPACE040';
  %     'SPACE041';
  %     'SPACE042';
  %     'SPACE043';
  %     'SPACE044';
  %     };
end

for sub = 1:length(subjects)
  fprintf('Working on %s...\n',subjects{sub});
  
  % set the subject events directory
  eventsOutdir_sub = fullfile(saveDir,subjects{sub},'events');
  if ~exist(eventsOutdir_sub,'dir')
    mkdir(eventsOutdir_sub);
  end
  
  eventsOutfile_sub = fullfile(eventsOutdir_sub,'events.mat');
  if ~exist(eventsOutfile_sub,'file')
    
    expParamFile = fullfile(dataroot,subjects{sub},'experimentParams.mat');
    if exist(expParamFile,'file')
      fprintf('Loading experiment parameter file for %s (%s).\n',subjects{sub},expParamFile);
      load(expParamFile);
    else
      error('Experiment parameter file does not exist: %s',expParamFile);
    end
    
    fprintf('Creating events for %s (%s).\n',subjects{sub},eventsOutfile_sub);
    
    % initialize the events struct
    events = struct;
    
    % go through each session
    for sesNum = 1:length(expParam.sesTypes)
      % set the subject events file
      sesName = expParam.sesTypes{sesNum};
      
      uniquePhaseNames = unique(expParam.session.(sesName).phases);
      uniquePhaseCounts = zeros(1,length(unique(expParam.session.(sesName).phases)));
      
      for pha = 1:length(expParam.session.(sesName).phases)
        phaseName = expParam.session.(sesName).phases{pha};
        
        % find out where this phase occurs in the list of unique phases
        uniquePhaseInd = find(ismember(uniquePhaseNames,phaseName));
        % increase the phase count for that phase
        uniquePhaseCounts(uniquePhaseInd) = uniquePhaseCounts(uniquePhaseInd) + 1;
        % set the phase count
        phaseCount = uniquePhaseCounts(uniquePhaseInd);
        
        %if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
        %if ~lockFile(eventsOutfile_sub)
        %fprintf('Creating events for %s %s (session_%d) %s (%d)...\n',subjects{sub},sesName,sesNum,phaseName,phaseCount);
        
        % create the events
        events = space_createEvents(events,dataroot,subjects{sub},sesNum,sesName,phaseName,phaseCount);
        
        % release the lockFile
        %releaseFile(eventsOutfile_sub);
        %end
      end
      
      %% put subsequent memory info in exposure events
      
      sourceDestPhases = {'cued_recall', 'expo'};
      sourceStimType = {'RECOGTEST_STIM'};
      fn_ses = fieldnames(events.(sesName));
      
      fprintf('Putting %s info in %s events...\n',sourceDestPhases{1},sourceDestPhases{2});
      
      for fn = 1:length(fn_ses)
        if ~isstrprop(fn_ses{fn}(end),'digit') && ~strcmp(fn_ses{fn}(end-1),'_')
          continue
        end
        
        if ~isempty(strfind(fn_ses{fn},sourceDestPhases{1}))
          sourcePhase = fn_ses{fn};
          
          if isempty(strfind(fn_ses{fn},'prac_'))
            phaseCount = str2double(strrep(fn_ses{fn},sprintf('%s_',sourceDestPhases{1}),''));
            destPhase = sprintf('%s_%d',sourceDestPhases{2},phaseCount);
          else
            phaseCount = str2double(strrep(strrep(fn_ses{fn},'prac_',''),sprintf('%s_',sourceDestPhases{1}),''));
            destPhase = sprintf('prac_%s_%d',sourceDestPhases{2},phaseCount);
          end
          
          if isfield(events.(sesName),sourcePhase) && isfield(events.(sesName),destPhase)
            % set apart the correct subset of source events
            sourceEvents = events.(sesName).(sourcePhase).data(ismember({events.(sesName).(sourcePhase).data.type},sourceStimType));
            
            % go through the destination events
            for ev = 1:length(events.(sesName).(destPhase).data)
              %keyboard
              if events.(sesName).(destPhase).data(ev).targ
                % find the source event
                sourceInd = find([sourceEvents.stimNum] == events.(sesName).(destPhase).data(ev).stimNum & ...
                  [sourceEvents.i_catNum] == events.(sesName).(destPhase).data(ev).i_catNum);
                
                % transfer information
                if ~isempty(sourceInd)
                  if length(sourceInd) == 1
                    events.(sesName).(destPhase).data(ev).cr_recog_acc = sourceEvents(sourceInd).recog_acc;
                    if ~strcmp(sourceEvents(sourceInd).recall_resp,'NO_RESPONSE') && ~isempty(sourceEvents(sourceInd).recall_resp)
                      events.(sesName).(destPhase).data(ev).cr_recall_resp = true;
                    else
                      events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
                    end
                    events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = sourceEvents(sourceInd).recall_spellCorr;
                  else
                    fprintf('Found more than one source event!\n');
                    keyboard
                  end
                else
                  % IMPORTANT: there will be no source event for single
                  % presentation destination events (lag==-1) if single
                  % presentation items are not tested
                  % (cfg.stim.testOnePres=false). This should be changed if
                  % we test single presentation items.
                  
                  if events.(sesName).(destPhase).data(ev).lag == -1
                    events.(sesName).(destPhase).data(ev).cr_recog_acc = false;
                    events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
                    events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = false;
                  else
                    fprintf('Did not find the source event!\n');
                    keyboard
                  end
                end
              else
                events.(sesName).(destPhase).data(ev).cr_recog_acc = false;
                events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
                events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = false;
              end
            end
          else
            fprintf('Source phase ''%s'' and/or destionation phase ''%s'' does not exist!\n',sourcePhase,destPhase);
            keyboard
          end
        end
      end
      
      %% put subsequent memory info in study events
      
      sourceDestPhases = {'cued_recall', 'multistudy'};
      sourceStimType = {'RECOGTEST_STIM'};
      fn_ses = fieldnames(events.(sesName));
      
      fprintf('Putting %s info in %s events...\n',sourceDestPhases{1},sourceDestPhases{2});
      
      for fn = 1:length(fn_ses)
        if ~isstrprop(fn_ses{fn}(end),'digit') && ~strcmp(fn_ses{fn}(end-1),'_')
          continue
        end
        
        if ~isempty(strfind(fn_ses{fn},sourceDestPhases{1}))
          sourcePhase = fn_ses{fn};
          
          if isempty(strfind(fn_ses{fn},'prac_'))
            phaseCount = str2double(strrep(fn_ses{fn},sprintf('%s_',sourceDestPhases{1}),''));
            destPhase = sprintf('%s_%d',sourceDestPhases{2},phaseCount);
          else
            phaseCount = str2double(strrep(strrep(fn_ses{fn},'prac_',''),sprintf('%s_',sourceDestPhases{1}),''));
            destPhase = sprintf('prac_%s_%d',sourceDestPhases{2},phaseCount);
          end
          
          if isfield(events.(sesName),sourcePhase) && isfield(events.(sesName),destPhase)
            % set apart the correct subset of source events
            sourceEvents = events.(sesName).(sourcePhase).data(ismember({events.(sesName).(sourcePhase).data.type},sourceStimType));
            
            % go through the destination events
            for ev = 1:length(events.(sesName).(destPhase).data)
              %keyboard
              if events.(sesName).(destPhase).data(ev).targ
                % find the source event
                if strcmp(events.(sesName).(destPhase).data(ev).type,'STUDY_IMAGE')
                  sourceInd = find([sourceEvents.stimNum] == events.(sesName).(destPhase).data(ev).stimNum & ...
                    [sourceEvents.i_catNum] == events.(sesName).(destPhase).data(ev).catNum);
                elseif strcmp(events.(sesName).(destPhase).data(ev).type,'STUDY_WORD')
                  % find the image that went with this word
                  imgInd = [events.(sesName).(destPhase).data.pairNum] == events.(sesName).(destPhase).data(ev).pairNum & ...
                    [events.(sesName).(destPhase).data.presNum] == events.(sesName).(destPhase).data(ev).presNum & ...
                    ismember({events.(sesName).(destPhase).data.type},'STUDY_IMAGE');
                  if sum(imgInd) == 1
                    sourceInd = find([sourceEvents.stimNum] == events.(sesName).(destPhase).data(imgInd).stimNum & ...
                      [sourceEvents.i_catNum] == events.(sesName).(destPhase).data(imgInd).catNum & ...
                      ismember(lower({sourceEvents.recall_origword}),lower(events.(sesName).(destPhase).data(ev).stimStr)));
                    if isempty(sourceInd)
                      % old stimuli called 'new' do not get recall_origword
                      % assigned for some reason
                      sourceInd = find([sourceEvents.stimNum] == events.(sesName).(destPhase).data(imgInd).stimNum & ...
                        [sourceEvents.i_catNum] == events.(sesName).(destPhase).data(imgInd).catNum);
                    end
                  else
                    fprintf('More than one image match found!\n');
                    keyboard
                  end
                  %sourceInd = find(ismember(lower({sourceEvents.recall_origword}),lower(events.(sesName).(destPhase).data(ev).stimStr)));
                end
                
                % transfer information
                if ~isempty(sourceInd)
                  if length(sourceInd) == 1
                    events.(sesName).(destPhase).data(ev).cr_recog_acc = sourceEvents(sourceInd).recog_acc;
                    if ~strcmp(sourceEvents(sourceInd).recall_resp,'NO_RESPONSE') && ~isempty(sourceEvents(sourceInd).recall_resp)
                      events.(sesName).(destPhase).data(ev).cr_recall_resp = true;
                    else
                      events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
                    end
                    events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = sourceEvents(sourceInd).recall_spellCorr;
                  else
                    fprintf('Found more than one source event!\n');
                    keyboard
                  end
                else
                  % IMPORTANT: there will be no source event for single
                  % presentation destination events (lag==-1) if single
                  % presentation items are not tested
                  % (cfg.stim.testOnePres=false). This should be changed if
                  % we test single presentation items.
                  
                  if events.(sesName).(destPhase).data(ev).lag == -1
                    events.(sesName).(destPhase).data(ev).cr_recog_acc = false;
                    events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
                    events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = false;
                  else
                    fprintf('Did not find the source event!\n');
                    keyboard
                  end
                end
              else
                events.(sesName).(destPhase).data(ev).cr_recog_acc = false;
                events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
                events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = false;
              end
            end
          else
            fprintf('Source phase ''%s'' and/or destionation phase ''%s'' does not exist!\n',sourcePhase,destPhase);
            keyboard
          end
        end
      end
      
      %% collapse phases
      
      fprintf('\nCollapsing same phases together within ''%s'' session...',sesName);
      % remove the phase numbers
      fn = fieldnames(events.(sesName));
      fn_trunc = fn;
      for p = 1:length(fn_trunc)
        startPN = strfind(fn_trunc{p},'_');
        if length(fn_trunc{p}(startPN(end):end)) == 2
          fn_trunc{p} = fn_trunc{p}(1:startPN(end) - 1);
        end
      end
      % get the unique phase types
      u_phases = unique(fn_trunc);
      for up = 1:length(u_phases)
        for p = 1:length(fn)
          % if it's the same phase type, concatenate the events. Can use
          % phaseCount field to divide them later.
          if strncmp(u_phases{up},fn{p},length(u_phases{up}))
            if events.(sesName).(fn{p}).isComplete
              thisPhase = events.(sesName).(fn{p}).data;
              if str2double(fn{p}(end)) == 1
                events.(sesName).(u_phases{up}).data = thisPhase;
              else
                events.(sesName).(u_phases{up}).data = cat(1,events.(sesName).(u_phases{up}).data,thisPhase);
              end
            else
              fprintf('\n');
              warning('%s %s %s is not complete. Not collapsing!',subjects{sub},sesName,fn{p});
            end
          end
          
        end
        % set this phase as complete
        events.(sesName).(u_phases{up}).isComplete = true;
      end
      fprintf('Done.\n');
      
    end
  else
    %     % hack to set each phase as complete
    %     load(eventsOutfile_sub);
    %
    %     for sesNum = 1:length(expParam.sesTypes)
    %       % set the subject events file
    %       sesName = expParam.sesTypes{sesNum};
    %
    %       % phase names without phase numbers
    %       uniquePhaseNames = unique(expParam.session.(sesName).phases);
    %       % all phase names, including some with phase numbers
    %       fn = fieldnames(events.(sesName));
    %       % set them as complete
    %       fprintf('Marking %s %s as complete (%s).\n',subjects{sub},sesName,eventsOutfile_sub);
    %       for p = 1:length(fn)
    %         if ismember(fn{p},uniquePhaseNames)
    %           events.(sesName).(fn{p}).isComplete = true;
    %         end
    %       end
    %     end
    
    fprintf('%s already exists! Moving on...\n',eventsOutfile_sub);
    continue
  end % if exist
  
  fprintf('Saving %s...',eventsOutfile_sub);
  % save each subject's events
  save(eventsOutfile_sub,'events','-v7');
  fprintf('Done.\n');
  
  fprintf('Done processing %s.\n',subjects{sub});
end % sub

end % function

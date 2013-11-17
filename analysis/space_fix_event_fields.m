function space_fix_event_fields

% change SPACE EEG event struct fields for image category number and string
%
% Fix 1:
% expo: get rid of empty catNum and catStr fields.
% cued_recall: change catNum and catStr to i_catNum and i_catStr
%
% OR:
%
% Fix 2:
% fix some cued recall empty fields when NO_RESPONSE occurs
%
% OR:
%
% Fix 3:
% transfer event info in existing event files
%
% OR:
%
% Fix 4:
% change expo rating negative ones to zeros
%

dataroot = '~/data/SPACE/Behavioral/Sessions';
% subjects = {'SPACE001'};
subjects = {'SPACE001', 'SPACE002', 'SPACE003', 'SPACE004', 'SPACE005', 'SPACE006', 'SPACE007'};
% sesNum = 1;
% sesDir = sprintf('session_%d',sesNum);
sesName = 'oneDay';

fixNum = 4;

%% Fix 1

if fixNum == 1
  phaseNames = {'expo', 'cued_recall'};
  phaseCounts = 1:7;
  
  for sub = 1:length(subjects)
    subject = subjects{sub};
    fprintf('%s...',subject);
    
    eventsFile = fullfile(dataroot,subject,'events','events.mat');
    eventsFile_backup = fullfile(dataroot,subject,'events','events_old.mat');
    
    if exist(eventsFile,'file')
      unix(sprintf('cp %s %s',eventsFile,eventsFile_backup));
      load(eventsFile);
    else
      error('Could not find events file: %s',eventsFile);
    end
    
    for pn = 1:length(phaseNames)
      phaseName = phaseNames{pn};
      fprintf('%s...',phaseName);
      
      if strcmp(phaseName,'cued_recall')
        if isfield(events.(sesName).(phaseName).data,'catStr')
          % why is this first one different from the others
          [events.(sesName).(phaseName).data(:).i_catStr] = deal(events.(sesName).(phaseName).data(:).catStr);
          events.(sesName).(phaseName).data = rmfield(events.(sesName).(phaseName).data,'catStr');
        end
        
        if isfield(events.(sesName).(phaseName).data,'catNum')
          [events.(sesName).(phaseName).data(:).i_catNum] = deal(events.(sesName).(phaseName).data(:).catNum);
          events.(sesName).(phaseName).data = rmfield(events.(sesName).(phaseName).data,'catNum');
        end
        
        for phaseCount = phaseCounts
          if isfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catStr')
            [events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data(:).i_catStr] = deal(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data(:).catStr);
            events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = rmfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catStr');
          end
          
          if isfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catNum')
            [events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data(:).i_catNum] = deal(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data(:).catNum);
            events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = rmfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catNum');
          end
        end % phaseCount
        
      elseif strcmp(phaseName,'expo')
        events.(sesName).(phaseName).data = rmfield(events.(sesName).(phaseName).data,'catStr');
        events.(sesName).(phaseName).data = rmfield(events.(sesName).(phaseName).data,'catNum');
        
        for phaseCount = phaseCounts
          if isfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catStr')
            events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = rmfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catStr');
          end
          
          if isfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catNum')
            events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = rmfield(events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,'catNum');
          end
        end % phaseCount
      end
    end % phaseNames
    
    save(eventsFile,'events');
    fprintf('\n');
    
  end % subject
  
end

%% Fix 2

if fixNum == 2
  phaseNames = {'cued_recall'};
  %phaseCounts = 1:7;
  
  for sub = 1:length(subjects)
    subject = subjects{sub};
    fprintf('%s...',subject);
    
    eventsFile = fullfile(dataroot,subject,'events','events.mat');
    eventsFile_backup = fullfile(dataroot,subject,'events','events_old.mat');
    
    if exist(eventsFile,'file')
      unix(sprintf('cp %s %s',eventsFile,eventsFile_backup));
      load(eventsFile);
    else
      error('Could not find events file: %s',eventsFile);
    end
    
    for pn = 1:length(phaseNames)
      phaseName = phaseNames{pn};
      fprintf('%s...',phaseName);
      
      fn_ses = fieldnames(events.(sesName));
      
      for fn = 1:length(fn_ses)
        if ~isempty(strfind(fn_ses{fn},phaseNames{pn}))
          for ev = 1:length(events.(sesName).(fn_ses{fn}).data)
            if strcmp(events.(sesName).(fn_ses{fn}).data(ev).recog_resp,'NO_RESPONSE')
              if isempty(events.(sesName).(fn_ses{fn}).data(ev).new_resp)
                events.(sesName).(fn_ses{fn}).data(ev).new_resp = '';
              end
              if isempty(events.(sesName).(fn_ses{fn}).data(ev).new_acc)
                events.(sesName).(fn_ses{fn}).data(ev).new_acc = false;
              end
              if isempty(events.(sesName).(fn_ses{fn}).data(ev).new_rt)
                events.(sesName).(fn_ses{fn}).data(ev).new_rt = -1;
              end
              
              if isempty(events.(sesName).(fn_ses{fn}).data(ev).recall_origword)
                events.(sesName).(fn_ses{fn}).data(ev).recall_origword = '';
              end
              if isempty(events.(sesName).(fn_ses{fn}).data(ev).recall_resp)
                events.(sesName).(fn_ses{fn}).data(ev).recall_resp = '';
              end
              if isempty(events.(sesName).(fn_ses{fn}).data(ev).recall_spellCorr)
                events.(sesName).(fn_ses{fn}).data(ev).recall_spellCorr = false;
              end
              if isempty(events.(sesName).(fn_ses{fn}).data(ev).recall_rt)
                events.(sesName).(fn_ses{fn}).data(ev).recall_rt = -1;
              end
              
            end
          end
        end
      end
      
    end % phaseNames
    
    save(eventsFile,'events');
    fprintf('\n');
    
  end % subject
  
end

%% fix 3

if fixNum == 3
  for sub = 1:length(subjects)
    subject = subjects{sub};
    fprintf('%s...',subject);
    
    eventsFile = fullfile(dataroot,subject,'events','events.mat');
    eventsFile_backup = fullfile(dataroot,subject,'events','events_old.mat');
    
    if exist(eventsFile,'file')
      unix(sprintf('cp %s %s',eventsFile,eventsFile_backup));
      load(eventsFile);
    else
      error('Could not find events file: %s',eventsFile);
    end
    
    %% put subsequent memory info in exposure events
    
    sourceDestPhases = {'cued_recall', 'expo'};
    sourceStimType = {'RECOGTEST_STIM'};
    fn_ses = fieldnames(events.(sesName));
    
    fprintf('Putting %s info in %s events...',sourceDestPhases{1},sourceDestPhases{2});
    
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
          phaseCount = str2double(strrep(strrep(fn_ses{fn},'prac_',''),sprintf('%s_',sourceDestPhases{1})));
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
    
    fprintf('Putting %s info in %s events...',sourceDestPhases{1},sourceDestPhases{2});
    
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
          phaseCount = str2double(strrep(strrep(fn_ses{fn},'prac_',''),sprintf('%s_',sourceDestPhases{1})));
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
    
    fieldsToRemove = {'expo','multistudy','distract_math','cued_recall'};
    for i = 1:length(fieldsToRemove)
      if isfield(events.(sesName),fieldsToRemove{i})
        events.(sesName) = rmfield(events.(sesName),fieldsToRemove{i});
      end
    end
    
    fprintf('\nCollapsing phases together...');
    
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
          thisPhase = events.(sesName).(fn{p}).data;
          if str2double(fn{p}(end)) == 1
            events.(sesName).(u_phases{up}).data = thisPhase;
          else
            events.(sesName).(u_phases{up}).data = cat(1,events.(sesName).(u_phases{up}).data,thisPhase);
          end
        end
        
      end
      % set this phase as complete
      events.(sesName).(u_phases{up}).isComplete = true;
    end
    
    save(eventsFile,'events');
    fprintf('\n');
    
  end % subject
  
end

%% Fix 4 - change expo rating negative ones to zeros

if fixNum == 4
  phaseNames = {'expo'};
  phaseCounts = 1:7;
  
  for sub = 1:length(subjects)
    subject = subjects{sub};
    fprintf('%s...',subject);
    
    eventsFile = fullfile(dataroot,subject,'events','events.mat');
    eventsFile_backup = fullfile(dataroot,subject,'events','events_old.mat');
    
    if exist(eventsFile,'file')
      unix(sprintf('cp %s %s',eventsFile,eventsFile_backup));
      load(eventsFile);
    else
      error('Could not find events file: %s',eventsFile);
    end
    
    for pn = 1:length(phaseNames)
      phaseName = phaseNames{pn};
      fprintf('%s...',phaseName);
      
      if strcmp(phaseName,'expo')
        negOneInd = find([events.(sesName).(phaseName).data.resp] == -1);
        if ~isempty(negOneInd)
          for i = 1:length(negOneInd)
            events.(sesName).(phaseName).data(negOneInd(i)).resp = 0;
          end
        end
        
        for phaseCount = phaseCounts
          negOneInd = find([events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data.resp] == -1);
          if ~isempty(negOneInd)
            for i = 1:length(negOneInd)
              events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data(negOneInd(i)).resp = 0;
            end
          end
          
        end % phaseCount
      end
    end % phaseNames
    
    save(eventsFile,'events');
    fprintf('\n');
    
  end % subject
  
end

%% done
fprintf('Done.\n');

end % function

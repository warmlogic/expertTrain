function space2_prepData_events(subjects)
% space2_prepData_events(subjects)
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

expName = 'SPACE2';

% behDataFolder = 'Behavioral';
beh_dir = 'behavioral_pilot';

serverDir = fullfile(filesep,'Volumes','curranlab','Data',expName,beh_dir,'Sessions');
serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data',expName,beh_dir,'Sessions');
localDir = fullfile(getenv('HOME'),'data',expName,beh_dir,'Sessions');
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
    'SPACE2001';
    'SPACE2002';
    'SPACE2003';
    'SPACE2004';
    'SPACE2005';
    'SPACE2006';
    'SPACE2007';
    'SPACE2008';
    'SPACE2009';
    'SPACE2010';
    'SPACE2011';
    'SPACE2012';
    'SPACE2013';
    'SPACE2014';
    'SPACE2015';
    'SPACE2016';
    'SPACE2017';
    'SPACE2018';
    'SPACE2019';
    'SPACE2020';
    'SPACE2021';
    'SPACE2022';
    'SPACE2023';
    'SPACE2024';
    'SPACE2025';
    'SPACE2026';
    'SPACE2027';
    'SPACE2028';
    'SPACE2029';
    'SPACE2029-2';
    'SPACE2030';
    'SPACE2031';
    'SPACE2032';
    'SPACE2033';
    'SPACE2034';
    'SPACE2035';
    'SPACE2036';
    };
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
    
    % hack
    if strcmp(beh_dir,'behavioral_pilot')
      expParam.sesTypes = {'day1'};
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
        events = space2_createEvents(events,dataroot,subjects{sub},sesNum,sesName,phaseName,phaseCount);
        
        % release the lockFile
        %releaseFile(eventsOutfile_sub);
        %end
      end
      
%       %% put subsequent memory info in exposure events
%       
%       sourceDestPhases = {'cued_recall', 'expo'};
%       sourceStimType = {'RECOGTEST_STIM'};
%       fn_ses = fieldnames(events.(sesName));
%       
%       fprintf('Putting %s info in %s events...\n',sourceDestPhases{1},sourceDestPhases{2});
%       
%       for fn = 1:length(fn_ses)
%         if ~isstrprop(fn_ses{fn}(end),'digit') && ~strcmp(fn_ses{fn}(end-1),'_')
%           continue
%         end
%         
%         if ~isempty(strfind(fn_ses{fn},sourceDestPhases{1}))
%           sourcePhase = fn_ses{fn};
%           
%           if isempty(strfind(fn_ses{fn},'prac_'))
%             phaseCount = str2double(strrep(fn_ses{fn},sprintf('%s_',sourceDestPhases{1}),''));
%             destPhase = sprintf('%s_%d',sourceDestPhases{2},phaseCount);
%           else
%             phaseCount = str2double(strrep(strrep(fn_ses{fn},'prac_',''),sprintf('%s_',sourceDestPhases{1}),''));
%             destPhase = sprintf('prac_%s_%d',sourceDestPhases{2},phaseCount);
%           end
%           
%           if isfield(events.(sesName),sourcePhase) && isfield(events.(sesName),destPhase)
%             % set apart the correct subset of source events
%             sourceEvents = events.(sesName).(sourcePhase).data(ismember({events.(sesName).(sourcePhase).data.type},sourceStimType));
%             
%             % go through the destination events
%             for ev = 1:length(events.(sesName).(destPhase).data)
%               %keyboard
%               if events.(sesName).(destPhase).data(ev).targ
%                 % find the source event
%                 sourceInd = find([sourceEvents.stimNum] == events.(sesName).(destPhase).data(ev).stimNum & ...
%                   [sourceEvents.i_catNum] == events.(sesName).(destPhase).data(ev).i_catNum);
%                 
%                 % transfer information
%                 if ~isempty(sourceInd)
%                   if length(sourceInd) == 1
%                     events.(sesName).(destPhase).data(ev).cr_recog_acc = sourceEvents(sourceInd).recog_acc;
%                     if ~strcmp(sourceEvents(sourceInd).recall_resp,'NO_RESPONSE') && ~isempty(sourceEvents(sourceInd).recall_resp)
%                       events.(sesName).(destPhase).data(ev).cr_recall_resp = true;
%                     else
%                       events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
%                     end
%                     events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = sourceEvents(sourceInd).recall_spellCorr;
%                   else
%                     fprintf('Found more than one source event!\n');
%                     keyboard
%                   end
%                 else
%                   % IMPORTANT: there will be no source event for single
%                   % presentation destination events (lag==-1) if single
%                   % presentation items are not tested
%                   % (cfg.stim.testOnePres=false). This should be changed if
%                   % we test single presentation items.
%                   
%                   if events.(sesName).(destPhase).data(ev).lag == -1
%                     events.(sesName).(destPhase).data(ev).cr_recog_acc = false;
%                     events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
%                     events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = false;
%                   else
%                     fprintf('Did not find the source event!\n');
%                     keyboard
%                   end
%                 end
%               else
%                 events.(sesName).(destPhase).data(ev).cr_recog_acc = false;
%                 events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
%                 events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = false;
%               end
%             end
%           else
%             fprintf('Source phase ''%s'' and/or destionation phase ''%s'' does not exist!\n',sourcePhase,destPhase);
%             keyboard
%           end
%         end
%       end
      
      %% put subsequent memory info in study events
      
      sourceDestPhases = {'cued_recall_only', 'multistudy'};
      sourceStimType = {'TEST_STIM'};
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
            if isfield(events.(sesName).(sourcePhase),'data') && isfield(events.(sesName).(destPhase),'data')
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
                      %                     events.(sesName).(destPhase).data(ev).cr_recog_acc = sourceEvents(sourceInd).recog_acc;
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
                    
                    %%%% TODO
                    
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
            elseif ~isfield(events.(sesName).(sourcePhase),'data') && isfield(events.(sesName).(destPhase),'data')
              fprintf('data field for source phase ''%s'' does not exist (but it does for destionation phase ''%s'')!\n',sourcePhase,destPhase);
              % did not finish this phase
              if ~isempty(events.(sesName).(destPhase).data)
                for ev = 1:length(events.(sesName).(destPhase).data)
                  events.(sesName).(destPhase).data(ev).cr_recog_acc = false;
                  events.(sesName).(destPhase).data(ev).cr_recall_resp = false;
                  events.(sesName).(destPhase).data(ev).cr_recall_spellCorr = false;
                end
              end
            elseif isfield(events.(sesName).(sourcePhase),'data') && ~isfield(events.(sesName).(destPhase),'data')
              fprintf('data field for source phase ''%s'' exist, but it does for destionation phase ''%s''! (this is very odd)\n',sourcePhase,destPhase);
              keyboard
            else
              fprintf('data fields for both source phase ''%s'' and destionation phase ''%s'' does not exist!\n',sourcePhase,destPhase);
              keyboard
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
                if ~isempty(thisPhase)
                  events.(sesName).(u_phases{up}).data = cat(1,events.(sesName).(u_phases{up}).data,thisPhase);
                end
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

function space_prepData_events(subjects,prep_eeg)
% space_prepData_events(subjects,prep_eeg)
%
% Purpose
%   Create behavioral events; if prep_eeg == 1: export Net Station events
%
% Inputs
%   subjects: a cell of subject numbers
%
%   prep_eeg: boolean, whether or not to prepare the EEG data
%
% Outputs
%   Events (struct and NetStation) will be saved in:
%     ~/data/SPACE/Behavioral/Sessions/subject/events
%
% Assumptions
%   Each subject ran in both sessions (session_0 and session_1)
%
%   The behavioral data is located in:
%     ~/data/SPACE/Behavioral/Sessions/subject/session
%
% NB: EEG processing and NS event creation are not done yet
%

expName = 'SPACE';

behDataFolder = 'Behavioral';
% behDataFolder = 'Behavioral_pilot';

serverDir = fullfile(filesep,'Volumes','curranlab','Data',expName,behDataFolder,'Sessions');
serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data',expName,behDataFolder,'Sessions');
localDir = fullfile(getenv('HOME'),'data',expName,behDataFolder,'Sessions');
if exist(serverDir,'dir')
  dataroot = serverDir;
elseif exist(serverLocalDir,'dir')
  dataroot = serverLocalDir;
elseif exist(localDir,'dir')
  dataroot = localDir;
else
  error('No data directory found.');
end
saveDir = dataroot;

if nargin == 0
  subjects = {
    'SPACE001';
    'SPACE002';
    'SPACE003';
    'SPACE004';
    'SPACE005';
    'SPACE006';
    'SPACE007';
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
  
  prep_eeg = 0;
end

%sessions = {'session_0','session_1'};

%matlabpool open

for sub = 1:length(subjects)
  fprintf('Getting data for %s...\n',subjects{sub});
  
  if prep_eeg == 1
    % find the bad channels for this subject and session
    %       sesStruct = filterStruct(infoStruct,'ismember(subject,varargin{1}) & ismember(session,varargin{2})',subjects{sub},sessions{ses});
    %       subSesBadChan = sesStruct.badChan;
    %       if isempty(sesStruct)
    %         error('no subject listing found for this session');
    %       end
    subSesBadChan = [];
  end
  
  % set the subject events directory
  eventsOutdir_sub = fullfile(saveDir,subjects{sub},'events');
  if ~exist(eventsOutdir_sub,'dir')
    mkdir(eventsOutdir_sub);
  end
  
  expParamFile = fullfile(dataroot,subjects{sub},'experimentParams.mat');
  if exist(expParamFile,'file')
    fprintf('Loading experiment parameter file for %s (%s).\n',subjects{sub},expParamFile);
    load(expParamFile)
  else
    error('Experiment parameter file does not exist: %s',expParamFile);
  end
  
  eventsOutfile_sub = fullfile(eventsOutdir_sub,'events.mat');
  if ~exist(eventsOutfile_sub,'file')
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
        
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          %if ~lockFile(eventsOutfile_sub)
          %fprintf('Creating events for %s %s (session_%d) %s (%d)...\n',subjects{sub},sesName,sesNum,phaseName,phaseCount);
          
          % create the events
          events = space_createEvents(events,dataroot,subjects{sub},sesNum,sesName,phaseName,phaseCount);
          
          % release the lockFile
          %releaseFile(eventsOutfile_sub);
        end
        
      end
      
      % collapse phases
      fprintf('\n');
      
      fprintf('Collapsing phases together...');
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
  save(eventsOutfile_sub,'events');
  fprintf('Done.\n');
  
  %% prep the EEG data
  if prep_eeg == 1
    for sesNum = 1:length(expParam.sesTypes)
      fprintf('Prepping EEG data for %s...\n',expParam.sesTypes{sesNum});
      % get this subject's session dir
      subDir = fullfile(dataroot,subjects{sub});
      sesDir = fullfile(subDir,sprintf('session_%d',sesNum));
      
      subEegDir = fullfile(sesDir,'eeg','eeg.noreref');
      pfile = dir(fullfile(subEegDir,[subjects{sub},'*params.txt']));
      
      if ~exist(fullfile(subEegDir,pfile.name),'file')
        curDir = pwd;
        % cd to the session directory since prep_egi_data needs to be there
        cd(sesDir);
        % align the behavioral and EEG data
        %
        % TODO: make sure this works
        prep_egi_data_CU(subjects{sub},sesDir,{fullfile(subDir,'events',sprintf('events_ses%d.mat',sesNum))},subSesBadChan,'mstime','HCGSN');
        % go back to the previous working directory
        cd(curDir);
      end
      
      % export the events for netstation; saves to the session's events dir
      %
      % TODO: create/fix space_events2ns so it doesn't rely on events in
      % session directory
      fprintf('space_events2ns IS NOT DONE YET!!!\n');
      space_events2ns(dataroot,subjects{sub},sesNum);
      
    end % ses
    
  end % prep_eeg
  fprintf('Done processing %s.\n',subjects{sub});
end % sub

%matlabpool close

function ebird_prepData_events(subjects)
% ebird_prepData_events(subjects)
%
% Purpose
%   Create behavioral events
%
% Inputs
%   subjects: a cell of subject numbers
%
% Outputs
%   Events (struct and NetStation) will be saved in:
%     ~/data/EBIRD/Behavioral/Sessions/subject/events
%
%   The behavioral data is located in:
%     ~/data/EBIRD/Behavioral/Sessions/subject/session
%

expName = 'EBIRD';

serverDir = fullfile(filesep,'Volumes','curranlab','Data',expName,'Behavioral','Sessions');
serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data',expName,'Behavioral','Sessions');
localDir = fullfile(getenv('HOME'),'data',expName,'Behavioral','Sessions');
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

% if ~exist('prep_eeg','var') || isempty(prep_eeg)
%   prep_eeg = false;
% end

% DNF = "Did not finish" some number of sessions

if ~exist('subjects','var') || isempty(subjects)
  subjects = {
    %'EBIRD049'; % Pilot. (due to short ses1 match, missing ses2 name)
    %'EBIRD002'; % Pilot. (due to short ses1 match, missing ses2 name)
    %'EBIRD003'; % Pilot. (due to missing ses7 name) - NB: LAST PILOT TO BE REPLACED
    %'EBIRD004'; % DNF. Dropout. Last session: 8.
    'EBIRD005';
    %'EBIRD006'; % DNF. Dropout. Last session: 2.
    'EBIRD007';
    'EBIRD008';
    'EBIRD009';
    'EBIRD010';
    'EBIRD011';
    'EBIRD012';
    %'EBIRD013'; % DNF. Dropout. Last session: 5. Lost session 6 in HD crash.
    %'EBIRD014'; % DNF. Rejected. Last session: 1.
    %'EBIRD015'; % DNF. Lost in HD crash.
    %'EBIRD016'; % DNF. Lost in HD crash.
    %'EBIRD017'; % DNF. Lost in HD crash.
    'EBIRD018';
    'EBIRD019';
    'EBIRD020';
    'EBIRD021';
    %'EBIRD022'; % DNF. Dropout. Last session: 8.
    %'EBIRD023'; % DNF. Dropout. Last session: 1.
    'EBIRD024';
    'EBIRD025';
    'EBIRD027';
    'EBIRD029';
    'EBIRD032';
    'EBIRD034';
    'EBIRD042';
    };
end

%sessions = {'session_0','session_1'};

%matlabpool open

for sub = 1:length(subjects)
  fprintf('Getting data for %s...\n',subjects{sub});
  
%   if prep_eeg
%     % find the bad channels for this subject and session
%     %       sesStruct = filterStruct(infoStruct,'ismember(subject,varargin{1}) & ismember(session,varargin{2})',subjects{sub},sessions{ses});
%     %       subSesBadChan = sesStruct.badChan;
%     %       if isempty(sesStruct)
%     %         error('no subject listing found for this session');
%     %       end
%     subSesBadChan = [];
%   end
  
  % set the subject events directory
  eventsOutdir_sub = fullfile(saveDir,subjects{sub},'events');
  if ~exist(eventsOutdir_sub,'dir')
    mkdir(eventsOutdir_sub);
  end
  
  expParamFile = fullfile(dataroot,subjects{sub},'experimentParams.mat');
  if exist(expParamFile,'file')
    load(expParamFile)
  else
    error('experiment parameter file does not exist: %s',expParamFile);
  end
  
  eventsOutfile_sub = fullfile(eventsOutdir_sub,'events.mat');
  %if ~exist(eventsOutfile_sub,'file')
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
        events = ebird_createEvents(events,cfg,expParam,dataroot,subjects{sub},sesNum,sesName,phaseName,phaseCount);
        
        % release the lockFile
        %releaseFile(eventsOutfile_sub);
        %end
        
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
      fprintf('Done.\n\n');
      
    end % sesNum
%   else
%     %fprintf('%s already exists! Skipping this subject!\n',eventsOutfile_sub);
%     %continue
%     fprintf('%s already exists! Moving on...\n',eventsOutfile_sub);
%     continue
  %end % if exist
  
  fprintf('Saving %s...',eventsOutfile_sub);
  % save each subject's events
  save(eventsOutfile_sub,'events','-v7');
  %saveEvents(events,eventsOutfile_sub);
  fprintf('Done.\n');
  
%   %% prep the EEG data
%   if prep_eeg
%     for sesNum = 1:length(expParam.sesTypes)
%       fprintf('Prepping EEG data for %s...\n',expParam.sesTypes{sesNum});
%       % get this subject's session dir
%       subDir = fullfile(dataroot,subjects{sub});
%       sesDir = fullfile(subDir,sprintf('session_%d',sesNum));
%       
%       subEegDir = fullfile(sesDir,'eeg','eeg.noreref');
%       pfile = dir(fullfile(subEegDir,[subjects{sub},'*params.txt']));
%       
%       if ~exist(fullfile(subEegDir,pfile.name),'file')
%         curDir = pwd;
%         % cd to the session directory since prep_egi_data needs to be there
%         cd(sesDir);
%         % align the behavioral and EEG data
%         %
%         % TODO: make sure this works
%         prep_egi_data_CU(subjects{sub},sesDir,{fullfile(subDir,'events',sprintf('events_ses%d.mat',sesNum))},subSesBadChan,'mstime','HCGSN');
%         % go back to the previous working directory
%         cd(curDir);
%       end
%       
%       % export the events for netstation; saves to the session's events dir
%       %
%       % TODO: create/fix ebird_events2ns so it doesn't rely on events in
%       % session directory
%       fprintf('ebird_events2ns IS NOT DONE YET!!!\n');
%       ebird_events2ns(dataroot,subjects{sub},sesNum);
%       
%     end % ses
%   end % prep_eeg
  
  fprintf('Done processing %s.\n',subjects{sub});
end % sub

%matlabpool close

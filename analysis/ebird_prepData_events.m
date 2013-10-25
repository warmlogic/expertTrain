function ebird_prepData_events(subjects,prep_eeg)
% ebird_prepData_events(subjects,prep_eeg)
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
%     ~/data/EBIRD/Behavioral/Sessions/subject/events
%
% Assumptions
%   Each subject ran in both sessions (session_0 and session_1)
%
%   The behavioral data is located in:
%     ~/data/EBIRD/Behavioral/Sessions/subject/session
%
% NB: EEG processing and NS event creation are not done yet
%

expName = 'EBIRD';

serverDir = fullfile(filesep,'Volumes','curranlab','Data',expName,'Behavioral','Sessions');
serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data',expName,'Behavioral','Sessions');
localDir = fullfile(getenv('HOME'),'data',expName,'Behavioral','Sessions');
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
    'EBIRD049';
    'EBIRD002';
    'EBIRD003';
    'EBIRD004';
    'EBIRD005';
    'EBIRD006';
    'EBIRD007';
    'EBIRD008';
    'EBIRD009';
    'EBIRD010';
    'EBIRD011';
    'EBIRD012';
    'EBIRD013';
    'EBIRD014';
    };
  
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
        
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          %if ~lockFile(eventsOutfile_sub)
          %fprintf('Creating events for %s %s (session_%d) %s (%d)...\n',subjects{sub},sesName,sesNum,phaseName,phaseCount);
          
          % create the events
          events = ebird_createEvents(events,cfg,expParam,dataroot,subjects{sub},sesNum,sesName,phaseName,phaseCount);
          
          % release the lockFile
          %releaseFile(eventsOutfile_sub);
        end
        
      end
    end
%   else
%     %fprintf('%s already exists! Skipping this subject!\n',eventsOutfile_sub);
%     %continue
%     fprintf('%s already exists! Moving on...\n',eventsOutfile_sub);
%     continue
  %end % if exist
  
  fprintf('Saving %s...',eventsOutfile_sub);
  % save each subject's events
  save(eventsOutfile_sub,'events');
  %saveEvents(events,eventsOutfile_sub);
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
      % TODO: create/fix ebird_events2ns so it doesn't rely on events in
      % session directory
      fprintf('ebird_events2ns IS NOT DONE YET!!!\n');
      ebird_events2ns(dataroot,subjects{sub},sesNum);
      
    end % ses
    
  end % prep_eeg
  fprintf('Done processing %s.\n',subjects{sub});
end % sub

%matlabpool close

function [events] = comp_createEvents(events,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
% function [events] = comp_createEvents(events,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
%
% create event struct for COMP
%
% NB: comp_prepData_events runs comp_createEvents
%
% if you want you could maybe create a comp_processData script to put it
% all in a summary spreadsheet and comp_visualizeData to make some plots

fprintf('Processing %s %s (session_%d) %s (%d)...',subject,sesName,sesNum,phaseName,phaseCount);

sesDir = sprintf('session_%d',sesNum);

commentStyle = '!!!';

% mark that this subject has not completed the experiment
if ~isfield(events,'isComplete')
  events.isComplete = false;
end

switch phaseName
  case {'compare'}
    
    %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_comp_%d.txt',sesName,phaseName,phaseCount));
    
    % this format string should work for view, stim, and resp trials
    formatStr = '%.6f%s%s%s%d%d%s%d%s%s%s%s%s%s%s%s%s%s%s%s';
    if exist(logFile,'file')
      
      % set up column numbers denoting kinds of data in the log file
      compS = struct;
      
      % common
      compS.time = 1;
      compS.subject = 2;
      compS.session = 3;
      compS.phase = 4;
      compS.phaseCount = 5;
      compS.isExp = 6;
      compS.type = 7;
      compS.trial = 8;
      
      % unique to {'COMP_VIEW_STIM'}
      compS.v_familyStr = 9;
      compS.v_speciesStr = 10;
      compS.v_exemplarNum = 11;
      compS.v_familyNum = 12;
      compS.v_speciesNum = 13;
      
      % unique to {'COMP_*_STIM'}
      compS.s_family1Str = 9;
      compS.s_species1Str = 10;
      compS.s_exemplar1Num = 11;
      compS.s_family1Num = 12;
      compS.s_species1Num = 13;
      compS.s_trained1 = 14;
      compS.s_family2Str = 15;
      compS.s_species2Str = 16;
      compS.s_exemplar2Num = 17;
      compS.s_family2Num = 18;
      compS.s_species2Num = 19;
      compS.s_trained2 = 20;
      
      % unique to {'COMP_*_RESP'}
      compS.r_resp = 9;
      compS.r_respKey = 10;
      compS.r_rt = 11;
      
      %% read the real file
      fid = fopen(logFile);
      logData = textscan(fid,formatStr,'Delimiter','\t','emptyvalue',NaN, 'CommentStyle',commentStyle);
      fclose(fid);
      
      if isempty(logData{1})
        error('Log file seems to be empty, something is wrong: %s',logFile);
      end
    else
      %error('Log file file not found: %s',logFile);
      warning('Log file file not found: %s',logFile);
      events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = false;
      return
    end
    
    % set all fields here so we can easily concatenate events later
    log = struct('subject',subject,'session',sesNum,'sesName',sesName,...
      'phaseName',phaseName,'phaseCount',phaseCount,...
      'isExp',num2cell(logical(logData{compS.isExp})), 'time',num2cell(logData{compS.time}),...
      'type',logData{compS.type}, 'trial',num2cell(single(logData{compS.trial})),...
      'family1Str',[], 'family1Num',[], 'species1Str',[], 'species1Num',[], 'exemplar1Num',[], 'trained1',[],...
      'family2Str',[], 'family2Num',[], 'species2Str',[], 'species2Num',[], 'exemplar2Num',[], 'trained2',[],...
      'resp',[], 'rt',[]);
    
    for i = 1:length(log)
      switch log(i).type
        % case {'COMP_VIEW_STIM'}
        
        % not currently saving the initial viewing trials
        
        case {'COMP_BT_STIM', 'COMP_WI_STIM'}
          % unique to COMP_*_STIM
          log(i).family1Str = logData{compS.s_family1Str}{i};
          log(i).family1Num = str2double(logData{compS.s_family1Num}{i});
          log(i).species1Str = logData{compS.s_species1Str}{i};
          log(i).species1Num = str2double(logData{compS.s_species1Num}{i});
          log(i).exemplar1Num = str2double(logData{compS.s_exemplar1Num}{i});
          log(i).trained1 = logical(str2double(logData{compS.s_trained1}{i}));
          
          log(i).family2Str = logData{compS.s_family2Str}{i};
          log(i).family2Num = str2double(logData{compS.s_family2Num}{i});
          log(i).species2Str = logData{compS.s_species2Str}{i};
          log(i).species2Num = str2double(logData{compS.s_species2Num}{i});
          log(i).exemplar2Num = str2double(logData{compS.s_exemplar2Num}{i});
          log(i).trained2 = logical(str2double(logData{compS.s_trained2}{i}));
          
        case {'COMP_BT_RESP', 'COMP_WI_RESP'}
          % unique to COMP_*_RESP
          if ~strcmp(logData{compS.r_resp}{i},'none')
            log(i).resp = single(str2double(logData{compS.r_resp}{i}));
          else
            log(i).resp = -1;
          end
          log(i).rt = single(str2double(logData{compS.r_rt}(i)));
          
          % get info from stimulus presentations
          log(i).family1Str = log(i-1).family1Str;
          log(i).family1Num = log(i-1).family1Num;
          log(i).species1Str = log(i-1).species1Str;
          log(i).species1Num = log(i-1).species1Num;
          log(i).exemplar1Num = log(i-1).exemplar1Num;
          log(i).trained1 = log(i-1).trained1;
          log(i).family2Str = log(i-1).family2Str;
          log(i).family2Num = log(i-1).family2Num;
          log(i).species2Str = log(i-1).species2Str;
          log(i).species2Num = log(i-1).species2Num;
          log(i).exemplar2Num = log(i-1).exemplar2Num;
          log(i).trained2 = log(i-1).trained2;
          
          % put info in stimulus presentations
          log(i-1).resp = log(i).resp;
          log(i-1).rt = log(i).rt;
      end
    end
    
    % only keep certain types of events
    log = log(ismember({log.type},{'COMP_BT_STIM', 'COMP_WI_STIM', 'COMP_BT_RESP', 'COMP_WI_RESP'}));
    
    % store the log struct in the events struct
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
    
    % mark the subject as complete
    if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
      events.isComplete = true;
    end
end

%fprintf('Done with %s %s (session_%d) %s (%d).\n',subject,sesName,sesNum,phaseName,phaseCount);
fprintf('Done.\n');

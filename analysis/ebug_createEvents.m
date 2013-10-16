function [events] = ebug_createEvents(events,cfg,expParam,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
% function [events] = ebug_createEvents(events,cfg,expParam,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
%
% create event struct for EBUG
%
% ebug_prepData_events runs ebug_createEvents, and then ebug_processData
% puts it all in a summary spreadsheet and ebug_visualizeData makes some
% plots

fprintf('Processing %s %s (session_%d) %s (%d)...',subject,sesName,sesNum,phaseName,phaseCount);

sesDir = sprintf('session_%d',sesNum);

commentStyle = '!!!';

% mark that this subject has not completed the experiment
if ~isfield(events,'isComplete')
  events.isComplete = false;
end

switch phaseName
  case {'match', 'prac_match'}
    
    %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_match_%d.txt',sesName,phaseName,phaseCount));
    
    formatStr = '%.6f%s%s%s%d%d%s%d%s%s%s%s%s%d%d%d';
    
    if exist(logFile,'file')
      
      matchS = struct;
      
      % common
      matchS.time = 1;
      matchS.subject = 2;
      matchS.session = 3;
      matchS.phase = 4;
      matchS.phaseCount = 5;
      matchS.isExp = 6;
      matchS.type = 7;
      matchS.trial = 8;
      
      % unique to {'MATCH_STIM1', 'MATCH_STIM2'}
      matchS.s_familyStr = 9;
      matchS.s_speciesStr = 10;
      matchS.s_exemplarNum = 11;
      matchS.s_isSubord = 12;
      matchS.s_familyNum = 13;
      matchS.s_speciesNum = 14;
      matchS.s_trained = 15;
      matchS.s_sameSpecies = 16;
      
      % unique to {'MATCH_RESP'}
      matchS.r_isSubord = 9;
      matchS.r_trained = 10;
      matchS.r_sameSpecies = 11;
      matchS.r_resp = 12;
      matchS.r_respKey = 13;
      matchS.r_acc = 14;
      matchS.r_rt = 15;
      
      %% read the real file
      fid = fopen(logFile,'r');
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
      'isExp',num2cell(logical(logData{matchS.isExp})), 'time',num2cell(logData{matchS.time}),...
      'type',logData{matchS.type}, 'trial',num2cell(single(logData{matchS.trial})),...
      'familyStr',[], 'familyNum',[], 'speciesStr',[], 'speciesNum',[], 'exemplarNum',[],...
      'isSubord',[], 'trained',[], 'sameSpecies',[],...
      'resp',[], 'acc',[], 'rt',[]);
    
    for i = 1:length(log)
      switch log(i).type
        case {'MATCH_STIM1', 'MATCH_STIM2'}
          log(i).familyStr = logData{matchS.s_familyStr}{i};
          log(i).speciesStr = logData{matchS.s_speciesStr}{i};
          log(i).exemplarNum = single(str2double(logData{matchS.s_exemplarNum}{i}));
          
%           % set the image condition
%           familyStrInd = strfind(log(i).familyStr,'_');
%           imgCond = strrep(log(i).familyStr,log(i).familyStr(1:familyStrInd(1)),'');
%           if isempty(imgCond)
%             imgCond = 'normal';
%           elseif strcmp(imgCond(end),'_')
%             % remove the trailing underscore
%             imgCond = imgCond(1:end-1);
%           end
%           log(i).imgCond = imgCond;
          
          log(i).isSubord = logical(str2double(logData{matchS.s_isSubord}{i}));
          log(i).familyNum = single(str2double(logData{matchS.s_familyNum}{i}));
          log(i).speciesNum = single(logData{matchS.s_speciesNum}(i));
          log(i).trained = logical(logData{matchS.s_trained}(i));
          log(i).sameSpecies = logical(logData{matchS.s_sameSpecies}(i));
          
        case {'MATCH_RESP'}
          log(i).isSubord = logical(str2double(logData{matchS.r_isSubord}{i}));
          log(i).trained = logical(str2double(logData{matchS.r_trained}{i}));
          log(i).sameSpecies = logical(str2double(logData{matchS.r_sameSpecies}{i}));
          
          % unique to MATCH_RESP
          log(i).resp = logData{matchS.r_resp}{i};
          log(i).acc = logical(logData{matchS.r_acc}(i));
          log(i).rt = single(logData{matchS.r_rt}(i));
          
          % get info from stimulus presentations
          log(i).familyStr = log(i-1).familyStr;
          log(i).speciesStr = log(i-1).speciesStr;
          log(i).exemplarNum = log(i-1).exemplarNum;
          %log(i).imgCond = log(i-1).imgCond;
          log(i).familyNum = log(i-1).familyNum;
          log(i).speciesNum = log(i-1).speciesNum;
          
          % put info in stimulus presentations
          log(i-1).resp = log(i).resp;
          log(i-1).acc = log(i).acc;
          log(i-1).rt = log(i).rt;
          log(i-2).resp = log(i).resp;
          log(i-2).acc = log(i).acc;
          log(i-2).rt = log(i).rt;
      end
    end
    
    % only keep certain types of events
    log = log(ismember({log.type},{'MATCH_STIM1','MATCH_STIM2','MATCH_RESP'}));
    
    % store the log struct in the events struct
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
    
    % if they've finished the last session, mark the subject as complete
    if strcmp(sesName,'posttest_delay') && strcmp(phaseName,'match')
      if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
        events.isComplete = true;
      end
    end
    
  case {'name', 'nametrain', 'prac_name'}
    
    if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
      nBlocks = 1;
    else
      nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
    end
    
    for b = 1:nBlocks
      %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
      logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_name_%d_b%d.txt',sesName,phaseName,phaseCount,b));
      
      formatStr = '%.6f%s%s%s%d%d%s%d%d%s%s%d%d%d%d%s%s%d%d';
      
      if exist(logFile,'file')
        nameS = struct;
        
        % common
        nameS.time = 1;
        nameS.subject = 2;
        nameS.session = 3;
        nameS.phase = 4;
        nameS.phaseCount = 5;
        nameS.isExp = 6;
        nameS.type = 7;
        nameS.block = 8;
        nameS.trial = 9;
        nameS.familyStr = 10;
        nameS.speciesStr = 11;
        nameS.exemplarNum = 12;
        nameS.isSubord = 13;
        nameS.speciesNum = 14;
        nameS.familyNum = 15;
        
        % none are unique to {'NAME_STIM'}
        
        % unique to {'NAME_RESP'}
        nameS.r_resp = 16;
        nameS.r_respKey = 17;
        nameS.r_acc = 18;
        nameS.r_rt = 19;
        
        %% read the real file
        fid = fopen(logFile,'r');
        logData = textscan(fid,formatStr, 'Delimiter','\t', 'emptyvalue',NaN, 'CommentStyle',commentStyle);
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
        'isExp',num2cell(logical(logData{nameS.isExp})), 'time',num2cell(logData{nameS.time}),...
        'type',logData{nameS.type}, 'block',num2cell(single(logData{nameS.block})), 'trial',num2cell(single(logData{nameS.trial})),...
        'familyStr',logData{nameS.familyStr}, 'familyNum',num2cell(single(logData{nameS.familyNum})),...
        'speciesStr',logData{nameS.speciesStr}, 'speciesNum',num2cell(single(logData{nameS.speciesNum})),...
        'exemplarNum',num2cell(single(logData{nameS.exemplarNum})),...
        'isSubord',num2cell(logical(logData{nameS.isSubord})),...
        'resp',[], 'acc',[], 'rt',[]);
      
      
      for i = 1:length(log)
        switch log(i).type
          % case {'NAME_STIM'}
          
          case {'NAME_RESP'}
%             % set the image condition
%             familyStrInd = strfind(log(i).familyStr,'_');
%             imgCond = strrep(log(i).familyStr,log(i).familyStr(1:familyStrInd(1)),'');
%             if isempty(imgCond)
%               imgCond = 'normal';
%             elseif strcmp(imgCond(end),'_')
%               % remove the trailing underscore
%               imgCond = imgCond(1:end-1);
%             end
%             log(i).imgCond = imgCond;
            
            % unique to MATCH_RESP
            if strcmp(logData{nameS.r_resp}(i),'none')
              log(i).resp = single(-1);
            elseif ~strcmp(logData{nameS.r_resp}(i),'none')
              log(i).resp = single(str2double(logData{nameS.r_resp}(i)));
            end
            log(i).acc = logical(logData{nameS.r_acc}(i));
            log(i).rt = single(logData{nameS.r_rt}(i));
            
            % put info in stimulus presentations
            log(i-1).resp = log(i).resp;
            log(i-1).acc = log(i).acc;
            log(i-1).rt = log(i).rt;
            %log(i-1).imgCond = log(i).imgCond;
        end
      end
      
      % only keep certain types of events
      log = log(ismember({log.type},{'NAME_STIM','NAME_RESP'}));
      
      % store the log struct in the events struct
      if b == 1
        events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
      else
        events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = cat(1,events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,log);
      end
      events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
      
    end % nBlocks
    
    
  case {'recog', 'prac_recog'}
    %keyboard
    
    %if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).allStims)
    %  nBlocks = 1;
    %else
    %  nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).allStims);
    %end
    
    %for b = 1:nBlocks
      %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
      %logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_recog_%d_b%d.txt',sesName,phaseName,phaseCount,b));
      logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_recog_%d.txt',sesName,phaseName,phaseCount));
      
      formatStr = '%.6f%s%s%s%d%d%s%d%d%s%s%d%d%d%d%s%s%d%d';
      
      if exist(logFile,'file')
        recogS = struct;
        
        % common
        recogS.time = 1;
        recogS.subject = 2;
        recogS.session = 3;
        recogS.phase = 4;
        recogS.phaseCount = 5;
        recogS.isExp = 6;
        recogS.type = 7;
        recogS.block = 8;
        recogS.trial = 9;
        recogS.familyStr = 10;
        recogS.speciesStr = 11;
        recogS.exemplarNum = 12;
        recogS.isSubord = 13;
        recogS.speciesNum = 14;
        recogS.targ = 15;
        
        % none are unique to {'NAME_STIM'}
        
        % unique to {'NAME_RESP'}
        recogS.r_resp = 16;
        recogS.r_respKey = 17;
        recogS.r_acc = 18;
        recogS.r_rt = 19;
        
        %% read the real file
        fid = fopen(logFile,'r');
        logData = textscan(fid,formatStr, 'Delimiter','\t', 'emptyvalue',NaN, 'CommentStyle',commentStyle);
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
        'isExp',num2cell(logical(logData{recogS.isExp})), 'time',num2cell(logData{recogS.time}),...
        'type',logData{recogS.type}, 'block',num2cell(single(logData{recogS.block})), 'trial',num2cell(single(logData{recogS.trial})),...
        'familyStr',logData{recogS.familyStr},...
        'speciesStr',logData{recogS.speciesStr}, 'speciesNum',num2cell(single(logData{recogS.speciesNum})),...
        'exemplarNum',num2cell(single(logData{recogS.exemplarNum})),...
        'isSubord',num2cell(logical(logData{recogS.isSubord})), 'targ',num2cell(logical(logData{recogS.targ})),...
        'resp',[], 'acc',[], 'rt',[]);
      
      
      for i = 1:length(log)
        switch log(i).type
          %case {'RECOGSTUDY_TARG'}
            
          %case {'RECOGTEST_STIM'}
            
          case {'RECOGTEST_RESP'}
            
            % unique to RECOGTEST_RESP
            log(i).resp = logData{recogS.r_resp}{i};
            log(i).acc = logical(logData{recogS.r_acc}(i));
            log(i).rt = single(logData{recogS.r_rt}(i));
            
            % find the corresponding RECOGTEST_RECOGSTIM
            thisRecogStim = strcmp({log.type},'RECOGTEST_STIM') & strcmp({log.familyStr},log(i).familyStr) & strcmp({log.speciesStr},log(i).speciesStr) & [log.speciesNum] == log(i).speciesNum & [log.exemplarNum] == log(i).exemplarNum;
            if sum(thisRecogStim) == 1
              % put info in stimulus presentations
              log(thisRecogStim).resp = log(i).resp;
              log(thisRecogStim).acc = log(i).acc;
              log(thisRecogStim).rt = log(i).rt;
            else
              keyboard
            end
            
            
            
            % put info in stimulus presentations
            %log(i-1).resp = log(i).resp;
            %log(i-1).acc = log(i).acc;
            %log(i-1).rt = log(i).rt;
            
        end
      end
      
      % only keep certain types of events
      log = log(ismember({log.type},{'RECOGSTUDY_TARG','RECOGTEST_STIM','RECOGTEST_RESP'}));
      
      % store the log struct in the events struct
      events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
      %       if b == 1
      %
      %       else
      %         events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = cat(1,events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data,log);
      %       end
      events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
      
    %end % nBlocks
    
    %         study_imgOn{b}(i),...
    %         expParam.subject,...
    %         sesName,...
    %         phaseName,...
    %         phaseCount,...
    %         phaseCfg.isExp,...
    %         'RECOGSTUDY_TARG',...
    %         b,...
    %         i,...
    %         targStims{b}(i).familyStr,...
    %         targStims{b}(i).speciesStr,...
    %         targStims{b}(i).exemplarName,...
    %         isSubord,...
    %         specNum,...
    %         targStims{b}(i).targ);
    
    %       test_imgOn{b}(i),...
    %       expParam.subject,...
    %       sesName,...
    %       phaseName,...
    %       phaseCount,...
    %       phaseCfg.isExp,...
    %       'RECOGTEST_STIM',...
    %       b,...
    %       i,...
    %       allStims{b}(i).familyStr,...
    %       allStims{b}(i).speciesStr,...
    %       allStims{b}(i).exemplarName,...
    %       isSubord,...
    %       specNum,...
    %       allStims{b}(i).targ);
    %
    %       respKeyImgOn{b}(i),...
    %       expParam.subject,...
    %       sesName,...
    %       phaseName,...
    %       phaseCount,...
    %       phaseCfg.isExp,...
    %       'RECOGTEST_RESPKEYIMG',...
    %       b,...
    %       i,...
    %       allStims{b}(i).familyStr,...
    %       allStims{b}(i).speciesStr,...
    %       allStims{b}(i).exemplarName,...
    %       isSubord,...
    %       specNum,...
    %       allStims{b}(i).targ);
    %
    %       endRT{b}(i),...
    %       expParam.subject,...
    %       sesName,...
    %       phaseName,...
    %       phaseCount,...
    %       phaseCfg.isExp,...
    %       'RECOGTEST_RESP',...
    %       b,...
    %       i,...
    %       allStims{b}(i).familyStr,...
    %       allStims{b}(i).speciesStr,...
    %       allStims{b}(i).exemplarName,...
    %       isSubord,...
    %       specNum,...
    %       allStims{b}(i).targ,...
    %       resp,...
    %       respKey,...
    %       acc,...
    %       rt);
    
end

%fprintf('Done with %s %s (session_%d) %s (%d).\n',subject,sesName,sesNum,phaseName,phaseCount);
fprintf('Done.\n');


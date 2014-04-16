function [events] = ebird_createEvents(events,cfg,expParam,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
% function [events] = ebird_createEvents(events,cfg,expParam,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
%
% create event struct for EBIRD
%
% ebird_prepData_events runs ebird_createEvents, and then ebird_processData
% puts it all in a summary spreadsheet and ebird_visualizeData makes some
% plots

fprintf('Processing %s %s (session_%d) %s (%d)...',subject,sesName,sesNum,phaseName,phaseCount);

sesDir = sprintf('session_%d',sesNum);

commentStyle = '!!!';
oldNewFormatMaxCheck = 10;

% the delay changed part-way through initial subject testing of EBIRD, so
% denote which subjects are which
subjectsWithMatchDelay = {'EBIRD049','EBIRD002','EBIRD003','EBIRD004','EBIRD005'};
matchDelay = 800;
subjectsWithNameDelay = {'EBIRD049','EBIRD002','EBIRD003'};
nameDelay = 1000;

% mark that this subject has not completed the experiment
if ~isfield(events,'isComplete')
  events.isComplete = false;
end

switch phaseName
  case {'match', 'prac_match'}
    
    %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_match_%d.txt',sesName,phaseName,phaseCount));
    
    % the log file format changed part-way through initial subject testing
    % of EBIRD, so figure out which log file format to use
    oldFormatStr = '%.6f%s%s%s%d%s%d%s%s%s%s%s%d%d%d';
    newFormatStr = '%.6f%s%s%s%d%d%s%d%s%s%s%s%s%d%d%d';
    formatStr = '';
    formatFlag = '';
    matchS = struct;
    
    if exist(logFile,'file')
      
      %% figure out the format string
      checkCounter = 1;
      fid = fopen(logFile,'r');
      while checkCounter < oldNewFormatMaxCheck
        tline = fgetl(fid);
        tline = regexp(tline,'\t','split');
        if length(tline) >= 6
          if ~isempty(strfind(tline{6},'PHASE'))
            formatFlag = 'old';
            break
          elseif ~isempty(strfind(tline{7},'PHASE'))
            formatFlag = 'new';
            break
          end
        end
        checkCounter = checkCounter + 1;
      end
      fclose(fid);
      % if we didn't find it (super old files), use the old format
      if isempty(formatFlag)
        formatFlag = 'old';
      end
      
      if strcmp(formatFlag,'old')
        formatStr = oldFormatStr;
        
        % common
        matchS.time = 1;
        matchS.subject = 2;
        matchS.session = 3;
        matchS.phase = 4;
        matchS.isExp = 5;
        matchS.type = 6;
        matchS.trial = 7;
        
        % unique to {'MATCH_STIM1', 'MATCH_STIM2'}
        matchS.s_familyStr = 8;
        matchS.s_speciesStr = 9;
        matchS.s_exemplarNum = 10;
        matchS.s_isSubord = 11;
        matchS.s_familyNum = 12;
        matchS.s_speciesNum = 13;
        matchS.s_trained = 14;
        matchS.s_sameSpecies = 15;
        
        % unique to {'MATCH_RESP'}
        matchS.r_isSubord = 8;
        matchS.r_trained = 9;
        matchS.r_sameSpecies = 10;
        matchS.r_resp = 11;
        matchS.r_respKey = 12;
        matchS.r_acc = 13;
        matchS.r_rt = 14;
      elseif strcmp(formatFlag,'new')
        formatStr = newFormatStr;
        
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
      end
      
      %% read the real file
      fid = fopen(logFile,'r');
      logData = textscan(fid,formatStr,'Delimiter','\t','emptyvalue',NaN, 'CommentStyle',commentStyle);
      fclose(fid);
      
      if isempty(logData{1})
        error('Log file seems to be empty, something is wrong: %s',logFile);
      end
    else
      fprintf('\n');
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
      'imgCond',[],...
      'isSubord',[], 'trained',[], 'sameTrained',[], 'sameSpecies',[],...
      'resp',[], 'acc',[], 'rt',[]);
    
    for i = 1:length(log)
      switch log(i).type
        case {'MATCH_STIM1', 'MATCH_STIM2'}
          log(i).familyStr = logData{matchS.s_familyStr}{i};
          log(i).speciesStr = logData{matchS.s_speciesStr}{i};
          log(i).exemplarNum = single(str2double(logData{matchS.s_exemplarNum}{i}));
          
          % set the image condition
          familyStrInd = strfind(log(i).familyStr,'_');
          imgCond = strrep(log(i).familyStr,log(i).familyStr(1:familyStrInd(1)),'');
          if isempty(imgCond)
            imgCond = 'normal';
          elseif strcmp(imgCond(end),'_')
            % remove the trailing underscore
            imgCond = imgCond(1:end-1);
          end
          log(i).imgCond = imgCond;
          
          log(i).isSubord = logical(str2double(logData{matchS.s_isSubord}{i}));
          log(i).familyNum = single(str2double(logData{matchS.s_familyNum}{i}));
          log(i).speciesNum = single(logData{matchS.s_speciesNum}(i));
          log(i).trained = logical(logData{matchS.s_trained}(i));
          log(i).sameSpecies = logical(logData{matchS.s_sameSpecies}(i));
          
          if strcmp(log(i).type, 'MATCH_STIM2')
            if log(i-1).trained == log(i).trained
              log(i-1).sameTrained = true;
              log(i).sameTrained = true;
            else
              log(i-1).sameTrained = false;
              log(i).sameTrained = false;
            end
          end
          
        case {'MATCH_RESP'}
          log(i).isSubord = logical(str2double(logData{matchS.r_isSubord}{i}));
          log(i).sameSpecies = logical(str2double(logData{matchS.r_sameSpecies}{i}));
          % trained for MATCH_RESP in log gets logged as the training
          % status of the second stimulus; this is not useful if the
          % training status is different. however, it doesn't matter
          % because this gets overwritten below when the training status of
          % both stimuli are combined into one vector
          log(i).trained = logical(str2double(logData{matchS.r_trained}{i}));
          
          % unique to MATCH_RESP
          log(i).resp = logData{matchS.r_resp}{i};
          log(i).acc = logical(logData{matchS.r_acc}(i));
          if ismember(subject,subjectsWithMatchDelay)
            log(i).rt = single(logData{matchS.r_rt}(i)) + matchDelay;
          else
            log(i).rt = single(logData{matchS.r_rt}(i));
          end
          
          % get info from stimulus presentations
          log(i).familyStr = log(i-1).familyStr;
          log(i).speciesStr = log(i-1).speciesStr;
          log(i).exemplarNum = log(i-1).exemplarNum;
          log(i).imgCond = log(i-1).imgCond;
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
    
    % hack: set up the proper training status based on normal images
    if strcmp(phaseName,'match')
      fprintf('\n\tSetting correct training status for manipulated images based on trained normal images...');
      normalStim = log(ismember({log.imgCond},'normal'));
      
      % remove training status from all non-normal stimuli
      % log(~ismember({log.imgCond},'normal')).trained = [];
      
      for i = 1:length(log)
        if ~strcmp(log(i).imgCond,'normal') && ismember({log(i).type},{'MATCH_STIM1', 'MATCH_STIM2'})
          %log(i).trained = [];
          
          thisFamily = strrep(log(i).familyStr,strcat(log(i).imgCond,'_'),'');
          
          %thisNormalStim = normalStim(ismember({normalStim.type},'MATCH_STIM1') & ismember({normalStim.familyStr},thisFamily) & ismember({normalStim.speciesStr},log(i).speciesStr) & [normalStim.exemplarNum] == log(i).exemplarNum);
          thisNormalStim = normalStim(ismember({normalStim.type},log(i).type) & ismember({normalStim.familyStr},thisFamily) & ismember({normalStim.speciesStr},log(i).speciesStr) & [normalStim.exemplarNum] == log(i).exemplarNum);
          
          if length(thisNormalStim) == 1
            log(i).trained = thisNormalStim.trained;
            
%             % debug
%             if log(i).isSubord ~= thisNormalStim.isSubord
%               keyboard
%             end
%             
%             if strcmp(log(i).type,'MATCH_STIM1')
%               otherType = 'MATCH_STIM2';
%             elseif strcmp(log(i).type,'MATCH_STIM2')
%               otherType = 'MATCH_STIM1';
%             end
%             otherStim = log(ismember({log.type},otherType) & [log.trial] == log(i).trial);
%             
%             if length(otherStim) == 1
%               if log(i).sameSpecies ~= otherStim.sameSpecies
%                 fprintf('Same species status is different\n');
%                 keyboard
%               end
%               if log(i).sameSpecies && ~strcmp(log(i).speciesStr, otherStim.speciesStr)
%                 fprintf('Same species but numbers are different\n');
%                 keyboard
%               elseif ~log(i).sameSpecies && strcmp(log(i).speciesStr, otherStim.speciesStr)
%                 fprintf('Not same species but numbers are the same\n');
%                 keyboard
%               end
%             else
%               keyboard
%             end
            
            % note whether the two stimuli had the same training status
            if strcmp(log(i).type,'MATCH_STIM2')
              if log(i-1).trained == log(i).trained
                log(i-1).sameTrained = true;
                log(i).sameTrained = true;
              else
                log(i-1).sameTrained = false;
                log(i).sameTrained = false;
              end
            end
          elseif isempty(thisNormalStim)
            keyboard % debug
            %thisNormalStim = normalStim(ismember({normalStim.type},'MATCH_STIM2') & ismember({normalStim.familyStr},thisFamily) & ismember({normalStim.speciesStr},log(i).speciesStr) & [normalStim.exemplarNum] == log(i).exemplarNum);
            %if length(thisNormalStim) == 1
            %  log(i).trained = thisNormalStim.trained;
            %elseif isempty(thisNormalStim)
            %  keyboard % debug
            %thisNormalStim = normalStim(ismember({normalStim.type},'MATCH_RESP') & ismember({normalStim.familyStr},thisFamily) & ismember({normalStim.speciesStr},log(i).speciesStr) & [normalStim.exemplarNum] == log(i).exemplarNum);
            %if length(thisNormalStim) == 1
            %  log(i).trained = thisNormalStim.trained;
            %elseif isempty(thisNormalStim)
            fprintf('\n\tCould not find a matching stim!\n');
            keyboard
            %end
            %end
          elseif length(thisNormalStim) > 1
            fprintf('\n\tFound multiple matching stims!\n');
            keyboard
          else
            keyboard
          end
          
        end
      end
      fprintf('Done.\n');
    else
      fprintf('\n');
    end
    
    % combine the training status for the two stimuli in the response event
    fprintf('\tCombining stimulus training status in response event...');
    for i = 1:length(log)
      switch log(i).type
        case {'MATCH_RESP'}
          log(i).trained = [log(i-2).trained log(i-1).trained];
          % note whether the two stimuli had the same training status
          if log(i-2).trained == log(i-1).trained
            log(i).sameTrained = true;
          else
            log(i).sameTrained = false;
          end
          
%           % debug: see if isSubord field is accurate
%           if log(i-2).isSubord ~= log(i-1).isSubord
%             keyboard
%           end
%           
%           % debug: see if sameSpecies field is accurate
%           if log(i-2).sameSpecies ~= log(i-1).sameSpecies
%             keyboard
%           end
      end
    end
    fprintf('Done.\n');
    
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
      
      oldFormatStr = '%.6f%s%s%s%d%s%d%d%s%s%d%d%d%d%s%s%d%d';
      newFormatStr = '%.6f%s%s%s%d%d%s%d%d%s%s%d%d%d%d%s%s%d%d';
      formatStr = '';
      formatFlag = '';
      nameS = struct;
      
      if exist(logFile,'file')
        %% figure out the format string
        checkCounter = 1;
        fid = fopen(logFile,'r');
        while checkCounter < oldNewFormatMaxCheck
          tline = fgetl(fid);
          tline = regexp(tline,'\t','split');
          if length(tline) >= 6
            if ~isempty(strfind(tline{6},'PHASE'))
              formatFlag = 'old';
              break
            elseif ~isempty(strfind(tline{7},'PHASE'))
              formatFlag = 'new';
              break
            end
          end
          checkCounter = checkCounter + 1;
        end
        fclose(fid);
        % if we didn't find it (super old files), use the old format
        if isempty(formatFlag)
          formatFlag = 'old';
        end
        
        if strcmp(formatFlag,'old')
          formatStr = oldFormatStr;
          
          % common
          nameS.time = 1;
          nameS.subject = 2;
          nameS.session = 3;
          nameS.phase = 4;
          nameS.isExp = 5;
          nameS.type = 6;
          nameS.block = 7;
          nameS.trial = 8;
          nameS.familyStr = 9;
          nameS.speciesStr = 10;
          nameS.exemplarNum = 11;
          nameS.isSubord = 12;
          nameS.speciesNum = 13;
          nameS.familyNum = 14;
          
          % none are unique to {'NAME_STIM'}
          
          % unique to {'NAME_RESP'}
          nameS.r_resp = 15;
          nameS.r_respKey = 16;
          nameS.r_acc = 17;
          nameS.r_rt = 18;
        elseif strcmp(formatFlag,'new')
          formatStr = newFormatStr;
          
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
        end
        
        %% read the real file
        fid = fopen(logFile,'r');
        logData = textscan(fid,formatStr, 'Delimiter','\t', 'emptyvalue',NaN, 'CommentStyle',commentStyle);
        fclose(fid);
        
        if isempty(logData{1})
          error('Log file seems to be empty, something is wrong: %s',logFile);
        end
      else
        fprintf('\n');
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
        'imgCond',[],...
        'isSubord',num2cell(logical(logData{nameS.isSubord})),...
        'resp',[], 'acc',[], 'rt',[]);
      
      
      for i = 1:length(log)
        switch log(i).type
          % case {'NAME_STIM'}
          
          case {'NAME_RESP'}
            % set the image condition
            familyStrInd = strfind(log(i).familyStr,'_');
            imgCond = strrep(log(i).familyStr,log(i).familyStr(1:familyStrInd(1)),'');
            if isempty(imgCond)
              imgCond = 'normal';
            elseif strcmp(imgCond(end),'_')
              % remove the trailing underscore
              imgCond = imgCond(1:end-1);
            end
            log(i).imgCond = imgCond;
            
            % unique to MATCH_RESP
            if strcmp(logData{nameS.r_resp}(i),'none')
              log(i).resp = single(-1);
            elseif ~strcmp(logData{nameS.r_resp}(i),'none')
              log(i).resp = single(str2double(logData{nameS.r_resp}(i)));
            end
            log(i).acc = logical(logData{nameS.r_acc}(i));
            if ismember(subject,subjectsWithNameDelay)
              log(i).rt = single(logData{nameS.r_rt}(i)) + nameDelay;
            else
              log(i).rt = single(logData{nameS.r_rt}(i));
            end
            
            % put info in stimulus presentations
            log(i-1).resp = log(i).resp;
            log(i-1).acc = log(i).acc;
            log(i-1).rt = log(i).rt;
            log(i-1).imgCond = log(i).imgCond;
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
    keyboard
    
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
    
    
  case {'viewname'}
    keyboard
    % blockSpeciesOrder
end

%fprintf('Done with %s %s (session_%d) %s (%d).\n',subject,sesName,sesNum,phaseName,phaseCount);
fprintf('Done.\n');


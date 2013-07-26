function [events] = ebird_createEvents(events,cfg,expParam,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
% function [events] = ebird_createEvents(events,cfg,expParam,dataroot,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
%
% create event struct for EBIRD
%

% expertTrain - EBIRD

fprintf('Processing %s %s (session_%d) %s (%d)...\n',subject,sesName,sesNum-1,phaseName,phaseCount);

sesDir = sprintf('session_%d',sesNum);

switch phaseName
  case {'match', 'prac_match'}
    
    %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_match_%d.txt',sesName,phaseName,phaseCount));

    if exist(logFile,'file')
      fid = fopen(logFile);
      logData = textscan(fid,'%.6f%s%s%s%d%s%d%s%s%s%s%s%d%d%d','Delimiter','\t','emptyvalue',NaN, 'CommentStyle','!!!');
      fclose(fid);
    else
      %error('Log file file not found: %s',logFile);
      warning('Log file file not found: %s',logFile);
      return
    end
    
    % set all fields here so we can easily concatenate events later
    log = struct('subject',subject,'session',sesNum,'sesName',sesName,...
      'phaseName',phaseName,'phaseCount',phaseCount,...
      'isExp',num2cell(logical(logData{5})), 'time',num2cell(logData{1}),...
      'type',logData{6}, 'trial',num2cell(single(logData{7})),...
      'familyStr',[], 'familyNum',[], 'speciesStr',[], 'speciesNum',[], 'exemplarNum',[],...
      'imgCond',[],...
      'isSubord',[], 'trained',[], 'sameSpecies',[],...
      'resp',[], 'acc',[], 'rt',[]);
    
    for i = 1:length(log)
      switch log(i).type
        case {'MATCH_STIM1', 'MATCH_STIM2'}
          log(i).familyStr = logData{8}{i};
          log(i).speciesStr = logData{9}{i};
          log(i).exemplarNum = single(str2double(logData{10}{i}));
          
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
          
          log(i).isSubord = logical(str2double(logData{11}{i}));
          log(i).familyNum = single(str2double(logData{12}{i}));
          log(i).speciesNum = single(logData{13}(i));
          log(i).trained = logical(logData{14}(i));
          log(i).sameSpecies = logical(logData{15}(i));
          
        case {'MATCH_RESP'}
          log(i).isSubord = logical(str2double(logData{8}{i}));
          log(i).trained = logical(str2double(logData{9}{i}));
          log(i).sameSpecies = logical(str2double(logData{10}{i}));
          
          % unique to MATCH_RESP
          log(i).resp = logData{11}{i};
          log(i).acc = logical(logData{13}(i));
          log(i).rt = single(logData{14}(i));
          
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
    
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)) = log;
    
  case {'name', 'nametrain', 'prac_name'}
    
    if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
      nBlocks = 1;
    else
      nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
    end
    
    for b = 1:nBlocks
      %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
      logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_name_%d_b%d.txt',sesName,phaseName,phaseCount,b));
      
      if exist(logFile,'file')
        fid = fopen(logFile);
        logData = textscan(fid,'%.6f%s%s%s%d%s%d%d%s%s%d%d%d%d%s%s%d%d', 'Delimiter','\t', 'emptyvalue',NaN, 'CommentStyle','!!!');
        fclose(fid);
      else
        %error('Log file file not found: %s',logFile);
        warning('Log file file not found: %s',logFile);
        return
      end
      
      % set all fields here so we can easily concatenate events later
      log = struct('subject',subject,'session',sesNum,'sesName',sesName,...
        'phaseName',phaseName,'phaseCount',phaseCount,...
        'isExp',num2cell(logical(logData{5})), 'time',num2cell(logData{1}),...
        'type',logData{6}, 'block',num2cell(single(logData{7})), 'trial',num2cell(single(logData{8})),...
        'familyStr',logData{9}, 'familyNum',num2cell(single(logData{14})), 'speciesStr',logData{10}, 'speciesNum',num2cell(single(logData{13})), 'exemplarNum',num2cell(single(logData{11})),...
        'imgCond',[],...
        'isSubord',num2cell(logical(logData{12})),...
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
            if strcmp(logData{15}(i),'none')
              log(i).resp = single(-1);
            elseif ~strcmp(logData{15}(i),'none')
              log(i).resp = single(str2double(logData{15}(i)));
            end
            log(i).acc = logical(logData{17}(i));
            log(i).rt = single(logData{18}(i));
            
            % put info in stimulus presentations
            log(i-1).resp = log(i).resp;
            log(i-1).acc = log(i).acc;
            log(i-1).rt = log(i).rt;
            log(i-1).imgCond = log(i).imgCond;
        end
      end
      
      % store the log struct in the events struct
      if b == 1
        events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)) = log;
      else
        events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)) = cat(1,events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)),log);
      end
      
    end % nBlocks
    
    
  case {'recog', 'prac_recog'}
    
%         study_imgOn{b}(i),...
%         expParam.subject,...
%         sesName,...
%         phaseName,...
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
    % blockSpeciesOrder
end

fprintf('Done with %s %s (session_%d) %s (%d).\n',subject,sesName,sesNum-1,phaseName,phaseCount);


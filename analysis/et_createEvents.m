function [events] = et_createEvents(events,cfg,expParam,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
% function [events] = et_createEvents(events,cfg,expParam,dataroot,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
%
% e.g., [events] = et_createEvents('/Volumes/curranlab/Data/EBIRD/Behavioral/Sessions/','EBIRD002',{'session_0','session_1'});
%
% create event struct for EBIRD
%

%% also old

% struct fields:
%   subject
%   session
%   mstime
%   msoffset
%   list (#)
%   condition (study, restudy, quiz, recogrecall, retention)
%   trial (#)
%   type
%   train_type (restudy or quiz)
%   item_swa
%   xcoord_swa
%   ycoord_swa
%   item_eng
%   xcoord_eng
%   ycoord_eng
%   serialpos (initial study SP)
%   rec_isTarg (1 or 0)
%   rec_correct (1 or 0)
%   rec_resp
%   rec_resp_rt
%   new_correct
%   new_resp (sure, maybe, -1)
%   new_resp_rt (sure, maybe, -1)
%   quiz_recall (1 or 0)
%   rec_recall (1 or 0)
%   ret_recall (1 or 0)
%   quiz_recall_resp
%   rec_recall_resp
%   ret_recall_resp
%
% [events_ses0, events_ses1] = et_createEvents('/Volumes/curranlab/Data/EBIRD/Behavioral/Sessions/','EBIRD002',{'session_0','session_1'});
%

%% old

% event struct recall notation:
%
% for quiz recall, -1 indicates that there was no word recalled; the
% corresponding 'resp' field should be blank (''). 0 indicates that they
% recalled the wrong word, inclduing vocalizations ('<>'). 1 indicates that
% they recalled the correct word.
%
% for recognition recall, -1 indicates that they did not have a chance to
% recall (they incorrectly called the old word "new"), and the resp field
% gets set to blank (''). 0 indicates that they recalled the wrong word
% (including vocalizations). 1 indicates that they recalled the correct
% word.
%
% retention recall should be the same as quiz recall.

% TODO: be able to process only the first session; e.g., for making sure
% the subject is doing a decent job as recalling during quiz and
% recognition

% % debug
% % dataroot = '/Volumes/curranlab/Data/TERP/beh/';
% dataroot = '~/data/TERP/beh/';
% subject = 'TERP001';
% % subject = 'TERP002';
% sessions = {'session_0','session_1'};
% nargout =2;

% %% error checking
% 
% if nargout ~= 2
%   error('%s currently only supports processing both session_0 and session_1. Therefore, output must be something like [events_ses0, events_ses1].',mfilename);
% end
% 
% if ~iscell(sessions)
%   error('input variable ''sessions'' must be a cell, specifically {''session_0'',''session_1''}.');
% end
% 
% if length(sessions) ~= 2
%   error('%s currently only supports processing both session_0 and session_1. Therefore, input variable ''sessions'' must be {''session_0'',''session_1''}.',mfilename);
% end


%% expertTrain

fprintf('Processing %s %s (session_%d) %s (%d)...\n',subject,sesName,sesNum-1,phaseName,phaseCount);

sesDir = sprintf('session_%d',sesNum);

switch phaseName
  case {'match', 'prac_match'}
    
    %logFile = fullfile(dataroot,subject,sesDir,'session.txt');
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_match_%d.txt',sesName,phaseName,phaseCount));

    if exist(logFile,'file')
      fid = fopen(logFile);
      logData = textscan(fid,'%.6f%s%s%s%d%s%d%s%s%s%s%s%s%s%s','Delimiter','\t','emptyvalue',NaN, 'CommentStyle','%%%');
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
      'isSubord',[], 'trained',[], 'sameSpecies',[],...
      'resp',[], 'acc',[], 'rt',[]);
    
    for i = 1:length(log)
      switch log(i).type
        case {'MATCH_STIM1', 'MATCH_STIM2'}
          log(i).familyStr = logData{8}{i};
          log(i).speciesStr = logData{9}{i};
          log(i).exemplarNum = single(str2double(logData{10}{i}));
          
          log(i).isSubord = logical(str2double(logData{11}{i}));
          log(i).familyNum = single(str2double(logData{12}{i}));
          log(i).speciesNum = single(str2double(logData{13}{i}));
          log(i).trained = logical(str2double(logData{14}{i}));
          log(i).sameSpecies = logical(str2double(logData{15}{i}));
          
        case {'MATCH_RESP'}
          log(i).isSubord = logical(str2double(logData{8}{i}));
          log(i).trained = logical(str2double(logData{9}{i}));
          log(i).sameSpecies = logical(str2double(logData{10}{i}));
          
          % unique to MATCH_RESP
          log(i).resp = logData{11}{i};
          log(i).acc = logical(str2double(logData{13}{i}));
          log(i).rt = single(str2double(logData{14}{i}));
          
          % get info from stimulus presentations
          log(i).familyStr = log(i-1).familyStr;
          log(i).speciesStr = log(i-1).speciesStr;
          log(i).exemplarNum = log(i-1).exemplarNum;
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
        logData = textscan(fid,'%.6f%s%s%s%d%s%d%d%s%s%d%d%d%d%s%s%d%d', 'Delimiter','\t', 'emptyvalue',NaN, 'CommentStyle','%%%');
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
        'isSubord',num2cell(logical(logData{12})),...
        'resp',[], 'acc',[], 'rt',[]);
      
      
      for i = 1:length(log)
        switch log(i).type
          % case {'NAME_STIM'}
          
          case {'NAME_RESP'}
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


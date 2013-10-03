function [events] = space_createEvents(events,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
% function [events] = space_createEvents(events,dataroot,subject,sesNum,sesName,phaseName,phaseCount)
%
% create event struct for SPACE
%
% NB: space_prepData_events runs space_createEvents
%
% if you want you could maybe create a space_processData script to put it
% all in a summary spreadsheet and space_visualizeData to make some plots

fprintf('Processing %s %s (session_%d) %s (%d)...',subject,sesName,sesNum,phaseName,phaseCount);

sesDir = sprintf('session_%d',sesNum);

commentStyle = '!!!';

% mark that this subject has not spaceleted the experiment
if ~isfield(events,'isComplete')
  events.isComplete = false;
end

switch phaseName
  case {'expo'}
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_expo_%d.txt',sesName,phaseName,phaseCount));
    
    formatStr = '%.6f%s%s%s%d%d%s%d%s%s%s%s%s%s%s%s%s%s';
    if exist(logFile,'file')
      
      % set up column numbers denoting kinds of data in the log file
      expoS = struct;
      
      % common
      expoS.time = 1;
      expoS.subject = 2;
      expoS.session = 3;
      expoS.phase = 4;
      expoS.phaseCount = 5;
      expoS.isExp = 6;
      expoS.type = 7;
      expoS.trial = 8;
      
      % unique to {'EXPO_IMAGE'}
      expoS.s_stimStr = 9;
      expoS.s_stimNum = 10;
      expoS.s_targ = 11;
      expoS.s_spaced = 12;
      expoS.s_lag = 13;
      expoS.s_presNum = 14;
      expoS.s_pairNum = 15;
      expoS.s_pairOrd = 16;
      expoS.s_catStr = 17;
      expoS.s_catNum = 18;
      
      % unique to {'EXPO_RESP'}
      expoS.r_resp = 9;
      expoS.r_respKey = 10;
      expoS.r_rt = 11;
      
      % read the real file
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
      'isExp',num2cell(logical(logData{expoS.isExp})), 'time',num2cell(logData{expoS.time}),...
      'type',logData{expoS.type}, 'trial',num2cell(single(logData{expoS.trial})),...
      'stimStr',[], 'stimNum',[], 'targ',[],...
      'spaced',[], 'lag',[],...
      'presNum',[], 'pairNum',[], 'pairOrd',[],...
      'catStr',[], 'catNum',[],...
      'resp',[], 'rt',[]);
    
    for i = 1:length(log)
      switch log(i).type
        case {'EXPO_IMAGE'}
          % unique to EXPO_IMAGE
          log(i).stimStr = logData{expoS.s_stimStr}{i};
          log(i).stimNum = str2double(logData{expoS.s_stimNum}{i});
          log(i).targ = logical(str2double(logData{expoS.s_targ}{i}));
          log(i).spaced = logical(str2double(logData{expoS.s_spaced}{i}));
          log(i).lag = str2double(logData{expoS.s_lag}{i});
          log(i).presNum = str2double(logData{expoS.s_presNum}{i});
          log(i).pairNum = str2double(logData{expoS.s_pairNum}{i});
          log(i).pairOrd = str2double(logData{expoS.s_pairOrd}{i});
          log(i).i_catStr = logData{expoS.s_catStr}{i};
          log(i).i_catNum = str2double(logData{expoS.s_catNum}{i});
          
        case {'EXPO_RESP'}
          % unique to EXPO_RESP
          %if ~strcmp(logData{expoS.r_resp}{i},'none')
          if strcmp(logData{expoS.r_resp}{i},'v_appeal')
            log(i).resp = 4;
          elseif strcmp(logData{expoS.r_resp}{i},'s_appeal')
            log(i).resp = 3;
          elseif strcmp(logData{expoS.r_resp}{i},'s_unappeal')
            log(i).resp = 2;
          elseif strcmp(logData{expoS.r_resp}{i},'v_unappeal')
            log(i).resp = 1;
          elseif strcmp(logData{expoS.r_resp}{i},'none')
            log(i).resp = -1;
          end
          log(i).rt = single(str2double(logData{expoS.r_rt}(i)));
          
          % get info from stimulus presentations
          log(i).stimStr = log(i-1).stimStr;
          log(i).stimNum = log(i-1).stimNum;
          log(i).targ = log(i-1).targ;
          log(i).spaced = log(i-1).spaced;
          log(i).lag = log(i-1).lag;
          log(i).presNum = log(i-1).presNum;
          log(i).pairNum = log(i-1).pairNum;
          log(i).pairOrd = log(i-1).pairOrd;
          log(i).i_catStr = log(i-1).i_catStr;
          log(i).i_catNum = log(i-1).i_catNum;
          
          % put info in stimulus presentations
          log(i-1).resp = log(i).resp;
          log(i-1).rt = log(i).rt;
      end
    end
    
    % only keep certain types of events
    log = log(ismember({log.type},{'EXPO_IMAGE', 'EXPO_RESP'}));
    
    % store the log struct in the events struct
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
    
    % mark the subject as spacelete
    if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
      events.isComplete = true;
    end
    
  case {'multistudy'}
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_multistudy_%d.txt',sesName,phaseName,phaseCount));
    
    formatStr = '%.6f%s%s%s%d%d%s%d%s%d%d%d%d%d%d%d%s%d';
    if exist(logFile,'file')
      
      % set up column numbers denoting kinds of data in the log file
      msS = struct;
      
      % common
      msS.time = 1;
      msS.subject = 2;
      msS.session = 3;
      msS.phase = 4;
      msS.phaseCount = 5;
      msS.isExp = 6;
      msS.type = 7;
      msS.trial = 8;
      msS.stimStr = 9;
      msS.stimNum = 10;
      msS.targ = 11;
      msS.spaced = 12;
      msS.lag = 13;
      msS.presNum = 14;
      msS.pairNum = 15;
      msS.pairOrd = 16;
      msS.i_catStr = 17;
      msS.i_catNum = 18;
      
      % read the real file
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
      'isExp',num2cell(logical(logData{msS.isExp})), 'time',num2cell(logData{msS.time}),...
      'type',logData{msS.type}, 'trial',num2cell(single(logData{msS.trial})),...
      'stimStr',logData{msS.stimStr}, 'stimNum',num2cell(single(logData{msS.stimNum})), 'targ',num2cell(logical(logData{msS.targ})),...
      'spaced',num2cell(logical(logData{msS.spaced})), 'lag',num2cell(single(logData{msS.lag})),...
      'presNum',num2cell(single(logData{msS.presNum})), 'pairNum',num2cell(single(logData{msS.pairNum})), 'pairOrd',num2cell(single(logData{msS.pairOrd})),...
      'catStr',logData{msS.i_catStr}, 'catNum',num2cell(single(logData{msS.i_catNum})));
    
    % only keep certain types of events
    log = log(ismember({log.type},{'STUDY_IMAGE', 'STUDY_WORD'}));
    
    % put them in the order of occurrence
    [~, timeInd] = sort([log.time]);
    log = log(timeInd);
    
    % store the log struct in the events struct
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
    
    % mark the subject as spacelete
    if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
      events.isComplete = true;
    end
    
  case {'distract_math'}
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_distMath_%d.txt',sesName,phaseName,phaseCount));
    
    % this format string should work for view, stim, and resp trials
    formatStr = '%.6f%s%s%s%d%d%s%d%s%s%s';
    if exist(logFile,'file')
      
      % set up column numbers denoting kinds of data in the log file
      mathS = struct;
      
      % common
      mathS.time = 1;
      mathS.subject = 2;
      mathS.session = 3;
      mathS.phase = 4;
      mathS.phaseCount = 5;
      mathS.isExp = 6;
      mathS.type = 7;
      mathS.trial = 8;
      
      % unique to {'MATH_PROB'}
      mathS.s_prob = 9;
      
      % unique to {'MATH_RESP'}
      mathS.r_resp = 9;
      mathS.r_acc = 10;
      mathS.r_rt = 11;
      
      % read the real file
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
      'isExp',num2cell(logical(logData{mathS.isExp})), 'time',num2cell(logData{mathS.time}),...
      'type',logData{mathS.type}, 'trial',num2cell(single(logData{mathS.trial})),...
      'prob',[], 'resp',[],...
      'acc',[], 'rt',[]);
    
    for i = 1:length(log)
      switch log(i).type
        case {'MATH_PROB'}
          % unique to MATH_PROB
          log(i).prob = logData{mathS.s_prob}{i};
          
        case {'MATH_RESP'}
          % unique to MATH_RESP
          log(i).resp = single(str2double(logData{mathS.r_resp}(i)));
          log(i).acc = logical(str2double(logData{mathS.r_acc}(i)));
          log(i).rt = single(str2double(logData{mathS.r_rt}(i)));
          
          % get info from problem presentations
          log(i).prob = log(i-1).prob;
          
          % put info in problem presentations
          log(i-1).resp = log(i).resp;
          log(i-1).acc = log(i).acc;
          log(i-1).rt = log(i).rt;
      end
    end
    
    % only keep certain types of events
    log = log(ismember({log.type},{'MATH_PROB', 'MATH_RESP'}));
    
    % store the log struct in the events struct
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
    
    % mark the subject as spacelete
    if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
      events.isComplete = true;
    end
    
  case {'cued_recall'}
    % whether to interactively check the spelling of cued recall trials
    checkSpelling = true;
    
    logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_cr_%d.txt',sesName,phaseName,phaseCount));
    
    formatStr = '%.6f%s%s%s%d%d%s%d%s%d%d%d%d%d%s%d%s%s%d%d';
    if exist(logFile,'file')
      
      % set up column numbers denoting kinds of data in the log file
      crS = struct;
      
      % common
      crS.time = 1;
      crS.subject = 2;
      crS.session = 3;
      crS.phase = 4;
      crS.phaseCount = 5;
      crS.isExp = 6;
      crS.type = 7;
      crS.trial = 8;
      crS.stimStr = 9;
      crS.stimNum = 10;
      crS.targ = 11;
      crS.spaced = 12;
      crS.lag = 13;
      crS.pairNum = 14;
      crS.i_catStr = 15;
      crS.i_catNum = 16;
      
      % unique to {'RECOGTEST_RECOGRESP'}
      crS.recog_resp = 17;
      crS.recog_respKey = 18;
      crS.recog_acc = 19;
      crS.recog_rt = 20;
      
      % unique to {'RECOGTEST_NEWRESP'}
      crS.new_resp = 17;
      crS.new_respKey = 18;
      crS.new_acc = 19;
      crS.new_rt = 20;
      
      % unique to {'RECOGTEST_RECALLRESP'}
      crS.recall_resp = 17;
      crS.recall_origword = 18;
      crS.recall_corrSpell = 19;
      crS.recall_rt = 20;
      
      % read the real file
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
    
    % Subjects 1-7 had lures (targ=0) marked as spaced=-1. needs to be
    % false instead because logical(-1)=1.
    if str2double(subject(end-2:end)) <= 7
      logData{crS.spaced}([logData{crS.targ}] == 0 & logData{crS.trial} ~= 0) = false;
      % % another method
      % logData{crS.spaced}([logData{crS.spaced}] == -1) = false;
    end
    
    % set all fields here so we can easily concatenate events later
    log = struct('subject',subject,'session',sesNum,'sesName',sesName,...
      'phaseName',phaseName,'phaseCount',phaseCount,...
      'isExp',num2cell(logical(logData{crS.isExp})), 'time',num2cell(logData{crS.time}),...
      'type',logData{crS.type}, 'trial',num2cell(single(logData{crS.trial})),...
      'stimStr',logData{crS.stimStr}, 'stimNum',num2cell(single(logData{crS.stimNum})), 'targ',num2cell(logical(logData{crS.targ})),...
      'spaced',num2cell(logical(logData{crS.spaced})), 'lag',num2cell(single(logData{crS.lag})),...
      'pairNum',num2cell(single(logData{crS.pairNum})), 'catStr',logData{crS.i_catStr}, 'catNum',num2cell(single(logData{crS.i_catNum})),...
      'recog_resp',[], 'recog_acc',[], 'recog_rt',[],...
      'new_resp',[], 'new_acc',[], 'new_rt',[],...
      'recall_origword',[], 'recall_resp',[], 'recall_spellCorr',[], 'recall_rt',[]);
    
    for i = 1:length(log)
      propagateNewRecall = false;
      
      switch log(i).type
        case {'RECOGTEST_RECOGRESP'}
          % unique to RECOGTEST_RECOGRESP
          log(i).recog_resp = logData{crS.recog_resp}{i};
          log(i).recog_acc = logical(logData{crS.recog_acc}(i));
          log(i).recog_rt = single(logData{crS.recog_rt}(i));
          
          % find the corresponding RECOGTEST_RECOGSTIM
          thisRecogStim = strcmp({log.type},'RECOGTEST_STIM') & [log.stimNum] == log(i).stimNum & [log.catNum] == log(i).catNum;
          if sum(thisRecogStim) == 1
            % put info in stimulus presentations
            log(thisRecogStim).recog_resp = log(i).recog_resp;
            log(thisRecogStim).recog_acc = log(i).recog_acc;
            log(thisRecogStim).recog_rt = log(i).recog_rt;
          else
            keyboard
          end
          
        case {'RECOGTEST_NEWRESP'}
          % unique to RECOGTEST_NEWRESP
          log(i).new_resp = logData{crS.new_resp}{i};
          log(i).new_acc = logical(logData{crS.new_acc}(i));
          log(i).new_rt = single(logData{crS.new_rt}(i));
          
          % didn't make a recall response
          log(i).recall_resp = '';
          log(i).recall_origword = '';
          log(i).recall_spellCorr = false;
          log(i).recall_rt = -1;
          
          propagateNewRecall = true;
          
        case {'RECOGTEST_RECALLRESP'}
          % unique to RECOGTEST_RECALLRESP
          log(i).recall_resp = logData{crS.recall_resp}{i};
          log(i).recall_origword = logData{crS.recall_origword}{i};
          if isempty(log(i).recall_resp)
            log(i).recall_spellCorr = false;
            % debug
            %fprintf('\nRecall for %s (%d) trial %d of %d:\n',phaseName,phaseCount,log(i).trial,max([log.trial]));
            %fprintf('\tNo recall response!!\n')
          else
            if checkSpelling
              % if we want to check the spelling on their recall responses
              if strcmpi(log(i).recall_resp,log(i).recall_origword)
                % auto spell check
                log(i).recall_spellCorr = true;
              else
                % manual spell check
                fprintf('\nRecall for %s (%d) trial %d of %d:\n',phaseName,phaseCount,log(i).trial,max([log.trial]));
                fprintf('\tOriginal word:  %s\n',log(i).recall_origword);
                fprintf('\tTheir response: %s\n',log(i).recall_resp);
                
                while 1
                  decision = input('                Correct or incorrect? (1 or 0?). ');
                  if ~isempty(decision) && isnumeric(decision) && (decision == 1 || decision == 0)
                    if decision
                      fprintf('\t\tMarked correct!\n');
                    else
                      fprintf('\t\tMarked incorrect!\n');
                    end
                    break
                  end
                end
                log(i).recall_spellCorr = logical(decision);
              end
            else
              % if we don't want to check their spelling
              log(i).recall_spellCorr = logical(logData{crS.recall_corrSpell}(i));
            end
          end
          log(i).recall_rt = single(logData{crS.recall_rt}(i));
          
          % didn't make a new response
          log(i).new_resp = '';
          log(i).new_acc = false;
          log(i).new_rt = -1;
          
          propagateNewRecall = true;
      end % switch
      
      if propagateNewRecall
        % find the corresponding RECOGTEST_RECOGSTIM
        thisRecogStim = strcmp({log.type},'RECOGTEST_STIM') & [log.stimNum] == log(i).stimNum & [log.catNum] == log(i).catNum;
        if sum(thisRecogStim) == 1
          % put info in stimulus presentations
          log(thisRecogStim).new_resp = log(i).new_resp;
          log(thisRecogStim).new_acc = log(i).new_acc;
          log(thisRecogStim).new_rt = log(i).new_rt;
          
          log(thisRecogStim).recall_resp = log(i).recall_resp;
          log(thisRecogStim).recall_origword = log(i).recall_origword;
          log(thisRecogStim).recall_spellCorr = log(i).recall_spellCorr;
          log(thisRecogStim).recall_rt = log(i).recall_rt;
        else
          keyboard
        end
        
        % find the corresponding RECOGTEST_RECOGRESP
        thisRecogResp = strcmp({log.type},'RECOGTEST_RECOGRESP') & [log.stimNum] == log(i).stimNum & [log.catNum] == log(i).catNum;
        if sum(thisRecogResp) == 1
          % put info in the recognition response
          log(thisRecogResp).new_resp = log(i).new_resp;
          log(thisRecogResp).new_acc = log(i).new_acc;
          log(thisRecogResp).new_rt = log(i).new_rt;
          
          log(thisRecogResp).recall_resp = log(i).recall_resp;
          log(thisRecogResp).recall_origword = log(i).recall_origword;
          log(thisRecogResp).recall_spellCorr = log(i).recall_spellCorr;
          log(thisRecogResp).recall_rt = log(i).recall_rt;
          
          % get info from the recognition response
          log(i).recog_resp = log(thisRecogResp).recog_resp;
          log(i).recog_acc = log(thisRecogResp).recog_acc;
          log(i).recog_rt = log(thisRecogResp).recog_rt;
        else
          keyboard
        end
      end
      
    end % for
    
    % only keep certain types of events
    log = log(ismember({log.type},{'RECOGTEST_STIM', 'RECOGTEST_RECOGRESP','RECOGTEST_NEWRESP','RECOGTEST_RECALLRESP'}));
    
    % store the log struct in the events struct
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
    
    % mark the subject as spacelete
    if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
      events.isComplete = true;
    end
    
end

%fprintf('Done with %s %s (session_%d) %s (%d).\n',subject,sesName,sesNum,phaseName,phaseCount);
fprintf('Done.\n');

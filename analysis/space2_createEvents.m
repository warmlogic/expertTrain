function [events,sessionCRList] = space2_createEvents(events,dataroot,subject,sesNum,sesName,phaseName,phaseCount,sessionCRList)
% function [events,sessionCRList] = space2_createEvents(events,dataroot,subject,sesNum,sesName,phaseName,phaseCount,sessionCRList)
%
% create event struct for SPACE
%
% NB: space_prepData_events runs space_createEvents
%
% if you want you could maybe create a space_processData script to put it
% all in a summary spreadsheet and space_visualizeData to make some plots

fprintf('Processing %s %s (session_%d) %s (%d)...\n',subject,sesName,sesNum,phaseName,phaseCount);

sesDir = sprintf('session_%d',sesNum);

commentStyle = '!!!';

% mark that this subject has not spaceleted the experiment
if ~isfield(events,'isComplete')
  events.isComplete = false;
end

isPilotData = false;

switch phaseName
  case {'multistudy', 'prac_multistudy'}
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
      msS.catStr = 17;
      msS.catNum = 18;
      
      % read the real file
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
      'isExp',num2cell(logical(logData{msS.isExp})), 'time',num2cell(logData{msS.time}),...
      'type',logData{msS.type}, 'trial',num2cell(single(logData{msS.trial})),...
      'stimStr',logData{msS.stimStr}, 'stimNum',num2cell(single(logData{msS.stimNum})), 'targ',num2cell(logical(logData{msS.targ})),...
      'spaced',num2cell(logical(logData{msS.spaced})), 'lag',num2cell(single(logData{msS.lag})),...
      'presNum',num2cell(single(logData{msS.presNum})), 'pairNum',num2cell(single(logData{msS.pairNum})), 'pairOrd',num2cell(single(logData{msS.pairOrd})),...
      'catStr',logData{msS.catStr}, 'catNum',num2cell(single(logData{msS.catNum})),...
      'cr_recall_resp', [], 'cr_recall_spellCorr', []);
    
    % only keep certain types of events
    log = log(ismember({log.type},{'STUDY_IMAGE', 'STUDY_WORD'}));
    
    % put them in the order of occurrence
    [~, timeInd] = sort([log.time]);
    log = log(timeInd);
    
    % store the log struct in the events struct
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).data = log;
    events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete = true;
    
    % mark the subject as complete
    if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
      events.isComplete = true;
    end
    
  case {'distract_math', 'prac_distract_math'}
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
    
    % mark the subject as complete
    if events.(sesName).(sprintf('%s_%d',phaseName,phaseCount)).isComplete
      events.isComplete = true;
    end
    
  case {'cued_recall', 'prac_cued_recall', 'cued_recall_only', 'prac_cued_recall_only'}
    % whether to interactively check the spelling of cued recall trials
    checkSpelling = true;
    respMustBeLongerThanOneLetter = true;
    allowIncorrectPlural = true;
    useEditDist = true;
    checkLetterTranspose = true;
    
    switch phaseName
      case {'cued_recall', 'prac_cued_recall'}
        logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_cr_%d.txt',sesName,phaseName,phaseCount));
      case {'cued_recall_only', 'prac_cued_recall_only'}
        logFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_cro_%d.txt',sesName,phaseName,phaseCount));
    end
    
    if ~isPilotData
      formatStr = '%.6f%s%s%s%d%d%s%d%s%d%d%d%d%d%s%d%s%s%d%d%d';
    else
      if str2double(subject(end-2:end)) <= 44
        formatStr = '%.6f%s%s%s%d%d%s%d%s%d%d%d%d%d%s%d%s%s%d%d';
      else
        formatStr = '%.6f%s%s%s%d%d%s%d%s%d%d%d%d%d%s%d%s%s%d%d%d';
      end
    end
    
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
      crS.i_stimStr = 9;
      crS.i_stimNum = 10;
      crS.targ = 11;
      crS.spaced = 12;
      crS.lag = 13;
      crS.pairNum = 14;
      crS.i_catStr = 15;
      crS.i_catNum = 16;
      
%       % unique to {'RECOGTEST_RECOGRESP'}
%       crS.recog_resp = 17;
%       crS.recog_respKey = 18;
%       crS.recog_acc = 19;
%       crS.recog_rt = 20;
%       
%       % unique to {'RECOGTEST_NEWRESP'}
%       crS.new_resp = 17;
%       crS.new_respKey = 18;
%       crS.new_acc = 19;
%       crS.new_rt = 20;
      
      % unique to {'TEST_RECALLRESP'}
      crS.recall_resp = 17;
      crS.recall_origword = 18;
      % hack due to minor log file change
      if ~isPilotData
        crS.w_stimNum = 19;
        crS.recall_corrSpell = 20;
        crS.recall_rt = 21;
      else
        if str2double(subject(end-2:end)) <= 44
          crS.recall_corrSpell = 19;
          crS.recall_rt = 20;
        else
          crS.w_stimNum = 19;
          crS.recall_corrSpell = 20;
          crS.recall_rt = 21;
        end
      end
      
      % read the real file
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
    
%     % SPACE Subjects 1-7 had lures (targ=0) marked as spaced=-1. needs to be
%     % false instead because logical(-1)=1.
%     if str2double(subject(end-2:end)) <= 7
%       logData{crS.spaced}([logData{crS.targ}] == 0 & logData{crS.trial} ~= 0) = false;
%       % % another method
%       % logData{crS.spaced}([logData{crS.spaced}] == -1) = false;
%     end
    
    % set all fields here so we can easily concatenate events later
    log = struct('subject',subject,'session',sesNum,'sesName',sesName,...
      'phaseName',phaseName,'phaseCount',phaseCount,...
      'isExp',num2cell(logical(logData{crS.isExp})), 'time',num2cell(logData{crS.time}),...
      'type',logData{crS.type}, 'trial',num2cell(single(logData{crS.trial})),...
      'stimStr',logData{crS.i_stimStr}, 'stimNum',num2cell(single(logData{crS.i_stimNum})), 'targ',num2cell(logical(logData{crS.targ})),...
      'spaced',num2cell(logical(logData{crS.spaced})), 'lag',num2cell(single(logData{crS.lag})),...
      'pairNum',num2cell(single(logData{crS.pairNum})), 'i_catStr',logData{crS.i_catStr}, 'i_catNum',num2cell(single(logData{crS.i_catNum})),...
      'recall_origword',[], 'recall_resp',[], 'recall_spellCorr',[], 'recall_rt',[]);
    
    studyPhaseStr = 'multistudy';
    if strncmp(phaseName,'prac_',5)
      studyPhaseStr = sprintf('prac_%s',studyPhaseStr);
    end
    % store all the words studied on this phase, including buffers
    phaseCRList = lower({events.(sesName).(sprintf('%s_%d',studyPhaseStr,phaseCount)).data.stimStr});
    for pl = 1:length(phaseCRList)
      if ~isempty(strfind(phaseCRList{pl},'.'))
        phaseCRList{pl} = '';
      end
    end
    phaseCRList = unique(phaseCRList(~ismember(phaseCRList,'')),'stable');
    if size(phaseCRList,1) > 1
      phaseCRList = phaseCRList';
    end
    fprintf('Studied words on this list:\n%s\n',sprintf(repmat(' %s',1,length(phaseCRList)),phaseCRList{:}));
    
    % store all the words studied in previous sessions, including buffers
    studyPhaseStrs = {'prac_multistudy','multistudy'};
    prevSesCRList = {};
    if sesNum > 1
      prevSesNumInit = sesNum - 1;
      for ps = prevSesNumInit:-1:1
        fn = fieldnames(events.(sprintf('day%d',ps)));
        for f = 1:length(fn)
          for sps = 1:length(studyPhaseStrs)
            studyPhaseStr = studyPhaseStrs{sps};
            if strcmp(fn{f},studyPhaseStr)
              prevPhaseCRList = lower({events.(sprintf('day%d',ps)).(fn{f}).data.stimStr});
              for pl = 1:length(prevPhaseCRList)
                if ~isempty(strfind(prevPhaseCRList{pl},'.'))
                  prevPhaseCRList{pl} = '';
                end
              end
              prevPhaseCRList = unique(prevPhaseCRList(~ismember(prevPhaseCRList,'')),'stable');
              if size(prevPhaseCRList,1) > 1
                prevPhaseCRList = prevPhaseCRList';
              end
              prevSesCRList = cat(2,prevSesCRList,prevPhaseCRList);
            end
          end
        end
      end
    end
    
    for i = 1:length(log)
      propagateNewRecall = false;
      
      switch log(i).type
        case {'TEST_RECALLRESP'}
          % unique to RECOGTEST_RECALLRESP
          log(i).recall_resp = logData{crS.recall_resp}{i};
          log(i).recall_origword = logData{crS.recall_origword}{i};
          if log(i).targ
            if isempty(log(i).recall_resp) || strcmpi(log(i).recall_resp,'NO_RESPONSE')
              log(i).recall_spellCorr = 0;
              % debug
              fprintf('No recall: %s (%d) trial %d of %d (%s, %s, session_%d):\n',phaseName,phaseCount,log(i).trial,max([log.trial]),subject,sesName,sesNum);
              fprintf('\tWord: %s\n',log(i).recall_origword);
            else
              if checkSpelling
                % if we want to check the spelling on their recall responses
                if strcmpi(log(i).recall_origword,log(i).recall_resp)
                  % auto spell check
                  log(i).recall_spellCorr = 1;
                  fprintf('Correct: %s (%d) trial %d of %d (%s, %s, session_%d):\n',phaseName,phaseCount,log(i).trial,max([log.trial]),subject,sesName,sesNum);
                  fprintf('\tWord: %s\n',log(i).recall_origword);
                elseif respMustBeLongerThanOneLetter && length(log(i).recall_resp) == 1
                  log(i).recall_spellCorr = 0;
                  fprintf('Incorrect: %s (%d) trial %d of %d (%s, %s, session_%d):\n',phaseName,phaseCount,log(i).trial,max([log.trial]),subject,sesName,sesNum);
                  fprintf('\tOriginal word:  %s\n',log(i).recall_origword);
                  fprintf('\tTheir response: %s\n',log(i).recall_resp);
                elseif allowIncorrectPlural && (strcmpi(log(i).recall_origword,cat(2,log(i).recall_resp,'s')) || strcmpi(log(i).recall_origword,cat(2,log(i).recall_resp,'es')) || strcmpi(cat(2,log(i).recall_origword,'s'),log(i).recall_resp) || strcmpi(cat(2,log(i).recall_origword,'es'),log(i).recall_resp))
                  % auto spell check
                  log(i).recall_spellCorr = 1;
                  fprintf('Wrong plural, marking correct: %s (%d) trial %d of %d (%s, %s, session_%d):\n',phaseName,phaseCount,log(i).trial,max([log.trial]),subject,sesName,sesNum);
                  fprintf('\tOriginal word:  %s\n',log(i).recall_origword);
                  fprintf('\tTheir response: %s\n',log(i).recall_resp);
                else
                  % initialize
                  decision = -1;
                  
                  % other auto checks, fall back on manual spell check
                  fprintf('\nRecall for %s (%d) trial %d of %d (%s, %s, session_%d):\n',phaseName,phaseCount,log(i).trial,max([log.trial]),subject,sesName,sesNum);
                  fprintf('\tOriginal word:  %s\n',log(i).recall_origword);
                  fprintf('\tTheir response: %s\n',log(i).recall_resp);
                  
                  % auto: intrusions should almost always be incorrect
                  % (just check on prior session intrusion)
                  if ismember(log(i).recall_resp,phaseCRList)
                    fprintf('\t\tIncorrect: CURRENT LIST INTRUSION (studied on this list)!\n');
                    decision = 0;
                  elseif ismember(log(i).recall_resp,sessionCRList)
                    fprintf('\t\tIncorrect: PRIOR LIST INTRUSION (studied on previous list this session)!\n');
                    decision = 0;
                  elseif ~strncmp(phaseName,'prac_',5) && ismember(log(i).recall_resp,prevSesCRList)
                    warning('PRIOR SESSION INTRUSION (studied on previous session)!');
                  end
                  
                  % auto: see if words are coupled
                  if strcmpi(log(i).recall_origword,cat(2,log(i).recall_resp,'r')) || strcmpi(cat(2,log(i).recall_origword,'r'),log(i).recall_resp) || strcmpi(log(i).recall_origword,cat(2,log(i).recall_resp,'er')) || strcmpi(cat(2,log(i).recall_origword,'er'),log(i).recall_resp)
                    decision = 2;
                    fprintf('\tCoupled: Found exact same word stem.\n');
                  end
                  
                  % auto: see if off by 1 letter (for misspellings)
                  if useEditDist && decision < 0
                    d = EditDist(lower(log(i).recall_origword),lower(log(i).recall_resp));
                    if d == 1
                      decision = 1;
                      fprintf('\tCorrect: Found that response was off by 1 letter using EditDist.m\n');
                    end
                  end
                  
                  % auto: check letter transposition
                  if checkLetterTranspose && decision < 0
                    lttr = 1;
                    while lttr < length(log(i).recall_resp)
                      lttr = lttr + 1;
                      resp = log(i).recall_resp;
                      resp(lttr) = log(i).recall_resp(lttr - 1);
                      resp(lttr - 1) = log(i).recall_resp(lttr);
                      if strcmpi(log(i).recall_origword,resp)
                        decision = 1;
                        fprintf('\tCorrect: Found neighboring letter transposition.\n');
                        break
                      end
                    end
                  end
                  
                  % Manual:
                  % Correct (1) and incorrect (0) are for typos and total
                  % intrusions, respectively. Coupled (2) means
                  % intrinsically linked words and must have the same word
                  % stem (staple/stapler, bank/banker, dance/dancer,
                  % serve/server)  Synonym (3) means words that strictly
                  % have the same meaning and can have the same word stem
                  % (sofa/couch, doctor/physician, home/house,
                  % pasta/noodle, woman/lady, cash/money). Homonym (4)
                  % means words that sound exactly the same (board/bored,
                  % brake/break). Related (5) means closely associated
                  % words but cannot have the same word stem (whiskey/rum,
                  % map/compass, sailor/boat, broccoli/carrot).
                  while decision < 0
                    decision = input('                Correct, incorrect, coupled (same stem), synonym, homonym, related?  (1, 0, c, s, h, or r?). ','s');
                    if length(decision) == 1
                      if isstrprop(decision,'digit') && (str2double(decision) == 1 || str2double(decision) == 0)
                        decision = str2double(decision);
                        if decision == 1
                          %fprintf('\t\tMarked correct!\n');
                          verify = input('                Press return to mark CORRECT. Type anything else to re-grade. ','s');
                          if isempty(verify)
                            break
                          else
                            decision = -1;
                          end
                        elseif decision == 0
                          %fprintf('\t\tMarked incorrect.\n');
                          verify = input('                Press return to mark INCORRECT. Type anything else to re-grade. ','s');
                          if isempty(verify)
                            break
                          else
                            decision = -1;
                          end
                        end
                      elseif isstrprop(decision,'alpha') && strcmp(decision,'c')
                        decision = 2;
                        %fprintf('\t\tMarked as coupled!\n');
                        verify = input('                Press return to mark as COUPLED (same stem only). Type anything else to re-grade. ','s');
                        if isempty(verify)
                          break
                        else
                          decision = -1;
                        end
                      elseif isstrprop(decision,'alpha') && strcmp(decision,'s')
                        decision = 3;
                        %fprintf('\t\tMarked as synonym!\n');
                        verify = input('                Press return to mark as SYNONYM. Type anything else to re-grade. ','s');
                        if isempty(verify)
                          break
                        else
                          decision = -1;
                        end
                      elseif isstrprop(decision,'alpha') && strcmp(decision,'h')
                        decision = 4;
                        %fprintf('\t\tMarked as homonym!\n');
                        verify = input('                Press return to mark as HOMONYM. Type anything else to re-grade. ','s');
                        if isempty(verify)
                          break
                        else
                          decision = -1;
                        end
                      elseif isstrprop(decision,'alpha') && strcmp(decision,'r')
                        decision = 5;
                        %fprintf('\t\tMarked as related!\n');
                        verify = input('                Press return to mark as RELATED. Type anything else to re-grade. ','s');
                        if isempty(verify)
                          break
                        else
                          decision = -1;
                        end
                      end
                    else
                      decision = -1;
                    end
                  end
                  
                  % store the grade
                  log(i).recall_spellCorr = decision;
                end
              else
                % if we don't want to check their spelling
                log(i).recall_spellCorr = logData{crS.recall_corrSpell}(i);
              end
            end
          else
            log(i).recall_spellCorr = 0;
          end
          log(i).recall_rt = single(logData{crS.recall_rt}(i));
          
%           % didn't make a new response
%           log(i).new_resp = '';
%           log(i).new_acc = false;
%           log(i).new_rt = -1;
          
          % flag to put info in stimulus presentations
          propagateNewRecall = true;
          
          sessionCRList = cat(2,sessionCRList,phaseCRList);
      end % switch
      
      if propagateNewRecall
        % put info in stimulus presentations
        
        % find the corresponding TEST_STIM
        thisRecogStim = strcmp({log.type},'TEST_STIM') & [log.stimNum] == log(i).stimNum & [log.i_catNum] == log(i).i_catNum;
        if sum(thisRecogStim) == 1
%           log(thisRecogStim).new_resp = log(i).new_resp;
%           log(thisRecogStim).new_acc = log(i).new_acc;
%           log(thisRecogStim).new_rt = log(i).new_rt;
          
          log(thisRecogStim).recall_resp = log(i).recall_resp;
          log(thisRecogStim).recall_origword = log(i).recall_origword;
          log(thisRecogStim).recall_spellCorr = log(i).recall_spellCorr;
          log(thisRecogStim).recall_rt = log(i).recall_rt;
        else
          keyboard
        end
        
%         % find the corresponding RECOGTEST_RECOGRESP
%         thisRecogResp = strcmp({log.type},'RECOGTEST_RECOGRESP') & [log.stimNum] == log(i).stimNum & [log.i_catNum] == log(i).i_catNum;
%         if sum(thisRecogResp) == 1
%           % put info in the recognition response
%           log(thisRecogResp).new_resp = log(i).new_resp;
%           log(thisRecogResp).new_acc = log(i).new_acc;
%           log(thisRecogResp).new_rt = log(i).new_rt;
%           
%           log(thisRecogResp).recall_resp = log(i).recall_resp;
%           log(thisRecogResp).recall_origword = log(i).recall_origword;
%           log(thisRecogResp).recall_spellCorr = log(i).recall_spellCorr;
%           log(thisRecogResp).recall_rt = log(i).recall_rt;
%           
%           % get info from the recognition response
%           log(i).recog_resp = log(thisRecogResp).recog_resp;
%           log(i).recog_acc = log(thisRecogResp).recog_acc;
%           log(i).recog_rt = log(thisRecogResp).recog_rt;
%         else
%           keyboard
%         end
      end
      
    end % for
    
    % only keep certain types of events
    log = log(ismember({log.type},{'TEST_STIM','TEST_RECALLRESP'}));
    
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

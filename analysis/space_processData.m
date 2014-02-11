function [results] = space_processData(results,dataroot,subjects,collapsePhases,collapseCategories,separateCategories,onlyCompleteSub,printResults,saveResults,partialCredit)
% function [results] = space_processData(results,dataroot,subjects,collapsePhases,collapseCategories,separateCategories,onlyCompleteSub,printResults,saveResults,partialCredit)
%
% Processes data into basic measures like accuracy, response time, and d-prime
%
% e.g.,
% [results] = space_processData([],[],[],true,true,true,true,false,true,true);

if ~exist('partialCredit','var') || isempty(partialCredit)
  partialCredit = true;
end

if ~exist('results','var') || isempty(results)
  results = [];
end

% EEG
if ~exist('subjects','var') || isempty(subjects)
  subjects = {
    'SPACE001';
    'SPACE002';
    'SPACE003';
    'SPACE004';
    'SPACE005';
    'SPACE006';
    'SPACE007';
    %'SPACE008';
    'SPACE009';
    'SPACE010';
    'SPACE011';
    'SPACE012';
    'SPACE013';
    'SPACE014';
    'SPACE015';
    'SPACE016';
    'SPACE017';
    'SPACE018';
    'SPACE019';
    'SPACE020';
    'SPACE021';
    'SPACE022';
    'SPACE027';
    'SPACE029';
    };
end
templateSubject = 'SPACE001';

% if ~exist('subjects','var') || isempty(subjects)
%   subjects = {
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
%     %'SPACE038'; % responded "J" to almost all cued recall prompts
%     'SPACE039';
%     'SPACE040';
%     'SPACE041';
%     'SPACE042';
%     'SPACE043';
%     'SPACE044';
%     };
% end
% % subject after which to set up results struct fields
% templateSubject = 'SPACE033';

% if ~exist('subjects','var') || isempty(subjects)
%   subjects = {
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
%     };
% end
% % subject after which to set up results struct fields
% templateSubject = 'SPACE010';

% if ~exist('subjects','var') || isempty(subjects)
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
% end
% % subject after which to set up results struct fields
% templateSubject = 'SPACE033';

% try to determine the experiment name by removing the subject number
if ~isempty(subjects)
  zs = strfind(subjects{1},'0');
  if ~isempty(zs)
    expName = subjects{1}(1:zs(1)-1);
  else
    error('Cannot determine experiment name, subject name ''%s'' not parseable.',subjects{1});
  end
else
  error('Cannot determine experiment name, no subjects provided.');
end

% find where the data is stored
if ~exist('dataroot','var') || isempty(dataroot)
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
  %saveDir = dataroot;
end

if ~exist('collapsePhases','var') || isempty(collapsePhases)
  collapsePhases = false;
end

if ~exist('collapseCategories','var') || isempty(collapseCategories)
  collapseCategories = true;
end

if ~exist('separateCategories','var') || isempty(separateCategories)
  separateCategories = true;
end

if ~exist('onlyCompleteSub','var') || isempty(onlyCompleteSub)
  onlyCompleteSub = true;
end

if ~exist('printResults','var') || isempty(printResults)
  printResults = true;
end

if ~exist('saveResults','var') || isempty(saveResults)
  saveResults = true;
end

%% messing around

% r1data = events.oneDay.cued_recall_1.data;
%
% % Subjects 1-7 had lures (targ=0) marked as spaced=-1. needs to be false
% % instead because logical(-1)=1.
% lureInd = [r1data.targ] == 0;
% for i = 1:length(lureInd)
%   if lureInd(i)
%     r1data(i).spaced = false;
%   end
% end
%
% massed = r1data(~ismember({r1data.recog_resp},{'NO_RESPONSE', 'none'}) & [r1data.targ] == true & [r1data.spaced] == false & [r1data.lag] == 0);
% spaced = r1data(~ismember({r1data.recog_resp},{'NO_RESPONSE', 'none'}) & [r1data.targ] == true & [r1data.spaced] == true & [r1data.lag] > 0);
% onePres = r1data(~ismember({r1data.recog_resp},{'NO_RESPONSE', 'none'}) & [r1data.targ] == true & [r1data.spaced] == false & [r1data.lag] == -1);
% newStims = r1data(~ismember({r1data.recog_resp},{'NO_RESPONSE', 'none'}) & [r1data.targ] == false);
%
% fprintf('\n\n');
% fprintf('Spaced recog acc (%d/%d) = %.3f\n',sum([spaced.recog_acc]),length(spaced),mean([spaced.recog_acc]));
% fprintf('Massed recog acc (%d/%d) = %.3f\n',sum([massed.recog_acc]),length(massed),mean([massed.recog_acc]));
% fprintf('onePres recog acc (%d/%d) = %.3f\n',sum([onePres.recog_acc]),length(onePres),mean([onePres.recog_acc]));
% fprintf('newStims recog acc (%d/%d) = %.3f\n',sum([newStims.recog_acc]),length(newStims),mean([newStims.recog_acc]));
%
% %fprintf('\n');
% %fprintf('Spaced new acc %.3f\n',mean([spaced.new_acc]));
% %fprintf('Massed new acc %.3f\n',mean([massed.new_acc]));
% %fprintf('onePres new acc %.3f\n',mean([onePres.new_acc]));
% %fprintf('newStims new acc %.3f\n',mean([newStims.new_acc]));
%
% fprintf('\n');
% fprintf('Spaced recall acc (%d/%d) = %.3f\n',sum([spaced.recall_spellCorr] == 1),length(spaced),mean([spaced.recall_spellCorr] == 1));
% fprintf('Massed recall acc (%d/%d) = %.3f\n',sum([massed.recall_spellCorr] == 1),length(massed),mean([massed.recall_spellCorr] == 1));
% fprintf('onePres recall acc (%d/%d) = %.3f\n',sum([onePres.recall_spellCorr] == 1),length(onePres),mean([onePres.recall_spellCorr] == 1));
% %fprintf('newStims recall acc %.3f\n',mean([newStims.recall_spellCorr] == 1));

if isempty(results)
  
  %% some constants
  
  %nBlocks = 3;
  
  % lagConds = [8, 0, -1];
  
  results = struct;
  
  mainFields = {'recog','recall'};
  %dataFields = {'nTrials','nCor','nInc','acc','hr','far','dp','rt_hit','rt_miss','rt_cr','rt_far'};
  dataFields = {'nTrials','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt_hit','rt_miss','rt_cr','rt_far'};
  
  % categories = [1, 2];
  % categoryStr = {'faces', 'houses'};
  
  %% initialize to store the data
  
  % use a subject's files for initialization
  if length(subjects) > 5
    tempSub = templateSubject;
  else
    tempSub = subjects{end};
  end
  tempSub = ismember(subjects,tempSub);
  
  subDir = fullfile(dataroot,subjects{tempSub});
  expParamFile = fullfile(subDir,'experimentParams.mat');
  if exist(expParamFile,'file')
    load(expParamFile,'expParam','cfg')
  else
    error('initialization experiment parameter file does not exist: %s',expParamFile);
  end
  eventsFile = fullfile(subDir,'events','events.mat');
  if exist(eventsFile,'file')
    load(eventsFile,'events');
  else
    error('initialization events file does not exist: %s',eventsFile);
  end
  
  for sesNum = 1:length(expParam.sesTypes)
    % set the subject events file
    sesName = expParam.sesTypes{sesNum};
    
    uniquePhaseNames = unique(expParam.session.(sesName).phases,'stable');
    uniquePhaseCounts = zeros(1,length(unique(expParam.session.(sesName).phases,'stable')));
    
    if collapsePhases
      processThesePhases = uniquePhaseNames;
    else
      processThesePhases = expParam.session.(sesName).phases;
    end
    
    for pha = 1:length(processThesePhases)
      phaseName = expParam.session.(sesName).phases{pha};
      
      % find out where this phase occurs in the list of unique phases
      uniquePhaseInd = find(ismember(uniquePhaseNames,phaseName));
      % increase the phase count for that phase
      uniquePhaseCounts(uniquePhaseInd) = uniquePhaseCounts(uniquePhaseInd) + 1;
      % set the phase count
      phaseCount = uniquePhaseCounts(uniquePhaseInd);
      
      % accidently set isExp=true for prac_distract_math
      if ~isempty(strfind(phaseName,'prac_')) && cfg.stim.(sesName).(phaseName)(phaseCount).isExp
        cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
      end
      
      if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
        
        if collapsePhases
          fn = phaseName;
        else
          % set the phase name with phase count
          fn = sprintf(sprintf('%s_%d',phaseName,phaseCount));
        end
        
        if isfield(events.(sesName),fn)
          
          switch phaseName
            case {'cued_recall'}
              targEvents = events.(sesName).(fn).data([events.(sesName).(fn).data.targ]);
              %lureEvents = events.(sesName).(fn).data(~[events.(sesName).(fn).data.targ]);
              
              lagConds = unique([targEvents.lag]);
              
              for lc = 1:length(lagConds)
                % choose the training condition
                if length(lagConds(lc)) == 1
                  if lagConds(lc) > 0
                    %lagStr = sprintf('lag%d',lagConds(lc));
                    lagStr = 'spaced';
                  elseif lagConds(lc) == 0
                    lagStr = 'massed';
                  elseif lagConds(lc) == -1
                    lagStr = 'once';
                  end
                elseif length(lagConds(lc)) > 1
                  lagStr = 'multi?';
                end
                
                
                if collapseCategories
                  for mf = 1:length(mainFields)
                    mField = mainFields{mf};
                    for df = 1:length(dataFields)
                      dField = dataFields{df};
                      
                      %if strcmp(mField,'recall')
                      %  dField = 'spellCorr';
                      %else
                      %  dField = dataFields{df};
                      %end
                      
                      %results.(sesName).(fn).(lagStr).(mainFields{mf}).(dataFields{df}) = nan(length(subjects),1);
                      results.(sesName).(fn).(lagStr).(mField).(sprintf('%s_%s',mField,dField)) = nan(length(subjects),1);
                    end
                  end
                end
                
                % image categories
                i_catStrs = unique({targEvents.i_catStr},'stable');
                if length(i_catStrs) > 1 && separateCategories
                  for im = 1:length(i_catStrs)
                    for mf = 1:length(mainFields)
                      mField = mainFields{mf};
                      for df = 1:length(dataFields)
                        dField = dataFields{df};
                        
                        %if strcmp(mField,'recall')
                        %  dField = 'spellCorr';
                        %else
                        %  dField = dataFields{df};
                        %end
                        
                        %results.(sesName).(fn).(lagStr).(i_catStrs{im}).(mainFields{mf}).(dataFields{df}) = nan(length(subjects),1);
                        results.(sesName).(fn).(lagStr).(i_catStrs{im}).(mField).(sprintf('%s_%s',mField,dField)) = nan(length(subjects),1);
                      end
                    end
                  end
                end
                
              end % for t
              %         case {'name', 'nametrain', 'prac_name'}
              %
              %           if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
              %             nBlocks = 1;
              %           else
              %             nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
              %           end
              %
              %           for mf = 1:length(mainFields)
              %             for df = 1:length(dataFields)
              %               results.(sesName).(fn).(mainFields{mf}).(dataFields{df}) = nan(length(subjects),1);
              %             end
              %           end
              %           if nBlocks > 1
              %             for b = 1:nBlocks
              %               for mf = 1:length(mainFields)
              %                 for df = 1:length(dataFields)
              %                   results.(sesName).(fn).(sprintf('b%d',b)).(mainFields{mf}).(dataFields{df}) = nan(length(subjects),1);
              %                 end
              %               end
              %             end
              %           end
          end % switch
        end
      end
    end
  end
  
  %% process the data
  
  fprintf('Processing data for experiment %s...\n',expName);
  
  for sub = 1:length(subjects)
    subDir = fullfile(dataroot,subjects{sub});
    fprintf('Processing %s in %s...\n',subjects{sub},subDir);
    
    fprintf('Loading events for %s...',subjects{sub});
    eventsFile = fullfile(subDir,'events','events.mat');
    if exist(eventsFile,'file')
      load(eventsFile,'events');
      fprintf('Done.\n');
    else
      error('events file does not exist: %s',eventsFile);
    end
    
    % do we only want to get data from subjects who have completed the exp?
    if ~onlyCompleteSub || (onlyCompleteSub && events.isComplete)
      
      fprintf('Loading experiment parameters for %s...',subjects{sub});
      expParamFile = fullfile(subDir,'experimentParams.mat');
      if exist(expParamFile,'file')
        load(expParamFile)
        fprintf('Done.\n');
      else
        error('experiment parameter file does not exist: %s',expParamFile);
      end
      
      for sesNum = 1:length(expParam.sesTypes)
        % set the subject events file
        sesName = expParam.sesTypes{sesNum};
        
        uniquePhaseNames = unique(expParam.session.(sesName).phases,'stable');
        uniquePhaseCounts = zeros(1,length(unique(expParam.session.(sesName).phases,'stable')));
        
        if collapsePhases
          processThesePhases = uniquePhaseNames;
        else
          processThesePhases = expParam.session.(sesName).phases;
        end
        
        for pha = 1:length(processThesePhases)
          phaseName = processThesePhases{pha};
          
          % find out where this phase occurs in the list of unique phases
          uniquePhaseInd = find(ismember(uniquePhaseNames,phaseName));
          % increase the phase count for that phase
          uniquePhaseCounts(uniquePhaseInd) = uniquePhaseCounts(uniquePhaseInd) + 1;
          % set the phase count
          phaseCount = uniquePhaseCounts(uniquePhaseInd);
          
          % accidently set isExp=true for prac_distract_math
          if ~isempty(strfind(phaseName,'prac_')) && cfg.stim.(sesName).(phaseName)(phaseCount).isExp
            cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
          end
          
          if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
            
            if collapsePhases
              fn = phaseName;
            else
              % set the phase name with phase count
              fn = sprintf(sprintf('%s_%d',phaseName,phaseCount));
            end
            
            if isfield(events.(sesName),fn)
              
              % collect data if this phase is complete
              if events.(sesName).(fn).isComplete
                
                switch phaseName
                  case {'cued_recall'}
                    thisPhaseEv = events.(sesName).(fn).data;
                    % this phase events; how many lag conditions occurred
                    % for targets (during study)?
                    lagConds = unique([thisPhaseEv([thisPhaseEv.targ]).lag]);
                    
                    % exclude missed responses ({'NO_RESPONSE', 'none'})
                    thisPhaseEv = thisPhaseEv(~ismember({thisPhaseEv.recog_resp},{'NO_RESPONSE', 'none'}));
                    
                    %targEvents = theseEvents([theseEvents.targ]);
                    %lureEvents = theseEvents(~[theseEvents.targ]);
                    
                    %testStimEvents = events.(sesName).(fn).data(ismember({events.(sesName).(fn).data.type},'RECOGTEST_STIM'));
                    %testEvents = events.(sesName).(fn).data;
                    
                    if sum(lagConds > 0) > 1
                      error('%s does not yet support multiple lag conditions!',mfilename);
                    end
                    
                    for lc = 1:length(lagConds)
                      fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                      
                      % targ events are either massed or spaced, depending
                      % on the lag condition
                      targEvents = thisPhaseEv([thisPhaseEv.targ] & ismember({thisPhaseEv.type},'RECOGTEST_STIM') & ismember([thisPhaseEv.lag],lagConds(lc)));
                      % lure events don't have lag conditions
                      lureEvents = thisPhaseEv(~[thisPhaseEv.targ] & ismember({thisPhaseEv.type},'RECOGTEST_STIM'));
                      
                      % choose the training condition
                      if length(lagConds(lc)) == 1
                        if lagConds(lc) > 0
                          if printResults
                            fprintf('*** Spaced (lag %d) ***\n',lagConds(lc));
                          end
                          %lagStr = sprintf('lag%d',lagConds(lc));
                          lagStr = 'spaced';
                        elseif lagConds(lc) == 0
                          if printResults
                            fprintf('*** Massed ***\n');
                          end
                          lagStr = 'massed';
                        elseif lagConds(lc) == -1
                          lagStr = 'once';
                          if printResults
                            fprintf('*** Once ***\n');
                          end
                        end
                      elseif length(lagConds(lc)) > 1
                        if printResults
                          fprintf('Multi?\n');
                        end
                        lagStr = 'all';
                      end
                      
                      % filter the events that we want
                      %recog_spaced_resp = targEvents(ismember({targEvents.type},'RECOGTEST_RECOGRESP') & ismember([targEvents.lag],lagConds(lc)));
                      
                      % exclude missed responses ({'NO_RESPONSE', 'none'})
                      %recog_spaced_resp = recog_spaced_resp(~ismember({recog_spaced_resp.recog_resp},{'NO_RESPONSE', 'none'}));
                      % % set missing responses to incorrect
                      % noRespInd = find(ismember({matchResp.resp},{'NO_RESPONSE', 'none'}));
                      % if ~isempty(noRespInd)
                      %   for nr = 1:length(noRespInd)
                      %     matchResp(noRespInd(nr)).acc = 0;
                      %   end
                      % end
                      
                      if collapseCategories
                        % overall, collapsing across categories
                        for mf = 1:length(mainFields)
                          mField = mainFields{mf};
                          
%                           % filter the events that we want
%                           theseEvents = targEvents(...
%                             strcmpi({targEvents.type},sprintf('RECOGTEST_%sRESP',mField)) &...
%                             ismember([targEvents.lag],lagConds(lc)));
                          
                          % if single presentation items are not tested,
                          % there will be no targets with lag=-1, only
                          % lures have this lag field value.
                          %if isempty(theseEvents)
                          %  keyboard
                          %end
                          
                          if strcmp(mField,'recog')
                            accField = sprintf('%s_acc',mField);
                            dpField = sprintf('%s_dp',mField);
                          elseif strcmp(mField,'recall')
                            accField = sprintf('%s_spellCorr',mField);
                            dpField = 'NA';
                          end
                          if strcmp(mField,'recog')
                            accField = sprintf('%s_acc',mField);
                          elseif strcmp(mField,'recall')
                            accField = sprintf('%s_spellCorr',mField);
                          end
                          hrField = sprintf('%s_hr',mField);
                          mrField = sprintf('%s_mr',mField);
                          crrField = sprintf('%s_crr',mField);
                          farField = sprintf('%s_far',mField);
                          nTrialsField = sprintf('%s_nTrials',mField);
                          nTargField = sprintf('%s_nTarg',mField);
                          nLureField = sprintf('%s_nLure',mField);
                          nHitField = sprintf('%s_nHit',mField);
                          nMissField = sprintf('%s_nMiss',mField);
                          nCRField = sprintf('%s_nCR',mField);
                          nFAField = sprintf('%s_nFA',mField);
                          %nCorField = sprintf('%s_nCor',mField);
                          %nIncField = sprintf('%s_nInc',mField);
                          rtField = sprintf('%s_rt',mField);
                          
                          %if strcmp(mField,'recog')
                          %  accField = 'acc';
                          %elseif strcmp(mField,'recall')
                          %  accField = 'spellCorr';
                          %end
                          %hrField = 'hr';
                          %farField = 'far';
                          %dpField = 'dp';
                          %nTrialsField = 'nTrials';
                          %nCorField = 'nCor';
                          %nIncField = 'nInc';
                          %rtField = 'rt';
                          
                          results.(sesName).(fn).(lagStr) = accAndRT(targEvents,lureEvents,sub,results.(sesName).(fn).(lagStr),partialCredit,mField,...
                            accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);

                          theseResults = results.(sesName).(fn).(lagStr).(mField);
                          if printResults
                            fprintf('\t%s\n',mField);
                            fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',theseResults.(hrField)(sub),theseResults.(nHitField)(sub),(theseResults.(nTargField)(sub)));
                            if ~strcmp(dpField,'NA')
                              fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',theseResults.(farField)(sub),theseResults.(nFAField)(sub),(theseResults.(nLureField)(sub)));
                              fprintf('\t\td'':\t\t%.2f\n',theseResults.(dpField)(sub));
                            end
                            fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',theseResults.(sprintf('%s_hit',rtField))(sub),theseResults.(sprintf('%s_miss',rtField))(sub));
                            if ~strcmp(dpField,'NA')
                              fprintf(', cr: %.2f, fa: %.2f\n',theseResults.(sprintf('%s_cr',rtField))(sub),theseResults.(sprintf('%s_fa',rtField))(sub));
                            else
                              fprintf('\n');
                            end
                          end
                        end
                      end
                      
                      % accuracy for the different image categories
                      i_catStrs = unique({targEvents.i_catStr},'stable');
                      % if there's only 1 image category, the results were
                      % printed above
                      if length(i_catStrs) > 1 && separateCategories
                        if printResults
                          fprintf('\n');
                        end
                        for im = 1:length(i_catStrs)
                          for mf = 1:length(mainFields)
                            mField = mainFields{mf};
                            
                            % targ events are either massed or spaced, depending
                            % on the lag condition
                            targEvents = thisPhaseEv([thisPhaseEv.targ] & ismember({thisPhaseEv.type},'RECOGTEST_STIM') & ismember([thisPhaseEv.lag],lagConds(lc)) & strcmpi({thisPhaseEv.i_catStr},i_catStrs{im}));
                            % lure events don't have lag conditions
                            lureEvents = thisPhaseEv(~[thisPhaseEv.targ] & ismember({thisPhaseEv.type},'RECOGTEST_STIM') & strcmpi({thisPhaseEv.i_catStr},i_catStrs{im}));
                            
%                             % filter the events that we want
%                             theseEvents = targEvents(...
%                               strcmpi({targEvents.type},sprintf('RECOGTEST_%sRESP',mField)) &...
%                               ismember([targEvents.lag],lagConds(lc)) &...
%                               strcmpi({targEvents.i_catStr},i_catStrs{im}));
                            %theseEvents = targEvents(...
                            %  strcmpi({targEvents.type},sprintf('RECOGTEST_%sRESP',mField)) &...
                            %  ismember([targEvents.lag],lagConds(lc)) &...
                            %  strcmpi({targEvents.i_catStr},i_catStrs{im}) &...
                            %  [targEvents.targ]);
                            
%                             if strcmp(mField,'recog')
%                               % exclude missed responses ({'NO_RESPONSE', 'none'})
%                               theseEvents = theseEvents(~ismember({theseEvents.recog_resp},{'NO_RESPONSE', 'none'}));
%                             end
                            
                            % if single presentation items are not tested,
                            % there will be no targets with lag=-1, only
                            % lures have this lag field value.
                            %if isempty(theseEvents)
                            %  keyboard
                            %end
                            
                            if strcmp(mField,'recog')
                              accField = sprintf('%s_acc',mField);
                              dpField = sprintf('%s_dp',mField);
                            elseif strcmp(mField,'recall')
                              accField = sprintf('%s_spellCorr',mField);
                              dpField = 'NA';
                            end
                            hrField = sprintf('%s_hr',mField);
                            mrField = sprintf('%s_mr',mField);
                            crrField = sprintf('%s_crr',mField);
                            farField = sprintf('%s_far',mField);
                            nTrialsField = sprintf('%s_nTrials',mField);
                            %nCorField = sprintf('%s_nCor',mField);
                            %nIncField = sprintf('%s_nInc',mField);
                            nTargField = sprintf('%s_nTarg',mField);
                            nLureField = sprintf('%s_nLure',mField);
                            nHitField = sprintf('%s_nHit',mField);
                            nMissField = sprintf('%s_nMiss',mField);
                            nCRField = sprintf('%s_nCR',mField);
                            nFAField = sprintf('%s_nFA',mField);
                            rtField = sprintf('%s_rt',mField);
                            
                            %if strcmp(mField,'recog')
                            %  accField = 'acc';
                            %elseif strcmp(mField,'recall')
                            %  accField = 'spellCorr';
                            %end
                            %hrField = 'hr';
                            %farField = 'far';
                            %dpField = 'dp';
                            %nTrialsField = 'nTrials';
                            %nCorField = 'nCor';
                            %nIncField = 'nInc';
                            %rtField = 'rt';
                            
                            results.(sesName).(fn).(lagStr).(i_catStrs{im}) = accAndRT(targEvents,lureEvents,sub,results.(sesName).(fn).(lagStr).(i_catStrs{im}),partialCredit,mField,...
                              accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);
                            theseResults = results.(sesName).(fn).(lagStr).(i_catStrs{im}).(mField);
                            if printResults
                              fprintf('\t%s %s\n',i_catStrs{im},mField);
                              fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',theseResults.(hrField)(sub),theseResults.(nHitField)(sub),(theseResults.(nTargField)(sub)));
                              if ~strcmp(dpField,'NA')
                                fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',theseResults.(farField)(sub),theseResults.(nFAField)(sub),(theseResults.(nLureField)(sub)));
                                fprintf('\t\td'':\t\t%.2f\n',theseResults.(dpField)(sub));
                              end
                              fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',theseResults.(sprintf('%s_hit',rtField))(sub),theseResults.(sprintf('%s_miss',rtField))(sub));
                              if ~strcmp(dpField,'NA')
                                fprintf(', cr: %.2f, fa: %.2f\n',theseResults.(sprintf('%s_cr',rtField))(sub),theseResults.(sprintf('%s_fa',rtField))(sub));
                              else
                                fprintf('\n');
                              end
                            end
                          end % mf
                          
                        end % im
                      end
                      
                    end % lc
                    
                end % switch phaseName
                
              else
                fprintf('%s: %s, session_%d %s: phase %s is incomplete.\n',mfilename,expParam.subject,sesNum,sesName,fn);
              end % phaseName complete
            else
              fprintf('%s: %s, session_%d %s: phase %s does not exist.\n',mfilename,expParam.subject,sesNum,sesName,fn);
            end % field doesn't exist
          end % isExp
          
        end % for pha
        fprintf('\n');
        
      end % for ses
    else
      fprintf('\t%s has not completed all sessions. Not including in results.\n',subjects{sub});
    end % onlyComplete check
  end % for sub
  fprintf('Done processing data for experiment %s.\n\n',expName);
  
  if saveResults
    matFileName = fullfile(dataroot,sprintf('%s_behav_results.mat',expName));
    fprintf('Saving results struct to %s...',matFileName);
    save(matFileName,'results');
    fprintf('Done.\n');
  end
end

if saveResults
  textFileName = fullfile(dataroot,sprintf('%s_behav_results.txt',expName));
  printResultsToFile(dataroot,subjects,results,textFileName,collapsePhases,collapseCategories,separateCategories,templateSubject);
end

end % function

%% print to file

function printResultsToFile(dataroot,subjects,results,fileName,collapsePhases,collapseCategories,separateCategories,templateSubject)

fid = fopen(fileName,'wt');

mainToPrint = {'recog','recall'};

generic_dataToPrint = {'nTrials','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt_hit','rt_miss','rt_cr','rt_far'};
dataToPrint = {...
  {'recog_nTrials','recog_nTarg','recog_nLure','recog_nHit','recog_nMiss','recog_nCR','recog_nFA','recog_hr','recog_mr','recog_crr','recog_far','recog_dp','recog_rt_hit','recog_rt_miss','recog_rt_cr','recog_rt_far'} ...
  {'recall_nTrials','recall_nTarg','recall_nLure','recall_nHit','recall_nMiss','recall_nCR','recall_nFA','recall_hr','recall_mr','recall_crr','recall_far','recall_dp','recall_rt_hit','recall_rt_miss','recall_rt_cr','recall_rt_far'} ...
  };

% generic_dataToPrint = {'nCor','nInc','hr','far','dp','rt_hit','rt_miss','rt_cr','rt_far'};
% dataToPrint = {...
%   {'recog_nCor','recog_nInc','recog_hr','recog_far','recog_dp','recog_rt_hit','recog_rt_miss'},...
%   {'recall_nCor','recall_nInc','recall_hr','recall_far','recall_dp','recall_rt_hit','recall_rt_miss'}};

% generic_dataToPrint = {'nTrials','nCor','acc','hr','far','dp','rt','rt_cor','rt_inc'};
% dataToPrint = {...
%   {'recog_nTrials','recog_nCor','recog_acc','recog_hr','recog_far','recog_dp','recog_rt','recog_rt_cor','recog_rt_inc'},...
%   {'recall_nTrials','recall_nCor','recall_spellCorr','recall_hr','recall_far','recall_dp','recall_rt','recall_rt_cor','recall_rt_inc'}};

% use a subject's files for initialization
if length(subjects) > 5
  tempSub = templateSubject;
else
  tempSub = subjects{end};
end
tempSub = ismember(subjects,tempSub);

subDir = fullfile(dataroot,subjects{tempSub});
expParamFile = fullfile(subDir,'experimentParams.mat');
if exist(expParamFile,'file')
  load(expParamFile)
else
  error('experiment parameter file does not exist: %s',expParamFile);
end
eventsFile = fullfile(subDir,'events','events.mat');
if exist(eventsFile,'file')
  load(eventsFile,'events');
else
  error('events file does not exist: %s',eventsFile);
end

for sesNum = 1:length(expParam.sesTypes)
  % set the subject events file
  sesName = expParam.sesTypes{sesNum};
  
  uniquePhaseNames = unique(expParam.session.(sesName).phases,'stable');
  uniquePhaseCounts = zeros(1,length(unique(expParam.session.(sesName).phases,'stable')));
  
  fprintf(fid,'session\t%s\n',sesName);
  
  if collapsePhases
    processThesePhases = uniquePhaseNames;
  else
    processThesePhases = expParam.session.(sesName).phases;
  end
  
  for pha = 1:length(processThesePhases)
    phaseName = expParam.session.(sesName).phases{pha};
    
    % find out where this phase occurs in the list of unique phases
    uniquePhaseInd = find(ismember(uniquePhaseNames,phaseName));
    % increase the phase count for that phase
    uniquePhaseCounts(uniquePhaseInd) = uniquePhaseCounts(uniquePhaseInd) + 1;
    % set the phase count
    phaseCount = uniquePhaseCounts(uniquePhaseInd);
    
    % accidently set isExp=true for prac_distract_math
    if ~isempty(strfind(phaseName,'prac_')) && cfg.stim.(sesName).(phaseName)(phaseCount).isExp
      cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
    end
    
    if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
      
      if collapsePhases
        fn = phaseName;
      else
        % set the phase name with phase count
        fn = sprintf(sprintf('%s_%d',phaseName,phaseCount));
      end
      
      if isfield(events.(sesName),fn)
        
        fprintf(fid,'phase\t%s\n',fn);
        
        switch phaseName
          case {'cued_recall'}
            targEvents = events.(sesName).(fn).data([events.(sesName).(fn).data.targ]);
            lagConds = unique([targEvents.lag]);
            
            % lureEvents = events.(sesName).(fn).data(~[events.(sesName).(fn).data.targ]);
            
            for lc = 1:length(lagConds)
              
              % choose the training condition
              if length(lagConds(lc)) == 1
                if lagConds(lc) > 0
                  %lagStr = sprintf('lag%d',lagConds(lc));
                  lagStr = 'spaced';
                elseif lagConds(lc) == 0
                  lagStr = 'massed';
                elseif lagConds(lc) == -1
                  lagStr = 'once';
                end
              elseif length(lagConds(lc)) > 1
                lagStr = 'all';
              end
              
              if collapseCategories
                % overall
                headerCell = {{lagStr},mainToPrint};
                [headerStr] = setHeaderStr(headerCell,length(generic_dataToPrint));
                fprintf(fid,sprintf('\t%s\n',headerStr));
                [headerStr] = setHeaderStr({generic_dataToPrint},1);
                headerStr = sprintf('\t%s',headerStr);
                headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
                fprintf(fid,sprintf('%s\n',headerStr));
                
                for sub = 1:length(subjects)
                  dataStr = subjects{sub};
                  for mf = 1:length(mainToPrint)
                    [dataStr] = setDataStr(dataStr,{sesName,fn,lagStr,mainToPrint{mf}},results,sub,dataToPrint{mf});
                  end
                  fprintf(fid,sprintf('%s\n',dataStr));
                end
              end
              
              % separate categories
              i_catStrs = unique({targEvents.i_catStr},'stable');
              if length(i_catStrs) > 1 && separateCategories
                headerCell = {{lagStr},i_catStrs,mainToPrint};
                [headerStr] = setHeaderStr(headerCell,length(generic_dataToPrint));
                fprintf(fid,sprintf('\t%s\n',headerStr));
                [headerStr] = setHeaderStr({generic_dataToPrint},1);
                headerStr = sprintf('\t%s',headerStr);
                headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
                fprintf(fid,sprintf('%s\n',headerStr));
                
                for sub = 1:length(subjects)
                  dataStr = subjects{sub};
                  for im = 1:length(i_catStrs)
                    for mf = 1:length(mainToPrint)
                      [dataStr] = setDataStr(dataStr,{sesName,fn,lagStr,i_catStrs{im},mainToPrint{mf}},results,sub,dataToPrint{mf});
                    end
                  end
                  fprintf(fid,sprintf('%s\n',dataStr));
                end
              end
              
              if lc ~= length(lagConds)
                fprintf(fid,'\n');
              end
              
            end % lc
            
            %             end
            
            %           case {'name', 'nametrain', 'prac_name'}
            %             if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
            %               nBlocks = 1;
            %             else
            %               nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
            %             end
            %
            %             if nBlocks > 1
            %               blockStr = cell(1,nBlocks);
            %               for b = 1:nBlocks
            %                 blockStr{b} = sprintf('b%d',b);
            %               end
            %               headerCell = {blockStr,mainToPrint};
            %               [headerStr] = setHeaderStr(headerCell,length(dataToPrint));
            %               fprintf(fid,sprintf('\t%s\n',headerStr));
            %               [headerStr] = setHeaderStr({dataToPrint},1);
            %               headerStr = sprintf('\t%s',headerStr);
            %               headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
            %               fprintf(fid,sprintf('%s\n',headerStr));
            %
            %               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %               for sub = 1:length(subjects)
            %                 dataStr = subjects{sub};
            %                 for b = 1:nBlocks
            %                   for mf = 1:length(mainToPrint)
            %                     [dataStr] = setDataStr(dataStr,{sesName,fn,sprintf('b%d',b),mainToPrint{mf}},results,sub,dataToPrint);
            %                   end
            %                 end
            %                 fprintf(fid,sprintf('%s\n',dataStr));
            %               end
            %             else
            %               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %               headerCell = {mainToPrint};
            %               [headerStr] = setHeaderStr(headerCell,length(dataToPrint));
            %               fprintf(fid,sprintf('\t%s\n',headerStr));
            %               [headerStr] = setHeaderStr({dataToPrint},1);
            %               headerStr = sprintf('\t%s',headerStr);
            %               headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
            %               fprintf(fid,sprintf('%s\n',headerStr));
            %
            %               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %               for sub = 1:length(subjects)
            %                 dataStr = subjects{sub};
            %                 for mf = 1:length(mainToPrint)
            %                   [dataStr] = setDataStr(dataStr,{sesName,fn,mainToPrint{mf}},results,sub,dataToPrint);
            %                 end
            %                 fprintf(fid,sprintf('%s\n',dataStr));
            %               end
            %
            %             end
        end % switch phaseName
        fprintf(fid,'\n');
      else
        fprintf('printResultsToFile: %s, %s: phase %s does not exist.\n',expParam.subject,sesName,fn);
      end
    end
  end % phases
end % sessions

% close out the results file
fprintf('Saving results to file: %s...',fileName);
fclose(fid);
fprintf('Done.\n');

end

%% create the header string

function [headerStr] = setHeaderStr(headerCell,nTabs)

% borrowed from http://stackoverflow.com/questions/8492277/matlab-combinations-of-an-arbitrary-number-of-cell-arrays
sizeVec = cellfun('prodofsize', headerCell);
indices = fliplr(arrayfun(@(n) {1:n}, sizeVec));
[indices{:}] = ndgrid(indices{:});
headerMat = cellfun(@(c,i) {reshape(c(i(:)), [], 1)}, headerCell, fliplr(indices));
headerMat = [headerMat{:}];

headerStr = headerMat{1,1};
if size(headerMat,2) > 1
  for j = 2:size(headerMat,2)
    headerStr = cat(2,headerStr,' ',headerMat{1,j});
  end
end

for i = 2:size(headerMat,1)
  thisStr = [];
  for j = 1:size(headerMat,2)
    thisStr = cat(2,thisStr,' ',headerMat{i,j});
  end
  thisStr = thisStr(2:end);
  if ~isempty(nTabs) && nTabs > 0
    thisStr = sprintf('%s%s',repmat('\t',1,nTabs),thisStr);
  end
  headerStr = sprintf('%s%s',headerStr,thisStr);
end

end

%% create the data string

function [dataStr] = setDataStr(dataStr,structFields,results,sub,dataToPrint) %#ok<INUSL>

theseResults = eval(sprintf('results%s',sprintf(repmat('.%s',1,length(structFields)),structFields{:})));

for i = 1:length(dataToPrint)
  if ~isnan(theseResults.(dataToPrint{i})(sub))
    dataStr = sprintf('%s\t%.4f',dataStr,theseResults.(dataToPrint{i})(sub));
  else
    dataStr = sprintf('%s\t',dataStr);
  end
end

end

%% Calculate accuracy and reaction time

function inputStruct = accAndRT(targEv,lureEv,sub,inputStruct,partialCredit,destField,accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField)
% function inputStruct = accAndRT(targEv,lureEv,sub,inputStruct,partialCredit,destField,accField,hrField,farField,dpField,nTrialsField,nCorField,nIncField,rtField)

if ~exist('partialCredit','var') || isempty(partialCredit)
  partialCredit = true;
end
if ~exist('accField','var') || isempty(accField)
  accField = 'acc';
end
if ~exist('hrField','var') || isempty(hrField)
  hrField = 'hr';
end
if ~exist('mrField','var') || isempty(mrField)
  mrField = 'mr';
end
if ~exist('crrField','var') || isempty(crrField)
  crrField = 'crr';
end
if ~exist('farField','var') || isempty(farField)
  farField = 'far';
end
if ~exist('dpField','var') || isempty(dpField)
  dpField = 'dp';
end
if ~exist('nTrialsField','var') || isempty(nTrialsField)
  nTrialsField = 'nTrials';
end
if ~exist('nTargField','var') || isempty(nTargField)
  nTargField = 'nTarg';
end
if ~exist('nLureField','var') || isempty(nLureField)
  nLureField = 'nLure';
end
if ~exist('nHitField','var') || isempty(nHitField)
  nHitField = 'nHit';
end
if ~exist('nMissField','var') || isempty(nMissField)
  nMissField = 'nMiss';
end
if ~exist('nCRField','var') || isempty(nCRField)
  nCRField = 'nCR';
end
if ~exist('nFAField','var') || isempty(nFAField)
  nFAField = 'nFA';
end
% if ~exist('nCorField','var') || isempty(nCorField)
%   nCorField = 'nCor';
% end
% if ~exist('nIncField','var') || isempty(nIncField)
%   nIncField = 'nInc';
% end
if ~exist('rtField','var') || isempty(rtField)
  rtField = 'rt';
end

if ~isfield(inputStruct,destField)
  error('input structure does not have field called ''%s''!',destField);
end

% trial counts
nTrials = length(targEv) + length(lureEv);
inputStruct.(destField).(nTrialsField)(sub) = nTrials;

inputStruct.(destField).(nTargField)(sub) = length(targEv);
inputStruct.(destField).(nLureField)(sub) = length(lureEv);

% separate events
if partialCredit
  hitEv = targEv([targEv.(accField)] > 0);
  missEv = targEv([targEv.(accField)] == 0);
  
  if ~strcmp(dpField,'NA')
    crEv = lureEv([lureEv.(accField)] > 0);
    faEv = lureEv([lureEv.(accField)] == 0);
  else
    crEv = [];
    faEv = [];
  end
else
  hitEv = targEv([targEv.(accField)] == 1);
  missEv = targEv([targEv.(accField)] < 1);
  
  if ~strcmp(dpField,'NA')
    crEv = lureEv([lureEv.(accField)] == 1);
    faEv = lureEv([lureEv.(accField)] < 1);
  else
    crEv = [];
    faEv = [];
  end
end

% inputStruct.(destField).(nCorField)(sub) = length(hitEv) + length(crEv);
% inputStruct.(destField).(nIncField)(sub) = length(missEv) + length(faEv);

inputStruct.(destField).(nHitField)(sub) = length(hitEv);
inputStruct.(destField).(nMissField)(sub) = length(missEv);
inputStruct.(destField).(nCRField)(sub) = length(crEv);
inputStruct.(destField).(nFAField)(sub) = length(faEv);

% % overall accuracy
% inputStruct.(destField).(accField)(sub) = inputStruct.(destField).(nCorField)(sub) / nTrials;

% d-prime; adjust for perfect performance, choose 1 of 2 strategies
% (Macmillan & Creelman, 2005; p. 8-9)
strategy = 2;

hr = length(hitEv) / length(targEv);
mr = length(missEv) / length(targEv);
if ~strcmp(dpField,'NA')
  crr = length(crEv) / length(lureEv);
  far = length(faEv) / length(lureEv);
end

if hr == 1
  warning('HR is 1.0! Correcting...');
  if strategy == 1
    hr = 1 - (1 / (2 * length(targEv)));
  elseif strategy == 2
    % (Hautus, 1995; Miller, 1996)
    hr = (length(hitEv) + 0.5) / (length(targEv) + 1);
  end
elseif hr == 0
  warning('HR is 0! Correcting...');
  if strategy == 1
    hr = 1 / (2 * length(targEv));
  elseif strategy == 2
    % (Hautus, 1995; Miller, 1996)
    hr = (length(hitEv) + 0.5) / (length(targEv) + 1);
  end
end
if ~strcmp(dpField,'NA')
  if far == 1
    warning('FAR is 1! Correcting...');
    if strategy == 1
      far = 1 - (1 / (2 * length(lureEv)));
    elseif strategy == 2
      % (Hautus, 1995; Miller, 1996)
      far = (length(faEv) + 0.5) / (length(lureEv) + 1);
    end
  elseif far == 0
    warning('FAR is 0! Correcting...');
    if strategy == 1
      far = 1 / (2 * length(lureEv));
    elseif strategy == 2
      % (Hautus, 1995; Miller, 1996)
      far = (length(faEv) + 0.5) / (length(lureEv) + 1);
    end
  end
end

inputStruct.(destField).(hrField)(sub) = hr;
inputStruct.(destField).(mrField)(sub) = mr;
if ~strcmp(dpField,'NA')
  inputStruct.(destField).(farField)(sub) = far;
  inputStruct.(destField).(crrField)(sub) = crr;
  
  zhr = norminv(hr,0,1);
  zfar = norminv(far,0,1);
  
  inputStruct.(destField).(dpField)(sub) = zhr - zfar;
end

% % If there are only two points, the slope will always be 1, and d'=da, so
% % we don't need this
% %
% % Find da: Macmillan & Creelman (2005), p. 61--62
% %
% % slope of zROC
% s = zhr/-zfar;
% inputStruct.(destField).da(sub) = (2 / (1 + (s^2)))^(1/2) * (zhr - (s*zfar));

% RT
inputStruct.(destField).(sprintf('%s_hit',rtField))(sub) = mean([hitEv.(rtField)]);
inputStruct.(destField).(sprintf('%s_miss',rtField))(sub) = mean([missEv.(rtField)]);
if ~strcmp(dpField,'NA')
  inputStruct.(destField).(sprintf('%s_cr',rtField))(sub) = mean([crEv.(rtField)]);
  inputStruct.(destField).(sprintf('%s_fa',rtField))(sub) = mean([faEv.(rtField)]);
end

end


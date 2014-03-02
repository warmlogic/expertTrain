function [results] = space_processData(results,dataroot,subjects,collapsePhases,collapseCategories,separateCategories,onlyCompleteSub,printResults,saveResults,partialCredit,prependDestField)
% function [results] = space_processData(results,dataroot,subjects,collapsePhases,collapseCategories,separateCategories,onlyCompleteSub,printResults,saveResults,partialCredit,prependDestField)
%
% Processes data into basic measures like accuracy, response time, and d-prime
%
% e.g.,
% [results] = space_processData([],[],[],true,true,true,true,false,true,true,true);

if ~exist('prependDestField','var') || isempty(prependDestField)
  prependDestField = true;
end

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
    'SPACE037';
    'SPACE039';
    };
end

% use a specific subject's files as a template for loading data
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
  dataFields = {...
    {'nTrial','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt','rt_hit','rt_miss','rt_cr','rt_fa','c','Pr','Br'} ...
    {'nTrial','nTarg','nHit','nMiss','hr','mr','rt','rt_hit','rt_miss'} ...
    };
  
  % % remove these fields when there's no noise distribution (i.e., recall
  % % events)
  % rmfieldNoNoise = {'nLure','nCR','nFA','crr','far','dp','rt_cr','rt_fa','c','Pr','Br'};
  
  % categories = [1, 2];
  % categoryStr = {'faces', 'houses'};
  
  %% initialize to store the data
  
  % use a specific subject's files as a template for loading data
  if length(subjects) > 5
    templateSubIndex = templateSubject;
  else
    templateSubIndex = subjects{end};
  end
  templateSubIndex = ismember(subjects,templateSubIndex);
  
  subDir = fullfile(dataroot,subjects{templateSubIndex});
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
    uniquePhaseCounts = zeros(1,length(uniquePhaseNames));
    
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
          
          switch phaseName
            case {'cued_recall'}
              targEvents = events.(sesName).(fn).data([events.(sesName).(fn).data.targ]);
              %lureEvents = events.(sesName).(fn).data(~[events.(sesName).(fn).data.targ]);
              
              lagConds = unique([targEvents.lag],'sorted');
              
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
                    for df = 1:length(dataFields{mf})
                      dField = dataFields{mf}{df};
                      
                      results.(sesName).(fn).(lagStr).(mField).(sprintf('%s_%s',mField,dField)) = nan(length(subjects),1);
                    end
                  end
                end
                
                % image categories
                i_catStrs = unique({targEvents.i_catStr},'sorted');
                if length(i_catStrs) > 1 && separateCategories
                  for im = 1:length(i_catStrs)
                    for mf = 1:length(mainFields)
                      mField = mainFields{mf};
                      for df = 1:length(dataFields{mf})
                        dField = dataFields{mf}{df};
                        
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
        uniquePhaseCounts = zeros(1,length(uniquePhaseNames));
        
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
                    lagConds = unique([thisPhaseEv([thisPhaseEv.targ]).lag],'sorted');
                    
                    % exclude missed responses ({'NO_RESPONSE', 'none'})
                    thisPhaseEv = thisPhaseEv(~ismember({thisPhaseEv.recog_resp},{'NO_RESPONSE', 'none'}));
                    
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
                          elseif strcmp(mField,'recall')
                            accField = sprintf('%s_spellCorr',mField);
                            lureEvents = [];
                          end
                          
                          results.(sesName).(fn).(lagStr) = accAndRT(targEvents,lureEvents,sub,results.(sesName).(fn).(lagStr),...
                            partialCredit,mField,accField,dataFields{mf},prependDestField);
                          
                          if printResults
                            theseResults = results.(sesName).(fn).(lagStr).(mField);
                            fprintf('\t%s\n',mField);
                            
                            if prependDestField
                              hrField = sprintf('%s_hr',mField);
                            else
                              hrField = 'hr';
                            end
                            if prependDestField
                              nHitField = sprintf('%s_nHit',mField);
                            else
                              nHitField = 'nHit';
                            end
                            if prependDestField
                              nTargField = sprintf('%s_nTarg',mField);
                            else
                              nTargField = 'nTarg';
                            end
                            
                            fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',theseResults.(hrField)(sub),theseResults.(nHitField)(sub),(theseResults.(nTargField)(sub)));
                            if ~isempty(lureEvents)
                              if prependDestField
                                farField = sprintf('%s_far',mField);
                              else
                                farField = 'far';
                              end
                              if prependDestField
                                nFAField = sprintf('%s_nFA',mField);
                              else
                                nFAField = 'nFA';
                              end
                              if prependDestField
                                nLureField = sprintf('%s_nLure',mField);
                              else
                                nLureField = 'nLure';
                              end
                              if prependDestField
                                dpField = sprintf('%s_dp',mField);
                              else
                                dpField = 'dp';
                              end
                              fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',theseResults.(farField)(sub),theseResults.(nFAField)(sub),(theseResults.(nLureField)(sub)));
                              fprintf('\t\td'':\t\t%.2f\n',theseResults.(dpField)(sub));
                            end
                            
                            if prependDestField
                              rtField = sprintf('%s_rt',mField);
                            else
                              rtField = 'rt';
                            end
                            fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',theseResults.(sprintf('%s_hit',rtField))(sub),theseResults.(sprintf('%s_miss',rtField))(sub));
                            if ~isempty(lureEvents)
                              fprintf(', cr: %.2f, fa: %.2f\n',theseResults.(sprintf('%s_cr',rtField))(sub),theseResults.(sprintf('%s_fa',rtField))(sub));
                            else
                              fprintf('\n');
                            end
                          end
                        end
                      end
                      
                      % accuracy for the different image categories
                      i_catStrs = unique({targEvents.i_catStr},'sorted');
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
                            elseif strcmp(mField,'recall')
                              accField = sprintf('%s_spellCorr',mField);
                              lureEvents = [];
                            end
                            
                            results.(sesName).(fn).(lagStr).(i_catStrs{im}) = accAndRT(targEvents,lureEvents,sub,results.(sesName).(fn).(lagStr).(i_catStrs{im}),...
                              partialCredit,mField,accField,dataFields{mf},prependDestField);
                            
                            if printResults
                              theseResults = results.(sesName).(fn).(lagStr).(i_catStrs{im}).(mField);
                              
                              fprintf('\t%s %s\n',i_catStrs{im},mField);
                              
                              if prependDestField
                                hrField = sprintf('%s_hr',mField);
                              else
                                hrField = 'hr';
                              end
                              if prependDestField
                                nHitField = sprintf('%s_nHit',mField);
                              else
                                nHitField = 'nHit';
                              end
                              if prependDestField
                                nTargField = sprintf('%s_nTarg',mField);
                              else
                                nTargField = 'nTarg';
                              end
                              
                              fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',theseResults.(hrField)(sub),theseResults.(nHitField)(sub),(theseResults.(nTargField)(sub)));
                              if ~isempty(lureEvents)
                                if prependDestField
                                  farField = sprintf('%s_far',mField);
                                else
                                  farField = 'far';
                                end
                                if prependDestField
                                  nFAField = sprintf('%s_nFA',mField);
                                else
                                  nFAField = 'nFA';
                                end
                                if prependDestField
                                  nLureField = sprintf('%s_nLure',mField);
                                else
                                  nLureField = 'nLure';
                                end
                                if prependDestField
                                  dpField = sprintf('%s_dp',mField);
                                else
                                  dpField = 'dp';
                                end
                                fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',theseResults.(farField)(sub),theseResults.(nFAField)(sub),(theseResults.(nLureField)(sub)));
                                fprintf('\t\td'':\t\t%.2f\n',theseResults.(dpField)(sub));
                              end
                              
                              if prependDestField
                                rtField = sprintf('%s_rt',mField);
                              else
                                rtField = 'rt';
                              end
                              fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',theseResults.(sprintf('%s_hit',rtField))(sub),theseResults.(sprintf('%s_miss',rtField))(sub));
                              if ~isempty(lureEvents)
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
    if collapsePhases
      matFileName = sprintf('%s_behav_results_collapsed.mat',expName);
    else
      matFileName = sprintf('%s_behav_results.mat',expName);
    end
    matFileName = fullfile(dataroot,matFileName);
    
    fprintf('Saving results struct to %s...',matFileName);
    save(matFileName,'results');
    fprintf('Done.\n');
  end
end

if saveResults
  if collapsePhases
    textFileName = sprintf('%s_behav_results_collapsed.txt',expName);
  else
    textFileName = sprintf('%s_behav_results.txt',expName);
  end
  textFileName = fullfile(dataroot,textFileName);
  
  printResultsToFile(dataroot,subjects,results,mainFields,dataFields,prependDestField,textFileName,collapsePhases,collapseCategories,separateCategories,templateSubject);
end

end % function

%% print to file

function printResultsToFile(dataroot,subjects,results,mainToPrint,dataToPrint,prependDestField,textFileName,collapsePhases,collapseCategories,separateCategories,templateSubject)

fprintf('Saving results to text file: %s...',textFileName);

% use a specific subject's files as a template for loading data
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

fid = fopen(textFileName,'wt');

for sesNum = 1:length(expParam.sesTypes)
  % set the subject events file
  sesName = expParam.sesTypes{sesNum};
  
  uniquePhaseNames = unique(expParam.session.(sesName).phases,'stable');
  uniquePhaseCounts = zeros(1,length(uniquePhaseNames));
  
  fprintf(fid,'session\t%s\n',sesName);
  
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
        
        fprintf(fid,'phase\t%s\n',fn);
        
        switch phaseName
          case {'cued_recall'}
            targEvents = events.(sesName).(fn).data([events.(sesName).(fn).data.targ]);
            lagConds = unique([targEvents.lag],'sorted');
            
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
                nTabs = nan(1,length(dataToPrint));
                nTabInd = 0;
                for d = 1:length(dataToPrint)
                  nTabInd = nTabInd + 1;
                  nTabs(nTabInd) = length(dataToPrint{d});
                end
                headerCell = {{lagStr},mainToPrint};
                [headerStr] = setHeaderStr(headerCell,nTabs);
                fprintf(fid,sprintf('\t%s\n',headerStr));
                
                for sub = 1:length(subjects)
                  % print the header string only before the first sub
                  if sub == 1
                    for mf = 1:length(mainToPrint)
                      [headerStr] = setHeaderStr(dataToPrint(mf),1);
                      headerStr = sprintf('\t%s',headerStr);
                      fprintf(fid,sprintf('%s',headerStr));
                    end
                    fprintf(fid,'\n');
                  end
                  
                  dataStr = subjects{sub};
                  for mf = 1:length(mainToPrint)
                    if prependDestField
                      subDataToPrint = strcat(sprintf('%s_',mainToPrint{mf}),dataToPrint{mf});
                    else
                      subDataToPrint = dataToPrint{mf};
                    end
                    
                    [dataStr] = setDataStr(dataStr,{sesName,fn,lagStr,mainToPrint{mf}},results,sub,subDataToPrint);
                  end
                  fprintf(fid,sprintf('%s\n',dataStr));
                end
              end
              
              % separate categories
              i_catStrs = unique({targEvents.i_catStr},'sorted');
              if length(i_catStrs) > 1 && separateCategories
                nTabs = nan(1,length(dataToPrint) * length(i_catStrs));
                nTabInd = 0;
                for ic = 1:length(i_catStrs)
                  for d = 1:length(dataToPrint)
                    nTabInd = nTabInd + 1;
                    nTabs(nTabInd) = length(dataToPrint{d});
                  end
                end
                headerCell = {{lagStr},i_catStrs,mainToPrint};
                [headerStr] = setHeaderStr(headerCell,nTabs);
                fprintf(fid,sprintf('\t%s\n',headerStr));
                
                for sub = 1:length(subjects)
                  % print the header string only before the first sub
                  if sub == 1
                    for ic = 1:length(i_catStrs)
                      for mf = 1:length(mainToPrint)
                        [headerStr] = setHeaderStr(dataToPrint(mf),1);
                        headerStr = sprintf('\t%s',headerStr);
                        fprintf(fid,sprintf('%s',headerStr));
                      end
                    end
                    fprintf(fid,'\n');
                  end
                  
                  dataStr = subjects{sub};
                  for im = 1:length(i_catStrs)
                    for mf = 1:length(mainToPrint)
                      if prependDestField
                        subDataToPrint = strcat(sprintf('%s_',mainToPrint{mf}),dataToPrint{mf});
                      else
                        subDataToPrint = dataToPrint{mf};
                      end
                      [dataStr] = setDataStr(dataStr,{sesName,fn,lagStr,i_catStrs{im},mainToPrint{mf}},results,sub,subDataToPrint);
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
  if ~isempty(nTabs)
    if length(nTabs) > 1 && nTabs(i-1) > 0
      thisStr = sprintf('%s%s',repmat('\t',1,nTabs(i-1)),thisStr);
    elseif length(nTabs) == 1 && nTabs > 0
      thisStr = sprintf('%s%s',repmat('\t',1,nTabs),thisStr);
    end
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

function inputStruct = accAndRT(targEv,lureEv,sub,inputStruct,partialCredit,destField,accField,dataFields,prependDestField)

if ~exist('prependDestField','var') || isempty(prependDestField)
  prependDestField = false;
end

if ~isfield(inputStruct,destField)
  error('input structure does not have field called ''%s''!',destField);
end

% concatenate the events together for certain measures
allEv = cat(1,targEv,lureEv);

% trial counts
thisStr = 'nTrial';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = length(allEv);
end

thisStr = 'nTarg';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = length(targEv);
end

if ~isempty(lureEv)
  thisStr = 'nLure';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub) = length(lureEv);
  end
end

% separate events
if partialCredit
  hitEv = targEv([targEv.(accField)] > 0);
  missEv = targEv([targEv.(accField)] == 0);
  
  if ~isempty(lureEv)
    crEv = lureEv([lureEv.(accField)] > 0);
    faEv = lureEv([lureEv.(accField)] == 0);
  end
else
  hitEv = targEv([targEv.(accField)] == 1);
  missEv = targEv([targEv.(accField)] < 1);
  
  if ~isempty(lureEv)
    crEv = lureEv([lureEv.(accField)] == 1);
    faEv = lureEv([lureEv.(accField)] < 1);
  end
end

thisStr = 'nHit';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = length(hitEv);
end

thisStr = 'nMiss';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = length(missEv);
end

if ~isempty(lureEv)
  thisStr = 'nCR';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub) = length(crEv);
  end
  
  thisStr = 'nFA';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub) = length(faEv);
  end
end

hr = length(hitEv) / length(targEv);
mr = length(missEv) / length(targEv);
if ~isempty(lureEv)
  crr = length(crEv) / length(lureEv);
  far = length(faEv) / length(lureEv);
end

% only adjust HR if also adjusting FAR
if ~isempty(lureEv)
  % d-prime; adjust for perfect performance, choose 1 of 2 strategies
  % (Macmillan & Creelman, 2005; p. 8-9)
  strategy = 2;
  
  if hr == 1
    warning('HR is 1.0! Correcting...');
    if strategy == 1
      hr = 1 - (1 / (2 * length(targEv)));
      mr = 1 / (2 * length(targEv));
    elseif strategy == 2
      % (Hautus, 1995; Miller, 1996)
      hr = (length(hitEv) + 0.5) / (length(targEv) + 1);
      mr = (length(missEv) + 0.5) / (length(targEv) + 1);
    end
  elseif hr == 0
    warning('HR is 0! Correcting...');
    if strategy == 1
      hr = 1 / (2 * length(targEv));
      mr = 1 - (1 / (2 * length(targEv)));
    elseif strategy == 2
      % (Hautus, 1995; Miller, 1996)
      hr = (length(hitEv) + 0.5) / (length(targEv) + 1);
      mr = (length(missEv) + 0.5) / (length(targEv) + 1);
    end
  end
  
  if far == 1
    warning('FAR is 1! Correcting...');
    if strategy == 1
      far = 1 - (1 / (2 * length(lureEv)));
      crr = 1 / (2 * length(lureEv));
    elseif strategy == 2
      % (Hautus, 1995; Miller, 1996)
      far = (length(faEv) + 0.5) / (length(lureEv) + 1);
      crr = (length(crEv) + 0.5) / (length(lureEv) + 1);
    end
  elseif far == 0
    warning('FAR is 0! Correcting...');
    if strategy == 1
      far = 1 / (2 * length(lureEv));
      crr = 1 - (1 / (2 * length(lureEv)));
    elseif strategy == 2
      % (Hautus, 1995; Miller, 1996)
      far = (length(faEv) + 0.5) / (length(lureEv) + 1);
      crr = (length(crEv) + 0.5) / (length(lureEv) + 1);
    end
  end
end

thisStr = 'hr';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = hr;
end

thisStr = 'mr';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = mr;
end

if ~isempty(lureEv)
  thisStr = 'far';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub) = far;
  end
  
  thisStr = 'crr';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub) = crr;
  end
  
  thisStr = 'dp';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    zhr = norminv(hr,0,1);
    zfar = norminv(far,0,1);
    
    inputStruct.(destField).(thisField)(sub) = zhr - zfar;
  end
  
  % response bias: c (criterion) (Macmillan & Creelman, 2005, p. 29)
  %
  % positive/conservative bias indicates a tendency to say 'new', whereas
  % negative/liberal bias indicates a tendency to say 'old'
  thisStr = 'c';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    c = -0.5 * (norminv(hr,0,1) + norminv(far,0,1));
    
    inputStruct.(destField).(thisField)(sub) = c;
  end
  
  % discrimination index (Pr)
  %
  % Mecklinger et al. (2007): Source-retrieval requirements influence late
  % ERP and EEG memory effects
  %
  % Corwin (1994): On measuring discrimination and response bias: Unequal
  % numbers of targets and distractors and two classes of distractors
  %
  % Snodgrass & Corwin (1988): Pragmatics of measuring recognition memory:
  % applications to dementia and amnesia
  thisStr = 'Pr';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    Pr = hr - far;
    
    inputStruct.(destField).(thisField)(sub) = Pr;
  end
  
  % response bias index (Br)
  %
  % Mecklinger et al. (2007): Source-retrieval requirements influence late
  % ERP and EEG memory effects
  %
  % Corwin (1994): On measuring discrimination and response bias: Unequal
  % numbers of targets and distractors and two classes of distractors
  %
  % Snodgrass & Corwin (1988): Pragmatics of measuring recognition memory:
  % applications to dementia and amnesia
  thisStr = 'Br';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    Pr = hr - far;
    Br = far / (1 - Pr);
    
    inputStruct.(destField).(thisField)(sub) = Br;
  end
end

% % If there are only two points, the slope will always be 1, and d'=da, so
% % we don't need this
% %
% % Find da: Macmillan & Creelman (2005), p. 61--62
% %
% % slope of zROC
% thisStr = 'da';
% if any(strcmp(thisStr,dataFields))
%   if prependDestField
%     thisField = sprintf('%s_%s',destField,thisStr);
%   else
%     thisField = thisStr;
%   end
%   s = zhr/-zfar;
%   inputStruct.(destField).(thisField)(sub) = (2 / (1 + (s^2)))^(1/2) * (zhr - (s*zfar));
% end

% Response Times
rtStr = 'rt';
if prependDestField
  rtField = sprintf('%s_%s',destField,rtStr);
else
  rtField = rtStr;
end

thisStr = 'rt';
if any(strcmp(thisStr,dataFields))
  inputStruct.(destField).(rtField)(sub) = mean([allEv.(rtField)]);
end

thisStr = 'rt_hit';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = mean([hitEv.(rtField)]);
end

thisStr = 'rt_miss';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub) = mean([missEv.(rtField)]);
end

if ~isempty(lureEv)
  thisStr = 'rt_cr';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub) = mean([crEv.(rtField)]);
  end
  
  thisStr = 'rt_fa';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub) = mean([faEv.(rtField)]);
  end
end

end


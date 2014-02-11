function [results] = ebird_processData(results,dataroot,subjects,onlyCompleteSub,printResults,saveResults)
% function [results] = ebird_processData(results,dataroot,subjects,onlyCompleteSub,printResults,saveResults)
%
% Processes data into basic measures like accuracy, response time, and d-prime
%
% e.g., [results] = ebird_processData([],[],[],true,false,true);

if ~exist('subjects','var') || isempty(subjects)
  subjects = {
    %'EBIRD049'; % Pilot. (due to short ses1 match, missing ses2 name)
    %'EBIRD002'; % Pilot. (due to short ses1 match, missing ses2 name)
    %'EBIRD003'; % Pilot. (due to missing ses7 name) - NB: LAST PILOT TO BE REPLACED
    %'EBIRD004'; % DNF. Dropout. Last session: 8.
    'EBIRD005';
    %'EBIRD006'; % DNF. Dropout. Last session: 2.
    'EBIRD007';
    'EBIRD008';
    'EBIRD009';
    'EBIRD010';
    'EBIRD011';
    'EBIRD012';
    %'EBIRD013'; % DNF. Dropout. Last session: 5. Lost session 6 in HD crash.
    %'EBIRD014'; % DNF. Rejected. Last session: 1.
    %'EBIRD015'; % DNF. Lost in HD crash.
    %'EBIRD016'; % DNF. Lost in HD crash.
    %'EBIRD017'; % DNF. Lost in HD crash.
    'EBIRD018';
    'EBIRD019';
    'EBIRD020';
    'EBIRD021';
    %'EBIRD022'; % DNF. Dropout. Last session: 8.
    %'EBIRD023'; % DNF. Dropout. Last session: 1.
    'EBIRD024';
    %'EBIRD025'; % In progress. Last session: 8.
    'EBIRD027';
    %'EBIRD029'; % In progress. Last session: 8.
    'EBIRD032';
    'EBIRD034';
    %'EBIRD042'; % In progress. Last session: 8.
    };
end

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

if ~exist('onlyCompleteSub','var') || isempty(onlyCompleteSub)
  onlyCompleteSub = false;
end

if ~exist('printResults','var') || isempty(printResults)
  printResults = true;
end

if ~exist('saveResults','var') || isempty(saveResults)
  saveResults = true;
end

if isempty(results)
  %% some constants
  
  %trainedConds = {1, 0, [1 0]};
  trainedConds = {1, 0};
  
  results = struct;
  
  %mainFields = {'overall','basic','subord'};
  mainFields = {'basic','subord'};
  
  %dataFields = {'nTrial','nCor','nInc','acc','dp','hr','far','rt','rt_cor','rt_inc'};
  dataFields = {...
    {'nTrial','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt_hit','rt_miss','rt_cr','rt_fa'} ...
    {'nTrial','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt_hit','rt_miss','rt_cr','rt_fa'} ...
    {'nTrial','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt_hit','rt_miss','rt_cr','rt_fa'} ...
    };
  
  % set field names
  accField = 'acc';
  dpField = 'dp';
  hrField = 'hr';
  %mrField = 'mr';
  %crrField = 'crr';
  farField = 'far';
  %nTrialsField = 'nTrial';
  nTargField = 'nTarg';
  nLureField = 'nLure';
  nHitField = 'nHit';
  %nMissField = 'nMiss';
  %nCRField = 'nCR';
  nFAField = 'nFA';
  rtField = 'rt';
  
  %% initialize to store the data
  
  % use subject 1's files for initialization
  sub = 1;
  subDir = fullfile(dataroot,subjects{sub});
  expParamFile = fullfile(subDir,'experimentParams.mat');
  if exist(expParamFile,'file')
    load(expParamFile)
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
        
        % set the phase name with phase count
        fn = sprintf(sprintf('%s_%d',phaseName,phaseCount));
        
        switch phaseName
          case {'match', 'prac_match'}
            for t = 1:length(trainedConds)
              % choose the training condition
              if length(trainedConds{t}) == 1
                if trainedConds{t} == 1
                  trainStr = 'trained';
                elseif trainedConds{t} == 0
                  trainStr = 'untrained';
                end
              elseif length(trainedConds{t}) > 1
                trainStr = 'all';
              end
              
              for mf = 1:length(mainFields)
                for df = 1:length(dataFields{mf})
                  results.(sesName).(fn).(trainStr).(mainFields{mf}).(dataFields{mf}{df}) = nan(length(subjects),1);
                end
              end
              
              imgConds = unique({events.(sesName).(fn).data.imgCond});
              if length(imgConds) > 1
                for im = 1:length(imgConds)
                  for mf = 1:length(mainFields)
                    for df = 1:length(dataFields{mf})
                      results.(sesName).(fn).(trainStr).(imgConds{im}).(mainFields{mf}).(dataFields{mf}{df}) = nan(length(subjects),1);
                    end
                  end
                end
              end
            end % for t
          case {'name', 'nametrain', 'prac_name'}
            
            if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
              nBlocks = 1;
            else
              nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
            end
            
            for mf = 1:length(mainFields)
              for df = 1:length(dataFields{mf})
                results.(sesName).(fn).(mainFields{mf}).(dataFields{mf}{df}) = nan(length(subjects),1);
              end
            end
            if nBlocks > 1
              for b = 1:nBlocks
                for mf = 1:length(mainFields)
                  for df = 1:length(dataFields{mf})
                    results.(sesName).(fn).(sprintf('b%d',b)).(mainFields{mf}).(dataFields{mf}{df}) = nan(length(subjects),1);
                  end
                end
              end
            end
        end % switch
      end
    end
  end
  
  %% process the data
  
  fprintf('Processing data for experiment %s...\n',expName);
  
  completeStatus = true(1,length(subjects));
  
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
    
    % if we only want complete subjects and this one is not done, set to F
    if onlyCompleteSub && ~events.isComplete
      completeStatus(sub) = false;
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
            
            % set the phase name with phase count
            fn = sprintf(sprintf('%s_%d',phaseName,phaseCount));
            
            if isfield(events.(sesName),fn)
              
              % collect data if this phase is complete
              if events.(sesName).(fn).isComplete
                fprintf('%s, session_%d %s, %s\n',expParam.subject,sesNum,sesName,fn);
                
                switch phaseName
                  case {'match', 'prac_match'}
                    for t = 1:length(trainedConds)
                      
                      % choose the training condition
                      if length(trainedConds{t}) == 1
                        if trainedConds{t} == 1
                          if printResults
                            fprintf('*** Trained ***\n');
                          end
                          trainStr = 'trained';
                        elseif trainedConds{t} == 0
                          if printResults
                            fprintf('*** Untrained ***\n');
                          end
                          trainStr = 'untrained';
                        end
                      elseif length(trainedConds{t}) > 1
                        if printResults
                          fprintf('Trained and untrained together\n');
                        end
                        trainStr = 'all';
                      end
                      
                      % filter the events that we want
                      matchResp = events.(sesName).(fn).data(ismember({events.(sesName).(fn).data.type},'MATCH_RESP') & ismember([events.(sesName).(fn).data.trained],trainedConds{t}));
                      
                      % exclude missed responses ('none')
                      matchResp = matchResp(~ismember({matchResp.resp},'none'));
                      % % set missing responses to incorrect
                      % noRespInd = find(ismember({matchResp.resp},'none'));
                      % if ~isempty(noRespInd)
                      %   for nr = 1:length(noRespInd)
                      %     matchResp(noRespInd(nr)).acc = 0;
                      %   end
                      % end
                      
                      % overall
                      destField = 'overall';
                      if ismember(destField,mainFields)
                        matchRespSame = matchResp([matchResp.sameSpecies] == 1);
                        matchRespDiff = matchResp([matchResp.sameSpecies] == 0);
                        
                        results.(sesName).(fn).(trainStr) = accAndRT(matchRespSame,matchRespDiff,sub,results.(sesName).(fn).(trainStr),destField,accField,dataFields{mf});
                        %accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);
                        
                        if printResults
                          matchResults = results.(sesName).(fn).(trainStr).(destField);
                          
                          fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',matchResults.(hrField)(sub),matchResults.(nHitField)(sub),matchResults.(nTargField)(sub));
                          if ~isempty(matchRespDiff)
                            fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',matchResults.(farField)(sub),matchResults.(nFAField)(sub),(matchResults.(nLureField)(sub)));
                            fprintf('\t\td'':\t\t%.2f\n',matchResults.(dpField)(sub));
                          end
                          fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',matchResults.(sprintf('%s_hit',rtField))(sub),matchResults.(sprintf('%s_miss',rtField))(sub));
                          if ~isempty(matchRespDiff)
                            fprintf(', cr: %.2f, fa: %.2f\n',matchResults.(sprintf('%s_cr',rtField))(sub),matchResults.(sprintf('%s_fa',rtField))(sub));
                          else
                            fprintf('\n');
                          end
                        end
                      end
                      
                      % basic and subordinate
                      destField = 'basic';
                      if ismember(destField,mainFields)
                        matchBasic = matchResp([matchResp.isSubord] == 0);
                        matchBasicSame = matchBasic([matchBasic.sameSpecies] == 1);
                        matchBasicDiff = matchBasic([matchBasic.sameSpecies] == 0);
                        
                        results.(sesName).(fn).(trainStr) = accAndRT(matchBasicSame,matchBasicDiff,sub,results.(sesName).(fn).(trainStr),destField,accField,dataFields{mf});
                        %accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);
                        
                        if printResults
                          matchBasicResults = results.(sesName).(fn).(trainStr).(destField);
                          
                          fprintf('\tBasic\n');
                          fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',matchBasicResults.(hrField)(sub),matchBasicResults.(nHitField)(sub),matchBasicResults.(nTargField)(sub));
                          if ~isempty(matchBasicDiff)
                            fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',matchBasicResults.(farField)(sub),matchBasicResults.(nFAField)(sub),(matchBasicResults.(nLureField)(sub)));
                            fprintf('\t\td'':\t\t%.2f\n',matchBasicResults.(dpField)(sub));
                          end
                          fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',matchBasicResults.(sprintf('%s_hit',rtField))(sub),matchBasicResults.(sprintf('%s_miss',rtField))(sub));
                          if ~isempty(matchBasicDiff)
                            fprintf(', cr: %.2f, fa: %.2f\n',matchBasicResults.(sprintf('%s_cr',rtField))(sub),matchBasicResults.(sprintf('%s_fa',rtField))(sub));
                          else
                            fprintf('\n');
                          end
                        end
                      end
                      
                      destField = 'subord';
                      if ismember(destField,mainFields)
                        matchSubord = matchResp([matchResp.isSubord] == 1);
                        matchSubordSame = matchSubord([matchSubord.sameSpecies] == 1);
                        matchSubordDiff = matchSubord([matchSubord.sameSpecies] == 0);
                        
                        results.(sesName).(fn).(trainStr) = accAndRT(matchSubordSame,matchSubordDiff,sub,results.(sesName).(fn).(trainStr),destField,accField,dataFields{mf});
                        %accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);
                        
                        if printResults
                          matchSubordResults = results.(sesName).(fn).(trainStr).(destField);
                          
                          fprintf('\tSubordinate\n')
                          fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',matchSubordResults.(hrField)(sub),matchSubordResults.(nHitField)(sub),matchSubordResults.(nTargField)(sub));
                          if ~isempty(matchSubordDiff)
                            fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',matchSubordResults.(farField)(sub),matchSubordResults.(nFAField)(sub),(matchSubordResults.(nLureField)(sub)));
                            fprintf('\t\td'':\t\t%.2f\n',matchSubordResults.(dpField)(sub));
                          end
                          fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',matchSubordResults.(sprintf('%s_hit',rtField))(sub),matchSubordResults.(sprintf('%s_miss',rtField))(sub));
                          if ~isempty(matchSubordDiff)
                            fprintf(', cr: %.2f, fa: %.2f\n',matchSubordResults.(sprintf('%s_cr',rtField))(sub),matchSubordResults.(sprintf('%s_fa',rtField))(sub));
                          else
                            fprintf('\n');
                          end
                        end
                      end
                      
                      %                   % check out the RT distribution
                      %                   distrib = 0:100:2000;
                      %
                      %                   figure;hist([matchResp.rt],distrib);
                      %                   axis([min(distrib) max(distrib) 0 150]);
                      %                   title(sprintf('%s %s %s %s: all',subjects{sub},sesName,fn,trainStr));
                      %                   ylabel('Number of trials');
                      %                   xlabel('RT (ms) measured from ''?'' prompt');
                      %
                      %                   figure;hist([matchBasic.rt],distrib);
                      %                   axis([min(distrib) max(distrib) 0 150]);
                      %                   title(sprintf('%s %s %s %s: basic',subjects{sub},sesName,fn,trainStr));
                      %                   ylabel('Number of trials');
                      %                   xlabel('RT (ms) measured from ''?'' prompt');
                      %
                      %                   figure;hist([matchSubord.rt],distrib);
                      %                   axis([min(distrib) max(distrib) 0 150]);
                      %                   title(sprintf('%s %s %s %s: subord',subjects{sub},sesName,fn,trainStr));
                      %                   ylabel('Number of trials');
                      %                   xlabel('RT (ms) measured from ''?'' prompt');
                      %
                      %                   keyboard
                      %                   close all
                      %                   % figure();print(gcf,'-dpng',fullfile('~/Desktop',sprintf('rtDist_%s_%s_%s_%s',subjects{sub},sesName,fn,trainStr)));
                      
                      % accuracy for the different image manipulation conditions
                      imgConds = unique({matchResp.imgCond});
                      % if there's only 1 image manipulation condition, the
                      % results were printed above
                      if length(imgConds) > 1
                        if printResults
                          fprintf('\n');
                        end
                        for im = 1:length(imgConds)
                          matchCond = matchResp(ismember({matchResp.imgCond},imgConds{im}));
                          
                          % overall for this manipulation
                          destField = 'overall';
                          if ismember(destField,mainFields)
                            matchCondSame = matchCond([matchCond.sameSpecies] == 1);
                            matchCondDiff = matchCond([matchCond.sameSpecies] == 0);
                            
                            results.(sesName).(fn).(trainStr).(imgConds{im}) = accAndRT(matchCondSame,matchCondDiff,sub,results.(sesName).(fn).(trainStr).(imgConds{im}),destField,accField,dataFields{mf});
                            %accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);
                            
                            if printResults
                              matchCondResults = results.(sesName).(fn).(trainStr).(imgConds{im}).(destField);
                              fprintf('\t%s:',imgConds{im});
                              fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',matchCondResults.(hrField)(sub),matchCondResults.(nHitField)(sub),matchCondResults.(nTargField)(sub));
                              if ~isempty(matchCondDiff)
                                fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',matchCondResults.(farField)(sub),matchCondResults.(nFAField)(sub),(matchCondResults.(nLureField)(sub)));
                                fprintf('\t\td'':\t\t%.2f\n',matchCondResults.(dpField)(sub));
                              end
                              fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',matchCondResults.(sprintf('%s_hit',rtField))(sub),matchCondResults.(sprintf('%s_miss',rtField))(sub));
                              if ~isempty(matchCondDiff)
                                fprintf(', cr: %.2f, fa: %.2f\n',matchCondResults.(sprintf('%s_cr',rtField))(sub),matchCondResults.(sprintf('%s_fa',rtField))(sub));
                              else
                                fprintf('\n');
                              end
                            end
                          end
                          
                          % basic and subordinate for this manipulation
                          destField = 'basic';
                          if ismember(destField,mainFields)
                            matchCondBasic = matchResp([matchCond.isSubord] == 0);
                            matchCondBasicSame = matchCondBasic([matchCondBasic.sameSpecies] == 1);
                            matchCondBasicDiff = matchCondBasic([matchCondBasic.sameSpecies] == 0);
                            
                            results.(sesName).(fn).(trainStr).(imgConds{im}) = accAndRT(matchCondBasicSame,matchCondBasicDiff,sub,results.(sesName).(fn).(trainStr).(imgConds{im}),destField,accField,dataFields{mf});
                            %accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);
                            
                            if printResults
                              matchCondBasicResults = results.(sesName).(fn).(trainStr).(imgConds{im}).(destField);
                              fprintf('\tBasic\n');
                              fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',matchCondBasicResults.(hrField)(sub),matchCondBasicResults.(nHitField)(sub),matchCondBasicResults.(nTargField)(sub));
                              if ~isempty(matchCondBasicDiff)
                                fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',matchCondBasicResults.(farField)(sub),matchCondBasicResults.(nFAField)(sub),(matchCondBasicResults.(nLureField)(sub)));
                                fprintf('\t\td'':\t\t%.2f\n',matchCondBasicResults.(dpField)(sub));
                              end
                              fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',matchCondBasicResults.(sprintf('%s_hit',rtField))(sub),matchCondBasicResults.(sprintf('%s_miss',rtField))(sub));
                              if ~isempty(matchCondBasicDiff)
                                fprintf(', cr: %.2f, fa: %.2f\n',matchCondBasicResults.(sprintf('%s_cr',rtField))(sub),matchCondBasicResults.(sprintf('%s_fa',rtField))(sub));
                              else
                                fprintf('\n');
                              end
                            end
                          end
                          
                          destField = 'subord';
                          if ismember(destField,mainFields)
                            matchCondSubord = matchResp([matchCond.isSubord] == 1);
                            matchCondSubordSame = matchCondSubord([matchCondSubord.sameSpecies] == 1);
                            matchCondSubordDiff = matchCondSubord([matchCondSubord.sameSpecies] == 0);
                            
                            results.(sesName).(fn).(trainStr).(imgConds{im}) = accAndRT(matchCondSubordSame,matchCondSubordDiff,sub,results.(sesName).(fn).(trainStr).(imgConds{im}),destField,accField,dataFields{mf});
                            %accField,hrField,mrField,crrField,farField,dpField,nTrialsField,nTargField,nLureField,nHitField,nMissField,nCRField,nFAField,rtField);
                            
                            if printResults
                              matchCondSubordResults = results.(sesName).(fn).(trainStr).(imgConds{im}).(destField);
                              fprintf('\tSubordinate\n')
                              fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',matchCondSubordResults.(hrField)(sub),matchCondSubordResults.(nHitField)(sub),matchCondSubordResults.(nTargField)(sub));
                              if ~isempty(matchCondSubordDiff)
                                fprintf('\t\tFA-Rate:\t%.4f (%d/%d)\n',matchCondSubordResults.(farField)(sub),matchCondSubordResults.(nFAField)(sub),(matchCondSubordResults.(nLureField)(sub)));
                                fprintf('\t\td'':\t\t%.2f\n',matchCondSubordResults.(dpField)(sub));
                              end
                              fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f',matchCondSubordResults.(sprintf('%s_hit',rtField))(sub),matchCondSubordResults.(sprintf('%s_miss',rtField))(sub));
                              if ~isempty(matchCondSubordDiff)
                                fprintf(', cr: %.2f, fa: %.2f\n',matchCondSubordResults.(sprintf('%s_cr',rtField))(sub),matchCondSubordResults.(sprintf('%s_fa',rtField))(sub));
                              else
                                fprintf('\n');
                              end
                            end
                          end
                          
                        end
                      end
                      
                    end
                    
                  case {'name', 'nametrain', 'prac_name'}
                    
                    if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
                      nBlocks = 1;
                    else
                      nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
                    end
                    
                    % filter the events that we want
                    nameResp = events.(sesName).(fn).data(ismember({events.(sesName).(fn).data.type},'NAME_RESP'));
                    
                    % exclude missed responses (-1)
                    nameResp = nameResp([nameResp.resp] ~= -1);
                    % set missing response to incorrect
                    % noRespInd = find([nameResp.resp] == -1);
                    % if ~isempty(noRespInd)
                    %   for nr = 1:length(noRespInd)
                    %     nameResp(noRespInd(nr)).acc = 0;
                    %   end
                    % end
                    
                    % overall
                    destField = 'overall';
                    if ismember(destField,mainFields)
                      results.(sesName).(fn) = accAndRT(nameResp,[],sub,results.(sesName).(fn),destField,accField,dataFields{mf});
                      if printResults
                        nameResults = results.(sesName).(fn).(destField);
                        fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',nameResults.(hrField)(sub),nameResults.(nHitField)(sub),nameResults.(nTargField)(sub));
                        fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f\n',nameResults.(sprintf('%s_hit',rtField))(sub),nameResults.(sprintf('%s_miss',rtField))(sub));
                      end
                    end
                    
                    % basic and subordinate
                    destField = 'basic';
                    if ismember(destField,mainFields)
                      nameBasic = nameResp([nameResp.isSubord] == 0);
                      results.(sesName).(fn) = accAndRT(nameBasic,[],sub,results.(sesName).(fn),destField,accField,dataFields{mf});
                      if printResults
                        nameBasicResults = results.(sesName).(fn).(destField);
                        fprintf('\tBasic\n');
                        fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',nameBasicResults.(hrField)(sub),nameBasicResults.(nHitField)(sub),nameBasicResults.(nTargField)(sub));
                        fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f\n',nameBasicResults.(sprintf('%s_hit',rtField))(sub),nameBasicResults.(sprintf('%s_miss',rtField))(sub));
                      end
                    end
                    
                    destField = 'subord';
                    if ismember(destField,mainFields)
                      nameSubord = nameResp([nameResp.isSubord] == 1);
                      results.(sesName).(fn) = accAndRT(nameSubord,[],sub,results.(sesName).(fn),destField,accField,dataFields{mf});
                      if printResults
                        nameSubordResults = results.(sesName).(fn).(destField);
                        fprintf('\tSubordinate\n')
                        fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',nameSubordResults.(hrField)(sub),nameSubordResults.(nHitField)(sub),nameSubordResults.(nTargField)(sub));
                        fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f\n',nameSubordResults.(sprintf('%s_hit',rtField))(sub),nameSubordResults.(sprintf('%s_miss',rtField))(sub));
                      end
                    end
                    
                    % if there's only 1 block, the results were printed above
                    if nBlocks > 1
                      fprintf('\n');
                      for b = 1:nBlocks
                        blockStr = sprintf('b%d',b);
                        
                        nameBlock = nameResp([nameResp.block] == b);
                        
                        % overall
                        destField = 'overall';
                        if ismember(destField,mainFields)
                          results.(sesName).(fn).(blockStr) = accAndRT(nameBlock,[],sub,results.(sesName).(fn).(blockStr),destField,accField,dataFields{mf});
                          if printResults
                            nameBlockResults = results.(sesName).(fn).(blockStr).(destField);
                            fprintf('\tB%d:',b);
                            fprintf('\t\tHitRate:\t%.4f (%d/%d)\n',nameBlockResults.(hrField)(sub),nameBlockResults.(nHitField)(sub),nameBlockResults.(nTargField)(sub));
                            fprintf('\t\tRespTime:\thit: %.2f, miss: %.2f\n',nameBlockResults.(sprintf('%s_hit',rtField))(sub),nameBlockResults.(sprintf('%s_miss',rtField))(sub));
                          end
                        end
                        
                        % basic and subordinate for this block
                        destField = 'basic';
                        if ismember(destField,mainFields)
                          nameBlockBasic = nameBlock([nameBlock.isSubord] == 0);
                          results.(sesName).(fn).(blockStr) = accAndRT(nameBlockBasic,[],sub,results.(sesName).(fn).(blockStr),destField,accField,dataFields{mf});
                          if printResults
                            nameBlockBasicResults = results.(sesName).(fn).(blockStr).(destField);
                            fprintf('\tB%d:',b);
                            fprintf('\t\tBasic\n');
                            fprintf('\t\t\tHitRate:\t%.4f (%d/%d)\n',nameBlockBasicResults.(hrField)(sub),nameBlockBasicResults.(nHitField)(sub),nameBlockBasicResults.(nTargField)(sub));
                            fprintf('\t\t\tRespTime:\thit: %.2f, miss: %.2f\n',nameBlockBasicResults.(sprintf('%s_hit',rtField))(sub),nameBlockBasicResults.(sprintf('%s_miss',rtField))(sub));
                          end
                        end
                        
                        destField = 'subord';
                        if ismember(destField,mainFields)
                          nameBlockSubord = nameBlock([nameBlock.isSubord] == 1);
                          results.(sesName).(fn).(blockStr) = accAndRT(nameBlockSubord,[],sub,results.(sesName).(fn).(blockStr),destField,accField,dataFields{mf});
                          if printResults
                            nameBlockSubordResults = results.(sesName).(fn).(blockStr).(destField);
                            fprintf('\tB%d:',b);
                            fprintf('\t\tSubordinate\n')
                            fprintf('\t\t\tHitRate:\t%.4f (%d/%d)\n',nameBlockSubordResults.(hrField)(sub),nameBlockSubordResults.(nHitField)(sub),nameBlockSubordResults.(nTargField)(sub));
                            fprintf('\t\t\tRespTime:\thit: %.2f, miss: %.2f\n',nameBlockSubordResults.(sprintf('%s_hit',rtField))(sub),nameBlockSubordResults.(sprintf('%s_miss',rtField))(sub));
                          end
                        end
                        
                      end
                    end
                    
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
    save(matFileName,'results');
  end
end

if saveResults
  fileName = fullfile(dataroot,sprintf('%s_behav_results.txt',expName));
  printResultsToFile(dataroot,subjects,completeStatus,trainedConds,results,mainFields,dataFields,fileName);
end

end % function

%% print to file

function printResultsToFile(dataroot,subjects,completeStatus,trainedConds,results,mainToPrint,dataToPrint,fileName)

fprintf('Saving results to file: %s...',fileName);

% mainToPrint = {'basic','subord'};
% % dataToPrint = {'nTrial','nCor','acc','dp','rt','rt_cor','rt_inc'};
% dataToPrint = {'nTrial','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt_hit','rt_miss','rt_cr','rt_far'};

% use subject 1's files for initialization
sub = 1;
subDir = fullfile(dataroot,subjects{sub});
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

fid = fopen(fileName,'wt');

for sesNum = 1:length(expParam.sesTypes)
  % set the subject events file
  sesName = expParam.sesTypes{sesNum};
  
  uniquePhaseNames = unique(expParam.session.(sesName).phases);
  uniquePhaseCounts = zeros(1,length(unique(expParam.session.(sesName).phases)));
  
  fprintf(fid,'session\t%s\n',sesName);
  
  for pha = 1:length(expParam.session.(sesName).phases)
    phaseName = expParam.session.(sesName).phases{pha};
    
    % find out where this phase occurs in the list of unique phases
    uniquePhaseInd = find(ismember(uniquePhaseNames,phaseName));
    % increase the phase count for that phase
    uniquePhaseCounts(uniquePhaseInd) = uniquePhaseCounts(uniquePhaseInd) + 1;
    % set the phase count
    phaseCount = uniquePhaseCounts(uniquePhaseInd);
    
    if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
      
      % set the phase name with phase count
      fn = sprintf(sprintf('%s_%d',phaseName,phaseCount));
      
      fprintf(fid,'phase\t%s\n',fn);
      
      switch phaseName
        case {'match', 'prac_match'}
          for t = 1:length(trainedConds)
            
            % choose the training condition
            if length(trainedConds{t}) == 1
              if trainedConds{t} == 1
                trainStr = 'trained';
              elseif trainedConds{t} == 0
                trainStr = 'untrained';
              end
            elseif length(trainedConds{t}) > 1
              trainStr = 'all';
            end
            
            matchResp = events.(sesName).(fn).data(ismember({events.(sesName).(fn).data.type},'MATCH_RESP') & ismember([events.(sesName).(fn).data.trained],trainedConds{t}));
            
            imgConds = unique({matchResp.imgCond});
            if length(imgConds) > 1
              nTabs = nan(1,length(dataToPrint) * length(imgConds));
              nTabInd = 0;
              for im = 1:length(imgConds)
                for d = 1:length(dataToPrint)
                  nTabInd = nTabInd + 1;
                  nTabs(nTabInd) = length(dataToPrint{d});
                end
              end
              headerCell = {{trainStr},imgConds,mainToPrint};
              [headerStr] = setHeaderStr(headerCell,nTabs);
              fprintf(fid,sprintf('\t%s\n',headerStr));
              
              for sub = 1:length(subjects)
                % print the header string only before the first sub
                if sub == 1
                  for im = 1:length(imgConds)
                    for mf = 1:length(mainToPrint)
                      [headerStr] = setHeaderStr(dataToPrint(mf),1);
                      headerStr = sprintf('\t%s',headerStr);
                      %headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
                      fprintf(fid,sprintf('%s',headerStr));
                    end
                  end
                  fprintf(fid,'\n');
                end
                
                if completeStatus(sub)
                  dataStr = subjects{sub};
                  for im = 1:length(imgConds)
                    for mf = 1:length(mainToPrint)
                      [dataStr] = setDataStr(dataStr,{sesName,fn,trainStr,imgConds{im},mainToPrint{mf}},results,sub,dataToPrint{mf});
                    end
                  end
                  fprintf(fid,sprintf('%s\n',dataStr));
                end
              end
              
            else
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              keyboard
              
              nTabs = nan(1,length(dataToPrint));
              nTabInd = 0;
              for d = 1:length(dataToPrint)
                nTabInd = nTabInd + 1;
                nTabs(nTabInd) = length(dataToPrint{d});
              end
              headerCell = {{trainStr},mainToPrint};
              [headerStr] = setHeaderStr(headerCell,nTabs);
              fprintf(fid,sprintf('\t%s\n',headerStr));
              
              for sub = 1:length(subjects)
                % print the header string only before the first sub
                if sub == 1
                  for mf = 1:length(mainToPrint)
                    [headerStr] = setHeaderStr(dataToPrint(mf),1);
                    headerStr = sprintf('\t%s',headerStr);
                    %headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
                    fprintf(fid,sprintf('%s',headerStr));
                  end
                  fprintf(fid,'\n');
                end
                
                if completeStatus(sub)
                  dataStr = subjects{sub};
                  for mf = 1:length(mainToPrint)
                    [dataStr] = setDataStr(dataStr,{sesName,fn,trainStr,mainToPrint{mf}},results,sub,dataToPrint{mf});
                  end
                  fprintf(fid,sprintf('%s\n',dataStr));
                end
              end
            end
            if t ~= length(trainedConds)
              fprintf(fid,'\n');
            end
          end
          
        case {'name', 'nametrain', 'prac_name'}
          if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
            nBlocks = 1;
          else
            nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
          end
          
          if nBlocks > 1
            blockStr = cell(1,nBlocks);
            for b = 1:nBlocks
              blockStr{b} = sprintf('b%d',b);
            end
            nTabs = nan(1,length(dataToPrint) * nBlocks);
            nTabInd = 0;
            for b = 1:nBlocks
              for d = 1:length(dataToPrint)
                nTabInd = nTabInd + 1;
                nTabs(nTabInd) = length(dataToPrint{d});
              end
            end
            headerCell = {blockStr,mainToPrint};
            [headerStr] = setHeaderStr(headerCell,nTabs);
            fprintf(fid,sprintf('\t%s\n',headerStr));
            
            for sub = 1:length(subjects)
              % print the header string only before the first sub
              if sub == 1
                for b = 1:nBlocks
                  for mf = 1:length(mainToPrint)
                    [headerStr] = setHeaderStr(dataToPrint(mf),1);
                    headerStr = sprintf('\t%s',headerStr);
                    %headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
                    fprintf(fid,sprintf('%s',headerStr));
                  end
                end
                fprintf(fid,'\n');
              end
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              if completeStatus(sub)
                dataStr = subjects{sub};
                for b = 1:nBlocks
                  for mf = 1:length(mainToPrint)
                    [dataStr] = setDataStr(dataStr,{sesName,fn,sprintf('b%d',b),mainToPrint{mf}},results,sub,dataToPrint{mf});
                  end
                end
                fprintf(fid,sprintf('%s\n',dataStr));
              end
            end
          else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            nTabs = nan(1,length(dataToPrint));
            nTabInd = 0;
            for d = 1:length(dataToPrint)
              nTabInd = nTabInd + 1;
              nTabs(nTabInd) = length(dataToPrint{d});
            end
            headerCell = {mainToPrint};
            [headerStr] = setHeaderStr(headerCell,nTabs);
            fprintf(fid,sprintf('\t%s\n',headerStr));
            
            for sub = 1:length(subjects)
              % print the header string only before the first sub
              if sub == 1
                for mf = 1:length(mainToPrint)
                  [headerStr] = setHeaderStr(dataToPrint(mf),1);
                  headerStr = sprintf('\t%s',headerStr);
                  %headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
                  fprintf(fid,sprintf('%s',headerStr));
                end
                fprintf(fid,'\n');
              end
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              if completeStatus(sub)
                dataStr = subjects{sub};
                for mf = 1:length(mainToPrint)
                  [dataStr] = setDataStr(dataStr,{sesName,fn,mainToPrint{mf}},results,sub,dataToPrint{mf});
                end
                fprintf(fid,sprintf('%s\n',dataStr));
              end
            end
            
          end
      end % switch phaseName
      fprintf(fid,'\n');
    end
  end
end

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

function inputStruct = accAndRT(targEv,lureEv,sub,inputStruct,destField,accField,dataFields,prependDestField)

if ~isfield(inputStruct,destField)
  error('input structure does not have field called ''%s''!',destField);
end

if ~exist('prependDestField','var') || isempty(prependDestField)
  prependDestField = false;
end

% trial counts
thisStr = 'nTrial';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  nTrial = length(targEv) + length(lureEv);
  inputStruct.(destField).(thisField)(sub) = nTrial;
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

hitEv = targEv([targEv.(accField)] == 1);
missEv = targEv([targEv.(accField)] == 0);

if ~isempty(lureEv)
  crEv = lureEv([lureEv.(accField)] == 1);
  faEv = lureEv([lureEv.(accField)] == 0);
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

% d-prime; adjust for perfect performance, choose 1 of 2 strategies
% (Macmillan & Creelman, 2005; p. 8-9)
strategy = 2;

hr = length(hitEv) / length(targEv);
mr = length(missEv) / length(targEv);
if ~isempty(lureEv)
  crr = length(crEv) / length(lureEv);
  far = length(faEv) / length(lureEv);
end

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
if ~isempty(lureEv)
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


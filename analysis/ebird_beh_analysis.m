function [results] = ebird_beh_analysis(subjects)
% basic analysis script for expertTrain experiments

if nargin == 0
  subjects = {
    'EBIRD049';
    'EBIRD002';
    'EBIRD003';
    };
end

expName = 'EBIRD';

serverDir = fullfile(filesep,'Volumes','curranlab','Data',expName,'Behavioral','Sessions');
serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data',expName,'Behavioral','Sessions');
localDir = fullfile(getenv('HOME'),'data',expName,'Behavioral','Sessions');
if exist(serverDir,'dir')
  dataroot = serverDir;
elseif exist(serverLocalDir,'dir')
  dataroot = serverLocalDir;
elseif exist(localDir,'dir')
  dataroot = localDir;
else
  error('No data directory found.');
end
%saveDir = dataroot;

%% some constants

%trainedConds = {0, 1, [0 1]};
trainedConds = {0, 1};

results = struct;

resFields = {'acc','dp','rt','rt_cor','rt_inc'};
mainFields = {'overall','basic','subord'};

%% initialize to store the data

% is this insane??

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
  if isfield(events,sesName)
    
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
              
              for mc = 1:length(mainFields)
                for rf = 1:length(resFields)
                  results.(sesName).(fn).(trainStr).(mainFields{mc}).(resFields{rf}) = nan(length(subjects),1);
                end
              end
              
              imgConds = unique({events.(sesName).(fn).imgCond});
              if length(imgConds) > 1
                for im = 1:length(imgConds)
                  for mc = 1:length(mainFields)
                    for rf = 1:length(resFields)
                      results.(sesName).(fn).(trainStr).(imgConds{im}).(mainFields{mc}).(resFields{rf}) = nan(length(subjects),1);
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
            
            for mc = 1:length(mainFields)
              for rf = 1:length(resFields)
                results.(sesName).(fn).(mainFields{mc}).(resFields{rf}) = nan(length(subjects),1);
              end
            end
            if nBlocks > 1
              fprintf('\n');
              for b = 1:nBlocks
                for mc = 1:length(mainFields)
                  for rf = 1:length(resFields)
                    results.(sesName).(fn).(sprintf('b%d',b)).(mainFields{mc}).(resFields{rf}) = nan(length(subjects),1);
                  end
                end
              end
            end
        end % switch
      end
    end
  end
end

%% process the data

for sub = 1:length(subjects)
  subDir = fullfile(dataroot,subjects{sub});
  fprintf('Processing %s in %s...\n',subjects{sub},subDir);
  
  fprintf('Loading experiment parameters for %s...',subjects{sub});
  expParamFile = fullfile(subDir,'experimentParams.mat');
  if exist(expParamFile,'file')
    load(expParamFile)
    fprintf('Done.\n');
  else
    error('experiment parameter file does not exist: %s',expParamFile);
  end
  
  fprintf('Loading events for %s...',subjects{sub});
  eventsFile = fullfile(subDir,'events','events.mat');
  if exist(eventsFile,'file')
    load(eventsFile,'events');
    fprintf('Done.\n');
  else
    error('events file does not exist: %s',eventsFile);
  end
  
  for sesNum = 1:length(expParam.sesTypes)
    % set the subject events file
    sesName = expParam.sesTypes{sesNum};
    
    % make sure the session field exists
    if isfield(events,sesName)
      
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
          
          % make sure the phase field exists
          if isfield(events.(sesName),fn)
            
            switch phaseName
              case {'match', 'prac_match'}
                for t = 1:length(trainedConds)
                  fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                  
                  % choose the training condition
                  if length(trainedConds{t}) == 1
                    if trainedConds{t} == 1
                      fprintf('*** Trained ***\n');
                      trainStr = 'trained';
                    elseif trainedConds{t} == 0
                      fprintf('*** Untrained ***\n');
                      trainStr = 'untrained';
                    end
                  elseif length(trainedConds{t}) > 1
                    fprintf('Trained and untrained together\n');
                    trainStr = 'all';
                  end
                  
                  % filter the events that we want
                  matchResp = events.(sesName).(fn)(strcmp({events.(sesName).(fn).type},'MATCH_RESP') & ismember([events.(sesName).(fn).trained],trainedConds{t}));
                  
                  % % exclude missed responses ('none')
                  % matchResp = matchResp(~strcmp({matchResp.resp},'none'));
                  % % % set missing responses to incorrect
                  % % noRespInd = find(strcmp({matchResp.resp},'none'));
                  % % if ~isempty(noRespInd)
                  % %   for nr = 1:length(noRespInd)
                  % %     matchResp(noRespInd(nr)).acc = 0;
                  % %   end
                  % % end
                  
                  % overall
                  thisField = 'overall';
                  results.(sesName).(fn).(trainStr) = accAndRT(matchResp,sub,results.(sesName).(fn).(trainStr),thisField);
                  matchResults = results.(sesName).(fn).(trainStr).(thisField);
                  fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',matchResults.acc(sub),sum([matchResp.acc] == 1),length([matchResp.acc]),matchResults.dp(sub));
                  fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchResults.rt(sub),matchResults.rt_cor(sub),matchResults.rt_inc(sub));
                  
                  % basic and subordinate
                  matchBasic = matchResp([matchResp.isSubord] == 0);
                  matchSubord = matchResp([matchResp.isSubord] == 1);
                  
                  thisField = 'basic';
                  results.(sesName).(fn).(trainStr) = accAndRT(matchBasic,sub,results.(sesName).(fn).(trainStr),thisField);
                  matchBasicResults = results.(sesName).(fn).(trainStr).(thisField);
                  thisField = 'subord';
                  results.(sesName).(fn).(trainStr) = accAndRT(matchSubord,sub,results.(sesName).(fn).(trainStr),thisField);
                  matchSubordResults = results.(sesName).(fn).(trainStr).(thisField);
                  fprintf('\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',matchBasicResults.acc(sub),sum([matchBasic.acc] == 1),length([matchBasic.acc]),matchBasicResults.dp(sub));
                  fprintf('\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',matchSubordResults.acc(sub),sum([matchSubord.acc] == 1),length([matchSubord.acc]),matchSubordResults.dp(sub));
                  fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchBasicResults.rt(sub),matchBasicResults.rt_cor(sub),matchBasicResults.rt_inc(sub));
                  fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchSubordResults.rt(sub),matchSubordResults.rt_cor(sub),matchSubordResults.rt_inc(sub));
                  
                  % accuracy for the different image manipulation conditions
                  imgConds = unique({matchResp.imgCond});
                  if length(imgConds) > 1
                    fprintf('\n');
                    for im = 1:length(imgConds)
                      matchCond = matchResp(strcmp({matchResp.imgCond},imgConds{im}));
                      
                      thisField = 'overall';
                      results.(sesName).(fn).(trainStr).(imgConds{im}) = accAndRT(matchCond,sub,results.(sesName).(fn).(trainStr).(imgConds{im}),thisField);
                      matchCondResults = results.(sesName).(fn).(trainStr).(imgConds{im}).(thisField);
                      fprintf('\t%s:',imgConds{im});
                      fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',matchCondResults.acc(sub),sum([matchCond.acc] == 1),length([matchCond.acc]),matchCondResults.dp(sub));
                      fprintf('\t');
                      fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondResults.rt(sub),matchCondResults.rt_cor(sub),matchCondResults.rt_inc(sub));
                      
                      % basic and subordinate for this manipulation
                      matchCondBasic = matchResp([matchCond.isSubord] == 0);
                      matchCondSubord = matchResp([matchCond.isSubord] == 1);
                      
                      thisField = 'basic';
                      results.(sesName).(fn).(trainStr).(imgConds{im}) = accAndRT(matchCondBasic,sub,results.(sesName).(fn).(trainStr).(imgConds{im}),thisField);
                      matchCondBasicResults = results.(sesName).(fn).(trainStr).(imgConds{im}).(thisField);
                      
                      thisField = 'subord';
                      results.(sesName).(fn).(trainStr).(imgConds{im}) = accAndRT(matchCondSubord,sub,results.(sesName).(fn).(trainStr).(imgConds{im}),thisField);
                      matchCondSubordResults = results.(sesName).(fn).(trainStr).(imgConds{im}).(thisField);
                      
                      fprintf('\t\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',matchCondBasicResults.acc(sub),sum([matchCondBasic.acc] == 1),length([matchCondBasic.acc]),matchCondBasicResults.dp(sub));
                      fprintf('\t\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',matchCondSubordResults.acc(sub),sum([matchCondSubord.acc] == 1),length([matchCondSubord.acc]),matchCondSubordResults.dp(sub));
                      fprintf('\t\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondBasicResults.rt(sub),matchCondBasicResults.rt_cor(sub),matchCondBasicResults.rt_inc(sub));
                      fprintf('\t\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondSubordResults.rt(sub),matchCondSubordResults.rt_cor(sub),matchCondSubordResults.rt_inc(sub));
                    end
                  end
                  
                end
                
              case {'name', 'nametrain', 'prac_name'}
                fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                
                if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
                  nBlocks = 1;
                else
                  nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
                end
                
                % filter the events that we want
                nameResp = events.(sesName).(fn)(strcmp({events.(sesName).(fn).type},'NAME_RESP'));
                
                % % exclude missed responses (-1)
                % nameResp = nameResp([nameResp.resp] ~= -1);
                % % set missing response to incorrect
                % % noRespInd = find([nameResp.resp] == -1);
                % % if ~isempty(noRespInd)
                % %   for nr = 1:length(noRespInd)
                % %     nameResp(noRespInd(nr)).acc = 0;
                % %   end
                % % end
                
                % overall
                thisField = 'overall';
                results.(sesName).(fn) = accAndRT(nameResp,sub,results.(sesName).(fn),thisField);
                nameResults = results.(sesName).(fn).(thisField);
                fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',nameResults.acc(sub),sum([nameResp.acc] == 1),length([nameResp.acc]),nameResults.dp(sub));
                fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameResults.rt(sub),nameResults.rt_cor(sub),nameResults.rt_inc(sub));
                
                % basic and subordinate accuracy
                nameBasic = nameResp([nameResp.isSubord] == 0);
                nameSubord = nameResp([nameResp.isSubord] == 1);
                
                thisField = 'basic';
                results.(sesName).(fn) = accAndRT(nameBasic,sub,results.(sesName).(fn),thisField);
                nameBasicResults = results.(sesName).(fn).(thisField);
                thisField = 'subord';
                results.(sesName).(fn) = accAndRT(nameSubord,sub,results.(sesName).(fn),thisField);
                nameSubordResults = results.(sesName).(fn).(thisField);
                fprintf('\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',nameBasicResults.acc(sub),sum([nameBasic.acc] == 1),length([nameBasic.acc]),nameBasicResults.dp(sub));
                fprintf('\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',nameSubordResults.acc(sub),sum([nameSubord.acc] == 1),length([nameSubord.acc]),nameSubordResults.dp(sub));
                fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBasicResults.rt(sub),nameBasicResults.rt_cor(sub),nameBasicResults.rt_inc(sub));
                fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameSubordResults.rt(sub),nameSubordResults.rt_cor(sub),nameSubordResults.rt_inc(sub));
                
                if nBlocks > 1
                  fprintf('\n');
                  for b = 1:nBlocks
                    %fprintf('Block %d\n',b);
                    
                    blockStr = sprintf('b%d',b);
                    nameBlock = nameResp([nameResp.block] == b);
                    
                    thisField = 'overall';
                    results.(sesName).(fn).(blockStr) = accAndRT(nameBlock,sub,results.(sesName).(fn).(blockStr),thisField);
                    nameBlockResults = results.(sesName).(fn).(blockStr).(thisField);
                    fprintf('\tB%d:',b);
                    fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',nameBlockResults.acc(sub),sum([nameBlock.acc] == 1),length([nameBlock.acc]),nameBlockResults.dp(sub));
                    fprintf('\t');
                    fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockResults.rt(sub),nameBlockResults.rt_cor(sub),nameBlockResults.rt_inc(sub));
                    
                    % basic and subordinate for this manipulation
                    nameBlockBasic = matchResp([nameBlock.isSubord] == 0);
                    nameBlockSubord = matchResp([nameBlock.isSubord] == 1);
                    
                    thisField = 'basic';
                    results.(sesName).(fn).(blockStr) = accAndRT(nameBlock,sub,results.(sesName).(fn).(blockStr),thisField);
                    nameBlockBasicResults = results.(sesName).(fn).(blockStr).(thisField);
                    thisField = 'subord';
                    results.(sesName).(fn).(blockStr) = accAndRT(nameBlock,sub,results.(sesName).(fn).(blockStr),thisField);
                    nameBlockSubordResults = results.(sesName).(fn).(blockStr).(thisField);
                    fprintf('\t\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',nameBlockBasicResults.acc(sub),sum([nameBlockBasic.acc] == 1),length([nameBlockBasic.acc]),nameBlockBasicResults.dp(sub));
                    fprintf('\t\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',nameBlockSubordResults.acc(sub),sum([nameBlockSubord.acc] == 1),length([nameBlockSubord.acc]),nameBlockSubordResults.dp(sub));
                    fprintf('\t\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockBasicResults.rt(sub),nameBlockBasicResults.rt_cor(sub),nameBlockBasicResults.rt_inc(sub));
                    fprintf('\t\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockSubordResults.rt(sub),nameBlockSubordResults.rt_cor(sub),nameBlockSubordResults.rt_inc(sub));
                    
                  end
                end
                
            end % switch phaseName
            
          else
            fprintf('%s, %s: phase %s does not exist.\n',expParam.subject,sesName,fn);
          end % isfield phaseName
          
        end % isExp
        
      end % for pha
      fprintf('\n');
      
    else
      fprintf('%s: session %s does not exist.\n',expParam.subject,sesName);
    end % isfield sesName
    
  end % for ses
  fprintf('\n');
  
end % for sub
fprintf('\n');

end % function

%% Calculate accuracy and reaction time

%function results = accAndRT(thisCond)
function inputStruct = accAndRT(inputData,sub,inputStruct,destField)

if ~isfield(inputStruct,destField)
  error('input structure does not have field called ''%s''!',destField);
end

% accuracy
%results.acc = mean([inputData.acc] == 1);
inputStruct.(destField).acc(sub) = mean([inputData.acc] == 1);

% d-prime
%results.dp = norminv((sum([inputData.acc] == 1) / length([inputData.acc])),0,1) - norminv((sum([inputData.acc] == 0) / length([inputData.acc])),0,1);
inputStruct.(destField).dp(sub) = norminv((sum([inputData.acc] == 1) / length([inputData.acc])),0,1) - norminv((sum([inputData.acc] == 0) / length([inputData.acc])),0,1);

% RT
%results.rt = mean([inputData.rt]);
%results.rt_cor = mean([inputData([inputData.acc] == 1).rt]);
%results.rt_inc = mean([inputData([inputData.acc] == 0).rt]);
inputStruct.(destField).rt(sub) = mean([inputData.rt]);
inputStruct.(destField).rt_cor(sub) = mean([inputData([inputData.acc] == 1).rt]);
inputStruct.(destField).rt_inc(sub) = mean([inputData([inputData.acc] == 0).rt]);

end


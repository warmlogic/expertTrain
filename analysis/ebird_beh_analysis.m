function ebird_beh_analysis(subjects)
% basic analysis script for expertTrain experiments

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

if nargin == 0
  subjects = {
    'EBIRD049';
    'EBIRD002';
    'EBIRD003';
    };
end

trainedConds = {0, 1, [0 1]};

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
                  
                  if length(trainedConds{t}) == 1
                    if trainedConds{t} == 1
                      fprintf('Trained\n');
                      trainStr = 'trained';
                    elseif trainedConds{t} == 0
                      fprintf('Untrained\n');
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
                  % % set missing responses to incorrect
                  % noRespInd = find(strcmp({matchResp.resp},'none'));
                  % if ~isempty(noRespInd)
                  %   for nr = 1:length(noRespInd)
                  %     matchResp(noRespInd(nr)).acc = 0;
                  %   end
                  % end
                  
                  matchResults.(trainStr) = accAndRT(matchResp);
                  fprintf('\tAccuracy:\t%.4f (%d/%d)\n',matchResults.(trainStr).acc,sum([matchResp.acc] == 1),length([matchResp.acc]));
                  fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchResults.(trainStr).rt,matchResults.(trainStr).rt_cor,matchResults.(trainStr).rt_inc);
                  
                  % basic and subordinate accuracy
                  matchBasic = matchResp([matchResp.isSubord] == 0);
                  matchSubord = matchResp([matchResp.isSubord] == 1);
                  
                  matchBasicResults.(trainStr) = accAndRT(matchBasic);
                  matchSubordResults.(trainStr) = accAndRT(matchSubord);
                  fprintf('\t\tBasic acc:\t%.4f (%d/%d)\n',matchBasicResults.(trainStr).acc,sum([matchBasic.acc] == 1),length([matchBasic.acc]));
                  fprintf('\t\tSubord acc:\t%.4f (%d/%d)\n',matchSubordResults.(trainStr).acc,sum([matchSubord.acc] == 1),length([matchSubord.acc]));
                  fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchBasicResults.(trainStr).rt,matchBasicResults.(trainStr).rt_cor,matchBasicResults.(trainStr).rt_inc);
                  fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchSubordResults.(trainStr).rt,matchSubordResults.(trainStr).rt_cor,matchSubordResults.(trainStr).rt_inc);
                  
                  % accuracy for the different image manipulation conditions
                  imgConds = unique({matchResp.imgCond});
                  if length(imgConds) > 1
                    fprintf('\n');
                    for im = 1:length(imgConds)
                      matchCond = matchResp(strcmp({matchResp.imgCond},imgConds{im}));
                      matchCondResults.(trainStr) = accAndRT(matchCond);
                      fprintf('\t%s:\tAccuracy:\t%.4f (%d/%d)\n',imgConds{im},matchCondResults.(trainStr).acc,sum([matchCond.acc] == 1),length([matchCond.acc]));
                      fprintf('\t%s:\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',imgConds{im},matchCondResults.(trainStr).rt,matchCondResults.(trainStr).rt_cor,matchCondResults.(trainStr).rt_inc);
                      
                      % basic and subordinate for this manipulation
                      matchCondBasic = matchResp([matchCond.isSubord] == 0);
                      matchCondSubord = matchResp([matchCond.isSubord] == 1);
                      matchCondBasicResults.(trainStr) = accAndRT(matchCondBasic);
                      matchCondSubordResults.(trainStr) = accAndRT(matchCondSubord);
                      fprintf('\t\t\tBasic acc:\t%.4f (%d/%d)\n',matchCondBasicResults.(trainStr).acc,sum([matchCondBasic.acc] == 1),length([matchCondBasic.acc]));
                      fprintf('\t\t\tSubord acc:\t%.4f (%d/%d)\n',matchCondSubordResults.(trainStr).acc,sum([matchCondSubord.acc] == 1),length([matchCondSubord.acc]));
                      fprintf('\t\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondBasicResults.(trainStr).rt,matchCondBasicResults.(trainStr).rt_cor,matchCondBasicResults.(trainStr).rt_inc);
                      fprintf('\t\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondSubordResults.(trainStr).rt,matchCondSubordResults.(trainStr).rt_cor,matchCondSubordResults.(trainStr).rt_inc);
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
                % set missing response to incorrect
                % noRespInd = find([nameResp.resp] == -1);
                % if ~isempty(noRespInd)
                %   for nr = 1:length(noRespInd)
                %     nameResp(noRespInd(nr)).acc = 0;
                %   end
                % end
                
                nameResults = accAndRT(nameResp);
                fprintf('\tAccuracy:\t%.4f (%d/%d)\n',nameResults.acc,sum([nameResp.acc] == 1),length([nameResp.acc]));
                fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameResults.rt,nameResults.rt_cor,nameResults.rt_inc);
                
                % basic and subordinate accuracy
                nameBasic = nameResp([nameResp.isSubord] == 0);
                nameSubord = nameResp([nameResp.isSubord] == 1);
                
                nameBasicResults = accAndRT(nameBasic);
                nameSubordResults = accAndRT(nameSubord);
                fprintf('\t\tBasic acc:\t%.4f (%d/%d)\n',nameBasicResults.acc,sum([nameBasic.acc] == 1),length([nameBasic.acc]));
                fprintf('\t\tSubord acc:\t%.4f (%d/%d)\n',nameSubordResults.acc,sum([nameSubord.acc] == 1),length([nameSubord.acc]));
                fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBasicResults.rt,nameBasicResults.rt_cor,nameBasicResults.rt_inc);
                fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameSubordResults.rt,nameSubordResults.rt_cor,nameSubordResults.rt_inc);
                
                if nBlocks > 1
                  fprintf('\n');
                  for b = 1:nBlocks
                    fprintf('Block %d\n',b);
                    
                    blockStr = sprintf('b%d',b);
                    nameBlock = nameResp([nameResp.block] == b);
                    
                    nameBlockResults.(blockStr) = accAndRT(nameBlock);
                    fprintf('\t%s:\tAccuracy:\t%.4f (%d/%d)\n',imgConds{im},nameBlockResults.(blockStr).acc,sum([nameBlock.acc] == 1),length([nameBlock.acc]));
                    fprintf('\t%s:\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',imgConds{im},nameBlockResults.(blockStr).rt,nameBlockResults.(blockStr).rt_cor,nameBlockResults.(blockStr).rt_inc);
                    
                    % basic and subordinate for this manipulation
                    nameBlockBasic = matchResp([nameBlock.isSubord] == 0);
                    nameBlockSubord = matchResp([nameBlock.isSubord] == 1);
                    nameBlockBasicResults.(blockStr) = accAndRT(nameBlockBasic);
                    nameBlockSubordResults.(blockStr) = accAndRT(nameBlockSubord);
                    fprintf('\t\t\tBasic acc:\t%.4f (%d/%d)\n',nameBlockBasicResults.(blockStr).acc,sum([nameBlockBasic.acc] == 1),length([nameBlockBasic.acc]));
                    fprintf('\t\t\tSubord acc:\t%.4f (%d/%d)\n',nameBlockSubordResults.(blockStr).acc,sum([nameBlockSubord.acc] == 1),length([nameBlockSubord.acc]));
                    fprintf('\t\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockBasicResults.(blockStr).rt,nameBlockBasicResults.(blockStr).rt_cor,nameBlockBasicResults.(blockStr).rt_inc);
                    fprintf('\t\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockSubordResults.(blockStr).rt,nameBlockSubordResults.(blockStr).rt_cor,nameBlockSubordResults.(blockStr).rt_inc);
                    
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

function results = accAndRT(thisCond)

% accuracy
results.acc = mean([thisCond.acc] == 1);
%fprintf('\t\tAccuracy:\t\t%.4f (%d/%d)\n',thisCondAcc,sum([thisCond.acc]),length([thisCond.acc]));
% RT
results.rt = mean([thisCond.rt]);
results.rt_cor = mean([thisCond([thisCond.acc] == 1).rt]);
results.rt_inc = mean([thisCond([thisCond.acc] == 0).rt]);
%fprintf('\t\tRT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',thisCondRT,thisCondRTcor,thisCondRTinc);

end


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
                
                % filter the events that we want
                matchResp = events.(sesName).(fn)(strcmp({events.(sesName).(fn).type},'MATCH_RESP'));
                
                % exclude missed responses ('none')
                matchResp = matchResp(~strcmp({matchResp.resp},'none'));
                % % set missing responses to incorrect
                % matchResp(strcmp({matchResp.resp},'none')).resp = 0;
                
                fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                
                % compute overall accuracy
                if length(matchResp) == length([matchResp.acc])
                  matchAcc = mean([matchResp.acc]);
                else
                  fprintf('Something is wrong with matching trial counts\n');
                  keyboard
                end
                fprintf('\tAccuracy:\t%.3f (%d/%d)\n',matchAcc,sum([matchResp.acc]),length([matchResp.acc]));
                % compute overall RT
                matchRT = mean([matchResp.rt]);
                matchRTcor = mean([matchResp([matchResp.acc] == 1).rt]);
                matchRTinc = mean([matchResp([matchResp.acc] == 0).rt]);
                fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchRT,matchRTcor,matchRTinc);
                
                % basic and subordinate accuracy
                matchBasic = matchResp([matchResp.isSubord] == 0);
                matchSubord = matchResp([matchResp.isSubord] == 1);
                matchBasicAcc = mean([matchBasic.acc]);
                matchSubordAcc = mean([matchSubord.acc]);
                fprintf('\t\tBasic accuracy:\t\t%.3f (%d/%d)\n',matchBasicAcc,sum([matchBasic.acc]),length([matchBasic.acc]));
                fprintf('\t\tSubordinate accuracy:\t%.3f (%d/%d)\n',matchSubordAcc,sum([matchSubord.acc]),length([matchSubord.acc]));
                % basic and subordinate RT
                matchBasicRT = mean([matchBasic.rt]);
                matchBasicRTcor = mean([matchBasic([matchBasic.acc] == 1).rt]);
                matchBasicRTinc = mean([matchBasic([matchBasic.acc] == 0).rt]);
                matchSubordRT = mean([matchSubord.rt]);
                matchSubordRTcor = mean([matchSubord([matchSubord.acc] == 1).rt]);
                matchSubordRTinc = mean([matchSubord([matchSubord.acc] == 0).rt]);
                fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchBasicRT,matchBasicRTcor,matchBasicRTinc);
                fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchSubordRT,matchSubordRTcor,matchSubordRTinc);
                
                % accuracy for the different image manipulation conditions
                imgConds = unique({matchResp.imgCond});
                if length(imgConds) > 1
                  fprintf('\n');
                  for im = 1:length(imgConds)
                    matchCond = matchResp(strcmp({matchResp.imgCond},imgConds{im}));
                    matchCondAcc = mean([matchCond.acc]);
                    fprintf('\t%s:\tAccuracy:\t%.3f (%d/%d)\n',imgConds{im},matchCondAcc,sum([matchCond.acc]),length([matchCond.acc]));
                    
                    % basic and subordinate for this manipulation
                    matchCondBasic = matchResp([matchCond.isSubord] == 0);
                    matchCondSubord = matchResp([matchCond.isSubord] == 1);
                    matchCondBasicAcc = mean([matchCondBasic.acc]);
                    matchCondSubordAcc = mean([matchCondSubord.acc]);
                    fprintf('\t\tBasic accuracy:\t\t%.3f (%d/%d)\n',matchCondBasicAcc,sum([matchCondBasic.acc]),length([matchCondBasic.acc]));
                    fprintf('\t\tSubord accuracy:\t%.3f (%d/%d)\n',matchCondSubordAcc,sum([matchCondSubord.acc]),length([matchCondSubord.acc]));
                    % response time
                    matchCondBasicRT = mean([matchCondBasic.rt]);
                    matchCondBasicRTcor = mean([matchCondBasic([matchCondBasic.acc] == 1).rt]);
                    matchCondBasicRTinc = mean([matchCondBasic([matchCondBasic.acc] == 0).rt]);
                    matchCondSubordRT = mean([matchCondSubord.rt]);
                    matchCondSubordRTcor = mean([matchCondSubord([matchCondSubord.acc] == 1).rt]);
                    matchCondSubordRTinc = mean([matchCondSubord([matchCondSubord.acc] == 0).rt]);
                    fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondBasicRT,matchCondBasicRTcor,matchCondBasicRTinc);
                    fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondSubordRT,matchCondSubordRTcor,matchCondSubordRTinc);
                  end
                end
                
              case {'name', 'nametrain', 'prac_name'}
                
                if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
                  nBlocks = 1;
                else
                  nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
                end
                
                % filter the events that we want
                nameResp = events.(sesName).(fn)(strcmp({events.(sesName).(fn).type},'NAME_RESP'));
                
                % exclude missed responses ('none')
                nameResp = nameResp([nameResp.resp] ~= -1);
                % % set missing response to incorrect
                % nameResp([nameResp.resp] == -1) = 0;
                
                if length(nameResp) == length([nameResp.acc])
                  nameAcc = mean([nameResp.acc]);
                else
                  fprintf('Something is wrong with naming trial counts\n');
                  keyboard
                end
                
                fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                % compute overall accuracy
                if nBlocks == 1
                  descripStr = 'Accuracy';
                elseif nBlocks > 1
                  descripStr = 'Overall accuracy';
                end
                fprintf('\t%s:\t%.3f (%d/%d)\n',descripStr,nameAcc,sum([nameResp.acc]),length([nameResp.acc]));
                % compute overall RT
                nameRT = mean([nameResp.rt]);
                nameRTcor = mean([nameResp([nameResp.acc] == 1).rt]);
                nameRTinc = mean([nameResp([nameResp.acc] == 0).rt]);
                fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameRT,nameRTcor,nameRTinc);
                
                % basic and subordinate accuracy
                nameBasic = nameResp([nameResp.isSubord] == 0);
                nameSubord = nameResp([nameResp.isSubord] == 1);
                nameBasicAcc = mean([nameBasic.acc]);
                nameSubordAcc = mean([nameSubord.acc]);
                fprintf('\t\tBasic accuracy:\t\t%.3f (%d/%d)\n',nameBasicAcc,sum([nameBasic.acc]),length([nameBasic.acc]));
                fprintf('\t\tSubord accuracy:\t%.3f (%d/%d)\n',nameSubordAcc,sum([nameSubord.acc]),length([nameSubord.acc]));
                % basic and subordinate RT
                nameBasicRT = mean([nameBasic.rt]);
                nameBasicRTcor = mean([nameBasic([nameBasic.acc] == 1).rt]);
                nameBasicRTinc = mean([nameBasic([nameBasic.acc] == 0).rt]);
                nameSubordRT = mean([nameSubord.rt]);
                nameSubordRTcor = mean([nameSubord([nameSubord.acc] == 1).rt]);
                nameSubordRTinc = mean([nameSubord([nameSubord.acc] == 0).rt]);
                fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBasicRT,nameBasicRTcor,nameBasicRTinc);
                fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameSubordRT,nameSubordRTcor,nameSubordRTinc);
                
                % % accuracy for the different image manipulation conditions
                % imgConds = unique({nameResp.imgCond});
                % if length(imgConds) > 1
                %   for im = 1:length(imgConds)
                %     nameCond = nameResp(strcmp({nameResp.imgCond},imgConds{im}));
                %     nameCondAcc = mean([nameCond.acc]);
                %     fprintf('\t%s:\tAccuracy:\t%.3f (%d/%d)\n',imgConds{im},nameCondAcc,sum([nameCond.acc]),length([nameCond.acc]));
                %   end
                % end
                
                if nBlocks > 1
                  fprintf('\n');
                  for b = 1:nBlocks
                    nameBlock = nameResp([nameResp.block] == b);
                    
                    if length(nameBlock) == length([nameBlock.acc])
                      nameBlockAcc = mean([nameBlock.acc]);
                    else
                      fprintf('Something is wrong with naming trial counts\n');
                      keyboard
                    end
                    
                    fprintf('\tBlock %d: Accuracy:\t%.3f (%d/%d)\n',b,nameBlockAcc,sum([nameBlock.acc]),length([nameBlock.acc]));
                    
                    % basic and subordinate within this block
                    %
                    % accuracy
                    nameBlockBasic = nameResp([nameBlock.isSubord] == 0);
                    nameBlockSubord = nameResp([nameBlock.isSubord] == 1);
                    nameBlockBasicAcc = mean([nameBlockBasic.acc]);
                    nameBlockSubordAcc = mean([nameBlockSubord.acc]);
                    fprintf('\t\tBasic accuracy:\t\t%.3f (%d/%d)\n',nameBlockBasicAcc,sum([nameBlockBasic.acc]),length([nameBlockBasic.acc]));
                    fprintf('\t\tSubord accuracy:\t%.3f (%d/%d)\n',nameBlockSubordAcc,sum([nameBlockSubord.acc]),length([nameBlockSubord.acc]));
                    % response time
                    nameBlockBasicRT = mean([nameBlockBasic.rt]);
                    nameBlockBasicRTcor = mean([nameBlockBasic([nameBlockBasic.acc] == 1).rt]);
                    nameBlockBasicRTinc = mean([nameBlockBasic([nameBlockBasic.acc] == 0).rt]);
                    nameBlockSubordRT = mean([nameBlockSubord.rt]);
                    nameBlockSubordRTcor = mean([nameBlockSubord([nameBlockSubord.acc] == 1).rt]);
                    nameBlockSubordRTinc = mean([nameBlockSubord([nameBlockSubord.acc] == 0).rt]);
                    fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockBasicRT,nameBlockBasicRTcor,nameBlockBasicRTinc);
                    fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockSubordRT,nameBlockSubordRTcor,nameBlockSubordRTinc);
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

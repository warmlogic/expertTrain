function et_beh_analysis(cfg,expParam,events)


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
              
              if length(matchResp) == length([matchResp.acc])
                matchAcc = mean([matchResp.acc]);
              else
                fprintf('Something is wrong with matching trial counts\n');
                keyboard
              end
              
              fprintf('%s, %s, %s: Accuracy:\t%.3f (%d/%d)\n',expParam.subject,sesName,fn,matchAcc,sum([matchResp.acc]),length([matchResp.acc]));
              
            case {'name', 'nametrain', 'prac_name'}
              
              if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
                nBlocks = 1;
              else
                nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
              end
              
              % filter the events that we want
              nameResp = events.(sesName).(fn)(strcmp({events.(sesName).(fn).type},'NAME_RESP'));
              
              if length(nameResp) == length([nameResp.acc])
                nameAcc = mean([nameResp.acc]);
              else
                fprintf('Something is wrong with naming trial counts\n');
                keyboard
              end
              
              fprintf('%s, %s, %s: Overall accuracy:\t%.3f (%d/%d)\n',expParam.subject,sesName,fn,nameAcc,sum([nameResp.acc]),length([nameResp.acc]));
              
              if nBlocks > 1
                for b = 1:nBlocks
                  nameRespBlock = nameResp([nameResp.block] == b);
                  
                  if length(nameRespBlock) == length([nameRespBlock.acc])
                    nameBlockAcc = mean([nameRespBlock.acc]);
                  else
                    fprintf('Something is wrong with naming trial counts\n');
                    keyboard
                  end
                  
                  fprintf('%s, %s, %s: Block %d accuracy:\t%.3f (%d/%d)\n',expParam.subject,sesName,fn,b,nameBlockAcc,sum([nameRespBlock.acc]),length([nameRespBlock.acc]));
                end
              end
              
          end % switch phaseName
          
        else
          fprintf('%s, %s: phase %s does not exist.\n',expParam.subject,sesName,fn);
        end % isfield phaseName
        
      end % isExp
      
    end % for pha
    
    % put a space between sessions
    fprintf('\n');
      
  else
    fprintf('%s: session %s does not exist.\n',expParam.subject,sesName);
  end % isfield sesName
  
end % for ses



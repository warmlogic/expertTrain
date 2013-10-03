function [results] = space_processData(dataroot,subjects,onlyCompleteSub,printResults,saveResults)
% function [results] = space_processData(dataroot,subjects,onlyCompleteSub,printResults,saveResults)
%
% Processes data into basic measures like accuracy, response time, and d-prime

if ~exist('subjects','var') || isempty(subjects)
  subjects = {
    'SPACE001';
    'SPACE002';
    'SPACE003';
    'SPACE004';
    'SPACE005';
    'SPACE006';
    'SPACE007';
    'SPACE008';
    'SPACE009';
    'SPACE010';
    'SPACE011';
    'SPACE012';
    'SPACE013';
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
% massed = r1data(~strcmp({r1data.recog_resp},'none') & [r1data.targ] == true & [r1data.spaced] == false & [r1data.lag] == 0);
% spaced = r1data(~strcmp({r1data.recog_resp},'none') & [r1data.targ] == true & [r1data.spaced] == true & [r1data.lag] > 0);
% onePres = r1data(~strcmp({r1data.recog_resp},'none') & [r1data.targ] == true & [r1data.spaced] == false & [r1data.lag] == -1);
% newStims = r1data(~strcmp({r1data.recog_resp},'none') & [r1data.targ] == false);
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
% fprintf('Spaced recall acc (%d/%d) = %.3f\n',sum([spaced.recall_spellCorr]),length(spaced),mean([spaced.recall_spellCorr]));
% fprintf('Massed recall acc (%d/%d) = %.3f\n',sum([massed.recall_spellCorr]),length(massed),mean([massed.recall_spellCorr]));
% fprintf('onePres recall acc (%d/%d) = %.3f\n',sum([onePres.recall_spellCorr]),length(onePres),mean([onePres.recall_spellCorr]));
% %fprintf('newStims recall acc %.3f\n',mean([newStims.recall_spellCorr]));


%% some constants

%nBlocks = 3;

% lagConds = [8, 0, -1];

results = struct;

dataFields = {'nTrials','nCor','nInc','acc','dp','rt','rt_cor','rt_inc'};
mainFields = {'recog','recall'};

%% initialize to store the data

% use subject 1's files for initialization
sub = 5;
subDir = fullfile(dataroot,subjects{sub});
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
        switch phaseName
          case {'cued_recall'}
            lagConds = unique([events.(sesName).(fn).data.lag]);
            
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
              
              for mf = 1:length(mainFields)
                for df = 1:length(dataFields)
                  results.(sesName).(fn).(lagStr).(mainFields{mf}).(dataFields{df}) = nan(length(subjects),1);
                end
              end
              
              %             imgConds = unique({events.(sesName).(fn).data.imgCond});
              %             if length(imgConds) > 1
              %               for im = 1:length(imgConds)
              %                 for mf = 1:length(mainFields)
              %                   for df = 1:length(dataFields)
              %                     results.(sesName).(fn).(lagStr).(imgConds{im}).(mainFields{mf}).(dataFields{df}) = nan(length(subjects),1);
              %                   end
              %                 end
              %               end
              %             end
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
        
        % accidently set isExp=true for prac_distract_math
        if ~isempty(strfind(phaseName,'prac_')) && cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          cfg.stim.(sesName).(phaseName)(phaseCount).isExp = false;
        end
        
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          
          % set the phase name with phase count
          fn = sprintf(sprintf('%s_%d',phaseName,phaseCount));
          
          if isfield(events.(sesName),fn)
            
            % collect data if this phase is complete
            if events.(sesName).(fn).isComplete
              
              switch phaseName
                case {'cued_recall'}
                  lagConds = unique([events.(sesName).(fn).data.lag]);
                  
                  if sum(lagConds(lagConds > 0)) > 1
                    error('%s does not yet support multiple lag conditions!',mfilename);
                  end
                  
                  for lc = 1:length(lagConds)
                    fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                    
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
                        if printResults
                          fprintf('*** Once ***\n');
                        end
                        lagStr = 'once';
                      end
                    elseif length(lagConds(lc)) > 1
                      if printResults
                        fprintf('Multi?\n');
                      end
                      lagStr = 'all';
                    end
                    
                    % filter the events that we want
                    %recog_spaced_resp = events.(sesName).(fn).data(ismember({events.(sesName).(fn).data.type},'RECOGTEST_RECOGRESP') & ismember([events.(sesName).(fn).data.lag],lagConds(lc)));
                    
                    % exclude missed responses ('none')
                    %recog_spaced_resp = recog_spaced_resp(~ismember({recog_spaced_resp.recog_resp},'none'));
                    % % set missing responses to incorrect
                    % noRespInd = find(ismember({matchResp.resp},'none'));
                    % if ~isempty(noRespInd)
                    %   for nr = 1:length(noRespInd)
                    %     matchResp(noRespInd(nr)).acc = 0;
                    %   end
                    % end
                    
                    for mf = 1:length(mainFields)
                      thisField = mainFields{mf};
                      
                      % filter the events that we want
                      theseEvents = events.(sesName).(fn).data(strcmpi({events.(sesName).(fn).data.type},sprintf('RECOGTEST_%sRESP',thisField)) & ismember([events.(sesName).(fn).data.lag],lagConds(lc)));
                      
                      if strcmp(thisField,'recog')
                        % exclude missed responses ('none')
                        theseEvents = theseEvents(~ismember({theseEvents.recog_resp},'none'));
                      end
                      
                      if strcmp(thisField,'recog')
                        accField = sprintf('%s_acc',thisField);
                      elseif strcmp(thisField,'recall')
                        accField = sprintf('%s_spellCorr',thisField);
                      end
                      nCorField = sprintf('%s_nCor',thisField);
                      nIncField = sprintf('%s_nInc',thisField);
                      rtField = sprintf('%s_rt',thisField);
                      
                      results.(sesName).(fn).(lagStr) = accAndRT(theseEvents,sub,results.(sesName).(fn).(lagStr),thisField,accField,nCorField,nIncField,rtField);
                      theseResults = results.(sesName).(fn).(lagStr).(thisField);
                      if printResults
                        fprintf('\t%s',thisField);
                        fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',theseResults.(accField)(sub),theseResults.(nCorField)(sub),(theseResults.(nCorField)(sub) + theseResults.(nIncField)(sub)),theseResults.dp(sub));
                        fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',theseResults.(rtField)(sub),theseResults.(sprintf('%s_cor',rtField))(sub),theseResults.(sprintf('%s_inc',rtField))(sub));
                      end
                    end
                    
                    % basic and subordinate
                    %matchBasic = recog_spaced_resp([recog_spaced_resp.isSubord] == 0);
                    %matchSubord = recog_spaced_resp([recog_spaced_resp.isSubord] == 1);
                    
                    %                   thisField = 'basic';
                    %                   results.(sesName).(fn).(lagStr) = accAndRT(matchBasic,sub,results.(sesName).(fn).(lagStr),thisField);
                    %                   matchBasicResults = results.(sesName).(fn).(lagStr).(thisField);
                    %                   thisField = 'subord';
                    %                   results.(sesName).(fn).(lagStr) = accAndRT(matchSubord,sub,results.(sesName).(fn).(lagStr),thisField);
                    %                   matchSubordResults = results.(sesName).(fn).(lagStr).(thisField);
                    %                   if printResults
                    %                     fprintf('\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',matchBasicResults.acc(sub),matchBasicResults.nCor(sub),(matchBasicResults.nCor(sub) + matchBasicResults.nInc(sub)),matchBasicResults.dp(sub));
                    %                     fprintf('\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',matchSubordResults.acc(sub),matchSubordResults.nCor(sub),(matchSubordResults.nCor(sub) + matchSubordResults.nInc(sub)),matchSubordResults.dp(sub));
                    %                     fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchBasicResults.rt(sub),matchBasicResults.rt_cor(sub),matchBasicResults.rt_inc(sub));
                    %                     fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchSubordResults.rt(sub),matchSubordResults.rt_cor(sub),matchSubordResults.rt_inc(sub));
                    %                   end
                    
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
                    
                    %                   % accuracy for the different image manipulation conditions
                    %                   imgConds = unique({matchResp.imgCond});
                    %                   % if there's only 1 image manipulation condition, the
                    %                   % results were printed above
                    %                   if length(imgConds) > 1
                    %                     fprintf('\n');
                    %                     for im = 1:length(imgConds)
                    %                       % overall for this manipulation
                    %                       matchCond = matchResp(ismember({matchResp.imgCond},imgConds{im}));
                    %
                    %                       thisField = 'overall';
                    %                       results.(sesName).(fn).(lagStr).(imgConds{im}) = accAndRT(matchCond,sub,results.(sesName).(fn).(lagStr).(imgConds{im}),thisField);
                    %                       matchCondResults = results.(sesName).(fn).(lagStr).(imgConds{im}).(thisField);
                    %                       if printResults
                    %                         fprintf('\t%s:',imgConds{im});
                    %                         fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',matchCondResults.acc(sub),matchCondResults.nCor(sub),(matchCondResults.nCor(sub) + matchCondResults.nInc(sub)),matchCondResults.dp(sub));
                    %                         fprintf('\t');
                    %                         fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondResults.rt(sub),matchCondResults.rt_cor(sub),matchCondResults.rt_inc(sub));
                    %                       end
                    %
                    %                       % basic and subordinate for this manipulation
                    %                       matchCondBasic = matchResp([matchCond.isSubord] == 0);
                    %                       matchCondSubord = matchResp([matchCond.isSubord] == 1);
                    %
                    %                       thisField = 'basic';
                    %                       results.(sesName).(fn).(lagStr).(imgConds{im}) = accAndRT(matchCondBasic,sub,results.(sesName).(fn).(lagStr).(imgConds{im}),thisField);
                    %                       matchCondBasicResults = results.(sesName).(fn).(lagStr).(imgConds{im}).(thisField);
                    %                       thisField = 'subord';
                    %                       results.(sesName).(fn).(lagStr).(imgConds{im}) = accAndRT(matchCondSubord,sub,results.(sesName).(fn).(lagStr).(imgConds{im}),thisField);
                    %                       matchCondSubordResults = results.(sesName).(fn).(lagStr).(imgConds{im}).(thisField);
                    %                       if printResults
                    %                         fprintf('\t\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',matchCondBasicResults.acc(sub),matchCondBasicResults.nCor(sub),(matchCondBasicResults.nCor(sub) + matchCondBasicResults.nInc(sub)),matchCondBasicResults.dp(sub));
                    %                         fprintf('\t\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',matchCondSubordResults.acc(sub),matchCondSubordResults.nCor(sub),(matchCondSubordResults.nCor(sub) + matchCondSubordResults.nInc(sub)),matchCondSubordResults.dp(sub));
                    %                         fprintf('\t\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondBasicResults.rt(sub),matchCondBasicResults.rt_cor(sub),matchCondBasicResults.rt_inc(sub));
                    %                         fprintf('\t\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',matchCondSubordResults.rt(sub),matchCondSubordResults.rt_cor(sub),matchCondSubordResults.rt_inc(sub));
                    %                       end
                    %                     end
                    %                   end
                    
                  end
                  
                  %               case {'name', 'nametrain', 'prac_name'}
                  %                 fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                  %
                  %                 if ~iscell(expParam.session.(sesName).(phaseName)(phaseCount).nameStims)
                  %                   nBlocks = 1;
                  %                 else
                  %                   nBlocks = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
                  %                 end
                  %
                  %                 % filter the events that we want
                  %                 nameResp = events.(sesName).(fn).data(ismember({events.(sesName).(fn).data.type},'NAME_RESP'));
                  %
                  %                 % exclude missed responses (-1)
                  %                 nameResp = nameResp([nameResp.resp] ~= -1);
                  %                 % set missing response to incorrect
                  %                 % noRespInd = find([nameResp.resp] == -1);
                  %                 % if ~isempty(noRespInd)
                  %                 %   for nr = 1:length(noRespInd)
                  %                 %     nameResp(noRespInd(nr)).acc = 0;
                  %                 %   end
                  %                 % end
                  %
                  %                 % overall
                  %                 thisField = 'overall';
                  %                 results.(sesName).(fn) = accAndRT(nameResp,sub,results.(sesName).(fn),thisField);
                  %                 nameResults = results.(sesName).(fn).(thisField);
                  %                 if printResults
                  %                   fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',nameResults.acc(sub),nameResults.nCor(sub),(nameResults.nCor(sub) + nameResults.nInc(sub)),nameResults.dp(sub));
                  %                   fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameResults.rt(sub),nameResults.rt_cor(sub),nameResults.rt_inc(sub));
                  %                 end
                  %
                  %                 % basic and subordinate
                  %                 nameBasic = nameResp([nameResp.isSubord] == 0);
                  %                 nameSubord = nameResp([nameResp.isSubord] == 1);
                  %
                  %                 thisField = 'basic';
                  %                 results.(sesName).(fn) = accAndRT(nameBasic,sub,results.(sesName).(fn),thisField);
                  %                 nameBasicResults = results.(sesName).(fn).(thisField);
                  %                 thisField = 'subord';
                  %                 results.(sesName).(fn) = accAndRT(nameSubord,sub,results.(sesName).(fn),thisField);
                  %                 nameSubordResults = results.(sesName).(fn).(thisField);
                  %                 if printResults
                  %                   fprintf('\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',nameBasicResults.acc(sub),nameBasicResults.nCor(sub),(nameBasicResults.nCor(sub) + nameBasicResults.nInc(sub)),nameBasicResults.dp(sub));
                  %                   fprintf('\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',nameSubordResults.acc(sub),nameSubordResults.nCor(sub),(nameSubordResults.nCor(sub) + nameSubordResults.nInc(sub)),nameSubordResults.dp(sub));
                  %                   fprintf('\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBasicResults.rt(sub),nameBasicResults.rt_cor(sub),nameBasicResults.rt_inc(sub));
                  %                   fprintf('\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameSubordResults.rt(sub),nameSubordResults.rt_cor(sub),nameSubordResults.rt_inc(sub));
                  %                 end
                  %
                  %                 % if there's only 1 block, the results were printed above
                  %                 if nBlocks > 1
                  %                   fprintf('\n');
                  %                   for b = 1:nBlocks
                  %                     blockStr = sprintf('b%d',b);
                  %
                  %                     % overall
                  %                     nameBlock = nameResp([nameResp.block] == b);
                  %
                  %                     thisField = 'overall';
                  %                     results.(sesName).(fn).(blockStr) = accAndRT(nameBlock,sub,results.(sesName).(fn).(blockStr),thisField);
                  %                     nameBlockResults = results.(sesName).(fn).(blockStr).(thisField);
                  %                     if printResults
                  %                       fprintf('\tB%d:',b);
                  %                       fprintf('\tAccuracy:\t%.4f (%d/%d), d''=%.2f\n',nameBlockResults.acc(sub),nameBlockResults.nCor(sub),(nameBlockResults.nCor(sub) + nameBlockResults.nInc(sub)),nameBlockResults.dp(sub));
                  %                       fprintf('\t');
                  %                       fprintf('\tRespTime:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockResults.rt(sub),nameBlockResults.rt_cor(sub),nameBlockResults.rt_inc(sub));
                  %                     end
                  %
                  %                     % basic and subordinate for this block
                  %                     nameBlockBasic = nameBlock([nameBlock.isSubord] == 0);
                  %                     nameBlockSubord = nameBlock([nameBlock.isSubord] == 1);
                  %
                  %                     thisField = 'basic';
                  %                     results.(sesName).(fn).(blockStr) = accAndRT(nameBlockBasic,sub,results.(sesName).(fn).(blockStr),thisField);
                  %                     nameBlockBasicResults = results.(sesName).(fn).(blockStr).(thisField);
                  %                     thisField = 'subord';
                  %                     results.(sesName).(fn).(blockStr) = accAndRT(nameBlockSubord,sub,results.(sesName).(fn).(blockStr),thisField);
                  %                     nameBlockSubordResults = results.(sesName).(fn).(blockStr).(thisField);
                  %                     if printResults
                  %                       fprintf('\t\t\tBasic acc:\t%.4f (%d/%d), d''=%.2f\n',nameBlockBasicResults.acc(sub),nameBlockBasicResults.nCor(sub),(nameBlockBasicResults.nCor(sub) + nameBlockBasicResults.nInc(sub)),nameBlockBasicResults.dp(sub));
                  %                       fprintf('\t\t\tSubord acc:\t%.4f (%d/%d), d''=%.2f\n',nameBlockSubordResults.acc(sub),nameBlockSubordResults.nCor(sub),(nameBlockSubordResults.nCor(sub) + nameBlockSubordResults.nInc(sub)),nameBlockSubordResults.dp(sub));
                  %                       fprintf('\t\t\tBasic RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockBasicResults.rt(sub),nameBlockBasicResults.rt_cor(sub),nameBlockBasicResults.rt_inc(sub));
                  %                       fprintf('\t\t\tSubord RT:\t%.2f ms (cor: %.2f, inc: %.2f)\n',nameBlockSubordResults.rt(sub),nameBlockSubordResults.rt_cor(sub),nameBlockSubordResults.rt_inc(sub));
                  %                     end
                  %
                  %                   end
                  %                 end
                  
              end % switch phaseName
              
            else
              fprintf('%s, %s: phase %s is incomplete.\n',expParam.subject,sesName,fn);
            end % phaseName complete
          else
            fprintf('%s, %s: phase %s does not exist.\n',expParam.subject,sesName,fn);
          end % field doesn't exist
        end % isExp
        
      end % for pha
      fprintf('\n');
    end % for ses
  else
    fprintf('\t%s, %s: session is incomplete. Not including in results.\n',expParam.subject,sesName);
  end % onlyComplete check
end % for sub
fprintf('Done processing data for experiment %s.\n\n',expName);

if saveResults
  fileName = fullfile(dataroot,sprintf('%s_behav_results.txt',expName));
  printResultsToFile(dataroot,subjects,results,fileName);
end

end % function

%% print to file

function printResultsToFile(dataroot,subjects,results,fileName)

fprintf('Saving results to file: %s.\n',fileName);

fid = fopen(fileName,'wt');

mainToPrint = {'recog','recall'};
generic_dataToPrint = {'nTrials','nCor','acc','dp','rt','rt_cor','rt_inc'};
dataToPrint = {...
  {'nTrials','recog_nCor','recog_acc','dp','recog_rt','recog_rt_cor','recog_rt_inc'},...
  {'nTrials','recall_nCor','recall_spellCorr','dp','recall_rt','recall_rt_cor','recall_rt_inc'}};

% use subject 1's files for initialization
sub = 5;
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
      
      if isfield(events.(sesName),fn)
        
        fprintf(fid,'phase\t%s\n',fn);
        
        switch phaseName
          case {'cued_recall'}
            lagConds = unique([events.(sesName).(fn).data.lag]);
            
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
              
              %               matchResp = events.(sesName).(fn).data(ismember({events.(sesName).(fn).data.type},'MATCH_RESP') & ismember([events.(sesName).(fn).data.lag],lagConds(lc)));
              %
              %               imgConds = unique({matchResp.imgCond});
              %               if length(imgConds) > 1
              %                 headerCell = {{lagStr},imgConds,mainToPrint};
              %                 [headerStr] = setHeaderStr(headerCell,length(dataToPrint));
              %                 fprintf(fid,sprintf('\t%s\n',headerStr));
              %                 [headerStr] = setHeaderStr({dataToPrint},1);
              %                 headerStr = sprintf('\t%s',headerStr);
              %                 headerStr = repmat(headerStr,1,prod(cellfun('prodofsize', headerCell)));
              %                 fprintf(fid,sprintf('%s\n',headerStr));
              %
              %                 for sub = 1:length(subjects)
              %                   dataStr = subjects{sub};
              %                   for im = 1:length(imgConds)
              %                     for mf = 1:length(mainToPrint)
              %                       [dataStr] = setDataStr(dataStr,{sesName,fn,lagStr,imgConds{im},mainToPrint{mf}},results,sub,dataToPrint);
              %                     end
              %                   end
              %                   fprintf(fid,sprintf('%s\n',dataStr));
              %                 end
              %
              %               else
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              %keyboard
              
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
            if lc ~= length(lagConds)
              fprintf(fid,'\n');
            end
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
        fprintf('%s, %s: phase %s does not exist.\n',expParam.subject,sesName,fn);
      end
    end
  end
end

% close out the results file
fprintf('Saving %s...',fileName);
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

theseResults = eval(sprintf('results%s',sprintf(repmat('.%s',1,size(structFields)),structFields{:})));

for i = 1:length(dataToPrint)
  if ~isnan(theseResults.(dataToPrint{i})(sub))
    dataStr = sprintf('%s\t%.4f',dataStr,theseResults.(dataToPrint{i})(sub));
  else
    dataStr = sprintf('%s\t',dataStr);
  end
end

end

%% Calculate accuracy and reaction time

function inputStruct = accAndRT(inputData,sub,inputStruct,destField,accField,nCorField,nIncField,rtField)

if ~exist('accField','var') || isempty(accField)
  accField = 'acc';
end
if ~exist('nCorField','var') || isempty(nCorField)
  nCorField = 'nCor';
end
if ~exist('nIncField','var') || isempty(nIncField)
  nIncField = 'nInc';
end
if ~exist('rtField','var') || isempty(rtField)
  rtField = 'rt';
end

if ~isfield(inputStruct,destField)
  error('input structure does not have field called ''%s''!',destField);
end

% trial counts
inputStruct.(destField).(nCorField)(sub) = sum([inputData.(accField)] == 1);
inputStruct.(destField).(nIncField)(sub) = sum([inputData.(accField)] == 0);

nTrials = sum([inputData.(accField)] == 1 | [inputData.(accField)] == 0);
inputStruct.(destField).nTrials(sub) = nTrials;

% accuracy
inputStruct.(destField).(accField)(sub) = inputStruct.(destField).(nCorField)(sub) / nTrials;

% d-prime; adjust for perfect performance, choose 1 of 2 strategies
% (Macmillan & Creelman, 2005; p. 8-9)
strategy = 2;

hr = sum([inputData.(accField)] == 1) / nTrials;
far = sum([inputData.(accField)] == 0) / nTrials;
if hr == 1
  if strategy == 1
    hr = 1 - (1 / (2 * nTrials));
  elseif strategy == 2
    % (Hautus, 1995; Miller, 1996)
    hr = (sum([inputData.(accField)] == 1) + 0.5) / (nTrials + 1);
  end
elseif hr == 0
  if strategy == 1
    hr = 1 / (2 * nTrials);
  elseif strategy == 2
    % (Hautus, 1995; Miller, 1996)
    hr = (sum([inputData.(accField)] == 1) + 0.5) / (nTrials + 1);
  end
end
if far == 1
  if strategy == 1
    far = 1 - (1 / (2 * nTrials));
  elseif strategy == 2
    % (Hautus, 1995; Miller, 1996)
    far = (sum([inputData.(accField)] == 0) + 0.5) / (nTrials + 1);
  end
elseif far == 0
  if strategy == 1
    far = 1 / (2 * nTrials);
  elseif strategy == 2
    % (Hautus, 1995; Miller, 1996)
    far = (sum([inputData.(accField)] == 0) + 0.5) / (nTrials + 1);
  end
end

zhr = norminv(hr,0,1);
zfar = norminv(far,0,1);

inputStruct.(destField).dp(sub) = zhr - zfar;

% % If there are only two points, the slope will always be 1, and d'=da, so
% % we don't need this
% %
% % Find da: Macmillan & Creelman (2005), p. 61--62
% %
% % slope of zROC
% s = zhr/-zfar;
% inputStruct.(destField).da(sub) = (2 / (1 + (s^2)))^(1/2) * (zhr - (s*zfar));

% RT
inputStruct.(destField).(rtField)(sub) = mean([inputData.(rtField)]);
inputStruct.(destField).(sprintf('%s_cor',rtField))(sub) = mean([inputData([inputData.(accField)] == 1).(rtField)]);
inputStruct.(destField).(sprintf('%s_inc',rtField))(sub) = mean([inputData([inputData.(accField)] == 0).(rtField)]);

end


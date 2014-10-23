function [results] = space2_processData(results,dataroot,subjects,collapsePhases,collapseCategories,separateCategories,onlyCompleteSub,printResults,saveResults,partialCredit,prependDestField,quantileMeasure,quantiles,filenameSuffix)
% function [results] = space2_processData(results,dataroot,subjects,collapsePhases,collapseCategories,separateCategories,onlyCompleteSub,printResults,saveResults,partialCredit,prependDestField,quantileMeasure,quantiles,filenameSuffix)
%
% Processes data into basic measures like accuracy, response time, and d-prime
%
% e.g.,
% [results] = space2_processData([],[],[],true,true,true,true,false,true,true,true);
%
% Quantile example (quantileMeasure is a cell array of phase names with
% a paired measure name).
%
% [results] = space2_processData([],[],[],true,true,true,true,false,true,true,true,{'expo','','multistudy','','distract_math','','cued_recall_only','recog_rt'},[.25 .50 .75]);
%
% [results] = space2_processData([],[],[],true,true,true,true,false,true,true,true,{'expo','','multistudy','','distract_math','','cued_recall_only','recog_rt'},3);
%
% [results] = space2_processData([],[],[],true,true,true,true,false,true,true,true,{'expo','','multistudy','','distract_math','','cued_recall_only','recog_rt'},0.5);

plotQhist = false;

if nargin == 14
  if isempty(filenameSuffix)
    filenameSuffix = '';
  end
end


if nargin < 14
  filenameSuffix = '';
  
  if nargin == 13
    if length(quantiles) > 1 && isempty(quantileMeasure)
      error('Need to supply both variables ''quantileMeasure'' and ''quantiles''.');
    elseif length(quantiles) == 1 && quantiles ~= 1 && isempty(quantileMeasure)
      error('Need to supply both variables ''quantileMeasure'' and ''quantiles''.');
    elseif length(quantiles) == 1 && quantiles == 1
      warning('Variable ''quantiles'' set to 1. This includes all the data, so not actually splitting data into quantiles.');
      quantileMeasure = {};
    end
  end
  
  if nargin < 13
    
    if nargin == 12
      if ~isempty(quantileMeasure)
        error('Need to supply both variables ''quantileMeasure'' and ''quantiles''.');
      elseif isempty(quantileMeasure)
        warning('No quantile measure supplied, not splitting data into quantiles.');
        quantiles = 1;
      end
    else
      quantiles = 1;
    end
    
    if nargin < 12
      quantileMeasure = {};
      if nargin < 11
        prependDestField = true;
        if nargin < 10
          partialCredit = true;
          if nargin < 9
            saveResults = true;
            if nargin < 8
              printResults = false;
              if nargin < 7
                onlyCompleteSub = true;
                if nargin < 6
                  separateCategories = true;
                  if nargin < 5
                    collapseCategories = true;
                    if nargin < 4
                      collapsePhases = true;
                      if nargin < 3
                        subjects = [];
                        if nargin < 2
                          dataroot = [];
                          if nargin < 1
                            results = [];
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

% figure out how many quantiles to use to split the data
if length(quantiles) == 1 && quantiles == 1
  nQuantiles = 0;
elseif length(quantiles) == 1 && quantiles ~= 1
  % this can happen when splitting the data in two (using a proportion less
  % than 1); or with a scalar splitting the data by N quantiles
  if quantiles < 1
    nQuantiles = 1;
  elseif quantiles > 1
    nQuantiles = quantiles;
  end
elseif length(quantiles) > 1
  nQuantiles = length(quantiles);
end
nDivisions = nQuantiles + 1;

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

% behavioral pilot
if ~exist('subjects','var') || isempty(subjects)
  subjects = {
    'SPACE2001';
    'SPACE2002';
    'SPACE2003';
    'SPACE2004';
    'SPACE2005';
    'SPACE2006';
    'SPACE2007';
    'SPACE2008';
    'SPACE2009';
    'SPACE2010';
    'SPACE2011';
    'SPACE2012';
    'SPACE2013';
    'SPACE2014';
    'SPACE2015';
    'SPACE2016';
    'SPACE2017';
    'SPACE2018';
    'SPACE2019';
    'SPACE2020';
    'SPACE2021';
    'SPACE2022';
    'SPACE2023';
    'SPACE2024';
    'SPACE2025';
    'SPACE2026';
    'SPACE2027';
    'SPACE2028';
    'SPACE2029';
    'SPACE2029-2';
    'SPACE2030';
    'SPACE2031';
    'SPACE2032';
    'SPACE2033';
    'SPACE2034';
    'SPACE2035';
    'SPACE2036';
    };
end

% use a specific subject's files as a template for loading data
templateSubject = 'SPACE2001';

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

beh_dir = 'behavioral_pilot';
% beh_dir = 'Behavioral';

% find where the data is stored
if ~exist('dataroot','var') || isempty(dataroot)
  serverDir = fullfile(filesep,'Volumes','curranlab','Data',expName,beh_dir,'Sessions');
  serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data',expName,beh_dir,'Sessions');
  localDir = fullfile(getenv('HOME'),'data',expName,beh_dir,'Sessions');
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

%% some constants

%nBlocks = 3;

% lagConds = [8, 0, -1];

% mainFields_expo = {'rating'};
% dataFields_expo = {{'resp', 'rt'}};

% mainFields = {'recog','recall'};
mainFields = {'recall'};
dataFields = {...
  {'nTrial','nTarg','nLure','nHit','nMiss','nCR','nFA','hr','mr','crr','far','dp','rt','rt_hit','rt_miss','rt_cr','rt_fa','c','Pr','Br'} ...
  {'nTrial','nTarg','nHit','nMiss','hr','mr','rt','rt_hit','rt_miss'} ...
  };

% % remove these fields when there's no noise distribution (i.e., recall
% % events)
% rmfieldNoNoise = {'nLure','nCR','nFA','crr','far','dp','rt_cr','rt_fa','c','Pr','Br'};

% categories = [1, 2];
% categoryStr = {'faces', 'houses'};

if isempty(results)
  % initialize to store the data
  
  results = struct;
  
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
  
  % hack
  if strcmp(beh_dir,'behavioral_pilot')
    expParam.sesTypes = {'day1'};
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
          
          if ~isempty(quantileMeasure)
            results.(sesName).(fn).quantiles = nan(length(subjects),nQuantiles);
          end
          
          switch phaseName
%             case {'expo'}
%               respEvents = events.oneDay.expo.data(strcmp({events.oneDay.expo.data.type},'EXPO_RESP'));
%               
%               if collapseCategories
%                 for mf = 1:length(mainFields_expo)
%                   mField = mainFields_expo{mf};
%                   for df = 1:length(dataFields_expo{mf})
%                     dField = dataFields_expo{mf}{df};
%                     
%                     results.(sesName).(fn).(mField).(sprintf('%s_%s',mField,dField)) = nan(length(subjects),nDivisions);
%                   end
%                 end
%               end
%               
%               % image categories
%               i_catStrs = unique({respEvents.i_catStr},'sorted');
%               if length(i_catStrs) > 1 && separateCategories
%                 for im = 1:length(i_catStrs)
%                   for mf = 1:length(mainFields_expo)
%                     mField = mainFields_expo{mf};
%                     for df = 1:length(dataFields_expo{mf})
%                       dField = dataFields_expo{mf}{df};
%                       
%                       results.(sesName).(fn).(i_catStrs{im}).(mField).(sprintf('%s_%s',mField,dField)) = nan(length(subjects),nDivisions);
%                     end
%                   end
%                 end
%               end
              
            case {'cued_recall_only'}
              targEvents = events.(sesName).(fn).data([events.(sesName).(fn).data.targ]);
              %lureEvents = events.(sesName).(fn).data(~[events.(sesName).(fn).data.targ]);
              
              lagConds = unique([targEvents.lag],'sorted');
              
              for lc = 1:length(lagConds)
                % choose the training condition
                if length(lagConds(lc)) == 1
                  if lagConds(lc) > 0
                    lagStr = sprintf('lag%d',lagConds(lc));
                    %lagStr = 'spaced';
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
                      
                      results.(sesName).(fn).(lagStr).(mField).(sprintf('%s_%s',mField,dField)) = nan(length(subjects),nDivisions);
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
                        
                        results.(sesName).(fn).(lagStr).(i_catStrs{im}).(mField).(sprintf('%s_%s',mField,dField)) = nan(length(subjects),nDivisions);
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
              %                   results.(sesName).(fn).(sprintf('b%d',b)).(mainFields{mf}).(dataFields{df}) = nan(length(subjects),nDivisions);
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
      
      % hack
      if strcmp(beh_dir,'behavioral_pilot')
        expParam.sesTypes = {'day1'};
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
                fprintf('%s, %s, %s\n',expParam.subject,sesName,fn);
                
                if ~isempty(quantileMeasure) && nDivisions > 1
                  if ismember(phaseName,quantileMeasure)
                    thisQuantMeasure = quantileMeasure{find(ismember(quantileMeasure,phaseName)) + 1};
                    if ~isempty(thisQuantMeasure)
                      quantz = quantile([events.(sesName).(fn).data.(thisQuantMeasure)],quantiles);
                      results.(sesName).(fn).quantiles(sub,:) = quantz;
                      if plotQhist
                        hist([events.(sesName).(fn).data.(thisQuantMeasure)],100); %#ok<UNRCH>
                        title(sprintf('%s %s %s %s',subjects{sub},strrep(sesName,'_','-'),strrep(fn,'_','-'),strrep(thisQuantMeasure,'_','-')));
                        keyboard
                        close all
                      end
                    end
                  else
                    thisQuantMeasure = '';
                  end
                else
                  thisQuantMeasure = '';
                end
                
                for q = 1:nDivisions
                  if ~isempty(thisQuantMeasure)
                    % get the events for this quantile
                    if q == 1
                      thisPhaseEv = events.(sesName).(fn).data([events.(sesName).(fn).data.(thisQuantMeasure)] <= quantz(q));
                    elseif q == nDivisions
                      thisPhaseEv = events.(sesName).(fn).data([events.(sesName).(fn).data.(thisQuantMeasure)] > quantz(q-1));
                    else
                      thisPhaseEv = events.(sesName).(fn).data([events.(sesName).(fn).data.(thisQuantMeasure)] > quantz(q-1) & [events.(sesName).(fn).data.(thisQuantMeasure)] <= quantz(q));
                    end
                    
                    if printResults
                      fprintf('==================================================\n');
                      if q == 1
                        fprintf('Quantile division %d of %d: %s <= %.4f\n',q,nDivisions,thisQuantMeasure,quantz(q));
                      elseif q == nDivisions
                        fprintf('Quantile division %d of %d: %s > %.4f\n',q,nDivisions,thisQuantMeasure,quantz(q-1));
                      else
                        fprintf('Quantile division %d of %d: %s > %.4f & %s <= %.4f\n',q,nDivisions,thisQuantMeasure,quantz(q-1),thisQuantMeasure,quantz(q));
                      end
                      fprintf('==================================================\n');
                    end
                  else
                    thisPhaseEv = events.(sesName).(fn).data;
                  end
                  
                  switch phaseName
                    case {'expo'}
                      thisPhaseEv = thisPhaseEv([thisPhaseEv.resp] ~= 0);
                      respEvents = thisPhaseEv(strcmp({thisPhaseEv.type},'EXPO_RESP'));
                      
                      if collapseCategories
                        % overall, collapsing across categories
                        for mf = 1:length(mainFields_expo)
                          mField = mainFields_expo{mf};
                          
                          for df = 1:length(dataFields_expo{mf})
                            dField = sprintf('%s_%s',mField,dataFields_expo{mf}{df});
                            if strcmp(dataFields_expo{mf}{df},'resp')
                              results.(sesName).(fn).(mField).(dField)(sub) = mean([respEvents.resp]);
                            elseif strcmp(dataFields_expo{mf}{df},'rt')
                              results.(sesName).(fn).(mField).(dField)(sub) = mean([respEvents.rt]);
                            end
                          end
                        end
                      end
                      
                      i_catStrs = unique({respEvents.i_catStr},'sorted');
                      % if there's only 1 image category, the results were
                      % printed above
                      if length(i_catStrs) > 1 && separateCategories
                        if printResults
                          fprintf('\n');
                        end
                        for im = 1:length(i_catStrs)
                          respEvents_imgCat = respEvents(strcmp({respEvents.i_catStr},i_catStrs{im}));
                          for mf = 1:length(mainFields_expo)
                            mField = mainFields_expo{mf};
                            
                            for df = 1:length(dataFields_expo{mf})
                              dField = sprintf('%s_%s',mField,dataFields_expo{mf}{df});
                              if strcmp(dataFields_expo{mf}{df},'resp')
                                results.(sesName).(fn).(i_catStrs{im}).(mField).(dField)(sub) = mean([respEvents_imgCat.resp]);
                              elseif strcmp(dataFields_expo{mf}{df},'rt')
                                results.(sesName).(fn).(i_catStrs{im}).(mField).(dField)(sub) = mean([respEvents_imgCat.rt]);
                              end
                            end
                            
                          end
                        end
                      end
                      
                    case {'cued_recall_only'}
                      % how many lag conditions occurred for targets
                      % (during study)?
                      lagConds = unique([thisPhaseEv([thisPhaseEv.targ]).lag],'sorted');
                      
                      % exclude missed responses ({'NO_RESPONSE', 'none'})
%                       thisPhaseEv = thisPhaseEv(~ismember({thisPhaseEv.recog_resp},{'NO_RESPONSE', 'none'}));
                      
                      if sum(lagConds > 0) > 1
%                         error('%s does not yet support multiple lag conditions!',mfilename);
                        fprintf('%s: testing out multiple lag conditions!\n',mfilename);
                      end
                      
                      for lc = 1:length(lagConds)
                        % targ events are either massed or spaced, depending
                        % on the lag condition
                        targEvents = thisPhaseEv([thisPhaseEv.targ] & ismember({thisPhaseEv.type},'TEST_STIM') & ismember([thisPhaseEv.lag],lagConds(lc)));
                        % lure events don't have lag conditions
                        lureEvents = thisPhaseEv(~[thisPhaseEv.targ] & ismember({thisPhaseEv.type},'TEST_STIM'));
                        
                        % choose the training condition
                        if length(lagConds(lc)) == 1
                          if lagConds(lc) > 0
                            if printResults
                              fprintf('*** Spaced (lag %d) ***\n',lagConds(lc));
                            end
                            lagStr = sprintf('lag%d',lagConds(lc));
                            %lagStr = 'spaced';
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
                            
                            results.(sesName).(fn).(lagStr) = accAndRT(targEvents,lureEvents,sub,q,results.(sesName).(fn).(lagStr),...
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
                              targEvents = thisPhaseEv([thisPhaseEv.targ] & ismember({thisPhaseEv.type},'TEST_STIM') & ismember([thisPhaseEv.lag],lagConds(lc)) & strcmpi({thisPhaseEv.i_catStr},i_catStrs{im}));
                              % lure events don't have lag conditions
                              lureEvents = thisPhaseEv(~[thisPhaseEv.targ] & ismember({thisPhaseEv.type},'TEST_STIM') & strcmpi({thisPhaseEv.i_catStr},i_catStrs{im}));
                              
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
                              
                              results.(sesName).(fn).(lagStr).(i_catStrs{im}) = accAndRT(targEvents,lureEvents,sub,q,results.(sesName).(fn).(lagStr).(i_catStrs{im}),...
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
                end % quantiles
                
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
    if nDivisions > 1
      quantStr = sprintf('_%dquantileDiv',nDivisions);
    else
      quantStr = '';
    end
    
    if collapsePhases
      collapseStr = '_collapsed';
    else
      collapseStr = '';
    end
    matFileName = sprintf('%s_behav_results%s%s%s.mat',expName,quantStr,collapseStr,filenameSuffix);
    matFileName = fullfile(dataroot,matFileName);
    
    fprintf('Saving results struct to %s...',matFileName);
    save(matFileName,'results');
    fprintf('Done.\n');
  end
else
  completeStatus = true(1,length(subjects));
  
  if onlyCompleteSub
    fprintf('Loading events to check whether each subject has completed all sessions...\n');
    for sub = 1:length(subjects)
      subDir = fullfile(dataroot,subjects{sub});
      
      fprintf('Loading events for %s...',subjects{sub});
      eventsFile = fullfile(subDir,'events','events.mat');
      if exist(eventsFile,'file')
        load(eventsFile,'events');
      else
        error('events file does not exist: %s',eventsFile);
      end
      
      % if we only want complete subjects and this one is not done, set to
      % false
      if ~events.isComplete
        fprintf('Incomplete!\n');
        completeStatus(sub) = false;
      else
        fprintf('Complete!\n');
      end
    end
  end
end

if saveResults
  if nDivisions > 1
    quantStr = sprintf('_%dquantileDiv',nDivisions);
  else
    quantStr = '';
  end
  
  if collapsePhases
    collapseStr = '_collapsed';
  else
    collapseStr = '';
  end
  textFileName = sprintf('%s_behav_results%s%s%s.txt',expName,quantStr,collapseStr,filenameSuffix);
  textFileName = fullfile(dataroot,textFileName);
  
  printResultsToFile(dataroot,subjects,results,mainFields,dataFields,prependDestField,textFileName,collapsePhases,collapseCategories,separateCategories,templateSubject,quantileMeasure,nDivisions);
end

end % function

%% print to file

function printResultsToFile(dataroot,subjects,results,mainToPrint,dataToPrint,prependDestField,textFileName,collapsePhases,collapseCategories,separateCategories,templateSubject,quantileMeasure,nDivisions)

if nargin < 13
  error('Must include both variables: ''quantileMeasure'' and ''nDivisions''.');
elseif nargin < 12
  quantileMeasure = {};
  nDivisions = 1;
end

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

% hack
if ~isempty(strfind(dataroot,'behavioral_pilot'))
  expParam.sesTypes = {'day1'};
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
        
        for q = 1:nDivisions
          if ~isempty(quantileMeasure) && nDivisions > 1
            if ismember(phaseName,quantileMeasure)
              thisQuantMeasure = quantileMeasure{find(ismember(quantileMeasure,phaseName)) + 1};
              if ~isempty(thisQuantMeasure)
                if q == 1
                  fprintf(fid,'Quantile division %d of %d: %s\n',q,nDivisions,thisQuantMeasure);
                elseif q == nDivisions
                  fprintf(fid,'Quantile division %d of %d: %s\n',q,nDivisions,thisQuantMeasure);
                else
                  fprintf(fid,'Quantile division %d of %d: %s\n',q,nDivisions,thisQuantMeasure);
                end
              end
            end
          end
          
          switch phaseName
            case {'cued_recall_only'}
              targEvents = events.(sesName).(fn).data([events.(sesName).(fn).data.targ]);
              lagConds = unique([targEvents.lag],'sorted');
              
              % lureEvents = events.(sesName).(fn).data(~[events.(sesName).(fn).data.targ]);
              
              for lc = 1:length(lagConds)
                
                % choose the training condition
                if length(lagConds(lc)) == 1
                  if lagConds(lc) > 0
                    lagStr = sprintf('lag%d',lagConds(lc));
                    %lagStr = 'spaced';
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
                      
                      [dataStr] = setDataStr(dataStr,{sesName,fn,lagStr,mainToPrint{mf}},results,sub,q,subDataToPrint);
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
                        [dataStr] = setDataStr(dataStr,{sesName,fn,lagStr,i_catStrs{im},mainToPrint{mf}},results,sub,q,subDataToPrint);
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
        end % q
      else
        fprintf('printResultsToFile: %s, %s: phase %s does not exist.\n',expParam.subject,sesName,fn);
      end % isfield
    end % isExp
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

function [dataStr] = setDataStr(dataStr,structFields,results,sub,thisQ,dataToPrint) %#ok<INUSL>

theseResults = eval(sprintf('results%s',sprintf(repmat('.%s',1,length(structFields)),structFields{:})));

for i = 1:length(dataToPrint)
  if ~isnan(theseResults.(dataToPrint{i})(sub,thisQ))
    dataStr = sprintf('%s\t%.4f',dataStr,theseResults.(dataToPrint{i})(sub,thisQ));
  else
    dataStr = sprintf('%s\t',dataStr);
  end
end

end

%% Calculate accuracy and reaction time

function inputStruct = accAndRT(targEv,lureEv,sub,thisQ,inputStruct,partialCredit,destField,accField,dataFields,prependDestField)

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
  inputStruct.(destField).(thisField)(sub,thisQ) = length(allEv);
end

thisStr = 'nTarg';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub,thisQ) = length(targEv);
end

if ~isempty(lureEv)
  thisStr = 'nLure';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub,thisQ) = length(lureEv);
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
  inputStruct.(destField).(thisField)(sub,thisQ) = length(hitEv);
end

thisStr = 'nMiss';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub,thisQ) = length(missEv);
end

if ~isempty(lureEv)
  thisStr = 'nCR';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub,thisQ) = length(crEv);
  end
  
  thisStr = 'nFA';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub,thisQ) = length(faEv);
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
  inputStruct.(destField).(thisField)(sub,thisQ) = hr;
end

thisStr = 'mr';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub,thisQ) = mr;
end

if ~isempty(lureEv)
  thisStr = 'far';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub,thisQ) = far;
  end
  
  thisStr = 'crr';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub,thisQ) = crr;
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
    
    inputStruct.(destField).(thisField)(sub,thisQ) = zhr - zfar;
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
    
    inputStruct.(destField).(thisField)(sub,thisQ) = c;
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
    
    inputStruct.(destField).(thisField)(sub,thisQ) = Pr;
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
    
    inputStruct.(destField).(thisField)(sub,thisQ) = Br;
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
%   inputStruct.(destField).(thisField)(sub,thisQ) = (2 / (1 + (s^2)))^(1/2) * (zhr - (s*zfar));
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
  inputStruct.(destField).(rtField)(sub,thisQ) = mean([allEv.(rtField)]);
end

thisStr = 'rt_hit';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub,thisQ) = mean([hitEv.(rtField)]);
end

thisStr = 'rt_miss';
if any(strcmp(thisStr,dataFields))
  if prependDestField
    thisField = sprintf('%s_%s',destField,thisStr);
  else
    thisField = thisStr;
  end
  inputStruct.(destField).(thisField)(sub,thisQ) = mean([missEv.(rtField)]);
end

if ~isempty(lureEv)
  thisStr = 'rt_cr';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub,thisQ) = mean([crEv.(rtField)]);
  end
  
  thisStr = 'rt_fa';
  if any(strcmp(thisStr,dataFields))
    if prependDestField
      thisField = sprintf('%s_%s',destField,thisStr);
    else
      thisField = thisStr;
    end
    inputStruct.(destField).(thisField)(sub,thisQ) = mean([faEv.(rtField)]);
  end
end

end


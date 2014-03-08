% basic analysis script for expertTrain experiments

% TODO: plot individual subjects along with mean/SEM

% TODO: is there a better kind of plot to use, e.g., box and whisker?

%% set the subjects and other variables

expName = 'EBIRD';

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
  'EBIRD025';
  'EBIRD027';
  'EBIRD029';
  'EBIRD032';
  'EBIRD034';
  'EBIRD042';
  };

saveFigs = true;
if saveFigs
  figsDir = fullfile(dataroot,'figs');
  if ~exist(figsDir,'dir')
    mkdir(figsDir);
  end
  %figFormat = '-djpg90';
  figFormat = '-dpng';
  %figFormat = '-deps2';
  %figFormat = '-depsc2';
  
  figRes = '-r150';
end

%% are we collapsing phases or not?

collapsePhases = false;

%% run the data processing script

% onlyCompleteSub = false;
% printResults = true;
% saveResults = true;

onlyCompleteSub = true;
printResults = false;
saveResults = true;

[results] = ebird_processData([],dataroot,subjects,onlyCompleteSub,collapsePhases,printResults,saveResults);

%% or just load the behavioral data

if collapsePhases
  load(fullfile(dataroot,'EBIRD_behav_results_collapsed.mat'));
else
  load(fullfile(dataroot,'EBIRD_behav_results.mat'));
end

%% rerun to print data again

% ebird_processData(results,dataroot,subjects,onlyCompleteSub,collapsePhases,printResults,saveResults);

%% initialize

data = struct;

%% Plot basic and subordinate RTs across training days, all phases on one figure

nTrainSes = 6;
if collapsePhases
  phases = {'name'};
else
  phases = {'name_1','name_2','name_3','name_4'};
end

plotOverall = false;

if collapsePhases
  data.overall = nan(length(subjects),(nTrainSes * length(phases)));
  data.basic = nan(length(subjects),(nTrainSes * length(phases)));
  data.subord = nan(length(subjects),(nTrainSes * length(phases)));
else
  % - 2 because pretest session only has two naming phases
  data.overall = nan(length(subjects),(nTrainSes * length(phases) - 2));
  data.basic = nan(length(subjects),(nTrainSes * length(phases) - 2));
  data.subord = nan(length(subjects),(nTrainSes * length(phases) - 2));
end

% dataMeasure = 'rt';ymin = 500; ymax = 2000;
% dataMeasure = 'rt_hit';ymin = 500; ymax = 2000;
% dataMeasure = 'rt_miss';ymin = 500; ymax = 2000;
dataMeasure = 'hr';ymin = 0.3; ymax = 1;

% % use defaults, set below
% ymin = [];
% ymax = [];

tpCounter = 0;
for t = 1:nTrainSes
  sesName = sprintf('train%d',t);
  for p = 1:length(phases)
    if isfield(results.(sesName),phases{p})
      tpCounter = tpCounter + 1;
      data.overall(:,tpCounter) = results.(sesName).(phases{p}).overall.(dataMeasure);
      data.basic(:,tpCounter) = results.(sesName).(phases{p}).basic.(dataMeasure);
      data.subord(:,tpCounter) = results.(sesName).(phases{p}).subord.(dataMeasure);
    end
  end
end

figure

basic_mean = nanmean(data.basic,1);
basic_sem = nanstd(data.basic,0,1) ./ sqrt(sum(~isnan(data.basic)));
hb = errorbar(basic_mean,basic_sem,'ro-','LineWidth',2);
hold on

subordData_mean = nanmean(data.subord,1);
subordData_sem = nanstd(data.subord,0,1) ./ sqrt(sum(~isnan(data.subord)));
hs = errorbar(subordData_mean,subordData_sem,'ks-','LineWidth',2);

if plotOverall
  overall_mean = nanmean(data.overall,1);
  overall_sem = nanstd(data.overall,0,1) ./ sqrt(sum(~isnan(data.overall)));
  ho = errorbar(overall_mean,overall_sem,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
end

hold off

if collapsePhases
  title(sprintf('Naming phases (collapsed): %s',strrep(dataMeasure,'_','\_')));
else
  title(sprintf('Naming phases: %s',strrep(dataMeasure,'_','\_')));
end
xlabel('Training Day');
if strcmp(dataMeasure,'rt') || strcmp(dataMeasure,'rt_hit') || strcmp(dataMeasure,'rt_miss')
  ylabel('Response Time (ms)');
  
  if ~exist('ymin','var') || isempty(ymin)
    ymin = 500;
  end
  if ~exist('ymax','var') || isempty(ymax)
    %ymax = ceil(nanmean(data.overall(:))/100)*100 + 500;
    ymax = 2500;
  end
  
  axis([0.5 (size(data.subord,2) + 0.5) ymin ymax]);
  %if ~strcmp(dataMeasure,'rt_inc')
  %  axis([0.5 (size(data.subord,2) + 0.5) 0 600]);
  %else
  %  axis([0.5 (size(data.subord,2) + 0.5) 0 1500]);
  %end
  
  legendLoc = 'NorthWest';
elseif strcmp(dataMeasure,'hr')
  ylabel('Accuracy');
  
  if ~exist('ymin','var') || isempty(ymin)
    ymin = 0.25;
  end
  if ~exist('ymax','var') || isempty(ymax)
    %ymax = round(max(data.overall(:))*100)/100;
    ymax = 1;
  end
  
  axis([0.5 (size(data.subord,2) + 0.5) ymin ymax]);
  
  legendLoc = 'SouthEast';
% elseif strcmp(dataMeasure,'dp')
%   ylabel('d''');
%   
%   if ~exist('ymin','var') || isempty(ymin)
%     ymin = -1;
%   end
%   if ~exist('ymax','var') || isempty(ymax)
%     %ymax = ceil(max(data.overall(:)));
%     ymax = 5;
%   end
%   
%   axis([0.5 (size(data.subord,2) + 0.5) ymin ymax]);
%   
%   legendLoc = 'SouthEast';
end
if collapsePhases
  new_xlabel = [ones(1,length(phases)) ones(1,length(phases))*2 ones(1,length(phases))*3 ones(1,length(phases))*4 ones(1,length(phases))*5 ones(1,length(phases))*6];
else
  new_xlabel = [ones(1,length(phases)/2) ones(1,length(phases))*2 ones(1,length(phases))*3 ones(1,length(phases))*4 ones(1,length(phases))*5 ones(1,length(phases))*6];
end
set(gca,'XTick',1:length(new_xlabel));
set(gca,'XTickLabel',new_xlabel);

% put the legend in a reasonable order
if strcmp(dataMeasure,'hr')
  if plotOverall
    legend([hb hs ho],{'Basic','Subordinate','Overall'},'Location',legendLoc);
  else
    legend([hb hs],{'Basic','Subordinate'},'Location',legendLoc);
  end
elseif strcmp(dataMeasure,'rt') || strcmp(dataMeasure,'rt_hit') || strcmp(dataMeasure,'rt_miss')
  if plotOverall
    legend([hs ho hb],{'Subordinate','Overall','Basic'},'Location',legendLoc);
  else
    legend([hs hb],{'Subordinate','Basic'},'Location',legendLoc);
  end
end

publishfig(gcf,0);

if saveFigs
  if collapsePhases
    collapseStr = '_collapsed';
  else
    collapseStr = '';
  end
  print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('training_name_%s%s',collapseStr,dataMeasure)));
end

%% Collapse across image manipulation conditions: pretest, posttest, posttest_delay

% plot basic and subordinate data for pretest, posttest, posttest_delay

sessions = {'pretest', 'posttest', 'posttest_delay'};
if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};
% training = {'TT','UU','TU','UT'};
training = {'TT','UU'};
naming = {'basic','subord'};

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [0 3];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'far';
% dataLabel = 'False alarm rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

data.(dataMeasure) = struct;
for n = 1:length(naming)
  data.(dataMeasure).(naming{n}) = nan(length(subjects),length(sessions),length(phases),length(training));
end

for s = 1:length(sessions)
  sesName = sessions{s};
  for p = 1:length(phases)
    for t = 1:length(training)
      for n = 1:length(naming)
        data.(dataMeasure).(naming{n})(:,s,p,t) = results.(sesName).(phases{p}).(training{t}).(naming{n}).(dataMeasure);
      end
    end
  end
end

for p = 1:length(phases)
  for n = 1:length(naming)
    figure
    data_mean = nan(length(sessions),length(training));
    data_sem = nan(length(sessions),length(training));
    
    for t = 1:length(training)
      for s = 1:length(sessions)
        data_mean(s,t) = nanmean(data.(dataMeasure).(naming{n})(:,s,p,t),1);
        data_sem(s,t) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t),0,1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t))));
      end
    end
    
    bw_title = sprintf('%s%s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'));
    bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
    %bw_legend = {'Trained','Untrained'};
    %bw_legend = {'TT','UU','TU','UT'};
    bw_legend = training;
    %bw_xlabel = 'Test day';
    bw_xlabel = [];
    bw_ylabel = dataLabel;
    %bw_colormap = 'gray';
    bw_colormap = 'linspecer';
    bw_data = data_mean;
    bw_errors = data_sem;
    h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
    set(h.legend,'Location','NorthWest');
    axis([0.5 (length(sessions)+0.5) ylimits(1) ylimits(2)]);
    publishfig(gcf,0);
    
    if saveFigs
      print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%s_%s',phases{p},dataMeasure,naming{n})));
    end
  end
end

%% Image manipulation conditions: pretest, posttest, posttest_delay

% plot basic and subordinate data for pretest, posttest, posttest_delay

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [0 3];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};
% training = {'TT','UU','TU','UT'};
training = {'TT','UU'};
naming = {'basic','subord'};
imgConds = {'normal','color','g','g_hi8','g_lo8'};
imgCondsStr = {'Cong','Incong','Gray','Hi8','Lo8'};

data.(dataMeasure) = struct;
for n = 1:length(naming)
  data.(dataMeasure).(naming{n}) = nan(length(subjects),length(sessions),length(phases),length(training),length(imgConds));
end

for s = 1:length(sessions)
  sesName = sessions{s};
  for p = 1:length(phases)
    for t = 1:length(training)
      for i = 1:length(imgConds)
        for n = 1:length(naming)
          data.(dataMeasure).(naming{n})(:,s,p,t,i) = results.(sesName).(phases{p}).(training{t}).(imgConds{i}).(naming{n}).(dataMeasure);
        end
      end
    end
  end
end

% % stats
% [h, p, ci, stats] = ttest(squeeze(data.(dataMeasure).(naming{1})(:,1,1,1,1)),squeeze(data.(dataMeasure).(naming{1})(:,2,1,1,1)));

% make some plots
for i = 1:length(imgConds)
  for p = 1:length(phases)
    for n = 1:length(naming)
      figure
      data_mean = nan(length(sessions),length(training));
      data_sem = nan(length(sessions),length(training));
      
      for t = 1:length(training)
        for s = 1:length(sessions)
          data_mean(s,t) = nanmean(data.(dataMeasure).(naming{n})(:,s,p,t,i),1);
          data_sem(s,t) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t,i),0,1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t,i))));
        end
      end
      
      bw_title = sprintf('%s%s: %s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'),strrep(imgConds{i},'_','\_'));
      bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
      %bw_legend = {'Trained','Untrained'};
      %bw_legend = {'TT','UU','TU','UT'};
      bw_legend = training;
      %bw_xlabel = 'Test day';
      bw_xlabel = [];
      bw_ylabel = dataLabel;
      %bw_colormap = 'gray';
      bw_colormap = 'linspecer';
      bw_data = data_mean;
      bw_errors = data_sem;
      h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
      set(h.legend,'Location','NorthWest');
      axis([0.5 (length(sessions)+0.5) ylimits(1) ylimits(2)]);
      publishfig(gcf,0);
      if saveFigs
        print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%s_%s_%s',phases{p},dataMeasure,naming{n},imgCondsStr{i})));
      end
    end
  end
end

%% Image manipulation conditions on same plot: pretest, posttest, posttest_delay

% plot basic and subordinate data for pretest, posttest, posttest_delay

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [0 3];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};
% training = {'TT','UU','TU','UT'};
training = {'TT','UU'};
naming = {'basic','subord'};
% imgConds = {'normal','color','g','g_hi8','g_lo8'};
% imgConds = {'normal','color','g'};
% groupname = 'color';
imgConds = {'g','g_hi8','g_lo8'};
groupname = 'spatialfreq';

data.(dataMeasure) = struct;
for n = 1:length(naming)
  data.(dataMeasure).(naming{n}) = nan(length(subjects),length(sessions),length(phases),length(training),length(imgConds));
end

for s = 1:length(sessions)
  sesName = sessions{s};
  for p = 1:length(phases)
    for t = 1:length(training)
      for i = 1:length(imgConds)
        for n = 1:length(naming)
          data.(dataMeasure).(naming{n})(:,s,p,t,i) = results.(sesName).(phases{p}).(training{t}).(imgConds{i}).(naming{n}).(dataMeasure);
        end
      end
    end
  end
end

% % stats
% [h, p, ci, stats] = ttest(squeeze(data.(dataMeasure).(naming{1})(:,1,1,1,1)),squeeze(data.(dataMeasure).(naming{1})(:,2,1,1,1)));

% make some plots
for p = 1:length(phases)
  for n = 1:length(naming)
    figure
    data_mean = nan(length(sessions),length(training) * length(imgConds));
    data_sem = nan(length(sessions),length(training) * length(imgConds));
    
    for s = 1:length(sessions)
      
      bw_legend = cell(1,length(training) * length(imgConds));

      
      counter = 0;
      for t = 1:length(training)
        for i = 1:length(imgConds)
          counter = counter + 1;
          
          bw_legend{counter} = sprintf('%s %s',strrep(imgConds{i},'_','-'),training{t});
          
          data_mean(s,counter) = nanmean(data.(dataMeasure).(naming{n})(:,s,p,t,i),1);
          data_sem(s,counter) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t,i),0,1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t,i))));
        end
      end
    end
    
    %for i = 1:length(imgConds)
    
    bw_title = sprintf('%s%s: %s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'),strrep(imgConds{i},'_','\_'));
    bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
    %bw_legend = {'Trained','Untrained'};
    %bw_legend = {'TT','UU','TU','UT'};
    %bw_legend = training;
    %bw_xlabel = 'Test day';
    bw_xlabel = [];
    bw_ylabel = dataLabel;
    %bw_colormap = 'gray';
    bw_colormap = 'linspecer';
    bw_data = data_mean;
    bw_errors = data_sem;
    h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
    set(h.legend,'Location','NorthEast');
    axis([0.5 (length(sessions)+2) ylimits(1) ylimits(2)]);
    publishfig(gcf,0);
    if saveFigs
      print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%s_%s_%s',phases{p},dataMeasure,naming{n},groupname)));
    end
    %end
  end
end

%% plot overall d' difference score: post minus pre

% plot basic and subordinate data for pretest, posttest, posttest_delay

sessions = {'pretest', 'posttest', 'posttest_delay'};
if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};
% training = {'TT','UU','TU','UT'};
training = {'TT','UU'};
naming = {'basic','subord'};

imgConds = {'all'};


sesDiff = {{'posttest_delay','pretest'}};

dataMeasure = 'dp';
dataLabel = 'd'' difference';
ylimits = [0 1.5];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'far';
% dataLabel = 'False alarm rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

data.(dataMeasure) = struct;
for n = 1:length(naming)
  data.(dataMeasure).(naming{n}) = nan(length(subjects),length(sessions),length(phases),length(training));
end

for s = 1:length(sessions)
  sesName = sessions{s};
  for p = 1:length(phases)
    for t = 1:length(training)
      for n = 1:length(naming)
        data.(dataMeasure).(naming{n})(:,s,p,t) = results.(sesName).(phases{p}).(training{t}).(naming{n}).(dataMeasure);
      end
    end
  end
end

for p = 1:length(phases)
  for t = 1:length(training)
    figure
    data_mean = nan(length(sesDiff),length(naming));
    data_sem = nan(length(sesDiff),length(naming));
    
    for n = 1:length(naming)
      %for s = 1:length(sessions)
      %  data_mean(s,t) = nanmean(data.(dataMeasure).(naming{n})(:,s,p,t),1);
      %  data_sem(s,t) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t),0,1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t))));
      %end
      
      %sesDiffStr = cell(size(sesDiff));
      for s = 1:length(sesDiff)
        firstInd = ismember(sessions,sesDiff{s}(1));
        secondInd = ismember(sessions,sesDiff{s}(2));
        
        %sesDiffStr{s} = sprintf('%s - %s (%s)',sessions{firstInd},sessions{secondInd},strrep(phases{p},'_','\_'));
        
        thisDiff = data.(dataMeasure).(naming{n})(:,firstInd,p,t) - data.(dataMeasure).(naming{n})(:,secondInd,p,t);
        data_mean(s,n) = nanmean(thisDiff);
        data_sem(s,n) = nanstd(thisDiff,0) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,1,p,t))));
      end
    end
    
    sesDiffStr = sprintf('%s: %s - %s (%s)',training{t},sesDiff{1}{1},sesDiff{1}{2},strrep(phases{p},'_','\_'));
    bw_title = sesDiffStr;
    %bw_title = sprintf('%s%s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'));
    %bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
    bw_groupnames = imgConds;
    %bw_legend = {'Trained','Untrained'};
    %bw_legend = {'TT','UU','TU','UT'};
    bw_legend = naming;
    %bw_xlabel = 'Test day';
    bw_xlabel = [];
    bw_ylabel = dataLabel;
    %bw_colormap = 'gray';
    bw_colormap = 'linspecer';
    bw_data = data_mean;
    bw_errors = data_sem;
    h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
    set(h.legend,'Location','NorthEast');
    axis([0.5 (length(imgConds)+0.5) ylimits(1) ylimits(2)]);
    publishfig(gcf,0);
    
    if saveFigs
      print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%sDiff_%s',phases{p},dataMeasure,training{t})));
    end
  end
end

%% diff score img cond

% plot basic and subordinate data for pretest, posttest, posttest_delay

dataMeasure = 'dp';
dataLabel = 'd'' difference';
ylimits = [0 1.5];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};

naming = {'basic','subord'};

training = {'TT','UU'};
imgConds = {'normal','color','g','g_hi8','g_lo8'};

% training = {'TT','UU'};
% imgConds = {'normal','color','g'};

% training = {'TT','UU','TU','UT'};
% imgConds = {'g','g_hi8','g_lo8'};

sesDiff = {{'posttest','pretest'}};
% sesDiff = {{'posttest_delay','pretest'}};

data.(dataMeasure) = struct;
for n = 1:length(naming)
  data.(dataMeasure).(naming{n}) = nan(length(subjects),length(sessions),length(phases),length(training),length(imgConds));
end

for s = 1:length(sessions)
  sesName = sessions{s};
  for p = 1:length(phases)
    for t = 1:length(training)
      for i = 1:length(imgConds)
        for n = 1:length(naming)
          data.(dataMeasure).(naming{n})(:,s,p,t,i) = results.(sesName).(phases{p}).(training{t}).(imgConds{i}).(naming{n}).(dataMeasure);
        end
      end
    end
  end
end

% % stats
% [h, p, ci, stats] = ttest(squeeze(data.(dataMeasure).(naming{1})(:,1,1,1,1)),squeeze(data.(dataMeasure).(naming{1})(:,2,1,1,1)));

% make some plots
for p = 1:length(phases)
  for t = 1:length(training)
    figure
    data_mean = nan(length(sesDiff),length(naming),length(imgConds));
    data_sem = nan(length(sesDiff),length(naming),length(imgConds));
    
    for i = 1:length(imgConds)
      for n = 1:length(naming)
        for s = 1:length(sesDiff)
          firstInd = ismember(sessions,sesDiff{s}(1));
          secondInd = ismember(sessions,sesDiff{s}(2));
          
          thisDiff = data.(dataMeasure).(naming{n})(:,firstInd,p,t,i) - data.(dataMeasure).(naming{n})(:,secondInd,p,t,i);
          data_mean(s,n,i) = nanmean(thisDiff);
          data_sem(s,n,i) = nanstd(thisDiff,0) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,firstInd,p,t,i))));
          
          %data_mean(s,t,i) = nanmean(data.(dataMeasure).(naming{n})(:,s,p,t,i),1);
          %data_sem(s,t,i) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t,i),0,1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t,i))));
        end
      end
      
      
    end
    
    sesDiffStr = sprintf('%s: %s - %s (%s)',training{t},sesDiff{1}{1},sesDiff{1}{2},strrep(phases{p},'_','\_'));
    bw_title = sesDiffStr;
    %bw_title = sprintf('%s%s: %s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'),strrep(imgConds{i},'_','\_'));
    %bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
    bw_groupnames = imgConds;
    %bw_legend = {'Trained','Untrained'};
    %bw_legend = {'TT','UU','TU','UT'};
    %bw_legend = training;
    bw_legend = naming;
    %bw_xlabel = 'Test day';
    bw_xlabel = [];
    bw_ylabel = dataLabel;
    %bw_colormap = 'gray';
    bw_colormap = 'linspecer';
    bw_data = squeeze(data_mean)';
    bw_errors = squeeze(data_sem)';
    h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
    set(h.legend,'Location','NorthEast');
    axis([0.5 (length(imgConds)+0.5) ylimits(1) ylimits(2)]);
    publishfig(gcf,0);
    
    if saveFigs
      print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%sDiff_%s_imgConds',phases{p},dataMeasure,training{t})));
    end
  end
end

%% diff score - subordinate only - img cond x training x pre/post/delay

% plot basic and subordinate data for pretest, posttest, posttest_delay

dataMeasure = 'dp';
dataLabel = 'd'' difference';
ylimits = [0 1.5];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};

naming = {'basic','subord'};
% naming = {'subord'};

% training = {'TT','UU'};
% imgConds = {'normal','color','g','g_hi8','g_lo8'};
% groupname = 'All';

training = {'TT','UU'};
imgConds = {'normal','color','g'};
groupname = 'Color';

% training = {'TT','UU'};
% % training = {'TT','UU','TU','UT'};
% imgConds = {'g','g_hi8','g_lo8'};
% groupname = 'SpatialFreq';

sesDiff = {{'posttest','pretest'},{'posttest_delay','pretest'}};

data.(dataMeasure) = struct;
for n = 1:length(naming)
  data.(dataMeasure).(naming{n}) = nan(length(subjects),length(sessions),length(phases),length(training),length(imgConds));
end

for s = 1:length(sessions)
  sesName = sessions{s};
  for p = 1:length(phases)
    for t = 1:length(training)
      for i = 1:length(imgConds)
        for n = 1:length(naming)
          data.(dataMeasure).(naming{n})(:,s,p,t,i) = results.(sesName).(phases{p}).(training{t}).(imgConds{i}).(naming{n}).(dataMeasure);
        end
      end
    end
  end
end

% % stats
% [h, p, ci, stats] = ttest(squeeze(data.(dataMeasure).(naming{1})(:,1,1,1,1)),squeeze(data.(dataMeasure).(naming{1})(:,2,1,1,1)));

% make some plots
for p = 1:length(phases)
  for n = 1:length(naming)
    figure
    data_mean = nan(length(imgConds), length(sesDiff) * length(training));
    data_sem = nan(length(imgConds), length(sesDiff) * length(training));
    
    for i = 1:length(imgConds)
      condCounter = 0;
      
      bw_legend = cell(1,length(sesDiff) * length(training));
      for t = 1:length(training)
        for s = 1:length(sesDiff)
          condCounter = condCounter + 1;
          
          if strcmp(sesDiff{s}{1},'posttest') && strcmp(sesDiff{s}{2},'pretest')
            sd_str = 'PP';
          elseif strcmp(sesDiff{s}{1},'posttest_delay') && strcmp(sesDiff{s}{2},'pretest')
            sd_str = 'DP';
          end
          bw_legend{condCounter} = sprintf('%s %s',training{t},sd_str);
          
          firstInd = ismember(sessions,sesDiff{s}(1));
          secondInd = ismember(sessions,sesDiff{s}(2));
          
          thisDiff = data.(dataMeasure).(naming{n})(:,firstInd,p,t,i) - data.(dataMeasure).(naming{n})(:,secondInd,p,t,i);
          %data_mean(s,t,i) = nanmean(thisDiff);
          %data_sem(s,t,i) = nanstd(thisDiff,0) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,firstInd,p,t,i))));
          
          data_mean(i,condCounter) = nanmean(thisDiff);
          data_sem(i,condCounter) = nanstd(thisDiff,0) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,firstInd,p,t,i))));
          
          %data_mean(s,t,i) = nanmean(data.(dataMeasure).(naming{n})(:,s,p,t,i),1);
          %data_sem(s,t,i) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t,i),0,1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t,i))));
        end
      end % i
    end % t
    
    %sesDiffStr = sprintf('%s: %s - %s (%s)',training{t},sesDiff{1}{1},sesDiff{1}{2},strrep(phases{p},'_','\_'));
    sesDiffStr = sprintf('%s: %s, %s',naming{n},strrep(phases{p},'_','\_'),groupname);
    bw_title = sesDiffStr;
    %bw_title = sprintf('%s%s: %s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'),strrep(imgConds{i},'_','\_'));
    %bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
    bw_groupnames = imgConds;
    %bw_legend = {'Trained','Untrained'};
    %bw_legend = {'TT','UU','TU','UT'};
    %bw_legend = training;
    %bw_legend = naming;
    %bw_xlabel = 'Test day';
    bw_xlabel = [];
    bw_ylabel = dataLabel;
    if exist('linspecer','file')
      bw_colormap = 'linspecer';
    else
      bw_colormap = 'gray';
    end
    bw_data = data_mean;
    bw_errors =data_sem;
    h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
    set(h.legend,'Location','NorthEast');
    axis([0.5 (length(imgConds)+1.5) ylimits(1) ylimits(2)]);
    publishfig(gcf,0);
    
    if saveFigs
      print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%sDiff_%s_%s_%dtrain',phases{p},dataMeasure,naming{n},groupname,length(training))));
    end
  end
end

%% NEW: d' - subordinate only for a training condition - pre/post/delay x img cond

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [0 4];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'rt_hit';
% dataLabel = 'Response Time: Hits';
% ylimits = [0 5000];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
sesStr = {'Pretest','Posttest','Delay'};
if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};

% naming = {'basic','subord'};
naming = {'subord'};

% training = {'TT','UU'};
% imgConds = {'normal','color','g','g_hi8','g_lo8'};
% groupname = 'All';

training = {'TT'};
% training = {'UU'};
imgConds = {'normal','color','g'};
groupname = 'Color';

% training = {'TT'};
% % training = {'UU'};
% % training = {'TT','UU','TU','UT'};
% imgConds = {'g','g_hi8','g_lo8'};
% groupname = 'SpatialFreq';

data = nan(length(sessions),length(imgConds),length(training),length(phases),length(subjects));

for s = 1:length(sessions)
  for p = 1:length(phases)
    for i = 1:length(imgConds)
      
      for t = 1:length(training)
        for n = 1:length(naming)
          data(s,i,t,p,:) = results.(sessions{s}).(phases{p}).(training{t}).(imgConds{i}).(naming{n}).(dataMeasure);
        end
      end
      
    end
  end
end

% % stats
% [h, p, ci, stats] = ttest(squeeze(data.(dataMeasure).(naming{1})(:,1,1,1,1)),squeeze(data.(dataMeasure).(naming{1})(:,2,1,1,1)));

% make some plots
for p = 1:length(phases)
  for t = 1:length(training)
    for n = 1:length(naming)
      figure
      
      data_mean = nanmean(data,5);
      data_sem = nanstd(data,0,5) ./ sqrt(length(subjects));
      
      bw_legend = imgConds;
      
      if strcmp(training{t},'TT')
        trainingStr = 'trained';
      elseif strcmp(training{t},'UU')
        trainingStr = 'untrained';
      else
        trainingStr = training{t};
      end
      
      bw_title = sprintf('%s: %s, %s',groupname,trainingStr,naming{n});
      %bw_title = sprintf('%s%s: %s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'),strrep(imgConds{i},'_','\_'));
      %bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
      bw_groupnames = sesStr;
      %bw_xlabel = 'Test day';
      bw_xlabel = [];
      bw_ylabel = dataLabel;
      if exist('linspecer','file')
        bw_colormap = 'linspecer';
      else
        bw_colormap = 'gray';
      end
      bw_data = data_mean;
      bw_errors =data_sem;
      h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
      set(h.legend,'Location','NorthEast');
      axis([0.5 (length(imgConds)+1.5) ylimits(1) ylimits(2)]);
      publishfig(gcf,0);
      
      if saveFigs
        print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%s_%s_%s_%s',phases{p},dataMeasure,training{t},naming{n},groupname)));
      end
    end
  end
end

%% NEW: d' - break pre/post tests into different graphs - training x img cond

% pretest only will collapse across training

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [0 4];

% dataMeasure = 'rt_hit';
% dataLabel = 'Response Time: Hits';
% ylimits = [0 5000];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
sesStr = {'Pretest', 'Posttest','Delay'};

if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end
% training = {'trained','untrained'};

% naming = {'basic','subord'};
naming = {'subord'};

% training = {'TT','UU','TU','UT'};
% trainStr = {'Trained','Untrained','TU','UT'};

training = {'TT','UU'};
trainingStr = {'Trained', 'Untrained'};

% imgConds = {'normal','color','g'};
% imgStr = {'Congruent','Incongruent','Gray'};
% groupname = 'Color';

imgConds = {'g','g_hi8','g_lo8'};
imgCondsStr = {'Gray','Hi8','Lo8'};
groupname = 'SpatialFreq';

data = nan(length(training),length(imgConds),length(sessions),length(phases),length(subjects));

for s = 1:length(sessions)
  for p = 1:length(phases)
    for i = 1:length(imgConds)
      
      %collapseData = [];
      
      for t = 1:length(training)
        for n = 1:length(naming)
          data(t,i,s,p,:) = results.(sessions{s}).(phases{p}).(training{t}).(imgConds{i}).(naming{n}).(dataMeasure);
        end
      end
      
    end
  end
end

% % stats
% [h, p, ci, stats] = ttest(squeeze(data.(dataMeasure).(naming{1})(:,1,1,1,1)),squeeze(data.(dataMeasure).(naming{1})(:,2,1,1,1)));

% make some plots
for p = 1:length(phases)
  for s = 1:length(sessions)
    for n = 1:length(naming)
      figure
      
      if strcmp(sessions{s},'pretest')
        data_mean = nanmean(nanmean(data(:,:,s,p,:),1),5);
        data_sem = nanstd(nanmean(data(:,:,s,p,:),1),0,5) ./ sqrt(length(subjects));
      else
        data_mean = nanmean(data(:,:,s,p,:),5);
        data_sem = nanstd(data(:,:,s,p,:),0,5) ./ sqrt(length(subjects));
      end
      
      bw_legend = imgCondsStr;
      
      bw_title = sprintf('%s: %s, %s',groupname,sesStr{s},naming{n});
      %bw_title = sprintf('%s%s: %s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'),strrep(imgConds{i},'_','\_'));
      %bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
      if strcmp(sessions{s},'pretest')
        bw_groupnames = [];
        axis_x = 1.5;
      else
        bw_groupnames = trainingStr;
        %axis_x = length(training) + 1.5;
        axis_x = length(training) + 0.5;
      end
      %bw_xlabel = 'Test day';
      bw_xlabel = [];
      bw_ylabel = dataLabel;
      if exist('linspecer','file')
        bw_colormap = 'linspecer';
      else
        bw_colormap = 'gray';
      end
      bw_data = data_mean;
      bw_errors = data_sem;
      h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
      set(h.legend,'Location','NorthEast');
      axis([0.5 axis_x ylimits(1) ylimits(2)]);
      
      if length(sessions) == 1 && strcmp(sessions{s},'pretest')
        xlabel('Collapsed');
      end
      publishfig(gcf,0);
      
      if saveFigs
        %print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%s_%s_%s_%s',phases{p},dataMeasure,sessions{s},naming{n},groupname)));
      end
    end
  end
end

%% NEWEST: d' bootci - break pre/post tests into different graphs - training x naming x img cond

% pretest only will collapse across training

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [-0.9 3.1];

% dataMeasure = 'rt_hit';
% dataLabel = 'Response Time: Hits';
% ylimits = [0 5000];

% dataMeasure = 'hr';
% dataLabel = 'Hit Rate';
% ylimits = [0 1];

% dataMeasure = 'c';
% dataLabel = 'Response bias (criterion; c)';
% ylimits = [-0.6 0.6];
% % positive/conservative bias indicates a tendency to say 'new', whereas
% % negative/liberal bias indicates a tendency to say 'old'

% dataMeasure = 'Br';
% dataLabel = 'Response bias index (Br)';
% ylimits = [0 1];

% dataMeasure = 'Pr';
% dataLabel = 'Discrimination index (Pr)';
% ylimits = [0 1];

% sessions = {'pretest', 'posttest', 'posttest_delay'};
% sesStr = {'Pretest', 'Posttest', 'Delay'};

% sessions = {'pretest'};
% sesStr = {'Pretest'};
% training = {'TT','UU','TU','UT'};
% trainingStr = {'Trained','Untrained','TU','UT'};

sessions = {'posttest', 'posttest_delay'};
sesStr = {'Posttest', 'Delay'};
% training = {'TT'};
% trainingStr = {'Trained'};
training = {'TT','UU'};
trainingStr = {'Trained', 'Untrained'};

if collapsePhases
  phases = {'match'};
else
  phases = {'match_1'};
end

naming = {'basic','subord'};
namingStr = {'Basic','Subordinate'};
% naming = {'subord'};
% namingStr = {'Subordinate'};

% imgConds = {'normal','color','g'};
% % imgStr = {'Congruent','Incongruent','Gray'};
% imgCondsStr = {'Cong','Inc','Gray'};
% groupname = 'Color';
% imgDiffs = {{'normal', 'color'},{'normal', 'g'},{'color', 'g'}};
% imgDiffsStr = {'Cong - Inc', 'Cong - Gray', 'Inc - Gray'};

imgConds = {'g','g_hi8','g_lo8'};
imgCondsStr = {'Gray','Hi8','Lo8'};
groupname = 'SpatialFreq';
imgDiffs = {{'g', 'g_hi8'},{'g', 'g_lo8'},{'g_hi8', 'g_lo8'}};
imgDiffsStr = {'Gray - Hi8', 'Gray - Lo8', 'Hi8 - Lo8'};

data = nan(length(training),length(naming),length(imgConds),length(sessions),length(phases),length(subjects));

for s = 1:length(sessions)
  for p = 1:length(phases)
    for i = 1:length(imgConds)
      for t = 1:length(training)
        for n = 1:length(naming)
          data(t,n,i,s,p,:) = results.(sessions{s}).(phases{p}).(training{t}).(imgConds{i}).(naming{n}).(dataMeasure);
        end
      end
    end
  end
end

data_diffs = nan(length(training),length(naming),length(imgDiffs),length(sessions),length(phases),length(subjects));

for s = 1:length(sessions)
  for p = 1:length(phases)
    for i = 1:length(imgDiffs)
      for t = 1:length(training)
        for n = 1:length(naming)
          data_diffs(t,n,i,s,p,:) = results.(sessions{s}).(phases{p}).(training{t}).(imgDiffs{i}{1}).(naming{n}).(dataMeasure) - results.(sessions{s}).(phases{p}).(training{t}).(imgDiffs{i}{2}).(naming{n}).(dataMeasure);
        end
      end
    end
  end
end

% bar options
bw_width = 0.75;
%bw_gridstatus = [];
bw_gridstatus = 'y';
bw_error_sides = 2;
%bw_legend_type = 'plot';
bw_legend_type = 'axis';

% make some plots
for p = 1:length(phases)
  for s = 1:length(sessions)
    
    if strcmp(sessions{s},'pretest')
      
      % collapse across training and basic/subordinate
      
      nboot = 10000;
      bootfun = @(x) mean(x);
      boottype = 'bca';
      data_ci_all = [];
      for i = 1:length(imgDiffs)
        fprintf('Calculating bootstrap confidence intervals for %s %s (collapsed)...',sessions{s},imgDiffsStr{i});
        data_ci = bootci(nboot,{bootfun,squeeze(nanmean(nanmean(data_diffs(:,:,i,s,p,:),1),2))'},'type',boottype);
        
        data_ci_all = cat(2,data_ci_all,data_ci);
        fprintf('Done.\n');
      end
      
      % collapse across training conditions
      data_mean = squeeze(nanmean(nanmean(nanmean(data(:,:,:,s,p,:),1),2),6))';
      data_sem = squeeze(nanstd(nanmean(nanmean(data(:,:,:,s,p,:),1),2),0,6))' ./ sqrt(length(subjects));
      
      data_diffs_mean = squeeze(nanmean(nanmean(nanmean(data_diffs(:,:,:,s,p,:),1),2),6))';
      
      %data_mean = cat(1,data_mean, data_diffs_mean);
      data_mean = cat(2,data_mean, data_diffs_mean);
      
      data_err_low = data_sem;
      data_err_up = data_sem;
      
      % set the upper and lower error bars
      %data_err_low = cat(1,data_err_low, data_diffs_mean - data_ci_all(1,:));
      %data_err_up = cat(1,data_err_up, data_ci_all(2,:) - data_diffs_mean);
      data_err_low = cat(2,data_err_low, data_diffs_mean - data_ci_all(1,:));
      data_err_up = cat(2,data_err_up, data_ci_all(2,:) - data_diffs_mean);
      
      figure
      
      %bw_legend = imgStr;
      bw_legend = cat(2,imgCondsStr,imgDiffsStr);
      
      bw_title = sprintf('%s: %s',groupname,sesStr{s});
      if strcmp(sessions{s},'pretest')
        bw_groupnames = [];
        axis_x = 1.5;
      else
        %bw_groupnames = trainStr;
        bw_groupnames = [];
        %axis_x = length(training) + 1.5;
        axis_x = length(training) + 0.5;
      end
      %bw_xlabel = 'Test day';
      bw_xlabel = [];
      bw_ylabel = dataLabel;
      if exist('linspecer','file')
        bw_colormap = 'linspecer';
      else
        bw_colormap = 'gray';
      end
      bw_data = data_mean;
      bw_errors_up = data_err_up;
      bw_errors_low = data_err_low;
      
      %       bw_data = data_mean';
      %       bw_errors_up = data_err_up';
      %       bw_errors_low = data_err_low';
      %
      %       bw_data = bw_data(:)';
      %       bw_errors_up = bw_errors_up(:)';
      %       bw_errors_low = bw_errors_low(:)';
      
      h = barweb_uplow(bw_data,bw_errors_up,bw_errors_low,bw_width,bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,bw_gridstatus,bw_legend,bw_error_sides,bw_legend_type);
      if strcmp(bw_legend_type,'plot')
        set(h.legend,'Location','NorthEast');
      end
      axis([0.5 axis_x ylimits(1) ylimits(2)]);
      %axis([0.5 axis_x min(bw_data - bw_errors_low)-0.5 max(bw_data + bw_errors_up)+0.5]);
      
      %if strcmp(sessions{s},'pretest')
      %  xlabel('Collapsed');
      %end
      set(gca,'YTick',0:1:round(ylimits(2)));
      publishfig(gcf,0);
      
      if saveFigs
        fileName = sprintf('mean_sem_ci_%s_%s_%s_%s',phases{p},dataMeasure,sessions{s},groupname);
        print(gcf,figFormat,figRes,fullfile(figsDir,fileName));
      end
      
    else
      for t = 1:length(training)
        for n = 1:length(naming)
          nboot = 10000;
          bootfun = @(x) mean(x);
          boottype = 'bca';
          data_ci_all = [];
          for i = 1:length(imgDiffs)
            fprintf('Calculating bootstrap confidence intervals for %s %s %s %s...',sesStr{s},namingStr{n},trainingStr{t},imgDiffsStr{i});
            data_ci = bootci(nboot,{bootfun,squeeze(data_diffs(t,n,i,s,p,:))'},'type',boottype);
            
            data_ci_all = cat(2,data_ci_all,data_ci);
            fprintf('Done.\n');
          end
          
          data_mean = squeeze(nanmean(data(t,n,:,s,p,:),6))';
          data_sem = squeeze(nanstd(data(t,n,:,s,p,:),0,6))' ./ sqrt(length(subjects));
          
          data_diffs_mean = squeeze(nanmean(data_diffs(t,n,:,s,p,:),6))';
          
          %data_mean = cat(1,data_mean, data_diffs_mean);
          data_mean = cat(2,data_mean, data_diffs_mean);
          
          data_err_low = data_sem;
          data_err_up = data_sem;
          
          % set the upper and lower error bars
          %data_err_low = cat(1,data_err_low, data_diffs_mean - data_ci_all(1,:));
          %data_err_up = cat(1,data_err_up, data_ci_all(2,:) - data_diffs_mean);
          data_err_low = cat(2,data_err_low, data_diffs_mean - data_ci_all(1,:));
          data_err_up = cat(2,data_err_up, data_ci_all(2,:) - data_diffs_mean);
          
          figure
          
          %bw_legend = imgStr;
          bw_legend = cat(2,imgCondsStr,imgDiffsStr);
          
          bw_title = sprintf('%s: %s, %s, %s',groupname,sesStr{s},trainingStr{t},namingStr{n});
          %bw_groupnames = {'Pretest', 'Posttest', 'Delay'};
          if strcmp(sessions{s},'pretest')
            bw_groupnames = [];
            axis_x = 1.5;
          else
            %bw_groupnames = trainStr;
            bw_groupnames = [];
            %axis_x = length(training) + 1.5;
            %axis_x = length(training) + 0.5;
            axis_x = 1.5;
          end
          %bw_xlabel = 'Test day';
          bw_xlabel = [];
          bw_ylabel = dataLabel;
          if exist('linspecer','file')
            bw_colormap = 'linspecer';
          else
            bw_colormap = 'gray';
          end
          bw_data = data_mean;
          bw_errors_up = data_err_up;
          bw_errors_low = data_err_low;
          
          %       bw_data = data_mean';
          %       bw_errors_up = data_err_up';
          %       bw_errors_low = data_err_low';
          %
          %       bw_data = bw_data(:)';
          %       bw_errors_up = bw_errors_up(:)';
          %       bw_errors_low = bw_errors_low(:)';
          
          h = barweb_uplow(bw_data,bw_errors_up,bw_errors_low,bw_width,bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,bw_gridstatus,bw_legend,bw_error_sides,bw_legend_type);
          if strcmp(bw_legend_type,'plot')
            set(h.legend,'Location','NorthEast');
          end
          axis([0.5 axis_x ylimits(1) ylimits(2)]);
          %axis([0.5 axis_x min(bw_data - bw_errors_low)-0.5 max(bw_data + bw_errors_up)+0.5]);
          
          %if strcmp(sessions{s},'pretest')
          %  xlabel('Collapsed');
          %end
          set(gca,'YTick',0:1:round(ylimits(2)));
          publishfig(gcf,0);
          
          if saveFigs
            fileName = sprintf('mean_sem_ci_%s_%s_%s_%s_%s_%s',phases{p},dataMeasure,sessions{s},trainingStr{t},namingStr{n},groupname);
            print(gcf,figFormat,figRes,fullfile(figsDir,fileName));
          end
        end % name
      end % train
    end % if pretest or other
  end % session
end % phase


%% old stuff

% %% plot basic and subordinate RTs across training days
% 
% nTrainSes = 6;
% phases = {'name_1','name_2','name_3','name_4'};
% 
% rt.overall = nan(length(subjects),nTrainSes,length(phases));
% rt.basic = nan(length(subjects),nTrainSes,length(phases));
% rt.subord = nan(length(subjects),nTrainSes,length(phases));
% 
% % dataField = 'rt';
% dataMeasure = 'rt_cor';
% 
% for t = 1:nTrainSes
%   sesName = sprintf('train%d',t);
%   for p = 1:length(phases)
%     if isfield(results.(sesName),phases{p})
%       rt.overall(:,t,p) = results.(sesName).(phases{p}).overall.(dataMeasure);
%       rt.basic(:,t,p) = results.(sesName).(phases{p}).basic.(dataMeasure);
%       rt.subord(:,t,p) = results.(sesName).(phases{p}).subord.(dataMeasure);
%     end
%   end
% end
% 
% for p = 1:length(phases)
%   figure
%   
%   bRT_mean = nanmean(rt.basic(:,:,p),1);
%   bRT_sem = nanstd(rt.basic(:,:,p),0,1) ./ sqrt(sum(~isnan(rt.basic(:,:,p))));
%   %plot(1:nTrainSes,bRT_mean,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   errorbar(bRT_mean,bRT_sem,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   hold on
%   
%   sRT_mean = nanmean(rt.subord(:,:,p),1);
%   sRT_sem = nanstd(rt.subord(:,:,p),0,1) ./ sqrt(sum(~isnan(rt.subord(:,:,p))));
%   %plot(1:nTrainSes,sRT_mean,'ks-','LineWidth',2);
%   errorbar(sRT_mean,sRT_sem,'ks-','LineWidth',2);
%   
%   % oRT_mean = nanmean(rt.overall(:,:,p),1);
%   % oRT_sem = nanstd(rt.overall(:,:,p),0,1) ./ sqrt(sum(~isnan(rt.overall(:,:,p))));
%   % % plot(1:nTrainSes,oRT_mean,'ro-','LineWidth',2);
%   % errorbar(oRT_mean,oRT_sem,'ro-','LineWidth',2);
%   hold off
%   
%   %axis([0.5 (nTrainSes + 0.5) 0 round(max(rt.overall(:))/100)*100]);
%   axis([0.5 (nTrainSes + 0.5) 0 600]);
%   title(sprintf('Naming phase %d: %s',p,strrep(dataMeasure,'_','\_')));
%   xlabel('Training Day');
%   ylabel('Response Time (ms)');
%   
%   legend({'Basic','Subordinate'},'Location','NorthEast');
%   %legend({'Basic','Subordinate','Overall'});
%   
%   publishfig(gcf,0);
% end

% %% plot basic and subordinate accuracy across training days
% 
% nTrainSes = 6;
% phases = {'name_1','name_2','name_3','name_4'};
% 
% acc.overall = nan(length(subjects),nTrainSes,length(phases));
% acc.basic = nan(length(subjects),nTrainSes,length(phases));
% acc.subord = nan(length(subjects),nTrainSes,length(phases));
% 
% dataMeasure = 'acc';
% 
% for t = 1:nTrainSes
%   sesName = sprintf('train%d',t);
%   for p = 1:length(phases)
%     if isfield(results.(sesName),phases{p})
%       acc.overall(:,t,p) = results.(sesName).(phases{p}).overall.(dataMeasure);
%       acc.basic(:,t,p) = results.(sesName).(phases{p}).basic.(dataMeasure);
%       acc.subord(:,t,p) = results.(sesName).(phases{p}).subord.(dataMeasure);
%     end
%   end
% end
% 
% for p = 1:length(phases)
%   figure
%   
%   bAcc_mean = nanmean(acc.basic(:,:,p),1);
%   bAcc_sem = nanstd(acc.basic(:,:,p),0,1) ./ sqrt(sum(~isnan(acc.basic(:,:,p))));
%   %plot(1:nTrainSes,bAcc_mean,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   errorbar(bAcc_mean,bAcc_sem,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   hold on
%   
%   sAcc_mean = nanmean(acc.subord(:,:,p),1);
%   sAcc_sem = nanstd(acc.subord(:,:,p),0,1) ./ sqrt(sum(~isnan(acc.subord(:,:,p))));
%   %plot(1:nTrainSes,sAcc_mean,'ks-','LineWidth',2);
%   errorbar(sAcc_mean,sAcc_sem,'ks-','LineWidth',2);
%   
%   % oAcc_mean = nanmean(acc.overall(:,:,p),1);
%   % oAcc_sem = nanstd(acc.overall(:,:,p),0,1) ./ sqrt(sum(~isnan(acc.overall(:,:,p))));
%   % % plot(1:nTrainSes,oAcc_mean,'ro-','LineWidth',2);
%   % errorbar(oAcc_mean,oAcc_sem,'ro-','LineWidth',2);
%   hold off
%   
%   %axis([0.5 6.5 0 round(max(acc.overall(:))/100)*100]);
%   axis([0.5 6.5 0.5 1]);
%   title(sprintf('Naming phase %d: %s',p,strrep(dataMeasure,'_','\_')));
%   xlabel('Training Day');
%   ylabel('Accuracy');
%   
%   legend({'Basic','Subordinate'},'Location','SouthEast');
%   %legend({'Basic','Subordinate','Overall','Location','SouthEast'});
%   
%   publishfig(gcf,0);
% end

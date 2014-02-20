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
basic_sem = nanstd(data.basic,1) ./ sqrt(sum(~isnan(data.basic)));
hb = errorbar(basic_mean,basic_sem,'ro-','LineWidth',2);
hold on

subordData_mean = nanmean(data.subord,1);
subordData_sem = nanstd(data.subord,1) ./ sqrt(sum(~isnan(data.subord)));
hs = errorbar(subordData_mean,subordData_sem,'ks-','LineWidth',2);

if plotOverall
  overall_mean = nanmean(data.overall,1);
  overall_sem = nanstd(data.overall,1) ./ sqrt(sum(~isnan(data.overall)));
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
training = {'TT','UU','TU','UT'};
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
        data_sem(s,t) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t),1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t))));
      end
    end
    
    bw_title = sprintf('%s%s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'));
    bw_groupnames = {'Pretest', 'Posttest', 'One week later'};
    %bw_legend = {'Trained','Untrained'};
    bw_legend = {'TT','UU','TU','UT'};
    %bw_xlabel = 'Test day';
    bw_xlabel = [];
    bw_ylabel = dataLabel;
    bw_colormap = 'gray';
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
% dataLabel = 'Accuracy (Hit Rate)';
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
training = {'TT','UU','TU','UT'};
naming = {'basic','subord'};
imgConds = {'normal','color','g','g_hi8','g_lo8'};

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
          data_sem(s,t) = nanstd(data.(dataMeasure).(naming{n})(:,s,p,t,i),1) ./ sqrt(sum(~isnan(data.(dataMeasure).(naming{n})(:,s,p,t,i))));
        end
      end
      
      bw_title = sprintf('%s%s: %s: %s',upper(naming{n}(1)),naming{n}(2:end),strrep(phases{p},'_','\_'),strrep(imgConds{i},'_','\_'));
      bw_groupnames = {'Pretest', 'Posttest', 'One week later'};
      %bw_legend = {'Trained','Untrained'};
      bw_legend = {'TT','UU','TU','UT'};
      %bw_xlabel = 'Test day';
      bw_xlabel = [];
      bw_ylabel = dataLabel;
      bw_colormap = 'gray';
      bw_data = data_mean;
      bw_errors = data_sem;
      h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend,[],'plot');
      set(h.legend,'Location','NorthWest');
      axis([0.5 (length(sessions)+0.5) ylimits(1) ylimits(2)]);
      publishfig(gcf,0);
      if saveFigs
        print(gcf,figFormat,figRes,fullfile(figsDir,sprintf('prepost_trainUn_%s_%s_%s_%s',phases{p},dataMeasure,naming{n},imgConds{i})));
      end
    end
  end
end

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
%   bRT_sem = nanstd(rt.basic(:,:,p),1) ./ sqrt(sum(~isnan(rt.basic(:,:,p))));
%   %plot(1:nTrainSes,bRT_mean,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   errorbar(bRT_mean,bRT_sem,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   hold on
%   
%   sRT_mean = nanmean(rt.subord(:,:,p),1);
%   sRT_sem = nanstd(rt.subord(:,:,p),1) ./ sqrt(sum(~isnan(rt.subord(:,:,p))));
%   %plot(1:nTrainSes,sRT_mean,'ks-','LineWidth',2);
%   errorbar(sRT_mean,sRT_sem,'ks-','LineWidth',2);
%   
%   % oRT_mean = nanmean(rt.overall(:,:,p),1);
%   % oRT_sem = nanstd(rt.overall(:,:,p),1) ./ sqrt(sum(~isnan(rt.overall(:,:,p))));
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
%   bAcc_sem = nanstd(acc.basic(:,:,p),1) ./ sqrt(sum(~isnan(acc.basic(:,:,p))));
%   %plot(1:nTrainSes,bAcc_mean,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   errorbar(bAcc_mean,bAcc_sem,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
%   hold on
%   
%   sAcc_mean = nanmean(acc.subord(:,:,p),1);
%   sAcc_sem = nanstd(acc.subord(:,:,p),1) ./ sqrt(sum(~isnan(acc.subord(:,:,p))));
%   %plot(1:nTrainSes,sAcc_mean,'ks-','LineWidth',2);
%   errorbar(sAcc_mean,sAcc_sem,'ks-','LineWidth',2);
%   
%   % oAcc_mean = nanmean(acc.overall(:,:,p),1);
%   % oAcc_sem = nanstd(acc.overall(:,:,p),1) ./ sqrt(sum(~isnan(acc.overall(:,:,p))));
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

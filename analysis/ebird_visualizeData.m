% basic analysis script for expertTrain experiments

% TODO: plot individual subjects along with mean/SEM

% TODO: is there a better kind of plot to use, e.g., box and whisker?

%% set the subjects and run the data processing script
subjects = {
  'EBIRD049';
  'EBIRD002';
  'EBIRD003';
  };

[results] = ebird_processData(subjects,true);

%% plot basic and subordinate RTs across training days

nTrainSes = 6;
phases = {'name_1','name_2','name_3','name_4'};

rt.overall = nan(length(subjects),nTrainSes,length(phases));
rt.basic = nan(length(subjects),nTrainSes,length(phases));
rt.subord = nan(length(subjects),nTrainSes,length(phases));

% dataField = 'rt';
dataMeasure = 'rt_cor';

for t = 1:nTrainSes
  sesName = sprintf('train%d',t);
  for p = 1:length(phases)
    if isfield(results.(sesName),phases{p})
      rt.overall(:,t,p) = results.(sesName).(phases{p}).overall.(dataMeasure);
      rt.basic(:,t,p) = results.(sesName).(phases{p}).basic.(dataMeasure);
      rt.subord(:,t,p) = results.(sesName).(phases{p}).subord.(dataMeasure);
    end
  end
end

for p = 1:length(phases)
  figure
  
  bRT_mean = nanmean(rt.basic(:,:,p),1);
  bRT_sem = nanstd(rt.basic(:,:,p),1) ./ sqrt(sum(~isnan(rt.basic(:,:,p))));
  %plot(1:nTrainDays,bRT_mean,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
  errorbar(bRT_mean,bRT_sem,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
  hold on
  
  sRT_mean = nanmean(rt.subord(:,:,p),1);
  sRT_sem = nanstd(rt.subord(:,:,p),1) ./ sqrt(sum(~isnan(rt.subord(:,:,p))));
  %plot(1:nTrainDays,sRT_mean,'ks-','LineWidth',2);
  errorbar(sRT_mean,sRT_sem,'ks-','LineWidth',2);
  
  % oRT_mean = nanmean(rt.overall(:,:,p),1);
  % oRT_sem = nanstd(rt.overall(:,:,p),1) ./ sqrt(sum(~isnan(rt.overall(:,:,p))));
  % % plot(1:nTrainDays,oRT_mean,'ro-','LineWidth',2);
  % errorbar(oRT_mean,oRT_sem,'ro-','LineWidth',2);
  hold off
  
  %axis([0.5 6.5 0 round(max(rt.overall(:))/100)*100]);
  axis([0.5 6.5 0 600]);
  title(sprintf('Naming phase %d: %s',p,strrep(dataMeasure,'_','\_')));
  xlabel('Training Day');
  ylabel('Response Time (ms)');
  
  legend({'Basic','Subordinate'},'Location','NorthEast');
  %legend({'Basic','Subordinate','Overall'});
  
  publishfig(gcf,0);
end

%% plot basic and subordinate accuracy across training days

nTrainSes = 6;
phases = {'name_1','name_2','name_3','name_4'};

acc.overall = nan(length(subjects),nTrainSes,length(phases));
acc.basic = nan(length(subjects),nTrainSes,length(phases));
acc.subord = nan(length(subjects),nTrainSes,length(phases));

dataMeasure = 'acc';

for t = 1:nTrainSes
  sesName = sprintf('train%d',t);
  for p = 1:length(phases)
    if isfield(results.(sesName),phases{p})
      acc.overall(:,t,p) = results.(sesName).(phases{p}).overall.(dataMeasure);
      acc.basic(:,t,p) = results.(sesName).(phases{p}).basic.(dataMeasure);
      acc.subord(:,t,p) = results.(sesName).(phases{p}).subord.(dataMeasure);
    end
  end
end

for p = 1:length(phases)
  figure
  
  bAcc_mean = nanmean(acc.basic(:,:,p),1);
  bAcc_sem = nanstd(acc.basic(:,:,p),1) ./ sqrt(sum(~isnan(acc.basic(:,:,p))));
  %plot(1:nTrainDays,bAcc_mean,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
  errorbar(bAcc_mean,bAcc_sem,'d-','LineWidth',2,'Color',[0.5 0.5 0.5]);
  hold on
  
  sAcc_mean = nanmean(acc.subord(:,:,p),1);
  sAcc_sem = nanstd(acc.subord(:,:,p),1) ./ sqrt(sum(~isnan(acc.subord(:,:,p))));
  %plot(1:nTrainDays,sAcc_mean,'ks-','LineWidth',2);
  errorbar(sAcc_mean,sAcc_sem,'ks-','LineWidth',2);
  
  % oAcc_mean = nanmean(acc.overall(:,:,p),1);
  % oAcc_sem = nanstd(acc.overall(:,:,p),1) ./ sqrt(sum(~isnan(acc.overall(:,:,p))));
  % % plot(1:nTrainDays,oAcc_mean,'ro-','LineWidth',2);
  % errorbar(oAcc_mean,oAcc_sem,'ro-','LineWidth',2);
  hold off
  
  %axis([0.5 6.5 0 round(max(acc.overall(:))/100)*100]);
  axis([0.5 6.5 0.5 1]);
  title(sprintf('Naming phase %d: %s',p,strrep(dataMeasure,'_','\_')));
  xlabel('Training Day');
  ylabel('Accuracy');
  
  legend({'Basic','Subordinate'},'Location','SouthEast');
  %legend({'Basic','Subordinate','Overall'});
  
  publishfig(gcf,0);
end

%% collapse across image conditions

% plot basic and subordinate data for pretest, posttest, posttest_delay

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [0 3];

% dataMeasure = 'acc';
% dataLabel = 'Accuracy';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
phases = {'match_1'};
training = {'trained','untrained'};
naming = {'basic','subord'};

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
    bw_legend = {'Trained','Untrained'};
    %bw_xlabel = 'Test day';
    bw_xlabel = [];
    bw_ylabel = dataLabel;
    bw_colormap = 'gray';
    bw_data = data_mean;
    bw_errors = data_sem;
    h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend);
    set(h.legend,'Location','NorthEast');
    axis([0.5 3.5 ylimits(1) ylimits(2)]);
    publishfig(gcf,0);
  end
end

%% image manipulation conditions

% plot basic and subordinate data for pretest, posttest, posttest_delay

dataMeasure = 'dp';
dataLabel = 'd''';
ylimits = [0 4];

% dataMeasure = 'acc';
% dataLabel = 'Accuracy';
% ylimits = [0 1];

sessions = {'pretest', 'posttest', 'posttest_delay'};
phases = {'match_1'};
training = {'trained','untrained'};
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
      bw_legend = {'Trained','Untrained'};
      %bw_xlabel = 'Test day';
      bw_xlabel = [];
      bw_ylabel = dataLabel;
      bw_colormap = 'gray';
      bw_data = data_mean;
      bw_errors = data_sem;
      h = barweb(bw_data,bw_errors,[],bw_groupnames,bw_title,bw_xlabel,bw_ylabel,bw_colormap,[],bw_legend);
      set(h.legend,'Location','NorthEast');
      axis([0.5 3.5 ylimits(1) ylimits(2)]);
      publishfig(gcf,0);
    end
  end
end



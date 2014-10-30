% ebug behavioral analysis

%% load the analysis details

expName = 'EBUG';

subDir = '';
behDir = fullfile(expName,'Behavioral','Sessions',subDir);
eegDir = fullfile(expName,'EEG','Sessions','ftpp',subDir);
% Possible locations of the data files (dataroot)
serverDir = fullfile(filesep,'Volumes','curranlab','Data');
serverLocalDir = fullfile(filesep,'Volumes','RAID','curranlab','Data');
dreamDir = fullfile(filesep,'data','projects','curranlab');
localDir = fullfile(getenv('HOME'),'data');

% pick the right dataroot
if exist('serverDir','var') && exist(serverDir,'dir')
  dataroot = serverDir;
elseif exist('serverLocalDir','var') && exist(serverLocalDir,'dir')
  dataroot = serverLocalDir;
elseif exist('dreamDir','var') && exist(dreamDir,'dir')
  dataroot = dreamDir;
elseif exist('localDir','var') && exist(localDir,'dir')
  dataroot = localDir;
else
  error('Data directory not found.');
end

% procDir = fullfile(dataroot,eegDir,'ft_data/???????????/tla');

behDir = fullfile(dataroot,behDir);

subjects = {
    'EBUG010';
    'EBUG012';
    'EBUG016';
    'EBUG017';
    'EBUG018';
    'EBUG019';
    'EBUG020';
    'EBUG022';
    'EBUG025';
    'EBUG027';
    'EBUG029';
    'EBUG030';
    'EBUG032';
    'EBUG045';
%     'EBUG047';
    'EBUG051';
    'EBUG052';
    'EBUG054';
    'EBUG055';
    'EBUG061';
  };

% % only one cell, with all session names
% sesNames = {'session_1','session_2','session_3','session_4','session_5','session_6','session_7','session_8','session_9'};
% 
% % replaceDataroot = {'/Users/matt/data','/Volumes/curranlab/Data'};
% replaceDataroot = false;
% 
% [exper,ana,dirs,files] = mm_loadAD(procDir,subjects,sesNames,replaceDataroot);

% %% decide who to kick out based on trial counts
% 
% % Subjects with bad behavior
% exper.badBehSub = {{}};
% 
% % exclude subjects with low event counts
% [exper,ana] = mm_threshSubs_multiSes(exper,ana,5,[],'vert');

% only loading saved data for good subjects
exper.badSub = false(length(subjects),1);

%% collapsed or not

collapsePhases = true;
% collapsePhases = false;

if collapsePhases
  collapseStr = '_collapsed';
else
  collapseStr = '';
end

%% split into quantile divisions?

% % nDivisions = 1;
% nDivisions = 2;
% % nDivisions = 3;
% % nDivisions = 4;
% 
% if nDivisions > 1
%   quantStr = sprintf('_%dquantileDiv',nDivisions);
% else
%   quantStr = '';
% end

%% load the behavioral data

% resultsFile = fullfile(behDir,sprintf('%s_behav_results%s%s.mat',expName,quantStr,collapseStr));
% Without quantiles
resultsFile = fullfile(behDir,sprintf('%s_behav_results%s%s.mat',expName,collapseStr));

fprintf('Loading %s...',resultsFile);
load(resultsFile);
fprintf('Done.\n');

%% ttest

alpha = 0.05;
tails = 'both';

% phase = 'match_1';
phase = 'match';

% trainCond = 'trained';
trainCond = 'untrained';


% level = 'basic';
level = 'subord';

measure = 'dp';

ses = 'pretest';
% ses = 'posttest';

  data1 = results.(ses).(phase).(trainCond).(level).(measure)(~exper.badSub);

data1_str = sprintf('%s %s %s %s %s',ses,phase,trainCond,level,measure);

ses = 'posttest';
% ses = 'posttest_delay';


  data2 = results.(ses).(phase).(trainCond).(level).(measure)(~exper.badSub);

data2_str = sprintf('%s %s %s %s %s',ses,phase,trainCond,level,measure);

d = mm_effect_size('within',data1,data2);
[h, p, ci, stats] = ttest(data1,data2,alpha,tails);

fprintf('%s (M=%.2f; SEM=%.2f) vs\t%s (M=%.2f; SEM=%.2f):\n\tt(%d)=%.2f, d=%.2f, SD=%.2f, SEM=%.2f, p=%.5f\n', ...
  data1_str, ...
  mean(data1), ...
  std(data1) / sqrt(length(data1)), ...
  data2_str, ...
  mean(data2), ...
  std(data2) / sqrt(length(data2)), ...
  stats.df, ...
  stats.tstat, ...
  d, ...
  std(data1 - data2),...
  std(data1 - data2) / sqrt(length(data1)),...
  p);

%% RMANOVA - prepost

sesNames = {'pretest','posttest','posttest_delay'};
sesStr = {'Pretest','Posttest','Delay'};
trainConds = {'trained','untrained'};
% trainConds = {'TT','UU','TU','UT'};
% trainConds = {'TT','UU'};
trainStr = {'Trained','Untrained'};
famLevel = {'basic','subord'};
famStr = {'Basic','Subordinate'};

phaseName = 'match';
% phaseName = 'match_1';

measure = 'dp';

anovaData = [];

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    theseData = [];
    
    for ses = 1:length(sesNames)
      for trn = 1:length(trainConds)
          for fam = 1:length(famLevel)
            
%             for d = 1:nDivisions
              theseData = cat(2,theseData,results.(sesNames{ses}).(phaseName).(trainConds{trn}).(famLevel{fam}).(measure)(sub));
%             end
            
          end
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end


  varnames = {'Session', 'Training','BasicSubord'};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(trainConds) length(famLevel)], varnames);

% if nDivisions > 1
%   varnames = {'Session', 'Training', 'BasicSubord', 'Quantile'};
%   O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(trainConds) length(famLevel) nDivisions], varnames);
% else
%   varnames = {'Session', 'Training','BasicSubord'};
%   O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(trainConds) length(famLevel)], varnames);
% end

%% write data in long format - all data

%e.g.,
% Participant Session TrainedUntrained ImgCond BasicSubord Quantile dp
% EBIRD001 Pretest Trained Congruent Basic D1 2.5015

sesNames = {'pretest','posttest','posttest_delay'};
sesStr = {'Pretest','Posttest','Delay'};
trainConds = {'trained','untrained'};
% trainConds = {'TT','UU','TU','UT'};
% trainConds = {'TT','UU'};
trainStr = {'Trained','Untrained'};
famLevel = {'basic','subord'};
famStr = {'Basic','Subordinate'};

% phaseName = 'match_1';
phaseName = 'match';

measure = 'dp';

%anovaData = [];

% anovaFile = fullfile(dataroot,'EBUG','Behavioral','Sessions','ANOVA',sprintf('EBUG_ANOVA_long_prepost_%s%s.txt',measure,quantStr));
anovaFile = fullfile(dataroot,'EBUG','Behavioral','Sessions','ANOVA',sprintf('EBUG_ANOVA_long_prepost_%s%s.txt',measure));
fid = fopen(anovaFile,'w+');

fprintf(fid,'Subject\tSession\tTraining\tBasicSubord\t%s\n',measure);
% fprintf(fid,'Subject\tSession\tTraining\tBasicSubord\tQuantDiv\t%s\n',measure);

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    for ses = 1:length(sesNames)
      for trn = 1:length(trainConds)
          for fam = 1:length(famLevel)          
%             for d = 1:nDivisions
              fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%d\t%.4f\n',subjects{sub},sesStr{ses},trainStr{trn},famStr{fam},d,results.(sesNames{ses}).(phaseName).(trainConds{trn}).(famLevel{fam}).(measure)(sub,d));
%             end
          end
      end
    end
  end
end

fclose(fid);

%% write data in long format - posttests - separate for each session, training condition, family learning level

%e.g.,
% Participant Session TrainedUntrained ImgCond BasicSubord Quantile dp
% EBIRD001 Pretest Trained Congruent Basic D1 2.5015

sesNames = {'pretest','posttest','posttest_delay'};
sesStr = {'Pretest','Posttest','Delay'};
% trainConds = {'TT','UU'};
trainConds = {'trained','untrained'};

% sesNames = {'pretest'};
% sesStr = {'Pretest'};
% trainConds = {'TT','UU','TU','UT'};

% sesNames = {'posttest','posttest_delay'};
% sesStr = {'Posttest','Delay'};
% trainConds = {'TT','UU'};

% trainConds = {'trained','untrained'};
trainStr = {'Trained','Untrained'};
famLevel = {'basic','subord'};
famStr = {'Basic','Subordinate'};

% imgConds = {'normal','color','g','g_hi8','g_lo8'};
% imgStr = {'Congruent','Incongruent','Gray','HiSF','LoSF'};

% imgConds = {'g','g_hi8','g_lo8'};
% imgStr = {'Gray','HiSF','LoSF'};
% groupname = 'SF';

phaseName = 'match';
% phaseName = 'match_1';

measure = 'dp';

for ses = 1:length(sesNames)
  for trn = 1:length(trainConds)
    for fam = 1:length(famLevel)
      origdata_dir = fullfile(dataroot,'EBUG','Behavioral','Sessions','ANOVA','origdata_long');
      if ~exist(origdata_dir,'dir')
        mkdir(origdata_dir);
      end
      anovaFile = fullfile(origdata_dir,sprintf('EBUG_ANOVA_long_%s_%s_%s_%s_%s%s.txt',groupname,sesStr{ses},trainStr{trn},famStr{fam},measure,quantStr));
      fid = fopen(anovaFile,'w+');
      fprintf(fid,'Subject\tQuantDiv\t%s\n',measure);
      
      for sub = 1:length(subjects)
        if ~exper.badSub(sub)
            
            for d = 1:nDivisions
              fprintf(fid,'%s\t%s\t%s\t%.4f\n',subjects{sub},sprintf('D%d',d),results.(sesNames{ses}).(phaseName).(trainConds{trn}).(famLevel{fam}).(measure)(sub,d));
            end

        end
      end
      fprintf('Saving %s.\n',anovaFile);
      fclose(fid);
      
    end
  end
end

%% write data in long format - pretest - separate for each session, training condition, family learning level

%e.g.,
% Participant Session TrainedUntrained ImgCond BasicSubord Quantile dp
% EBIRD001 Pretest Trained Congruent Basic D1 2.5015

% sesNames = {'pretest','posttest','posttest_delay'};
% sesStr = {'Pretest','Posttest','Delay'};
% trainConds = {'TT','UU'};

sesNames = {'pretest'};
sesStr = {'Pretest'};
trainConds = {'TT','UU','TU','UT'};

% sesNames = {'posttest','posttest_delay'};
% sesStr = {'Posttest','Delay'};
% trainConds = {'TT','UU'};

% trainConds = {'trained','untrained'};
trainStr = {'Trained','Untrained'};
famLevel = {'basic','subord'};
famStr = {'Basic','Subordinate'};

% imgConds = {'normal','color','g','g_hi8','g_lo8'};
% imgStr = {'Congruent','Incongruent','Gray','HiSF','LoSF'};

% imgConds = {'g','g_hi8','g_lo8'};
% imgStr = {'Gray','HiSF','LoSF'};
% groupname = 'SF';

phaseName = 'match';
% phaseName = 'match_1';

measure = 'dp';

for ses = 1:length(sesNames)
  origdata_dir = fullfile(dataroot,'EBUG','Behavioral','Sessions','ANOVA','origdata_long');
  if ~exist(origdata_dir,'dir')
    mkdir(origdata_dir);
  end
  anovaFile = fullfile(origdata_dir,sprintf('EBUG_ANOVA_long_%s_%s_%s%s.txt',groupname,sesStr{ses},measure,quantStr));
  fid = fopen(anovaFile,'w+');
  fprintf(fid,'Subject\tQuantDiv\t%s\n',measure);
  
  for sub = 1:length(subjects)
    if ~exper.badSub(sub)
        
        for d = 1:nDivisions
          
          % collapse across training and basic/subord for pretest
          collapseData = [];
          
          for trn = 1:length(trainConds)
            for fam = 1:length(famLevel)
              collapseData = cat(2,collapseData,results.(sesNames{ses}).(phaseName).(trainConds{trn}).(famLevel{fam}).(measure)(sub,d));
            end
          end
          
          fprintf(fid,'%s\t%s\t%s\t%.4f\n',subjects{sub},imgStr{img},sprintf('D%d',d),nanmean(collapseData));
          
        end
        
    end
  end
  fprintf('Saving %s.\n',anovaFile);
  fclose(fid);
  
end

%% write to file, with header, quantiles together

anovaFile = fullfile(dataroot,'EBIRD','Behavioral','Sessions','ANOVA',sprintf('EBUG_ANOVA_prepost_%s%s.txt',measure,quantStr));
fid = fopen(anovaFile,'w+');

thisHeader = [];
for i = 1:length(sesNames)
  thisHeader = cat(2,thisHeader,sprintf('%s%s',sesStr{i},repmat(sprintf('\t'),1,length(trainConds) * length(imgConds) * length(famLevel) * nDivisions)));
end
fprintf(fid,'\t%s\n',thisHeader);

thisHeader = [];
for i = 1:length(trainConds)
  thisHeader = cat(2,thisHeader,sprintf('%s%s',trainStr{i},repmat(sprintf('\t'),1,length(imgConds) * length(famLevel) * nDivisions)));
end
thisHeader = repmat(thisHeader,1,length(sesNames));
fprintf(fid,'\t%s\n',thisHeader);

thisHeader = [];
for i = 1:length(imgConds)
  thisHeader = cat(2,thisHeader,sprintf('%s%s',imgStr{i},repmat(sprintf('\t'),1,length(famLevel)  * nDivisions)));
end
thisHeader = repmat(thisHeader,1,length(sesNames) * length(trainConds));
fprintf(fid,'\t%s\n',thisHeader);

thisHeader = [];
for i = 1:length(famLevel)
  thisHeader = cat(2,thisHeader,sprintf('%s%s',famStr{i},repmat(sprintf('\t'),1,(length(famLevel) - 1) * nDivisions)));
end
thisHeader = repmat(thisHeader,1,length(sesNames) * length(trainConds) * length(imgConds));
fprintf(fid,'\t%s\n',thisHeader);

if nDivisions > 1
  thisHeader = [];
  for i = 1:nDivisions
    thisHeader = cat(2,thisHeader,sprintf('%s%s',sprintf('D%d',i),repmat(sprintf('\t'),1,1)));
  end
  thisHeader = repmat(thisHeader,1,length(sesNames) * length(trainConds) * length(imgConds) * (length(famLevel)));
  fprintf(fid,'\t%s\n',thisHeader);
end

for i = 1:size(anovaData,1)
  tData = sprintf('%s',subjects{i});
  %tData = sprintf('%.4f',anovaData(i,1));
  tData = sprintf('%s%s\n',tData,sprintf(repmat('\t%.4f',1,length(anovaData(i,:))),anovaData(i,:)));
  
  fprintf(fid,'%s',tData);
end

fclose(fid);

%% write to file, with header, separate quantiles

if nDivisions > 1
  for d = 1:nDivisions
    anovaFile = fullfile(dataroot,'EBIRD','Behavioral','Sessions','ANOVA',sprintf('EBIRD_ANOVA_prepost_%s%s.txt',measure,sprintf('_D%d',d)));
    fid = fopen(anovaFile,'w+');
    
    thisHeader = [];
    for i = 1:length(sesNames)
      thisHeader = cat(2,thisHeader,sprintf('%s%s',sesStr{i},repmat(sprintf('\t'),1,length(trainConds) * length(imgConds) * length(famLevel))));
    end
    fprintf(fid,'\t%s\n',thisHeader);
    
    thisHeader = [];
    for i = 1:length(trainConds)
      thisHeader = cat(2,thisHeader,sprintf('%s%s',trainStr{i},repmat(sprintf('\t'),1,length(imgConds) * length(famLevel))));
    end
    thisHeader = repmat(thisHeader,1,length(sesNames));
    fprintf(fid,'\t%s\n',thisHeader);
    
    thisHeader = [];
    for i = 1:length(imgConds)
      thisHeader = cat(2,thisHeader,sprintf('%s%s',imgStr{i},repmat(sprintf('\t'),1,length(famLevel))));
    end
    thisHeader = repmat(thisHeader,1,length(sesNames) * length(trainConds));
    fprintf(fid,'\t%s\n',thisHeader);
    
    thisHeader = [];
    for i = 1:length(famLevel)
      thisHeader = cat(2,thisHeader,sprintf('%s%s',famStr{i},repmat(sprintf('\t'),1,length(famLevel) - 1)));
    end
    thisHeader = repmat(thisHeader,1,length(sesNames) * length(trainConds) * length(imgConds));
    fprintf(fid,'\t%s\n',thisHeader);
    
    for i = 1:size(anovaData,1)
      tData = sprintf('%s',subjects{i});
      %tData = sprintf('%.4f',anovaData(i,1));
      tData = sprintf('%s%s\n',tData,sprintf(repmat('\t%.4f',1,length(anovaData(i,d:2:end))),anovaData(i,d:2:end)));
      
      fprintf(fid,'%s',tData);
    end
    
    fclose(fid);
  end
end

%% RMANOVA - train - need to collapse phases

sesNames = {'train1','train2','train3','train4','train5','train6'};
famLevel = {'basic','subord'};

% phaseNames = {'name_1','name_2','name_3','name_4'};
phaseName = 'name';

measure = 'hr';
% measure = 'rt_hit';

anovaData = [];

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    theseData = [];
    
    for ses = 1:length(sesNames)
      for fam = 1:length(famLevel)
        
        theseData = cat(2,theseData,results.(sesNames{ses}).(phaseName).(famLevel{fam}).(measure)(sub));
        
        %for pha = 1:length(phaseNames)
        %  theseData = cat(2,theseData,results.(sesNames{ses}).(phaseNames{pha}).(famLevel{fam}).(measure)(sub));
        %end
        
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end

varnames = {'session', 'basicSubord'};
O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(famLevel)], varnames);

% varnames = {'session', 'basicSubord', 'phaseNum'};
% O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(famLevel) length(phaseNames)], varnames);

%% write to file, with header

anovaFile = fullfile(dataroot,'EBIRD','Behavioral','Sessions','ANOVA',sprintf('EBIRD_ANOVA_train_%s.txt',measure));
fid = fopen(anovaFile,'w+');

thisHeader = [];
for i = 1:length(sesNames)
  thisHeader = cat(2,thisHeader,sprintf('%s%s',sesNames{i},repmat(sprintf('\t'),1,length(famLevel))));
end
fprintf(fid,'\t%s\n',thisHeader);

thisHeader = [];
for i = 1:length(famLevel)
  thisHeader = cat(2,thisHeader,sprintf('%s%s',famLevel{i},repmat(sprintf('\t'),1,length(famLevel) - 1)));
end
thisHeader = repmat(thisHeader,1,length(sesNames));
fprintf(fid,'\t%s\n',thisHeader);

for i = 1:size(anovaData,1)
  tData = sprintf('%s',subjects{i});
  tData = sprintf('%s%s\n',tData,sprintf(repmat('\t%.4f',1,length(anovaData(i,:))),anovaData(i,:)));
  
  fprintf(fid,'%s',tData);
end

fclose(fid);

%% RMANOVA - pre-test vs post-test (diff) x basic/subord x training, for each image manipulation group

% trainConds = {'TT','UU'};
% imgConds = {'normal','color','g'};

% trainConds = {'TT','UU','TU','UT'};
trainConds = {'TT','UU'};
imgConds = {'g','g_hi8','g_lo8'};

% sesNames = {'pretest','posttest','posttest_delay'};

% sesNames = {'posttest', 'pretest'};
% sesNames = {'posttest_delay', 'pretest'};

sesDiff = {{'posttest','pretest'},{'posttest_delay','pretest'}};

famLevel = {'basic','subord'};

phaseName = 'match_1';

measure = 'dp';

anovaData = [];

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    theseData = [];
    
    %for ses = 1:length(sesNames)
    for ses = 1:length(sesDiff)
      for trn = 1:length(trainConds)
        for img = 1:length(imgConds)
          for fam = 1:length(famLevel)
            
            %dp_diff = results.(sesNames{1}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub) - results.(sesNames{2}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub);
            dp_diff = results.(sesDiff{ses}{1}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub) - results.(sesDiff{ses}{2}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub);
            
            theseData = cat(2,theseData,dp_diff);
            
          end
        end
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end

varnames = {'sesDiff', 'training', 'imgConds', 'basicSubord'};
O = teg_repeated_measures_ANOVA(anovaData, [length(sesDiff) length(trainConds) length(imgConds) length(famLevel)], varnames);

%% NEW: RMANOVA - pretest 1-way (or 2-way with quantile), image manipulation conditions (2 groups of 3 manips)

% can also include quantile divisions

% pretest: collapse basic/subord, all training conditions because they
% haven't seen these birds yet

% sesNames = {'pretest','posttest','posttest_delay'};
sesNames = {'pretest'};
% sesNames = {'posttest'};
% sesNames = {'posttest_delay'};

imgConds = {'normal','color','g'};
imgConds = {'g','g_hi8','g_lo8'};

% trainConds = {'trained','untrained'};
trainConds = {'TT','UU','TU','UT'};
% trainConds = {'TT','UU'};
famLevel = {'basic','subord'};

phaseName = 'match_1';

measure = 'dp';

anovaData = [];

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    theseData = [];
    
    for ses = 1:length(sesNames)
      for img = 1:length(imgConds)
        
        for d = 1:nDivisions
          collapsedData = [];
          
          for trn = 1:length(trainConds)
            for fam = 1:length(famLevel)
              
              collapsedData = cat(2,collapsedData,results.(sesNames{ses}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub,d));
              
            end
          end
          
          theseData = cat(2,theseData,nanmean(collapsedData));
        end
        
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end

if nDivisions > 1
  varnames = {'imgConds','Quantile'};
  O = teg_repeated_measures_ANOVA(anovaData, [length(imgConds) nDivisions], varnames);
elseif nDivisions == 1
  varnames = {'imgConds'};
  O = teg_repeated_measures_ANOVA(anovaData, length(imgConds), varnames);
end

%% NEW: RMANOVA - for each image manipulation group: posttest vs posttest_delay x basic/subord x training x image condition

trainConds = {'TT','UU'};
imgConds = {'normal','color','g'};

% % trainConds = {'TT','UU','TU','UT'};
% trainConds = {'TT','UU'};
% imgConds = {'g','g_hi8','g_lo8'};

sesNames = {'posttest', 'posttest_delay'};

famLevel = {'basic','subord'};

phaseName = 'match_1';

measure = 'dp';

anovaData = [];

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    theseData = [];
    
    for ses = 1:length(sesNames)
      for trn = 1:length(trainConds)
        for img = 1:length(imgConds)
          for fam = 1:length(famLevel)
            
            for d = 1:nDivisions
            dp_post = results.(sesNames{ses}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub);
            
            theseData = cat(2,theseData,dp_post);
            end
            
          end
        end
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end

if nDivisions > 1
  varnames = {'sesName', 'training', 'imgConds', 'basicSubord', 'quartile'};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(trainConds) length(imgConds) length(famLevel) nDivisions], varnames);
elseif nDivisions == 1
  varnames = {'sesName', 'training', 'imgConds', 'basicSubord'};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(trainConds) length(imgConds) length(famLevel)], varnames);
end

%% RMANOVA: subordinate only - session x training x image condition (x quantile)

trainConds = {'TT','UU'};
imgConds = {'normal','color','g'};
imgStr = 'Color';

% % trainConds = {'TT','UU','TU','UT'};
% % trainConds = {'TT','UU'};
% imgConds = {'g','g_hi8','g_lo8'};
% imgStr = 'SF';

sesNames = {'pretest', 'posttest'};
sesStr = 'Pre/Post';

% sesNames = {'pretest', 'posttest_delay'};
% sesStr = 'Pre/Delay';

% sesNames = {'posttest', 'posttest_delay'};
% sesStr = 'Post/Delay';

% famLevel = {'basic'};
famLevel = {'subord'};

phaseName = 'match_1';

measure = 'dp';

anovaData = [];

% fn = {};
fn = cell(1,prod([length(sesNames) length(trainConds) length(imgConds) nDivisions]));

for sub = 1:length(subjects)
  fnCount = 0;

  if ~exper.badSub(sub)
    
    theseData = [];
    
    for ses = 1:length(sesNames)
      for trn = 1:length(trainConds)
        for img = 1:length(imgConds)
          for fam = 1:length(famLevel)
            
            for d = 1:nDivisions
              fnCount = fnCount + 1;
              fn{fnCount} = sprintf('%s_%s_%s_%s_%d',sesNames{ses},trainConds{trn},imgConds{img},famLevel{fam},d);
              
              dp_post = results.(sesNames{ses}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub,d);
              
              theseData = cat(2,theseData,dp_post);
            end
          end
        end
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end

if nDivisions > 1
  varnames = {sesStr, 'Training', imgStr, 'Quantile'};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(trainConds) length(imgConds) nDivisions], varnames);
  
  %[efs,F,cdfs,p,eps,dfs,b,y2,sig]=repanova(anovaData,[length(sesNames) length(trainConds) length(imgConds) nDivisions],fn);
  
elseif nDivisions == 1
  varnames = {sesStr, 'Training', imgStr};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(trainConds) length(imgConds)], varnames);
  
  %[efs,F,cdfs,p,eps,dfs,b,y2,sig]=repanova(anovaData,[length(sesNames) length(trainConds) length(imgConds)],fn);
end

%% RMANOVA: pre/post x basic/sub x image condition (color and SF) (collapse TT+UU training)

% subordinate only

% Would be good to show a pre/post by sub/basic interaction with followups
% showing significant pre/post effects for subordinate but not basic.

sesNames = {'pretest','posttest'};
sesStr = 'Pre/Post';
% sesNames = {'pretest','posttest_delay'};
% sesStr = 'Pre/Delay';
% sesNames = {'posttest'};
% sesNames = {'posttest_delay'};

imgConds = {'normal','color','g'};
imgStr = 'Color';
% imgConds = {'g','g_hi8','g_lo8'};
% imgStr = 'SF';

% trainConds = {'trained','untrained'};
% trainConds = {'TT','UU','TU','UT'};
trainConds = {'TT','UU'};
famLevel = {'basic','subord'};

phaseName = 'match_1';

measure = 'dp';

anovaData = [];

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    theseData = [];
    
    for ses = 1:length(sesNames)
      for fam = 1:length(famLevel)
        
        for img = 1:length(imgConds)
          for d = 1:nDivisions
            collapsedData = [];
            
            for trn = 1:length(trainConds)
              collapsedData = cat(2,collapsedData,results.(sesNames{ses}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub,d));
            end
            
            theseData = cat(2,theseData,nanmean(collapsedData));
            
          end
        end
        
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end

if nDivisions > 1
  varnames = {sesStr, 'Basic/Subord', imgStr, 'Quantile'};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(famLevel) length(imgConds) nDivisions], varnames);
elseif nDivisions == 1
  varnames = {sesStr, 'Basic/Subord', imgStr};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(famLevel) length(imgConds)], varnames);
end

%% RMANOVA: pre/post x basic/sub x training x image condition

% subordinate only

% Would be good to show a pre/post by sub/basic interaction with followups
% showing significant pre/post effects for subordinate but not basic.

sesNames = {'pretest','posttest'};
sesStr = 'Pre/Post';
% sesNames = {'pretest','posttest_delay'};
% sesStr = 'Pre/Delay';
% sesNames = {'posttest'};
% sesNames = {'posttest_delay'};

imgConds = {'normal','color','g'};
imgStr = 'Color';
% imgConds = {'g','g_hi8','g_lo8'};
% imgStr = 'SF';

% trainConds = {'trained','untrained'};
% trainConds = {'TT','UU','TU','UT'};
trainConds = {'TT','UU'};
famLevel = {'basic','subord'};

phaseName = 'match_1';

measure = 'dp';

anovaData = [];

collapseTrain = false;

for sub = 1:length(subjects)
  
  if ~exper.badSub(sub)
    
    theseData = [];
    
    for ses = 1:length(sesNames)
      for fam = 1:length(famLevel)
        
        for trn = 1:length(trainConds)
          
          for img = 1:length(imgConds)
            for d = 1:nDivisions
              theseData = cat(2,theseData,results.(sesNames{ses}).(phaseName).(trainConds{trn}).(imgConds{img}).(famLevel{fam}).(measure)(sub,d));
            end
          end
          
        end
        
      end
    end
    anovaData = cat(1,anovaData,theseData);
  end
end

if nDivisions > 1
  varnames = {sesStr, 'Basic/Subord', 'Training', imgStr, 'Quantile'};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(famLevel) length(trainConds) length(imgConds) nDivisions], varnames);
elseif nDivisions == 1
  varnames = {sesStr, 'Basic/Subord', 'Training', imgStr};
  O = teg_repeated_measures_ANOVA(anovaData, [length(sesNames) length(famLevel) length(trainConds) length(imgConds)], varnames);
end

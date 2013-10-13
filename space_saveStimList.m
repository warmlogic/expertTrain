function [cfg] = space_saveStimList(cfg,imgStimDir,wpStimDir,stimInfoStruct)
% function [cfg] = space_saveStimList(cfg,imgStimDir,wpStimDir,stimInfoStruct)

if exist(cfg.files.expParamFile,'file')
  error('Experiment parameter file should not exist before stimulus list has been created: %s',cfg.files.expParamFile);
end

%% image stimuli

fprintf('Creating image stimulus list: %s...',stimInfoStruct.imgStimListFile);

if exist(imgStimDir,'dir')
  % for this subject, write out the file containing all stimuli
  fid = fopen(stimInfoStruct.imgStimListFile,'w');
  fprintf(fid,'fileName\tcategoryStr\tcategoryNum\tstimNum\n');
  
  for cn = 1:length(stimInfoStruct.categoryNames)
    if exist(fullfile(imgStimDir,stimInfoStruct.categoryNames{cn}),'dir')
      catImgs = dir(fullfile(imgStimDir,stimInfoStruct.categoryNames{cn},['*',cfg.files.stimFileExt]));
      if ~isempty(catImgs)
        catImgs = {catImgs.name};
        % remove the file extension
        catImgs = cellfun(@(x) strrep(x,cfg.files.stimFileExt,''), catImgs, 'UniformOutput', false);
        
        for ci = 1:length(catImgs)
          fprintf(fid,'%s%s\t%s\t%d\t%d\n',...
            catImgs{ci},cfg.files.stimFileExt,...
            stimInfoStruct.categoryNames{cn},cn,...
            ci);
        end
      else
        fclose(fid);
        error('No stimuli found in %s with extension %s!',fullfile(imgStimDir,stimInfoStruct.categoryNames{cn}),cfg.files.stimFileExt);
      end
    else
      fclose(fid);
      error('Category directory %s does not exist!',fullfile(imgStimDir,stimInfoStruct.categoryNames{cn}));
    end
  end % for each category
  
  fclose(fid);
  
  fprintf('Done with image stimuli.\n');
else
  error('Image stimuli directory %s does not exist!',imgStimDir);
end

%% word stimuli

fprintf('Creating wordpool stimulus list: %s...',stimInfoStruct.wordpoolListFile);

% for this subject, write out the file containing all word stimuli

% make sure the wordpool directory exists
if exist(wpStimDir,'dir')
  
  % read the wordpool
  if exist(cfg.files.wordpool,'file')
    fid = fopen(cfg.files.wordpool);
    includeWords = textscan(fid,'%s');
    fclose(fid);
  else
    error('No wordpool found at %s!',cfg.files.wordpool);
  end
  
  % read the exclusion list, if any
  if exist(cfg.files.wordpoolExclude,'file')
    fid = fopen(cfg.files.wordpoolExclude);
    excludeWords = textscan(fid,'%s');
    fclose(fid);
  else
    fprintf('No wordpool exclude file found at %s, not excluding any words!\n',cfg.files.wordpoolExclude);
    excludeWords = {};
  end
  
  % exclude any words
  if ~isempty(excludeWords)
    words = includeWords{1}(~ismember(includeWords{1},excludeWords{1}));
  else
    words = includeWords{1};
  end
  
  % exclude words that are longer than we want
  tooLongWords = logical(cell2mat(cellfun(@(x) length(x) > cfg.stim.maxWordLength, words, 'UniformOutput', false)));
  words = words(~tooLongWords);
  
  % write out the list
  fid = fopen(stimInfoStruct.wordpoolListFile,'w');
  fprintf(fid,'word\tstimNum\n');
  
  for wi = 1:length(words)
    fprintf(fid,'%s\t%d\n',...
      words{wi},wi);
  end
  
  fclose(fid);
  
  fprintf('Done with word stimuli.\n');
else
  error('Wordpool directory %s does not exist!',wpStimDir);
end

end

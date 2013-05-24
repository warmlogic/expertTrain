function [cfg] = et_saveStimList(cfg,shuffleSpecies)
% function [cfg] = et_saveStimList(cfg,shuffleSpecies)

if ~exist('shuffleSpecies','var') || isempty(shuffleSpecies)
  shuffleSpecies = true;
end

fprintf('Creating stimulus list: %s...',cfg.stim.file);

if exist(cfg.files.expParamFile,'file')
  error('Experiment parameter file should not exist before stimulus list has been created: %s',cfg.files.expParamFile);
end

% for this subject, write out the file containing all stimuli
fid = fopen(cfg.stim.file,'w');
fprintf(fid,'fileName\tfamilyStr\tfamilyNum\tspeciesStr\tspeciesNum\texemplarName\texemplarNum\tstimNum\n');

for f = 1:length(cfg.stim.familyNames)
  fam = dir(fullfile(cfg.files.stimDir,cfg.stim.familyNames{f},['*',cfg.files.stimFileExt]));
  fam = {fam.name};
  % remove the file extension
  fam = cellfun(@(x) strrep(x,cfg.files.stimFileExt,''), fam, 'UniformOutput', false);
  
  % initialize some counters
  famCount = 0;
  specStart = 1;
  % for saving the full stimulus names in sorted order
  fam_tmp = cell(size(fam));
  % for saving the species string in sorted order
  specStr_tmp = cell(size(fam));
  % for saving the exemplar numbers from fam names in sorted order
  exempNums_tmp = nan(size(fam));
  % for saving the exemplar number
  fam_eNum = zeros(size(fam));
  
  % because there is no leading zero on the exemplar number, put the
  % files in the correct order (whether this is necessary depends on the
  % output of 'dir', which depends on the operating system)
  
  % get all the species letters for this family
  specExempStr = cell(size(fam));
  for i = 1:length(fam)
    % find where in the string the family name occurs
    fnInd = strfind(fam{i},cfg.stim.familyNames{f});
    % only remove the first instance
    specExempStr{i} = fam{i}((fnInd + length(cfg.stim.familyNames{f})):end);
  end
  % remove the exemplar numbers (only keep the characters that are in the
  % alphabet letter range)
  specStr = cellfun(@(x) x(isstrprop(x,'alpha')), specExempStr, 'UniformOutput', false);
  % get the actual exemplar numbers of this species for sorting
  exempNums = str2double(cellfun(@(x) x(isstrprop(x,'digit')), specExempStr, 'UniformOutput', false));
  
  % get the unique species letters for this family
  if ~exist('uniqueSpecStr','var')
    uniqueSpecStr = unique(specStr,'stable');
  else
    uniqueSpecStr = cat(1,uniqueSpecStr,unique(specStr,'stable'));
  end
  
  % put this species in the correct order
  for s = 1:length(uniqueSpecStr(f,:))
    % slice out only this species
    sInd = find(ismember(specStr,uniqueSpecStr(f,s)));
    % save the actual exemplar count
    fam_eNum(sInd) = 1:length(sInd);
    famCount = famCount + length(sInd);
    
    % sort the exemplar numbers for this species
    [~,j] = sort(exempNums(sInd));
    % put them in the "correct" order
    fam_tmp(specStart:famCount) = fam(sInd(j));
    specStr_tmp(specStart:famCount) = specStr(sInd(j));
    exempNums_tmp(specStart:famCount) = exempNums(sInd(j));
    specStart = specStart + length(sInd);
    cfg.stim.nExemplars(f,s) = length(sInd);
  end
  % make sure we're only grabbing real entires
  filled_cells = cell2mat(cellfun(@(x) ~isempty(x), fam_tmp, 'UniformOutput', false));
  fam = fam_tmp(filled_cells);
  specStr = specStr_tmp(filled_cells);
  exempNums = exempNums_tmp(filled_cells);
  fam_eNum = fam_eNum(filled_cells);
  
  if shuffleSpecies
    if ~exist('specNum','var')
      specNum = randperm(length(uniqueSpecStr(f,:)));
    else
      if cfg.stim.yokeSpecies
        % assumes that all families have the same number of species
        if length(uniqueSpecStr(f,:)) == length(uniqueSpecStr(f-1,:))
          if cfg.stim.yokeTogether(f) == cfg.stim.yokeTogether(f-1)
            specNum = cat(1,specNum,specNum(f-1,:));
          else
            specNum = cat(1,specNum,randperm(length(uniqueSpecStr(f,:))));
          end
        else
          error('There are different numbers of species in family %d (%d) and %d (%d), so it is not possible to yoke species numbers across families.',f-1,length(uniqueSpecStr(f-1,:)),f,length(uniqueSpecStr(f,:)));
        end
      else
        specNum = cat(1,specNum,randperm(length(uniqueSpecStr(f,:))));
      end
    end
  else
    if ~exist('specNum','var')
      specNum = 1:length(uniqueSpecStr(f,:));
    else
      specNum = cat(1,specNum,1:length(uniqueSpecStr(f,:)));
    end
  end
  
  % store the indices for later
  if ~isfield(cfg.stim,'specNum') || isempty(cfg.stim.specNum)
    cfg.stim.specNum = specNum(f,:);
  else
    cfg.stim.specNum = cat(1,cfg.stim.specNum,specNum(f,:));
  end
  
  % print the stimulus info to the stimulus list file
  for i = 1:famCount
    %sStr = specStr{i};
    sNum = cfg.stim.specNum(f,ismember(uniqueSpecStr(f,:),specStr{i}));
    fprintf(fid,'%s%s\t%s\t%d\t%s\t%d\t%d\t%d\t%d\n',...
      fam{i},cfg.files.stimFileExt,...
      cfg.stim.familyNames{f},f,...
      specStr{i},sNum,...
      exempNums(i),fam_eNum(i),i);
  end
end % for each family

fclose(fid);

fprintf('Done.\n');

end

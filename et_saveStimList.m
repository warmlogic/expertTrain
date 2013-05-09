function [cfg] = et_saveStimList(cfg,shuffleSpecies)
% function [cfg] = et_saveStimList(cfg,shuffleSpecies)

if ~exist('shuffleSpecies','var') || isempty(shuffleSpecies)
  shuffleSpecies = true;
end

fprintf('Creating stimulus list: %s...',cfg.stim.file);

if exist(cfg.files.expParamFile,'file')
  error('Experiment parameter file should not exist before stimulus list has been created: %s',cfg.files.expParamFile);
end

%%%%%%%%%%%%%
% Family 1
%%%%%%%%%%%%%

fam1 = dir(fullfile(cfg.files.stimDir,cfg.stim.familyNames{1},['*',cfg.files.stimFileExt]));
fam1 = {fam1.name};
fam1Count = 0;
fam1_tmp = cell(size(fam1));
specStart = 1;
% for saving the exemplar number
fam1_eNum = zeros(size(fam1));
% because there is no leading zero on the exemplar number, put the
% files in the correct order (whether this is necessary depends on the
% output of 'dir')

% get all the species letters for this family
specChar = cellfun(@(x) x(2), fam1, 'UniformOutput', false);
% get the unique species letters for this family
fam1_specChar = unique(specChar,'stable');

for s = 1:length(fam1_specChar)
  % slice out only this species
  sInd = ismember(specChar,fam1_specChar(s));
  % save the exemplar number
  fam1_eNum(sInd) = 1:length(find(sInd));
  fam1Species = fam1(sInd);
  fam1Count = fam1Count + length(fam1Species);
  % initialize
  fam1Nums = nan(size(fam1Species));
  % get the actual exemplar numbers for sorting
  for i = 1:length(fam1Species)
    speciesStr = fam1Species{i}(2);
    % do strrep for the fileExt in case a letter matches
    fam1Nums(i) = str2double(strrep(strrep(fam1Species{i}(2:end),speciesStr,''),strrep(cfg.files.stimFileExt,speciesStr,''),''));
  end
  [~,j] = sort(fam1Nums);
  % put them in the "correct" order
  fam1_tmp(specStart:fam1Count) = fam1Species(j);
  specStart = specStart + length(fam1Species);
  cfg.stim.nExemplars(1,s) = length(fam1Species);
end
filled_cells = cell2mat(cellfun(@(x) ~isempty(x), fam1_tmp, 'UniformOutput', false));
fam1 = fam1_tmp(filled_cells);
fam1_eNum = fam1_eNum(filled_cells);

%%%%%%%%%%%%%
% Family 2
%%%%%%%%%%%%%

fam2 = dir(fullfile(cfg.files.stimDir,cfg.stim.familyNames{2},['*',cfg.files.stimFileExt]));
fam2 = {fam2.name};
fam2Count = 0;
fam2_tmp = cell(size(fam2));
specStart = 1;
% for saving the exemplar number
fam2_eNum = zeros(size(fam1));
% because there is no leading zero on the exemplar number, put the
% files in the correct order (whether this is necessary depends on the
% output of 'dir')

% get all the species letters for this family
specChar = cellfun(@(x) x(2), fam2, 'UniformOutput', false);
% get the unique species letters for this family
fam2_specChar = unique(specChar,'stable');

for s = 1:length(fam2_specChar);
  % slice out only this species
  sInd = ismember(specChar,fam2_specChar(s));
  % save the exemplar number
  fam2_eNum(sInd) = 1:length(find(sInd));
  fam2Species = fam2(sInd);
  fam2Count = fam2Count + length(fam2Species);
  % initialize
  fam2Nums = nan(size(fam2Species));
  % get the numbers for sorting
  for i = 1:length(fam2Species)
    speciesStr = fam2Species{i}(2);
    % do strrep for the fileExt in case a letter matches
    fam2Nums(i) = str2double(strrep(strrep(fam2Species{i}(2:end),speciesStr,''),strrep(cfg.files.stimFileExt,speciesStr,''),''));
  end
  [~,j] = sort(fam2Nums);
  % put them in the "correct" order
  fam2_tmp(specStart:fam2Count) = fam2Species(j);
  specStart = specStart + length(fam2Species);
  cfg.stim.nExemplars(2,s) = length(fam2Species);
end
filled_cells = cell2mat(cellfun(@(x) ~isempty(x), fam2_tmp, 'UniformOutput', false));
fam2 = fam2_tmp(filled_cells);
fam2_eNum = fam2_eNum(filled_cells);

% randomize the species number so every subject gets a random species
% assigned to each number
if shuffleSpecies
  fam1_specNumInd = randperm(length(fam1_specChar));
  fam2_specNumInd = randperm(length(fam2_specChar));
else
  fam1_specNumInd = 1:length(fam1_specChar);
  fam2_specNumInd = 1:length(fam2_specChar);
end
% store the indices for later
cfg.stim.specNumInd = nan(cfg.stim.nFamilies,cfg.stim.nSpecies);
cfg.stim.specNumInd(1,:) = fam1_specNumInd;
cfg.stim.specNumInd(2,:) = fam2_specNumInd;
%cfg.stim.fam1_specNumInd = fam1_specNumInd;
%cfg.stim.fam2_specNumInd = fam2_specNumInd;

% for this subject, write out the file containing all stimuli
fid = fopen(cfg.stim.file,'w');
fprintf(fid,'Filename\tFamilyStr\tFamilyNum\tSpeciesStr\tSpeciesNum\tExemplarName\tExemplarNum\tNumber\n');

for i = 1:fam1Count
  fStr = fam1{i}(1);
  fNum = find(ismember(cfg.stim.familyNames,fStr));
  sStr = fam1{i}(2);
  sNum = cfg.stim.specNumInd(fNum,ismember(fam1_specChar,sStr));
  [~,name] = fileparts(fam1{i});
  eName = str2double(strrep(name,[fStr sStr],''));
  fprintf(fid,'%s\t%s\t%d\t%s\t%d\t%d\t%d\t%d\n',fam1{i},fStr,fNum,sStr,sNum,eName,fam1_eNum(i),i);
end

for i = 1:fam2Count
  fStr = fam2{i}(1);
  fNum = find(ismember(cfg.stim.familyNames,fStr));
  sStr = fam2{i}(2);
  sNum = cfg.stim.specNumInd(fNum,ismember(fam2_specChar,sStr));
  [~,name] = fileparts(fam2{i});
  eName = str2double(strrep(name,[fStr sStr],''));
  fprintf(fid,'%s\t%s\t%d\t%s\t%d\t%d\t%d\t%d\n',fam2{i},fStr,fNum,sStr,sNum,eName,fam2_eNum(i),i);
end

fclose(fid);

fprintf('Done.\n');

end

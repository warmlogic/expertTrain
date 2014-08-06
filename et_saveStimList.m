function [cfg] = et_saveStimList(cfg,stimDir,stimInfoStruct,shuffleSpecies,manualSpeciesNums)
% function [cfg] = et_saveStimList(cfg,stimDir,stimInfoStruct,shuffleSpecies,manualSpeciesNums)

if nargin < 5
  manualSpeciesNums = [];
  if nargin < 4
    warning('Default setting: Shuffling species numbers!');
    shuffleSpecies = true;
    if nargin < 3
      error('Not enough input arguments!');
    end
  end
end

if isempty(shuffleSpecies)
  warning('Default setting: Shuffling species numbers!');
  shuffleSpecies = true;
end

if shuffleSpecies && ~isempty(manualSpeciesNums)
  error('Cannot shuffle species numbers and define manual species numbers');
end

if ~isfield(stimInfoStruct,'yokeSpecies') || isempty(stimInfoStruct.yokeSpecies)
  stimInfoStruct.yokeSpecies = false;
end

% initialize to store the number of exemplars for each species
stimInfoStruct.nExemplars = zeros(length(stimInfoStruct.familyNames),stimInfoStruct.nSpecies);

fprintf('Creating stimulus list: %s...',stimInfoStruct.stimListFile);

if exist(cfg.files.expParamFile,'file')
  error('Experiment parameter file should not exist before stimulus list has been created: %s',cfg.files.expParamFile);
end

% for this subject, write out the file containing all stimuli
fid = fopen(stimInfoStruct.stimListFile,'w');
fprintf(fid,'fileName\tfamilyStr\tfamilyNum\tspeciesStr\tspeciesNum\texemplarName\texemplarNum\tstimNum\n');

for f = 1:length(stimInfoStruct.familyNames)
  if exist(fullfile(stimDir,stimInfoStruct.familyNames{f}),'dir')
    fam = dir(fullfile(stimDir,stimInfoStruct.familyNames{f},['*',cfg.files.stimFileExt]));
    if ~isempty(fam)
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
        fnInd = strfind(fam{i},stimInfoStruct.familyNames{f});
        % only remove the first instance
        specExempStr{i} = fam{i}((fnInd + length(stimInfoStruct.familyNames{f})):end);
      end
      % remove the exemplar numbers (only keep the characters that are in the
      % alphabet letter range)
      specStr = cellfun(@(x) x(~isstrprop(x,'digit')), specExempStr, 'UniformOutput', false);
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
        stimInfoStruct.nExemplars(f,s) = length(sInd);
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
          if stimInfoStruct.yokeSpecies
            % assumes that all families have the same number of species
            if length(uniqueSpecStr(f,:)) == length(uniqueSpecStr(f-1,:))
              if stimInfoStruct.yokeTogether(f) == stimInfoStruct.yokeTogether(f-1)
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
          if ~isempty(manualSpeciesNums)
            specNum = manualSpeciesNums;
          else
            specNum = 1:length(uniqueSpecStr(f,:));
          end
        else
          if ~isempty(manualSpeciesNums)
            specNum = cat(1,specNum,manualSpeciesNums);
          else
            specNum = cat(1,specNum,1:length(uniqueSpecStr(f,:)));
          end
        end
      end
      
      % store the indices for later
      if ~isfield(stimInfoStruct,'specNum') || isempty(stimInfoStruct.specNum)
        stimInfoStruct.specNum = specNum(f,:);
      else
        stimInfoStruct.specNum = cat(1,stimInfoStruct.specNum,specNum(f,:));
      end
      
      % print the stimulus info to the stimulus list file
      for i = 1:famCount
        %sStr = specStr{i};
        sNum = stimInfoStruct.specNum(f,ismember(uniqueSpecStr(f,:),specStr{i}));
        fprintf(fid,'%s%s\t%s\t%d\t%s\t%d\t%d\t%d\t%d\n',...
          fam{i},cfg.files.stimFileExt,...
          stimInfoStruct.familyNames{f},f,...
          specStr{i},sNum,...
          exempNums(i),fam_eNum(i),i);
      end
    else
      fclose(fid);
      error('No stimuli found in %s with extension %s!',fullfile(stimDir,stimInfoStruct.familyNames{f}),cfg.files.stimFileExt);
    end
  else
    fclose(fid);
    error('Family directory %s does not exist!',fullfile(stimDir,stimInfoStruct.familyNames{f}));
  end
end % for each family

fclose(fid);

fprintf('Done.\n');

end

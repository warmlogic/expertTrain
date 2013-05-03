function et_saveStimList(cfg)

fprintf('Creating stimulus list: %s...',cfg.stim.file);

alphabet = ('a':'z');

fam1 = dir(fullfile(cfg.files.stimDir,cfg.stim.familyNames{1},['*',cfg.files.stimFileExt]));
fam1 = {fam1.name};
% because there is no leading zero on the exemplar number, put the
% files in the correct order (whether this is necessary depends on the
% output of 'dir')
fam1Count = 0;
for s = 1:cfg.stim.nSpecies
  % slice out only this species
  sInd = (((s*cfg.stim.nExemplars)+1)-cfg.stim.nExemplars:s*cfg.stim.nExemplars);
  fam1Species = fam1(sInd);
  fam1Count = fam1Count + length(fam1Species);
  % initialize
  fam1Nums = nan(size(fam1Species));
  % get the numbers for sorting
  for i = 1:length(fam1Species)
    speciesStr = fam1Species{i}(2);
    % do strrep for the fileExt in case a letter matches
    fam1Nums(i) = str2double(strrep(strrep(fam1Species{i}(2:end),speciesStr,''),strrep(cfg.files.stimFileExt,speciesStr,''),''));
  end
  [~,j] = sort(fam1Nums);
  % put them in the "correct" order
  fam1(sInd) = fam1Species(j);
end

fam2 = dir(fullfile(cfg.files.stimDir,cfg.stim.familyNames{2},['*',cfg.files.stimFileExt]));
fam2 = {fam2.name};
fam2Count = 0;
% because there is no leading zero on the exemplar number, put the
% files in the correct order (whether this is necessary depends on the
% output of 'dir')
for s = 1:cfg.stim.nSpecies
  % slice out only this species
  sInd = (((s*cfg.stim.nExemplars)+1)-cfg.stim.nExemplars:s*cfg.stim.nExemplars);
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
  fam2(sInd) = fam2Species(j);
end

% write out the file containing all stimuli
fid = fopen(fullfile(cfg.files.stimDir,'stimList.txt'),'w');
fprintf(fid,'Filename\tFamilyStr\tFamilyNum\tSpeciesStr\tSpeciesNum\tExemplar\tNumber\n');

fNum = 1;
fStr = fam1{1}(1);
for i = 1:fam1Count
  sStr = fam1{i}(2);
  sNum = strfind(alphabet,sStr);
  [~,name] = fileparts(fam1{i});
  eNum = str2double(strrep(name,[fStr sStr],''));
  fprintf(fid,'%s\t%s\t%d\t%s\t%d\t%d\t%d\n',fam1{i},fStr,fNum,sStr,sNum,eNum,i);
end

fNum = 2;
fStr = fam2{1}(1);
for i = 1:fam2Count
  sStr = fam2{i}(2);
  sNum = strfind(alphabet,sStr);
  [~,name] = fileparts(fam2{i});
  eNum = str2double(strrep(name,[fStr sStr],''));
  fprintf(fid,'%s\t%s\t%d\t%s\t%d\t%d\t%d\n',fam2{i},fStr,fNum,sStr,sNum,eNum,i);
end

fclose(fid);

fprintf('Done.\n');

end

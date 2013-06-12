
%% set up files

centeredDims = [450 450];

% the gray color to add in the background of the image. can be empty [] to
% use most common background color in original image.
bgColor = 210;

% type of mask to use.
%
% 'manual' expects to find a file in a FAMILY_mask dir
processMask = 'manual';
% % the threshold used by makeMask.m
% processMask = 0.7;

cropImage = false;

plotSteps = false;

familyName = 'Finch_';
% familyName = 'Warbler_';
imgDir = '~/Documents/experiments/expertTrain/images/Birds';
% imgDir = '~/Downloads/croppedbirds/Birds';
familyDir = fullfile(imgDir,familyName);
if exist(familyDir,'dir')
  files = dir(fullfile(familyDir,'*.bmp'));
  files = {files.name};
  if isempty(files)
    error('No files found in %s.',familyDir);
  end
else
  error('Family directory %s not found.',familyDir);
end
if ischar(processMask) && strcmp(processMask,'manual')
  maskDir = fullfile(imgDir,sprintf('%smask',familyName));
  if ~exist(maskDir,'dir')
    error('Mask directory %s not found.',maskDir);
  end
end

% image manipulations to translate in the same way (cropImage = false; is
% required)
% manipulations = {};
manipulations = {{familyName}, {'g', 'g_hi8', 'g_lo8', 'inverta', 'swap', 'invertb', 'invertab', 'swapinverta', 'swapinvertb', 'swapinvertab'}};

outputDir = strcat(familyDir,'cent');
if ~exist(outputDir,'dir')
  mkdir(outputDir);
end

%% loop through files
for i = 1:length(files)
  [~,current_file,ext] = fileparts(files{i});
  imageFile = fullfile(familyDir,strcat(current_file,ext));
  
  if ischar(processMask) && strcmp(processMask,'manual')
    fprintf('processing %s with a manual mask...\n',files{i});
    maskInfo = fullfile(maskDir,strcat(current_file,'_mask',ext));
  elseif isnumeric(processMask)
    fprintf('processing %s with an internally generated mask (using makeMask.m)...\n',files{i});
    maskInfo = processMask;
  else
    fprintf('processing %s without a mask...\n',files{i});
    maskInfo = [];
  end
  
  [centeredImage,manipulatedImages] = centerImageOnCentroid(imageFile,maskInfo,centeredDims,bgColor,cropImage,plotSteps,manipulations);
  
  fNameInd = strfind(current_file,familyName);
  speciesNameExemplarNum = current_file((fNameInd(1)+length(familyName)):end);
  speciesName = speciesNameExemplarNum(~isstrprop(speciesNameExemplarNum,'digit'));
  exemplarNumStr = speciesNameExemplarNum(isstrprop(speciesNameExemplarNum,'digit'));
  
  outputFile = fullfile(outputDir,strcat(familyName,'cent_',speciesName,exemplarNumStr,ext));
  imwrite(centeredImage,outputFile);
  
  if ~isempty(manipulations)
    for m = 1:length(manipulations{2})
      manip_outputDir = strcat(familyDir,manipulations{2}{m},'_cent');
      if ~exist(manip_outputDir,'dir')
        mkdir(manip_outputDir);
      end

      manip_outputFile = fullfile(manip_outputDir,sprintf('%s%s_cent_%s%s%s',familyName,manipulations{2}{m},speciesName,exemplarNumStr,ext));
      imwrite(manipulatedImages{m},manip_outputFile);
    end

  end
  
end

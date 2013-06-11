function manip_image_colors(swap_flag,invert_flag,manualMask,save_gray)
% function manip_image_colors(swap_flag,invert_flag,manualMask,save_gray)
%
% swap_flag:   to swap colors (1 or 0) (default: 0)
% invert_flag: to invert colors
%              (0 = no inversion, 1 = invert a*, 2 = invert b*, 3 = invert
%              a* and b*) (default: 0)
% manualMask:  look for a manually created mask file (default: false)
% save_gray:   whether to save the grayscale and inverted gray (default:
%              false)
%
% NB: requires functions makeMask.m and modifyLab.m
%
% see also: MAKEMASK, MODIFYLAB

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make grayscale and inverted versions of colour images
% 10/12/11, qcv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% do all manips:
% manip_image_colors(1,0,true,false);manip_image_colors(0,1,true,false);manip_image_colors(0,2,true,false);manip_image_colors(0,3,true,false);manip_image_colors(1,1,true,false);manip_image_colors(1,2,true,false);manip_image_colors(1,3,true,false);

if ~exist('swap_flag','var') || isempty(swap_flag)
  swap_flag = 0;
end
if ~exist('invert_flag','var') || isempty(invert_flag)
  invert_flag = 0;
end
if ~exist('manualMask','var') || isempty(manualMask)
  manualMask = false;
end
if ~exist('save_gray','var') || isempty(save_gray)
  save_gray = false;
end

close all

% colour conversion structures:
C2lab = makecform('srgb2lab');
C2rgb = makecform('lab2srgb');

% set background gray level:
val = 210;

familyName = 'Finch_';
% familyName = 'Warbler_';
% imgDir = '~/Documents/experiments/expertTrain/images/Birds';
imgDir = '~/Downloads/croppedbirds/Birds';
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

if manualMask
  maskDir = fullfile(imgDir,sprintf('%smask',familyName));
  if ~exist(maskDir,'dir')
    error('Mask directory %s not found.',maskDir);
  end
  thresh = nan;
else
  thresh = repmat(0.7,size(files));
end

% loop through files
for i = 1:length(files)
  if ~manualMask
    fprintf('processing %s at threshold = %.2f...\n',files{i},thresh(i));
  else
    fprintf('processing %s with a manual mask...\n',files{i});
  end
  
  % read in image:
  [~,current_file,ext] = fileparts(files{i});
  im_rgb = imread(fullfile(familyDir,strcat(current_file,ext)));
  
  % get filename parts
  fNameInd = strfind(current_file,familyName);
  speciesNameExemplarNum = current_file((fNameInd(1)+length(familyName)):end);
  speciesName = speciesNameExemplarNum(~isstrprop(speciesNameExemplarNum,'digit'));
  exemplarNumStr = speciesNameExemplarNum(isstrprop(speciesNameExemplarNum,'digit'));
  
  % make background:
  graybackground = (val/255)*(ones(size(im_rgb)));
  
  % get mask data
  if manualMask
    % read in mask file
    msk = double(rgb2gray(imread(fullfile(maskDir,strcat(current_file,'_mask',ext)))));
    msk = makeMask(manualMask,msk,thresh,0);
  else
    % convert temporarily to grayscale for thresholding:
    im_gray = rgb2gray(im_rgb);
    % make the mask
    msk = makeMask(manualMask,im_gray,thresh(i),0);
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % process colour (rgb)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % invert colour in L*a*b*:
  % new flag to show histogram:
  hist_flag = 0;      % to show luminance hist in Lab space (1 or 0)
  %swap_flag = 0;      % to swap (1 or 0)
  %invert_flag = 0;    % to invert (0 = no inversion, 1 = invert a*, 2 = invert b*, 3 = invert a* and b*)
  imd = double(im_rgb);
  rgb_img = imd./255;
  [rgb_img,LL,imr] = modifyLab(rgb_img,swap_flag,invert_flag,C2lab,C2rgb,hist_flag);
  
  % reset inverted background:
  rgb_img = msk.*rgb_img + (1-msk).*graybackground;
  
  % filename
  swap_nm = '';
  invert_nm = '';
  if swap_flag==1, swap_nm = 'swap'; end
  if invert_flag==1, invert_nm = 'inverta'; end
  if invert_flag==2, invert_nm = 'invertb'; end
  if invert_flag==3, invert_nm = 'invertab'; end
  
  if swap_flag || invert_flag
    % save inverted rgb to file:
    outputDir = fullfile(imgDir,sprintf('%s%s%s',familyName,swap_nm,invert_nm));
    % make sure output directory exists
    if ~exist(outputDir,'dir')
      mkdir(outputDir);
    end
    
    outfilename = fullfile(outputDir,sprintf('%s%s%s%s%s%s',familyName,swap_nm,invert_nm,speciesName,exemplarNumStr,ext));
    %outfilename = sprintf('%s_%s%s.bmp',current_file,swap_nm,invert_nm);
    
    imwrite(rgb_img,outfilename);
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % process grey
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if save_gray
    % save luminance-only image to file:
    outputDir = fullfile(imgDir,sprintf('%sg%s%s',familyName,swap_nm,invert_nm));
    % make sure output directory exists
    if ~exist(outputDir,'dir')
      mkdir(outputDir);
    end
    
    % save luminance-only image to file:
    outfilename = fullfile(outputDir,sprintf('%sg%s%s%s%s%s',familyName,swap_nm,invert_nm,speciesName,exemplarNumStr,ext));
    %outfilename = sprintf('%s_gray.bmp',current_file);
    imwrite(LL,outfilename);
    
    % reset background:
    imr = msk.*imr + (1-msk).*graybackground;
    
    % save inverted rgb to file:
    outputDir = fullfile(imgDir,sprintf('%sgRev%s%s',familyName,swap_nm,invert_nm));
    % make sure output directory exists
    if ~exist(outputDir,'dir')
      mkdir(outputDir);
    end
    
    % save inverted rgb to file:
    outfilename = fullfile(outputDir,sprintf('%sgRev%s%s%s%s%s',familyName,swap_nm,invert_nm,speciesName,exemplarNumStr,ext));
    %outfilename = sprintf('%s_greyreversed.bmp',current_file);
    imwrite(imr,outfilename);
  end
  
end

fprintf('Done.\n');  

figure(1);
imshow(rgb_img);
title(sprintf('normal%s%s',swap_nm,invert_nm));
figure(2);
imshow(msk);
title('mask');
figure(3);
imshow(LL);
title('gray');
figure(4);
imshow(imr);
title('gray reversed');

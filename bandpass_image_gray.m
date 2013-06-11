function bandpass_image_gray(freq,low_pass,manualMask,plot_flag,show_image)
%function bandpass_image_gray(freq,low_pass,plot_flag,show_image)
%
% freq:       freq band-pass range (e.g., [0 8]), or cutoff frequency for
%             low- or high-pass (e.g., [8]) (default: 8)
% low_pass:   1 = lowpass, 0 = highpass, -1 = grayscale. Only applies when
%             variable 'freq' has a single value (default: 1)
% manualMask: look for a manually created mask file (default: false)
% plot_flag:  true/false, if you want to see some plots (default: false)
% show_image: true/false, if you want to see the blurred image (default: false)
%
% NB: requires functions makeMask.m and fft_filter.m
%
% see also: MAKEMASK, FFT_FILTER

% bandpass_image_gray(8,1,true,false,false);bandpass_image_gray(8,0,true,false,false);

if ~exist('freq','var')
  freq = 8;
end
if ~exist('low_pass','var')
  low_pass = 1;
end
if ~exist('manualMask','var') || isempty(manualMask)
  manualMask = false;
end
if ~exist('plot_flag','var') || isempty(plot_flag)
  plot_flag = false;
end
if ~exist('show_image','var') || isempty(show_image)
  show_image = false;
end

close all

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

for i = 1:length(files)
  fprintf('processing %s...\n',files{i});
  
  % get filename
  [~,current_file,ext] = fileparts(files{i});
  im_rgb = imread(fullfile(familyDir,strcat(current_file,ext)));
  im_gray = rgb2gray(im_rgb); % convert to grayscale
  %mim = mean(im_gray(:)); % get mean intensity
  
  % get filename parts
  fNameInd = strfind(current_file,familyName);
  speciesNameExemplarNum = current_file((fNameInd(1)+length(familyName)):end);
  speciesName = speciesNameExemplarNum(~isstrprop(speciesNameExemplarNum,'digit'));
  exemplarNumStr = speciesNameExemplarNum(isstrprop(speciesNameExemplarNum,'digit'));
  
  % make background
  graybackground = val*(ones(size(im_gray)));
  
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
  msk = msk(:,:,1);
  
  % get output filename
  if length(freq) == 1
    if low_pass == 1
      filtStr = 'lo';
    elseif low_pass == 0
      filtStr = 'hi';
    end
  elseif length(freq) == 2
    filtStr = 'bp';
  end
  
  % set output directory and filename
  if length(freq) == 1 && low_pass ~= -1
    if low_pass == 1 || low_pass == 0
      outputDir = fullfile(imgDir,sprintf('%sg_%s%i',familyName,filtStr,freq));
      outputFile = fullfile(outputDir,sprintf('%sg_%s%i_%s%s%s',familyName,filtStr,freq,speciesName,exemplarNumStr,ext));
    end
  elseif length(freq) == 2 && low_pass ~= -1
    outputDir = fullfile(imgDir,sprintf('%sg_%s%i_%i',familyName,filtStr,freq(1),freq(2)));
    outputFile = fullfile(outputDir,sprintf('%sg_%s%i_%i_%s%s%s',familyName,filtStr,freq(1),freq(2),speciesName,exemplarNumStr,ext));
  elseif low_pass == -1
    outputDir = fullfile(imgDir,sprintf('%sg',familyName));
    outputFile = fullfile(outputDir,sprintf('%sg_%s%s%s',familyName,speciesName,exemplarNumStr,ext));
  end
  
  % make sure output directory exists
  if ~exist(outputDir,'dir')
    mkdir(outputDir);
  end
  
  % filter
  if low_pass == 1
    [im_gray,HSF] = fft_filter(im_gray,freq,plot_flag);
  elseif low_pass == 0
    [LSF,im_gray] = fft_filter(im_gray,freq,plot_flag);
  elseif low_pass == -1
    im_gray = double(im_gray);
  end
  
  % reset background
  im_gray = msk.*im_gray + (1-msk).*graybackground;
  
  if show_image
    figure
    imshow(im_gray./255);
  end
  
  % write the image to file
  imwrite(im_gray./255,outputFile);
end

fprintf('Done.\n');  

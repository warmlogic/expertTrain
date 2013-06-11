function [centeredImage] = centerImageOnCentroid(image_file,mask_file,centeredDims,bgColor)
% function [centeredImage] = centerImageOnCentroid(image_file,mask_file,centeredDims,bgColor)
%
% Description:
%  Centers images on the centroid (center of mass). Expects images with
%  cropped-out objects on uniform backgrounds.
%
% Input:
%  image_file: string to an image file
%  mask_file:  string to a black-background white-object mask file;
%              optional.
%  centeredDims: [x y] dimensions of the output image; optional. Default:
%                the same size as the input image.
%  bgColor:      single scalar digit reperesenting the background color
%                (e.g., 210 for gray). optional. Default: the most common
%                color outside of the identified object.
%
% Output:
%  centeredImage: the image, centered on the centroid
%
% NB: uses the function imtranslate(), from the MATLAB File Exchange:
%     http://www.mathworks.com/matlabcentral/fileexchange/27251-imtranslate
%
% See also: IMTRANSLATE
%


% image_file = '~/Desktop/birds/Original_340.bmp';
% mask_file = '';

% % left bottom - good
% image_file = '~/Desktop/birds/Finch_BlackRosy_7.bmp';
% % read the mask, bird is white, background is black
% mask_file = '~/Desktop/birds/Finch_BlackRosy_7_mask.bmp';

% % left top - good
% image_file = '~/Desktop/birds/Finch_BlackRosy_7_up.bmp';
% % read the mask, bird is white, background is black
% mask_file = '~/Desktop/birds/Finch_BlackRosy_7_up_mask.bmp';

% right bottom - good
% image_file = '~/Desktop/birds/Finch_BlackRosy_10.bmp';
% % read the mask, bird is white, background is black
% mask_file = '~/Desktop/birds/Finch_BlackRosy_10_mask.bmp';

% % right top - good
% image_file = '~/Desktop/birds/Finch_BlackRosy_10_up.bmp';
% % read the mask, bird is white, background is black
% mask_file = '~/Desktop/birds/Finch_BlackRosy_10_up_mask.bmp';

% % right top - good
% image_file = '~/Desktop/birds/Warbler_BlackThroatedGreen_10.bmp';
% % read the mask, bird is white, background is black
% mask_file = '~/Desktop/birds/Warbler_BlackThroatedGreen_10_mask.bmp';

if ~exist('mask_file','var') || isempty(mask_file)
  mask_file = [];
end

if exist(image_file,'file')
  im = imread(image_file);
else
  error('image file %s does not exist',image_file);
end

if ~isempty(mask_file)
  if exist(mask_file,'file')
    processMask = true;
    im_mask = imread(mask_file);
  else
    error('mask file %s does not exist',mask_file);
  end
else
  processMask = false;
end

if processMask
  if size(im,1) ~= size(im_mask,1) || size(im,2) ~= size(im_mask,2)
    error('image and mask are not the same size');
  end
end

if ~exist('centeredDims','var') || isempty(centeredDims)
  out_x = size(im,1);
  out_y = size(im,2);
else
  out_x = centeredDims(1);
  out_y = centeredDims(2);
end
% out_xy = [out_x out_y];

if processMask
  % convert to gray scale
  im_gray = rgb2gray(im_mask);
  
  % % Bright objects will be the chosen if you use >.
  im_bw = im_gray > 100;
else
  % convert to gray scale
  im_gray = rgb2gray(im);
  % Dark objects will be the chosen if you use <.
  im_bw = im_gray < 100;
end
% figure;
% imshow(im_bw);
% title('bw');

% Do a "hole fill" to get rid of any background pixels.
im_bw = imfill(im_bw, 'holes');
% figure;
% imshow(im_bw);
% title('bw holes');

if processMask
  L = logical(im_bw);
else
  % Label the disconnected foreground regions (using 8 conned neighbourhood)
  L = bwlabel(im_bw, 8);
end

% get the most common gray background value
if ~exist('bgColor','var') || isempty(bgColor)
  bgColor = mode(double(im(repmat(L,[1,1,3]) == 0)));
end

if ~processMask
  % only get the first object
  L(L ~= 1) = 0;
end

% Get the bounding box around each object
bb = regionprops(L, 'BoundingBox');
bbs = cat(1, bb.BoundingBox);

% trim the image to the bounding box
im_bb = im(floor(bbs(2)):(bbs(4)+ceil(bbs(2))),floor(bbs(1)):(bbs(3)+ceil(bbs(1))),:);
% im_bw_bb = im_bw(floor(bbs(2)):(bbs(4)+ceil(bbs(2))),floor(bbs(1)):(bbs(3)+ceil(bbs(1))),:);
L_bb = L(floor(bbs(2)):(bbs(4)+ceil(bbs(2))),floor(bbs(1)):(bbs(3)+ceil(bbs(1))),:);

% figure
% imshow(im_bb);
% title('color bounding box');
% % figure
% % imshow(im_bw_bb);
% % title('bw bounding box');
% figure
% imshow(L_bb);
% title('L bounding box');

% % convert to gray scale
% im_gray = rgb2gray(im_bb);
% % % Bright objects will be the chosen if you use >.
% im_bw = im_gray > 100;
% % Dark objects will be the chosen if you use <.
% % im_bw = im_gray < 100;
% % Do a "hole fill" to get rid of any background pixels inside the blobs.
% im_bw = imfill(im_bw, 'holes');
% % figure;
% % imshow(im_bw);
% 
% % % Label the disconnected foreground regions (using 8 conned neighbourhood)
% % L = bwlabel(im_bw, 8);
% L = logical(im_bw);
% 
% % % only get the first object
% % L(L ~= 1) = 0;

% calculate the centroid
stat = regionprops(L_bb, 'Centroid');
centroids = round(cat(1, stat.Centroid));
figure
imshow(im_bb);
hold on
plot(centroids(:,1), centroids(:,2), 'r*');
hold off
title('centroid');

%% grow around the centroid so it is in the middle

cent_x = centroids(1);
cent_y = centroids(2);

% cropped image dimensions
im_bb_x = size(im_bb,2);
im_bb_y = size(im_bb,1);

if cent_x < (im_bb_x / 2)
  leftCentroid = true;
  centerXCentroid = false;
elseif cent_x > (im_bb_x / 2)
  leftCentroid = false;
  centerXCentroid = false;
else
  centerXCentroid = true;
end

if cent_y < (im_bb_y / 2)
  topCentroid = true;
  centerYCentroid = false;
elseif cent_y > (im_bb_y / 2)
  topCentroid = false;
  centerYCentroid = false;
else
  centerYCentroid = true;
end

if ~centerXCentroid
  if leftCentroid
    % expand to the left
    add_x = (im_bb_x - cent_x) - cent_x;
    
    % if it's going to be bigger than the background layer, add less
    if im_bb_x + add_x > out_x
     add_x = out_x - im_bb_x;
    end
    
    if im_bb_x + add_x < out_x
      trans2_x = (out_x - (im_bb_x + add_x)) / 2;
    else
      trans2_x = 0;
    end
  elseif ~leftCentroid
    % expand to the right
    add_x = cent_x - (im_bb_x - cent_x);
    
    % if it's going to be bigger than the background layer, add less
    if im_bb_x + add_x > out_x
     add_x = out_x - im_bb_x;
    end
    
    if im_bb_x + add_x < out_x
      trans2_x = (out_x - (im_bb_x + add_x)) / 2;
    else
      trans2_x = 0;
    end
  end
end

if ~centerYCentroid
  if topCentroid
    % expand to the top
    add_y = (im_bb_y - cent_y) - cent_y;
    
    % if it's going to be bigger than the background layer, add less
    if im_bb_y + add_y > out_y
     add_y = out_y - im_bb_y;
    end
    
    if im_bb_y + add_y < out_y
      trans2_y = (out_y - (im_bb_y + add_y)) / 2;
    else
      trans2_y = 0;
    end
  elseif ~topCentroid
    % expand to the bottom
    add_y = cent_y - (im_bb_y - cent_y);
    
    % if it's going to be bigger than the background layer, add less
    if im_bb_y + add_y > out_y
     add_y = out_y - im_bb_y;
    end
    
    if im_bb_y + add_y < out_y
      trans2_y = (out_y - (im_bb_y + add_y)) / 2;
    else
      trans2_y = 0;
    end
  end
end

%% do the translation

if ~centerXCentroid
  trans1_x = add_x;
else
  trans1_x = 0;
end
if ~centerYCentroid
  trans1_y = add_y;
else
  trans1_y = 0;
end

im_bb_t = imtranslate(im_bb,[trans1_y, trans1_x, 0],bgColor,'linear',0);
%figure
%imshow(im_bb_t);
%title('1');

if ~leftCentroid
  im_bb_t = imtranslate(im_bb_t,[0, -trans1_x, 0],bgColor,'linear',1);
  %figure
  %imshow(im_bb_t);
  %title('1 right');
end

if ~topCentroid
  im_bb_t = imtranslate(im_bb_t,[-trans1_y, 0, 0],bgColor,'linear',1);
  %figure
  %imshow(im_bb_t);
  %title('1 bottom');
end

if trans2_x > 0 || trans2_y > 0
  im_bb_t2 = imtranslate(im_bb_t,[trans2_y, trans2_x, 0],bgColor,'linear',0);
  %figure
  %imshow(im_bb_t2);
  %title('2');
  im_bb_t3 = imtranslate(im_bb_t2,[-trans2_y, trans2_x, 0],bgColor,'linear',0);
  %figure
  %imshow(im_bb_t3);
  %title('3');
  centeredImage = imtranslate(im_bb_t3,[trans2_y, -trans2_x, 0],bgColor,'linear',1);
  %figure
  %imshow(centeredImage);
  %title('4');
  %hold on
  %plot(225, 225, 'r*');
  %hold off
end

% 
% bg_rect = uint8(cat(3, repmat(bgColor,newim_xy), repmat(bgColor,newim_xy), repmat(bgColor,newim_xy)));
% hold on
% imshow(bg_rect);
% hold off
% 
% 
% input_points = [cent_x, cent_y; (cent_x + 1), (cent_y + 1)];
% base_points = [(newim_x/2), (newim_y/2); ((newim_x/2) + 1), ((newim_y/2) + 1)];
% 
% cpselect(bg_rect,im_bw,input_points,base_points);
% 
% tform = cp2tform(input_points,base_points,'nonreflective similarity');
% 
% 
% 
% % Crop the individual objects and store them in a cell
% siz = size(im_bw); % image dimensions
% n=max(L(:)); % number of objects
% ObjCell=cell(n,1);
% for i=1:n
%   % Get the bb of the i-th object and offest by 2 pixels in all
%   % directions
%   bb_i=ceil(bb(i).BoundingBox);
%   idx_x=[bb_i(1)-2 bb_i(1)+bb_i(3)+2];
%   idx_y=[bb_i(2)-2 bb_i(2)+bb_i(4)+2];
%   if idx_x(1)<1, idx_x(1)=1; end
%   if idx_y(1)<1, idx_y(1)=1; end
%   if idx_x(2)>siz(2), idx_x(2)=siz(2); end
%   if idx_y(2)>siz(1), idx_y(2)=siz(1); end
%   % Crop the object and write to ObjCell
%   im_bw = L == i;
%   ObjCell{i}=im(idx_y(1):idx_y(2),idx_x(1):idx_x(2));
% end
% 
% % Visualize the individual objects
% figure
% for i=1:n
%   subplot(1,n,i)
%   imshow(ObjCell{i})
% end

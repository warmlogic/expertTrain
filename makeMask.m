function msk = makeMask(manualMask,im,thresh,showflag)

% im = grayscale image
% thresh = threshold value, typically greater than the uniform background
% showflag = show mask, 1 = yes, 0 = no, for debugging
%

if ~manualMask
  msk = double(bwmorph(imfill(1-im2bw(im,thresh),8,'holes'),'majority'));
else
  msk = im;
end

% % shave off a few pixels:
msk = double(bwmorph(msk,'erode'));

% blur edge:
f = [ 0.25 0.5 0.25; 
       0.5 1.0  0.5;
     0.25  0.5 0.25   ];
f = f./sum(f(:)); 
msk = imfilter(msk,f); 
 
% make into 3d:
msk = repmat(msk,[1 1 3]);

if showflag
    figure;
    imshow(msk,[]);
end





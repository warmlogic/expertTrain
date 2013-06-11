function [LSF,HSF] = fft_filter(im,fc,plotflag)

% im = grayscale im
% fc = cutoff frequency, in pixels
%      if 1 value, then does lo/hi-pass
%      if 2 values e.g., [8 16], then does band-pass
% plotflag: 0 = no figure; 1 = figure

% normalize image to mean
im = double(im);
mim = mean(im(:));
im = im - mim;

[n1,n2] = size(im);

% Define frequency coordinate matrices:
[fx,fy] = meshgrid(0:n2-1,0:n1-1);
fx = fx - (n2-1)/2;
fy = fy - (n1-1)/2;

% Scale the filter frequencies (sic):
s = fc/sqrt(log(2));

% Define Gaussian fitlers:
nfcs = max(size(fc));
if nfcs==1  % low/high-pass
    gf1 = exp(-(fx.^2+fy.^2)/(s^2));		% Low-pass.
    gf2 = 1-gf1;                            % High-pass.
else        % band-pass
    gf1i = exp(-(fx.^2+fy.^2)/(s(1)^2));
    gf1o = exp(-(fx.^2+fy.^2)/(s(2)^2));
    gf1 = gf1o - gf1i;                      % Low-pass.
    gf2 = 1 - gf1;                          % High-pass.
end

% Do filtering in k-space:
Ilf = real(ifftn(fftshift(fftshift(fftn(im)).*gf1)));
Ihf = real(ifftn(fftshift(fftshift(fftn(im)).*gf2)));

% Scale images to the range [0, 255]:
LSF = Ilf + mim; %(Ilf-min(Ilf(:)))/(max(Ilf(:))-min(Ilf(:)))*255;
HSF = Ihf + mim; %(Ihf-min(Ihf(:)))/(max(Ihf(:))-min(Ihf(:)))*255;

% Display images:
if plotflag==1
    figure;
    HSF(HSF>255) = 255;
    subplot(2,2,1); imshow(LSF./255); title(sprintf('mean = %.0f, min = %.0f, max = %.0f',mean(LSF(:)),min(LSF(:)),max(LSF(:))));
    subplot(2,2,2); imshow(HSF./255); title(sprintf('mean = %.0f, min = %.0f, max = %.0f',mean(HSF(:)),min(HSF(:)),max(HSF(:))));
    subplot(2,2,3); imshow(gf1,[]);
    subplot(2,2,4); imshow(gf2,[]);
end

function [rgb,LL,imr] = modifyLab(rgb,swapflag,invertflag,C2lab,C2rgb,hist_flag)

%
% rgb = colour image
% swapflag = swap a and b, 1 = yes, 0 = no
% invertflag = invert L, a, and b, 1 = yes, 0 = no
% both swap and invert can be done simultaneously
% c2lab = cform matrix to lab
% c2rgb = cform matrix to rgb
% hist_flag = show luminance histogram, 1 = yes, 0 = no
% cform matrices are passed in to save time
%

% transform to lab:
lab = applycform(rgb,C2lab);

% swap a* and b*:
if swapflag
    tmp = lab(:,:,2);
    lab(:,:,2) = lab(:,:,3);
    lab(:,:,3) = tmp;
end

%invert a*:
if invertflag==1
    if swapflag==0
        lab(:,:,2) = -lab(:,:,2);
    else
        lab(:,:,3) = -lab(:,:,3);
    end
end

%invert b*:
if invertflag==2
    if swapflag==0
        lab(:,:,3) = -lab(:,:,3);
    else
        lab(:,:,2) = -lab(:,:,2);
    end
end

% invert a* and b*:
if invertflag==3
    lab(:,:,2) = -lab(:,:,2);
    lab(:,:,3) = -lab(:,:,3);
end

% transform back to rgb:
rgb = applycform(lab,C2rgb);

% LL is the luminance only image
LL = zeros(size(lab));
imr = zeros(size(lab));
tmp1 = lab(:,:,1);
tmp1 = ( max(tmp1(:)) + min(tmp1(:)) ) - tmp1;
imr(:,:,1) = tmp1;
LL(:,:,1) = lab(:,:,1);
LL = applycform(LL,C2rgb);
imr = applycform(imr,C2rgb);

% convert to double:
%rgb = double(rgb);

if hist_flag
    figure(9);
    imhist(lab(:,:,1),255);
end


function [ Transforms, Merged, flag ] = xcorr2imgs( template, A, varargin )
%XCORR2IMGS Rough alignment by 2D cross-correlation differing by
%translation and/or rotation.
%   Performs automated alignment to template and A. performs the same
%   transformations to templateStack and AStack, respectively.
%   [ Transforms, Merged, flag ] = xcorr2imgs( template, A )
%   [ Transforms, Merged, flag ] = xcorr2imgs( template, A, align )
%   [ Transforms, Merged, flag ] = xcorr2imgs( template, A, align, pad )
%   If align parameter is set to 'align', then Merged will be the aligned
%   images. Otherwise Merged is nil. If the pad parameter is set to 'pad',
%   then program will add extra padding, at the cost of more computation
%   time. flag is raised if alignment is deemed to fail.
%   ASSUMPTIONS: template and A are the SAME size, and DO NOT have any
%   zero pad. These assumptions are consistent with inputs from EM
%   sections.
%
%   Adapted from Reddy, Chatterji, An FFT-Based Technique for Translation,
%   Rotation, and Scale-Invariant Image Registration, 1996, IEEE Trans.

% retrieve global variables
global scalethreshold peakclassifier;
% threshold for possible scaling.
if isempty(scalethreshold)
    scalethreshold = 1.05;
end
threshold = scalethreshold;
% whether to use a trained classifier
classify = 0;
if strcmpi(class(peakclassifier), 'ClassificationSVM')
    classifier = peakclassifier;
    classify = 1;
end

% stop program early if one image is flat (all one color).
if std(double(template(:))) == 0 || std(double(A(:))) == 0
    warning('XCORR2IMGS: one image is completely flat; no transformations performed');
    Transforms = eye(3);
    Merged = cat(3, template, A);
    return;
end

% validate inputs.
narginchk(2,4);
align = 0;
pad = 0;
if nargin > 2 && strcmpi(varargin{1}, 'align')  % align param
	align = 1;
end
if nargin > 3 && strcmpi(varargin{2}, 'pad') % align and pad param
    pad = 1;
end

% flag to indicate failed alignment.
flag = 0;

% convert inputs to unsigned 8-bit integers.
A = uint8(A);
template = uint8(template);

% apply hamming window.
Amod = hamming2dwindow(A);
Tmod = hamming2dwindow(template);

% additional zero padding to avoid edge bias. Tests show this improves
% image alignment, but slows down program.
if pad
    ypad = min(floor(size(Amod, 1)/2), floor(size(Tmod, 1)/2));
    xpad = min(floor(size(Amod, 2)/2), floor(size(Tmod, 2)/2));
    Amod = padarray(Amod, [ypad, xpad]);
    Tmod = padarray(Tmod, [ypad, xpad]);
end

% DFT of template and A.
Amod = fft2(Amod);
Tmod = fft2(Tmod);

% high-pass filtering.
Amod = highpass(abs(fftshift(Amod)));
Tmod = highpass(abs(fftshift(Tmod)));

% Resample image in log-polar coordinates.
[Tmod, rhoaxis] = log_polar(Tmod);
Amod = log_polar(Amod);
clear filteredFT filteredFA;

% compute phase correlation to find best theta.
xpowerspec = fft2(Amod).*conj(fft2(Tmod));
c = real(ifft2(xpowerspec.*(1/norm(xpowerspec))));
clear xpowerspec Amod Tmod;
[rhopeak, thetapeak] = find(c==max(c(:)));
% [rhopeak, thetapeak] = detectpeaks(c, ceil(length(c)/8), 'gaussian', 'rt');
if rhopeak > size(c, 1)/2    % template scaled down to match A
    rhoindex = size(c,1) - rhopeak + 1;
    SCALE = 1/rhoaxis(rhoindex);
else    % template scaled up to match A
    SCALE = rhoaxis(rhopeak);
end
% assume scaling is always 1 for now.
if SCALE > threshold || SCALE < 1/threshold     % threshold against excessive/wrong scaling
    SCALE = 1;
    THETA1 = 0;
    THETA2 = 0;
    warning('scaling exceeded threshold. Potentially failed alignment');
else
    SCALE = 1;
    th = (thetapeak - 1) * 360 / size(c, 2);
    THETA1 = -th;
    THETA2 = -th - 180;
end
clear c;

% rotate template image two possible ways.
RotatedT1 = imrotate(template, THETA1, 'nearest', 'crop');
RotatedT2 = imrotate(template, THETA2, 'nearest', 'crop');

% scale each potential template image
if SCALE ~= 1
    RotatedT1 = imresize(RotatedT1, 1/SCALE);
    RotatedT2 = imresize(RotatedT2, 1/SCALE);
end

% pick correct rotation by maximizing cross correlation. compute best
% transformation parameters.
[RotatedT1, ysmin1, xsmin1, ysmax1, xsmax1] = rmzeropadding(RotatedT1, 2);
[RotatedT2, ysmin2, xsmin2, ysmax2, xsmax2] = rmzeropadding(RotatedT2, 2);
Atemp1 = A(1+ysmin1:size(A,1)-ysmax1, 1+xsmin1:size(A,1)-xsmax1);
Atemp2 = A(1+ysmin2:size(A,1)-ysmax2, 1+xsmin2:size(A,1)-xsmax2);
c1 = normxcorr2(RotatedT1, Atemp1);
c2 = normxcorr2(RotatedT2, Atemp2);
% [ypeak1, xpeak1] = find(c1==max(c1(:)));
% [ypeak2, xpeak2] = find(c2==max(c2(:)));
% format long g
% f1 = getpeakfeatures(c1, ypeak1, xpeak1)
% f2 = getpeakfeatures(c2, ypeak2, xpeak2)
if classify
    [y1, x1] = detectpeaksvm(c1, classifier);
    [y2, x2] = detectpeaksvm(c2, classifier);
else
    [y1, x1] = find(c1==max(c1(:)));
    [y2, x2] = find(c2==max(c2(:)));
%     [y1, x1] = detectpeakxcorr(c1, ceil(length(c1)/8), 'gaussian', 'yx');
%     [y2, x2] = detectpeakxcorr(c2, ceil(length(c2)/8), 'gaussian', 'yx');
end
[errors1, flag1, mnzp1] = errormetrics(cat(3, RotatedT1, Atemp1), 'pxdiff');
[errors2, flag2, mnzp2] = errormetrics(cat(3, RotatedT2, Atemp2), 'pxdiff');
select = 0;
% one is rejected
if x1 ~= -1 && x2 == -1 && c1(y1,x1) > c2(y2,x2)
    select = 1;
elseif x1 == -1 && x2 ~= -1 && c2(y2,x2) > c1(y1,x1)
    select = 2;
else
    if ~flag1 && c1(y1,x1) > c2(y2,x2) && errors1 < errors2 && mnzp1 > mnzp2
        select = 1;
    elseif ~flag2 && c2(y2,x2) > c1(y1,x1) && errors2 < errors1 && mnzp2 > mnzp1
        select = 2;
    end
end
clear c1 c2 Atemp1 Atemp2;
% pick rotation that produces the greatest peak
if select == 1
    RotatedT = RotatedT1;
    THETA = THETA1;
    TranslateY = y1 - size(RotatedT, 1);
    TranslateX = x1 - size(RotatedT, 2);
elseif select == 2
    RotatedT = RotatedT2;
    THETA = THETA2;
    TranslateY = y2 - size(RotatedT, 1);
    TranslateX = x2 - size(RotatedT, 2);
else
    THETA = 0;
    TranslateX = 0;
    TranslateY = 0;
    warning('failed alignment.');
    flag = 1;
end
clear RotatedT1 RotatedT2

% save transformations
Transforms = params2matrix([TranslateY, TranslateX, THETA, SCALE]);

% if align is true, applies transformations
Merged = [];
if align
    Merged  = affinetransform(template, A, Transforms);
end

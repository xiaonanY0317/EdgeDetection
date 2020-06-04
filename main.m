clear;
I = imread("stones2.bmp");
% turn to gray image
Ip = im2double(I);
Ip = rgb2gray(Ip);

% filter -- midfilter, using median filter, remove the noise
Ip = medfilt2(Ip);

% Kmeans compute the treshhold to turn the gray image to BW image
idx = kmeans(Ip(:), 2);
% gm = fitgmdist(Ip(:),2);
% idx = cluster(gm,Ip(:));
thresh = min(max(Ip(idx == 1)), max(Ip(idx == 2)));
tem = imsharpen(Ip, "Threshold", thresh);
bw = edge(tem, "Canny");
Ip = im2bw(Ip, thresh);
Ip = im2double(Ip);

% Fill the imcomplete stones.
Ip = logical(bw) | logical(Ip);

% imfill to fill the hole in each image
Ip = imfill(Ip, "holes");

% remotetunnal to remove the small tunnels in the image.
% imerode then imdilate
se = strel("disk", 2);
Ip = imerode(Ip, se);
Ip = imdilate(Ip, strel("disk", 3));


% watershed_fine to generate edge for adjoint stones
% https://blogs.mathworks.com/steve/2013/11/19/watershed-transform-question-from-tech-support/
D = -bwdist(~Ip);
MinGraph = (D - min(D(:))) / (max(D(:) - min(D(:))));
mask = imextendedmin(MinGraph, 0.025);
D2 = imimposemin(D, mask);
Ld = watershed(D2);
Ip(Ld == 0) = 0;

% remove the incomplete stones on the border
Ip = imclearborder(Ip);

% bwlabel to lable the connected zones
[Label, num] = bwlabel(Ip, 4); % 4 means, only the direct right, left, top and bottom will be considered as connected

% perim algo to abtract edge of the stone
Ip = bwperim(Ip);

% show the boundary and the original image
% seperate layers
I = im2double(I);
R = I(:, :, 1);
G = I(:, :, 2);
B = I(:, :, 3);
R = R + Ip;
G = G + Ip;
B = B + Ip;
Ir = cat(3,R,G,B);
imshow(Ir);

% label the stone and show the number in the image
for k = 1 : num
    [r, c] = find(Label == k);
    rcenter = mean(r) - 8;
    ccenter = mean(c) - 12;
    text(ccenter, rcenter, num2str(k), 'color', 'g');
end

% chunk and show the selected stone
a = regionprops(Label == 1, 'boundingbox');
i = imcrop(I, a.BoundingBox);
figure
imshow(i);

% compute its perimeter and area
C = regionprops(Label == 1, 'perimeter');
A = regionprops(Label == 1, 'area');

% complete the gui for the program


% load image
%Code altered from section 3.5.5 in Szeliski textbook example Citation below
%Citation: Ke Yan (2024). image pyramid(Gaussian and Laplacian) (https://www.mathworks.com/matlabcentral/fileexchange/30790-image-pyramid-gaussian-and-laplacian), MATLAB Central File Exchange. Retrieved February 18, 2024.'''



apple = im2double(imread('apple.png'));
orange = im2double(imread('orange.png'));
apple = imresize(apple,[size(orange,1) size(orange,2)]);

levels = 10;


[M N ~] = size(apple);
v = 230;


limga = genPyr(apple,'lap',level); % the Laplacian pyramid
limgb = genPyr(orange,'lap',level);
maska = zeros(size(apple));
maska(:,1:v,:) = 1;
maskb = 1-maska;
blurh = fspecial('gauss',460,460); % feather the border
maska = imfilter(maska,blurh,'replicate');
maskb = imfilter(maskb,blurh,'replicate');
blend = cell(1,level); % the blended pyramid
for p = 1:level
	[Mp Np ~] = size(limga{p});
	maskap = imresize(maska,[Mp Np]);
	maskbp = imresize(maskb,[Mp Np]);
	blend{p} = limga{p}.*maskap + limgb{p}.*maskbp;
end
blend = pyrReconstruct(blend);
figure,imshow(blend) % blend by pyramid



function [ pyr ] = genPyr( img, type, level )
pyr = cell(1,level);
pyr{1} = im2double(img);
for p = 2:level
	pyr{p} = pyr_reduce(pyr{p-1});
end
if strcmp(type,'gauss'), return; end
for p = level-1:-1:1 % adjust the image size
	osz = size(pyr{p+1})*2-1;
	pyr{p} = pyr{p}(1:osz(1),1:osz(2),:);
end
for p = 1:level-1
	pyr{p} = pyr{p}-pyr_expand(pyr{p+1});
end
end


function [ imgout ] = pyr_reduce( img )
kernelWidth = 5; % default
cw = .375; % kernel centre weight, same as MATLAB func impyramid. 0.6 in the Paper
ker1d = [.25-cw/2 .25 cw .25 .25-cw/2];
kernel = kron(ker1d,ker1d');
img = im2double(img);
sz = size(img);
imgout = [];
for p = 1:size(img,3)
	img1 = img(:,:,p);
	imgFiltered = imfilter(img1,kernel,'replicate','same');
	imgout(:,:,p) = imgFiltered(1:2:sz(1),1:2:sz(2));
end
end


function [ imgout ] = pyr_expand( img )
kw = 5; % default kernel width
cw = .375; % kernel centre weight, same as MATLAB func impyramid. 0.6 in the Paper
ker1d = [.25-cw/2 .25 cw .25 .25-cw/2];
kernel = kron(ker1d,ker1d')*4;
% expand [a] to [A00 A01;A10 A11] with 4 kernels
ker00 = kernel(1:2:kw,1:2:kw); % 3*3
ker01 = kernel(1:2:kw,2:2:kw); % 3*2
ker10 = kernel(2:2:kw,1:2:kw); % 2*3
ker11 = kernel(2:2:kw,2:2:kw); % 2*2
img = im2double(img);
sz = size(img(:,:,1));
osz = sz*2-1;
imgout = zeros(osz(1),osz(2),size(img,3));
for p = 1:size(img,3)
	img1 = img(:,:,p);
	img1ph = padarray(img1,[0 1],'replicate','both'); % horizontally padded
	img1pv = padarray(img1,[1 0],'replicate','both'); % horizontally padded
	
	img00 = imfilter(img1,ker00,'replicate','same');
	img01 = conv2(img1pv,ker01,'valid'); % imfilter doesn't support 'valid'
	img10 = conv2(img1ph,ker10,'valid');
	img11 = conv2(img1,ker11,'valid');
	
	imgout(1:2:osz(1),1:2:osz(2),p) = img00;
	imgout(2:2:osz(1),1:2:osz(2),p) = img10;
	imgout(1:2:osz(1),2:2:osz(2),p) = img01;
	imgout(2:2:osz(1),2:2:osz(2),p) = img11;
end
end


function [ img ] = pyrReconstruct( pyr )
for p = length(pyr)-1:-1:1
	pyr{p} = pyr{p}+pyr_expand(pyr{p+1});
end
img = pyr{1};
end
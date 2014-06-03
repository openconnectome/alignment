%for detecting folds, which are assumed to be dark lines of varying thickness that extend from one side of the image to the other

%iterated threshold segmentation
for i = 1:100;
image = imageAC4(:,:,i);
G = fspecial('gaussian',[3,3],3);
im = imfilter(image,G);
[r,c] = find(im <= 40);

%RANSAC
ptNum = size([r,c]',2); %#columns
iterNum = 45;
thDist = 15;
thInlrRatio = 0.05; 
[t,rho] = ransac([r,c]',iterNum,thDist,thInlrRatio)
k = -tan(t)
b = rho/cos(t)
X = 0:2^5:2^10;

%shows #pts that are thDist close to the line
for i = 1:ptNum;
    A = [r,c];
    pt = [A(i,1),A(i,2)];
    Q1 = [32,k*32+b];
    Q2 = [512,k*32+b];
    dist(i) = abs(det([Q2-Q1; pt-Q1]))/norm(Q2-Q1);
end
    num = dist <= thresh;
    points = sum(num)

%plot lines on image
Im(i) = imshow(im);
hold on;
plot(k*X+b,X,'r')
plot(k*X+b+thDist,X,'r')
plot(k*X+b-thDist,X,'r')
figure;

end
% Determine aspect ratio given BW mask of fused droplets.
% Adjust ScanWidth to reflect size of image.
% Method: finds longest distance between two points, allMaxDist,
% then finds longest length perpendicular to this max distance,
% AR = allMaxDist / max_length
% Can also return dimensions (max dist and max length) and min_length
% (length where fused droplets join/are 'pinched')
% only works for R2017b onward due to use of polyshape function

% @param BW binary image of fusing droplets
% @param ScanWidth spacing between scan lines

function [aspect_ratio, allMaxDist, max_length, min_length] = getAspectRatio(BW, ScanWidth)
%% test1: expect ratio of 1
% X = [2 3 4 3 2 1 0 1];
% Y = [0 1 2 3 4 3 2 1];
% ScanWidth = 1;

%% test2: expect ratio of 1.5
% X = [0 1 2 3 4 5 6 5 4 3 2 1];
% Y = [2 3 4 3 4 3 2 1 0 1 0 1];
% ScanWidth = 1;

%% test3: expect ratio of ~1.8
% I = imread('test_ratio.jpg');
% I = im2bw(I, 0.5);
% figure; imshow(I)
% ScanWidth = 0.5;

%% test4: expect ratio of 2.05 (?)
% I = imread('test_ratio2.jpg');
% I = im2bw(I, 0.5);
% figure; imshow(I)
% ScanWidth = 0.5;

%% test5: actual droplet
% img = imread('test_drop.tif');
% img = img(:,:,1);
% I = img2mask(img);
% figure; imshow(I)
% ScanWidth = 0.5;


%% body %%
%% mask to coords, X and Y
X = [];
Y = [];
boundaries = bwboundaries(BW);
mask_size = size(BW);

for j=1:length(boundaries)
    X=[X boundaries{j,1}(:,2)'];
    X(1,end+1)=NaN;
    Y=[Y mask_size(1,1)-boundaries{j,1}(:,1)'];
    Y(1,end+1)=NaN;
end

%% X and Y to longest dist
num_points = length(X);

maxDists = zeros(1,length(X));
indMaxDists = zeros(1,length(X));

%for each point on boundary, find max distance from any other point on boundary
for thisPoint = 1:num_points
    % calculate x dist and y dist of point from each point in boundary
    xCoord = X(thisPoint);
    yCoord = Y(thisPoint);
    [this_maxDist, this_indMaxDist] = maxDistFromBoundary(xCoord, yCoord, X, Y);
    maxDists(thisPoint) = this_maxDist;
    indMaxDists(thisPoint) = this_indMaxDist;
end

[allMaxDist, allMaxDistInd] = max(maxDists);
%allMaxDist is longest distance between two points on boundary

% coords of two points that are max dist from each other
x1 = X(allMaxDistInd);
y1 = Y(allMaxDistInd);
[that_maxDist, that_indMaxDist] = maxDistFromBoundary(x1, y1, X, Y);
x2 = X(that_indMaxDist);
y2 = Y(that_indMaxDist);

if that_maxDist ~= allMaxDist
    error('Max distances for each point did not match.')
end


% equation of line connecting the points
m = (y2 - y1) / (x2 - x1);
b = -m * x1 + y1;
if (x2 - x1) == 0
    y = [min(X):ScanWidth:max(X)];
    x = ones(1, length(y))*x1;
else
    if x1 > x2
        x = [x2:ScanWidth:x1];
        y = m*x + b;
    else
        x = [x1:ScanWidth:x2];
        y = m*x + b;
    end
end
%figure; scatter(x, y) % plot connecting line

%% scan across longest distance to get max length
% slope of line perpendicular to connecting points
if m == 0
    m2 = Inf;
else
    m2 = -1/m;
end
droplet = polyshape(X, Y); % only works for R2017b onward

% for each point in x, plot intersecting line of slope m2 and check for
% intersections with boundary
all_xInt = [];
all_yInt = [];
lengths = [];

for i = 1:length(x)
    if m2 == Inf
        xi = ones(1, length(x))*x(i);
        yi = [min(X):ScanWidth:max(X)];
    elseif m == Inf
        xi = [min(X):ScanWidth:max(X)];
        yi = y(i)*ones(1, length(xi));
    else
        b2 = y(i) - m2*x(i);
        xi = [min(X):ScanWidth:max(X)];
        yi = m2*xi + b2;
    end
    hold on; scatter(xi, yi, '.')
    
    % find where line intersects droplet and determine length
    [in, out] = intersect(droplet, [xi' yi']);
    if ~isempty(in)
        if m2 == Inf
            [in_minY, ind_in_minY] = min(in(:,2));
            [in_maxY, ind_in_maxY] = max(in(:,2));
            dx = in(ind_in_maxY, 1) - in(ind_in_minY, 1);
            dy = in_maxY - in_minY;
        else
            [in_minX, ind_in_minX] = min(in(:,1));
            [in_maxX, ind_in_maxX] = max(in(:,1));
            dx = in_maxX - in_minX;
            dy = in(ind_in_maxX, 2) - in(ind_in_minX, 2);
        end
        length_in = sqrt(dx.^2 + dy.^2);
        lengths = horzcat(lengths, length_in);
    end
    hold on; scatter(in(:,1), in(:,2), 'x')
end
hold on; plot(X, Y, 'ro')
hold on; plot(droplet)

% find max length
max_length = max(lengths);
min_length = min(lengths); %length where fused droplet is most pinched

% calculate aspect ratio as longest diameter / length of longest segment perpendicular to diameter
aspect_ratio = allMaxDist / max_length;


%TO DO: test on actual droplet images
%Note: Brangwynne paper used following method to determine aspect ratio:
% fit fusing droplets as ellipse
% AR = major axis / minor axis

%TO DO: make parameter BW mask rather than X and Y coords, determine coords
%of boundaries within this function

% Note: can also find min_length to find distance where droplets meet
% (pinched length)


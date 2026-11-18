function [BW] = profileROI(x1_um, x2_um, um_dists, lin_x, lin_y, img_size)
%Inputs: x1_um, x2_um (distances for edge points, in microns), um_dists (linear profile x axis),
%        linear x and y indices (lin_x, lin_y from linearROI), img_size (m x n in pix)
% Given distance values of circle edges from linear intensity profile,
%        returns circular ROI for desired region.

% find closest values on intensity profile
[~,x1_ind] = min(x1_um);
[~,x2_ind] = min(x2_um);

% get x and y coords
% x1 = img_size(1) - lin_x(x1_ind)+1;
% y1 = lin_y(x1_ind)+1;
% 
% y2 = img_size(1) - lin_x(x2_ind)+1;
% x2 = lin_y(x2_ind)+1;
x1=lin_x(x1_ind);
y1=lin_y(x1_ind);

x2=lin_x(x2_ind);
y2=lin_y(x2_ind);

% create circular ROI
th = 0:pi/50:2*pi;
dx = x2 - x1;
dy = y2 - y1;
s_center=[x1+dx y1+dy];
s_radius=sqrt(dx^2+dy^2)/2;
xunit = s_radius * cos(th) + s_center(1);
yunit = s_radius * sin(th) + s_center(2);
            
% convert ROI to mask
BW = poly2mask(xunit,yunit,img_size(1), img_size(2)) > 0;
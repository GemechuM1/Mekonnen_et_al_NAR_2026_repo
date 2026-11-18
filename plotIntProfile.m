function [linear_inds, lin_x, lin_y, um_dists] = plotIntProfile(img_stack, bleachROI, dropletROI, linearROI, slope, Pixel_Size)
%inputs: img_stack (video frames), bleachROI, dropletROI, linearROI (ROI masks), 
%        slope (of linearROI), PixelSize (um per pix)
%returns: linear indices (overall and row/x and col/y), um_dists (x axis of plot in microns)
% Plots linear intensity profile given video frames (img_stack) and ROIs.

img_size = size(bleachROI);
num_frames = length(img_stack);

% apply linear mask
linear_inds = find(linearROI == 1);
[lin_x, lin_y] = find(linearROI == 1);

% get intensities across linear ROI
if abs(slope) > 1 % line more vertical
    lin_sort = sortrows([lin_x lin_y]);
else % line more horizontal
    lin_sort = sortrows([lin_x lin_y], 2);
end

% split droplet ROI into bleached and unbleached
spot_inds = find(bleachROI == 1); % bleached ROI
droplet_inds = find(dropletROI == 1); % droplet ROI
unbleach_inds = find(dropletROI - bleachROI == 1); % in droplet but not bleach ROI

unbleachROI = zeros(img_size(1), img_size(2));
unbleachROI(unbleach_inds) = 1;

% split linear ROI into bleached and unbleached
lin_spot_inds = linear_inds(find(ismember(linear_inds, spot_inds) == 1));
lin_unbleach_inds = linear_inds(find(ismember(linear_inds, unbleach_inds) == 1));
lin_droplet_inds = linear_inds(find(ismember(linear_inds, droplet_inds) == 1));

lin_dropletROI = zeros(img_size(1), img_size(2));
lin_dropletROI(lin_droplet_inds) = 1;

lin_bleachROI = zeros(img_size(1), img_size(2));
lin_bleachROI(lin_spot_inds) = 1;

lin_unbleachROI = zeros(img_size(1), img_size(2));
lin_unbleachROI(lin_unbleach_inds) = 1;

% plot linear ROI intensity vals
linear_vals = zeros(num_frames, length(linear_inds));
figure
for i = 1:num_frames
    img_i = img_stack{i};
    for j = 1:length(lin_x)
        linear_vals(i,j) = img_i(lin_sort(j,1), lin_sort(j,2));
    end
    %linear_vals(i,:) = img_i(linear_inds);
    
    % pixel indexes to distance (um)
    um_dists = zeros(1, length(linear_inds));
    for j = 2:length(linear_inds)
        dx = lin_x(j) - lin_x(j-1);
        dy = lin_y(j) - lin_y(j-1);
        um_dists(j) = um_dists(j-1) + sqrt(dx^2 + dy^2)*Pixel_Size;
    end
    
    % plot values
    red = i/num_frames;
    blue = 1 - red;
    green = 0.2 + min([red blue]);
    if i > 2 % post-bleach
        plot(um_dists, linear_vals(i,:),'Color',[red, 0.2, blue], 'HandleVisibility','off'), hold on
    else % pre-bleach
        plot(um_dists, linear_vals(i,:),'Color',[0.1,0.2,0.3], 'HandleVisibility','off'), hold on
    end
end
% emphasize first bleached frame
plot(um_dists, linear_vals(3,:),'Color',[0,0,1], 'LineWidth',3, 'HandleVisibility','off'), hold on

% add droplet and bleached region boundaries
bleach_i = lin_spot_inds(1);
bleach_f = lin_spot_inds(end);
bleach_i_ind = find(ismember(linear_inds, bleach_i)==1);
bleach_f_ind = find(ismember(linear_inds, bleach_f)==1);

droplet_i = lin_droplet_inds(1);
droplet_f = lin_droplet_inds(end);
droplet_i_ind = find(ismember(linear_inds, droplet_i)==1);
droplet_f_ind = find(ismember(linear_inds, droplet_f)==1);

min_val = min(min(linear_vals));
max_val = max(max(linear_vals));

% droplet boundaries
plot(ones(1,2).*um_dists(droplet_i_ind), [min_val max_val], 'k-', 'LineWidth', 2), hold on
plot(ones(1,2).*um_dists(droplet_f_ind), [min_val max_val], 'k-', 'LineWidth', 2, 'HandleVisibility','off'), hold on

% bleach boundaries
if slope < 0
    plot(ones(1,2).*um_dists(end - bleach_i_ind), [min_val max_val], 'm-'), hold on
    plot(ones(1,2).*um_dists(end - bleach_f_ind), [min_val max_val], 'm-', 'HandleVisibility','off')
else
    plot(ones(1,2).*um_dists(bleach_i_ind), [min_val max_val], 'm-'), hold on
    plot(ones(1,2).*um_dists(bleach_f_ind), [min_val max_val], 'm-', 'HandleVisibility','off')
end

hold off
title('Intensity profiles over time')
xlabel('Distance (um)')
ylabel('Raw Fluorescence')
legend({'droplet','bleach'})

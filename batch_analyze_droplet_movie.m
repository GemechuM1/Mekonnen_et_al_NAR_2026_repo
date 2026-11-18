% Analyzes droplets across all frames of a single multi-frame .tif movie.
% For each frame, saves regionprops stats, droplet count, and area +
% circularity + AR statistics. Output files named by frame number.
% Adapted from batch script by Sophie Skanchy (v3, 6/23/2021)
%
% Circularity = 4*Area*pi / Perimeter^2
% Aspect Ratio = Minor axis / Major axis

close all; clc; clear

%% Select the multi-frame .tif file
[filename, Directory] = uigetfile('*.tif', 'Select multi-frame .tif movie');
if isequal(filename, 0)
    error('No file selected.');
end
cd(Directory);
img_info = imfinfo(filename);
number_of_frames = length(img_info);
disp(['Found ', num2str(number_of_frames), ' frames in ', filename]);

%% >> Input Parameters << (adjust these)
PixelSize = 0.13; % microns per pixel

y = 1; yes = 1; n = 0; no = 0;

% Masking
watershed_segment = y;
use_maskGUI = n;
    mask_method = 7;

% Size Filtering
filterSize = n;
    um_min_minorAxis = 1;
    um_min_area = 0;
    um_max_area = 20;

nonzero_perimeter = y;

% Output Settings
out_name = 'stats.txt';

plot_frame_hists = y;   % save png of histograms per frame
plot_batch_hist = y;    % save png of histograms across all frames
area_bin = 0.25;
circ_bin = 0.1;
AR_bin = 0.1;

save_vars = n;
save_list_txt = y;

%% Calc filter thresholds
if filterSize
    min_minorAxis = um_min_minorAxis / PixelSize;
    min_area = um_min_area / (PixelSize^2);
    max_area = um_max_area / (PixelSize^2);
else
    min_minorAxis = 0;
    min_area = 0;
    max_area = Inf;
end

while ~strcmp(out_name(end-3:end), '.txt')
    out_name = input('Please input valid .txt filename: ', 's');
end
disp(' ')

%% Base name for outputs (strip .tif extension)
base_name = filename(1:end-4);

%% Create output .txt
try
    fileID = fopen(out_name, 'w');
    fprintf(fileID, '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n', ...
        'Frame', 'Mask Method', ...
        'Number of Droplets', 'Mean Area', 'Area STDEV', 'Area SEM', ...
        'Total Area', 'Mean Circularity', 'Circularity STDEV', 'Circularity SEM', ...
        'Mean AR', 'AR STDEV', 'AR SEM', ...
        'Mean Intensity', 'Intensity STDEV', 'Intensity SEM');

    %% Preallocate accumulators
    droplet_counts = zeros(1, number_of_frames);
    all_area      = zeros(1, number_of_frames);
    all_circ      = zeros(1, number_of_frames);
    all_AR        = zeros(1, number_of_frames);
    all_tot_area  = zeros(1, number_of_frames);
    all_mean_int  = zeros(1, number_of_frames);
    area_list = [];
    circ_list = [];
    AR_list   = [];

    %% Loop over frames
    for frameNum = 1:number_of_frames
        frame_label = sprintf('frame%04d', frameNum);
        disp(['Analyzing frame ', num2str(frameNum), ' / ', num2str(number_of_frames)]);

        img = imread(filename, frameNum, 'Info', img_info);

        if use_maskGUI
            mask_method_frame = 0;
        else
            mask_method_frame = mask_method;
        end

        [num_droplets, area_stats, circ_stats, AR_stats, mean_int_stats, ...
            img_stats_table, mask_method_frame] = ...
            analyzeDroplets_v3(PixelSize, img, [base_name, '_', frame_label], ...
            watershed_segment, mask_method_frame, ...
            min_minorAxis, min_area, max_area, nonzero_perimeter);

        droplet_counts(frameNum) = num_droplets;
        all_area(frameNum)     = area_stats(1);
        all_circ(frameNum)     = circ_stats(1);
        all_AR(frameNum)       = AR_stats(1);
        all_tot_area(frameNum) = area_stats(4);
        all_mean_int(frameNum) = mean_int_stats(1);

        % Save per-frame table
        writetable(img_stats_table, [base_name, '_', frame_label, '_stats_table']);

        % Append row to .txt
        fprintf(fileID, '%d,%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
            frameNum, mask_method_frame, num_droplets, ...
            area_stats(1), area_stats(2), area_stats(3), area_stats(4), ...
            circ_stats(1), circ_stats(2), circ_stats(3), ...
            AR_stats(1),   AR_stats(2),   AR_stats(3), ...
            mean_int_stats(1), mean_int_stats(2), mean_int_stats(3));

        area_list = [area_list; img_stats_table.Area];
        circ_list = [circ_list; img_stats_table.Circularity];
        AR_list   = [AR_list;   img_stats_table.AspectRatio];

        %% Per-frame histograms
        if plot_frame_hists && num_droplets > 0
            figure('Visible', 'off')
            area_bins = 0:area_bin:ceil(max(img_stats_table.Area));
            circ_bins = 0:circ_bin:ceil(max(img_stats_table.Circularity));
            AR_bins   = 0:AR_bin:ceil(max(img_stats_table.AspectRatio));

            subplot(1,3,1)
            histogram(img_stats_table.Area, area_bins)
            title([frame_label, ' Areas'])
            xlabel('Area (\mum^2)'); ylabel('Number of Droplets')

            subplot(1,3,2)
            histogram(img_stats_table.Circularity, circ_bins)
            title([frame_label, ' Circularities'])
            xlabel('Circularity')

            subplot(1,3,3)
            histogram(img_stats_table.AspectRatio, AR_bins)
            title([frame_label, ' Aspect Ratios'])
            xlabel('Aspect Ratio'); xticks(0:0.2:1)

            saveas(gcf, [base_name, '_', frame_label, '_hist.png'])
            close(gcf)
        elseif plot_frame_hists
            disp(['  Frame ', num2str(frameNum), ': no droplets detected, histogram skipped.'])
        end
    end

    fclose(fileID);

    %% Save batch lists
    if save_vars
        save([base_name, '_area_circ_lists.mat'], 'area_list', 'circ_list', 'AR_list');
    end

    if save_list_txt
        writematrix(area_list, [base_name, '_batch_area_list.txt'])
        writematrix(circ_list, [base_name, '_batch_circ_list.txt'])
        writematrix(AR_list,   [base_name, '_batch_AR_list.txt'])
    end

    %% Batch histogram (across all frames)
    if plot_batch_hist && ~isempty(area_list)
        figure
        area_bins = 0:area_bin:ceil(max(area_list));
        circ_bins = 0:circ_bin:ceil(max(circ_list));
        AR_bins   = 0:AR_bin:ceil(max(AR_list));

        subplot(1,3,1)
        histogram(area_list, area_bins)
        title('All Frames: Droplet Areas')
        xlabel('Area (\mum^2)'); ylabel('Number of Droplets')

        subplot(1,3,2)
        histogram(circ_list, circ_bins)
        title('All Frames: Circularities')
        xlabel('Circularity')

        subplot(1,3,3)
        histogram(AR_list, AR_bins)
        title('All Frames: Aspect Ratios')
        xlabel('Aspect Ratio'); xticks(0:0.2:1)

        saveas(gcf, [base_name, '_batch_hist.png'])
    end

    %% Summary stats across frames
    disp(' '); disp('=== Summary stats across all frames ===')

    % Droplet counts per frame
    disp('Droplet counts per frame:')
    disp(['  Mean: ', num2str(mean(droplet_counts)), ...
          ', STDEV: ', num2str(std(droplet_counts)), ...
          ', SEM: ',   num2str(std(droplet_counts)/sqrt(number_of_frames))])

    % Mean area per frame (exclude zeros)
    valid_area = all_area(all_area > 0);
    disp('Mean area per frame (um^2):')
    disp(['  Mean: ', num2str(mean(valid_area)), ...
          ', STDEV: ', num2str(std(valid_area)), ...
          ', SEM: ',   num2str(std(valid_area)/sqrt(length(valid_area)))])

    % Total area per frame
    disp('Total area per frame (um^2):')
    disp(['  Mean: ', num2str(mean(all_tot_area)), ...
          ', STDEV: ', num2str(std(all_tot_area)), ...
          ', SEM: ',   num2str(std(all_tot_area)/sqrt(number_of_frames))])

    % Circularity
    valid_circ = all_circ(all_circ > 0);
    disp('Mean circularity per frame:')
    disp(['  Mean: ', num2str(mean(valid_circ)), ...
          ', STDEV: ', num2str(std(valid_circ)), ...
          ', SEM: ',   num2str(std(valid_circ)/sqrt(length(valid_circ)))])

    % Intensity
    valid_int = all_mean_int(all_mean_int > 0);
    disp('Mean intensity per frame:')
    disp(['  Mean: ', num2str(mean(valid_int)), ...
          ', STDEV: ', num2str(std(valid_int)), ...
          ', SEM: ',   num2str(std(valid_int)/sqrt(length(valid_int)))])

    %% Optional: plot per-frame time series
    frames = 1:number_of_frames;
    figure
    subplot(2,2,1)
    plot(frames, droplet_counts, 'o-')
    xlabel('Frame'); ylabel('Count'); title('Droplets per Frame')

    subplot(2,2,2)
    plot(frames, all_area, 'o-')
    xlabel('Frame'); ylabel('Mean Area (\mum^2)'); title('Mean Area per Frame')

    subplot(2,2,3)
    plot(frames, all_circ, 'o-')
    xlabel('Frame'); ylabel('Mean Circularity'); title('Mean Circularity per Frame')

    subplot(2,2,4)
    plot(frames, all_mean_int, 'o-')
    xlabel('Frame'); ylabel('Mean Intensity'); title('Mean Intensity per Frame')

    saveas(gcf, [base_name, '_timeseries.png'])

catch ME
    if exist('fileID','var') && fileID ~= 0
        fclose(fileID);
    end
    disp(['Error at line ', num2str(ME.stack(1).line), ': ', ME.identifier])
    disp(ME.message)
    disp('Closed output .txt file.')
end
% function for generating mask of ROIs based on user-selected points in figure
% requires calculateEllipse.m
% outputs BW ROI mask, radius if ROI is circular, slope if ROI is linear
% Written by Sophie Skanchy in R2019b
% shapes currently supported:
%   'circ' = circle (select center and edge)
%   'd circ' = diameter circle (select two edges to form diameter)
%   'poly' = polygon (select points until reach start point)
%   's line' = straight line (select two points, create horizontal or vertical line)
%   'line' = line of any slope (select two points)
%   'th line' = thick line of width = 3 (select two points) TODO: test
%   'rect' = rectangle (select diagonal corners)
%   'oval' = ellipse (select center, major axis edge, minor axis edge)

function [BW, radius, slope] = getROImask(img, n_roi, shape)

radius = NaN;
slope = NaN;
img_size = size(img);
figure, imshow(img)

% user inputs number of ROIs
% while true
%     n_roi = input('How many ROIs are being analyzed? ');
%     if isempty(n_roi)
%         continue;
%     else
%         break;
%     end
% end

input('ZOOM IN TO THE DESIRED REGION, then hit enter');
th = 0:pi/50:2*pi;
s_ROI=zeros(length(th),2*n_roi);
BW = zeros(img_size(1:2));

%% circle by radius (select center and edge)
if strcmp(shape, 'circ')
    % get user-input ROI
    n_cnt=1;
    while n_cnt<=n_roi
        disp('Choose the center and the edge')
        [sx,sy]=ginput(2);
        s_center=[sx(1,1) sy(1,1)];
        s_radius=sqrt((sx(2,1)-sx(1,1))^2+(sy(2,1)-sy(1,1))^2);
        xunit = s_radius * cos(th) + sx(1,1);
        yunit = s_radius * sin(th) + sy(1,1);
        hold on
        spot=plot(xunit, yunit,'r','LineWidth',1);
        hold off
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            set(spot,'Visible','off')
            continue;
        else
            % the coordinates for the spot (x1,y1,x2,y2,...)
            s_ROI(:,2*n_cnt-1:2*n_cnt)=[xunit' yunit'];
            radius = s_radius;
            % convert ROIs to mask
            BW = BW + poly2mask(xunit,yunit,img_size(1), img_size(2)) > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
end

%% circle by diameter (select opposite edges)
if strcmp(shape, 'd circ')
    % get user-input ROI
    n_cnt=1;
    while n_cnt<=n_roi
        disp('Choose the opposite edges')
        [sx,sy]=ginput(2);
        dx = (sx(2) - sx(1))/2;
        dy = (sy(2) - sy(1))/2;
        s_center=[sx(1)+dx sy(1)+dy];
        s_radius=sqrt((sx(2,1)-sx(1,1))^2+(sy(2,1)-sy(1,1))^2)/2;
        xunit = s_radius * cos(th) + s_center(1);
        yunit = s_radius * sin(th) + s_center(2);
        hold on
        spot=plot(xunit, yunit,'r','LineWidth',1);
        hold off
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            set(spot,'Visible','off')
            continue;
        else
            % the coordinates for the spot (x1,y1,x2,y2,...)
            s_ROI(:,2*n_cnt-1:2*n_cnt)=[xunit' yunit'];
            % convert ROIs to mask
            BW = BW + poly2mask(xunit,yunit,img_size(1), img_size(2)) > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
    radius = s_radius;
end

%% polygon
if strcmp(shape, 'poly')
    dist_thresh = 4; % pixel distance threshold for finishing a polygon
    n_cnt = 1;
    while n_cnt<=n_roi
        disp('Choose the edge points')
        
        % start point
        [sxo,syo]=ginput(1);
        xunit = sxo;
        yunit = syo;
        hold on
        scatter(sxo, syo,'r');
        hold off
        
        % second point
        [sx,sy] = ginput(1);
        dist = sqrt((sx-sxo)^2 + (sy-syo)^2);
        xunit = [xunit, sx];
        yunit = [yunit, sy];
        hold on
        scatter(sx, sy,'g');
        hold off
        
        % get points until end point near start point
        while dist > dist_thresh
            [sx,sy] = ginput(1);
            xunit = [xunit, sx];
            yunit = [yunit, sy];
            hold on
            scatter(sx, sy,'g');
            hold off
            dist = sqrt((sx-sxo)^2 + (sy-syo)^2);
        end
        xunit = [xunit, sxo];
        yunit = [yunit, syo];
        hold on
        spot=plot(xunit, yunit,'g','LineWidth',1);
        hold off
        
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            if n_cnt == 1
                imshow(img)
            else
                %imshow(imfuse(img, BW))
            end
            continue;
        else
            % convert ROIs to mask
            BW = BW + poly2mask(xunit,yunit,img_size(1), img_size(2)) > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
end

%% straight line (horizontal or vertical)
if strcmp(shape, 's line')
    n_cnt = 1;
    while n_cnt<=n_roi
        disp('Choose start point and length point')
        
        % start point
        [sxo,syo]=ginput(1);
        hold on
        scatter(sxo, syo,'r');
        hold off
        
        % length point
        [sx,sy] = ginput(1);
        hold on, plot([sxo sx], [syo sy],'-r')
        hold on, scatter(sx, sy, 'ro')
        hold off
        
        lineBW = zeros(img_size(1:2));
        
        % determine vert (0) or horz (1)
        if abs(sx - sxo) > abs(sy - syo)
            direction = 1;
            slope = 0;
        else
            direction = 0;
            slope = Inf;
        end
        
        % create line
        if direction % horz
            % determine left and right
            if sx > sxo
                left = [sxo, syo];
                right = [sx, sy];
            else
                left = [sx, sy];
                right = [sxo, syo];
            end
            for i = left(1):right(1)
                lineBW(round(syo), round(i)) = 1;
            end
        else % vert
            % determine top and bottom
            if sy < syo
                top = [sxo, syo];
                bot = [sx, sy];
            else
                top = [sx, sy];
                bot = [sxo, syo];
            end
            for i = bot(2):top(2)
                lineBW(round(i), round(sxo)) = 1;
            end
        end
        
        % show line
        %figure, imshow(lineBW)
        
        % qc
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            if n_cnt == 1
                imshow(img)
            else
                %imshow(imfuse(img, BW))
            end
            continue;
        else
            % convert ROIs to mask
            BW = BW + lineBW > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
    %figure, imshow(BW)
end

%% line (any slope)
if strcmp(shape, 'line')
    n_cnt = 1;
    while n_cnt<=n_roi
        disp('Choose start point and end point')
        
        % start point
        [sxo,syo]=ginput(1);
        hold on
        scatter(sxo, syo,'r');
        hold off
        
        % end point
        [sx,sy] = ginput(1);
        hold on, plot([sxo sx], [syo sy],'-r')
        hold on, plot(sx, sy, 'ro')
        hold off
        
        lineBW = zeros(img_size(1:2));
        
        % determine left and right
        if sx > sxo
            left = [sxo, syo];
            right = [sx, sy];
        else
            left = [sx, sy];
            right = [sxo, syo];
        end
        
        % determine slope and intercept
        slope = (right(2) - left(2)) / (right(1) - left(1));
        y_int = left(2) - slope*left(1);
        
        % create line
        if abs(slope) == Inf % vertical line
            if left(2) > right(2)
                for i = right(2):left(2)
                    lineBW(round(i), round(left(1))) = 1;
                end
            else
                for i = left(2):right(2)
                    lineBW(round(i), round(left(1))) = 1;
                end
            end
        elseif slope == 0 % horizontal line
            for i = left(1):right(1)
                lineBW(round(left(2)), round(i)) = 1;
            end
        elseif abs(slope) == 1 % perfect diagonal
            x = left(1); y = left(2);
            for i = left(1):right(1)
                x = x + 1;
                y = y + 1;
                lineBW(round(y), round(x)) = 1;
            end
        elseif abs(slope) < 1 % scan across x
            for i = left(1):right(1)
                y = slope*i + y_int;
                lineBW(floor(y), round(i)) = 1;
            end
        else % scan across y
            if left(2) > right(2)
                for i = right(2):left(2)
                    x = (i - y_int)/slope;
                    lineBW(round(i), floor(x)) = 1;
                end
            else
                for i = left(2):right(2)
                    x = (i - y_int)/slope;
                    lineBW(round(i), floor(x)) = 1;
                end
            end
        end
        
        % show line
        %figure, imshow(lineBW)
        
        % qc
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            if n_cnt == 1
                imshow(img)
            else
                %imshow(imfuse(img, BW))
            end
            continue;
        else
            % convert ROIs to mask
            BW = BW + lineBW > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
    %figure, imshow(BW)
end

%% thick line (line with any slope, width = 3)
if strcmp(shape, 'th line')
    n_cnt = 1;
    while n_cnt<=n_roi
        disp('Choose start point and end point')
        
        % start point
        [sxo,syo]=ginput(1);
        hold on
        scatter(sxo, syo,'r');
        hold off
        
        % end point
        [sx,sy] = ginput(1);
        hold on, plot([sxo sx], [syo sy],'-r')
        hold on, plot(sx, sy, 'ro')
        hold off
        
        lineBW = zeros(img_size(1:2));
        
        % determine left and right
        if sx > sxo
            left = [sxo, syo];
            right = [sx, sy];
        else
            left = [sx, sy];
            right = [sxo, syo];
        end
        
        % determine slope and intercept
        slope = (right(2) - left(2)) / (right(1) - left(1));
        y_int = left(2) - slope*left(1);
        
        % create line
        if abs(slope) == Inf % vertical line
            if left(2) > right(2)
                for i = right(2):left(2)
                    lineBW(round(i), round(left(1))) = 1;
                    
                    if left(1) > 1
                        lineBW(round(i), round(left(1))-1) = 1; %one to left
                    end
                    
                    if left(1) < img_size(1)
                        lineBW(round(i), round(left(1))+1) = 1; %one to right
                    end
                end
            else
                for i = left(2):right(2)
                    lineBW(round(i), round(left(1))) = 1;
                    
                    if left(1) > 1
                        lineBW(round(i), round(left(1))-1) = 1; %one to left
                    end
                    
                    if left(1) < img_size(1)
                        lineBW(round(i), round(left(1))+1) = 1; %one to right
                    end
                end
            end
        elseif slope == 0 % horizontal line
            for i = left(1):right(1)
                lineBW(round(left(2)), round(i)) = 1;
                
                if left(2) > 1
                    lineBW(round(left(2))-1, round(i)) = 1; %one above
                end
                
                if left(2) < img_size(2)
                    lineBW(round(left(2))+1, round(i)) = 1; %one below
                end
            end
        elseif abs(slope) == 1 % perfect diagonal
            x = left(1); y = left(2);
            for i = left(1):right(1)
                x = x + 1;
                y = y + 1;
                lineBW(round(y), round(x)) = 1;
                
                if i > 1
                    lineBW(round(y), round(x)-1) = 1; %one to left
                end
                
                if i < img_size(1)
                    lineBW(round(y), round(x)+1) = 1; %one to right
                end
            end
        elseif abs(slope) < 1 % scan across x
            for i = left(1):right(1)
                x = i;
                y = slope*i + y_int;
                lineBW(floor(y), round(i)) = 1;
                
                if i > 1
                    lineBW(floor(y), round(x)-1) = 1; %one to left
                end
                
                if i < img_size(1)
                    lineBW(floor(y), round(x)+1) = 1; %one to right
                end
            end
        else % scan across y
            if left(2) > right(2)
                for i = right(2):left(2)
                    x = (i - y_int)/slope;
                    lineBW(round(i), floor(x)) = 1;
                    
                    if i > 1
                        lineBW(round(i)-1, floor(x)) = 1; %one above
                    end
                    
                    if i < img_size(2)
                        lineBW(round(i)+1, floor(x)) = 1; %one below
                    end
                end
            else
                for i = left(2):right(2)
                    x = (i - y_int)/slope;
                    lineBW(round(i), floor(x)) = 1;
                    
                    if i > 1
                        lineBW(round(i)-1, floor(x)) = 1; %one above
                    end
                    
                    if i < img_size(2)
                        lineBW(round(i)+1, floor(x)) = 1; %one below
                    end
                end
            end
        end
        
        % show line
        %figure, imshow(lineBW)
        
        % qc
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            if n_cnt == 1
                imshow(img)
            else
                %imshow(imfuse(img, BW))
            end
            continue;
        else
            % convert ROIs to mask
            BW = BW + lineBW > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
end

%% rectangle
if strcmp(shape, 'rect')
    n_cnt = 1;
    while n_cnt<=n_roi
        % start point
        disp('Choose start point')
        [sxo,syo]=ginput(1);
        xunit = sxo;
        yunit = syo;
        hold on
        scatter(sxo, syo,'r');
        hold off
        
        % end point
        disp('Choose opposite corner')
        [wx,hy] = ginput(1);
        rect_height = hy - syo; % negative if below start point
        rect_width = wx - sxo; % negative if left of start point
        hold on
        scatter(wx, hy,'g');
        hold off
        
        rect = polyshape([sxo sxo sxo+rect_width sxo+rect_width],[syo+rect_height syo syo syo+rect_height]);
        hold on
        plot(rect)
        hold off
        xi = rect.Vertices(:,1);
        yi = rect.Vertices(:,2);
        
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            if n_cnt == 1
                imshow(img)
            else
                %imshow(imfuse(img, BW))
            end
            continue;
        else
            % convert ROIs to mask
            BW = BW + poly2mask(xi, yi,img_size(1), img_size(2)) > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
end

%% ellipse (select center, major axis edge, minor axis edge)
if strcmp(shape, 'oval')
    % get user-input ROI
    n_cnt=1;
    while n_cnt<=n_roi
        disp('Choose the center')
        [cx,cy] = ginput(1);
        hold on, plot(cx, cy, 'ro'), hold off
        
        axes = zeros(1,2);
        disp('Choose major axis edge')
        [ax,ay] = ginput(1);
        hold on, plot(ax, ay, 'ro'), hold off
        axes(1) = sqrt((ax - cx)^2 + (ay - cy)^2);
        angle = atan((ay - cy)/(ax - cx))*180/pi;
        
        disp('Choose minor axis edge')
        [bx, by] = ginput(1);
        hold on, plot(bx, by, 'ro'), hold off
        axes(2) = sqrt((bx - cx)^2 + (by - cy)^2);
        
        [xunit, yunit] = calculateEllipse(cx, cy, axes(1), axes(2), -angle);
        hold on
        spot=plot(xunit, yunit,'r','LineWidth',1);
        hold off
        quality_check = input('Is it OK? (Ent or n) ','s');
        if quality_check == 'n'
            %set(spot,'Visible','off')
            imshow(img)
            continue;
        else
            % convert ROIs to mask
            BW = BW + poly2mask(xunit,yunit,img_size(1), img_size(2)) > 0;
            %imshow(imfuse(img, BW));
            n_cnt=n_cnt+1;
        end
    end
    %figure, imshow(imfuse(img, BW)), title('Final ROI mask overlay')
end
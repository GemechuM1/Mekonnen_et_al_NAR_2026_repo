%% import video
fname = 'XXX.tif';
info = imfinfo(fname);
vid_length = length(info);

img_stack_crop = cell(1, vid_length);

for f = 1:vid_length
    img = imread(fname, f, 'Info', info);
    I = img; % default
    %I = img(140:190, 175:225); % 2027
    %I = img(130:180, 130:180); % 2030
    img_stack_crop{f} = I;
    
    radiusRange = [2 100];
    [centers,radii] = imfindcircles(I,radiusRange);
    
    if ~isempty(radii)
        %figure, imshow(imadjust(I))
        %hold on, scatter(centers(:,1), centers(:,2),'yo')
        
        dr2 = zeros(1,length(radii));
        
        for i = 1:length(radii)
            
            x = centers(i,1);
            y = centers(i,2);
            r = radii(i);
%             hold on
%             th = 0:pi/50:2*pi;
%             xunit = r * cos(th) + x;
%             yunit = r * sin(th) + y;
%             plot(xunit, yunit);
%             hold off
%             title(['Frame ' num2str(f)])
            
            
        end
        
        if length(radii)>1
            inds = find(radii < 10);
            
            for rad = 1:length(radii)
                if ismember(rad, inds)
                    dr2(rad) = (x - size(I,1)/2)^2 + (y - size(I,2)/2)^2;
                else
                    dr2(rad) = Inf;
                end
            end
            [~, ind_min] = min(dr2);
        else
            ind_min = 1;
        end
        
        circles(f).r = radii(ind_min);
        circles(f).x = centers(ind_min,1);
        circles(f).y = centers(ind_min,2);
    end
end

%% plot selected circles
radii = zeros(1, length(vid_length));
fig = figure;
imcells = cell(1, vid_length);
for c = 1:vid_length
    imshow((img_stack_crop{c}))
    hold on, scatter(circles(c).x, circles(c).y,'yo')
    
    xi = circles(c).x;
    yi = circles(c).y;
    ri = circles(c).r;
    hold on
    th = 0:pi/50:2*pi;
    xunit = ri .* cos(th) + xi;
    yunit = ri .* sin(th) + yi;
    plot(xunit, yunit);
    hold off
    
    title(['Frame ' num2str(c)])
    
    % save frame
    frame = getframe(fig);
    imcells{c} = frame2im(frame);
    
    disp(['Press any key to go to frame' num2str(c+1)])
    %pause()

    radii(c) = ri;
end

%% save gif
interval = 1;
speed = 5;
gif_name = [fname(1:end-4) '_circles.gif'];

for idx = 1:vid_length
    [A,map] = rgb2ind(imcells{idx},256);
    if idx == 1
        imwrite(A,map,gif_name,'gif','LoopCount',Inf,'DelayTime',interval/speed);
    else
        imwrite(A,map,gif_name,'gif','WriteMode','append','DelayTime',interval/speed);
    end
end
    

%% plot radius
t = 3:63;
r = radii(t);

figure
scatter(t, r, 'k.')

% fit

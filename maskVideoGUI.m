% Given input cell array of grayscale images, outputs user-selected masking method
% Edited 7/12/2021 for use with fusion analysis: displays ellipses overlaid on original image
function varargout = maskVideoGUI(varargin)
% MASKVIDEOGUI MATLAB code for maskVideoGUI.fig
%      MASKVIDEOGUI, by itself, creates a new MASKVIDEOGUI or raises the existing
%      singleton*.
%
%      H = MASKVIDEOGUI returns the handle to a new MASKVIDEOGUI or the handle to
%      the existing singleton*.
%
%      MASKVIDEOGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MASKVIDEOGUI.M with the given input arguments.
%
%      MASKVIDEOGUI('Property','Value',...) creates a new MASKVIDEOGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before maskVideoGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to maskVideoGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help maskVideoGUI

% Last Modified by GUIDE v2.5 02-Mar-2020 15:02:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @maskVideoGUI_OpeningFcn, ...
    'gui_OutputFcn',  @maskVideoGUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before maskVideoGUI is made visible.
function maskVideoGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to maskVideoGUI (see VARARGIN)

% Choose default command line output for maskingGUI
handles.output = hObject;

% original video
img_stack = varargin{1};
setappdata(hObject, 'original', img_stack)
vid_length = length(img_stack);
setappdata(hObject, 'vid_length', vid_length)

% default mask method is 1
setappdata(handles.mask_dropdown, 'mask_method', 1)

% default toggle is show orig
setappdata(handles.toggle_orig_mask, 'orig_mask_toggle', 0);

% set up slider
set(handles.slider_frames, 'Value', 1)
set(handles.slider_frames, 'SliderStep', [1/(vid_length - 1), 10/(vid_length - 1)])
set(handles.slider_frames, 'Min', 1)
set(handles.slider_frames, 'Max', vid_length)
setappdata(handles.slider_frames, 'frame', 1)


% Update handles structure
guidata(hObject, handles);
axes(handles.axes_img)
imshow(imadjust(img_stack{1}))
title('Original - Frame 1')

% UIWAIT makes maskingGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = maskVideoGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
mask_method = getappdata(handles.push_load_mask, 'loaded_mask_method');
varargout{1} = mask_method;
close(gcf)




% --- Executes on slider movement.
function slider_frames_Callback(hObject, eventdata, handles)
% hObject    handle to slider_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

frame = round(get(hObject, 'Value'));
set(hObject, 'Value', frame)
setappdata(hObject, 'frame', frame)
mask_method = getappdata(handles.mask_dropdown, 'mask_method');
state = getappdata(handles.toggle_orig_mask, 'orig_mask_toggle');
orig_stack = getappdata(handles.figure1, 'original');
orig = orig_stack{frame};

% graph selected frame
if ~isempty(getappdata(handles.push_load_mask, 'loaded_mask'))
    mask_stack = getappdata(handles.push_load_mask, 'loaded_mask');
    mask = mask_stack{frame};
    if state == 1
        axes(handles.axes_img)
        imshow(mask)
        title(['Mask ' num2str(mask_method) ' - Frame ' num2str(frame)])
        
        axes(handles.axes_small)
        %imshow(imadjust(orig)), title('original')
        imshow(imadjust(orig)), hold on
        droplets = regionprops(mask, 'Centroid', 'MajorAxisLength','MinorAxisLength','Orientation');
        for i = 1:length(droplets)
            [X,Y] =  calculateEllipse(droplets(i).Centroid(1), droplets(i).Centroid(2), droplets(i).MajorAxisLength/2, droplets(i).MinorAxisLength/2, droplets(i).Orientation, 20);
            plot(X, Y, '-r'), hold on
        end
        title('Ellipses')
        hold off
    else
        axes(handles.axes_img)
        %imshow(imfuse(imadjust(orig), mask)) % show overlay
        %         imshow(imadjust(orig)) % show original
        %         title(['Original - Frame ' num2str(frame)])
        imshow(imadjust(orig)), hold on
        droplets = regionprops(mask, 'Centroid', 'MajorAxisLength','MinorAxisLength','Orientation');
        for i = 1:length(droplets)
            [X,Y] =  calculateEllipse(droplets(i).Centroid(1), droplets(i).Centroid(2), droplets(i).MajorAxisLength/2, droplets(i).MinorAxisLength/2, droplets(i).Orientation, 20);
            plot(X, Y, '-r'), hold on
        end
        title('Ellipses')
        hold off
        
        axes(handles.axes_small)
        imshow(mask), title(['Mask ' num2str(mask_method)])
    end
elseif state == 0 % display orig
    axes(handles.axes_img)
    %     imshow(imadjust(orig))
    %     title(['Original - Frame ' num2str(frame)])
    imshow(imadjust(orig)), hold on
    droplets = regionprops(mask, 'Centroid', 'MajorAxisLength','MinorAxisLength','Orientation');
    for i = 1:length(droplets)
        [X,Y] =  calculateEllipse(droplets(i).Centroid(1), droplets(i).Centroid(2), droplets(i).MajorAxisLength/2, droplets(i).MinorAxisLength/2, droplets(i).Orientation, 20);
        plot(X, Y, '-r'), hold on
    end
    title('Ellipses')
    hold off
else
    disp('Please load a mask first.')
end

% --- Executes during object creation, after setting all properties.
function slider_frames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in toggle_orig_mask.
function toggle_orig_mask_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_orig_mask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggle_orig_mask
state = get(hObject, 'Value');
setappdata(hObject, 'orig_mask_toggle', state);

frame = getappdata(handles.slider_frames, 'frame');
mask_method = getappdata(handles.push_load_mask, 'loaded_mask_method');
orig_stack = getappdata(handles.figure1, 'original');
mask_stack = getappdata(handles.push_load_mask, 'loaded_mask');

if ~isempty(mask_stack)
    orig = orig_stack{frame};
    mask = mask_stack{frame};
    
    if state == 1
        axes(handles.axes_img)
        imshow(mask)
        title(['Mask ' num2str(mask_method) ' - Frame ' num2str(frame)])
        
        axes(handles.axes_small)
        %         imshow(imadjust(orig)), title('original')
        imshow(imadjust(orig)), hold on
        droplets = regionprops(mask, 'Centroid', 'MajorAxisLength','MinorAxisLength','Orientation');
        for i = 1:length(droplets)
            [X,Y] =  calculateEllipse(droplets(i).Centroid(1), droplets(i).Centroid(2), droplets(i).MajorAxisLength/2, droplets(i).MinorAxisLength/2, droplets(i).Orientation, 20);
            plot(X, Y, '-r'), hold on
        end
        title('Ellipses')
        hold off
    else
        axes(handles.axes_img)
        %imshow(imfuse(imadjust(orig), mask)) % show overlay
        %         imshow(imadjust(orig)) % show original
        %         title(['Original - Frame ' num2str(frame)])
        imshow(imadjust(orig)), hold on
        droplets = regionprops(mask, 'Centroid', 'MajorAxisLength','MinorAxisLength','Orientation');
        for i = 1:length(droplets)
            [X,Y] =  calculateEllipse(droplets(i).Centroid(1), droplets(i).Centroid(2), droplets(i).MajorAxisLength/2, droplets(i).MinorAxisLength/2, droplets(i).Orientation, 20);
            plot(X, Y, '-r'), hold on
        end
        title('Ellipses')
        hold off
        
        axes(handles.axes_small)
        imshow(mask), title(['Mask ' num2str(mask_method)])
    end
else
    disp('Please load a mask first.')
end


% --- Executes on selection change in mask_dropdown.
function mask_dropdown_Callback(hObject, eventdata, handles)
% hObject    handle to mask_dropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns mask_dropdown contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mask_dropdown
mask_method = get(hObject, 'Value');
setappdata(handles.mask_dropdown, 'mask_method', mask_method);

% --- Executes during object creation, after setting all properties.
function mask_dropdown_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mask_dropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_load_mask.
function push_load_mask_Callback(hObject, eventdata, handles)
% hObject    handle to push_load_mask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get original video
orig_stack = getappdata(handles.figure1, 'original');
mask_method = getappdata(handles.mask_dropdown, 'mask_method');
setappdata(hObject, 'loaded_mask_method', mask_method);

% convert each frame to mask
vid_length = length(orig_stack);
mask_stack = cell(1, vid_length);
for i = 1:vid_length
    mask_stack{i} = im2mask(orig_stack{i}, mask_method);
end
setappdata(handles.push_load_mask, 'loaded_mask', mask_stack)

% update display
state = getappdata(handles.toggle_orig_mask, 'orig_mask_toggle');
frame = getappdata(handles.slider_frames, 'frame');
orig = orig_stack{frame};
mask = mask_stack{frame};
if state == 1
    axes(handles.axes_img)
    imshow(mask)
    title(['Mask ' num2str(mask_method) ' - Frame ' num2str(frame)])
    
    axes(handles.axes_small)
    % imshow(imadjust(orig)), title('original')
    imshow(imadjust(orig)), hold on
    droplets = regionprops(mask, 'Centroid', 'MajorAxisLength','MinorAxisLength','Orientation');
    for i = 1:length(droplets)
        [X,Y] =  calculateEllipse(droplets(i).Centroid(1), droplets(i).Centroid(2), droplets(i).MajorAxisLength/2, droplets(i).MinorAxisLength/2, droplets(i).Orientation, 20);
        plot(X, Y, '-r'), hold on
    end
    title('Ellipses')
    hold off
else
    axes(handles.axes_img)
    imshow(imfuse(imadjust(orig), mask))
    title(['Original - Frame ' num2str(frame)])
    
    axes(handles.axes_small)
    imshow(mask), title(['Mask ' num2str(mask_method)])
end

% --- Executes on button press in push_chooseMask.
function push_chooseMask_Callback(hObject, eventdata, handles)
% hObject    handle to push_chooseMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chosen_method = getappdata(handles.push_load_mask, 'loaded_mask_method');
setappdata(handles.push_chooseMask, 'chosen_mask_method', chosen_method)
uiresume(handles.figure1)

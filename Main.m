function varargout = Main(varargin)
% MAIN MATLAB code for Main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Main

% Last Modified by GUIDE v2.5 25-Feb-2014 12:03:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Main_OpeningFcn, ...
                   'gui_OutputFcn',  @Main_OutputFcn, ...
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
end


% --- Override the closing function to close the serial port.
function closeProgram(hObject, eventdata, handles, varargin)
% Close the serial port. Otherwise, it will remain open and
% no other instance will be able to connect to it.
% Then, delete the figure.

global programSettings;
fclose(programSettings.port);
disp('Serial port closed.');
delete(gcf);
end

% --- Executes just before Main is made visible.
function Main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Main (see VARARGIN)

% Choose default command line output for Main
handles.output = hObject;

% brodrigu: add global variable for serial port access
% also set the default close operation to a custom function.
global programSettings;

disp('Starting program...');
disp('Initializing to:');
disp('  1 mote');
disp('  Using first serial port detected...');
disp('  Setting Baud Rate to 57600');
programSettings.numberOfMotes = 1;
radio = instrhwinfo('serial');
radio = radio.AvailableSerialPorts(1);
programSettings.port = serial(radio, 'BaudRate', 57600);
fopen(programSettings.port);
setRadioDefaults();

set(gcf, 'CloseRequestFcn', @closeProgram);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Main wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% Set initial parameters:
%  Calibrate
%  Set Frequency to 10
%  Set Precision to LOW
%  Set Gain to 1
function setRadioDefaults()
global programSettings;
%fprintf(programSettings.port, 'C');
%pause(1);
%fprintf(programSettings.port, 'F1');
%pause(1);
%fprintf(programSettings.port, 'PL');
%pause(1);
%fprintf(programSettings.port, 'G1');
end

% Display mote acknowledgements.
function displayResponses()
global programSettings;
pause(0.5*programSettings.numberOfMotes);
for n = 1:programSettings.numberOfMotes
    while programSettings.port.BytesAvailable > 0
       b = fscanf(programSettings.port, '%s');
       disp(['  ', b]);
    end
end
end


% --- Outputs from this function are returned to the command line.
function varargout = Main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes on button press in pushbutton1.
% pushbutton1 = START
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global programSettings;
fprintf(programSettings.port, 'R');
disp('Broadcasting "R" (Start) to all motes');
displayResponses();
end



% --- Executes on button press in pushbutton2.
% pushbutton2 = STOP
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global programSettings;
fprintf(programSettings.port, 'S');
disp('Broadcasting "S" (Stop) to all motes');
displayResponses();

pause(1);
programSettings.filenames = containers.Map(0, 'null');
for n = 1:programSettings.numberOfMotes
   command = strcat('T', int2str(n));
   fprintf(programSettings.port, command);
   pause(0.5);
   filename = strcat(date, '-', int2str(n), '-', int2str(round(cputime)), '.txt');
   tempMap = containers.Map(n, filename);
   programSettings.filenames = [programSettings.filenames; tempMap];
   fileID = fopen(filename, 'w');
   while programSettings.port.BytesAvailable > 0
       b = fscanf(programSettings.port, '%u');
       % Transmit message will be read as ASCII numbers. We don't want to
       % write this to the file, so through out numbers in the ASCII
       % domain.
       if b > 128
        fprintf(fileID, '%u\n', b);
       end
       %fprintf(fileID, '%c\n', fscanf(programSettings.port, '%c'))
   end
   fclose(fileID);
   pause(1);
end
graphData();
end

function graphData()
cla;
global programSettings;
c = ['r','g','b'];
hold all;
for n = 1:(programSettings.numberOfMotes)
    y = load(programSettings.filenames(n));
    l = size(y);
    plot(1:l(1), y, c(n));
end
hold off;
programSettings.filenames = containers.Map(0, 'null');
end


% --- Executes on button press in pushbutton3.
% pushbutton3 = CALIBRATE
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global programSettings;
fprintf(programSettings.port, 'C');
disp('Broadcasting "C" (Calibrate) to all motes');
displayResponses();

end


% --- Executes on selection change in popupmenu2.
% popupmenu2 = FREQUENCY
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2

value = get(hObject,'Value');
frequency = cellstr(get(hObject,'String'));
frequency = frequency{value};
message = strcat('F', num2str(value));
global programSettings;
fprintf(programSettings.port, message);
disp(['Broadcasting ', message, '(', frequency, ')', ' to all motes']);
displayResponses();

end


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on selection change in popupmenu3.
% popupmenu3 = PRECISION
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3

value = get(hObject,'Value');
switch value
    case 1 % 1 = LOW
        message = 'PL';
        
    case 2 % 2 = HIGH
        message = 'PH';
end

global programSettings;
fprintf(programSettings.port, message);
disp(['Broadcasting ', message, ' to all motes']);
displayResponses();

end


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on selection change in popupmenu4.
% popupmenu4 = GAIN
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4

value = get(hObject, 'Value');
gain = get(hObject, 'String');
gain = gain{value};
message = strcat('G', num2str(value));
global programSettings;
fprintf(programSettings.port, message);
disp(['Broadcasting ', message, '(', gain, ')', ' to all motes']);
displayResponses();

end


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in popupmenu5.
% popupmenu5 = # OF MOTES
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu5
global programSettings;
motes = cellstr(get(hObject,'String'));
n = motes{get(hObject,'Value')};
n = str2num(n);
programSettings.numberOfMotes = n;
disp(['Updating number of motes to ', num2str(n), '...']);
disp(['Program will now poll ', num2str(n), ' motes when program is stopped']);
end

% --- Executes during object creation, after setting all properties.
function popupmenu5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

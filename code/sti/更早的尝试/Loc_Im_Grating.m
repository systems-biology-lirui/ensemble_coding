function Loc_Im_Grating(session_name, paradigm_name)

% color localizer code for imagination experiments
% 
% Run from command line, e.g.: Loc_Im_Grating('QQ_210903_s001', 'run01')
% 
% The run will start upon receiving a trigger from the scanner, or in
% response to keystroke "s". Keystroke "q" can be used to quit at any time.
%
% Changing TR(line 73) affects the length of Fix block but not condition block!!!
%
% The program will wait for 2 dummy TRs(line 77) after the trigger to start the stimuli.
% There are 2 additional TRs(line 341) waiting for scanner end.
% 
% The code will create folder "session_name" under 'Results' with paradigm
% files for each run, named "Loc_Im_GrayScale_paradigm_name.mat", which consists of
%  'PreLog' and 'ResLog'. 'PreLog', abbreviation of 'presentation log',
%  logs stimuli's info in the first twelve columns and
% the code and time of this block in the last column. While 'ResLog',
% abbreviation of 'response log',  logs response time score of this block in the last column..
% 
% Condition codes: 1 = YellowB (Yellow Banana), 2 = YellowC (Yellow Corn), 3 = GreenC (Green Cabbage), 
% 4 = GreenK (Green Kiwi), 5 = RedS (Red Strawberry), 6 = RedW (Red Watermelon)
%
% 
% 
% Written by Ning Liu (ibp), 2021.
% 

commandwindow;

% System seting
%**************************************************************************
warning('off', 'MATLAB:DeprecatedLogicalAPI');
warning('off', 'MATLAB:dispatcher:InexactMatch');
rng('shuffle'); % avoid repeating the same random number arrays when MATLAB restarts

%**************************************************************************

% Path for saving paradigm files and images
%**************************************************************************
MainPath='D:\ZuoZG';

ImageDir = fullfile(MainPath, 'Stimuli', filesep);

RunFile = fullfile(MainPath, 'Results', session_name, ['Loc_Im_Grating_' paradigm_name '.mat']);
BreakRunFile = fullfile(MainPath, 'Results', session_name, ['Loc_Im_Grating_' paradigm_name '_break' '.mat']);

if ~isdir(fullfile(MainPath, 'Results', session_name))
    mkdir(fullfile(MainPath, 'Results', session_name));
else
    if exist(RunFile, 'file') == 2
        choice = questdlg( [paradigm_name ' has been scanned!!!'], 'Warning!', 'Stop', 'Override', 'Stop');
        switch choice
            case 'Stop'
                return
        end
    end
end
%**************************************************************************

% Keyboard parameters
%**************************************************************************
Exit = KbName('q');                 % Press 'q' to quit
Start = KbName('s');                % Trigger from MR-scanner
%**************************************************************************

% fMRI parameters
%**************************************************************************
TR = 2.5;                           % TR (in seconds)
NumBlocks = 6;                      % Number of blocks in each repetition, i.e., number of conditions
nRep = 3;                           % Number of repetition in one run
EpochTime_Cond = 6;                 % Epoch time for each block (unit: TR)
EpochTime_Fix = 4;                  % Epoch time for each fix block (unit: TR)
NumDummies = 0;                     % Number of dummy TR's
%**************************************************************************

% General stimulus parameters
%**************************************************************************
nFrame = 60;                        % screen frash rate
BColor = [100 100 100];             % Background color
FixColor = [255 255 255];           % Color of fixation point
RectFix = 16;                       % Line Length
LineThick = 10;                     % Line Thickness, <=10
% durEachImage = 0.750;               % unit: s
% aftEachImage = 0.250;               % unit: s
% TotalImages = 15;                   % Number of images in each image category
% NumImages = 15;                     % Number of images in each block
% NumRep = 0;                         % Number of repeated images in each block
% FMT = 'tif' ;                       % Format of images
%**************************************************************************

% Grating stimulus parameters
%**************************************************************************
Grating_Switch = 3; % in second
color_list{1} = [228.11/255     0           0           1;100/255       100/255     100/255     1]; % red & background
color_list{2} = [0              112.65/255	0           1;100/255       100/255     100/255     1]; % green & background
color_list{3} = [86.24/255      86.24/255	0           1;100/255       100/255     100/255     1]; % yellow & background
color_list{4} = [128.14/255     128.14/255	128.14/255	1;57.39/255     57.39/255	57.39/255	1]; % gray contrast 75 & background
color_list{5} = [119.64/255     119.64/255	119.64/255	1;74.83/255     74.83/255	74.83/255	1]; % gray contrast 50 & background
color_list{6} = [110.38/255     110.38/255	110.38/255	1;88.53/255     88.53/255	88.53/255	1]; % gray contrast 25 & background

sigma = 0.5; % decide the shape of grating, now is trapezoid

% default x + y size
virtualSize = 450; % the overall size of the grating pannel
% radius of the disc edge
radius = floor(virtualSize/2); % if radius = 0, then the shape of grating is rectangle

% These settings are the parameters passed in directly to DrawTexture angle
angle = 0;

% spatial frequency
frequency = 0.1; % spatial frequency in cycles per pixel, the smaller the number, the thicker the grating

% contrast
contrast = 1; % contrast is the mixing amount from baseColor to color1 and color2.
%**************************************************************************

% Output variables
%**************************************************************************
PreLog = zeros(NumBlocks*2*nRep+2,3);         % Presentation log
% ResLog = cell(NumBlocks*nRep, NumImages+NumRep+1);         % Response log

RawTiming = [];      % All timing log
n = 1;               % RawTiming index
RawKb  = {};         % All kb log
m = 1;               % RawKb index
Key = 0;               % Keypress indicator
KeyCode_Prev = [];     % Last keycode
%**************************************************************************

try
    % Openning screens
    %**************************************************************************
    Screen('Preference', 'SkipSyncTests', 1);
    screens=Screen('Screens');
    WhichScreen = max(screens);
%     WhichScreen = 0;
    Window = Screen(WhichScreen, 'Openwindow');
    
    % Query frame duration: We use it later on to time 'Flips' properly for an
    % animation with constant framerate:
    ifi = Screen('GetFlipInterval', Window);

    % Enable alpha-blending
    Screen('BlendFunction', Window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%     load('Calibration_2606_P2317H_dis66_20180807.mat','gamInv','dacsize')
%     maxcol = 2.^dacsize-1;
%     ncolors = 256; % see details in makebkg.m, dacsize = 8; % How many bits per pixel
%     newcmap = rgb2cmapramp([.5 .5 .5],[.5 .5 .5],1,ncolors,gamInv,dacsize); % Make the gamma table we want
%     newclut(1:ncolors,:) = newcmap./maxcol;
%     oldclut = Screen('ReadNormalizedGammaTable',WhichScreen);
%     Screen('LoadNormalizedGammaTable', Window, newclut);

    [heightp, widthp] = Screen('WindowSize', Window);
    priorityLevel = MaxPriority(Window);
    HideCursor;
    Priority(priorityLevel);
%     slack = 0.5 * Screen('GetFlipInterval', Window);
    slack = 3 * Screen('GetFlipInterval', Window); % adjust this number to adjust the real stimuli dur

    imgFIX = BColor(1) * ones(256,256);
    CanvasFIX = Screen('MakeTexture', Window, imgFIX);
    %**************************************************************************
    
    % Waiting for trigger
    %**************************************************************************
    Screen('FillRect', Window, BColor);
%     Screen('DrawTexture', Window, CanvasNote);
    Screen('Drawline', Window, FixColor,heightp/2-RectFix,widthp/2,heightp/2+RectFix,widthp/2,LineThick);
    Screen('Drawline', Window, FixColor,heightp/2,widthp/2-RectFix,heightp/2,widthp/2+RectFix,LineThick);
    flipTime = Screen('Flip', Window);
    [~, ~, KeyCode] = KbCheck;
    while ~KeyCode(Start)
        [KeyIsDown, ~, KeyCode] = KbCheck;
        CheckKeyPress(KeyIsDown, KeyCode, Start, Exit);
    end;
    
    RunStartTime = GetSecs;
%     % communicate with ISCAN
    s1 = serial('COM4','BaudRate',9600);
    fopen(s1)
    s1.Status
    fwrite(s1,132) % start trigger 132
%     KeyCode_Prev = KeyCode;
%     RawTiming(n, 1) = KbTime; % Log starting time
    n = n + 1;
    Screen('Drawline', Window, FixColor,heightp/2-RectFix,widthp/2,heightp/2+RectFix,widthp/2,LineThick);
    Screen('Drawline', Window, FixColor,heightp/2,widthp/2-RectFix,heightp/2,widthp/2+RectFix,LineThick);
    Screen('Flip', Window);
    %**************************************************************************

    % Scanning phase
    %**************************************************************************
    DummyStartTime = GetSecs;
    while GetSecs-DummyStartTime < NumDummies*TR
        [KeyIsDown, ~, KeyCode] = KbCheck;
        CheckKeyPress(KeyIsDown, KeyCode, Start, Exit);
    end

%     tmp_img = randperm(TotalImages);                      % Randomize all images' NO.
    for run = 1:nRep                                         % nRep repitions each block in one run

        % Set block order
        RandomFactor1 = randperm(NumBlocks/2);
        RandomFactor2 = randperm(NumBlocks/2)+NumBlocks/2;
        BlockCondition = [0 RandomFactor1(1) 0 RandomFactor2(1) 0 RandomFactor1(2) 0 RandomFactor2(2) 0 RandomFactor1(3) 0 RandomFactor2(3)];
        PreLog(NumBlocks*2*(run-1)+1:NumBlocks*2*run,1) = BlockCondition;
        for Block = 1:numel(BlockCondition)
            BlockStartTime = GetSecs;
            if run == 1 && Block == 1
                PreLog(end-1,2) = BlockStartTime - RunStartTime;
            end
            kc = BlockCondition(Block);
            if kc == 0 % Fixation condition
                TrialTexture = CanvasFIX;
                Screen('FillRect', Window, BColor);
                Screen('DrawTexture', Window, TrialTexture);
                Screen('Drawline', Window, FixColor,heightp/2-RectFix,widthp/2,heightp/2+RectFix,widthp/2,LineThick);
                Screen('Drawline', Window, FixColor,heightp/2,widthp/2-RectFix,heightp/2,widthp/2+RectFix,LineThick);
                Screen('Flip', Window);
                while GetSecs-BlockStartTime < EpochTime_Fix*TR
                    [KeyIsDown, ~, KeyCode] = KbCheck;
                    r = CheckKeyPress(KeyIsDown, KeyCode, Start, Exit);
                end
            else
                color1 = color_list{kc}(1,:);
                color2 = color_list{kc}(2,:);
                                 
                phase = 0;  % phase
                
                Screen('FillRect', Window, BColor);
                % Build a procedural texture, we also keep the shader as we will show how to
                % modify it (though not as efficient as using parameters in drawtexture)
                texture = CreateProceduralColorGrating(Window, virtualSize, virtualSize, color1, color2, 0);

                % Preperatory flip
                vbl = Screen('Flip', Window); % the time when flip is done
                tstart = vbl + ifi; %start is on the next frame
                j=1;
                % target_start = clock;
%                 while vbl < tstart + EpochTime_Cond*TR-slack
                while j <= 900
                    % Draw a message
                    %     Screen('DrawText', Window, 'Standard Color Squarewave Grating', 10, 10, [1 1 1]);
                    % Draw the shader texture with parameters
                    Screen('DrawTexture', Window, texture, [], [],...
                    angle, [], [], BColor, [], [],...
                    [phase, frequency, contrast, sigma]);
                    Screen('Drawline', Window, FixColor,heightp/2-RectFix,widthp/2,heightp/2+RectFix,widthp/2,LineThick);
                    Screen('Drawline', Window, FixColor,heightp/2,widthp/2-RectFix,heightp/2,widthp/2+RectFix,LineThick);
                    %     imageArray2{i} = Screen('GetImage', Window); % 
                    vbl = Screen('Flip', Window, vbl + 0.5 * ifi);
                    %     phase = phase - 15;
                    if mod(j/(Grating_Switch*nFrame),2)>=1 % may affect the accuracy of timing
                        phase = phase - 4.5;  % if not 60 frames per second, then adjust 4.5, which is 0.75*360/the actual number of frames per second
                    else
                        phase = phase + 4.5;
                    end
                    j=j+1;
                end
                PreLog(NumBlocks*2*(run-1)+Block,3) = j;
            end
            BlockEndTime = GetSecs;
            PreLog(NumBlocks*2*(run-1)+Block,2) = BlockEndTime - BlockStartTime;
        end      
    end
    
    Screen('FillRect', Window, BColor);
    Screen('Drawline', Window, FixColor,heightp/2-RectFix,widthp/2,heightp/2+RectFix,widthp/2,LineThick);
    Screen('Drawline', Window, FixColor,heightp/2,widthp/2-RectFix,heightp/2,widthp/2+RectFix,LineThick);
    flipTime = Screen('Flip', Window);
    while GetSecs-BlockEndTime < (EpochTime_Fix+0)*TR % Fix block + additional 0 TR waiting for scanner end.
    end
    
    RunEndTime = GetSecs;
    PreLog(end,2) = RunEndTime - RunStartTime;
    
%     cell2mat(ResLog(:, end))
    save(RunFile, 'PreLog')
    %**************************************************************************

    ShowCursor; Priority(0);

    % Closing screens/Clearing memory
    %**********************************************************************
%     Screen('LoadNormalizedGammatable', Window, oldclut);
    Screen('CloseAll');
    fclose(s1)
    clear all;
    return;
    %**************************************************************************
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
%     cell2mat(ResLog(:, end))
    save(BreakRunFile, 'PreLog')
%     Screen('LoadNormalizedGammatable', Window, oldclut);
    Screen('CloseAll');
    fclose(s1)
    ShowCursor;
    rethrow(lasterror);
end %try..catch..

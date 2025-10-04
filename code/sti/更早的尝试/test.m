sca;
close all;
clear;

% Setup PTB with some default values
PsychDefaultSetup(2);
color1 = [1 0 0 1];

color2 = [0 1 0 1];

baseColor = [0.5 0.5 0.5 1];

% Setup defaults and unit color range:
PsychDefaultSetup(2);

% Disable synctests for this quick demo:
oldSyncLevel = Screen('Preference', 'SkipSyncTests', 2);

% Select screen with maximum id for output window:
screenid = 0;

% Open a fullscreen, onscreen window with gray background. Enable 32bpc
% floating point framebuffer via imaging pipeline on it, if this is possible
% on your hardware while alpha-blending is enabled. Otherwise use a 16bpc
% precision framebuffer together with alpha-blending. 
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[win, winRect] = PsychImaging('OpenWindow', screenid, baseColor);

% Query frame duration: We use it later on to time 'Flips' properly for an
% animation with constant framerate:
ifi = Screen('GetFlipInterval', win);

% % Set maximum priority level
% topPriorityLevel = MaxPriority(win);
% Priority(topPriorityLevel);



% Enable alpha-blending
Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% default x + y size
virtualSize = winRect(4) / 4;
% radius of the disc edge
radius = floor(virtualSize / 2);

% Build a procedural texture, we also keep the shader as we will show how to
% modify it (though not as efficient as using parameters in drawtexture)
texture = CreateProceduralColorGrating(win, virtualSize, virtualSize,...
     color1, color2, radius);


% These settings are the parameters passed in directly to DrawTexture
% angle
ensembleangle = 10;

% phase
phase = 0;
% spatial frequency
frequency = 0.01;
% contrast
contrast = 0.4;
% sigma < 0 is a sinusoid.
sigma = -3.0;

% Number of Gabors
numGabors = 4;

% Randomise the phase of the Gabors and make a properties matrix
propertiesMat = repmat([phase, frequency, sigma, contrast, 1, 0, 0, 0], numGabors, 1);
propertiesMat(:, 1) = rand(1, 4) * 360;

% Positions of the gabors
YgabShifts = [0.25 0.75] * winRect(4);
XgabShifts = [0.25 0.75] * winRect(3);
gaborsRects1 = nan(4, 2);
for i = 1:2
    gaborsRects1(:, i) = CenterRectOnPointd([0 0 virtualSize virtualSize], winRect(3)/2, YgabShifts(i));
    
end
gaborsRects2 = nan(4, 2);
for i = 1:2
    gaborsRects2(:,i) = CenterRectOnPointd([0 0 virtualSize virtualSize], XgabShifts(i), winRect(4)/2);
    
end
gaborsRects = [gaborsRects1, gaborsRects2];
%gaborsRects = [620,1160,890,890;470,470,200,740;760,1300,1030,1030;610,610,340,880];

% Preperatory flip
showTime = 3;
vbl = Screen('Flip', win);
vb0 = vbl;
tstart = vbl + ifi; %start is on the next frame
% We will update the stimulus on each frame
waitframes = 6;

% We choose an arbitary value at which our Gabor will drift
% phasePerFrame = 10;
angleperframe = 10;
i = 0;
timearray = [0;0];
movieFile = 'D:\Desktop\test\video.avi';
[movie, movieInfo] = Screen('OpenMovie', win, movieFile, [], [], 30); 
while ~KbCheck
    time = vbl - vb0;
    Screen('DrawText', win, 'Standard Color Sinusoidal Grating', 10, 10, [1 1 1]);
    i = i+1;
    if mod(i, 4) == 0
        if mod(i, 24) == 0
            ensembleangle = 120;   
            angle = [ensembleangle + randi([-2, 2])*10, ensembleangle + randi([-2 2])*10, ensembleangle + randi([-2 2])*10, ensembleangle + randi([-2 2])*10 ];
            Screen('DrawText', win, num2str(i), 10, 50, [1 1 0]);
            Screen('DrawText', win, num2str(time), 10, 100, [1 1 0]);
            timearray = [timearray [i;time]];
            Screen('DrawTextures', win, texture, [], gaborsRects,...
            angle, [], [], baseColor, [], [],...
            propertiesMat');
        else
            ensembleangle = 30;
            angle = [ensembleangle + randi([-2, 2])*10, ensembleangle + randi([-2 2])*10, ensembleangle + randi([-2 2])*10, ensembleangle + randi([-2 2])*10 ];
            Screen('DrawText', win, num2str(i), 10, 50, [1 0 1]);
            Screen('DrawText', win, num2str(time), 10, 100, [1 0 1]);
            timearray = [timearray [i;time]];
            Screen('DrawTextures', win, texture, [], gaborsRects,...
            angle, [], [], baseColor, [], [],...
            propertiesMat');
        end

    else
        ensembleangle = 10 + randi([-20, 20]);
        angle = [ensembleangle + randi([-2, 2])*10, ensembleangle + randi([-2 2])*10, ensembleangle + randi([-2 2])*10, ensembleangle + randi([-2 2])*10 ];
    % Draw a message
        Screen('DrawText', win, num2str(i), 10, 50, [1 1 1]);
        Screen('DrawText', win, num2str(time), 10, 100, [1 1 1]);
        timearray = [timearray [i;time]];
    % Draw the shader texture with parameters
    %Screen('DrawDots', win, [xCenter; yCenter], 10, black, [], 2);
        Screen('DrawTextures', win, texture, [], gaborsRects,...
        angle, [], [], baseColor, [], [],...
        propertiesMat');
    end

    vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * ifi);
    %propertiesMat(:, 1) = propertiesMat(:, 1) + ([-1; 1] * phasePerFrame);
    %angle(:,1) = angle(:,1) + angleperframe*randi([-4, 4])/10;
    
    
end
Screen('CloseMovie', movie);


%--- now we switch to a square wave grating using sigma >= 0
% if sigma is 0 then the squarewave is not smoothed, but if it is > 0 then
% hermite interpolation smoothing in +-sigma of the edge is performed.

% Close onscreen window, release all resources:
sca;

% Restore old settings for sync-tests:
Screen('Preference', 'SkipSyncTests', oldSyncLevel);

% Clear the workspace and the screen
sca;
close all;
clear;


color1 = [1 1 0 1];
color2 = [0 1 0 1];
baseColor = [0.5 0.5 0.5 1];

% Setup PTB with some default values
PsychDefaultSetup(2);
% Disable synctests for this quick demo:
oldSyncLevel = Screen('Preference', 'SkipSyncTests', 2);

% Set the screen number to the external secondary monitor if there is one
% connected
screenid = 0;

%open window，32bpc floating point framebuffer
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[win, winRect] = PsychImaging('OpenWindow', screenid, baseColor, [], 32, 2,...
    [], [],  kPsychNeed32BPCFloat);

% Get the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval', win);

% Set maximum priority level
topPriorityLevel = MaxPriority(win);
Priority(topPriorityLevel);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(winRect);

% Dimension of the region where will draw the Gabors in pixels
gaborDimPix = winRect(4) / 4;

% Sigma of Gaussian
sigma = -3.0;

% Obvious Parameters
orientation = 45;
contrast = 0.8;
phase = 0;

% Spatial Frequency (Cycles Per Pixel)
% One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
numCycles = 5;
freq = numCycles / gaborDimPix;

% Build a procedural texture, we also keep the shader as we will show how to
% modify it (though not as efficient as using parameters in drawtexture)
texture = CreateProceduralColorGrating(win, gaborDimPix, gaborDimPix,...
     color1, color2, gaborDimPix);

% Number of Gabors
numGabors = 2;

% Randomise the phase of the Gabors and make a properties matrix
propertiesMat = repmat([phase, freq, contrast, sigma], numGabors, 1);
propertiesMat(:, 1) = rand(1, 2) * 360;

% Positions of the gabors
gabShifts = [0.25 0.75] * winRect(4);
gaborsRects = nan(4, 2);
for i = 1:numGabors
    gaborsRects(:, i) = CenterRectOnPointd([0 0 gaborDimPix gaborDimPix], winRect(3) / 2, gabShifts(i));
end

% Preperatory flip
showTime = 8;
vbl = Screen('Flip', win);
% We will update the stimulus on each frame
waitframes = 1;
tstart = vbl + ifi; %start is on the next frame
phasePerFrame = 4 * pi;

while vbl < tstart + showTime
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', win, 'GL_ONE', 'GL_ZERO');

    % Draw the Gabor. By default PTB will draw this in the center of the screen
    % for us.
    Screen('DrawTextures', win, texture, [], gaborsRects, orientation, [], [], baseColor, [],...
        kPsychDontDoRotation, propertiesMat');
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Draw the fixation point
    Screen('DrawDots', win, [xCenter; yCenter], 10, BlackIndex(screenid), [], 2);

    % Flip to the screen
    vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * ifi);

    % Update the phase element of the properties matrix (we could if we
    % want update any or all of the properties on each frame. Here the
    % Gabor will drift to the left.
    

end

% Clear screen
sca;

% Restore old settings for sync-tests:
Screen('Preference', 'SkipSyncTests', oldSyncLevel);

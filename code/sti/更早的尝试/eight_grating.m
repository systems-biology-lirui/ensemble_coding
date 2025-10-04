function ProceduralColorGratingDemo(color1,color2,baseColor)

if ~exist('color1','var') || isempty(color1)
    color1 = [1 0 0 1];
end

if ~exist('color2','var') || isempty(color2)
    color2 = [0 0 1 1];
end

if ~exist('baseColor','var') || isempty(baseColor)
    baseColor = [0.5 0.5 0.5 1];
end

PsychDefaultSetup(2);
oldSyncLevel = Screen('Preference', 'SkipSyncTests', 2);
screenid = 0;
black = BlackIndex(screenid);

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[win, winRect] = PsychImaging('OpenWindow', screenid, baseColor);


ifi = Screen('GetFlipInterval', win);

% Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% default x + y size
virtualSize = 512;
% radius of the disc edge半径
radius = floor(virtualSize / 2);

topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

[xCenter, yCenter] = RectCenter(winRect);

gaborDimPix = winRect(4) / 4;

% Sigma of Gaussian
sigma = -3.0;

% Obvious Parameters
orientation = rand(1,2) .* 180;
contrast = 0.5;
% aspectRatio = 1;
phase = 0;

% Spatial Frequency (Cycles Per Pixel)
% One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
numCycles = 5;
freq = numCycles / gaborDimPix;

% Build a procedural gabor texture (Note: to get a "standard" Gabor patch
% we set a grey background offset, disable normalisation, and set a
% % pre-contrast multiplier of 0.5).
% backgroundOffset = [0.5 0.5 0.5 0.0];
% disableNorm = 1;
% preContrastMultiplier = 0.5;
%构建单个光栅
gabortex = CreateProceduralColorGrating(win, virtualSize, virtualSize,...
     color1, color2, radius);

%构建多个光栅
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


showTime = 8;
vbl = Screen('Flip', win);
tstart = vbl + ifi;
phasePerFrame = 162;%需要改一下
waitframes = 3;

while ~KbCheck
    % Set the right blend function for drawing the gabors
%     Screen('BlendFunction', win, 'GL_ONE', 'GL_ZERO');

    % Draw the Gabor. By default PTB will draw this in the center of the screen
    % for us.
    Screen('DrawTextures', win, gabortex, [], gaborsRects, orientation, [], [], [], [],...
        kPsychDontDoRotation, propertiesMat');

    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Draw the fixation point
    Screen('DrawDots', win, [xCenter; yCenter], 10, black, [], 2);

    % Flip to the screen
    vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * ifi);

    % Update the phase element of the properties matrix (we could if we
    % want update any or all of the properties on each frame. Here the
    % Gabor will drift to the left.
    %propertiesMat(:, 1) = propertiesMat(:, 1) + ([-1; 1] * phasePerFrame);
    orientation = orientation + 10;
end
sca;

% Restore old settings for sync-tests:
Screen('Preference', 'SkipSyncTests', oldSyncLevel);

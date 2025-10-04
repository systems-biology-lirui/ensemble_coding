% Clear the workspace and the screen
sca;
close all;
clear;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = 0;

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
inc = white - grey;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set up alpha-blending for smooth (anti-aliased) lines



% Dimension of the region where will draw the Gabors in pixels
gaborDimPix = 100;

% Sigma of Gaussian
sigma = gaborDimPix / 7;

% Obvious Parameters
orientation = 0;
contrast = 0.9;
aspectRatio = 1.0;
phase = 0;

% Spatial Frequency (Cycles Per Pixel)
% One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
numCycles = 5;
freq = numCycles / gaborDimPix;

% Build a procedural gabor texture (Note: to get a "standard" Gabor patch
% we set a grey background offset, disable normalisation, and set a
% pre-contrast multiplier of 0.5).
backgroundOffset = [0.5 0.5 0.5 0.0];
disableNorm = 1;
preContrastMultiplier = 0.9;
gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
    backgroundOffset, disableNorm, preContrastMultiplier);

numGabors = 8;
propertiesMat = repmat([phase, freq, sigma, contrast, aspectRatio, 0, 0, 0], numGabors, 1);
%空格位置

%4*4方形
% gaborsRects = [560 ,560, 560, 560, 760, 760, 760, 760, 960, 960, 960, 960, 1160, 1160, 1160, 1160;
%     140, 340, 540, 740, 140, 340, 540, 740, 140, 340, 540, 740, 140, 340, 540, 740;
%     760, 760, 760, 760, 960, 960, 960, 960, 1160, 1160, 1160, 1160, 1360, 1360, 1360, 1360;
%     340, 540, 740, 940, 340, 540, 740, 940, 340, 540, 740, 940, 340, 540, 740, 940,];

%环形
% gaborsRects = [460, 710, 1110, 1320, 860, 860, 860, 860, 690, 690, 1330,1330;
%     440, 440, 440, 440, 40, 290, 590, 840, 270, 610, 270, 610;
%     690, 910, 1310, 1520, 1060, 1060, 1060, 1060, 890, 890, 1530, 1530;
%     640, 640, 640, 640, 240, 490, 790, 1040, 470, 810, 470, 810];

%3*3方形
% gaborsRects = [660, 660, 660, 860, 860, 860, 1060, 1060, 1060;
%     240, 440, 640, 240, 440, 640, 240, 440, 640;
%     860, 860, 860, 1060, 1060, 1060, 1260, 1260, 1260;
%     440, 640, 840, 440, 640, 840, 440, 640, 840];

%真环形
circles_out = [
    0, 348;
    331, 108;
    204, -282;
    -331, 108;
    -204, -282;
];
circles_in = [
    110, 64;
    -110, 64;
    0, -128
];



% We will update the stimulus on each frame
waitframes = 100;
blackframe = 4;

% % We choose an arbitary value at which our Gabor will drift
% i=0;
vbl = Screen('Flip', window);
vb0 = vbl;
imageArray = zeros(1080, 1920, 3, 'double');
recordmatrix2 = zeros(5,8,'double');
%循环获得图片
for i = 1:36
    
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
%      i=i+1;
%     if mod(i, 2) == 0
%         Screen('FillRect', window, grey)
%         vbl = Screen('Flip', window, vbl + (blackframe - 0.5) * ifi);
% 
%     else
    % 获得随机位置矩阵
    
    %获得随机方向矩阵
    randomOrderO = i;
    %for a = 1:3
        time = vbl -vb0;
        angle_random_out = randi(360);
        angle_random_in = randi(360);
        circles = rotatePoints(circles, angle_random);
        gaborsRects_out = calculateCircleBoundaries(circles_out, 100);
        gaborsRects_in = calculateCircleBoundaries(circles_in, 100);
        randomOrderL = randperm(8);
        randomSelectionL_out = randomOrderL(1:5);
        randomSelectionL_in = randomOrderL(6:8);
        newgaborMatrix_out = gaborsRects_out(:, randomSelectionL_out);
        newgaborMatrix_in = gaborsRects_in(:,randomSelectionL_in);
        ra= randperm(40)+randomOrderO*5-20;
        randomSelectionO_out = ra(1:5);
        randomSelectionO_in = ra(6:8);
        Screen('DrawTextures', window, gabortex, [], newgaborMatrix_out, randomSelectionO_out, [], [], [], [],...
        kPsychDontDoRotation, propertiesMat');
        Screen('DrawTextures', window, gabortex, [], newgaborMatrix_in, randomSelectionO_in, [], [], [], [],...
        kPsychDontDoRotation, propertiesMat');
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        recordmatrix1 = cat(1, newgaborMatrix,randomSelectionO);
        recordmatrix2 = cat(3, recordmatrix2,recordmatrix1);
        imageArray1 = Screen('GetImage', window, [], [], 1, []);
        %%imageArray = cat(4,imageArray,imageArray1);
    
        filename = sprintf('circle20_%d.jpeg', i*5);
        fullpath = fullfile('D:\Desktop\test\', filename);
%         imwrite(imageArray1, fullpath);
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);

    %end
      
        
%      end
end



save('recordmatrixsquare_30.mat', "recordmatrix2")
% Clear the screen
sca;

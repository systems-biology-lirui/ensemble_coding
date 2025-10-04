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

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
[xCenter, yCenter] = RectCenter(windowRect);
% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% 十字注视点
fixCrossDimPix = 10;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% 线粗
lineWidthPix = 2;
% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window
% [xCenter, yCenter] = RectCenter(windowRect);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Here we load in an image from file. This one is a image of rabbits that
% is included with PTB

% Determine the scaling needed to make the rabbit image fill the whole
% screen in the y dimension
% maxScaling = screenYpixels / s1;

% Our square will oscilate with a sine wave function to the left and right
% of the screen. These are the parameters for the sine wave
% See: http://en.wikipedia.org/wiki/Sine_wave
% amplitude = maxScaling;
% frequency = 0.1;
% angFreq = 2 * pi * frequency;
% startPhase = 0;

% Flip each frame
waitframes = 30;
blackframes = 2;
time = 0;

% Maximum priority level
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Get an initial timestamp
vbl = Screen('Flip', window);
vb0 = vbl;
timematrix = zeros(2,1,'double');
% moviePtr = Screen('CreateMovie', window, 'rotatingSquaresDemo.mp4', ...
%     [], [], [], ':CodecType=avenc_mpeg4');
% Endless loop in which we scale the size of the texture
% while ~KbCheck
%     Screen('DrawLines', window, allCoords,...
%     lineWidthPix, white, [xCenter yCenter], 2);
for i = 1:150
    if i == 1
        c= randi(3);
        filename = sprintf('circle10_100_%d.jpeg', c);
        %filename = sprintf('com_large_%d_0%d.bmp', (a, b));
        %filename = sprintf(name_try);
        fullpath = fullfile('D:\Desktop\circle_10_0_10\', filename);
        theImage = imread(fullpath);
        % Get the size of the image
        [s1, s2, s3] = size(theImage);
        % Make the image into a texture
        imageTexture = Screen('MakeTexture', window, theImage);

        % Set the based rectangle size for drawing to the screen
        baseRect = CenterRectOnPointd([0 0 s2 s1] .* 0.5,700 , 700);

        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.
        Screen('DrawTexture', window, imageTexture, [], baseRect, 0);
        %         Screen('DrawLines', window, allCoords,...
        %     lineWidthPix, black, [xCenter yCenter], 2);
        % Get an initial screen flip for timing
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);

        % Increment the time
        time = vbl -vb0;
        timematrix1 = [i;time];
        timematrix = cat(2, timematrix, timematrix1);

    elseif mod(i, 2) == 0
        

        Screen('FillRect', window, grey)
        %         Screen('DrawLines', window, allCoords,...
        %     lineWidthPix, black, [xCenter yCenter], 2);
        vbl = Screen('Flip', window, vbl + (blackframes - 0.5) * ifi);
        time = vbl -vb0;
        timematrix1 = [i;time];
        timematrix = cat(2, timematrix, timematrix1);
        
    elseif mod(i-2, 7) == 0
        c= randi(3);
        filename = sprintf('circle10_100_%d.jpeg',c);
        %filename = sprintf('com_large_%d_0%d.bmp', (a, b));
        %filename = sprintf(name_try);
        fullpath = fullfile('D:\Desktop\circle_10_0_10\', filename);
        theImage = imread(fullpath);
        % Get the size of the image
        [s1, s2, s3] = size(theImage);
        % Make the image into a texture
        imageTexture = Screen('MakeTexture', window, theImage);

        % Set the based rectangle size for drawing to the screen
        baseRect = CenterRectOnPointd([0 0 s2 s1] .* 0.5,700 , 700);

        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.
        Screen('DrawTexture', window, imageTexture, [], baseRect, 0);
        %         Screen('DrawLines', window, allCoords,...
        %     lineWidthPix, black, [xCenter yCenter], 2);
        % Get an initial screen flip for timing
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);

        % Increment the time
        time = vbl -vb0;
        timematrix1 = [i;time];
        timematrix = cat(2, timematrix, timematrix1);
    else
        a = (randi(17)+1)*10;
        if a == 100
            a = a + 10;
        end
        %a = num2str(randi(22)/10);
        b = randi(3);
        
        % Image scale on this frame. We use abs as negative scaling makes no
        % sense. The scaling will never get larger than the maximum needed for
        % the image to be fully screen height.
        % theScale = abs(amplitude * sin(angFreq * time + startPhase));
        %name_try=['com_large_',a,'_0',b,'.bmp'];
        filename = sprintf(['circle10_',num2str(a),'_',num2str(b),'.jpeg']);
        %filename = sprintf('circle10_%d_.jpeg', a);
        %filename = sprintf('com_large_%d_0%d.bmp', (a, b));
        %filename = sprintf(name_try);
        fullpath = fullfile('D:\Desktop\circle_10_0_10\', filename);
        theImage = imread(fullpath);
        % Get the size of the image
        [s1, s2, s3] = size(theImage);
        % Make the image into a texture
        imageTexture = Screen('MakeTexture', window, theImage);
    
        % Set the based rectangle size for drawing to the screen
        baseRect = CenterRectOnPointd([0 0 s2 s1] .* 0.5,700 , 700);
    
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.
        Screen('DrawTexture', window, imageTexture, [], baseRect, 0);
%         Screen('DrawLines', window, allCoords,...
%     lineWidthPix, black, [xCenter yCenter], 2);
        % Get an initial screen flip for timing
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    
        % Increment the time
        time = vbl -vb0;
        timematrix1 = [i;time];
        timematrix = cat(2, timematrix, timematrix1);
    end
end

% Clear the screen
sca;

% Clear the workspace and the screen
sca;
close all;
clear;
%%
varience = 20;
orientation_step = 5;
gabor_num = 8;
gabor_out_num = 5;
gabor_in_num = 3;

%%
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = 0;
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
[xCenter, yCenter] = RectCenter(windowRect);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);


ifi = Screen('GetFlipInterval', window);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Flip each frame
waitframes = 100;
blackframes = 10;
time = 0;

% Maximum priority level
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Get an initial timestamp
vbl = Screen('Flip', window);
vb0 = vbl;
timematrix = zeros(2,1,'double');
circles = [
        0, 348;
        331, 108;
        204, -282;
        -331, 108;
        -204, -282;
        110, 64;
        -110, 64;
        0, -128
        ];
circles_win = zeros(8,2);
circles_win(:,1) = circles(:,1)+960;
circles_win(:,2) = 540 - circles(:,2);
filename = sprintf('gabor.png');
fullpath = fullfile('D:\Desktop\', filename);
theImage = imread(fullpath);
imageArray = zeros(1080, 1920, 3, 'double');
for i = 1:(180/orientation_step)

    o = randperm(2*varience) + i - varience;
    ol = o(1:(gabor_num/2));
    or = 2*i*orientation_step - ol(1:4);
    o = cat(2, or, ol);
    l = length(o);
    ranorder = randperm(l);
    o = o(ranorder);
%     randomSelectionO_out = o(1:gabor_out_num);
%     randomSelectionO_in = o((gabor_out_num+1):(gabor_out_num+gabor_in_num));
    
    % Get the size of the image
    [s1, s2, s3] = size(theImage);
    % Make the image into a texture
    imageTexture = Screen('MakeTexture', window, theImage);
    for m =1:8
        baseRect = CenterRectOnPointd([0 0 s2 s1] .* 0.3, circles_win(m,1), circles_win(m,2));
        Screen('DrawTexture', window, imageTexture, [], baseRect, o(m));
    end

    %Screen('DrawTextures', window, imageTexture, [], baseRect, o);
    %Screen('DrawTextures', window, imageTexture, [], baseRects, o, [], [], [], [],...
%        kPsychDontDoRotation, propertiesMat');
    vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    time = vbl -vb0;
    timematrix1 = [i;time];
    timematrix = cat(2, timematrix, timematrix1);
    %Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
%     % 光栅信息的记录
%     recordmatrix1 = cat(1, gaborsRects,randomSelectionO);
%     recordmatrix2 = cat(3, recordmatrix2 , recordmatrix1);
%     imageArray1 = Screen('GetImage', window, [], [], 1, []);
%     imageArray = cat(4,imageArray,imageArray1);
    
%     绘制图片
    filename = sprintf('circle8_%d.jpeg', i*orientation_step);
    fullpath = fullfile('D:\Desktop\circle_eight\', filename);
    imwrite(imageArray1, fullpath);
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
end


% Clear the screen
sca;

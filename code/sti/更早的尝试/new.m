% 本实验的目的是为了探究V1是否会表现出整体朝鲜内阁编码的SSVEP，刺激的方式是
% 采用多个朝向变化的反相光栅，并在每个固定变化次数后发生平均朝向的变化。每个
% session 设置为两个block，分别为单个光栅的刺激和多个光栅的刺激，每个block
% 有n个trail，一个trail中包括500ms的注视，2个1s的刺激和0.5s的刺激间隔。
% 在光栅刺激呈现过程中，光栅会随机出现在感受野范围内。

sca;
close all;
clear;

%实验设计
%面对显示器的距离，单位为cm
distance = 80;
%显示器的尺寸
monitorsize = 11;
%背景颜色
background = [130 130 130];
%感受野位置
RFcenter = [768 648];
RFdim = 100;

%--------------
%构建背景
screenid = 0;

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[window, windowRect] = PsychImaging('OpenWindow', screenid, background);
[xCenter, yCenter] = RectCenter(windowRect);

%--------------------------
%%构建元素
%---------------------------

%注视点，设定为24min弧度值，在屏幕中心
%注视点大小，这里简化了一下，实际上我们要知道显示器的尺寸
perimeter = distance * pi * 2;
fixCrossDimPix = perimeter/ 360 / 60 * 24;
fixCrossDimPix = fixCrossDimPix / monitorsize * round(sqrt(windowRect(4)^2 +windowRect(3)^2));
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
% 线粗
lineWidthPix = 4;

%---------------------------
% 光栅
%单个光栅大小，设置为2°
singleg = perimeter / 360 * 2;
singlegaborDimpix = singleg / round(sqrt(windowRect(4)^2 +windowRect(3)^2));

%多个光栅大小，设置为0.5°
multig = perimeter/ 720;
multigaaborDixpix = multi/monitorsize;


%光栅参数
orientation = 0;
contrast = 0.8;
aspectRatio = 1.0;
phase = 0;

%光栅空间频率
numCycles = 5;
freq = numCycles / singlegaborDimPix;
backgroundOffset = [0.5 0.5 0.5 0.0];

%光栅的构建
disableNorm = 1;
preContrastMultiplier = 0.5;
gabortex = CreateProceduralGabor(window, singlegaborDimpix, singlegaborDimPix, [],...
    backgroundOffset, disableNorm, preContrastMultiplier);


% 光栅数量
numGabors = 2;

% 光栅的参数
propertiesMat = repmat([phase, freq, sigma, contrast, aspectRatio, 0, 0, 0], numGabors, 1);
propertiesMat(:, 1) = rand(1, 2) * 360;


% 多光栅的位置
gabShifts = [0.25 0.75] * windowRect(4);
multigaborsRects = nan(4, 2);
for i = 1:numGabors
    gaborsRects(:, i) = CenterRectOnPointd([0 0 gaborDimPix gaborDimPix], windowRect(3) / 2, gabShifts(i));
end

vbl = Screen('flip',window);
while ~KbCheck
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
    %300ms的注视点，绘制十字注视点，可以修改中心位置改变注视点所在
    Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);
    %300ms以后，开始放持续3s的刺激，单个光栅
    vbl = Screen

   
    

 
sca;
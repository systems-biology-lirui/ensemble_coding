%% Clear the workspace and the screen
sca;
close all;
clear;
PsychDefaultSetup(2);

%% 设定参数
model = 1;           %光栅排列方式：1-环形；2-双环形；3-3*3方形；4-4*4方形；

%% 单个光栅基本参数
numCycles = 1.5;
gaborDimPix = 60;        %光栅的绘制范围
freq = numCycles / gaborDimPix;%光栅空间频率
sigma = 20; %高斯包络              
contrast = 0.9;
aspectRatio = 1.0;


%%光栅朝向 
varience = 10;       %单个光栅的变化幅度
orientation_step =1; %光栅朝向的分辨率


%% 光栅位置调整
gabor_out_num = 5;   %外圆环的数量
gabor_in_num = 3;    %内圆环的数量
distance_out=80; %想要缩进的距离
distance_in=0;   %想要缩进的距离

rotate_jitter_out = 40;  %外侧单圆环的旋转偏差，默认为最大
rotate_jitter_in = 30;    %内侧单圆环的旋转偏差，默认为最大
jitter_out = 0.4;                                 %圆环的位置偏移
jitter_in = 0.1;

%% 帧数
waitframes = 20;    %等待帧
blackframe = 4;      %空白帧


%% 显示器
%显示器选择
screens = Screen('Screens');
screenNumber = 0;

%绘制灰白背景
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

%屏幕尺寸
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);

%% 单个光栅绘制区域
back = 221/256;
backgroundOffset = [0.5 0.5 0.5 1.0];
disableNorm = 1;
preContrastMultiplier = 0.9;
gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
    backgroundOffset, disableNorm, preContrastMultiplier);
%单光栅参数矩阵


%%model
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






%% 模板位点
circles_out_template = [
    0, 348;
    331, 108;
    204, -282;
    -331, 108;
    -204, -282;
];
circles_in_template = [
    110, 64;
    -110, 64;
    0, -128
];
circleone = [0, 0];

distance_times_out=(350-distance_out)/350;
distance_times_in=(350-distance_in)/350;
circles_out=circles_out_template*distance_times_out;
circles_in=circles_in_template*distance_times_in;



%% 屏幕刷新
ifi = Screen('GetFlipInterval', window);
vbl = Screen('Flip', window);
vb0 = vbl;
imageArray_60 = zeros(1080, 1920, 3, 'double');
recordmatrix2 = zeros(5,8,'double');

%% 循环获得图片
for p = 1:6

    phase = p*30;
    propertiesMat = repmat([phase, freq, sigma, contrast, aspectRatio, 0, 0, 0], gabor_out_num+gabor_in_num, 1);
    for i = 1:(180/orientation_step+1)
        randomOrderO = i;
        time = vbl -vb0;
        Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
        circles_out_template = [
            0, 348;
            331, 108;
            204, -282;
            -331, 108;
            -204, -282;
            ];
        circles_in_template = [
            110, 64;
            -110, 64;
            0, -128
            ];

        distance_times_out=(350-distance_out)/350;
        distance_times_in=(350-distance_in)/350;
        circles_out=circles_out_template*distance_times_out;
        circles_in=circles_in_template*distance_times_in;

        %% 双环
        if model == 2
            %% black
            %       i=i+1;
            %       if mod(i, 2) == 0
            %           Screen('FillRect', window, grey)
            %           vbl = Screen('Flip', window, vbl + (blackframe - 0.5) * ifi);
            %
            %       else

            %% 外环
            angle_random_out = randi(360);
            angle_matrix_out = zeros(gabor_out_num, 1);
            %         for m = 1:gabor_out_num
            %
            % %              if rotate_jitter_out ~= round(180/gabor_out_num)
            % %                  angle_matrix_out(m) = angle_random_out-2*round(rotate_jitter_out) +randi(round(rotate_jitter_out));
            % %              else
            % %                  angle_matrix_out(m) = angle_random_out-round(180/gabor_out_num) +randi(round(360/gabor_out_num));
            % %              end
            %             circles_out(m,1) = circles_out(m,1) + randi(gaborDimPix*jitter_out*2) - gaborDimPix*jitter_out;
            %             circles_out(m,2) = circles_out(m,2) + randi(gaborDimPix*jitter_out*2) - gaborDimPix*jitter_out;
            %         end
            circles_out = rotatePoints(circles_out, angle_matrix_out);
            gaborsRects_out = calculateCircleBoundaries(circles_out*0.5, 50);


            %% 内环
            angle_random_in = randi(360);
            angle_matrix_in = zeros(gabor_in_num, 1);
            %         for m = 1:gabor_in_num
            % %              if rotate_jitter_in ~= round(180/gabor_in_num)
            % %                  angle_matrix_in(m) = angle_random_out-2*round(rotate_jitter_in) +randi(round(rotate_jitter_in));
            % %              else
            % %                  angle_matrix_in(m) = angle_random_in-round(180/gabor_in_num) +randi(round(360/gabor_in_num));
            % %              end
            %             circles_in(m,1) = circles_in(m,1) + randi(gaborDimPix*jitter_in*2) - gaborDimPix*jitter_in;
            %             circles_in(m,2) = circles_in(m,2) + randi(gaborDimPix*jitter_in*2) - gaborDimPix*jitter_in;
            %         end
            circles_in = rotatePoints(circles_in, angle_matrix_in);
            gaborsRects_in = calculateCircleBoundaries(circles_in*0.5, 60);



            %% 每个光栅的方向
            ra= randperm(2*varience)+randomOrderO*orientation_step-varience;
            randoml = ra(1:4);
            randomr = 2*randomOrderO*orientation_step - ra(1:4);
            ra = cat(2, randoml, randomr);
            l = length(ra);
            ranorder = randperm(l);
            ra = ra(ranorder);
            randomSelectionO_out = ra(1:gabor_out_num);
            randomSelectionO_in = ra((gabor_out_num+1):(gabor_out_num+gabor_in_num));

            %% 内外矩阵合并
            gaborsRects = cat(2, gaborsRects_out, gaborsRects_in);
            randomSelectionO = cat(2, randomSelectionO_out, randomSelectionO_in);
            %    elseif model == 3
            %       randomOrderL = randperm(8);
            %       randomSelectionL_out = randomOrderL(1:5);
            %       randomSelectionL_in = randomOrderL(6:8);
            %       newgaborMatrix_out = gaborsRects_out(:, randomSelectionL_out);
            %       newgaborMatrix_in = gaborsRects_in(:,randomSelectionL_in);


        elseif model == 1
            % circles_out = rotatePoints(circleone, angle_matrix_out);
            gaborsRects = calculateCircleBoundaries(circleone, 25);
            randomSelectionO = i *orientation_step;

        end
        %% 光栅的生成
        Screen('DrawTextures', window, gabortex, [], gaborsRects, randomSelectionO, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

        % 光栅信息的记录
        %     recordmatrix1 = cat(1, gaborsRects,randomSelectionO);
        %     recordmatrix2 = cat(3, recordmatrix2 , recordmatrix1);
        imageArray1 = Screen('GetImage', window, [], [], 1, []);
        %imageArray = cat(4,imageArray,imageArray1);

        %     绘制图片
        filename = sprintf('circle_1.6_%d_%d.jpeg', phase, (i-1)*orientation_step);
        fullpath = fullfile('D:\Desktop\test4\', filename);
        imwrite(imageArray1(520:570,930:990,:), fullpath);
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);


    end
end




save('recordmatrixsquare_30.mat', "recordmatrix2")
% Clear the screen
sca;

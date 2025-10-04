function zzj_single_line_train(Date_Gender_Num_Name_single_line_type)
clear clc
%%
try
tic
exp_start=clock;
commandwindow;
warning('off','MATLAB:DeprecatedLogicalAPI');
warning('off','MATLAB:dispatcher:InexactMatch');
rng('shuffle');
HideCursor

%mainpath
pathname='D:\zzj\';

if isdir(pathname)
	MainPath = pathname;
else
    mkdir(pathname);
end
KbName('UnifyKeyNames')
Exit = KbName('q');         % Press 'q' to quit
Start = KbName('s');        % press 's' to starta
ResultFile = fullfile([MainPath,'single_line_train\'],[Date_Gender_Num_Name_single_line_type '.mat']);  

%% 
%**************************************************************************
% General images parameters
%**************************************************************************
Screen('Preference','SkipSyncTests',1);
[Window, wrect]= Screen(2,'OpenWindow');
slack = 0.5 * Screen('GetFlipInterval', Window);

bcolor = [128 128 128];               % background color
refresh_rate = 100; 
fixation_dur = 50/refresh_rate-slack;
prime_dur = 10/refresh_rate; 
prime_fix_dur=10/refresh_rate-slack;
prime_dur2=10/refresh_rate-slack;
feedback_dur=10/refresh_rate-slack; 
wait_response_target = 10;
baseITI = 1;
left  = KbName('UpArrow');
right = KbName('DownArrow');  
Keys = [left right];

% Define the center coordinates
[x_center, y_center] = RectCenter(wrect);

first_downstepSize = 30;
first_upstepSize = 20;
second_downstepSize = 15;
second_upstepSize = 10;
third_downstepSize = 2;
third_upstepSize = 1;

%% create stimuli
load([MainPath,'test_dis.mat'])
load([MainPath,'presentation_single_line.mat'])
load([MainPath,'intro_train_single_line.mat'])
load([MainPath,'wrong.mat']) 
load([MainPath,'rest.mat'])
load([MainPath,'finish.mat'])
%*********************************** 
%% need to change

nTrials= 1000;
startingCoherence_gap = 200;
single_line_final = presentation_single_line;


%% staircase
priorityLevel = MaxPriority(Window); 
Priority(priorityLevel);
Screen('FillRect',Window ,bcolor);  
txttexture = Screen('MakeTexture',Window,intro_train_single_line); % Introduction
Screen('DrawTexture',Window,txttexture);

Screen('Flip',Window);
QuitFlag = 0;
while ~QuitFlag
    [KeyIsDown,~,KeyCode] = KbCheck;
    if KeyIsDown && KeyCode(Start)
        QuitFlag = 1;
    end
end
pause(1)

%% staircase
results.intensity = NaN*ones(1,nTrials);  %to  be filled in after each trial
results.response = NaN*ones(1,nTrials);   %to  be filled in after each trial
%test_train_judge
RESULTS_TOT = {};
    results = {};
    reaction_time=[];%this parameter keeps track of the number of correct responses in a row
correctInaRow = 0;
times=[];
reversal=0;
 %record the clock time at the beginning
startTime = GetSecs;

level = size(single_line_final,1);
trialNum=1  
Flag=true;
upstepSize = first_upstepSize;
downstepSize = first_downstepSize;

while Flag == true
        column_num = randi([1 4],1)
        rownum = level
        prime_cell = single_line_final{rownum,column_num*2+1}; 
        prime_1 = prime_cell{1,1};
        primetexture_1 = Screen('MakeTexture',Window,prime_1);
        prime_2 = prime_cell{1,2};
        primetexture_2 = Screen('MakeTexture',Window,prime_2);

        % presentation fixation
        Screen('FillRect', Window, bcolor);
        Screen('DrawDots', Window, [x_center; y_center], 15, [255,0,0], [], 1);
        Screen('Flip',Window); 
        fixation_start = clock;
        WaitSecs(fixation_dur);
              
        
        % presentation prime
        Screen('FillRect', Window, bcolor);
        Screen('DrawTexture',Window,primetexture_1); 
        Screen('DrawDots', Window, [x_center; y_center], 15, [255,0,0], [], 1);
        Screen('Flip',Window);
        prime_start = clock;
        WaitSecs(prime_dur);
        reaction_time(trialNum,1) = etime(prime_start,fixation_start);  % fixation last time        
            
        % presentation fixation2
        Screen('FillRect', Window, bcolor);
        Screen('DrawDots', Window, [x_center; y_center], 15, [255,0,0], [], 1);
        Screen('Flip',Window); 
        fixation_start2 = clock;
        WaitSecs(prime_fix_dur);
        reaction_time(trialNum,2) = etime(fixation_start2,prime_start);  % prime1 last time   
        
        % presentation prime
        Screen('FillRect', Window, bcolor);
        Screen('DrawTexture',Window,primetexture_2); 
        Screen('DrawDots', Window, [x_center; y_center], 15, [255,0,0], [], 1);
        Screen('Flip',Window);
        prime_start2 = clock;
        WaitSecs(prime_dur2);
        reaction_time(trialNum,3) = etime(prime_start2,fixation_start2);  % fixation2 last time  
        
        % waiting for response(target)
        Screen('FillRect', Window, bcolor);
        Screen('DrawDots', Window, [x_center; y_center], 15, [255,0,0], [], 1);
        Screen('Flip',Window); 
        pause_stop = clock;
        judge_key=0;
        %Interpret the response provide feedback and deal with
        results.intensity(trialNum) = rownum;
        results.intensityjudge(trialNum) = single_line_final{rownum,column_num*2};
                

        while etime(clock,pause_stop) < wait_response_target && ~judge_key
            [KeyIsDown,~,KeyCode] = KbCheck;
             judge_key=CheckKeyPress(KeyIsDown, KeyCode, Start, Exit);
            judge_time = etime(clock,pause_stop);
        end
        reaction_time(trialNum,4) = etime(pause_stop,prime_start2);  % prime2 presentaion time  
        reaction_time(trialNum,5) = judge_time; % response last time             

        choice_direction = single_line_final{rownum,column_num*2}
            %correct response
            if (find(Keys==judge_key)==1 & choice_direction == 2) | (find(Keys==judge_key)==2 & choice_direction == 1)
                results.response(trialNum) = 1
                correctInaRow = correctInaRow +1
                 if correctInaRow == 3
                    level = level-downstepSize;
                    level = min(level,startingCoherence_gap);
                    position=size(times,2)+1;
                    times(position)=1;
                    correctInaRow = 0;
                end
                
            %Incorrect response
            elseif (find(Keys==judge_key)==1 & choice_direction == 1) | (find(Keys==judge_key)==2 & choice_direction == 2)
                results.response(trialNum) = 0
                level = level+upstepSize;
                level = min(level,startingCoherence_gap);
                correctInaRow = 0
                position=size(times,2)+1;
                times(position)=0;
                Screen('FillRect', Window, bcolor);
                txt=Screen('MakeTexture',Window,wrong);
                Screen('DrawTexture',Window,txt);
            else
                results.response(trialNum) = NaN;    
               %Note, for wrong keypresses, don't update the staircase parameters
            end

            Screen('Flip',Window);
            WaitSecs(feedback_dur);
       
            %record the reversal times
            lengthnumber=size(times,2)
            if correctInaRow==0
                if size(times,2) < 2
                    reversal=0;
                elseif times(lengthnumber)==times(lengthnumber-1) 
                    reversal=reversal
                else
                    reversal=reversal+1
                end
            else
            end

            %according to the condition, adjust the step size

            if level<=100  & upstepSize == first_upstepSize
                upstepSize = second_upstepSize;
                downstepSize = second_downstepSize;
            end
             
             if level <=30 & upstepSize == second_upstepSize
                upstepSize = third_upstepSize;
                downstepSize = third_downstepSize;
                reversal = 0;
             end

             if reversal >= 3 & upstepSize == first_upstepSize 
                upstepSize = second_upstepSize;
                downstepSize = second_downstepSize;
                reversal = 0;
             elseif reversal >= 3 & upstepSize == second_upstepSize 
                upstepSize = third_upstepSize;
                downstepSize = third_downstepSize;
                reversal = 0;
             end           

       

        % random ITI
        ITI = baseITI;
        randomITI = randperm(5,1)/10;
        ITI = ITI+randomITI;
        WaitSecs(ITI);
        Screen('Flip',Window);
        
       
        %results
        results.designprimetime(trialNum) = prime_dur;
        results.prime1time(trialNum) = reaction_time(trialNum,2);% prime real time
        results.prime2time(trialNum) = reaction_time(trialNum,4);% prime real time
        results.judgetime(trialNum) = judge_time;
        results.reversal(trialNum) = reversal;
        results.TIMES = times;
        
      
        reaction_main_time_table = table(reaction_time(:,1),reaction_time(:,2),...
reaction_time(:,3),reaction_time(:,4),reaction_time(:,5),'VariableNames',...,
{'blank_last_time' 'prime1_last_time' 'blank2_last_time' 'prime2_last_time' 'response_last_time' });%turn it to a table 
        trialNum=trialNum+1    
        
        %break
         if  trialNum ==100
       Screen('FillRect', Window, bcolor);
       txt=Screen('MakeTexture',Window,rest);
       Screen('DrawTexture',Window,txt);           
       Screen('Flip', Window);
       QuitFlag = 0;
        while ~QuitFlag
            [KeyIsDown,~,KeyCode] = KbCheck;
            if KeyIsDown && KeyCode(Start)
                QuitFlag = 1;
            end 
        end
       pause(1);
         end
         
         if  trialNum ==200
             Screen('FillRect', Window, bcolor);
             txt=Screen('MakeTexture',Window,rest);
             Screen('DrawTexture',Window,txt);   
             Screen('Flip', Window);
             QuitFlag = 0;
             while ~QuitFlag
                 [KeyIsDown,~,KeyCode] = KbCheck;
                 if KeyIsDown && KeyCode(Start)
                     QuitFlag = 1;
                 end
             end
             pause(1);
         end
       
        
         %the terminal condtion
         if  (trialNum>=300) || (level<=1)
             Flag =false
         end

end
results_main_all=[];
        results_main_all(1,:)=results.intensity;
        results_main_all(2,:)=results.intensityjudge;
        results_main_all(3,:)=results.response;
        results_main_all(4,:)=results.reversal;
        results_main_all(5,:)=results.designprimetime;
        results_main_all(6,:)=results.prime1time;
        results_main_all(7,:)=results.prime2time;
        results_main_all(8,:)=results.judgetime;
        results_main_all(9,1:size(results.TIMES,2))=results.TIMES;

        results_main_all=results_main_all'

        results_main_all_table= table(results_main_all(:,1),results_main_all(:,2),...
results_main_all(:,3),results_main_all(:,4),results_main_all(:,5),results_main_all(:,6), ...
results_main_all(:,7),results_main_all(:,8),results_main_all(:,9),'VariableNames',...,
{'intensity_angel' 'original_orientation_1left_2right' 'response_0wrong_1right' ...
'reversal' 'designprimetime' 'prime1time' 'prime2time' 'judgetime' 'TIMES'});%turn it to a table 



%% End
    Screen('FillRect', Window, bcolor);
    txt=Screen('MakeTexture',Window,finish);
    Screen('DrawTexture',Window,txt);
    Screen('Flip', Window);
    trialbegin = GetSecs;
    while (GetSecs - trialbegin < 0.5)     
    end
    exp_stop=clock;
    whole_time=etime(exp_stop,exp_start);
    Screen('CloseAll');   
    save(ResultFile,'whole_time','results','reaction_main_time_table','results_main_all_table','results_main_all');
    toc
catch
    sca;
    Priority(0);
    ShowCursor;
    psychrethrow(lasterror);
end
function response = CheckKeyPress(keyIsDown, keyCode, Start, Exit)
if (keyIsDown) && ~keyCode(Start)
    response = find(keyCode);
    response = response(1);
    if response==Exit
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        return;
    end 
else response=0;
end
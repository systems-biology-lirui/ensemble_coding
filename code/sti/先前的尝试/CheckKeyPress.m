function response = CheckKeyPress(KeyIsDown, KeyCode, Start, Exit)
if (KeyIsDown) && ~KeyCode(Start)
    response = find(KeyCode);
    response = response(1);
    if response==Exit
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        return;
    end 
else response=0;
end
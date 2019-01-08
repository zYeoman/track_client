; #NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
; SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv
#SingleInstance force

isResting := GetIsResting()
task := GetTask()
work := GetTimeDelta()
if isResting
{
    SetTimer, DELAY, off
    SetTimer, RELAX, 300000
}
else
{
    SetTimer, RELAX, off
    SetTimer, DELAY, 300000
}

times := 0
FilePath:="..\..\..\track.txt"
Menu, Tray, Icon, stopwatch.ico,,1


; 当前状态
RAlt & a::
    isResting := GetIsResting()
    if isResting
        MsgBox 正在玩, 好好玩233
    else
        MsgBox 正在进行, %work% %task%
return
; 结束
RAlt & z::
    SetTimer, DELAY, off
    SetTimer, RELAX, off
    work := 0
    TrayTip 停止吧, 循环
return
; 同步番茄
RAlt & d::Reload
; 结束番茄
RAlt & e::
    work = 5
    goto DELAY
return
; 开始
RAlt & s::
    work := 0
    task := NextTask(FilePath, "")
DELAY:
    if (work >= 5){
        SoundPlay %A_ScriptDir%/notice.wav
        MsgBox, 6,, %task% 做完了么？
        times+=1
        time := GetTime()
        IfMsgBox Continue
        {
            FileAppend, %time% - 完成 - %times% - %Task%`n, %FilePath%
            task := ""
            times:=0
        }
        Else IfMsgBox Cancel
        {
            InputBox, actual, 实际上做了什么？, ,,,100
            If %actual%
                FileAppend, %time% - 中断 - x - %actual%`n, %FilePath%
        }
        Else
        {
            FileAppend, %time% - 继续 - %times% - %Task%`n, %FilePath%
        }
        TrayTip Timer, 休息
        SetTimer, DELAY, off
        SetTimer, RELAX, 300000
    }
    else{
        work++
        SetTimer, RELAX, off
        SetTimer, DELAY, 300000
    }
return

RELAX:
    task := NextTask(FilePath, task)
    work := 1
    TrayTip Timer, %task%
    SetTimer, RELAX, off
    SetTimer, DELAY, 300000
return
GetTime()
{
    time = %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%
    return time
}
GetInfo(openURL)
{
    oHttp := ComObjCreate("WinHttp.Winhttprequest.5.1")
    Try {
        oHttp.open("GET", openURL)
        oHttp.send()
        return oHttp.responseText
    }
    Catch e{
        return 0
    }
}
GetIsResting()
{
    openURL = http://localhost:5000/isResting
    return GetInfo(openURL)
}
GetTask()
{
    openURL = http://localhost:5000
    return GetInfo(openURL)
}
GetTimeDelta()
{
    openURL = http://localhost:5000/timeDelta
    return GetInfo(openURL)
}
PutTask(Task)
{
    oHttp := ComObjCreate("WinHttp.Winhttprequest.5.1")
    openURL = http://localhost:5000
    Try {
        oHttp.open("PUT", openURL, false)
        data = data=%Task%
        oHttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        oHttp.send(data)
    }
    Catch e{
        return
    }
}
PutIsResting()
{
    oHttp := ComObjCreate("WinHttp.Winhttprequest.5.1")
    openURL = http://localhost:5000/isResting
    Try {
        oHttp.open("PUT", openURL, false)
        oHttp.send()
    }
    Catch e{
        return
    }
}
NextTask(FilePath, Task)
{
    SoundPlay %A_ScriptDir%/notice.wav
    if (Task == "")
    {
        InputBox, Task, 接下来要干什么？, ,,,100
        time := GetTime()
        FileAppend, %time% - 开始 - 0 - %Task%`n, %FilePath%
    }
    PutTask(Task)
    return Task
}

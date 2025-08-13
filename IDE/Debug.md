#region VSC Debugger program
red dot or the F9 key to add a break point while debugging.
Ctrl+Shift+D opens the debug panel. Green play button to start the debugger rogram
it pauses right before breakpoint
highlights the line

Dbg at Terminal prompt. Implies you are inside the function being executed
hover over the variable to check its contents mid-execution  or you can expand the variable in the variables panel in the left  OR you can also type the variable in the console and select to see all properties
buttons at the top. play , step over step into, step out of

Line Breakpoints  |  Function\Command breakpoints: No red dot     |conditional breakpoints: anylogic on variables and on expressions   |  Tracepoints allows to emit information or change state of the script

VSC debugger variable groups: Auto, Local, Script, Global

VSC debugger Watch --track a variable or expression
VSC debugger call stack: With each breakpoint, you create a call frame that you can interact with. The call stack gives you the ability to jump between the breakpoints and interact with the call frame at each break point. 

```
F5                  Continue 
F10                 Step Over 
F11                 Step Into 
Shift + F11         Step Out 
Ctrl + Shift + F5   Restart Debugger
Shift + F5          Stop Debugger
```

Debug config option
Ctrl+Shift+D        Debugger Panel
There wont be any configurations unless one sets up the workspace


Select code . Rt click and select format.  Ctrl+k Ctrl+F
PSformattingSettings.json file  contains PowerShell formatting rules

Ctrl+N, Ctrl+K, M  select PowerShell and Enter
#endregion

#region PowerShell cmdlets for Command line debugging

#https://youtu.be/TCs8KmyZCgs

#Shift+Enter allows you to continue the same line in the Terminal

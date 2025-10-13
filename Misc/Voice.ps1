#region text-to-speech
$speaker=New-Object -ComObject sapi.spvoice
$speaker.Speak("how are you")
#endregion

<#Narrator commands
Turn on Narrator (Win+Ctrl+Enter) 

 (CapsLock+Shift+↓) to read the selected text.

#>


#region get available voices
Add-Type -AssemblyName System.speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.GetInstalledVoices()| foreach  { $_.VoiceInfo.Name }
#endregion



<#VSC custom task to read clipboard
{ "version": "2.0.0",
  "tasks": [
    { "label": "Speak Clipboard", "type": "process", "command": "powershell.exe",
      "args": ["-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-Command",
        "Add-Type -AssemblyName System.Speech; $s=New-Object System.Speech.Synthesis.SpeechSynthesizer; try{$s.SelectVoice(\"Microsoft Zira Desktop\")}catch{}; $t=Get-Clipboard -Raw; if($t){$s.Speak($t)}"
      ],
      "problemMatcher": []
    }
  ]
}
#>

<#VSC 'VsCode Action Buttons' extension setting to add a statusbar button to speak clipboard and terminate while speaking
"actionButtons": { "reloadButton": null,

  "commands": [
    { "name": "🎙️", "command": "workbench.action.editorDictation.start", "useVsCodeApi": true, "tooltip": "Start Dictation" },
    { "name": "$(unmute)", "tooltip": "Speak clipboard", "useVsCodeApi": true,"command": "workbench.action.tasks.runTask", "args": ["Speak Clipboard"] }
    { "name": "$(debug-stop) Stop", "tooltip": "Stop speaking", "useVsCodeApi": true, "command": "workbench.action.tasks.terminate", "args": ["terminateAll"]   // or omit args to choose a single task
     }
  ]
},
#>



<# Natural language package installation step. [Worked on x64 but not on ARMx64]
Download. The MSIX for. The voice that you want. 
Rename it to zip. And extract it. In your temp folder. 
Download the adapter. 
Extract the adapter and execute install EXE. 
Point the EXE. To the. MSI XS unzipped folder. Uncheck other options. And just install for 64 bit. 
#>
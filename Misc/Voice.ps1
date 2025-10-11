#region text-to-speech
$speaker=New-Object -ComObject sapi.spvoice
$speaker.Speak("how are you")
#endregion


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

<#VSC 'VsCode Action Buttons' extension setting to add a statusbar button to speak clipboard
"actionButtons": { "reloadButton": null,

  "commands": [
    { "name": "🎙️", "command": "workbench.action.editorDictation.start", "useVsCodeApi": true, "tooltip": "Start Dictation" },
    { "name": "$(unmute)", "tooltip": "Speak clipboard", "useVsCodeApi": true,"command": "workbench.action.tasks.runTask", "args": ["Speak Clipboard"] }

  ]
},
#>




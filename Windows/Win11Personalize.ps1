#AppsUseLightTheme value to 0, which means dark mode. To switch back to light mode, you can set the value to 1.
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0  

Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0

#Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\DWM -Name AccentColor -Value 0xFF000000

Set-ItemProperty -Path "HKCU:Control Panel\Desktop" -Name "AutoColorization" -Value 1 #Sets accent color to automatic

Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name ColorPrevalence -Value 1 #Enables 'Show accent color on start and taskbar'

Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\DWM -Name ColorPrevalence -Value 1  # enable 'show accent color on title bars and windows borders'


#Set background to solid color manually| https://superuser.com/questions/1386302/how-to-replace-the-desktop-background-image-with-a-solid-color-using-powershell
Set-ItemProperty -Path "HKCU:Control Panel\Colors" -Name "Background" -Value "0 0 0"  #Didn't work

#Taskbar was still blue. Manually set accent color to blue
#MAnually set taskbar alignment to 'left'
#Manually set system display settings text size to 150%
#Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name LogPixels -Value 144  #Didn't work


winget install discord

ddd M.d.yy  #My custom date format in System regional settings.


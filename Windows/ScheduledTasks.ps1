Set-ScheduledTask -TaskName startupapptask -User '<user>' -Password '<>'   #change credentials of a scheduled task


Register-ScheduledTask -TaskName CDPXMLExport -Trigger $(New-ScheduledTaskTrigger -RepetitionInterval 1hr) -User NTDOMAIN\PDI_Fivetran_Prod –Action $PS -Password '<>' -Verbose


#region Query scheduled tasks
$objArr=@()

$a=Get-ScheduledTask|sort state
$b=$a|Get-ScheduledTaskInfo

for ($i=0; $i -lt $a.Count;$i+=1)

{$props=@{'Name'       =$a[$i].TaskName;
          'Description'=$a[$i].description;
          'State'      =$a[$i].state;
          'NextRun'    =$b[$i].nextruntime;
          'LastRun'    =$b[$i].lastruntime}
$obj = New-Object -TypeName PSOBject -Property $props
if(($a[$i].state -ne 'disabled') -and($b[$i].lastruntime)) {$objArr +=$obj}}

$objArr|ft -Wrap
#endregion

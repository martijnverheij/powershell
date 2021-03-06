param([string]$outputfile = "d:\tmp\mbtest.csv",
      [bool] $includedgroup = $false,
	  [bool] $includegroupmembers=$true,
	  [bool] $exporttofile = $true,
	  [bool] $mbxperm=$true
)

function getmailboxsizes($mbx)
{
#    write-host "bepaal sizes $mbx"
    $info = 0 | select "total_mbx","Total_archive","Total"
    $mm = get-MailboxStatistics -identity $mbx -erroraction silentlycontinue -WarningAction silentlycontinue | select TotalItemSize,TotalDeletedItemSize
#	$info.total_mbx = $info.total_archive = $info.total =0
	if ($mm -ne $null)
	{
	    $info.total_mbx = $mm.totalitemsize.value.tokb() + $mm.TotalDeletedItemSize.value.tokb()
	}
	$ma = Get-MailboxStatistics -identity $mbx -archive -erroraction silentlycontinue -WarningAction silentlycontinue | select TotalItemSize,TotalDeletedItemSize
	if ($ma -ne $null)
	{
	   $info.total_archive = $ma.totalitemsize.value.tokb() + $ma.TotalDeletedItemSize.value.tokb()
	}
	$info.total = $info.total_mbx + $info.total_archive
	$info
}

#function makeobject($selection,$mbsam,$mbdisplay,$mbadd,$rights,$ussam,$usdisplay,$usadd,$outputfile)
function makeobject($selection)
{
#  $mbobject = "" | select mailbox_samaccount,mailbox_display,mailbox_smtpaddress,rights,user_samaccount,user_display,user_smtpaddress
  $mbobject = "" | select $selection
  $tel =0
  foreach($sel in $selection)
  {
     $mbobject.$sel = $args[$tel++]
  }
  $mbobject
}

function getmanagersam($managerdn)
{
   if (($managerdn -ne "") -and ($managerdn -ne $null))
   { 
     $mansam = (get-aduser -identity $managerdn).samaccountname
   }
   else
   { 
     $mansam = ""
   }
   $mansam
}

function makerights($accessrights,$extendedrights)
{
   if ($accessrights -eq "Extendedright")
   {
     $rights = $extendedrights -join("")
   }
   else
   {
     $rights = $accessrights -join("")
   }
   $rights
}

function isgroup($account)
{
      try
	  {
	     $ad1 = get-adgroup -identity $account
		 $result = $true
	  }
	  catch
	  {
	    $result = $false
	  }
	  $result
}

function getaccountdetails($account,$includedgroup,$includegroupmembers)
{
    $adinfo=@()
	$ads=@()
    if (isgroup $account)
    {
	  if ($includegroupmembers)
	  {
	      $ads = @(get-adgroupmember -identity $account -recursive)
	  }
	  if ($includedgroup)
	  {
	     $adinfo += get-adgroup -identity $account -properties samaccountname,displayname,mail | select samaccountname,displayname,@{n="emailadress";e={$_.mail}}
	  }
    }
	else
	{
	   $ads = @($account)
	}
	foreach ($ad in $ads)
    {
	  $adinfo += get-aduser -identity $ad -properties samaccountname,displayname,emailaddress
    }
	$adinfo
}
    
if ((get-module | where {$_.name -match "activedirectory"}) -eq $null) 
{ 
  import-module Activedirectory
}

if (test-path $outputfile)
{
     remove-item $outputfile -force
}

$allobject =@()
#$selection = "mailbox_samaccount","mailbox_display","mailbox_smtpaddress","MailboxType","EmployeeNumber","Department","Manager_sam","rights","user_samaccount","user_display","user_smtpaddress","total_mbx(KB)","total_archive(KB)","Total(KB)"
$selection = "mailbox_samaccount","mailbox_display","mailbox_smtpaddress","MailboxType","EmployeeNumber","Department","Manager_sam","total_mbx(KB)","total_archive(KB)","Total(KB)"

#$mball=@(get-recipient _mbx_aanbestedingen | get-mailbox | select identity,samaccountname,displayname,primarysmtpaddress,RecipientTypeDetails)
$mball = @(get-mailbox -resultsize unlimited  | select identity,samaccountname,displayname,primarysmtpaddress,RecipientTypeDetails)
$count = $mball.count
$i=1
foreach ($mb in $mball)
{
  write-progress -activity "$i/$count   Sam: $($mb.samaccountname)  Display: $($mb.displayname)"  -status "Getting mbx info" -percentcomplete ( $i * 100 / $count)
  $i++
  $allinfotemp=@()
  $mbobject = "" | select $selection
  $countperm =0
  $sizes = getmailboxsizes $mb.samaccountname
  $extra = get-aduser $mb.samaccountname -properties EmployeeNumber,Department,Manager | select EmployeeNumber,Department,Manager
  $extra.manager = getmanagersam $extra.manager
  $allinfotemp += makeobject $selection $mb.samaccountname $mb.displayname $mb.primarysmtpaddress $mb.RecipientTypeDetails $extra.EmployeeNumber $extra.Department $extra.manager $sizes.total_mbx $sizes.total_archive $sizes.total
  $allobject += $allinfotemp | select -unique $selection
}
$allobject | export-csv -path $outputfile -delimiter ";" -encoding UNICODE -notypeinformation -force


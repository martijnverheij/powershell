New-ADUser -Name $fullname -GivenName $firstname -Surname $lastname -DisplayName $fullname -SamAccountName $logonname -UserPrincipalName $logonname@$domain -City $City -Company $Company -MobilePhone $mobile -PostalCode $Zipcode -StreetAddress $homeadres -State $State -AccountPassword $password -Enabled $true -Path $OU -ChangePasswordAtLogon $True -Confirm:$false
# Windows Domain Controller
## Builds a Windows Server 2022 Azure Edition VM with the AD DS and DNS roles installed.  
The default size is a B2ms, which is usually considered the best option for a standard domain controller.  
If you will be running additional roles or software on this VM, it is recommended to bump up to size to a B4ms.  
Don't forget to get a reservation if you are leaving the VM online all the time.  
The outputs.tf file will output information needed to connect to your new VM via RDP.  
It will create a DNS label that you can connect with or the public IP.  
To use the DNS label, take the label output and add .*your-region*.cloudapp.azure.com  
The end result will look something like this: `terraform-test-dns.westus2.cloudapp.azure.com`
By default the admin password doesn't display for security reasons, so to display it enter this command after the VM is built:  
```terraform
terraform output -raw admin_password
```
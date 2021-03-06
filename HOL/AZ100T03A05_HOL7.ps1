#먼저 로그인
Connect-AzAccount
$myResourceGroup = "hahaysh-rg4"
$myScaleSet = "hahaysh-scaleset4"

#가상머신확장집합셋만들기
New-AzVmss `
-ResourceGroupName $myResourceGroup `
-VMScaleSetName $myScaleSet `
-Location "EastUS2" `
-VirtualNetworkName "myVnet" `
-SubnetName "mySubnet" `
-PublicIpAddressName "hahaysh-ss-pubip" `
-LoadBalancerName "hahaysh-ss-lb" `
-UpgradePolicyMode "Automatic"

#사용자지정스크립트만들기 - Gihub에 있는 예제를 쓴다.(웹서버를 설치하고, default.html파일을 만드는 스크립트)
$customConfig = @{
    "fileUris" = (,"https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate-iis.ps1");
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1"
}

#가상머신확장집합 정보
$vmss = Get-AzVmss `
-ResourceGroupName $myResourceGroup `
-VMScaleSetName $myScaleSet

# Add-AzVmssExtension을 사용하여 사용자 지정 스크립트 확장을 적용합니다. 
$vmss = Add-AzVmssExtension `
-VirtualMachineScaleSet $vmss `
-Name "MycustomScript" `
-Publisher "Microsoft.Compute" `
-Type "CustomScriptExtension" `
-TypeHandlerVersion 1.9 `
-Setting $customConfig

# Update-AzVmss를 사용하여 VM 인스턴스에서 확장을 업데이트하고 실행합니다. - 웹서버가 설치되고 기본페이지가 만들어짐.
# 실행전에 가상머신 한대에 미리 접속해서 모니터링
Update-AzVmss `
-ResourceGroupName $myResourceGroup `
-Name $myScaleSet `
-VirtualMachineScaleSet $vmss

# 다시 가상머신확장집합셋 정보를 가지고 오고,,
$vmss = Get-AzVmss `
-ResourceGroupName $myResourceGroup `
-VMScaleSetName $myScaleSet

# 80포트를 확인을 위해 네트워크 보안 그룹 포트 개방
$nsgFrontendRule = New-AzNetworkSecurityRuleConfig `
-Name myFrontendNSGRule `
-Protocol Tcp `
-Direction Inbound `
-Priority 200 `
-SourceAddressPrefix * `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 80,3389 `
-Access Allow

#애클리케이션에 트래픽 허용
$nsgFrontend = New-AzNetworkSecurityGroup `
-ResourceGroupName $myResourceGroup `
-Location EastUS2 `
-Name myFrontendNSG `
-SecurityRules $nsgFrontendRule
 $vnet = Get-AzVirtualNetwork `
-ResourceGroupName $myResourceGroup `
-Name myVnet
 $frontendSubnet = $vnet.Subnets[0]
 $frontendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
-VirtualNetwork $vnet `
-Name mySubnet `
-AddressPrefix $frontendSubnet.AddressPrefix `
-NetworkSecurityGroup $nsgFrontend
 Set-AzVirtualNetwork -VirtualNetwork $vnet

#사용자정의확장적용 VM업데이트
Update-AzVmss `
-ResourceGroupName $myResourceGroup `
-Name $myScaleSet `
-VirtualMachineScaleSet $vmss

#확장집합 테스트 - 출력된 IP로 브라우저 접근
Get-AzPublicIpAddress -ResourceGroupName $myResourceGroup | Select IpAddress


============================================================
[DEMO] 가상머신 집합셋에 애플리케이션 배포 (포탈에서 만든 집합셋으로)– 잘 안됨

#먼저 로그인
Connect-AzAccount

#리소스그룹과 확장집합셋이름정의
$myResourceGroup = "hahaysh-rg4"
$myScaleSet = "hahayshscaleset"
$myVnet = "hahaysh-vnet4"
$myFrontendNSG = "hahayshscalesetnsg"

#사용자지정스크립트만들기 - Gihub에 있는 예제를 쓴다.(웹서버를 설치하고, default.html파일을 만드는 스크립트)
$customConfig = @{
"fileUris" = (,"https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate-iis.ps1");
"commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1"
}

#가상머신확장집합에 VME적용
$vmss = Get-AzVmss `
-ResourceGroupName $myResourceGroup `
-VMScaleSetName $myScaleSet

# Add-AzVmssExtension을 사용하여 사용자 지정 스크립트 확장을 적용. 
$vmss = Add-AzVmssExtension `
-VirtualMachineScaleSet $vmss `
-Name "hahayshcustomScript" `
-Publisher "Microsoft.Compute" `
-Type "CustomScriptExtension" `
-TypeHandlerVersion 1.9 `
-Setting $customConfig

# Update-AzVmss를 사용하여 VM 인스턴스에서 확장을 업데이트하고 실행합니다. - 웹서버가 설치되고 기본페이지가 만들어짐.
Update-AzVmss `
-ResourceGroupName $myResourceGroup `
-Name $myScaleSet `
-VirtualMachineScaleSet $vmss

# Get information about the scale set
# 다시 가상머신확장집합셋 정보를 가지고 오고,,
$vmss = Get-AzVmss `
-ResourceGroupName $myResourceGroup `
-VMScaleSetName $myScaleSet

#Create a rule to allow traffic over port 80
# 80포트를 확인을 위해 네트워크 보안 그룹 포트 개방
$nsgFrontendRule = New-AzNetworkSecurityRuleConfig `
-Name myFrontendNSGRule `
-Protocol Tcp `
-Direction Inbound `
-Priority 200 `
-SourceAddressPrefix * `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 80,3389 `
-Access Allow

#애리케이션에 트래픽 허용
#Create a network security group and associate it with the rule
$nsgFrontend = New-AzNetworkSecurityGroup `
-ResourceGroupName $myResourceGroup `
-Location EastUS2 `
-Name $myFrontendNSG `
-SecurityRules $nsgFrontendRule
 $vnet = Get-AzVirtualNetwork `
-ResourceGroupName $myResourceGroup `
-Name $myVnet
 $frontendSubnet = $vnet.Subnets[0]
 $frontendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
-VirtualNetwork $vnet `
-Name default `
-AddressPrefix $frontendSubnet.AddressPrefix `
-NetworkSecurityGroup $nsgFrontend

Set-AzVirtualNetwork -VirtualNetwork $vnet


#사용자정의확장적용 VM업데이트 Update the scale set and apply the Custom Script Extension to the VM instances
Update-AzVmss `
-ResourceGroupName $myResourceGroup `
-Name $myScaleSet `
-VirtualMachineScaleSet $vmss

#확장집합 테스트 - 출력된 IP로 브라우저 접근
Get-AzPublicIpAddress -ResourceGroupName $myResourceGroup | Select IpAddress

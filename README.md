# Get-AddressInfo

#### .DESCRIPTION

This script was created to display various aspects of poweshell scripting.
Accepting a comma separated list or values from pipeline this function will 
provide the following information for public ip addresses that are specified:

* The average latency of 10 pings
* The number of hops to destination address
* The ISP Information
* The ASN Information
* The geo-location data for the address
* The local time based on geo-location data
* The local weather based on geo-location data

Output is available in text, json, or an array

#### .PARAMETER ipAddress

Specify a valid public IP address that is routable on the internet

#### .PARAMETER json

Will provide the output as a json formated object

#### .PARAMETER array

Will provide the output as a powershell array

#### .PARAMETER ipAddress

Specify a valid public IP address that is routable on the internet

#### .PARAMETER Verbose

Provides verbose logging of script steps

#### .EXAMPLE

PS C:\> Get-AddressInfo 8.8.8.8 -Array

#### .EXAMPLE

PS C:\> Get-AddressInfo 8.8.8.8,8.8.4.4 -Json

#### .EXAMPLE

PS C:\> $ipAddress | Get-AddressInfo

#### .Notes

Author : Lucas Coulson

Created 2022/10/05

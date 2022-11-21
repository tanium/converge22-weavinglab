function Request-SessionId {
    <#
    Example function using username and password to request a 
    session. This will return a session token.

    parameter TS is the Tanium Server to use
    parameter Credential accepts a credential object use for Username/Password Auth
    parameter TSPORT is the Tanium Server port to use :default 443
    parameter DisableCetficateValidation use to validate Tanium Server Certificate :default true
    #>
    
    [CmdletBinding()]
    Param(
        [PSCredential]
        $Credential,
        [String]
        $TS = $TaniumServer,
        [Int]
        [ValidateRange(0, 65535)]
        $TSPORT = 443,
        [Boolean]
        $DisableCertificateValidation = $false
    )

    $uri = "https://{0}:{1}/auth" -f $TS, $TSPORT
    $webRequest = [System.Net.WebRequest]::Create($Uri)
    if ($DisableCertificateValidation) {
        $webRequest.ServerCertificateValidationCallback = { $true }
    }
    $webRequest.ContentType = "text/plain;charset=`"utf-8`""
    $webRequest.Accept = "*/*"
    $webRequest.Method = "GET"
    $webRequest.Headers.Add('username', ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.UserName))))
    $webRequest.Headers.Add('password', ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.GetNetworkCredential().Password))))

    try {
        $response = $webRequest.GetResponse()
        $reader = [System.IO.StreamReader]($response.GetResponseStream())
        $sessionId = $reader.ReadToEnd()
        $response.Close()
        $reader.Close()
        return $sessionId
    }
    catch {
        Write-Output "An exception has occured"
        Write-Error $_
        exit

    }
}

function Request-Report {
    <#
    Example function used to request data from the API Gateway.
    Uses https://TaniumServer/plugin/products/gateway/graphq.

    parameter TS is the Tanium Server to use
    parameter Body accepts a JSON-Object
    parameter SessionID accpes active sessionID and/or API token
    parameter Method accepts valid web methd (POST, GET, PUT, PATCH, DELETE)
    #>
    [CmdletBinding()]
    Param(
        [String]
        $TaniumServer,
        [String]
        $Body,
        [String]
        $SessionId = $SessionId,  
        [ValidateRange(0, 65535)]
        $TSPORT = 443,
        [String]
        [ValidateSet('POST', 'GET', 'PUT', 'PATCH', 'DELETE')]
        $Method
    )
    $uri = "https://{0}:{1}/plugin/products/gateway/graphql" -f $TaniumServer, $TSPORT
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    try {
        $headers = @{}
        $headers.Add("Content-Type", "application/json")
        $headers.Add("session", $SessionId)
        $request = Invoke-WebRequest -Uri $uri -Headers $headers -Body $body -Method $method
    }
    catch {
        Write-Warning $Error[0]
    }
    return $request
}

# Request SessionId using username and password:
Write-Output "Please enter a username and password"
$Creds = Get-Credential
$TS = '127.0.0.1'
$SessionId = Request-SessionId -TS $TS -Credential $Creds -DisableCertificateValidation $true

# GraphQL Query - Cached Data
<# Example output taken from Query Explorer in the Tanium Console
        endpoints {
            edges {
            node {
                name
                ipAddress
                        os {
                            name
                        }
            }
        } 
#>

$QueryCached = @"
{"query":"{endpoints{edges{node{name ipAddress os{name}}}}}"}
"@

# Request data from the API Gateway
Write-Output "Requesting Cached Data"
$Response = Request-Report -TaniumServer $TS -Method POST -SessionId $SessionId -Body $QueryCached
$Response.content


# GraphQL Query - Live Data
<# Note: Requesting live data is the same as with cached but we define a source
when requesting live data "source: {ts:" #>
<#Example taken from Query Explorer
        endpoints(source: {ts: {expectedCount: 1, stableWaitTime: 10}}) {
            edges {
                node {
                    name
                    ipAddress
                            os {
                                name
                            }
                }
            }
        }
#>

$QueryLive = @"
{"query":"{endpoints(source:{ts:{expectedCount: 1, stableWaitTime: 10}}){edges{node{name ipAddress os{name}}}}}"}
"@


Write-Output "Requesting Live Data"
$Response = Request-Report -TaniumServer $TS -Method POST -SessionId $SessionId -Body $QueryLive
$Response.content
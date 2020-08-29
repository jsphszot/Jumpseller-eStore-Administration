# https://jumpseller.com/support/api/

    # create an array of specific type
    # $id_list = New-Object Collections.Generic.List[Int]
    # $id_list.Add(1999) # to extend list
    # powershell -ExecutionPolicy Bypass -File .\updateOrders.ps1 1642

    # https://stackoverflow.com/questions/18770723/hide-progress-of-invoke-webrequest
    # $global:progressPreference = 'silentlyContinue'


# import parameters
$bananas = Get-Content -Raw  -Path  tokens.json | ConvertFrom-Json
$api_login = $bananas.api_login
$api_token = $bananas.api_token

# HTTP request parameters
$header_js = @{"Accept" = "application/json"};

$url_mostRecentOrder = "https://api.jumpseller.com/v1/orders.json?login={0}&authtoken={1}&limit=1&page=1" -f $api_login, $api_token
$responseMRO = Invoke-RestMethod -Method GET -Uri $url_mostRecentOrder -Headers $header_js #| ConvertTo-Json | ConvertFrom-Json
$id_MRO = $responseMRO.order.id

# receive input from user -> what range to affect
"Most recent order id is {0}" -f $id_MRO
"The following input must be given from the smaller number in the range to the bigger one"
[int]$start = Read-Host -Prompt "ID range start" # -AsSecureString for passwords
[int]$end = Read-Host -Prompt "ID range end"

# jumpseller id's start at 1001
if ($start -lt 1001) {$start = 1001}

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_arrays?view=powershell-7
if (($start -is [int]) -and ($end -is [int]) -and ($start -le $end)) {
    $id_list = $start..$end
    foreach ($order_id in $id_list) {
        $url_js = 'https://api.jumpseller.com/v1/orders/{0}.json?login={1}&authtoken={2}' -f $order_id,$api_login, $api_token
        # if status is not cancelled
        
        $status = Invoke-RestMethod -Method GET -Uri $url_js -Headers $header_js | ConvertTo-Json | ConvertFrom-Json
        $order_status = $status.order.status
        $ship_status = $status.order.shipment_status

        # status (string, optional): Status of the Order = ['Abandoned', 'Canceled', 'Pending Payment', 'Paid'],
        if (($order_status -eq "Paid") -and ($ship_status -ne "Entregado")) {
            $contentType_js = 'application/json'
            # Shipment Status for Order Fulfillment. = ['delivered', 'requested', 'in_transit', 'failed'],
            $body_js = @{order = @{shipment_status = "delivered"}} 
            $body_json = $body_js | ConvertTo-Json
            Invoke-RestMethod -Method PUT -Uri $url_js -ContentType $contentType_js -Headers $header_js -Body $body_json
        } else {
            # skip
        }
    }
} else {
    Write-Warning -Message "Somthing was wrong with your input"
    exit
}

"Finished! Updated all paid orders from {0} to {1}" -f $start, $end
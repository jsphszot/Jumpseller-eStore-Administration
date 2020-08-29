# Get all orders from certain date to present, that have been paid
# Separate store pick-up from delivery.

# IWR
# https://davidhamann.de/2019/04/12/powershell-invoke-webrequest-by-example/

"Hello Miau Miau arf arf"
"process is running ..."

# utility function to correct encoding
# https://html.developreference.com/article/13017641/Powershell+Invoke-WebRequest+and+character+encoding


# import parameters
$bananas = Get-Content -Raw  -Path  tokens.json | ConvertFrom-Json

$order_status = "Paid"

$apijs = "https://api.jumpseller.com/v1/orders.json"
$api_login = $bananas.api_login
$api_token = $bananas.api_token
$api_page = 1

$cat = @()

# HTTP request parameters
$header_js = @{"Accept" = "application/json"};

# $pages = 1..3
$pages = 1

$params = @{
    Headers = $header_js
    Method = 'GET' 
    ContentType = 'application/json; charset=utf-8'
}

foreach ($api_page in $pages) {
    $url_orders = "{0}?login={1}&authtoken={2}&limit=100&page={3}" -f $apijs, $api_login, $api_token, $api_page
    # limit max = 100, get more pages for more info
    Invoke-RestMethod @params -Uri $url_orders -OutFile ".\NewOrdersJson.txt"
    $response_orders = get-content ".\NewOrdersJson.txt" -Encoding utf8 -raw | ConvertFrom-Json
    $cat += $response_orders
}

# $cat | Measure-Object
# $cat.GetType()

$mystring = ""
foreach ($row in $cat) {
    $RO = $row.order
    
    # for each data row, validate
    if (($RO.status -eq "Paid") -and ($RO.shipment_status -ne "Entregado")) {
        # if (($RO.status -eq "Paid") -and ($RO.shipment_status -eq "Procesado")) { # find processed cases
        $CU = $RO.customer
        $SA = $RO.shipping_address
        $PR = $RO.products

        $mystring += "id: {0} - {1} - {2}`n" -f $RO.id, $RO.status, $RO.shipment_status
        $mystring += "{0} {1}, {2} {3}`n" -f $SA.name, $SA.surname, $CU.phone, $CU.email
        $mystring += "{0}, {1}`n{2}, {3}, {4}`n" -f $SA.address, $SA.city, $SA.region, $SA.country, $SA.postal
        $mystring += "fecha compra: {0}`n" -f $RO.completed_at
        $mystring += "{0} total `${1}, shipping `${2}`n" -f $RO.currency, $RO.total, $RO.shipping

        foreach ($pdct in $PR) {
            $mystring += "{0} x {1}`n" -f $pdct.qty, $pdct.name 
        }

        $mystring += "`n"

        # fields
            # status
            # additional_information
            # shipping_method_name
            # shipment_status
            # created_at
            # completed_at
            # currency, subtotal, shipping, discount, total
            
            # customer
            # - email
            # - phone
            # shipping_address
            # - name, surname
            # - address, city, postal, region, country
            


            # products (foreach)
            # id, name, qty

        
    }

}

# write-output $mystring | out-file -append "cats.txt"
write-output $mystring | out-file "..\NewOrders.txt"

"Finished! Orders are available for printing"
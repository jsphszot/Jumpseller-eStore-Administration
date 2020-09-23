# Links I'm grateful of
    # https://poshgui.com/
    # GUI: https://gallery.technet.microsoft.com/GUI-Popup-Custom-Form-with-bf6c4141
    # GUI: https://channel9.msdn.com/Series/GuruPowerShell/GUI-Form-Using-PowerShell-Add-Panel-Label-Edit-box-Combo-Box-List-Box-CheckBox-and-More
    # GUI: https://domruggeri.com/2019/07/06/creating-extensive-powershell-gui-applications-part-1/
    # approved function verbs: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7
## functions

function Update-HashTable {
    param (
        $HashTbl,
        $HashKey,
        $Qty
    )
    
    if ($HashTbl.ContainsKey($HashKey)){
        $HashTbl[$HashKey] += $Qty
    } else {
        $HashTbl.Add($HashKey, $Qty)
    }

}

function Update-ProdsHashTable {
    Param(
        $HashTbl,
        $HashKey,
        $ProdName
    )
    if (!($HashTbl.ContainsKey($HashKey))) {
        $HashTbl.Add($HashKey, $ProdName)
    }
}

function Update-StatusLabel {
    param($text)
    $toolStripStatusLabel.Text = $text;
}

function Get-ScriptDirectory { 
    #Return the directory name of this script
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}
# $ScriptPath = Get-ScriptDirectory

function Read-WrittenRequest {
    param(
        $params,
        $url
    )

    Invoke-RestMethod @params -Uri $url
    $response_orders = Get-Content $params["OutFile"] -Encoding utf8 -raw | ConvertFrom-Json

    Return $response_orders
}

function Invoke-BuildOrderInfo {
    param($OrdersList)

    $orders_string = ""
    $picking_string = ""
    $myhshtbl = @{}
    $prodskus = @{}
    # CSV Header
    $delivery_string = "id;Nombre;Telefono;Direccion;Municipalidad;Ciudad;Region;CodPostal;Comentarios`n"

    $newordercount = 0
    foreach($row in $OrdersList){
        
        $RO = $row.order
        if (($RO.status -eq "Paid") -and ($RO.shipment_status -ne "Entregado")) {
            $newordercount += 1
            $CU = $RO.customer
            $SA = $RO.shipping_address
            $PR = $RO.products
            $clientname = "{0} {1}" -f $SA.name, $SA.surname

            $orders_string += "id: {0} - {1} - {2}<br>" -f $RO.id, $RO.status, $RO.shipment_status
            $orders_string += "<b>{0}, {1} {2}</b><br>" -f $clientname, $CU.phone, $CU.email
            $orders_string += "<b>{0}, {1} - {2}<br>{3}, {4}, {5}</b><br>" -f $SA.address, $SA.municipality, $SA.city, $SA.region, $SA.country, $SA.postal
            $orders_string += "fecha compra: {0}<br>" -f $RO.completed_at
            $orders_string += "{0} total `${1} (`${2} + S/H `${3})<br>" -f $RO.currency, $RO.total, $RO.subtotal, $RO.shipping
            $orders_string += "ExtraInfo: {0}<br>" -f $RO.additional_information

            foreach ($pdct in $PR) {
                $orders_string += "{0} x {1} - {2}<br>" -f $pdct.qty, $pdct.name, $pdct.id 
                Update-HashTable $myhshtbl $pdct.id $pdct.qty
                Update-ProdsHashTable $prodskus $pdct.id $pdct.name
            }

            $orders_string += "<br>"

            if ($RO.shipping -ne 0){
                $delivery_string += '"{0}";"{1}";"{2}";"{3}";"{4}";"{5}";"{6}";"{7}";"{8}"' -f $RO.id, $clientname, $CU.phone, $SA.address, $SA.municipality, $SA.city, $SA.region, $SA.postal, $RO.additional_information
                $delivery_string += "`n"
            }

        }

    }
    
    $picking_string = "<b>You have {0} new Orders</b><br>" -f $newordercount
    foreach ($i in $myhshtbl.keys) {
        $prodname = $prodskus[$i]
        $prodqty = $myhshtbl[$i]

        $picking_string += "{0} x {1}<br>" -f $prodqty, $prodname

    }

    $picking_string += "<br>"
    $picking_string += $orders_string

    write-output $picking_string | out-file "..\NewOrders.html"
    write-output $delivery_string | out-file "..\Delivery.csv"


}

function Get-OrdersJson {
        param (
            $pages,
            $pprms
            )

        $pages = 1..$pages
        $apijs = $pprms["apijsorders"]
        $api_login = $pprms["api_login"]
        $api_token = $pprms["api_token"]
        
        $params = @{
            Headers = $pprms["header_js"]
            Method = "GET"
            OutFile = ".\NewOrdersJson.txt"
        }

        $OrdersList = @()
        foreach ($api_page in $pages) {
            $url_orders = "{0}?login={1}&authtoken={2}&limit=100&page={3}" -f $apijs, $api_login, $api_token, $api_page
            $OrdersList += Read-WrittenRequest $params $url_orders
        }
        
        Invoke-BuildOrderInfo $OrdersList
        Update-StatusLabel "Retreived Pending Orders"

}

function Get-UpdateRange {
    param($pprms)
    $startyinfunc = [int]$RangeTB.Text
    $endyinfunc = [int]$RangeTBend.Text
    
    if (($startyinfunc -is [int] -and ($endyinfunc -is [int]))) {
        if ($endyinfunc -eq 0) {$endyinfunc = $startyinfunc}
        $catmeout = $startyinfunc..$endyinfunc
        Write-Host $endyinfunc
        Update-OrderStatus $pprms $catmeout 
        # Update-StatusLabel $catmeout
    } else {
        Update-StatusLabel "Something was wrong with your input, try only numbers"
    }


}

function Update-OrderStatus {
    param (
        $pprms, $id_list
        )

        $api_login = $pprms["api_login"]
        $api_token = $pprms["api_token"]
        
        Update-StatusLabel "Updating status...";

        foreach ($order_id in $id_list) {
            $apijs = $pprms["apijsordersID"] -f $order_id
            $url_js = '{0}?login={1}&authtoken={2}' -f $apijs, $api_login, $api_token

            # if status is not cancelled
            $status = Invoke-RestMethod -Method GET -Uri $url_js -Headers $header_js | ConvertTo-Json | ConvertFrom-Json
            $order_status = $status.order.status
            $ship_status = $status.order.shipment_status
    
            # status (string, optional): Status of the Order = ['Abandoned', 'Canceled', 'Pending Payment', 'Paid'],
            if (($order_status -eq "Paid") -and ($ship_status -ne "Entregado")) {
                Update-StatusLabel "Updating status {0}..." -f $order_id;
                $contentType_js = 'application/json'
                # Shipment Status for Order Fulfillment. = ['delivered', 'requested', 'in_transit', 'failed'],
                $body_js = @{order = @{shipment_status = "delivered"}} 
                $body_json = $body_js | ConvertTo-Json
                Invoke-RestMethod -Method PUT -Uri $url_js -ContentType $contentType_js -Headers $header_js -Body $body_json
            } else {
                # skip
            }
        }
        "Finished! Updated all paid orders from {0} to {1}" -f $id_list[0], $id_list[-1]

} 

## Parameters
# import
    $jumpseller_auth = Get-Content -Raw -Path tokens.json | ConvertFrom-Json
    $api_login = $jumpseller_auth.api_login
    $api_token = $jumpseller_auth.api_token
# packed parameters
    $pprms = @{
        "api_login" = $api_login
        "api_token" = $api_token
        "apijsorders" = "https://api.jumpseller.com/v1/orders.json"
        "apijsordersID" = "https://api.jumpseller.com/v1/orders/{0}.json"
        "header_js" = @{"Accept" = "application/json"}
    }

# Get most recent order number
$url_mostRecentOrder = "https://api.jumpseller.com/v1/orders.json?login={0}&authtoken={1}&limit=1&page=1" -f $api_login, $api_token
$responseMRO = Invoke-RestMethod -Method GET -Uri $url_mostRecentOrder -Headers $header_js #| ConvertTo-Json | ConvertFrom-Json
$id_MRO = $responseMRO.order.id

## Load the Windows Forms 
    Add-Type -Assembly System.Windows.Forms; 
    Add-Type -Assembly System.Drawing; 
    [System.Windows.Forms.Application]::EnableVisualStyles()

## Create the main form
    Write-Host "Create form" (Get-Date)
    $form = New-Object Windows.Forms.Form;

    $welcometext = New-Object System.Windows.Forms.Label
    $statusstrip1 = New-Object System.Windows.Forms.StatusStrip
    $toolStripStatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $BtnGetOrders = New-Object System.Windows.Forms.Button
    $BtnChangeStatus = New-Object System.Windows.Forms.Button
    $RangeTB = New-Object System.Windows.Forms.TextBox
    $RangeTBtext = New-Object System.Windows.Forms.Label
    $RangeTBend = New-Object System.Windows.Forms.TextBox
    $RangeTBendtext = New-Object System.Windows.Forms.Label

# Form size
    $setheight = 200
    $setwidth = 500

# Font Size

# $FontSize = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Regular)

# Labels
    $welcometext.Location = New-Object System.Drawing.Point(10,10) 
    $welcometext.Name = "WelcomeText" 
    # $welcometext.Font = $FontSize
    $welcometext.Size = New-Object System.Drawing.Size(683,50)
    $welcometext.TabIndex = 5 
    $welcometext.Text = "Welcome to the SZOT E-Store Administrator. What do you want to do?`n" 
    $welcometext.Text += "(Most recent order id is {0})" -f $id_MRO 

# Buttons
    $btnW = 180;
    $btnH = 30;
    $btnX = 30;
    $btnY = 70;
    $btnSep = 40;

    # Orders Button
    $BtnGetOrders.Location = New-Object System.Drawing.Point($btnX, $btnY)
    $BtnGetOrders.Name = "BtnGetOrders"
    # $BtnGetOrders.Font = $FontSize
    $BtnGetOrders.Size = New-Object System.Drawing.Size($btnW, $btnH)
    $BtnGetOrders.TabIndex = 1
    $BtnGetOrders.Text = "Get Orders"
    $BtnGetOrders.UseVisualStyleBackColor = $true

    # Status Button
    $BtnChangeStatus.Location = New-Object System.Drawing.Point($btnX, ($btnY + $btnSep))
    $BtnChangeStatus.Name = "BtnChangeStatus"
    # $BtnChangeStatus.Font = $FontSize
    $BtnChangeStatus.Size = New-Object System.Drawing.Size($btnW, $btnH)
    $BtnChangeStatus.TabIndex = 2
    $BtnChangeStatus.Text = "Change Status"
    $BtnChangeStatus.UseVisualStyleBackColor = $true
    
    $BtnChangeStatus.Enabled = $RangeTB.Text

    # Range input
    $TBtextWidth = $btnW/4
    $TBtextHeight = 20

    $rangefromtextX = $btnX
    $rangefromtextY = ($btnY + (2*$btnSep))

    $RangeTBtext.Location = New-Object System.Drawing.Point($rangefromtextX, ($rangefromtextY+2))
    # $RangeTBtext.width = $btnW/3
    # $RangeTBtext.Size = New-Object System.Drawing.Size($TBtextWidth-20,$TBtextHeight)
    $RangeTBtext.height = $TBtextHeight
    $RangeTBtext.width = ($TBtextWidth)
    $RangeTBtext.text = "From:"
    $RangeTB.Location = New-Object System.Drawing.Point(($TBtextWidth+$rangefromtextX), $rangefromtextY)
    $RangeTB.width = ($TBtextWidth)
    $RangeTB.add_TextChanged({$BtnChangeStatus.Enabled = $RangeTB.Text})
    
    $rangetotextX = ($rangefromtextX + $RangeTBtext.width + $RangeTB.width)
    $rangetotextY = ($btnY + (2*$btnSep))
    $RangeTBendtext.Location = New-Object System.Drawing.Point($rangetotextX, ($rangetotextY+2))
    $RangeTBendtext.text = "     To:"
    $RangeTBendtext.Size = New-Object System.Drawing.Size($TBtextWidth,$TBtextHeight)
    $RangeTBend.Location = New-Object System.Drawing.Point(($rangetotextX + $RangeTBendtext.width), $rangetotextY)
    $RangeTBend.width = ($TBtextWidth)

    
# Icon
    # https://www.gimp.org/tutorials/Creating_Icons/

# Image
    # https://gist.github.com/zippy1981/969855
    # http://hodentekhelp.blogspot.com/2015/09/can-you-create-windows-form-with.html
    $imgfile = (Get-Item "szot_delivery_small.png")
    # $imgfile = (Get-Item "C:\Users\jsphs\Downloads\jumpseller-szot\SZOT JumpSeller\code\szot_delivery_small.png")
    $img = [System.Drawing.Image]::Fromfile($imgfile);
    [System.Windows.Forms.Application]::EnableVisualStyles();
    $pictureBox = New-Object Windows.Forms.PictureBox;
    $pictureBox.SizeMode = "Zoom" # scales image
    $pictureBox.Height = 115;
    $pictureBox.Width = 300;
    $pictureBox.Location = New-Object System.Drawing.Point(200,40) 
    $pictureBox.Image = $img;

# Status bar
    $statusStrip1.ImageScalingSize = New-Object System.Drawing.Size(32, 32)
    $statusStrip1.Items.AddRange(@($toolStripStatusLabel))
    $statusStrip1.Location = New-Object System.Drawing.Point(0, 408)
    $statusStrip1.Name = "statusStrip1"
    $statusStrip1.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::Professional
    $statusStrip1.Size = New-Object System.Drawing.Size($setwidth, 42)
    $statusStrip1.TabIndex = 0

    $toolStripStatusLabel.Name = "toolStripStatusLabel"
    $toolStripStatusLabel.Size = New-Object System.Drawing.Size(157, 32)
    $toolStripStatusLabel.Text = "Status:"

# Main Form
    $form.FormBorderStyle = "FixedToolWindow";
    $form.Text = "Bier Spiks, Pipol Mumbel";
    $form.StartPosition = "CenterScreen";
    $form.ClientSize = New-Object System.Drawing.Size($setwidth, $setheight)
    # $form.Width = $setwidth; $form.Height = $setheight;

# Add Everything to form
    $form.Controls.Add($welcometext)
    $form.controls.add($BtnGetOrders);
    $form.controls.add($BtnChangeStatus);
    $form.controls.add($RangeTB);
    $form.controls.add($RangeTBtext);
    $form.controls.add($RangeTBend);
    $form.controls.add($RangeTBendtext);
    $form.controls.add($pictureBox);
    $form.controls.add($statusStrip1);

## Add action
    $BtnGetOrders.Add_click({ Update-StatusLabel "Working On Pending Orders..."; Get-OrdersJson 3 $pprms })
    $BtnChangeStatus.Add_click({ Get-UpdateRange $pprms })

## Show Form
    Write-Host "Show form" (Get-Date);
    $form.Add_Shown({ $form.Activate(); <# $okButton.Focus #>});
    $form.ShowDialog();


    
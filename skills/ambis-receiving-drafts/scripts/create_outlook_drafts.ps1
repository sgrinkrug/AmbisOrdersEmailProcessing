param(
    [Parameter(Mandatory = $true)]
    [string]$InputJson,

    [switch]$NoSkipExisting,

    [switch]$UpdateExisting,

    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

function Get-JsonText {
    param([string]$PathOrJson)

    if (Test-Path -LiteralPath $PathOrJson) {
        return Get-Content -LiteralPath $PathOrJson -Raw
    }

    return $PathOrJson
}

function ConvertTo-HtmlText {
    param($Value)

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function ConvertTo-HtmlBody {
    param($Order)

    $itemBlocks = @()
    $itemIndex = 0
    foreach ($item in @($Order.items)) {
        $itemIndex += 1
        $lineNumber = [string]$item.lineNumber
        if ([string]::IsNullOrWhiteSpace($lineNumber)) {
            $lineNumber = [string]$itemIndex
        }

        $quantity = [string]$item.quantity
        $unit = [string]$item.unit
        $quantityText = if ([string]::IsNullOrWhiteSpace($unit)) {
            $quantity
        } else {
            "$quantity $unit"
        }

        $itemBlocks += "$(ConvertTo-HtmlText $lineNumber). $(ConvertTo-HtmlText $item.description) ,  $(ConvertTo-HtmlText $quantityText)"
    }

    $itemsText = $itemBlocks -join "<br>`r`n"
    $vendor = ConvertTo-HtmlText $Order.vendor
    $orderTotal = ConvertTo-HtmlText $Order.orderTotal
    $url = ConvertTo-HtmlText $Order.url

    return @"
<html>
<body>
<p>Good day,</p>

<p>The order with $vendor has been placed.</p>

<p>Items ordered:<br>
$itemsText</p>

<p>Order Total: $orderTotal</p>

<p><strong>When the package arrives, please reply to this email and include the following</strong></p>
<ol>
<li>Packing Slip</li>
<li>Hand-written note on the slip - "Received" or "Partially received"</li>
<li>Receiver's signature on the slip (wet signature)</li>
<li>Statement (in the email body) indicating what was received, i.e.</li>
</ol>

<p>Example 1: I received all items.<br>
Example 2: I received partial shipment, only line item [description] was delivered.<br>
Example 3: I received partial shipment, only 5 out of 10 items for [description] were delivered.</p>

<p><a href="$url">$url</a></p>
</body>
</html>
"@
}

function Find-ExistingDraft {
    param(
        $DraftsFolder,
        [string]$Subject
    )

    foreach ($item in @($DraftsFolder.Items)) {
        if ($item.Subject -eq $Subject) {
            return $item
        }
    }

    return $null
}

$jsonText = Get-JsonText -PathOrJson $InputJson
$orders = $jsonText | ConvertFrom-Json
if ($orders.PSObject.Properties.Name -contains 'orders') {
    $orders = $orders.orders
}

$results = @()

if ($ValidateOnly) {
    foreach ($order in @($orders)) {
        $body = ConvertTo-HtmlBody -Order $order
        $results += [PSCustomObject]@{
            Seq = [string]$order.seq
            DraftCreated = $false
            SkippedExisting = $false
            RecipientsResolved = $null
            To = [string]$order.to
            Subject = "Please confirm the receiving for AMBIS request #$($order.seq)"
            BodyPreview = $body.Substring(0, [Math]::Min(200, $body.Length))
        }
    }

    $results | ConvertTo-Json -Depth 6
    exit 0
}

$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNamespace('MAPI')
$draftsFolder = $namespace.GetDefaultFolder(16)

foreach ($order in @($orders)) {
    $subject = "Please confirm the receiving for AMBIS request #$($order.seq)"
    $existing = $null

    if (-not $NoSkipExisting) {
        $existing = Find-ExistingDraft -DraftsFolder $draftsFolder -Subject $subject
    }

    if ($existing -ne $null) {
        if ($UpdateExisting) {
            $existing.To = [string]$order.to
            $existing.BodyFormat = 2
            $existing.HTMLBody = ConvertTo-HtmlBody -Order $order
            $resolved = $existing.Recipients.ResolveAll()
            $existing.Save()

            $results += [PSCustomObject]@{
                Seq = [string]$order.seq
                DraftCreated = $false
                DraftUpdated = $true
                SkippedExisting = $false
                RecipientsResolved = [bool]$resolved
                To = [string]$existing.To
                Subject = [string]$existing.Subject
            }
            continue
        }

        $results += [PSCustomObject]@{
            Seq = [string]$order.seq
            DraftCreated = $false
            DraftUpdated = $false
            SkippedExisting = $true
            RecipientsResolved = $null
            To = [string]$existing.To
            Subject = [string]$existing.Subject
        }
        continue
    }

    $mail = $outlook.CreateItem(0)
    $mail.To = [string]$order.to
    $mail.Subject = $subject
    $mail.BodyFormat = 2
    $mail.HTMLBody = ConvertTo-HtmlBody -Order $order
    $resolved = $mail.Recipients.ResolveAll()
    $mail.Save()

    $results += [PSCustomObject]@{
        Seq = [string]$order.seq
        DraftCreated = $true
        DraftUpdated = $false
        SkippedExisting = $false
        RecipientsResolved = [bool]$resolved
        To = [string]$mail.To
        Subject = [string]$mail.Subject
    }
}

$results | ConvertTo-Json -Depth 6

# seed-atlas.ps1: Seed initial customers and opening ledger transactions into MongoDB Atlas via Backend API
$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Logging in as Owner..." -ForegroundColor Cyan
$loginBody = @{ username = "owner@tiffin.local"; password = "Password123!" } | ConvertTo-Json
$authResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($loginBody)) -ContentType "application/json; charset=utf-8"
$token = $authResponse.accessToken
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json; charset=utf-8"
}

Write-Host "Fetching current customers in MongoDB Atlas..." -ForegroundColor Cyan
$existingPage = Invoke-RestMethod -Uri "http://localhost:8080/api/customers?size=50" -Method Get -Headers $headers
$existingNames = @()
if ($existingPage.content) {
    $existingNames = $existingPage.content | ForEach-Object { $_.name }
}

$customersToSeed = @(
    @{
        name = "Ramesh (Auto)"
        aliases = @("రమేష్", "రామేష్", "Auto Ramesh", "ఆటో రమేష్")
        phoneNumber = "9848011223"
        notes = "Bus stand auto stand driver. Morning breakfast daily."
        initialDebtPaise = 25000
        pageNumber = "Page 12"
    },
    @{
        name = "Ramesh (Master)"
        aliases = @("రమేష్ మాస్టారు", "Teacher Ramesh", "Ramesh Teacher")
        phoneNumber = "9988776655"
        notes = "Govt High School teacher. Monthly settlement."
        initialDebtPaise = 15000
        pageNumber = "Page 15"
    },
    @{
        name = "Suresh (Tailor)"
        aliases = @("సురేష్", "టైలర్ సురేష్")
        phoneNumber = "9440123456"
        notes = "Opposite cloth shop tailor."
        initialDebtPaise = 5000
        pageNumber = "Page 18"
    },
    @{
        name = "Venkatesh (Electrician)"
        aliases = @("వెంకటేష్", "వెంకట్")
        phoneNumber = "9866123789"
        notes = "Weekly payment."
        initialDebtPaise = 32000
        pageNumber = "Page 22"
    },
    @{
        name = "Laxmi (Flower Vendor)"
        aliases = @("లక్ష్మి", "పూల లక్ష్మి")
        phoneNumber = "9123456780"
        notes = "Evening snacks & tea."
        initialDebtPaise = 12000
        pageNumber = "Page 25"
    }
)

foreach ($c in $customersToSeed) {
    $custId = $null
    
    # Check if customer already exists
    $found = $null
    if ($existingPage.content) {
        $found = $existingPage.content | Where-Object { $_.name -eq $c.name }
    }

    if ($null -ne $found) {
        $custId = $found.id
        Write-Host "[=] Customer already exists: $($c.name) (ID: $custId)" -ForegroundColor DarkGray
    } else {
        $custObj = @{
            name = $c.name
            aliases = $c.aliases
            phoneNumber = $c.phoneNumber
            notes = $c.notes
        }
        $custBytes = [System.Text.Encoding]::UTF8.GetBytes(($custObj | ConvertTo-Json))
        $created = Invoke-RestMethod -Uri "http://localhost:8080/api/customers" -Method Post -Headers $headers -Body $custBytes -ContentType "application/json; charset=utf-8"
        $custId = $created.id
        Write-Host "[+] Created customer: $($created.name) (ID: $custId)" -ForegroundColor Green
    }

    # Record opening balance if not already present
    if ($c.initialDebtPaise -gt 0) {
        try {
            $obObj = @{
                customerId = $custId
                amountPaise = $c.initialDebtPaise
                notebookPageNumber = $c.pageNumber
                notes = "Migrated from physical notebook $($c.pageNumber)"
            }
            $obBytes = [System.Text.Encoding]::UTF8.GetBytes(($obObj | ConvertTo-Json))
            $txHeaders = @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json; charset=utf-8"
                "Idempotency-Key" = "seed_ob_$custId"
            }
            $tx = Invoke-RestMethod -Uri "http://localhost:8080/api/transactions/opening-balance" -Method Post -Headers $txHeaders -Body $obBytes -ContentType "application/json; charset=utf-8"
            Write-Host "    -> Recorded Opening Debt: Rs $($c.initialDebtPaise / 100.0) ($($c.pageNumber))" -ForegroundColor Green
        } catch {
            Write-Host "    -> Opening balance already exists or recorded: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
}

Write-Host "`nAll 5 Telugu customers and opening debt records successfully seeded into MongoDB Atlas!" -ForegroundColor Cyan

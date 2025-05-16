
. .\_common-functions.ps1

function Confirm-Stack {
    # this function was used for debugging purposes only
    param(
        [string[]]$Stack
    )

    $clubCounter = 0
    $heartCounter = 0
    $diamondCounter = 0

    $aceCounter = 0
    $twoCounter = 0
    $threeCounter = 0

    foreach ($card in $Stack) {
        $value = $card.Substring(0,1)
        $suit = $card.Substring(1,1)

        switch ($value) {
            1 {
                $aceCounter++
                break
            }
            2 {
                $twoCounter++
                break
            }
            3 {
                $threeCounter++
                break
            }
            Default {
                Write-Warning "unknown value detected`: $card"   
                break
            }
        }

        switch ($suit) {
            'c' {
                $clubCounter++
                break
            }
            'h' {
                $heartCounter++
                break
            }
            'd' {
                $diamondCounter++
                break
            }
            Default {
                Write-Warning "unknown suit detected`: $card"   
                break
            }
        }
    }

    if ($aceCounter -eq 3 -and $twoCounter -eq 3 -and $threeCounter -eq 3 -and $clubCounter -eq 3 -and $heartCounter -eq 3 -and $diamondCounter -eq 3) {
        return ($true)
    }
    else {
        return ($false)
    }

}

<# MANUAL STEPS
    1. 3 piles of 3 cards:
        - ace, 2, 3 of hearts, clubs, and diamonds
    2. do this 3 times:
        - shuffle pile, separate into new 3 pile
    3. stack piles together how spectator wants
    4. cut as many times they want
    5. then do the following 3 times:
        - separate into 2 piles
        - stack back into 1 pile either way
    6. spell out CLUB: each letter goes under, but drop down B into new pile
    7. spell out HEART: each letter goes under, but drop down T into 2nd new pile
    8. spell out DIAMOND: each letter goes under, but drop down D into 3rd new pile
    9. spell out CLUB: each letter goes under, but drop down B into 3rd pile (going backwards now)
    10. spell out HEART: each letter goes under, but drop down T into 2nd new pile
    11. spell out DIAMOND: each letter goes under, but drop down D into 1st new pile
    12. deal out remaining 3 cards starting on 3rd pile then 2nd then 1st
    13. each pile should have the same suit (order doesn't matter)
#>

$timesGood = 0
$timesBad = 0
$maxTries = 1000

$outputObjects = @()
$outputFolder = '.\outputs'
if (!(Test-Path $outputFolder)) {
    $null = mkdir $outputFolder -Force
}
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$outputFile = ".\outputs\$scriptName.xml"

$suits = @('clubs','hearts','diamonds')

$activity = "Performing 3 of 3s trick.."
for ($attempt=1;$attempt -le $maxTries;$attempt++) {

    Write-Progress -Id 1 -Activity $activity -Status $attempt -PercentComplete ($attempt/$maxTries*100)

    # create initial piles - these will always be the same
    $piles = @{}
    $index = 0
    foreach ($suit in $suits) {
        $piles[$index] = ("1{0},2{0},3{0}" -f "$suit".Substring(0,1)) -split ','
        $index++
    }
    $InitialPiles = foreach ($key in $Piles.Keys) { "$($key+1)`: $($Piles[$key] -join '; ')"  }
    $InitialPiles = $InitialPiles | Sort-Object

    # shuffle each pile
    $newPiles = @{}
    for ($i=0; $i -lt 3; $i++) {
        $shuffled = $null = $piles[$i] | Sort-Object {Get-Random}
        for ($j=0; $j -lt 3; $j++) {
            $newPiles[$j] += @($shuffled[$j])
        }
    }
    $ShuffledPiles = foreach ($key in $newPiles.Keys) { "$($key+1)`: $($newPiles[$key] -join '; ')"  }
    $ShuffledPiles = $ShuffledPiles | Sort-Object

    # stack and cuts
    $stack = $newPiles.GetEnumerator() | Sort-Object {Get-Random} | Select-Object -ExpandProperty Value

    $stack = Invoke-CutCards -Deck $stack -Complete
    #if (!(Confirm-Stack -Stack $stack)) { Write-Host "Stack failed after Cutting Cards" -ForegroundColor Red }

    # do 3 times: 2 pile deal and re-stack
    for ($i=0; $i -lt 3; $i++) {
        # deal out 2 piles
        $pile1 = @()
        $pile2 = @()
        for ($j=0; $j -le ($stack.Count - 1); $j++) {
            if ($j % 2 -eq 0) {
                $pile1 += $stack[$j]
            }
            else {
                $pile2 += $stack[$j]
            }
        }

        # re-stack
        $stackPick = $null
        $stackPick = 1..2 | Get-Random
        if ($stackPick -eq 1) {
            $stack = $pile1 + $pile2
        }
        else {
            $stack = $pile2 + $pile1
        }
    }

    # now do the letter counting to final piles
    $FinalPile1 = @()
    $FinalPile2 = @()
    $FinalPile3 = @()
    $remaining = $stack

    # spell out CLUB
    $remaining = Invoke-TopToBottom -Deck $remaining -Cards 3
    $FinalPile1 += $remaining[0]
    $remaining = $remaining[1..($remaining.Count - 1)]

    # now HEART
    $remaining = Invoke-TopToBottom -Deck $remaining -Cards 4
    $FinalPile2 += $remaining[0]
    $remaining = $remaining[1..($remaining.Count - 1)]

    # now DIAMOND
    $remaining = Invoke-TopToBottom -Deck $remaining -Cards 6
    $FinalPile3 += $remaining[0]
    $remaining = $remaining[1..($remaining.Count - 1)]

    # CLUB again but start on final pile 3
    $remaining = Invoke-TopToBottom -Deck $remaining -Cards 3
    $FinalPile3 += $remaining[0]
    $remaining = $remaining[1..($remaining.Count - 1)]

    # now HEART
    $remaining = Invoke-TopToBottom -Deck $remaining -Cards 4
    $FinalPile2 += $remaining[0]
    $remaining = $remaining[1..($remaining.Count - 1)]

    # now DIAMOND
    $remaining = Invoke-TopToBottom -Deck $remaining -Cards 6
    $FinalPile1 += $remaining[0]
    $remaining = $remaining[1..($remaining.Count - 1)]

    # deal out remaining cards
    $FinalPile3 += $remaining[0]
    $FinalPile2 += $remaining[1]
    $FinalPile1 += $remaining[2]

    $FinalPile1Count = $FinalPile1 | ForEach-Object { "$_".Substring(1,1) } | Sort-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count
    $FinalPile2Count = $FinalPile2 | ForEach-Object { "$_".Substring(1,1) } | Sort-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count
    $FinalPile3Count = $FinalPile3 | ForEach-Object { "$_".Substring(1,1) } | Sort-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count

    # remaining card should equal goal
    if ($FinalPile1Count -eq 1 -and $FinalPile2Count -eq 1 -and $FinalPile3Count -eq 1) {
        $result = $true
        ++$timesGood
    }
    else {
        $result = $false
        ++$timesBad
    }

    $outputObjects += [pscustomobject]@{
        #InitialPiles = $InitialPiles -join ','
        ShuffledPiles = $ShuffledPiles -join ','
        Stack = $stack -join ','
        Remaining = $remaining -join ','
        FinalPile1 = $FinalPile1 -join ','
        FinalPile2 = $FinalPile2 -join ','
        FinalPile3 = $FinalPile3 -join ','
        Result = $result
    }

    Start-Sleep -Milliseconds 50
}

Write-Progress -Id 1 -Activity $activity -Completed

$outputObjects | Export-Clixml $outputFile -Force

Write-Host "times Good = $timesGood | times bad = $timesBad"
Write-Host "Percentage = $($timesGood/($timesGood+$timesBad)*100)"

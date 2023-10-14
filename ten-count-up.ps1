. .\_common-functions.ps1


<# MANUAL STEPS
    1. shuffle deck
    2. take the top 7 cards off the deck, rest go into remaining pile/deck
    3. shuffle 7 cards, bottom card = goal
    4. with remaining deck, count out 19 cards into another pile
    5. combine remaining deck plus the 7 underneath remaining plus the 19 cards underneath (remaining + 7 + 19)
    6. do this for dealing out 3 piles:
        - remember first card and get value (face cards are 10)
        - without covering the first card, count up to 10 (e.g. dealt 7 so deal 3 more cards; if it were 10 then go to next pile)
    7. add up the values of the first cards from the 3 piles
    8. deal out that amount from the remaining deck, last one is goal
#>


$timesGood = 0
$timesBad = 0
$maxTries = 10000

$outputObjects = @()
$outputFolder = '.\outputs'
if (!(Test-Path $outputFolder)) {
    $null = mkdir $outputFolder -Force
}
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$outputFile = ".\outputs\$scriptName.xml"

for ($i=1;$i -le $maxTries;$i++) {

    Write-Progress -Activity "Performing Ten Count Up trick.." -Status $i -PercentComplete ($i/$maxTries*100)
    $shuffledDeck = New-Deck -SuitsMatter | Invoke-ShuffleDeck

    # get 7 cards and shuffle them (not really needed)
    $sevenCards = $shuffledDeck[0..6]
    $shuffledSevenCards = $sevenCards | Get-Random -Count $sevenCards.Count

    # get goal - now technically suits matter since we're looking for a specific card
    $goal = $shuffledSevenCards[-1]

    # now get 19 more
    $nineteen = $shuffledDeck[7..25]

    # set the remaining deck
    $remainingDeck = $shuffledDeck[26..51]

    # re-combine deck
    $newDeckOrder = $remainingDeck + $shuffledSevenCards + $nineteen

    $cardIndex = 0
    $addedValues = 0

    # 3 piles to countdown
    $Piles = @(1,2,3)
    foreach ($pile in $Piles) {
        ++$cardIndex

        # first card and add it to running total
        $cardValue = Get-CardValue -Card $newDeckOrder[$cardIndex] -FacesAreTen
        $addedValues += $cardValue

        if ($cardValue -eq 10) {
            # do nothing - starting new pile
        }
        else {
            # not 10 so count that many cards
            # we don't have to save the pile - just need to get values
            $cardIndex += 10 - $cardValue
        }
    }

    # check if goal = cardIndex + addedValues
    $endedWithCard = $newDeckOrder[($cardIndex + $addedValues - 1)]
    if ($goal -eq $endedWithCard) {
        ++$timesGood
        $result = 'Good'
    }
    else {
        ++$timesBad
        $result = 'Bad'
    }

    $newObject = [pscustomobject]@{
        ShuffledDeck = $shuffledDeck -join ','
        NewDeckOrder = $newDeckOrder -join ','
        Goal = $goal
        EndedWithCard = $endedWithCard
        Result = $result
    }

    $outputObjects += $newObject

    Start-Sleep -Milliseconds 50
}

Write-Progress -Completed $true

$outputObjects | Export-Clixml $outputFile -Force

Write-Host "times Good = $timesGood | times bad = $timesBad"
Write-Host "Percentage = $($timesGood/$maxTries*100)"

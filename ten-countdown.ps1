. .\_common-functions.ps1


<# MANUAL STEPS
    1. shuffle deck
    2. show that the deck is shuffled, taking note of the 9th last card, this will be your prediction (i.e. goal)
    3. do this four times:
      a. dealing cards counting down from 10
      b. if a card value matches the countdown number then stop and move to next pile (face cards are 0)
      c. otherwise, if after counting down to 1 and there wasn't a match then put another card to "cover" that pile and then move to next pile
    3. after 4 piles are dealt, add up the non-covered card values from the 4 piles
    4. count that amount into the remaining deck and the last card will be the prediction
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

    Write-Progress -Activity "Performing 10 Countdown.." -Status $i -PercentComplete ($i/$maxTries*100)
    $shuffledDeck = New-Deck -SuitsMatter | Invoke-ShuffleDeck

    # get the 9th last card
    $goal = $shuffledDeck[-9]

    $cardIndex = 0
    $addedValues = 0

    # 4 piles to countdown
    $Piles = @()
    $Piles += [PSCustomObject]@{Num=1;Cards=@()}
    $Piles += [PSCustomObject]@{Num=2;Cards=@()}
    $Piles += [PSCustomObject]@{Num=3;Cards=@()}
    $Piles += [PSCustomObject]@{Num=4;Cards=@()}

    foreach ($pile in $Piles) {
        for ($cd=10;$cd -ge 1;$cd--) {
            ++$cardIndex
            $pile.Cards += $shuffledDeck[$cardIndex]
            $cardValue = Get-CardValue -Card ($shuffledDeck[$cardIndex]) -FacesAreZero

            if ($cardValue -eq $cd) {
                $addedValues += $cardValue
                break
            }
        }

        if ($cd -eq 0) {
            # no matching values so add 1 card to "cover up"
            ++$cardIndex
            $pile.Cards += $shuffledDeck[$cardIndex]
        }
    }

    # check if goal = cardIndex + addedValues
    $endedWithCard = $shuffledDeck[($cardIndex + $addedValues - 1)]
    if ($goal -eq $endedWithCard) {
        ++$timesGood
        $result = 'Good'
    }
    else {
        ++$timesBad
        $result = 'Bad'
    }

    # extra debugging values
    $PilesInLongString = ''
    foreach ($pile in $Piles) {
        $PilesInLongString += ($pile.Cards -join ',')
        $PilesInLongString += '-'
    }
    
    $outputObjects += [pscustomobject]@{
        Deck = $shuffledDeck -join ','
        Piles = $PilesInLongString.Trim('-')
        GoalValue = $goal
        EndWithCard = $endedWithCard
        Result = $result
    }

    Start-Sleep -Milliseconds 50
}

Write-Progress -Completed $true

$outputObjects | Export-Clixml $outputFile -Force

Write-Host "times Good = $timesGood | times bad = $timesBad"
Write-Host "Percentage = $($timesGood/$maxTries*100)"

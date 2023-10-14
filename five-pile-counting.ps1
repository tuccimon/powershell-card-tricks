. .\_common-functions.ps1


<# MANUAL STEPS
    1. shuffle deck
    2. do this five times: deal card, count up to king, turn over pile
    3. ask spectator to discard 2 of the 5 piles (or randomly), place them under the remaining deck
    4. remaining piles (3 of them) can be reordered (but not shuffled individually); so 1st pile can be 3rd pile, 2nd can be 1st, etc
    5. turn over cards on pile #1 and #3, get their values
    6. add their values plus 10
    7. count remaining pile's cards by that amount and discard cards
    8. the remaining number of cards = pile #2's first card's value
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

    Write-Progress -Activity "Performing Five Pile Counting trick.." -Status $i -PercentComplete ($i/$maxTries*100)
    $shuffledDeck = New-Deck | Invoke-ShuffleDeck

    $cardIndex = 0

    # 5 piles to countdown
    $Piles = @()
    $Piles += [pscustomobject]@{Num=1;Cards=@()}
    $Piles += [pscustomobject]@{Num=2;Cards=@()}
    $Piles += [pscustomobject]@{Num=3;Cards=@()}
    $Piles += [pscustomobject]@{Num=4;Cards=@()}
    $Piles += [pscustomobject]@{Num=5;Cards=@()}

    foreach ($pile in $Piles) {
        ++$cardIndex
        $cd = $shuffledDeck[$cardIndex-1]

        $cardValue = Get-CardValue -Card $cd -FacesHaveValue

        if ($cardValue -eq 13) {
            # it's a king - next pile
            $pile.Cards += $cd
        }
        else {
            # get pile card set
            $pileCount = 13 - $cardValue
            $pile.Cards = ($shuffledDeck)[($cardIndex-1)..($cardIndex+$pileCount-1)]
            $cardIndex += $pileCount
        }
    }

    # get remaining pile cards
    $RemainingPile = ($shuffledDeck)[$cardIndex..51]


    # selected/random 2 piles selected to be placed under remaining pile (goal still unknown)
    # to make coding easier, we're just going to shuffle 5 and the last 2 numbers will be placed under remaining pile

    $shuffledPiles = $Piles | Get-Random -Count $Piles.Count

    $RemainingPile += $shuffledPiles[3].Cards
    $RemainingPile += $shuffledPiles[4].Cards

    # randomize order of the remaining 3 piles
    $ThreePiles = $shuffledPiles[0..2]
    $shuffledThree = $ThreePiles | Get-Random -Count $ThreePiles.Count

    # turn over new pile 1 and 3's top cards, goal is now top card on pile 2
    # get values of top card on pile 1 and 2, add them and + 10
    $Pile1 = $shuffledThree[0].Cards
    $Pile2 = $shuffledThree[1].Cards
    $Pile3 = $shuffledThree[2].Cards

    $goal = (Get-CardValue -Card $Pile2[0] -FacesHaveValue)
    $RemainingPileCountdown = (Get-CardValue -Card $Pile1[0] -FacesHaveValue) + (Get-CardValue -Card $Pile3[0] -FacesHaveValue) + 10

    # finally remove countdown from remaining pile and then count remaining cards
    $CountOfLeftOver = ($RemainingPile[($RemainingPileCountdown)..($RemainingPile.Count - 1)]).Count

    # check if goal = count of left over = goal
    if ($goal -eq $CountOfLeftOver) {
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
        RemainingPile = $RemainingPile -join ','
        Pile1ShuffedUnder = $shuffledPiles[3].Num
        Pile2ShuffedUnder = $shuffledPiles[4].Num
        RemainingPile1 = $shuffledThree[0].Num
        RemainingPile2 = $shuffledThree[1].Num
        RemainingPile3 = $shuffledThree[2].Num
        GoalValue = $goal
        CountOfLeftOver = $CountOfLeftOver
        Result = $result
    }

    Start-Sleep -Milliseconds 50
}

Write-Progress -Completed $true

$outputObjects | Export-Clixml $outputFile -Force

Write-Host "times Good = $timesGood | times bad = $timesBad"
Write-Host "Percentage = $($timesGood/$maxTries*100)"

. .\_common-functions.ps1


<# MANUAL STEPS
    Note: This is very similar to five-pile-counting.ps1 but with zero chance to fail.
    1. shuffle deck
    2. do this five times: deal card, count up to king, then go to next pile; if last pile can't make it to king then it becomes the "remaining" deck
    3. ask spectator to choose 3 piles to keep (these would then be turned over, face down), the rest go to remaining deck (order doesn't matter)
    4. take remaining deck and discard 10 cards
    5. goal = count of remaining deck = values of top card from each pile
    Note: in person, I prefer to do the following:
        - ask the spectator to reveal one of the top cards from the 3 piles and then discard that from the remaining deck
        - ask spectator to reveal another one of the top cards from the other 2 piles and then discard that from the remaining deck
        - tell spectator wait, count the remaining deck and then say the next card is that value
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

    Write-Progress -Activity "Performing All Pile Counting trick.." -Status $i -PercentComplete ($i/$maxTries*100)
    $shuffledDeck = New-Deck | Invoke-ShuffleDeck

    $cardIndex = 0

    # get piles
    $Piles = @()
    $pileNumber = 0

    $cardIndex = 0
    $breakLoop = $false
    $naturalBreak = $false

    while ($breakLoop -ne $true) {
        ++$cardIndex
        if ($cardIndex -le 52) {
            $cd = $shuffledDeck[$cardIndex-1]

            $cardValue = Get-CardValue -Card $cd -FacesHaveValue

            ++$pileNumber

            if ($cardValue -eq 13) {
                # next pile
                $Piles += [pscustomobject]@{Num=$pileNumber;Cards=@($cd)}
            }
            else {
                # get pile card set
                $pileCount = 13 - $cardValue
                $pileCounter = 0
                $breakInnerLoop = $false
                $Cards = $null = @($cd)
                while ($breakInnerLoop -ne $true) {
                    ++$pileCounter
                    if ($pileCounter -le $pileCount) {
                        ++$cardIndex
                        if ($cardIndex -le 52) {
                            $Cards += $shuffledDeck[$cardIndex-1]
                        }
                        else {
                            # ran out of cards
                            $breakInnerLoop = $true
                            $breakLoop = $true
                        }
                    }
                    else {
                        # counted up to pilecount without problems - exit inner loop only
                        $breakInnerLoop = $true
                    }
                }

                $Piles += [pscustomobject]@{Num=$pileNumber;Cards=$Cards}
            }
        }
        else {
            # ideal but rare break
            $breakLoop = $true
            $naturalBreak = $true
        }
    }

    # get the number of piles
    $totalPiles = $Piles.Count

    # choose 3 random piles to remain, and the get added to remaining pile

    # get remaining pile cards
    if ($naturalBreak) {
        $RemainingPile = @()
        # use all - nothing to exclude
        $shuffledPiles = $Piles[0..($totalPiles-1)] | Get-Random -Count $Piles.Count
    }
    else {
        $RemainingPile = @($Piles[-1])
        # exclude remaining pile
        $shuffledPiles = $Piles[0..($totalPiles-2)] | Get-Random -Count $Piles.Count
    }

    $StayOnTable = @()
    $StayOnTable += $shuffledPiles[0]
    $StayOnTable += $shuffledPiles[1]
    $StayOnTable += $shuffledPiles[2]

    $pileIndex = 0
    foreach ($pile in $shuffledPiles) {
        ++$pileIndex
        if ($pileIndex -ge 1 -and $pileIndex -le 3) {
            # ignore
        }
        else {
            $RemainingPile += $pile
        }
    }

    $goal = 0
    $goal += Get-CardValue -Card ($shuffledPiles[0].Cards)[0] -FacesHaveValue
    $goal += Get-CardValue -Card ($shuffledPiles[1].Cards)[0] -FacesHaveValue
    $goal += Get-CardValue -Card ($shuffledPiles[2].Cards)[0] -FacesHaveValue


    # for remaining deck, let's remove 10, count out the rest and see if it matches the goal
    $RemainingCount = ($RemainingPile.Cards).Count
    $RemainingCountMinusTen = $RemainingCount - 10

    # check if goal = remaining count
    if ($goal -eq $RemainingCountMinusTen) {
        ++$timesGood
        $result = 'Good'
    }
    else {
        ++$timesBad
        $result = 'Bad'
    }

    $PilesInLongString = ''

    foreach ($pile in $Piles) {
        $PilesInLongString += ($pile.Cards -join ',')
        $PilesInLongString += '-'
    }

    $newObject = [pscustomobject]@{
        ShuffledDeck = $shuffledDeck -join ','
        PilesInLongString = $PilesInLongString.Trim('-')
        NaturalBreak = $naturalBreak
        RemainingCountMinusTen = $RemainingCountMinusTen
        Goal = $goal
        Result = $result
    }

    foreach ($pile in $shuffledPiles) {
        $pileNum = $pile.Num
        $pileCards = $pile.Cards -join ''
        $noteProp = ("Pile{0}" -f "$pileNum".PadLeft(2,'0'))
        $null = $newObject | Add-Member -MemberType NoteProperty -Name $noteProp -Value $pileCards
    }

    $outputObjects += $newObject

    Start-Sleep -Milliseconds 50
}

Write-Progress -Completed $true

$outputObjects | Export-Clixml $outputFile -Force

Write-Host "times Good = $timesGood | times bad = $timesBad"
Write-Host "Percentage = $($timesGood/$maxTries*100)"

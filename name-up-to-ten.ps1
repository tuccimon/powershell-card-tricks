. .\_common-functions.ps1


<# MANUAL STEPS
    1. shuffle deck
    2. drop off 19 cards to a pile (that will be the bottom)
    3. count the letters of your spectator's name
    4. shuffle if wanted, but get the bottom of that name-counted pile = goal
    5. put name-counted pile on bottom stack
    6. put other cards on top
    7. starting from the top, deal 3 cards into their own pile. for each pile:
        - get value of card
            - if 10 then continue to next pile
            - else deal 10 - value number of cards to that pile
    8. once 3 piles accounted for, add the original 3 cards' values, and then deal out that many
    9. last card dealt should be goal
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

    Write-Progress -Activity "Spectator's name and Up to Ten trick.." -Status $i -PercentComplete ($i/$maxTries*100)
    $shuffledDeck = New-Deck -SuitsMatter | Invoke-ShuffleDeck

    # take out 19 cards
    $nineteenCards = $shuffledDeck[0..18]

    # take out name-counted cards (going to use random to get the #)
    #$nameLength = Get-Random -Minimum 2 -Maximum 20
    $nameLength = Get-Random -Minimum 20 -Maximum 26
    # mini formula is simply 18 + <name counted cards amout> = the x in [19..x]
    $x = 18 + $nameLength
    $nameCounted = $shuffledDeck[19..($x)]

    # get goal - now technically suits matter since we're looking for a specific card
    $goal = $nameCounted[-1]

    # set the remaining deck [(x+1)..51]
    $remainingDeck = $shuffledDeck[($x+1)..51]

    # re-combine deck
    $newDeckOrder = $remainingDeck + $nameCounted + $nineteenCards

    # deal out 3 cards
    $firstCard = $newDeckOrder[0]
    $firstCardValue = Get-CardValue -Card $newDeckOrder[0] -FacesAreTen

    $secondCard = $newDeckOrder[1]
    $secondCardValue = Get-CardValue -Card $newDeckOrder[1] -FacesAreTen

    $thirdCard = $newDeckOrder[2]
    $thirdCardValue = Get-CardValue -Card $newDeckOrder[2] -FacesAreTen

    $addedValues = $firstCardValue + $secondCardValue + $thirdCardValue

    $cardIndex = 3

    $countOutCards = $null = 10 - $firstCardValue
    $cardIndex += $countOutCards

    $countOutCards = $null = 10 - $secondCardValue
    $cardIndex += $countOutCards

    $countOutCards = $null = 10 - $thirdCardValue
    $cardIndex += $countOutCards

    # check if goal = cardIndex + addedValues
    $cardIndex = $cardIndex - 1 + $addedValues
    $endedWithCard = $newDeckOrder[$cardIndex]
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
        Nineteen = $nineteenCards -join ','
        NameLength = $nameLength
        NameCounted = $nameCounted -join ','
        RemainingDeck = $remainingDeck -join ','
        NewDeckOrder = $newDeckOrder -join ','
        FirstCard = $firstCard
        SecondCard = $secondCard
        ThirdCard = $thirdCard
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

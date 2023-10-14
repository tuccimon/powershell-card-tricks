. .\_common-functions.ps1

<# MANUAL STEPS
    1. shuffle deck (suits matter)
    2. cut off about a third, throw the rest away
    3. shuffle smaller pile (not really needed)
    4. goal = bottom card of third-sized pile (player lies about it saying another card)
    5. run different full spelling of cards against small pile (e.g. queen of hearts), three times
    6. at end, top card of small pile should equal goal
#>

$NamePermutations = @(
    'AceOfSpades',
    'AceOfHearts',
    'AceOfDiamonds',
    'AceOfClubs',
    'TwoOfSpades',
    'TwoOfHearts',
    'TwoOfDiamonds',
    'TwoOfClubs',
    'ThreeOfSpades',
    'ThreeOfHearts',
    'ThreeOfDiamonds',
    'ThreeOfClubs',
    'FourOfSpades',
    'FourOfHearts',
    'FourOfDiamonds',
    'FourOfClubs',
    'FiveOfSpades',
    'FiveOfHearts',
    'FiveOfDiamonds',
    'FiveOfClubs',
    'SixOfSpades',
    'SixOfHearts',
    'SixOfDiamonds',
    'SixOfClubs',
    'SevenOfSpades',
    'SevenOfHearts',
    'SevenOfDiamonds',
    'SevenOfClubs',
    'EightOfSpades',
    'EightOfHearts',
    'EightOfDiamonds',
    'EightOfClubs',
    'NineOfSpades',
    'NineOfHearts',
    'NineOfDiamonds',
    'NineOfClubs',
    'TenOfSpades',
    'TenOfHearts',
    'TenOfDiamonds',
    'TenOfClubs',
    'JackOfSpades',
    'JackOfHearts',
    'JackOfDiamonds',
    'JackOfClubs',
    'QueenOfSpades',
    'QueenOfHearts',
    'QueenOfDiamonds',
    'QueenOfClubs',
    'KingOfSpades',
    'KingOfHearts',
    'KingOfDiamonds',
    'KingOfClubs'
)

$timesGood = 0
$timesBad = 0
$maxTries = 10000   # note that this script due to cycling through many permutations can take hours to run (i.e. change this value to 100 for testing)

$outputObjects = @()
$outputFolder = '.\outputs'
if (!(Test-Path $outputFolder)) {
    $null = mkdir $outputFolder -Force
}
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$outputFile = ".\outputs\$scriptName.xml"


# what accounts for a "third" of the deck
$MinimumCards = 10 - 1  # for a true minimum of 10
$MaximumCards = 20      # anything above 20 can have failures
#$MaximumCards = 26 # half the deck - this shouldn't happen in real life


for ($i=1;$i -le $maxTries;$i++) {

    Write-Progress -Activity "Performing Liar trick.." -Status $i -PercentComplete ($i/$maxTries*100)

    $shuffledDeck = New-Deck -SuitsMatter | Invoke-ShuffleDeck

    # note that there is a bug in Powershell 5.1 where Minimum is never returned
    $ThirdNumber = Get-Random -SetSeed ((Get-Date).Millisecond) -Minimum $MinimumCards -Maximum $MaximumCards

    $ThirdOfDeck = $shuffledDeck[0..$ThirdNumber]

    # it's already shuffled with stacking/cheating, no need to shuffle again
    # now look at the bottom card and that is the goal
    $goal = $ThirdOfDeck[-1]

    # we are going to cycle through all possible "spellings" to see if we ever get fails
    # and then we are going to record their result for each pass

    foreach ($perm in $NamePermutations) {
        # we don't want to modify the original so let's make a new array
        $thisPile = $ThirdOfDeck.Clone()                                           #; $thisPile -join ','
        $firstTime = Invoke-DealAndUnder -Deck $thisPile -DealAmount $perm.Length    #; $firstTime -join ','
        $secondTime = Invoke-DealAndUnder -Deck $firstTime -DealAmount $perm.Length  #; $secondTime -join ','
        $thirdTime = Invoke-DealAndUnder -Deck $secondTime -DealAmount $perm.Length  #; $thirdTime -join ','

        $top = $thirdTime[0]

        # check if permutation worked or not
        if ($top -eq $goal) {
            Invoke-Expression "`$$perm=`$true"
            ++$timesGood
        }
        else {
            Invoke-Expression "`$$perm=`$false"
            ++$timesBad
        }
        Start-Sleep -Milliseconds 50
    }


    $newObject = [pscustomobject]@{
        ShuffledDeck = $shuffledDeck -join ','
        ThirdOfDeck = $ThirdOfDeck -join ','
        ThirdSize = $ThirdOfDeck.Count
        Goal = $goal
    }

    foreach ($perm in $NamePermutations) {
        $value = Invoke-Expression "`$$perm"
        $null = $newObject | Add-Member -MemberType NoteProperty -Name $perm -Value $value
    }

    $outputObjects += $newObject

    Start-Sleep -Milliseconds 50
}

Write-Progress -Completed $true

$outputObjects | Export-Clixml $outputFile -Force

Write-Host "times Good = $timesGood | times bad = $timesBad"
Write-Host "Percentage = $($timesGood/($timesGood+$timesBad)*100)"

. .\_common-functions.ps1

<# MANUAL STEPS
    1. shuffle deck (suits matter)
    2. have spectator pick any card
    3. deal out 8 cards from rest of deck, dump rest of deck
    4. put picked card at position 5 of now 9-card deck (middle position)
    5. now as the following questions (and they can lie or not):
      a. suit?
      b. picture or number?
      c. value (ace to king)?
      d. did they lie (yes or no)?
    6. when they answer, deal cards by spelling out the response
    7. if cards left in hand then drop them on the new pile
    8. remove top and bottom cards
    9. at the end, ask them what their card was, and then show 1 remaining card (should be what they picked)
#>


$CardValues = @(
    'Ace'
    'Two'
    'Three'
    'Four'
    'Five'
    'Six'
    'Seven'
    'Eight'
    'Nine'
    'Ten'
    'Jack'
    'Queen'
    'King'
)


$timesGood = 0
$timesBad = 0
$maxTries = 1000 # in this script's context at least, this denotes the number of different shuffled decks used; permutations to follow

$outputObjects = @()
$outputFolder = '.\outputs'
if (!(Test-Path $outputFolder)) {
    $null = mkdir $outputFolder -Force
}
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$outputFile = ".\outputs\$scriptName.xml"

# needed for suits question
$suits = @('spades','hearts','diamonds','clubs')

$iteration = 0

for ($i=1;$i -le $maxTries;$i++) {

    Write-Progress -Id 1 -Activity "Performing lie detector trick.." -Status $i -PercentComplete ($i/$maxTries*100)

    $shuffledDeck = New-Deck -SuitsMatter | Invoke-ShuffleDeck

    # since deck is shuffled with no "sleight of hand", we can just select the first 9 cards and the 5th will be the goal card
    $pile = $shuffledDeck[0..8]
    $goal = $pile[4]

    # ask for suit but since we're testing all possibilities, we have to account for that
    foreach ($suit in $suits) {
        $postSuitPile = $null = Invoke-DealAndUnder -Deck $pile -DealAmount ($suit.Length)

        # remove top and bottom cards
        $postSuitPile = Remove-TopAndBottomCards -Deck $postSuitPile

        # is picture or number?
        foreach ($item in @('picture','number')) {
            $postPicOrNum = $null = Invoke-DealAndUnder -Deck $postSuitPile -DealAmount ($item.Length)

            # remove top and bottom cards
            $postPicOrNum = Remove-TopAndBottomCards -Deck $postPicOrNum

            # what's the card value?
            foreach ($value in $CardValues) {
                $postCardValue = $null = Invoke-DealAndUnder -Deck $postPicOrNum -DealAmount ($value.Length)

                # remove top and bottom cards
                $postCardValue = Remove-TopAndBottomCards -Deck $postCardValue

                # did they lie during this process?
                foreach ($response in @('yes','no')) {
                    $postResponse = $null = Invoke-DealAndUnder -Deck $postCardValue -DealAmount ($response.Length)

                    # remove top and bottom cards
                    $postResponse = Remove-TopAndBottomCards -Deck $postResponse

                    # remaining card should equal goal
                    if ($goal -eq $postResponse) {
                        $result = $true
                        ++$timesGood
                    }
                    else {
                        $result = $false
                        ++$timesBad
                    }

                    $iteration++

                    $outputObjects += [pscustomobject]@{
                        Index = $iteration
                        ShuffledDeck = $shuffledDeck -join ','
                        PileOfNine = $pile
                        Suit = $suit
                        PostSuit = $postSuitPile
                        PicOrNum = $item
                        PostPicOrNum = $postPicOrNum
                        Value = $value
                        PostValue = $postCardValue
                        Response = $response
                        PostResponse = $postResponse
                        Goal = $goal
                        Result = $result
                    }

                    Start-Sleep -Milliseconds 50
                }
            }
        }
    }
}

Write-Progress -Id 1 -Activity "Performing lie detector trick.." -Completed

$outputObjects | Export-Clixml $outputFile -Force

Write-Host "times Good = $timesGood | times bad = $timesBad"
Write-Host "Percentage = $($timesGood/($timesGood+$timesBad)*100)"

# common functions to help with the rest of the card tricks

function New-Deck {
    param(
        [switch]$WithJokers,
        [switch]$SuitsMatter
    )

    $suit = @{}
    $suit.1 = 's'
    $suit.2 = 'h'
    $suit.3 = 'd'
    $suit.4 = 'c'

    $newDeck = @()

    $baseDeck = "111122223333444455556666777788889999xxxxjjjjqqqqkkkk"
    if ($SuitsMatter) {
        $charArray = $baseDeck.ToCharArray()
        $idx = 0
        foreach ($card in $charArray) {
            ++$idx
            if ($idx -ge 5) {
                $idx = 1
            }
            $newDeck += $card + $suit.$idx
        }
        if ($WithJokers) {
            $newDeck += "r"
            $newDeck += "r"
        }
    }
    else {
        if ($WithJokers) {
            $baseDeck += "rr"
        }
        $newDeck = $baseDeck.ToCharArray()
    }
    return ([string[]]$newDeck)
}

function Invoke-ShuffleDeck {
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$Deck
    )

    begin {
        $tempDeck = @()
    }
    process {
        # workaround for taking in an array from the pipeline
        foreach ($card in $Deck) {
            $tempDeck += $card
        }
    }
    end {
        ($tempDeck | Sort-Object {Get-Random})
    }
}


function Get-CardValue {
    [cmdletbinding(DefaultParameterSetName='FacesHaveValue')]
    param(
        [parameter(Mandatory=$true)]
        $Card,

        [Parameter(ParameterSetName='FacesHaveValue', Mandatory=$true)]
        [switch]$FacesHaveValue,

        [Parameter(ParameterSetName='FacesAreTen', Mandatory=$true)]
        [switch]$FacesAreTen,

        [Parameter(ParameterSetName='FacesAreZero', Mandatory=$true)]
        [switch]$FacesAreZero
    )

    switch ($Card[0].ToString()) {
        'x' {
            $Value = 10
            break
        }
        'j' {
            $Value = 11
            break
        }
        'q' {
            $Value = 12
            break
        }
        'k' {
            $Value = 13
            break
        }
        'r' {
            # jokers are zero - not used
            $Value = 0
            break
        }
        Default {
            $Value = [int]($Card[0].ToString())
            break
        }
    }

    if ($Value -gt 10) {
        if ($FacesAreTen -and $PSCmdlet.ParameterSetName -eq 'FacesAreTen') {
            $Value = 10
        }
        if ($FacesAreZero -and $PSCmdlet.ParameterSetName -eq 'FacesAreZero') {
            $Value = 0
        }
    }

    return $Value
}


function Invoke-CutCards {
    # takes in a deck or pile and then performs a cut (and complete if needed)
    param(
        [string[]]$Deck,
        [switch]$Complete
    )

    $maxCardIndex = $Deck.Length - 1
    $maxCutPoint = $maxCardIndex - 1 # can't cut the whole deck/pile - that wouldn't make sense
    $cutPoint = 0..$maxCutPoint | Get-Random

    if ($Complete) {
        # cut done but now "complete" (put cut cards under remaining pile)
        return ($Deck[($cutPoint+1)..$maxCardIndex] + $Deck[0..$cutPoint])
    }
    else {
        # return cut cards only
        return ($Deck[0..$cutPoint])
    }
}


function Expand-Card {
    param(
        $Card
    )

    $value = $Card[0]
    $suit = $Card[1]

    switch ($value) {
        'k' {
            $valueName = 'king'
            break
        }
        'q' {
            $valueName = 'queen'
            break
        }
        'j' {
            $valueName = 'jack'
            break
        }
        'x' {
            $valueName = 'ten'
            break
        }
        '9' {
            $valueName = 'nine'
            break
        }
        '8' {
            $valueName = 'eight'
            break
        }
        '7' {
            $valueName = 'seven'
            break
        }
        '6' {
            $valueName = 'six'
            break
        }
        '5' {
            $valueName = 'five'
            break
        }
        '4' {
            $valueName = 'four'
            break
        }
        '3' {
            $valueName = 'three'
            break
        }
        '2' {
            $valueName = 'two'
            break
        }
        '1' {
            $valueName = 'ace'
            break
        }
    }

    switch ($suit) {
        's' {
            $suitName = 'spades'
            break
        }
        'h' {
            $suitName = 'hearts'
            break
        }
        'd' {
            $suitName = 'diamonds'
            break
        }
        'c' {
            $suitName = 'clubs'
            break
        }
    }

    return ("$valueName of $suitName")

}


function Invoke-ReverseString {
    param(
        [string]$InputString
    )

    $reversedArray = $InputString.ToCharArray() | ForEach-Object { $_ }
    [array]::Reverse($reversedArray)
    -join $reversedArray
}


function Invoke-DealAndUnder {
    # this takes in a "deck" or pile and then deals out the number
    # specified, and then places that dealt out pile under the remaining
    # returns the new "deck" formation
    param(
        [string[]]$Deck,
        [int]$DealAmount
    )

    if ($DealAmount -ge $Deck.Count) {
        # just reverse the whole thing
        $reversedDeck = $Deck.Clone()
        $null = [array]::Reverse($reversedDeck)
        $reversedDeck
    }
    else {
        $newDeck = @()
        $dealtPile = $Deck[0..($DealAmount-1)]
        $reversedDealtPile = $dealtPile.Clone()
        $null = [array]::Reverse($reversedDealtPile)
        $newDeck += $Deck[$DealAmount..($Deck.Count-1)]        
        $newDeck += $reversedDealtPile
        $newDeck
    }
}

function Invoke-TopToBottom {
    # this function takes in a deck or pile and then take the top card and puts it to the bottom of the deck in hand
    # the number of times is defaulted to 1 but more can be specified
    param(
        [string[]]$Deck,
        [int]$Cards=1
    )

    $maxCardIndex = $Deck.Length - 1

    if ($Cards -lt 1) {
        Write-Error "Cards parameter value must be 1 or greater."
        return
    }
    elseif ($Cards -eq $Deck.Count) {
        # if it's equal then it will just return the Deck back
        return ($Deck)
    }
    elseif ($Cards -gt $Deck.Count) {
        if ($Cards % $Deck.Count -eq 0) {
            # Cards is a multiple of the Deck count which means just return the Deck
            return ($Deck)
        }
        else {
            # there is a remainder
            $realCards = $Cards - $Deck.Count
            return ($Deck[$realCards..($maxCardIndex)] + $Deck[0..($realCards-1)])    
        }
    }
    else {
        # Cards is between 1 and Deck size minus 1
        return ($Deck[$Cards..($maxCardIndex)] + $Deck[0..($Cards-1)])
    }
}


function Remove-TopAndBottomCards {
    # this takes in a "deck" or pile and then removes the top and bottom cards
    # returning the remaining pile
    param(
        [string[]]$Deck
    )

    $totalCards = $Deck.Count

    # last card index ($totalCards - 1) and then subtract 1 to "remove" that last card to get new last card index
    $lastCardIndex = $totalCards - 2

    return ($Deck[1..$lastCardIndex])
}


<# debugging the script variables

$shuffledDeck -join ','
$sevenCards -join ','
$shuffledSevenCards -join ','
$goal
$nineteen -join ','
$remainingDeck -join ','
$newDeckOrder -join ','

#>


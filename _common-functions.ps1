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


<# debugging the script variables

$shuffledDeck -join ','
$sevenCards -join ','
$shuffledSevenCards -join ','
$goal
$nineteen -join ','
$remainingDeck -join ','
$newDeckOrder -join ','

#>


function Find-BinarySearch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Array,

        [Parameter(Mandatory = $true)]
        $Target
    )

    # CORREÇÃO: Ordenamos a lista antes de começar a busca usando o cmdlet Sort-Object.
    $SortedArray = $Array | Sort-Object
    
    $Left = 0
    $Right = $SortedArray.Count - 1

    while ($Left -le $Right) {
        $Mid = [Math]::Floor(($Left + $Right) / 2)
        $CurrentValue = $SortedArray[$Mid]

        if ($CurrentValue -eq $Target) {
            return [PSCustomObject]@{
                Encontrado = $true
                Index      = $Mid
                Mensagem   = "Elemento '$Target' encontrado no índice $Mid da lista ORDENADA."
                ListaOriginal = $Array -join ', '
                ListaOrdenada = $SortedArray -join ', '
            }
        }
        elseif ($CurrentValue -gt $Target) {
            $Right = $Mid - 1
        }
        else {
            $Left = $Mid + 1
        }
    }

    return [PSCustomObject]@{
        Encontrado = $false
        Index      = -1
        Mensagem   = "Elemento '$Target' não foi encontrado."
    }
}

# Testando com uma lista completamente bagunçada:
$ListaBaguncada = 45, 12, 89, 3, 21, 7
Find-BinarySearch -Array $ListaBaguncada -Target 21 | Format-List
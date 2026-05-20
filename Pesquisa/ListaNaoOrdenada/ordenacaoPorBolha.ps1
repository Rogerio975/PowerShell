# Algoritmo de ordenação manualmente utilizando Bubble Sort (Ordenação por Bolha).

function Optimize-BubbleSort {
    param (
        [array]$Array
    )
    # Criamos uma cópia para não alterar o array original externamente
    $LocalArray = $Array.Clone()
    $N = $LocalArray.Count

    # Loop para passar por todo o array
    for ($i = 0; $i -lt $N - 1; $i++) {
        # Otimização: se nenhuma troca acontecer nesta rodada, o array já está ordenado!
        $Swapped = $false

        # Os últimos $i elementos já estão no lugar certo
        for ($j = 0; $j -lt $N - $i - 1; $j++) {
            
            # Se o elemento atual for maior que o próximo, eles trocam de lugar
            if ($LocalArray[$j] -gt $LocalArray[$j + 1]) {
                $Temp = $LocalArray[$j]
                $LocalArray[$j] = $LocalArray[$j + 1]
                $LocalArray[$j + 1] = $Temp
                $Swapped = $true
            }
        }

        # Se não houve troca, podemos parar o loop mais cedo
        if (-not $Swapped) { break }
    }

    return $LocalArray
}

function Find-BinarySearchManual {
    param (
        [array]$Array,
        $Target
    )

    # 1. Ordenação Manual usando o nosso Bubble Sort
    Write-Host "Ordenando a lista manualmente..." -ForegroundColor Gray
    $SortedArray = Optimize-BubbleSort -Array $Array

    # 2. Execução da Pesquisa Binária tradicional
    $Left = 0
    $Right = $SortedArray.Count - 1

    while ($Left -le $Right) {
        $Mid = [Math]::Floor(($Left + $Right) / 2)
        $CurrentValue = $SortedArray[$Mid]

        if ($CurrentValue -eq $Target) {
            return [PSCustomObject]@{
                Encontrado    = $true
                IndexOrdenado = $Mid
                Mensagem      = "Elemento '$Target' encontrado no índice $Mid após a ordenação."
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
        Mensagem   = "Elemento '$Target' não foi encontrado na lista."
    }
}

$DadosBaguncados = 74, 23, 1, 90, 5, 32, 18

Write-Host "--- Iniciando Busca ---" -ForegroundColor Cyan
Find-BinarySearchManual -Array $DadosBaguncados -Target 32 | Format-List
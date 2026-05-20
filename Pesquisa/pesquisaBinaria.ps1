function Find-BinarySearch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Array,

        [Parameter(Mandatory = $true)]
        $Target
    )

    # Definimos os ponteiros inicial e final
    $Left = 0
    $Right = $Array.Count - 1

    while ($Left -le $Right) {
        # Encontra o ponto médio (usando [Math]::Floor para evitar números quebrados)
        $Mid = [Math]::Floor(($Left + $Right) / 2)
        $CurrentValue = $Array[$Mid]

        if ($CurrentValue -eq $Target) {
            return [PSCustomObject]@{
                Encontrado = $true
                Index      = $Mid
                Mensagem   = "Elemento '$Target' encontrado no índice $Mid."
            }
        }
        # Se o valor atual for maior que o alvo, descartamos a metade direita
        elseif ($CurrentValue -gt $Target) {
            $Right = $Mid - 1
        }
        # Se o valor atual for menor que o alvo, descartamos a metade esquerda
        else {
            $Left = $Mid + 1
        }
    }

    # Se o loop terminar e não encontrar nada
    return [PSCustomObject]@{
        Encontrado = $false
        Index      = -1
        Mensagem   = "Elemento '$Target' não foi encontrado na lista."
    }
}

# 1. Criando uma lista ordenada de exemplo
$ListaOrdenada = 1, 3, 5, 7, 9, 11, 13, 15, 17, 19

# Exemplo 1: Procurando um número que EXISTE na lista
Write-Host "--- Teste 1: Elemento Existente ---" -ForegroundColor Cyan
Find-BinarySearch -Array $ListaOrdenada -Target 15 | Format-List

# Exemplo 2: Procurando um número que NÃO EXISTE na lista
Write-Host "--- Teste 2: Elemento Inexistente ---" -ForegroundColor Yellow
Find-BinarySearch -Array $ListaOrdenada -Target 8 | Format-List